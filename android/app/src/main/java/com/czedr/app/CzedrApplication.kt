package com.czedr.app

import android.app.Application
import com.czedr.app.data.session.SessionStore
import kotlinx.coroutines.runBlocking

class CzedrApplication : Application() {
    lateinit var sessionStore: SessionStore
        private set

    override fun onCreate() {
        super.onCreate()
        sessionStore = SessionStore(this)
        // Swipe-up kill starts a new process; require sign-in again (keep saved API base URL).
        runBlocking {
            if (sessionStore.getToken().isNotBlank()) {
                sessionStore.clear()
            }
        }
    }
}
