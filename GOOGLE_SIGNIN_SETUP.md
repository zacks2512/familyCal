# Google Sign-In Setup Guide

## Current Status

✅ **Email/Password signup is WORKING** - Use this for now!
❌ **Google Sign-In needs configuration** (Error code 10)

## Why Google Sign-In Fails

Error: `PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10 : , null, null)`

This means:
- Google Play Services is not properly configured
- SHA-1 certificate fingerprint needs to be registered in Firebase

## How to Fix Google Sign-In

### Step 1: Get Your SHA-1 Certificate Fingerprint

Run this command:
```bash
cd /home/shani/personalProjects/familycal
./gradlew signingReport
```

Or manually:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Look for: `SHA1: XX:XX:XX:XX:...`

### Step 2: Add to Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **familycal-3b3a9**
3. Go to **Authentication** → **Sign-in method** → **Google**
4. Enable Google Sign-In if not already enabled
5. Go to **Project Settings** → **Your apps** → **Android**
6. Add your SHA-1 fingerprint to the app configuration
7. Download updated `google-services.json`
8. Replace `android/app/google-services.json`

### Step 3: Rebuild

```bash
cd /home/shani/personalProjects/familycal
flutter clean
flutter run -d R5CW13J241L
```

## For Now: Use Email Registration

✅ **This works immediately!**

1. Click "Register with Email or Phone"
2. Enter email and password
3. Account is created in Firebase
4. Automatically proceeds to family setup

## Current Implementation

### Files Updated:
- `lib/services/firebase_auth_service.dart` - Real Firebase auth
- `lib/screens/auth/signup_screen.dart` - Email registration with password
- `lib/screens/auth/welcome_screen.dart` - Google Sign-In (needs config)
- `pubspec.yaml` - Added `google_sign_in: ^6.2.1`
- `lib/main.dart` - Firebase initialization
- `lib/firebase_options.dart` - Firebase configuration

### Email Registration Flow:
1. User enters: Name, Email, Password
2. Firebase creates account
3. User is authenticated
4. App navigates to Family Setup
5. All data syncs to Firestore

## Quick Test

Try registering with:
- Email: `test@example.com`
- Password: `password123`

Then check [Firestore Console](https://console.firebase.google.com/project/familycal-3b3a9/firestore) to see your data!

---

## Next: Optional Social Login Setup

After you confirm email signup works, you can:
1. Get SHA-1 fingerprint
2. Add to Firebase
3. Google Sign-In will work automatically
4. Optional: Add Facebook Sign-In (requires additional setup)

