# Czedr Android

Native **Kotlin + Jetpack Compose** client for the same JSON API used by iOS (`/v1/...`).

## Requirements

- Android Studio Koala or newer (or a JDK 17 + Android SDK with the same Gradle/AGP as the root `build.gradle.kts`)

## Run against your API

1. From repo root run **`scripts\start-php-server.ps1`** (serves on **0.0.0.0:8080** — use the URLs it prints).
2. **Android emulator**: API base **`http://10.0.2.2:8080`** (default in the app).
3. **Physical device**: same Wi‑Fi as the PC; API base **`http://YOUR_PC_LAN_IP:8080`** (the script prints your LAN IP). Allow Windows Firewall for port **8080** if prompted.

Cleartext HTTP is enabled for local dev (`usesCleartextTraffic`). Use HTTPS in production and turn that off.

## Auth note

This MVP uses **`POST /v1/auth/login`** (email + password JSON). iOS production builds use **`/v1/auth/login-secure`** (image-derived crypto); that flow is not implemented here yet.

## Project layout

- `app/src/main/java/com/czedr/app/` — UI, `MainViewModel`, `CzedrApi` (OkHttp), `SessionStore` (DataStore)

Open the **`android/`** folder in Android Studio, sync Gradle, then Run.
