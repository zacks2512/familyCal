# Complete Google Sign-In Setup Guide

## Your Information

```
Project ID: familycal-3b3a9
Package Name: com.example.familycal
SHA-1: 40:15:3E:A1:92:1E:73:18:F7:82:E7:24:E5:F1:7D:33:C8:0B:BB:E1
```

## Why It's Not Working Now

Your `google-services.json` has empty `oauth_client`:

```json
"oauth_client": [],  // ❌ Empty - This is the problem!
```

**Solution**: Add your SHA-1 fingerprint to Firebase Console → it will auto-populate the oauth_client → download new google-services.json

---

## Step-by-Step Fix (5 minutes)

### 1️⃣ Open Firebase Console

URL: https://console.firebase.google.com/project/familycal-3b3a9/settings/general

(or: Firebase Console → Projects → familycal-3b3a9 → Settings)

### 2️⃣ Go to Project Settings

- Look for ⚙️ **Settings** icon (top-left area)
- Click it
- You should see: "Project settings"

### 3️⃣ Find Your Android App

In the Project settings page:
- Look for **"Your apps"** tab
- You should see an Android app entry
- It should show: `com.example.familycal`

Click on the Android app to expand/edit it.

### 4️⃣ Add SHA-1 Fingerprint

In the Android app configuration section:
- Look for **"SHA certificate fingerprints"**
- Click **"Add fingerprint"** button
- Paste your SHA-1 exactly:

```
40:15:3E:A1:92:1E:73:18:F7:82:E7:24:E5:F1:7D:33:C8:0B:BB:E1
```

- Click **Save**

### 5️⃣ Download New google-services.json

After adding the fingerprint:
- Scroll down in the same Android app section
- Click **"Download google-services.json"** button
- A file will download

### 6️⃣ Replace the File

```bash
# Backup old one (optional)
cp android/app/google-services.json android/app/google-services.json.bak

# Replace with new one
# Move the downloaded google-services.json to:
# android/app/google-services.json
```

**The new file should have oauth_client populated!**

### 7️⃣ Enable Google in Authentication

Still in Firebase Console:
- Go to **Authentication** (left sidebar)
- Click **Sign-in method** tab
- Find **Google** in the list
- Toggle the switch to **Enable** (blue)
- Click **Save**

### 8️⃣ Rebuild Flutter App

```bash
cd /home/shani/personalProjects/familycal

# Clean everything
flutter clean
rm -rf build/
rm pubspec.lock

# Get dependencies again
flutter pub get

# Rebuild
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
flutter run -d R5CW13J241L
```

---

## Verify It Works

After rebuild:

1. **Welcome Screen** → Tap "Register"
2. **Register Options** → Tap "Continue with Google"
3. **Google Dialog** should appear (NO RED ERROR!)
4. Sign in with your Google account
5. ✅ Redirects to Family Setup

---

## Visual Checklist

- ✅ SHA-1 added to Firebase Console
- ✅ New google-services.json downloaded
- ✅ google-services.json has populated oauth_client (not empty [])
- ✅ Google enabled in Authentication → Sign-in method
- ✅ Flutter app rebuilt (flutter clean)

---

## Troubleshooting

### Still Getting Error 10?

**Check these:**

1. **Is the new google-services.json in the right place?**
   ```bash
   cat android/app/google-services.json | grep oauth_client
   ```
   Should NOT be empty `[]`

2. **Was Flutter rebuilt?**
   ```bash
   flutter clean
   flutter run -d R5CW13J241L
   ```

3. **Is Google enabled in Authentication?**
   Go to Firebase Console → Authentication → Sign-in method → Google should be BLUE

### The google-services.json Still Shows Empty oauth_client?

This means the SHA-1 wasn't added correctly. Go back to step 4:
- Make sure SHA-1 is pasted **exactly** with colons
- Verify package name is `com.example.familycal`
- Click Save before downloading

### Getting "Web client ID not found"?

In Firebase Console:
1. Go to **Authentication** → **Settings**
2. Scroll to "Authorized domains"
3. Make sure your app ID is there

---

## What Happens After Google Sign-In Works

```
User taps "Continue with Google"
         ↓
Google Sign-In Dialog Opens
         ↓
User selects Google account
         ↓
Google authenticates user
         ↓
Firebase receives Google credentials
         ↓
User account created in Firebase Authentication
         ↓
User auto-logged in
         ↓
Redirects to Family Setup
         ↓
Family data saved to Firestore
```

---

## Files Involved

| File | What it does |
|------|-------------|
| `google-services.json` | Contains OAuth client config (MUST be updated) |
| `firebase_auth_service.dart` | Handles Google Sign-In code ✅ (already correct) |
| `welcome_screen.dart` | Shows Google button ✅ (already correct) |
| `pubspec.yaml` | Has google_sign_in dependency ✅ (already added) |

---

## Need Help?

If still not working:

1. **Verify SHA-1 was added:**
   - Firebase Console → Project Settings → Your apps → Android
   - Should show your fingerprint in the list

2. **Verify new google-services.json:**
   - Open `android/app/google-services.json`
   - Search for `oauth_client`
   - Should NOT be empty `[]`
   - Should have entries like: `"client_id", "client_type", etc.`

3. **Check logs:**
   ```bash
   flutter run -d R5CW13J241L 2>&1 | grep -i "google\|oauth\|auth"
   ```

---

## Summary

**Before**: google-services.json had empty oauth_client → Google Sign-In failed  
**After**: SHA-1 added to Firebase → oauth_client populated → Google Sign-In works ✅

The code is already correct. We just need Firebase to know about your device's certificate!

