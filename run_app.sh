#!/bin/bash

# FamilyCal App Runner Script
# This script sets up the environment and runs the Flutter app

set -e

echo "🚀 FamilyCal App Launcher"
echo "========================="
echo ""

# Activate nvm and Node.js
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    . "$NVM_DIR/nvm.sh"
fi

# Navigate to project
cd /home/shani/personalProjects/familycal

# Check if devices are connected
echo "📱 Checking for connected devices..."
/home/shani/flutter/bin/flutter devices

echo ""
echo "Choose an option:"
echo "1) Run on first device"
echo "2) Create and launch Android emulator"
echo "3) Show available emulators"
echo "4) Deploy backend (Firebase)"
echo "5) View Cloud Functions logs"
echo ""

read -p "Enter your choice (1-5): " choice

case $choice in
    1)
        echo "🏃 Running app on first device..."
        /home/shani/flutter/bin/flutter run
        ;;
    2)
        echo "📲 Creating Android emulator..."
        /home/shani/flutter/bin/flutter emulators --create --name pixel_5
        echo "⏳ Launching emulator..."
        /home/shani/flutter/bin/flutter emulators --launch pixel_5
        sleep 15
        echo "🏃 Running app..."
        /home/shani/flutter/bin/flutter run
        ;;
    3)
        echo "📋 Available emulators:"
        /home/shani/flutter/bin/flutter emulators
        ;;
    4)
        echo "☁️  Deploying Firebase backend..."
        firebase deploy --only functions,firestore:rules
        ;;
    5)
        echo "📊 Cloud Functions logs:"
        firebase functions:log
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "✅ Done!"

