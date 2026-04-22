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
