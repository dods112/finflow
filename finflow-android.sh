#!/bin/bash

# ============================================================
#  FinFlow → Android APK Builder (Capacitor)
#  Run from: C:\laragon\www\Phone-app\
#  Usage:    bash finflow-android.sh
# ============================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

# ╔══════════════════════════════════════════╗
# ║   🔧 EDIT THIS BEFORE RUNNING           ║
# ╚══════════════════════════════════════════╝
APP_URL="https://your-domain.com"       # ← Change this to your live URL
APP_NAME="FinFlow"
APP_ID="com.finflow.app"                # ← Change this if you want (reverse domain)
# ════════════════════════════════════════════

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║     FinFlow → Android APK Builder        ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""

# ── Validate domain was changed ─────────────────────────────
if [[ "$APP_URL" == "https://your-domain.com" ]]; then
    echo -e "${RED}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ⚠️  You forgot to set your domain!                      ║${NC}"
    echo -e "${RED}║                                                          ║${NC}"
    echo -e "${RED}║  Open finflow-android.sh in a text editor and change:    ║${NC}"
    echo -e "${RED}║  APP_URL=\"https://your-domain.com\"                       ║${NC}"
    echo -e "${RED}║  to your actual live URL, e.g.:                          ║${NC}"
    echo -e "${RED}║  APP_URL=\"https://finflow.mysite.com\"                    ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    exit 1
fi

step() { echo -e "\n${YELLOW}▶ $1${NC}"; }
ok()   { echo -e "  ${GREEN}✔${NC} $1"; }
info() { echo -e "  ${CYAN}ℹ${NC}  $1"; }
fail() { echo -e "  ${RED}✘${NC} $1"; }

# ============================================================
# STEP 1 — Check Node.js & npm
# ============================================================
step "Step 1/6 — Checking Node.js & npm"

if ! command -v node &> /dev/null; then
    fail "Node.js not found. Please install from https://nodejs.org"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    fail "npm not found. Please reinstall Node.js from https://nodejs.org"
    exit 1
fi

NODE_VER=$(node -v)
NPM_VER=$(npm -v)
ok "Node.js $NODE_VER"
ok "npm $NPM_VER"

# ============================================================
# STEP 2 — Create Capacitor project folder
# ============================================================
step "Step 2/6 — Creating Capacitor project"

ANDROID_DIR="finflow-android"

if [ -d "$ANDROID_DIR" ]; then
    info "Folder '$ANDROID_DIR' already exists — removing and recreating"
    rm -rf "$ANDROID_DIR"
fi

mkdir -p "$ANDROID_DIR"
cd "$ANDROID_DIR" || exit 1

ok "Created folder: $ANDROID_DIR"

# ── Init npm project ─────────────────────────────────────────
cat > package.json << JSON
{
  "name": "finflow-android",
  "version": "1.0.0",
  "description": "FinFlow Android App",
  "main": "index.js",
  "scripts": {
    "build": "echo 'No build needed - using live URL'"
  }
}
JSON
ok "package.json created"

# ============================================================
# STEP 3 — Install Capacitor
# ============================================================
step "Step 3/6 — Installing Capacitor (this may take 1-2 minutes)"

npm install @capacitor/core @capacitor/cli @capacitor/android --save 2>/dev/null
if [ $? -ne 0 ]; then
    fail "npm install failed. Check your internet connection."
    exit 1
fi
ok "Capacitor installed"

# ============================================================
# STEP 4 — Create the web app wrapper
# ============================================================
step "Step 4/6 — Creating web wrapper files"

# ── www/index.html (the shell that loads your live app) ──────
mkdir -p www
cat > www/index.html << HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover">
    <meta http-equiv="Content-Security-Policy"
          content="default-src * 'unsafe-inline' 'unsafe-eval' data: blob:;">
    <title>FinFlow</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        html, body { width: 100%; height: 100%; overflow: hidden; background: #030712; }

        #splash {
            position: fixed;
            inset: 0;
            background: #030712;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            z-index: 9999;
            transition: opacity 0.5s ease;
        }
        #splash .logo {
            width: 72px; height: 72px;
            background: #4f46e5;
            border-radius: 20px;
            display: flex; align-items: center; justify-content: center;
            margin-bottom: 20px;
            box-shadow: 0 20px 60px rgba(79,70,229,0.4);
        }
        #splash .logo svg { width: 36px; height: 36px; color: white; }
        #splash h1 {
            color: white;
            font-size: 28px;
            font-weight: 700;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
            letter-spacing: -0.5px;
        }
        #splash p {
            color: #6b7280;
            font-size: 13px;
            margin-top: 8px;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
        }
        #splash .spinner {
            width: 24px; height: 24px;
            border: 2px solid #374151;
            border-top-color: #4f46e5;
            border-radius: 50%;
            animation: spin 0.8s linear infinite;
            margin-top: 40px;
        }
        @keyframes spin { to { transform: rotate(360deg); } }

        #app-frame {
            width: 100%;
            height: 100%;
            border: none;
            display: block;
        }
    </style>
