#!/bin/bash

# ============================================================
#  FinFlow → Railway.app Deployment Script
#  Run from: C:\laragon\www\Phone-app\
#  Usage:    bash finflow-railway.sh
# ============================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║   FinFlow → Railway.app Deployment Setup     ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════╝${NC}"
echo ""

step() { echo -e "\n${YELLOW}▶ $1${NC}"; }
ok()   { echo -e "  ${GREEN}✔${NC} $1"; }
info() { echo -e "  ${CYAN}ℹ${NC}  $1"; }
fail() { echo -e "  ${RED}✘${NC} $1"; exit 1; }
warn() { echo -e "  ${YELLOW}⚠${NC}  $1"; }

# ============================================================
# STEP 1 — Check requirements
# ============================================================
step "Step 1/7 — Checking requirements"

command -v git  &>/dev/null && ok "Git found" || fail "Git not found. Install from https://git-scm.com"
command -v php  &>/dev/null && ok "PHP found"  || fail "PHP not found."
command -v composer &>/dev/null && ok "Composer found" || warn "Composer not found globally — will use local"

# ============================================================
# STEP 2 — Prepare Laravel for production
# ============================================================
step "Step 2/7 — Preparing Laravel for production"

# ── Create/update .env.example with Railway-ready placeholders
cat > .env.example << 'ENV'
APP_NAME=FinFlow
APP_ENV=production
APP_KEY=
APP_DEBUG=false
APP_URL=https://your-app.up.railway.app

LOG_CHANNEL=stack
LOG_DEPRECATIONS_CHANNEL=null
LOG_LEVEL=error

DB_CONNECTION=mysql
DB_HOST=${MYSQLHOST}
DB_PORT=${MYSQLPORT}
DB_DATABASE=${MYSQLDATABASE}
DB_USERNAME=${MYSQLUSER}
DB_PASSWORD=${MYSQLPASSWORD}

BROADCAST_DRIVER=log
CACHE_DRIVER=file
FILESYSTEM_DISK=local
QUEUE_CONNECTION=sync
SESSION_DRIVER=file
SESSION_LIFETIME=120

MAIL_MAILER=smtp
MAIL_HOST=smtp.mailtrap.io
MAIL_PORT=2525
MAIL_USERNAME=null
MAIL_PASSWORD=null
MAIL_ENCRYPTION=null
MAIL_FROM_ADDRESS="hello@finflow.app"
MAIL_FROM_NAME="${APP_NAME}"

OPENAI_API_KEY=
ENV
ok ".env.example updated for Railway"

# ── Create Nixpacks config (tells Railway how to build) ──────
cat > nixpacks.toml << 'TOML'
[phases.setup]
nixPkgs = ["php82", "php82Extensions.pdo", "php82Extensions.pdo_mysql",
           "php82Extensions.mbstring", "php82Extensions.xml",
           "php82Extensions.curl", "php82Extensions.zip",
           "php82Extensions.gd", "php82Extensions.bcmath",
           "php82Extensions.tokenizer", "php82Extensions.ctype",
           "composer"]

[phases.install]
cmds = [
  "composer install --no-dev --optimize-autoloader --no-interaction"
]

[phases.build]
cmds = [
  "php artisan config:cache",
  "php artisan route:cache",
  "php artisan view:cache"
]

[start]
cmd = "php artisan migrate --force && php artisan db:seed --force && php -S 0.0.0.0:$PORT -t public"
TOML
ok "nixpacks.toml created"

# ── Create Procfile as fallback ──────────────────────────────
cat > Procfile << 'PROC'
web: php artisan migrate --force && php artisan db:seed --force && php -S 0.0.0.0:$PORT -t public
PROC
ok "Procfile created"

# ── Create railway.json ──────────────────────────────────────
cat > railway.json << 'JSON'
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": {
    "builder": "NIXPACKS"
  },
  "deploy": {
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 3
  }
}
JSON
ok "railway.json created"

# ── Update .gitignore to not ignore .env.example ─────────────
if ! grep -q "!.env.example" .gitignore 2>/dev/null; then
    echo "" >> .gitignore
    echo "# Keep env example for Railway" >> .gitignore
    echo "!.env.example" >> .gitignore
fi

# Make sure storage & bootstrap/cache are tracked
if ! grep -q "storage/app/public" .gitignore 2>/dev/null; then
    echo "" >> .gitignore
    echo "# Keep storage folders" >> .gitignore
    echo "!storage/app/public" >> .gitignore
    echo "!storage/framework/cache" >> .gitignore
    echo "!storage/framework/sessions" >> .gitignore
    echo "!storage/framework/views" >> .gitignore
    echo "!storage/logs" >> .gitignore
