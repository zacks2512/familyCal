# 🚀 Quick Google Sign-In Setup Checklist

## Your SHA-1 Fingerprint
```
40:15:3E:A1:92:1E:73:18:F7:82:E7:24:E5:F1:7D:33:C8:0B:BB:E1
```

---

## ✅ Firebase Console Steps (Do These)

### Step 1: Add SHA-1 to Firebase
- [ ] Go to: https://console.firebase.google.com/project/familycal-3b3a9/settings/general
- [ ] Click ⚙️ **Settings** → **Project Settings**
- [ ] Find **"Your apps"** tab
- [ ] Click the **Android app** (com.example.familycal)
- [ ] Find **"SHA certificate fingerprints"**
- [ ] Click **"Add fingerprint"**
- [ ] Paste: `40:15:3E:A1:92:1E:73:18:F7:82:E7:24:E5:F1:7D:33:C8:0B:BB:E1`
- [ ] Click **Save**

### Step 2: Download New google-services.json
- [ ] Scroll down in the same Android app section
- [ ] Click **"Download google-services.json"**
- [ ] Replace: `android/app/google-services.json` with the new file

### Step 3: Enable Google Sign-In
- [ ] Go to **Authentication** (left sidebar)
- [ ] Click **Sign-in method**
- [ ] Find **Google**
- [ ] Toggle switch to **Enable** (should be blue)
- [ ] Click **Save**

---

## ✅ Local Steps (After Firebase Changes)

```bash
# 1. Clean everything
cd /home/shani/personalProjects/familycal
flutter clean
rm -rf build/

# 2. Get fresh dependencies
flutter pub get

# 3. Rebuild app
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
flutter run -d R5CW13J241L
```

---

## ✅ Verify It Works

1. **App loads** → Welcome screen appears
2. **Tap "Register"** → Register options screen
3. **Tap "Continue with Google"** → Google dialog appears (NO ERROR!)
4. **Sign in with Google account** → Proceeds to Family Setup ✅

---

## 📋 Verification Checklist

After everything:

- [ ] google-services.json downloaded from Firebase
- [ ] File is at: `android/app/google-services.json`
- [
    
 ] Open the file, search for `"oauth_client"` - should NOT be empty `[]`
- [ ] Flutter rebuilt with `flutter clean`
- [ ] No red errors when clicking Google button
- [ ] Google dialog appears when tapping "Continue with Google"

---

## ❌ If Still Not Working

**Check:**
1. Is SHA-1 in Firebase Console? (Project Settings → Your apps → Android)
2. Is the NEW google-services.json file saved in android/app/?
3. Did you run `flutter clean`?
4. Is Google enabled in Authentication → Sign-in method?

**If all ✅ but still error:**
```bash
flutter clean
rm pubspec.lock
flutter pub get
flutter run -d R5CW13J241L
```

---

## 🎯 That's It!

The code is already correct. You just need to:
1. Add SHA-1 to Firebase Console ✅
2. Download new google-services.json ✅
3. Enable Google in Authentication ✅
4. Rebuild app ✅

Then Google Sign-In will work! 🎉

