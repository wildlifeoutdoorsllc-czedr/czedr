package com.czedr.app.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

private val Green = Color(0xFF8EC966)
private val Blue = Color(0xFF043A7A)

private val LightColors = lightColorScheme(
    primary = Blue,
    onPrimary = Color.White,
    secondary = Green,
    onSecondary = Color.Black,
    tertiary = Green,
    background = Color(0xFFF5F5F5),
    surface = Color.White,
)

@Composable
fun CzedrTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = LightColors,
        content = content,
    )
}
