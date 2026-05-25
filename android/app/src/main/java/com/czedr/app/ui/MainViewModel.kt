package com.czedr.app.ui

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.czedr.app.BuildConfig
import com.czedr.app.CzedrApplication
import com.czedr.app.data.api.ApiResult
import com.czedr.app.data.api.Balance
import com.czedr.app.data.api.CzedrApi
import com.czedr.app.data.api.ReferralEarnings
import com.czedr.app.data.api.TransferRow
import com.czedr.app.data.network.LanApiFinder
import com.czedr.app.data.session.UserSession
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class PaymentSuccessDetails(
    val transactionId: String?,
    val recipientCzedrId: String,
    val recipientName: String,
    val amountCents: Long,
    val memo: String,
)

data class HomeUiState(
    val balance: Balance? = null,
    val referrals: ReferralEarnings? = null,
    val history: List<TransferRow> = emptyList(),
    val loading: Boolean = false,
    val error: String? = null,
    val recipientLabel: String? = null,
    val actionMessage: String? = null,
    val paymentSuccess: PaymentSuccessDetails? = null,
)

data class AuthUiState(
    val error: String? = null,
    val loading: Boolean = false,
    val discoveryStatus: String = "",
)

class MainViewModel(application: Application) : AndroidViewModel(application) {

    private val app = application as CzedrApplication
    private val api = CzedrApi(app.sessionStore)

    private val _session = MutableStateFlow<UserSession?>(null)
    val session: StateFlow<UserSession?> = _session.asStateFlow()

    private val _home = MutableStateFlow(HomeUiState())
    val home: StateFlow<HomeUiState> = _home.asStateFlow()

    private val _auth = MutableStateFlow(AuthUiState())
    val auth: StateFlow<AuthUiState> = _auth.asStateFlow()

    private val _menuOpen = MutableStateFlow(false)
    val menuOpen: StateFlow<Boolean> = _menuOpen.asStateFlow()

    val buildLabel: String get() = "Android · Build ${BuildConfig.VERSION_NAME}"

    init {
        viewModelScope.launch {
            app.sessionStore.session.collect { _session.value = it }
        }
    }

    fun openMenu() { _menuOpen.value = true }
    fun closeMenu() { _menuOpen.value = false }

    fun discoverApi(onResolved: (String) -> Unit) {
        viewModelScope.launch {
            _auth.value = _auth.value.copy(
                discoveryStatus = "Looking for your PC on Wi‑Fi…",
                error = null,
            )
            val saved = app.sessionStore.getApiBaseUrl()
            val default = BuildConfig.API_BASE_DEFAULT.trimEnd('/')
            LanApiFinder.discover(getApplication(), saved, default)
                .onSuccess { base ->
                    app.sessionStore.setApiBaseUrl(base)
                    _auth.value = _auth.value.copy(discoveryStatus = "Server found: $base")
                    onResolved(base)
                }
                .onFailure { e ->
                    _auth.value = _auth.value.copy(
                        discoveryStatus = e.message ?: "Discovery failed",
                    )
                }
        }
    }

    private suspend fun resolveApiBase(input: String): String? {
        val trimmed = input.trim().trimEnd('/')
        if (trimmed.isEmpty()) {
            val saved = app.sessionStore.getApiBaseUrl()
            val default = BuildConfig.API_BASE_DEFAULT.trimEnd('/')
            return LanApiFinder.discover(getApplication(), saved, default).getOrNull()?.also {
                app.sessionStore.setApiBaseUrl(it)
            }
        }
        return if (LanApiFinder.testBase(trimmed)) {
            app.sessionStore.setApiBaseUrl(trimmed)
            trimmed
        } else {
            val saved = app.sessionStore.getApiBaseUrl()
            val default = BuildConfig.API_BASE_DEFAULT.trimEnd('/')
            LanApiFinder.discover(getApplication(), saved, default).getOrNull()?.also {
                app.sessionStore.setApiBaseUrl(it)
            }
        }
    }

    fun login(email: String, password: String, apiBaseInput: String) {
        viewModelScope.launch {
            _auth.value = _auth.value.copy(loading = true, error = null)
            val base = resolveApiBase(apiBaseInput)
            if (base == null) {
                _auth.value = _auth.value.copy(
                    loading = false,
                    error = "Could not reach the Czedr server. Check Wi‑Fi and that START-IPHONE-TESTING is running on your PC.",
                )
                return@launch
            }
            when (val r = api.login(email, password, base)) {
                is ApiResult.Ok -> {
                    val p = r.value
                    app.sessionStore.saveSession(p.token, p.email, p.czedrId, p.hasPinSet)
                    _auth.value = AuthUiState(loading = false)
                    refreshHome()
                }
                is ApiResult.Err -> {
                    _auth.value = _auth.value.copy(loading = false, error = r.message)
                }
            }
        }
    }