</head>
<body>

    <!-- Splash Screen -->
    <div id="splash">
        <div class="logo">
            <svg fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round"
                      d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
            </svg>
        </div>
        <h1>FinFlow</h1>
        <p>Smart money management</p>
        <div class="spinner"></div>
    </div>

    <!-- Your Live App -->
    <iframe
        id="app-frame"
        src="${APP_URL}"
        allow="camera; microphone; geolocation"
        allowfullscreen>
    </iframe>

    <script>
        const frame  = document.getElementById('app-frame');
        const splash = document.getElementById('splash');

        // Hide splash when iframe loads
        frame.addEventListener('load', function () {
            setTimeout(function () {
                splash.style.opacity = '0';
                setTimeout(function () {
                    splash.style.display = 'none';
                }, 500);
            }, 800);
        });

        // Hide splash after max 5s regardless
        setTimeout(function () {
            splash.style.opacity = '0';
            setTimeout(function () { splash.style.display = 'none'; }, 500);
        }, 5000);

        // Handle Android back button
        document.addEventListener('backbutton', function () {
            if (frame.contentWindow) {
                frame.contentWindow.history.back();
            }
        }, false);
    </script>
</body>
</html>
HTML
ok "www/index.html created"

# ── capacitor.config.json ────────────────────────────────────
cat > capacitor.config.json << JSON
{
  "appId": "${APP_ID}",
  "appName": "${APP_NAME}",
  "webDir": "www",
  "server": {
    "url": "${APP_URL}",
    "cleartext": false,
    "androidScheme": "https"
  },
  "android": {
    "allowMixedContent": false,
    "captureInput": true,
    "webContentsDebuggingEnabled": false
  },
  "plugins": {
    "SplashScreen": {
      "launchShowDuration": 2000,
      "backgroundColor": "#030712",
      "androidSplashResourceName": "splash",
      "showSpinner": false
    }
  }
}
JSON
ok "capacitor.config.json created"

# ============================================================
# STEP 5 — Add Android platform
# ============================================================
step "Step 5/6 — Adding Android platform"

npx cap add android 2>/dev/null
if [ $? -ne 0 ]; then
    fail "Failed to add Android platform."
    info "Make sure you have Java JDK 17+ installed."
    info "Download from: https://adoptium.net"
    exit 1
fi
ok "Android platform added"

# ── Sync web assets ──────────────────────────────────────────
npx cap sync android 2>/dev/null
ok "Assets synced to Android"

# ============================================================
# STEP 6 — Patch Android files for better experience
# ============================================================
step "Step 6/6 — Patching Android configuration"

# ── Update app name in strings.xml ──────────────────────────
STRINGS_FILE="android/app/src/main/res/values/strings.xml"
if [ -f "$STRINGS_FILE" ]; then
    sed -i "s|<string name=\"app_name\">.*</string>|<string name=\"app_name\">${APP_NAME}</string>|g" "$STRINGS_FILE"
    ok "App name set to '$APP_NAME'"
fi

# ── Update AndroidManifest.xml — add internet + camera perms ─
MANIFEST="android/app/src/main/AndroidManifest.xml"
if [ -f "$MANIFEST" ]; then
    # Add permissions before <application tag
    if ! grep -q "CAMERA" "$MANIFEST"; then
        sed -i 's|<application|<uses-permission android:name="android.permission.INTERNET" />\n    <uses-permission android:name="android.permission.CAMERA" />\n    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />\n    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />\n    <uses-feature android:name="android.hardware.camera" android:required="false" />\n\n    <application|' "$MANIFEST"
        ok "Permissions added to AndroidManifest.xml"
    else
        ok "Permissions already present"
    fi
fi

# ── Set background color in styles.xml ───────────────────────
STYLES="android/app/src/main/res/values/styles.xml"
if [ -f "$STYLES" ]; then
    cat > "$STYLES" << XML
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="AppTheme" parent="Theme.AppCompat.NoActionBar">
        <item name="android:background">#030712</item>
        <item name="colorPrimary">#4f46e5</item>
        <item name="colorPrimaryDark">#030712</item>
        <item name="colorAccent">#4f46e5</item>
        <item name="android:statusBarColor">#030712</item>
        <item name="android:navigationBarColor">#030712</item>
        <item name="android:windowBackground">#030712</item>
    </style>
    <style name="AppTheme.NoActionBar" parent="AppTheme">
        <item name="windowActionBar">false</item>
        <item name="windowNoTitle">true</item>
    </style>
