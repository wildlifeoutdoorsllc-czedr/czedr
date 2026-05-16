package com.czedr.app.ui

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.czedr.app.CzedrApplication
import com.czedr.app.data.api.ApiResult
import com.czedr.app.data.api.Balance
import com.czedr.app.data.api.CzedrApi
import com.czedr.app.data.session.UserSession
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class HomeUiState(
    val balance: Balance? = null,
    val referrals: ReferralEarnings? = null,
    val loading: Boolean = false,
    val error: String? = null,
    val recipientLabel: String? = null,
    val actionMessage: String? = null,
)

class MainViewModel(application: Application) : AndroidViewModel(application) {

    private val app = application as CzedrApplication
    private val api = CzedrApi(app.sessionStore)

    private val _session = MutableStateFlow<UserSession?>(null)
    val session: StateFlow<UserSession?> = _session.asStateFlow()

    private val _home = MutableStateFlow(HomeUiState())
    val home: StateFlow<HomeUiState> = _home.asStateFlow()

    init {
        viewModelScope.launch {
            app.sessionStore.session.collect { _session.value = it }
        }
    }

    fun login(email: String, password: String, apiBaseInput: String) {
        viewModelScope.launch {
            val trimmedBase = apiBaseInput.trim().trimEnd('/')
            if (trimmedBase.isNotEmpty()) {
                app.sessionStore.setApiBaseUrl(trimmedBase)
            }
            when (val r = api.login(email, password, trimmedBase.ifEmpty { null })) {
                is ApiResult.Ok -> {
                    val (token, em, cid) = r.value
                    app.sessionStore.saveSession(token, em, cid)
                    _home.value = _home.value.copy(error = null)
                    refreshHome()
                }
                is ApiResult.Err -> {
                    _home.value = _home.value.copy(error = r.message, actionMessage = null)
                }
            }
        }
    }

    fun clearLoginError() {
        _home.value = _home.value.copy(error = null)
    }

    fun dismissHomeMessage() {
        _home.value = _home.value.copy(actionMessage = null)
    }

    fun logout() {
        viewModelScope.launch {
            api.logout()
            app.sessionStore.clear()
            _home.value = HomeUiState()
        }
    }

    fun refreshHome() {
        viewModelScope.launch {
            _home.value = _home.value.copy(loading = true, error = null, actionMessage = null)
            val balance = api.fetchBalance()
            val refs = api.fetchReferralEarnings()
            var next = _home.value.copy(loading = false)
            when (balance) {
                is ApiResult.Ok -> next = next.copy(balance = balance.value)
                is ApiResult.Err -> next = next.copy(error = balance.message)
            }
            when (refs) {
                is ApiResult.Ok -> next = next.copy(referrals = refs.value)
                is ApiResult.Err -> next = next.copy(error = next.error ?: refs.message)
            }
            _home.value = next
        }
    }

    fun validateRecipient(czedrId: String) {
        if (czedrId.isBlank()) return
        viewModelScope.launch {
            when (val r = api.validateRecipient(czedrId)) {
                is ApiResult.Ok -> {
                    _home.value = _home.value.copy(recipientLabel = r.value, actionMessage = null, error = null)
                }
                is ApiResult.Err -> {
                    _home.value = _home.value.copy(recipientLabel = null, error = r.message)
                }
            }
        }
    }

    fun sendTransfer(toCzedrId: String, amountDollarsText: String, memo: String, pin: String) {
        viewModelScope.launch {
            val dollars = amountDollarsText.trim().toDoubleOrNull()
                ?: run {
                    _home.value = _home.value.copy(error = "Enter a valid amount")
                    return@launch
                }
            val cents = (dollars * 100.0).toLong()
            if (cents <= 0) {
                _home.value = _home.value.copy(error = "Amount must be positive")
                return@launch
            }
            when (val r = api.transfer(toCzedrId, cents, memo, pin)) {
                is ApiResult.Ok -> {
                    _home.value = _home.value.copy(
                        actionMessage = "Transfer sent",
                        error = null,
                        recipientLabel = null,
                    )
                    refreshHome()
                }
                is ApiResult.Err -> {
                    _home.value = _home.value.copy(error = r.message, actionMessage = null)
                }
            }
        }
    }
}
