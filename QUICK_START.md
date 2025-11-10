# ⚡ Quick Start Guide

Get FamilyCal running in 5 minutes!

## 🚀 Setup Commands

```bash
# 1. Install Flutter dependencies
flutter pub get

# 2. Install Firebase CLI
npm install -g firebase-tools

# 3. Login to Firebase
firebase login

# 4. Initialize Firebase (if not done)
firebase init

# Select:
# - Firestore (Database, Rules, Indexes)
# - Functions
# - Emulators (optional for local dev)

# 5. Install Cloud Functions dependencies
cd functions
npm install
cd ..

# 6. Deploy Firestore rules and indexes
firebase deploy --only firestore:rules,firestore:indexes

# 7. Deploy Cloud Functions
firebase deploy --only functions
```

---

## 🏃 Run Locally (Development)

### Option 1: With Firebase Emulators (Recommended)

```bash
# Terminal 1: Start emulators
firebase emulators:start

# Terminal 2: Run Flutter app
flutter run

# Note: App will automatically connect to local emulators
```

### Option 2: With Production Firebase

```bash
# Just run the app
flutter run

# Or for release mode
flutter run --release
```

---

## 📱 Platform-Specific Setup

### iOS

```bash
# Install CocoaPods dependencies
cd ios
pod install
cd ..

# Run on iOS simulator
flutter run -d "iPhone 15 Pro"

# Or on physical device
flutter run -d "Your iPhone Name"
```

**Required Files:**
- ✅ `ios/Runner/GoogleService-Info.plist` (download from Firebase Console)
- ✅ iOS Deployment Target: 15.0+
- ✅ Calendar and Notification permissions in Info.plist

### Android

```bash
# Run on Android emulator
flutter run -d emulator-5554

# Or on physical device
flutter run -d "Your Android Device"
```

**Required Files:**
- ✅ `android/app/google-services.json` (download from Firebase Console)
- ✅ minSdkVersion: 23
- ✅ Calendar and Notification permissions in AndroidManifest.xml

---

## 🧪 Test the Implementation

### 1. Test Authentication

```bash
# Run the app
flutter run

# In app:
# 1. Sign up with email/password
# 2. Verify Firebase Console > Authentication shows new user
```

### 2. Test Calendar Sync

```bash
# In app:
# 1. Create a family
# 2. Add a child
# 3. Create an event and assign to yourself
# 4. Grant calendar permission when prompted
# 5. Open device Calendar app
# 6. Verify event appears
```

### 3. Test Notifications

```bash
# In app (need 2 devices/emulators):
# Device 1:
# 1. Create event and assign to Device 2 user
# 
# Device 2:
# 2. Should receive "You're responsible for..." notification
# 3. Tap notification
# 4. Verify app opens to event
```

### 4. Test Offline Mode

```bash
# In app:
# 1. Create an event
# 2. Enable Airplane Mode
# 3. Confirm the event
# 4. Disable Airplane Mode
# 5. Wait 5 seconds
# 6. Check Firebase Console > Firestore
# 7. Verify confirmation appears
```

### 5. Test Cloud Functions Locally

```bash
# Terminal 1: Start emulators
firebase emulators:start

# Terminal 2: Test function
curl -X POST http://localhost:5001/YOUR_PROJECT/us-central1/onEventAssignment \
  -H "Content-Type: application/json" \
  -d '{
    "familyId": "test",
    "eventId": "test123",
    "type": "assigned"
  }'

# Check emulator logs for output
```

---

## 🐛 Common Issues & Fixes

### Issue: "Firebase not initialized"

**Fix:**
```dart
// In main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Add this
  runApp(MyApp());
}
```

### Issue: "Calendar permission denied"

**Fix iOS:**
```xml
<!-- In ios/Runner/Info.plist -->
<key>NSCalendarsUsageDescription</key>
<string>FamilyCal needs calendar access to sync events</string>
```

**Fix Android:**
```xml
<!-- In android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.READ_CALENDAR" />
<uses-permission android:name="android.permission.WRITE_CALENDAR" />
```

