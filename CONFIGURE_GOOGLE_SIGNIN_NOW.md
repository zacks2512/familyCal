# ✅ Configure Google Sign-In - Your SHA-1 Fingerprint

## Your Debug SHA-1 Fingerprint

```
40:15:3E:A1:92:1E:73:18:F7:82:E7:24:E5:F1:7D:33:C8:0B:BB:E1
```

⚠️ **IMPORTANT**: Copy this exactly - include all colons!

---

## Step-by-Step Configuration

### Step 1: Open Firebase Console

1. Go to: https://console.firebase.google.com/
2. Select project: **familycal-3b3a9**

### Step 2: Go to Authentication

1. In left sidebar, click **Authentication**
2. Click on **Sign-in method** tab
3. Look for **Google** in the list

### Step 3: Enable Google Provider (if not already enabled)

1. Click on **Google**
2. Toggle the switch to **Enable** (should be blue)
3. Under "Web SDK configuration", leave default settings
4. Click **Save**

### Step 4: Add Your SHA-1 Fingerprint

1. Go to **Project Settings** (gear icon, top-left)
2. Click on **Your apps** tab
3. Find the app labeled **com.example.familycal** (Android)
4. Click on it to expand

### Step 5: Add Fingerprint

In the Android app section, you should see:
- App ID
- Package name: `com.example.familycal`
- SHA certificate fingerprints section

1. Click **Add fingerprint** button
2. Paste your SHA-1:
   ```
   40:15:3E:A1:92:1E:73:18:F7:82:E7:24:E5:F1:7D:33:C8:0B:BB:E1
   ```
3. Click **Save**

### Step 6: Download Updated google-services.json

1. In the same Project Settings → Your apps section
2. Click the **Android** app
3. Scroll down and click **google-services.json** download button
4. Save it to: `android/app/google-services.json`
5. Replace the existing file

### Step 7: Verify Configuration

Your firebase console should show:
- ✅ Google Sign-In enabled
- ✅ SHA-1 fingerprint registered
- ✅ google-services.json downloaded

---

## Rebuild the App

After adding the fingerprint, run:

```bash
cd /home/shani/personalProjects/familycal
flutter clean
flutter pub get
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
flutter run -d R5CW13J241L
```

---

## Test Google Sign-In

After rebuild:

1. Tap **"Register"** on welcome screen
2. Tap **"Continue with Google"**
3. Google sign-in dialog should appear (no error!)
4. Sign in with your Google account
5. ✅ Account created in Firebase!

---

## Troubleshooting

### Still getting Error 10?

**Possible causes:**
1. Fingerprint not added correctly (missing colons)
2. google-services.json not updated/replaced
3. Need to rebuild app (flutter clean)

**Try:**
```bash
flutter clean
flutter pub get
flutter run -d R5CW13J241L
```

### Error 12: Sign-in canceled

User canceled the Google sign-in - this is normal. Just try again.

### Other errors?

Make sure:
- ✅ Google is enabled in Authentication → Sign-in method
- ✅ SHA-1 is formatted correctly with colons
- ✅ Package name is `com.example.familycal`
- ✅ google-services.json is in `android/app/`

---

## Your Configuration Summary

**Project ID:** familycal-3b3a9  
**App Package:** com.example.familycal  
**SHA-1 Fingerprint:** `40:15:3E:A1:92:1E:73:18:F7:82:E7:24:E5:F1:7D:33:C8:0B:BB:E1`  
**Auth Method:** Google Sign-In  

---

## After Configuration Works

Once Google Sign-In works:
1. Users can sign up with Google account
2. Their Google email becomes their Firebase account
3. They proceed to family setup
4. All data syncs to Firestore

✅ **Everything will be ready!**

