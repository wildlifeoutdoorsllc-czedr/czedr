# Czedr — TestFlight without a Mac

GitHub Actions builds the iOS app on a cloud Mac and uploads to **TestFlight**. You install the app on your iPhone from the TestFlight app.

## Prerequisites

1. **Apple Developer Program** ($99/year) — [developer.apple.com](https://developer.apple.com/programs/)
2. **GitHub repository** with this code pushed to `main` or `master`
3. **App Store Connect** app record for bundle ID `com.czedr.app`

### Create the app in App Store Connect

1. [App Store Connect](https://appstoreconnect.apple.com) → **Apps** → **+** → New App  
2. Platform: iOS  
3. Bundle ID: `com.czedr.app` (register under [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list) if needed)  
4. Name: **Czedr**

## Step 1 — App Store Connect API key

1. App Store Connect → **Users and Access** → **Integrations** → **App Store Connect API**  
2. **+** to generate a key with role **App Manager** or **Admin**  
3. Download the `.p8` file (once only)  
4. Note **Issuer ID** and **Key ID**

Base64-encode the private key for GitHub:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("AuthKey_XXXXXXXXXX.p8"))
```

## Step 2 — Distribution certificate (.p12)

On any Mac (borrow one hour at a library, or use a cloud Mac trial):

1. Xcode → Settings → Accounts → your Apple ID → **Manage Certificates**  
2. **+** → **Apple Distribution**  
3. Keychain Access → My Certificates → export **Apple Distribution: …** as `.p12` with a password  

Or use [Apple’s documentation](https://developer.apple.com/help/account/certificates/create-enterprise-distribution-certificates/) to create a distribution certificate.

Base64-encode the `.p12`:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("distribution.p12"))
```

## Step 3 — GitHub secrets

Repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

| Secret | Value |
|--------|--------|
| `APPLE_TEAM_ID` | 10-character Team ID (Apple Developer → Membership) |
| `APPSTORE_ISSUER_ID` | From App Store Connect API |
| `APPSTORE_KEY_ID` | From App Store Connect API |
| `APPSTORE_PRIVATE_KEY` | Base64 of the `.p8` file |
| `BUILD_CERTIFICATE_BASE64` | Base64 of the `.p12` file |
| `P12_PASSWORD` | Password you set when exporting `.p12` |
| `KEYCHAIN_PASSWORD` | Any strong random string (e.g. `openssl rand -base64 32`) |

### Optional variable

**Settings** → **Secrets and variables** → **Actions** → **Variables**:

| Variable | Example | Purpose |
|----------|---------|---------|
| `CZEDR_API_BASE` | `https://api.yourdomain.com` | API URL compiled into the app |

Or pass per run: **Actions** → **iOS TestFlight** → **Run workflow** → **api_base_url**.

For local dev on iPhone + PC, use your PC’s LAN URL, e.g. `http://192.168.1.10:8080` (only works on your Wi‑Fi).

## Step 4 — Run the workflow

1. Push code to GitHub  
2. **Actions** → **iOS TestFlight** → **Run workflow**  
3. Wait ~15–25 minutes (first run may fail on signing — check logs)  
4. App Store Connect → **TestFlight** → build appears → add yourself as **Internal Tester**  
5. Install **TestFlight** on iPhone → accept invite → install **Czedr**

## Troubleshooting

| Error | Fix |
|-------|-----|
| No signing certificate | Re-export `.p12`, update `BUILD_CERTIFICATE_BASE64` |
| No profiles for bundle ID | Create `com.czedr.app` in Apple Developer portal |
| Wrong team | `APPLE_TEAM_ID` must match certificate team |
| Build compile errors | Open logs; legacy code may need Xcode fixes on `macos-15` |
| App can’t reach API | Set `CZEDR_API_BASE` / workflow input to a reachable HTTPS URL |

## iPhone testing without TestFlight

Use the web sandbox (no build):

```powershell
cd scripts
.\start-iphone-sandbox.ps1
```

On iPhone Safari: `http://YOUR_PC_IP:8080/sandbox`

## After TestFlight install — point app at your PC (optional)

The app reads `UserDefaults` key `czedr_api_base` if set. A future in-app dev screen can set this; for now use the workflow **api_base_url** input when building.
