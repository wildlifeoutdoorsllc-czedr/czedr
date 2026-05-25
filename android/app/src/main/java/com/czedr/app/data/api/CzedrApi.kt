package com.czedr.app.data.api

import com.czedr.app.data.session.SessionStore
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.HttpUrl.Companion.toHttpUrlOrNull
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID
import java.util.concurrent.TimeUnit

sealed class ApiResult<out T> {
    data class Ok<T>(val value: T) : ApiResult<T>()
    data class Err(val message: String) : ApiResult<Nothing>()
}

data class AuthPayload(
    val token: String,
    val email: String,
    val czedrId: String,
    val hasPinSet: Boolean,
)

data class TransferResult(
    val transactionId: String?,
)

data class TransferRow(
    val id: String,
    val amountCents: Long,
    val currency: String,
    val memo: String,
    val createdAt: String,
    val fromCzedrId: String,
    val toCzedrId: String,
    val status: String,
)

private class ApiHttpException(val code: Int, message: String) : Exception(message)

class CzedrApi(private val sessionStore: SessionStore) {

    private val client = OkHttpClient.Builder()
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(60, TimeUnit.SECONDS)
        .writeTimeout(60, TimeUnit.SECONDS)
        .build()

    private val jsonMedia = "application/json; charset=utf-8".toMediaType()

    suspend fun login(
        email: String,
        password: String,
        apiBaseOverride: String?,
    ): ApiResult<AuthPayload> = withContext(Dispatchers.IO) {
        postAuth("/v1/auth/login", apiBaseOverride) {
            JSONObject()
                .put("user_email", email)
                .put("email", email)
                .put("user_pwd", password)
                .put("password", password)
        }
    }

    suspend fun register(
        email: String,
        password: String,
        referrerCzedrId: String?,
        apiBaseOverride: String?,
    ): ApiResult<AuthPayload> = withContext(Dispatchers.IO) {
        postAuth("/v1/auth/register", apiBaseOverride) {
            val body = JSONObject()
                .put("email", email)
                .put("password", password)
            val ref = referrerCzedrId?.trim()?.uppercase().orEmpty()
            if (ref.isNotEmpty()) body.put("referrer_czedr_id", ref)
            body
        }
    }

    suspend fun setPin(pin: String): ApiResult<Unit> = withContext(Dispatchers.IO) {
        runCatching {
            val base = normalizeBase(sessionStore.getApiBaseUrl())
                ?: return@runCatching ApiResult.Err("Invalid API base URL")
            val token = sessionStore.getToken()
            if (token.isBlank()) return@runCatching ApiResult.Err("Not signed in")
            val body = JSONObject().put("user_pin", pin).toString().toRequestBody(jsonMedia)
            val req = Request.Builder()
                .url("$base/v1/auth/pin/set")
                .post(body)
                .addHeader("Authorization", "Bearer $token")
                .build()
            parseObjectEnvelope(execute(req)) { ApiResult.Ok(Unit) }
        }.getOrElse { e -> apiError(e) }
    }

    private suspend fun postAuth(
        path: String,
        apiBaseOverride: String?,
        buildBody: () -> JSONObject,
    ): ApiResult<AuthPayload> = runCatching {
        val base = normalizeBase(apiBaseOverride ?: sessionStore.getApiBaseUrl())
            ?: return@runCatching ApiResult.Err("Invalid API base URL")
        val body = buildBody().toString().toRequestBody(jsonMedia)
        val req = Request.Builder().url("$base$path").post(body).build()
        parseObjectEnvelope(execute(req)) { data -> parseAuthPayload(data) }
    }.getOrElse { e -> apiError(e) }

    private fun parseAuthPayload(data: JSONObject): ApiResult<AuthPayload> {
        val auth = data.optString("auth_code").ifBlank { data.optString("auth_token") }
        if (auth.isBlank()) return ApiResult.Err("No auth token in response")
        val user = data.optJSONObject("user")
        val em = user?.optString("email").orEmpty().ifBlank { data.optString("email") }
        val cid = user?.optString("czedr_id").orEmpty()
            .ifBlank { data.optString("czedr_id") }
            .ifBlank { data.optString("id") }
        if (cid.isBlank()) return ApiResult.Err("No Czedr ID in response")
        val pinFlag = data.optString("user_pin").ifBlank { user?.optString("user_pin").orEmpty() }
        return ApiResult.Ok(AuthPayload(auth, em, cid, pinFlag == "1"))
    }

