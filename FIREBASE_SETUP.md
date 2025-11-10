# Firebase & Mock Data Setup Guide

## Overview

FamilyCal is configured to connect to Firebase by default. For development/testing, you can switch to mock data by editing a single line of code.

## Default Configuration

**By default, the app connects to Firebase** ✅🔥

No configuration needed - just run the app and it will sync with Firestore!

## Switching to Mock Data (Development Only)

If you want to test the UI **without Firebase connection**:

### Step 1: Edit Configuration

Open `lib/config/app_config.dart` and change:

```dart
// Current (Firebase mode):
static bool useMockData = false;

// Change to (Mock mode):
static bool useMockData = true;
```

### Step 2: Hot Reload

Save the file and hot-reload the app (press `r` in terminal).

### Step 3: Done!

The app now uses pre-loaded sample data instead of Firebase.

---

## What's the Difference?

### Firebase Mode (Default - useMockData = false)
- ✅ Connects to Firestore database
- ✅ All changes are saved
- ✅ Real-time sync across devices
- ✅ User authentication required
- ⚠️ Requires internet connection

### Mock Data Mode (useMockData = true)
- ✅ Uses pre-loaded sample data
- ✅ No Firebase connection needed
- ✅ No network delays
- ❌ Changes are NOT saved (in-memory only)
- ✅ Perfect for UI testing

---

## Files Overview

| File | Purpose |
|------|---------|
| `lib/config/app_config.dart` | Configuration (change `useMockData` here) |
| `lib/services/data_repository.dart` | Abstract data layer |
| `lib/data/mock_data.dart` | Sample test data |
| `lib/services/firebase_repository.dart` | Firebase implementation |

---

## Development Workflow

### Day 1: Test UI (Mock Mode)
```dart
// In lib/config/app_config.dart
static bool useMockData = true; // 🧪 Use mock data
```
- Test all UI features without Firebase
- No network needed
- Fast feedback loop

### Day 2: Integration Testing (Firebase Mode)
```dart
// In lib/config/app_config.dart
static bool useMockData = false; // 🔥 Use Firebase
```
- Sign up with real email
- Create family and events
- Verify Firestore has your data

### Production (Release Build)
```dart
// Always Firebase in production
static bool useMockData = false; // 🔥 Firebase only
```

---

## Firebase is Already Configured ✅

✅ Google Services plugin enabled  
✅ Firebase dependencies added  
✅ Firestore security rules deployed  
✅ Cloud Functions running  
✅ Authentication enabled  

Just start using it!

---

## Quick Start

1. **Run the app:**
   ```bash
   flutter run -d R5CW13J241L  # (or your device ID)
   ```

2. **Sign up** with an email address

3. **Create a family** and start using the app

4. **All data syncs to Firebase automatically** ✅

---

## To Use Mock Data for Testing

**Change ONE line in `lib/config/app_config.dart`:**

```dart
// Line 12
static bool useMockData = true; // Change false → true
```

**Hot reload and you're using mock data!**

---

## Notes

- Mock data is only in-memory (changes don't persist)
- Great for UI testing and demos
- Production always uses Firebase
- No need to rebuild, just hot-reload to switch modes

---

**Happy coding! 🎉**
