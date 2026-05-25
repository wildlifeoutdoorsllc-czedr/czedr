package com.czedr.app.data.network

import android.content.Context
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.wifi.WifiManager
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import java.net.Inet4Address
import java.net.NetworkInterface
import java.util.concurrent.TimeUnit

/**
 * Finds the Czedr API on the LAN (same idea as iOS CzedrLanAPIFinder / build 110).
 */
object LanApiFinder {

    private val probeClient = OkHttpClient.Builder()
        .connectTimeout(2, TimeUnit.SECONDS)
        .readTimeout(2, TimeUnit.SECONDS)
        .build()

    suspend fun discover(
        context: Context,
        savedBase: String?,
        defaultBase: String,
    ): Result<String> = withContext(Dispatchers.IO) {
        val candidates = buildCandidates(context, savedBase, defaultBase)
        for (batch in candidates.chunked(28)) {
            val found = coroutineScope {
                batch.map { base ->
                    async {
                        if (testBase(base)) base else null
                    }
                }.awaitAll().firstOrNull { it != null }
            }
            if (found != null) return@withContext Result.success(found)
        }
        Result.failure(
            Exception(
                "Could not find your Czedr server on Wi‑Fi. On your PC run START-IPHONE-TESTING.cmd. " +
                    "Phone and PC must be on the same network.",
            ),
        )
    }

    suspend fun testBase(base: String): Boolean = withContext(Dispatchers.IO) {
        val normalized = normalizeBase(base) ?: return@withContext false
        val url = "$normalized/v1/health"
        runCatching {
            val req = Request.Builder().url(url).get().build()
            probeClient.newCall(req).execute().use { resp ->
                if (!resp.isSuccessful) return@use false
                val raw = resp.body?.string().orEmpty()
                raw.contains("\"Status\":\"true\"") || raw.contains("\"Status\": \"true\"")
            }
        }.getOrDefault(false)
    }

    private fun buildCandidates(context: Context, savedBase: String?, defaultBase: String): List<String> {
        val ordered = LinkedHashSet<String>()
        fun add(value: String?) {
            val n = normalizeBase(value ?: return) ?: return
            if (n.contains("127.0.0.1") || n.contains("localhost")) return
            ordered.add(n)
        }
        add(savedBase)
        add(defaultBase)
        add("http://10.0.2.2:8080")

        val wifiIp = wifiIpv4(context) ?: localIpv4()
        if (wifiIp != null) {
            val parts = wifiIp.split(".")
            if (parts.size == 4) {
                val prefix = "${parts[0]}.${parts[1]}.${parts[2]}."
                val own = parts[3].toIntOrNull() ?: 0
                val hosts = linkedSetOf(1, 10, 20, 51, 100, own, 254)
                for (h in 1..254) hosts.add(h)
                for (h in hosts) {
                    add("http://$prefix$h:8080")
                }
            }
        }
        return ordered.toList()
    }

    private fun wifiIpv4(context: Context): String? {
        val cm = context.getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager ?: return null
        val network = cm.activeNetwork ?: return null
        val caps = cm.getNetworkCapabilities(network) ?: return null
        if (!caps.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) return null
        @Suppress("DEPRECATION")
        val wm = context.applicationContext.getSystemService(Context.WIFI_SERVICE) as? WifiManager
        @Suppress("DEPRECATION")
        val ip = wm?.connectionInfo?.ipAddress ?: return null
        if (ip == 0) return null
        return Inet4Address.getByAddress(
            byteArrayOf(
                (ip and 0xff).toByte(),
                (ip shr 8 and 0xff).toByte(),
                (ip shr 16 and 0xff).toByte(),
                (ip shr 24 and 0xff).toByte(),
            ),
        ).hostAddress
    }

    private fun localIpv4(): String? {
        return NetworkInterface.getNetworkInterfaces()?.toList()?.flatMap { it.inetAddresses.toList() }
            ?.filterIsInstance<Inet4Address>()
            ?.map { it.hostAddress }
            ?.firstOrNull { addr ->
                addr != null && !addr.startsWith("127.") && !addr.startsWith("169.254.")
            }
    }

    fun normalizeBase(url: String): String? {
        val u = url.trim().trimEnd('/')
        if (u.isEmpty()) return null
        if (!u.startsWith("http://") && !u.startsWith("https://")) return null
        return u
    }
}
