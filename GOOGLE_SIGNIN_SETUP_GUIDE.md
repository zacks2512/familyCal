# 🔐 Google Sign-In Setup Guide for FamilyCal

## ✅ What I've Already Done (Code Side)

1. ✅ Added `google_sign_in: ^6.2.1` to `pubspec.yaml`
2. ✅ Implemented `signInWithGoogle()` method in `firebase_auth_service.dart`
3. ✅ Updated `signOut()` to handle Google sign-out

---

## 🚀 What YOU Need to Do (Firebase Console Setup)

Follow these steps **in order**. This should take about 5-10 minutes.

---

### **Step 1: Get Your SHA-1 Fingerprint** 🔑

Your app needs to be verified by Google. This is done using an SHA-1 fingerprint.

**Run this command in your terminal:**

```bash
cd ~/personalProjects/familycal/android
./gradlew signingReport
```

**What to look for:**
The output will show something like:

```
Variant: debug
Config: debug
Store: ~/.android/debug.keystore
Alias: AndroidDebugKey
MD5: XX:XX:XX:...
SHA1: 40:15:3E:A1:92:1E:73:18:F7:82:E7:24:E5:F1:7D:33:C8:0B:BB:E1
SHA-256: XX:XX:XX:...
```

**Copy the SHA1 value** (the long string with colons).

> 📝 **Note**: Based on your previous setup [[memory:11031467]], your SHA-1 was:  
> `40:15:3E:A1:92:1E:73:18:F7:82:E7:24:E5:F1:7D:33:C8:0B:BB:E1`  
> Run the command above to verify it's still the same.

---

### **Step 2: Open Firebase Console** 🌐

1. Go to: **https://console.firebase.google.com**
2. Select your project: **`familycal-3b3a9`**
3. Click on **⚙️ Settings** (gear icon) → **Project settings**

---

### **Step 3: Add SHA-1 Fingerprint to Firebase** 📝

1. In **Project settings**, scroll down to **"Your apps"** section
2. Find your Android app: `com.example.familycal`
3. Click **"Add fingerprint"** button
4. Paste your **SHA-1** fingerprint
5. Click **"Save"**

**Visual guide:**
```
Project Settings
  └─ Your apps
      └─ Android app (com.example.familycal)
          └─ SHA certificate fingerprints
              └─ [+ Add fingerprint] ← Click here
                  ↓
              Paste: 40:15:3E:A1:92:1E:73:18:F7:82:E7:24:E5:F1:7D:33:C8:0B:BB:E1
              [Save]
```

---

### **Step 4: Enable Google Sign-In Provider** 🔓

1. In Firebase Console, go to **Authentication** (left sidebar)
2. Click on **"Sign-in method"** tab
3. Click on **"Google"** in the providers list
4. Toggle **"Enable"** to ON
5. **Select a support email** (your email)
6. Click **"Save"**

**Visual guide:**
```
Authentication
  └─ Sign-in method
      └─ Native providers
          └─ Google [Disabled] ← Click this
              ↓
          [Enable toggle: ON]
          Project support email: [your-email@example.com]
          [Save]
```

---

### **Step 5: Download Updated google-services.json** 📥

This is **CRITICAL** - the old file doesn't have Google OAuth credentials!

1. Still in **Project settings** → **Your apps**
2. Find your Android app: `com.example.familycal`
3. Click **"google-services.json"** download button
4. Save the file

**Visual guide:**
```
Project Settings
  └─ Your apps
      └─ Android app (com.example.familycal)
          └─ [google-services.json] ← Click to download
```

---

### **Step 6: Replace google-services.json** 🔄

Replace the old file with the new one:

```bash
# From your Downloads folder (or wherever you saved it)
mv ~/Downloads/google-services.json ~/personalProjects/familycal/android/app/google-services.json
```

**Or manually:**
1. Delete: `~/personalProjects/familycal/android/app/google-services.json`
2. Copy the new `google-services.json` you just downloaded to that location

---

### **Step 7: Clean and Rebuild** 🧹

Run these commands to apply the changes:

```bash
cd ~/personalProjects/familycal
flutter clean
flutter pub get
flutter run -d R5CW13J241L
```

This will:
1. Clean old build files
2. Download the `google_sign_in` package
3. Rebuild with new Google configuration
4. Run on your device

---

## 🎯 How to Test

Once the app is running, you should be able to:

1. Call `FirebaseAuthService().signInWithGoogle()` in your UI
2. See the Google account picker
3. Sign in successfully
4. See debug logs:
   ```
   🔑 Starting Google Sign-In...
   ✅ Google user selected: user@gmail.com
   ✅ Google authentication tokens received
   🔑 Signing in to Firebase with Google credential...
   ✅ Google Sign-In successful: [user-id]
   ```

---

## ❓ Troubleshooting

### Error: `PlatformException(sign_in_failed, 10, null, null)`

**Cause**: SHA-1 fingerprint not added OR google-services.json not updated

**Fix**: 
- Verify Step 3 (SHA-1 added to Firebase)
- Verify Step 6 (new google-services.json downloaded and replaced)
- Verify Step 7 (flutter clean and rebuild)

### Error: `The Google Sign-In flow cancelled by user`

**Cause**: User clicked back or closed the Google account picker

**Fix**: This is normal - just means the user cancelled

### Error: `google_sign_in package not found`

**Cause**: Package not installed

**Fix**: Run `flutter pub get`

---

## 📋 Quick Checklist

Before you run the app, make sure:

- [ ] SHA-1 fingerprint added to Firebase Console
- [ ] Google provider enabled in Firebase Authentication
- [ ] New `google-services.json` downloaded from Firebase
- [ ] New `google-services.json` replaced the old one at `android/app/google-services.json`
- [ ] Ran `flutter clean`
- [ ] Ran `flutter pub get`
- [ ] Rebuilt the app

---

## 🎉 Success!

Once these steps are complete, Google Sign-In will work perfectly in your app!

The updated `google-services.json` will have the `oauth_client` array populated, which is what makes Google Sign-In work.

**Need help?** Let me know which step you're stuck on!

