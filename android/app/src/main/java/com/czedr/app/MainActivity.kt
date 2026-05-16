package com.czedr.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Surface
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import com.czedr.app.ui.HomeScreen
import com.czedr.app.ui.LoginScreen
import com.czedr.app.ui.MainViewModel
import com.czedr.app.ui.theme.CzedrTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            CzedrTheme {
                val vm: MainViewModel = viewModel()
                val session by vm.session.collectAsState()
                val home by vm.home.collectAsState()

                Surface(modifier = Modifier.fillMaxSize()) {
                    val s = session
                    if (s == null) {
                        LoginScreen(
                            apiBaseDefault = BuildConfig.API_BASE_DEFAULT.trimEnd('/'),
                            error = home.error,
                            onClearError = vm::clearLoginError,
                            onLogin = vm::login,
                        )
                    } else {
                        LaunchedEffect(s.czedrId) {
                            vm.refreshHome()
                        }
                        HomeScreen(
                            session = s,
                            state = home,
                            onRefresh = vm::refreshHome,
                            onLogout = vm::logout,
                            onValidate = vm::validateRecipient,
                            onSendTransfer = vm::sendTransfer,
                            onDismissMessage = vm::dismissHomeMessage,
                        )
                    }
                }
            }
        }
    }
}