</resources>
XML
    ok "Dark theme applied to Android"
fi

# ── Create build instructions file ───────────────────────────
cat > ../ANDROID_BUILD_INSTRUCTIONS.txt << 'TXT'
╔══════════════════════════════════════════════════════════════════╗
║         FinFlow Android — Build Instructions                     ║
╚══════════════════════════════════════════════════════════════════╝

The script has set up everything inside the "finflow-android" folder.
Now follow these steps to build your APK:

──────────────────────────────────────────────────────────────────
STEP A — Install Android Studio
──────────────────────────────────────────────────────────────────
1. Go to: https://developer.android.com/studio
2. Download and install Android Studio (it's free)
3. During setup, make sure to install:
   ✔ Android SDK
   ✔ Android SDK Platform (API 33 or 34)
   ✔ Android Virtual Device (AVD) — optional, for testing

──────────────────────────────────────────────────────────────────
STEP B — Open the project in Android Studio
──────────────────────────────────────────────────────────────────
1. Open Android Studio
2. Click "Open" (NOT "New Project")
3. Navigate to:
   C:\laragon\www\Phone-app\finflow-android\android
4. Click OK and wait for Gradle to sync (2-5 minutes first time)

──────────────────────────────────────────────────────────────────
STEP C — Build the APK
──────────────────────────────────────────────────────────────────
1. In Android Studio top menu:
   Build → Build Bundle(s) / APK(s) → Build APK(s)
2. Wait for it to finish (1-3 minutes)
3. Click "locate" in the notification that appears
4. Your APK is at:
   finflow-android\android\app\build\outputs\apk\debug\app-debug.apk

──────────────────────────────────────────────────────────────────
STEP D — Install on your Android phone
──────────────────────────────────────────────────────────────────
Option 1 — Direct transfer:
  1. Copy app-debug.apk to your phone via USB or Google Drive
  2. On your phone go to Settings → Security → Allow unknown sources
  3. Tap the APK file to install

Option 2 — Via Android Studio:
  1. Connect phone via USB
  2. Enable "USB Debugging" in phone's Developer Options
  3. Press the ▶ Run button in Android Studio

──────────────────────────────────────────────────────────────────
STEP E — Build Release APK (for Google Play)
──────────────────────────────────────────────────────────────────
1. Build → Generate Signed Bundle / APK
2. Choose APK
3. Create a new keystore (keep it safe — you need it forever)
4. Fill in the details and build
5. Upload the signed APK to Google Play Console

──────────────────────────────────────────────────────────────────
TROUBLESHOOTING
──────────────────────────────────────────────────────────────────
• Gradle sync fails?
  → File → Invalidate Caches → Restart

• SDK not found?
  → File → Project Structure → SDK Location
  → Set Android SDK path (usually C:\Users\YOU\AppData\Local\Android\Sdk)

• App shows blank screen?
  → Check your APP_URL is correct and accessible
  → Make sure your server has HTTPS (not just HTTP)

• Need to change the domain later?
  → Edit: finflow-android\capacitor.config.json
  → Change the "url" field
  → Run: cd finflow-android && npx cap sync android
  → Rebuild in Android Studio
TXT
ok "Build instructions saved to ANDROID_BUILD_INSTRUCTIONS.txt"

# ── Final summary ────────────────────────────────────────────
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║              ✅  Setup Complete!                         ║${NC}"
echo -e "${CYAN}╠══════════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║                                                          ║${NC}"
echo -e "${CYAN}║  App URL  : ${APP_URL}${NC}"
echo -e "${CYAN}║  App ID   : ${APP_ID}${NC}"
echo -e "${CYAN}║  Project  : finflow-android/android                     ║${NC}"
echo -e "${CYAN}║                                                          ║${NC}"
echo -e "${CYAN}║  ✅ Capacitor installed                                  ║${NC}"
echo -e "${CYAN}║  ✅ Android project generated                            ║${NC}"
echo -e "${CYAN}║  ✅ Dark theme applied                                   ║${NC}"
echo -e "${CYAN}║  ✅ Splash screen configured                             ║${NC}"
echo -e "${CYAN}║  ✅ Camera & internet permissions added                  ║${NC}"
echo -e "${CYAN}║                                                          ║${NC}"
echo -e "${CYAN}║  👉 NEXT STEP:                                           ║${NC}"
echo -e "${CYAN}║  Read: ANDROID_BUILD_INSTRUCTIONS.txt                   ║${NC}"
echo -e "${CYAN}║  Then open Android Studio and build your APK!           ║${NC}"
echo -e "${CYAN}║                                                          ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
