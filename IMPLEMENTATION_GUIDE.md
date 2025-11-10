# 🚀 FamilyCal Implementation Guide

This guide walks you through setting up Firebase + Calendar Sync for FamilyCal.

## 📋 Prerequisites

- Flutter SDK 3.5+
- Node.js 20+
- Firebase CLI: `npm install -g firebase-tools`
- iOS: Xcode 15+ (for iOS development)
- Android: Android Studio (for Android development)

---

## 🔥 Firebase Setup

### 1. Create Firebase Project

```bash
# Login to Firebase
firebase login

# Create new project (or use existing)
firebase projects:create familycal-app

# Set current project
firebase use familycal-app
```

### 2. Enable Firebase Services

In [Firebase Console](https://console.firebase.google.com):

1. **Authentication**
   - Enable Email/Password provider
   - Enable Phone Authentication (optional)

2. **Firestore Database**
   - Create database in production mode
   - Location: Choose closest to your users
   - Deploy security rules: `firebase deploy --only firestore:rules`
   - Deploy indexes: `firebase deploy --only firestore:indexes`

3. **Cloud Functions**
   - Upgrade to Blaze (pay-as-you-go) plan
   - Deploy functions: `cd functions && npm install && firebase deploy --only functions`

4. **Cloud Messaging (FCM)**
   - Automatically enabled
   - iOS: Add APNs key in Project Settings > Cloud Messaging
   - Android: Automatically configured

### 3. Configure Flutter App

#### Add Firebase Config Files

**iOS:**
```bash
# Download GoogleService-Info.plist from Firebase Console
# Move to ios/Runner/GoogleService-Info.plist
```

**Android:**
```bash
# Download google-services.json from Firebase Console
# Move to android/app/google-services.json
```

#### Update iOS Configuration

Edit `ios/Runner/Info.plist`:
```xml
<!-- Add these keys -->
<key>NSCalendarsUsageDescription</key>
<string>FamilyCal needs calendar access to sync your family events</string>
<key>NSRemindersUsageDescription</key>
<string>FamilyCal needs reminders access to notify you of events</string>
<key>NSFaceIDUsageDescription</key>
<string>FamilyCal uses Face ID to securely confirm event completions</string>
```

Edit `ios/Podfile`:
```ruby
# Uncomment and set minimum platform
platform :ios, '15.0'

# Add this at the end of the file
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end
```

#### Update Android Configuration

Edit `android/app/build.gradle`:
```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 23
        targetSdkVersion 34
        // ... other settings
    }
}

dependencies {
    // ... existing dependencies
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
}
```

Edit `android/app/src/main/AndroidManifest.xml`:
```xml
<manifest>
    <!-- Add permissions -->
    <uses-permission android:name="android.permission.READ_CALENDAR" />
    <uses-permission android:name="android.permission.WRITE_CALENDAR" />
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
    <uses-permission android:name="android.permission.USE_BIOMETRIC" />
    <uses-permission android:name="android.permission.INTERNET" />
    
    <application>
        <!-- Add notification channels -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_channel_id"
            android:value="assignments" />
    </application>
</manifest>
```

---

## 📦 Install Dependencies

```bash
# In project root
flutter pub get

# In functions directory
cd functions
npm install
cd ..
```

---

## 🏃 Running the App

### Local Development with Emulators

```bash
# Start Firebase emulators
firebase emulators:start

# In another terminal, run the app
flutter run
```

### Production Mode

```bash
# Deploy Cloud Functions
firebase deploy --only functions

# Deploy Firestore rules and indexes
firebase deploy --only firestore

# Run the app
flutter run --release
```

---

## 🔔 Notification Setup

### iOS (APNs)

1. In Apple Developer Portal:
   - Create App ID with Push Notifications capability
   - Create APNs Key
   - Download `.p8` key file

2. In Firebase Console:
   - Go to Project Settings > Cloud Messaging
   - Upload APNs key (.p8 file)
   - Enter Key ID and Team ID

### Android (FCM)

- Automatically configured when you add `google-services.json`
- No additional setup required

---

## 📅 Calendar Permissions

### Request Permissions at Runtime

The app will automatically request calendar permissions when:
1. User signs up
2. User enables calendar sync in settings
3. User is assigned to an event

Users can:
- Grant/deny permissions
- Choose which device calendar to sync with
- Enable/disable sync at any time

---

## 🧪 Testing

### Test Notifications

```bash
# Send test notification via Cloud Functions
curl -X POST https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/onEventAssignment \
  -H "Content-Type: application/json" \
  -d '{
    "familyId": "test_family",
    "eventId": "test_event",
    "userId": "test_user"
  }'
```

### Test Calendar Sync

1. Create a test event
2. Assign it to yourself
3. Check device calendar app
4. Verify event appears with correct details

### Test Offline Mode

1. Enable Airplane Mode
2. Confirm an event
3. Disable Airplane Mode
4. Verify confirmation syncs to Firestore

---

## 🚀 Deployment

### Build for Production

**iOS:**
```bash
# Build IPA
flutter build ipa --release

# Upload to TestFlight
# Use Xcode or Transporter app
```

**Android:**
```bash
# Build APK
flutter build apk --release

# Or build App Bundle (recommended)
flutter build appbundle --release

# Upload to Google Play Console
```

---

## 📊 Monitoring

### Firebase Console

- **Authentication**: Monitor user signups
- **Firestore**: Check database usage and reads/writes
- **Cloud Functions**: View function logs and execution times
- **Cloud Messaging**: Track notification delivery rates

### Firebase Analytics

Events are automatically tracked:
- `event_created`
- `event_assigned`
- `event_confirmed`
- `calendar_sync_success`
- `calendar_sync_failed`

View in Firebase Console > Analytics

---

## 💰 Cost Monitoring

### Expected Costs (1,000 families)

| Service | Usage | Cost/Month |
|---------|-------|------------|
| Firestore | 150K reads, 50K writes | ~$6 |
| Cloud Functions | 100K invocations | ~$0 (free tier) |
| FCM | Unlimited | $0 |
| Cloud Storage | 1GB | ~$0.03 |
| **Total** | | **~$6-10/month** |

### Set Budget Alerts

1. Go to Google Cloud Console
2. Billing > Budgets & Alerts
3. Set budget: $50/month
4. Configure email alerts at 50%, 90%, 100%

---

## 🐛 Troubleshooting

### Calendar Sync Issues

**Problem**: Events not appearing in device calendar

**Solution**:
1. Check calendar permissions: Settings > Privacy > Calendars
2. Verify calendar is selected in app settings
3. Check logs for sync errors
4. Try disabling and re-enabling calendar sync

### Notification Issues

**Problem**: Not receiving notifications

**Solution**:
1. Check notification permissions
2. Verify FCM token is saved in Firestore
3. Check Cloud Functions logs for errors
4. Test with Firebase Console > Cloud Messaging > Send test message

### Offline Sync Issues

**Problem**: Confirmations not syncing when back online

**Solution**:
1. Check network connectivity
2. View offline queue status in app
3. Manually trigger sync from settings
4. Check Firestore security rules

---

## 📚 Additional Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter Device Calendar Plugin](https://pub.dev/packages/device_calendar)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Firebase Messaging](https://pub.dev/packages/firebase_messaging)

---

## 🤝 Support

For issues or questions:
1. Check logs: `flutter logs` or Firebase Console
2. Review Firestore security rules
3. Test with Firebase Emulators
4. Check Cloud Functions logs

---

## ✅ Checklist

Before deploying to production:

- [ ] Firebase project created and configured
- [ ] iOS and Android config files added
- [ ] Calendar permissions configured
- [ ] Notification permissions configured
- [ ] Biometric authentication tested
- [ ] Firestore security rules deployed
- [ ] Cloud Functions deployed
- [ ] Firestore indexes created
- [ ] Test on real devices (iOS and Android)
- [ ] Budget alerts configured
- [ ] Analytics verified
- [ ] Offline mode tested
- [ ] Privacy policy added
- [ ] Terms of service added

---

## 🎉 You're All Set!

Your FamilyCal app is now ready to help families coordinate their daily routines with seamless calendar integration and smart notifications!