### Issue: "Notifications not showing"

**Fix iOS:**
```bash
# Make sure you've:
# 1. Uploaded APNs key to Firebase Console
# 2. Enabled Push Notifications capability in Xcode
# 3. Run on physical device (notifications don't work on iOS simulator)
```

**Fix Android:**
```bash
# Make sure you've:
# 1. Added POST_NOTIFICATIONS permission to AndroidManifest.xml
# 2. Requested notification permission at runtime
```

### Issue: "Firestore permission denied"

**Fix:**
```bash
# Redeploy security rules
firebase deploy --only firestore:rules

# Check rules allow your operation
# Common issue: user not in family.member_ids
```

### Issue: "Cloud Functions not triggering"

**Fix:**
```bash
# Check function logs
firebase functions:log

# Redeploy functions
firebase deploy --only functions

# Verify function exists in Firebase Console
```

---

## 📊 View Data in Firebase Console

### Firestore Data

```bash
# Open in browser
open https://console.firebase.google.com/project/YOUR_PROJECT/firestore
```

**Check:**
- ✅ `families` collection has your family
- ✅ `users` collection has your user
- ✅ `families/{id}/children` has children
- ✅ `families/{id}/events` has events
- ✅ `families/{id}/confirmations` has confirmations

### Cloud Functions Logs

```bash
# View in terminal
firebase functions:log

# Or in browser
open https://console.firebase.google.com/project/YOUR_PROJECT/functions
```

### FCM Tokens

```bash
# Check user document in Firestore
# Should see fcm_tokens object with device entries
```

---

## 🎯 Development Workflow

### 1. Start Local Development

```bash
# Terminal 1: Firebase emulators
firebase emulators:start

# Terminal 2: Flutter hot reload
flutter run
```

### 2. Make Changes

```dart
// Edit Dart files
// Save (hot reload automatically triggers)
```

### 3. Update Cloud Functions

```bash
# Edit functions/index.js
# Redeploy
cd functions
npm run deploy
```

### 4. Update Firestore Rules

```bash
# Edit firestore.rules
# Deploy
firebase deploy --only firestore:rules
```

### 5. Test on Real Device

```bash
# iOS
flutter run -d "Your iPhone"

# Android  
flutter run -d "Your Android Phone"
```

---

## 🚀 Deploy to Production

### 1. Build App

```bash
# iOS
flutter build ipa --release

# Android
flutter build appbundle --release
```

### 2. Deploy Backend

```bash
# Deploy everything
firebase deploy

# Or specific services
firebase deploy --only firestore,functions
```

### 3. Distribute

**iOS:**
- Upload IPA to TestFlight via Xcode/Transporter
- Submit for review

**Android:**
- Upload AAB to Google Play Console
- Create release

---

## 📝 Environment Variables

Create `.env` file in project root:

```bash
# Firebase (client-side)
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_APP_ID=your_app_id

# Optional
SENTRY_DSN=your_sentry_dsn
```

**Note:** These are automatically in GoogleService files, but useful for CI/CD.

---

## ✅ Pre-Launch Checklist

Before deploying to production:

### Backend
- [ ] Firebase project created
- [ ] Billing enabled (Blaze plan)
- [ ] Budget alerts configured ($50/month)
- [ ] Firestore rules deployed
- [ ] Firestore indexes created
- [ ] Cloud Functions deployed
- [ ] Function logs reviewed for errors

### Mobile App
- [ ] iOS config file added
- [ ] Android config file added
- [ ] Calendar permissions configured
- [ ] Notification permissions configured
- [ ] Biometric auth tested
- [ ] Tested on iOS physical device
- [ ] Tested on Android physical device
- [ ] Offline mode tested
- [ ] Calendar sync verified

### Documentation
- [ ] Privacy policy written
- [ ] Terms of service written
- [ ] App store descriptions ready
- [ ] Screenshots prepared

---

## 🎉 You're Ready!

Run this command to start:

```bash
flutter pub get && flutter run
```

For issues, check `IMPLEMENTATION_GUIDE.md` for detailed troubleshooting!

