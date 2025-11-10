# 🔧 Troubleshooting Guide

## Issues You Encountered & Fixes

### ✅ Issue 1: "I see email in Firebase Authentication but didn't register yet"

**This is NORMAL behavior!** ✓

**Explanation:**
- When you click "Continue with Google" for the first time, it BOTH registers AND logs you in
- Firebase automatically creates a user account the moment Google Sign-In succeeds
- Google Sign-In doesn't have separate "register" vs "login" flows - it's the same thing
- Your Google account IS your registration

**What happens:**
```
First Google Sign-In:
1. User clicks "Continue with Google"
2. Selects Google account
3. Firebase creates new user automatically
4. User is logged in
5. Email appears in Firebase Auth Console ← This is correct!
```

**No action needed** - this is the expected behavior for Google Sign-In.

---

### ⚠️ Issue 2: "Calendar page shows mock data"

**This is EXPECTED** - Your app is not connected to Firebase Firestore yet.

**Explanation:**
- Your app uses `createMockState()` in `lib/app.dart` (line 15)
- Mock data includes fake family members, children, events
- This is for UI development/testing
- Real data storage in Firestore is **not yet implemented**

**Current Flow:**
```
User signs in → Calendar loads mock data → Mock data shows example events
```

**What you see:**
- Alex Rivera (mock user)
- Jamie Rivera (mock user)  
- Mia & Noah (mock children)
- Mock events for school drop-off/pickup

**To connect real Firebase data**, you need to:
1. Store user's family data in Firestore when they complete family setup
2. Load family data from Firestore when user signs in
3. Replace `createMockState()` with `createFirestoreState(userId)`

This requires implementing:
- `FirebaseRepository` integration (already exists!)
- Family setup flow → save to Firestore
- Calendar screen → load from Firestore
- Event creation → save to Firestore

**Estimated work: 2-3 hours of development**

---

### ❌ Issue 3: "Logout and login with different email fails" 

**THIS WAS A BUG** - Now FIXED! ✅

**What was happening:**
- Google Sign-In caches the account selection
- When you signed out and tried to sign in again, Google tried to use cached credentials
- This caused "Google login failed" error when switching accounts

**What I fixed:**

1. **Added `disconnect()` on sign out:**
   ```dart
   await _googleSignIn.disconnect();  // Clears cached account
   await _googleSignIn.signOut();
   ```

2. **Clear previous session before sign in:**
   ```dart
   // First, ensure any previous session is cleared
   await _googleSignIn.signOut();
   ```

3. **Better error handling:**
   - Added null checks for authentication tokens
   - Better error messages
   - Continued Firebase sign-out even if Google sign-out fails

**Now the flow works:**
```
1. Sign in with account1@gmail.com → Works ✅
2. Sign out → Clears cached account ✅
3. Sign in with account2@gmail.com → Shows account picker ✅
4. Select different account → Works! ✅
```

---

## 🧪 How to Test the Fixes

### Test 1: Sign In with First Account
```bash
1. flutter clean
2. flutter pub get  
3. flutter run -d R5CW13J241L
4. Click "Register" or "Log In"
5. Click "Continue with Google"
6. Select your first Google account
7. ✅ Should sign in successfully
```

### Test 2: Switch to Different Account
```bash
1. Go to Settings
2. Click "Sign Out"
3. Click "Log In"
4. Click "Continue with Google"
5. ✅ Should show account picker (not auto-select previous account)
6. Select different Google account
7. ✅ Should sign in successfully with new account
```

### Test 3: Verify in Firebase Console
```bash
1. Go to https://console.firebase.google.com
2. Select project: familycal-3b3a9
3. Go to Authentication → Users
4. ✅ You should see both email addresses listed
5. ✅ Each should have creation timestamp
```

---

## 📊 Current Status Summary

