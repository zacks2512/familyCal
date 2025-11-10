#!/bin/bash

# FamilyCal - Commands Reference
# A quick reference for all common commands

# ═══════════════════════════════════════════════════════════════════════════
# 🚀 RUN THE APP
# ═══════════════════════════════════════════════════════════════════════════

# Interactive launcher (easiest)
/home/shani/personalProjects/familycal/run_app.sh

# Run on Android phone (replace DEVICE_ID with your device)
cd /home/shani/personalProjects/familycal
/home/shani/flutter/bin/flutter devices                    # List devices
/home/shani/flutter/bin/flutter run -d <DEVICE_ID>       # Run on device

# Run on Android emulator
/home/shani/flutter/bin/flutter emulators --create --name pixel_5
/home/shani/flutter/bin/flutter emulators --launch pixel_5
/home/shani/flutter/bin/flutter run

# Run in release mode (optimized, faster)
/home/shani/flutter/bin/flutter run --release

# Run in verbose mode (see detailed logs)
/home/shani/flutter/bin/flutter run --verbose


# ═══════════════════════════════════════════════════════════════════════════
# 📱 FLUTTER COMMANDS
# ═══════════════════════════════════════════════════════════════════════════

cd /home/shani/personalProjects/familycal

# List connected devices
/home/shani/flutter/bin/flutter devices

# List available emulators
/home/shani/flutter/bin/flutter emulators

# Create emulator
/home/shani/flutter/bin/flutter emulators --create --name pixel_5

# Launch emulator
/home/shani/flutter/bin/flutter emulators --launch pixel_5

# Check system compatibility
/home/shani/flutter/bin/flutter doctor
/home/shani/flutter/bin/flutter doctor -v

# Install dependencies
/home/shani/flutter/bin/flutter pub get

# Update dependencies
/home/shani/flutter/bin/flutter pub upgrade

# Clean build
/home/shani/flutter/bin/flutter clean

# Build APK (Android app file)
/home/shani/flutter/bin/flutter build apk --release

# Build app bundle (for Play Store)
/home/shani/flutter/bin/flutter build appbundle --release


# ═══════════════════════════════════════════════════════════════════════════
# ☁️ FIREBASE & NODE.JS COMMANDS
# ═══════════════════════════════════════════════════════════════════════════

# First, activate nvm and Node.js
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Verify Node versions
node --version
npm --version

# Firebase CLI
firebase --version
firebase projects:list

# Deploy everything
firebase deploy

# Deploy only functions
firebase deploy --only functions

# Deploy only Firestore rules
firebase deploy --only firestore:rules

# Deploy only indexes
firebase deploy --only firestore:indexes

# Deploy with cleanup policy setup
firebase deploy --only functions --force

# View function logs
firebase functions:log

# Query Firestore
firebase firestore:get /families
firebase firestore:get /families/FAMILY_ID/events

# Initialize emulators (for local testing)
firebase emulators:start

# List all deployed functions
firebase functions:list

# Test specific function
firebase functions:call onEventAssignment --data '{"familyId":"123","eventId":"456"}'


# ═══════════════════════════════════════════════════════════════════════════
# 🔐 GIT COMMANDS
# ═══════════════════════════════════════════════════════════════════════════

cd /home/shani/personalProjects/familycal

# Check status
git status

# View changes
git diff

# Stage changes
git add .
git add <file>

# Commit
git commit -m "Your message here"

# Push to remote
git push origin main

# View logs
git log --oneline
git log --graph --all

# Create branch
git checkout -b feature/my-feature

# Switch branch
git checkout main

# Merge branch
git merge feature/my-feature


# ═══════════════════════════════════════════════════════════════════════════
# 🏗️ BUILD & ARCHITECTURE COMMANDS
# ═══════════════════════════════════════════════════════════════════════════

cd /home/shani/personalProjects/familycal

# Analyze dependencies
/home/shani/flutter/bin/flutter pub deps

# Check for outdated dependencies
/home/shani/flutter/bin/flutter pub outdated

# Check code quality
/home/shani/flutter/bin/flutter analyze