    fun register(
        email: String,
        password: String,
        confirmPassword: String,
        referrerCzedrId: String,
        apiBaseInput: String,
    ) {
        if (password != confirmPassword) {
            _auth.value = _auth.value.copy(error = "Passwords do not match")
            return
        }
        if (password.length < 10) {
            _auth.value = _auth.value.copy(error = "Password must be at least 10 characters")
            return
        }
        viewModelScope.launch {
            _auth.value = _auth.value.copy(loading = true, error = null)
            val base = resolveApiBase(apiBaseInput)
            if (base == null) {
                _auth.value = _auth.value.copy(
                    loading = false,
                    error = "Could not reach the Czedr server.",
                )
                return@launch
            }
            when (val r = api.register(email, password, referrerCzedrId, base)) {
                is ApiResult.Ok -> {
                    val p = r.value
                    app.sessionStore.saveSession(p.token, p.email, p.czedrId, p.hasPinSet)
                    _auth.value = AuthUiState(loading = false)
                    refreshHome()
                }
                is ApiResult.Err -> {
                    _auth.value = _auth.value.copy(loading = false, error = r.message)
                }
            }
        }
    }

    fun setPin(pin: String, onDone: () -> Unit) {
        if (pin.length != 4) {
            _home.value = _home.value.copy(error = "PIN must be 4 digits")
            return
        }
        viewModelScope.launch {
            _home.value = _home.value.copy(loading = true, error = null)
            when (val r = api.setPin(pin)) {
                is ApiResult.Ok -> {
                    app.sessionStore.setHasPinSet(true)
                    _session.value = _session.value?.copy(hasPinSet = true)
                    _home.value = _home.value.copy(loading = false)
                    onDone()
                }
                is ApiResult.Err -> {
                    _home.value = _home.value.copy(loading = false, error = r.message)
                }
            }
        }
    }

    fun clearAuthError() {
        _auth.value = _auth.value.copy(error = null)
    }

    fun clearLoginError() = clearAuthError()

    fun dismissHomeMessage() {
        _home.value = _home.value.copy(actionMessage = null, paymentSuccess = null)
    }

    fun logout() {
        viewModelScope.launch {
            closeMenu()
            api.logout()
            app.sessionStore.clear()
            _home.value = HomeUiState()
        }
    }

    fun refreshHome() {
        viewModelScope.launch {
            _home.value = _home.value.copy(loading = true, error = null)
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

    fun loadHistory() {
        viewModelScope.launch {
            _home.value = _home.value.copy(loading = true, error = null)
            when (val r = api.fetchHistory()) {
                is ApiResult.Ok -> _home.value = _home.value.copy(loading = false, history = r.value)
                is ApiResult.Err -> _home.value = _home.value.copy(loading = false, error = r.message)
            }
        }
    }

    fun validateRecipient(czedrId: String) {
        if (czedrId.isBlank()) return
        viewModelScope.launch {
            when (val r = api.validateRecipient(czedrId)) {
                is ApiResult.Ok -> {
                    _home.value = _home.value.copy(recipientLabel = r.value, error = null)
                }
                is ApiResult.Err -> {
                    _home.value = _home.value.copy(recipientLabel = null, error = r.message)
                }
            }
        }
    }

    fun sendTransfer(
        toCzedrId: String,
        amountDollarsText: String,
        memo: String,
        pin: String,
        recipientName: String,
    ) {
        viewModelScope.launch {
            val dollars = amountDollarsText.trim().replace("$", "").replace(",", "")
                .toDoubleOrNull()
            if (dollars == null || dollars <= 0) {
                _home.value = _home.value.copy(error = "Enter a valid amount")
                return@launch
            }
            if (pin.length != 4) {
                _home.value = _home.value.copy(error = "PIN must be 4 digits")
                return@launch
            }
            val cents = (dollars * 100.0).toLong()
            _home.value = _home.value.copy(loading = true, error = null)
            when (val r = api.transfer(toCzedrId, cents, memo, pin)) {
                is ApiResult.Ok -> {
                    _home.value = _home.value.copy(
                        loading = false,
                        paymentSuccess = PaymentSuccessDetails(
                            transactionId = r.value.transactionId,
                            recipientCzedrId = toCzedrId.trim().uppercase(),
                            recipientName = recipientName,
                            amountCents = cents,
                            memo = memo.trim(),
                        ),
                        recipientLabel = null,
                    )
                    refreshHome()
                }
                is ApiResult.Err -> {
                    _home.value = _home.value.copy(loading = false, error = r.message)
                }
            }
        }
    }
}