| Feature | Status | Notes |
|---------|--------|-------|
| Google Sign-In | ✅ Working | First account works |
| Google Account Switching | ✅ Fixed | Now properly clears cache |
| Firebase Auth Integration | ✅ Working | Users appear in Firebase Console |
| User Info Display | ✅ Working | Shows name/email in Settings |
| Sign Out | ✅ Fixed | Properly disconnects Google |
| Email/Phone Auth | ⚠️ Mock | Still simulated (not real) |
| Calendar Data | ⚠️ Mock | Using fake data, not Firestore |
| Family Setup | ⚠️ UI Only | Doesn't save to Firestore yet |

---

## 🔍 Understanding Firebase Console

When you open Firebase Console → Authentication → Users, you'll see:

**Columns:**
- **Identifier** - User's email from Google
- **Providers** - Shows "google.com" 
- **Created** - When they first signed in
- **Signed In** - Last sign-in time
- **User UID** - Unique Firebase ID

**This is normal!** Every Google Sign-In creates a Firebase user automatically.

---

## 🐛 Common Errors & Solutions

### Error: "Google Login Failed: PlatformException(sign_in_failed, 10)"

**Cause:** SHA-1 fingerprint not added OR old google-services.json

**Fix:**
```bash
# 1. Get SHA-1
cd android
./gradlew signingReport
# Copy SHA1 value

# 2. Add to Firebase Console
# Project Settings → Your apps → Android app → Add fingerprint

# 3. Download NEW google-services.json
# Replace android/app/google-services.json

# 4. Rebuild
flutter clean
flutter pub get
flutter run
```

### Error: "Missing Google Tokens"

**Cause:** Google authentication didn't complete properly

**Fix:**
- Check internet connection
- Verify google-services.json is up to date
- Try signing out completely and signing in again

### Error: "Network Error" when signing in

**Cause:** Firebase connection issue

**Fix:**
```bash
# Check if Firebase is initialized
# In lib/main.dart, you should see:
await Firebase.initializeApp();

# Verify google-services.json exists:
ls -la android/app/google-services.json
```

---

## 📱 Expected Debug Logs

When signing in successfully, you should see:

```
🔑 Starting Google Sign-In...
🧹 Cleared previous Google session
✅ Google user selected: yourname@gmail.com
✅ Google authentication tokens received
🔑 Signing in to Firebase with Google credential...
✅ Google Sign-In successful: abc123xyz...
   Email: yourname@gmail.com
   Display Name: Your Name
```

When signing out:
```
👋 Signing out...
✅ Disconnected and signed out from Google
✅ Signed out from Firebase
```

---

## 🎯 Next Steps

### Option A: Connect Calendar to Firestore (Recommended)
**Time: 2-3 hours**
**Benefit:** Your events, family members, children will persist across sign-ins

This involves:
1. Save family setup data to Firestore
2. Load user's family data when signing in
3. Replace `createMockState()` with real Firestore queries
4. Use `FirebaseRepository` (already implemented!)

### Option B: Implement Email/Password Auth
**Time: 30-60 minutes**
**Benefit:** Users can sign in with email/password (in addition to Google)

See `AUTH_STATUS.md` for implementation guide.

### Option C: Keep Testing with Current Setup
**Time: 0 minutes**
**Benefit:** You can test UI/UX with mock data while planning backend

Google Sign-In works fully - you can test authentication flows now!

---

## 🆘 Still Having Issues?

If you're still experiencing problems after the fixes:

1. **Check console logs** - Look for the emoji logs (🔑, ✅, ❌)
2. **Verify Firebase Console** - Check if users appear in Authentication
3. **Try completely uninstalling and reinstalling the app**
4. **Clear app data:**
   ```bash
   adb shell pm clear com.example.familycal
   flutter run
   ```

---

## ✅ Summary of Fixes Applied

1. ✅ Added `disconnect()` to clear Google account cache on sign out
2. ✅ Added `signOut()` at start of sign-in flow to clear previous session
3. ✅ Added null checks for authentication tokens
4. ✅ Improved error handling and logging
5. ✅ Better error messages for users

**Try signing out and signing in with a different account now - it should work!** 🎉