# Format code
/home/shani/flutter/bin/flutter format lib/

# Run tests
/home/shani/flutter/bin/flutter test


# ═══════════════════════════════════════════════════════════════════════════
# 📊 MONITORING & DEBUGGING
# ═══════════════════════════════════════════════════════════════════════════

# View app logs
/home/shani/flutter/bin/flutter logs

# Take screenshot from device
/home/shani/flutter/bin/flutter screenshot

# Hot reload during development (press 'r' in terminal)
# Hot restart during development (press 'R' in terminal)

# View Firebase function logs
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
firebase functions:log

# View Firestore usage
firebase firestore:usage


# ═══════════════════════════════════════════════════════════════════════════
# 🧹 CLEANUP & MAINTENANCE
# ═══════════════════════════════════════════════════════════════════════════

cd /home/shani/personalProjects/familycal

# Clean Flutter build
/home/shani/flutter/bin/flutter clean

# Remove pubspec lock and reinstall
rm pubspec.lock
/home/shani/flutter/bin/flutter pub get

# Clean Android build
cd android
./gradlew clean
cd ..

# Remove build artifacts
rm -rf build/
rm -rf .dart_tool/


# ═══════════════════════════════════════════════════════════════════════════
# 📦 APK & DISTRIBUTION
# ═══════════════════════════════════════════════════════════════════════════

cd /home/shani/personalProjects/familycal

# Build release APK
/home/shani/flutter/bin/flutter build apk --release

# APK location
# build/app/outputs/flutter-apk/app-release.apk

# Sign APK (if not already signed)
jarsigner -verbose -sigalg SHA1withRSA -digestalg SHA1 \
  -keystore ~/my-release-key.keystore \
  build/app/outputs/flutter-apk/app-release.apk alias_name

# Build app bundle for Play Store
/home/shani/flutter/bin/flutter build appbundle --release

# App bundle location
# build/app/outputs/bundle/release/app-release.aab


# ═══════════════════════════════════════════════════════════════════════════
# 🚨 TROUBLESHOOTING
# ═══════════════════════════════════════════════════════════════════════════

# If app won't run
cd /home/shani/personalProjects/familycal
/home/shani/flutter/bin/flutter clean
/home/shani/flutter/bin/flutter pub get
/home/shani/flutter/bin/flutter run --verbose

# If devices not found
/home/shani/flutter/bin/flutter doctor -v
adb devices

# If build fails
cd /home/shani/personalProjects/familycal/android
./gradlew clean
cd ..
/home/shani/flutter/bin/flutter pub get
/home/shani/flutter/bin/flutter run

# If Firebase not connecting
# Check google-services.json exists
ls -la /home/shani/personalProjects/familycal/android/app/google-services.json

# Check Firebase CLI login
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
firebase projects:list


# ═══════════════════════════════════════════════════════════════════════════
# 💡 TIPS & SHORTCUTS
# ═══════════════════════════════════════════════════════════════════════════

# Create an alias for easier access
alias familycal='cd /home/shani/personalProjects/familycal'
alias fcal_run='/home/shani/personalProjects/familycal/run_app.sh'
alias fcal_flutter='/home/shani/flutter/bin/flutter'
alias fcal_deploy='export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" && firebase deploy'

# Then use:
# familycal                    # Go to project
# fcal_run                     # Run the app
# fcal_flutter run             # Run Flutter
# fcal_deploy                  # Deploy Firebase


# ═══════════════════════════════════════════════════════════════════════════
# 📞 USEFUL LINKS
# ═══════════════════════════════════════════════════════════════════════════

# Firebase Console
# https://console.firebase.google.com/project/familycal-3b3a9/overview

# Firestore
# https://console.firebase.google.com/project/familycal-3b3a9/firestore/data

# Cloud Functions
# https://console.firebase.google.com/project/familycal-3b3a9/functions/list

# Authentication
# https://console.firebase.google.com/project/familycal-3b3a9/authentication/users

# Billing
# https://console.firebase.google.com/project/familycal-3b3a9/usage/database


echo "✅ FamilyCal Commands Reference Loaded"
echo "See this file for all available commands"