    suspend fun logout() = withContext(Dispatchers.IO) {
        val base = normalizeBase(sessionStore.getApiBaseUrl()) ?: return@withContext
        val token = sessionStore.getToken()
        if (token.isBlank()) return@withContext
        val req = Request.Builder()
            .url("$base/v1/auth/logout")
            .post(ByteArray(0).toRequestBody(null))
            .addHeader("Authorization", "Bearer $token")
            .build()
        runCatching { client.newCall(req).execute().close() }
    }

    suspend fun fetchBalance(): ApiResult<Balance> = withContext(Dispatchers.IO) {
        authedGetObject("/v1/ledger/balance") { data ->
            Balance(
                balanceCents = data.optLong("balance_cents"),
                currency = data.optString("currency", "USD"),
                transferFeeCents = data.optLong("transfer_fee_cents"),
                referralRewardCents = data.optLong("referral_reward_cents"),
            )
        }
    }

    suspend fun fetchReferralEarnings(limit: Int = 25): ApiResult<ReferralEarnings> = withContext(Dispatchers.IO) {
        authedGetObject("/v1/referrals/earnings?recent_limit=$limit") { data ->
            val recent = data.optJSONArray("recent_credits") ?: JSONArray()
            val items = buildList {
                for (i in 0 until recent.length()) {
                    val row = recent.optJSONObject(i) ?: continue
                    add(
                        ReferralCredit(
                            amountCents = row.optLong("amount_cents"),
                            createdAt = row.optString("created_at"),
                            memo = row.optString("memo"),
                        ),
                    )
                }
            }
            ReferralEarnings(
                totalCents = data.optLong("referral_earnings_total_cents"),
                paymentCount = data.optInt("referral_payment_count"),
                currency = data.optString("currency", "USD"),
                recent = items,
            )
        }
    }

    suspend fun validateRecipient(czedrId: String): ApiResult<String> = withContext(Dispatchers.IO) {
        val q = czedrId.trim().uppercase()
        authedGetObject("/v1/users/validate?czedr_id=${encodeQuery(q)}") { data ->
            data.optString("display_name").ifBlank { data.optString("result") }.ifBlank { q }
        }
    }

    suspend fun transfer(
        toCzedrId: String,
        amountCents: Long,
        memo: String,
        pin: String,
    ): ApiResult<TransferResult> = withContext(Dispatchers.IO) {
        runCatching {
            val base = normalizeBase(sessionStore.getApiBaseUrl())
                ?: return@runCatching ApiResult.Err("Invalid API base URL")
            val token = sessionStore.getToken()
            if (token.isBlank()) return@runCatching ApiResult.Err("Not signed in")
            val body = JSONObject()
                .put("to_czedr_id", toCzedrId.trim().uppercase())
                .put("amount_cents", amountCents)
                .put("idempotency_key", "android-${UUID.randomUUID()}")
                .put("memo", memo.ifBlank { "Payment" })
                .put("user_pin", pin)
                .toString()
                .toRequestBody(jsonMedia)
            val req = Request.Builder()
                .url("$base/v1/transfers")
                .post(body)
                .addHeader("Authorization", "Bearer $token")
                .build()
            parseObjectEnvelope(execute(req)) { data ->
                ApiResult.Ok(TransferResult(data.optString("id").ifBlank { data.optString("transaction_id") }))
            }
        }.getOrElse { e -> apiError(e) }
    }