fi
ok ".gitignore updated"

# ── Ensure storage folders exist with .gitkeep ──────────────
mkdir -p storage/app/public
mkdir -p storage/framework/cache/data
mkdir -p storage/framework/sessions
mkdir -p storage/framework/views
mkdir -p storage/logs
mkdir -p bootstrap/cache

touch storage/app/public/.gitkeep
touch storage/framework/cache/data/.gitkeep
touch storage/framework/sessions/.gitkeep
touch storage/framework/views/.gitkeep
touch storage/logs/.gitkeep
touch bootstrap/cache/.gitkeep
ok "Storage folders prepared"

# ============================================================
# STEP 3 — Initialize Git repository
# ============================================================
step "Step 3/7 — Setting up Git repository"

if [ ! -d ".git" ]; then
    git init
    ok "Git repository initialized"
else
    ok "Git repository already exists"
fi

# ── Set default branch to main ───────────────────────────────
git checkout -b main 2>/dev/null || git checkout main 2>/dev/null
ok "Branch set to main"

# ── Stage all files ──────────────────────────────────────────
git add -A
git status --short | head -20
ok "All files staged"

# ── Commit ───────────────────────────────────────────────────
git commit -m "🚀 Initial FinFlow deployment to Railway" 2>/dev/null || \
git commit --allow-empty -m "🚀 Deploy FinFlow to Railway"
ok "Initial commit created"

# ============================================================
# STEP 4 — Save manual instructions
# ============================================================
step "Step 4/7 — Generating deployment guide"

cat > RAILWAY_DEPLOY_GUIDE.txt << 'TXT'
╔══════════════════════════════════════════════════════════════════╗
║          FinFlow → Railway.app — Deployment Guide               ║
╚══════════════════════════════════════════════════════════════════╝

