package com.czedr.app.data.session

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.czedr.app.BuildConfig
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map

data class UserSession(
    val token: String,
    val email: String,
    val czedrId: String,
    val hasPinSet: Boolean = false,
    val paymentQrPayload: String = "",
) {
    fun effectivePaymentQrPayload(): String =
        paymentQrPayload.trim().ifBlank { com.czedr.app.qr.CzedrQrCode.paymentPayload(czedrId) }
}

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore("czedr")

class SessionStore(private val context: Context) {

    private val keys = object {
        val token = stringPreferencesKey("auth_token")
        val email = stringPreferencesKey("user_email")
        val czedrId = stringPreferencesKey("czedr_id")
        val apiBase = stringPreferencesKey("api_base")
        val hasPin = stringPreferencesKey("has_pin_set")
        val paymentQrPayload = stringPreferencesKey("payment_qr_payload")
    }

    val session: Flow<UserSession?> = context.dataStore.data.map { prefs ->
        val token = prefs[keys.token].orEmpty()
        if (token.isBlank()) return@map null
        UserSession(
            token = token,
            email = prefs[keys.email].orEmpty(),
            czedrId = prefs[keys.czedrId].orEmpty(),
            hasPinSet = prefs[keys.hasPin] == "1",
            paymentQrPayload = prefs[keys.paymentQrPayload].orEmpty(),
        )
    }

    suspend fun saveSession(
        token: String,
        email: String,
        czedrId: String,
        hasPinSet: Boolean,
        paymentQrPayload: String = "",
    ) {
        context.dataStore.edit { prefs ->
            prefs[keys.token] = token
            prefs[keys.email] = email
            prefs[keys.czedrId] = czedrId
            prefs[keys.hasPin] = if (hasPinSet) "1" else "0"
            if (paymentQrPayload.isNotBlank()) {
                prefs[keys.paymentQrPayload] = paymentQrPayload
            }
        }
    }

    suspend fun updatePaymentQrPayload(payload: String) {
        context.dataStore.edit { prefs ->
            if (payload.isBlank()) {
                prefs.remove(keys.paymentQrPayload)
            } else {
                prefs[keys.paymentQrPayload] = payload
            }
        }
    }

    suspend fun setHasPinSet(value: Boolean) {
        context.dataStore.edit { prefs ->
            prefs[keys.hasPin] = if (value) "1" else "0"
        }
    }

    suspend fun setApiBaseUrl(url: String) {
        val normalized = url.trim().trimEnd('/')
        context.dataStore.edit { it[keys.apiBase] = normalized }
    }

    suspend fun getApiBaseUrl(): String {
        val stored = context.dataStore.data.first()[keys.apiBase].orEmpty().trim().trimEnd('/')
        return if (stored.isNotEmpty()) stored else BuildConfig.API_BASE_DEFAULT.trimEnd('/')
    }

    suspend fun getToken(): String = context.dataStore.data.first()[keys.token].orEmpty()

    suspend fun clear() {
        context.dataStore.edit { prefs ->
            prefs.remove(keys.token)
            prefs.remove(keys.email)
            prefs.remove(keys.czedrId)
            prefs.remove(keys.hasPin)
            prefs.remove(keys.paymentQrPayload)
        }
    }
}
