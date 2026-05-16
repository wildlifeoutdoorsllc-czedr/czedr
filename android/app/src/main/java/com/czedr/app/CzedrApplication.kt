package com.czedr.app

import android.app.Application
import com.czedr.app.data.session.SessionStore

class CzedrApplication : Application() {
    lateinit var sessionStore: SessionStore
        private set

    override fun onCreate() {
        super.onCreate()
        sessionStore = SessionStore(this)
    }
}