    suspend fun fetchHistory(): ApiResult<List<TransferRow>> = withContext(Dispatchers.IO) {
        authedGetObject("/v1/transfers/history") { data ->
            val rows = data.optJSONArray("transactions") ?: JSONArray()
            buildList {
                for (i in 0 until rows.length()) {
                    val row = rows.optJSONObject(i) ?: continue
                    val id = row.optString("id").ifBlank { continue }
                    add(
                        TransferRow(
                            id = id,
                            amountCents = row.optLong("amount_cents"),
                            currency = row.optString("currency", "USD"),
                            memo = row.optString("memo"),
                            createdAt = row.optString("created_at"),
                            fromCzedrId = row.optString("from_czedr_id"),
                            toCzedrId = row.optString("to_czedr_id"),
                            status = row.optString("status"),
                        ),
                    )
                }
            }
        }
    }

    private fun apiError(e: Throwable): ApiResult<Nothing> = when (e) {
        is ApiHttpException -> ApiResult.Err(e.message ?: "HTTP ${e.code}")
        else -> ApiResult.Err(e.message ?: "Network error")
    }

    private fun encodeQuery(s: String): String = java.net.URLEncoder.encode(s, Charsets.UTF_8.name())

    private suspend fun <T> authedGetObject(pathAndQuery: String, map: (JSONObject) -> T): ApiResult<T> {
        return runCatching {
            val base = normalizeBase(sessionStore.getApiBaseUrl())
                ?: return@runCatching ApiResult.Err("Invalid API base URL")
            val token = sessionStore.getToken()
            if (token.isBlank()) return@runCatching ApiResult.Err("Not signed in")
            val url = "$base$pathAndQuery"
            val req = Request.Builder()
                .url(url)
                .get()
                .addHeader("Authorization", "Bearer $token")
                .build()
            parseObjectEnvelope(execute(req), map)
        }.getOrElse { e ->
            when (e) {
                is ApiHttpException -> ApiResult.Err(e.message ?: "HTTP ${e.code}")
                else -> ApiResult.Err(e.message ?: "Network error")
            }
        }
    }

    private fun execute(req: Request): String {
        client.newCall(req).execute().use { resp ->
            val raw = resp.body?.string().orEmpty()
            if (!resp.isSuccessful) {
                val msg = runCatching { extractErrorMessage(JSONObject(raw)) }.getOrNull()
                    ?: raw.ifBlank { "${resp.code} ${resp.message}" }
                throw ApiHttpException(resp.code, msg)
            }
            return raw
        }
    }

    private fun <T> parseObjectEnvelope(raw: String, useData: (JSONObject) -> ApiResult<T>): ApiResult<T> {
        return try {
            val json = JSONObject(raw)
            if (json.optString("Status") != "true") {
                return ApiResult.Err(extractErrorMessage(json))
            }
            when (val data = json.get("Data")) {
                is JSONObject -> useData(data)
                is JSONArray -> {
                    if (data.length() > 0 && data.opt(0) is JSONObject) {
                        useData(data.getJSONObject(0))
                    } else {
                        ApiResult.Err("Unexpected response shape")
                    }
                }
                else -> ApiResult.Err("Unexpected response shape")
            }
        } catch (e: Exception) {
            ApiResult.Err(e.message ?: "Parse error")
        }
    }

    private fun extractErrorMessage(json: JSONObject): String {
        val data = json.optJSONArray("Data") ?: return json.optString("message").ifBlank { "Request failed" }
        val first = data.optJSONObject(0) ?: return "Request failed"
        return first.optString("result").ifBlank { "Request failed" }
    }

    private fun normalizeBase(url: String): String? {
        val u = url.trim().trimEnd('/')
        if (u.isEmpty()) return null
        val httpUrl = u.toHttpUrlOrNull() ?: return null
        val portPart = if (httpUrl.port != httpUrl.defaultPort) ":${httpUrl.port}" else ""
        return "${httpUrl.scheme}://${httpUrl.host}$portPart"
    }
}

data class Balance(
    val balanceCents: Long,
    val currency: String,
    val transferFeeCents: Long,
    val referralRewardCents: Long,
)

data class ReferralCredit(
    val amountCents: Long,
    val createdAt: String,
    val memo: String,
)

data class ReferralEarnings(
    val totalCents: Long,
    val paymentCount: Int,
    val currency: String,
    val recent: List<ReferralCredit>,
)