The script has prepared your Laravel app for Railway.
Follow these steps to go live:

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 1 — Push code to GitHub
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Go to https://github.com and log in
2. Click the "+" button → "New repository"
3. Name it: finflow
4. Set to PUBLIC (free accounts)
5. Do NOT tick "Initialize with README"
6. Click "Create repository"
7. Copy the repo URL (looks like: https://github.com/YOURNAME/finflow.git)

8. Back in VS Code terminal, run:
   (replace YOUR-GITHUB-USERNAME with your actual username)

   git remote add origin https://github.com/YOUR-GITHUB-USERNAME/finflow.git
   git push -u origin main

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 2 — Create Railway account & project
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Go to https://railway.app
2. Click "Start a New Project"
3. Sign up with GitHub (same account)
4. Click "Deploy from GitHub repo"
5. Select your "finflow" repository
6. Click "Deploy Now"
   → Railway will start building (takes 2-3 minutes)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 3 — Add MySQL database
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. In your Railway project dashboard click "+ New"
2. Select "Database" → "Add MySQL"
3. Railway automatically links the DB to your app ✅
   (The MYSQL* environment variables are auto-injected)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 4 — Set environment variables
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Click your app service (not the MySQL one)
2. Go to "Variables" tab
3. Click "RAW Editor" and paste ALL of these:

APP_NAME=FinFlow
APP_ENV=production
APP_DEBUG=false
APP_KEY=         ← leave blank for now, we'll generate it
SESSION_DRIVER=file
CACHE_DRIVER=file
QUEUE_CONNECTION=sync
LOG_LEVEL=error
OPENAI_API_KEY=your-groq-api-key-here

4. Click "Update Variables"
5. Railway will redeploy automatically

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 5 — Generate APP_KEY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. In VS Code terminal run:
   php artisan key:generate --show

2. Copy the output (looks like: base64:xxxxxxxxxxxx=)
3. Go back to Railway → Variables
4. Find APP_KEY and paste the value
5. Save → Railway redeploys

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 6 — Get your free domain
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. In your app service click "Settings" tab
2. Scroll to "Domains"
3. Click "Generate Domain"
4. You get a URL like:
   https://finflow-production-xxxx.up.railway.app  ✅

5. Copy this URL!
6. Go to Variables → add:
   APP_URL=https://finflow-production-xxxx.up.railway.app
7. Save → redeploy

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 7 — Test your live app
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Open your Railway domain in the browser
2. You should see the FinFlow login page 🎉
3. Register a new account and test it

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
PHASE 8 — Build the Android APK
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Once your app is live:

1. Open finflow-android.sh in Notepad
2. Change line 16 to your Railway URL:
   APP_URL="https://finflow-production-xxxx.up.railway.app"
3. Run: bash finflow-android.sh
4. Follow the Android Studio steps

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
UPDATING YOUR APP IN THE FUTURE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Every time you make changes, just run in VS Code terminal:

  git add -A
  git commit -m "your message"
  git push

Railway auto-deploys within 1-2 minutes! ✅

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
TROUBLESHOOTING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

❌ "500 Server Error" after deploy?
   → Check Railway logs (Deployments → View Logs)
   → Usually means APP_KEY is missing or wrong

❌ "Database connection refused"?
   → Make sure MySQL service is added in Railway
   → Check MYSQL* variables are present in Variables tab

❌ "Class not found" errors?
   → Railway → Deployments → Redeploy
   → Or push an empty commit:
     git commit --allow-empty -m "force redeploy"
     git push

❌ Migrations not running?
   → Railway → your app → click "Deploy" manually
   → Check logs for migration errors

❌ App loads but CSS/JS missing?
   → Add to Variables: ASSET_URL=https://your-app.up.railway.app
TXT

ok "RAILWAY_DEPLOY_GUIDE.txt created"

# ============================================================
# STEP 5 — Generate APP_KEY for convenience
# ============================================================
step "Step 5/7 — Generating APP_KEY"

if command -v php &>/dev/null; then
    APP_KEY=$(php artisan key:generate --show 2>/dev/null)
    if [ -n "$APP_KEY" ]; then
        ok "APP_KEY generated: $APP_KEY"
        echo ""
        echo -e "  ${YELLOW}⚠  Save this key! You'll need it in Railway Variables:${NC}"
        echo -e "  ${CYAN}   APP_KEY=$APP_KEY${NC}"
        echo ""
        # Save to a temp file for easy copy
        echo "APP_KEY=$APP_KEY" > YOUR_APP_KEY.txt
        ok "Also saved to: YOUR_APP_KEY.txt"
    fi
fi

# ============================================================
# STEP 6 — Quick push helper script
# ============================================================
step "Step 6/7 — Creating push helper script"

cat > deploy.sh << 'DEPLOY'
#!/bin/bash
# Quick deploy to Railway
# Usage: bash deploy.sh "your commit message"

MSG=${1:-"Update FinFlow"}
echo "🚀 Deploying: $MSG"
git add -A
git commit -m "$MSG"
git push
echo "✅ Pushed! Railway will auto-deploy in ~2 minutes."
echo "   Watch progress at: https://railway.app/dashboard"
DEPLOY
ok "deploy.sh created — use 'bash deploy.sh' to push future updates"

# ============================================================
# STEP 7 — Final summary
# ============================================================
step "Step 7/7 — Done!"

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║              ✅  Preparation Complete!                   ║${NC}"
echo -e "${CYAN}╠══════════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║                                                          ║${NC}"
echo -e "${CYAN}║  Files created:                                          ║${NC}"
echo -e "${CYAN}║  ✅ nixpacks.toml      — Railway build config           ║${NC}"
echo -e "${CYAN}║  ✅ Procfile           — Start command                  ║${NC}"
echo -e "${CYAN}║  ✅ railway.json       — Railway settings               ║${NC}"
echo -e "${CYAN}║  ✅ .env.example       — Production env template        ║${NC}"
echo -e "${CYAN}║  ✅ YOUR_APP_KEY.txt   — Your APP_KEY (save this!)      ║${NC}"
echo -e "${CYAN}║  ✅ deploy.sh          — Quick push script              ║${NC}"
echo -e "${CYAN}║  ✅ RAILWAY_DEPLOY_GUIDE.txt — Full step-by-step guide  ║${NC}"
echo -e "${CYAN}║                                                          ║${NC}"
echo -e "${CYAN}║  👉 NEXT STEP:                                           ║${NC}"
echo -e "${CYAN}║  Read RAILWAY_DEPLOY_GUIDE.txt and follow Phase 1       ║${NC}"
echo -e "${CYAN}║  (Push to GitHub → Connect Railway → Add MySQL)         ║${NC}"
echo -e "${CYAN}║                                                          ║${NC}"
echo -e "${CYAN}║  After going live, run finflow-android.sh for APK! 📱   ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
