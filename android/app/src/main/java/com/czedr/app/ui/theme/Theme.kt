package com.czedr.app.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

object CzedrColors {
    val Background = Color(0xFF1A1A1A)
    val Surface = Color(0xFF2A2A2A)
    val OrangeField = Color(0xFFE8A54B)
    val FieldText = Color(0xFF1A1A1A)
    val LightText = Color(0xFFF5F5F5)
    val Caption = Color(0xFFB0B0B0)
    val BalanceGreen = Color(0xFF8EC966)
    val RedPrimary = Color(0xFFE53935)
    val CharcoalButton = Color(0xFF3D3D3D)
    val Blue = Color(0xFF043A7A)
}

private val DarkColors = darkColorScheme(
    primary = CzedrColors.BalanceGreen,
    onPrimary = Color.Black,
    secondary = CzedrColors.OrangeField,
    background = CzedrColors.Background,
    surface = CzedrColors.Surface,
    onBackground = CzedrColors.LightText,
    onSurface = CzedrColors.LightText,
    error = CzedrColors.RedPrimary,
)

@Composable
fun CzedrTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = DarkColors,
        content = content,
    )
}
