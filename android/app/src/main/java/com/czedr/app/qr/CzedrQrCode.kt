package com.czedr.app.qr

import android.graphics.Bitmap
import android.graphics.Color
import com.google.zxing.BarcodeFormat
import com.google.zxing.EncodeHintType
import com.google.zxing.qrcode.QRCodeWriter
import java.util.regex.Pattern

object CzedrQrCode {
    const val PAY_URL_PREFIX = "https://czedr.com/pay/"

    private val idPattern = Pattern.compile("(?i)\\b(CZ[0-9A-F]{8})\\b")

    fun paymentPayload(czedrId: String): String =
        PAY_URL_PREFIX + czedrId.trim().uppercase()

    fun parseCzedrId(raw: String): String? {
        val trimmed = raw.trim()
        if (trimmed.isEmpty()) return null

        firstIdMatch(trimmed)?.let { return it }

        if (trimmed.contains("://")) {
            runCatching {
                val uri = android.net.Uri.parse(trimmed)
                val host = uri.host?.lowercase().orEmpty()
                if (host.contains("czedr.com")) {
                    val path = uri.path?.trim('/')?.orEmpty()
                    firstIdMatch(path)?.let { return it }
                }
                if (uri.scheme?.lowercase() == "czedr") {
                    uri.getQueryParameter("czedr_id")?.let { firstIdMatch(it) }?.let { return it }
                }
            }
        }

        return firstIdMatch(trimmed.replace("-", ""))
    }

    fun encodeBitmap(payload: String, sizePx: Int = 512): Bitmap? {
        val text = payload.trim()
        if (text.isEmpty()) return null
        return try {
            val hints = mapOf(EncodeHintType.MARGIN to 1)
            val matrix = QRCodeWriter().encode(text, BarcodeFormat.QR_CODE, sizePx, sizePx, hints)
            val w = matrix.width
            val h = matrix.height
            val pixels = IntArray(w * h)
            for (y in 0 until h) {
                for (x in 0 until w) {
                    pixels[y * w + x] = if (matrix[x, y]) Color.BLACK else Color.WHITE
                }
            }
            Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888).apply {
                setPixels(pixels, 0, w, 0, 0, w, h)
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun firstIdMatch(text: String): String? {
        val matcher = idPattern.matcher(text)
        return if (matcher.find()) matcher.group(1)?.uppercase() else null
    }
}
