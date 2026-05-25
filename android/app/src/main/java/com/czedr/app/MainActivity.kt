package com.czedr.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import com.czedr.app.ui.CzedrApp
import com.czedr.app.ui.MainViewModel
import com.czedr.app.ui.theme.CzedrTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            CzedrTheme {
                val vm: MainViewModel = viewModel()
                Surface(modifier = Modifier.fillMaxSize()) {
                    CzedrApp(vm)
                }
            }
        }
    }
}
