# FamilyCal Setup Status

## ✅ COMPLETED STEPS

### 1. Android Configuration
- ✅ `google-services.json` file in place
- ✅ Google Services plugin configured in both gradle files  
- ✅ Android permissions added to AndroidManifest.xml (Calendar, Notifications, Biometric, Internet)
- ✅ SDK versions set (minSdk: 23, compileSdk: 34, targetSdk: 34)

### 2. App Code
- ✅ Firebase initialization added to `main.dart`
- ✅ All Firebase service files exist and are implemented:
  - `firebase_repository.dart` 
  - `calendar_sync_service.dart`
  - `notification_service.dart`
  - `offline_queue_service.dart`

### 3. Backend Code
- ✅ Firestore security rules created (`firestore.rules`)
- ✅ Cloud Functions implemented (`functions/index.js`)
- ✅ Firebase config files in place (`.firebaserc`, `firebase.json`)

## ⚠️ BLOCKER: Node.js Version Too Old

**Current Issue:** Your Node.js version is 4.9.1, but Firebase CLI requires **Node.js 20+**

### Quick Fix (Choose ONE):

**Option A: Install nvm (Node Version Manager) - RECOMMENDED**
```bash
# 1. Install nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# 2. Reload your shell configuration
source ~/.bashrc
# or if you use zsh: source ~/.zshrc

# 3. Install Node 20
nvm install 20

# 4. Use Node 20
nvm use 20

# 5. Set it as default
nvm alias default 20

# 6. Verify
node --version  # Should show v20.x.x
npm --version   # Should show 10.x.x or higher
```

**Option B: System Package Manager**
```bash
# For Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify
node --version
npm --version
```

## 📋 REMAINING STEPS (After Node.js Update)

### Step 1: Install Firebase CLI
```bash
npm install -g firebase-tools
```

### Step 2: Login to Firebase
```bash
firebase login
```

### Step 3: Link Firebase Project
```bash
cd /home/shani/personalProjects/familycal
firebase use --add
# Select your project: familycal-3b3a9
# Give it an alias like "production"
```

### Step 4: Install Cloud Functions Dependencies
```bash
cd functions
npm install
cd ..
```

### Step 5: Install Flutter Dependencies
```bash
flutter pub get
```

### Step 6: Deploy Firebase Backend
```bash
# Deploy Firestore Security Rules
firebase deploy --only firestore:rules

# Deploy Firestore Indexes  
firebase deploy --only firestore:indexes

# Deploy Cloud Functions (takes 5-10 minutes)
firebase deploy --only functions
```

### Step 7: Run the App (Android Only for now)
```bash
# Check connected devices
flutter devices

# Run on Android emulator or device
flutter run
```

## 🍎 iOS Development Note

**You're on Linux**, so iOS development requires:
- A Mac computer with Xcode
- Or skip iOS for now and focus on Android
- Or use a CI/CD service for iOS builds

The iOS configuration steps (13-19) can be done later if you get access to a Mac.

## ✅ What's Ready

1. ✅ Your Flutter app code is complete
2. ✅ Android configuration is done
3. ✅ Firebase backend code is ready
4. ✅ All service implementations are in place

## 🎯 Next Action

**UPDATE NODE.JS** using one of the methods above, then continue with the remaining steps!


