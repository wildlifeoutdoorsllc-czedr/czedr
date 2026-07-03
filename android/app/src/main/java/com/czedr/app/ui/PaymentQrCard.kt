package com.czedr.app.ui

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.QrCode
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.czedr.app.qr.CzedrQrCode
import com.czedr.app.ui.theme.CzedrColors

@Composable
fun PaymentQrCard(payload: String, czedrId: String) {
    val trimmedPayload = remember(payload, czedrId) {
        payload.trim().ifBlank { CzedrQrCode.paymentPayload(czedrId) }
    }
    val bitmap = remember(trimmedPayload) { CzedrQrCode.encodeBitmap(trimmedPayload) }

    Column(
        Modifier.fillMaxWidth().padding(vertical = 8.dp),
        horizontalAlignment = Alignment.Start,
    ) {
        Text("My payment QR", color = CzedrColors.Caption, fontSize = 12.sp)
        Column(
            Modifier
                .fillMaxWidth()
                .padding(top = 8.dp)
                .background(Color.White, RoundedCornerShape(8.dp))
                .padding(12.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            when {
                bitmap != null -> {
                    Image(
                        bitmap = bitmap.asImageBitmap(),
                        contentDescription = "Payment QR code for $czedrId",
                        modifier = Modifier.size(200.dp),
                    )
                }
                trimmedPayload.isBlank() -> {
                    CircularProgressIndicator(
                        modifier = Modifier.size(48.dp),
                        color = CzedrColors.BalanceGreen,
                    )
                }
                else -> {
                    Icon(
                        Icons.Default.QrCode,
                        contentDescription = null,
                        modifier = Modifier.size(48.dp),
                        tint = CzedrColors.Caption,
                    )
                    Text(
                        "QR could not be drawn on this device.",
                        color = CzedrColors.Caption,
                        fontSize = 12.sp,
                        modifier = Modifier.padding(top = 8.dp),
                    )
                }
            }
        }
        Text(
            "Show this so others can pay you. They can also type or paste your ID: $czedrId",
            color = CzedrColors.Caption,
            fontSize = 12.sp,
            modifier = Modifier.padding(top = 8.dp),
        )
    }
}
