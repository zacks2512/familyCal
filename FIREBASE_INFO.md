# Firebase Project Information

**Project Name:** FamilyCal  
**Project ID:** familycal-3b3a9  
**Project Number:** 478220568403  
**Region:** us-central1

---

## 🔑 Service Credentials

### Android
- **Package Name:** com.example.familycal
- **Config File:** android/app/google-services.json
- **API Key:** AIzaSyB66YfV8dQGIwlAa3wxkCzC_SbJi974G7w

### iOS
- **Bundle ID:** (To be configured on Mac)
- **Config File:** ios/Runner/GoogleService-Info.plist
- **Status:** ⏸️ Pending (requires macOS)

---

## 📊 Firebase Services Status

### ✅ Enabled Services
- [x] Firestore Database
- [x] Firebase Authentication (Email/Password)
- [x] Cloud Functions
- [x] Cloud Pub/Sub
- [x] Cloud Scheduler
- [x] Artifact Registry
- [x] Cloud Build
- [x] Cloud Logging

### 🔔 Notifications (Pending)
- [ ] Firebase Cloud Messaging
  - Android: Ready (will work automatically)
  - iOS: Requires APNs key upload
  - Web: Requires FCM server key

---

## 🔗 Important Links

### Dashboard
- Firebase Console: https://console.firebase.google.com/project/familycal-3b3a9/overview

### Databases
- Firestore: https://console.firebase.google.com/project/familycal-3b3a9/firestore/data
- Indexes: https://console.firebase.google.com/project/familycal-3b3a9/firestore/indexes

### Functions
- Functions Dashboard: https://console.firebase.google.com/project/familycal-3b3a9/functions/list
- Function Logs: https://console.firebase.google.com/project/familycal-3b3a9/functions/logs

### Authentication
- Users: https://console.firebase.google.com/project/familycal-3b3a9/authentication/users

### Monitoring
- Performance: https://console.firebase.google.com/project/familycal-3b3a9/performance
- Errors: https://console.firebase.google.com/project/familycal-3b3a9/monitoring

### Billing
- Usage & Billing: https://console.firebase.google.com/project/familycal-3b3a9/usage/database

---

## 🎯 Deployed Cloud Functions

All functions are deployed and active:

### 1. onEventAssignment
- **Trigger:** Firestore write to `families/{familyId}/events/{eventId}`
- **Action:** Sends assignment notification to user
- **Status:** ✅ Active

### 2. onEventDeleted
- **Trigger:** Firestore delete from `families/{familyId}/events/{eventId}`
- **Action:** Sends event deleted notification
- **Status:** ✅ Active

### 3. onEventConfirmed
- **Trigger:** Firestore create in `families/{familyId}/confirmations/{confirmationId}`
- **Action:** Sends confirmation to other family members
- **Status:** ✅ Active

### 4. checkUnassignedEvents
- **Trigger:** Pub/Sub scheduled (Daily at 08:00 UTC)
- **Action:** Checks for unassigned events and notifies family owner
- **Status:** ✅ Active

---

## 📐 Database Structure

### Collections

#### users
```
{
  id: string (uid)
  family_id: string
  display_name: string
  fcm_tokens: { device_id: { token: string, updated_at: timestamp } }
  settings: {
    calendar_sync_enabled: boolean
    calendar_id: string | null
    notifications: {
      assignments: boolean
      confirmations: boolean
      unassigned_alerts: boolean
    }
  }
  created_at: timestamp
}
```

#### families
```
{
  id: string
  owner_id: string (user id)
  member_ids: array<string>
  settings: {
    timezone: string
    locale: string
  }
  created_at: timestamp
  
  // Subcollections:
  children/{childId}
  events/{eventId}
  confirmations/{confirmationId}
  pending_syncs/{syncId}
}
```

#### children (in families)
```
{
  id: string
  family_id: string
  display_name: string
  date_of_birth: date
  notes: string
  created_at: timestamp
}
```

#### events (in families)
```
{
  id: string
  family_id: string
  child_id: string
  created_by: string (user id)
  responsible_member_id: string | null
  place: string
  role: 'pickUp' | 'dropOff'
  start_time: string (HH:MM)
  end_time: string (HH:MM)
  start_date: timestamp
  recurrence: 'daily' | 'weekly' | 'monthly' | null
  recurrence_end: timestamp | null
  created_at: timestamp
}
```

#### confirmations (in families)
```
{
  id: string
  family_id: string
  event_id: string
  child_id: string
  place: string
  role: 'pickUp' | 'dropOff'
  confirmed_by_id: string (user id)
  confirmed_at: timestamp
  geo_ok: boolean
  offline: boolean
  note: string
}
```

---

## 🔐 Security Rules

Current Firestore rules enforce:
- ✅ Users can only access their family's data
- ✅ Only family members can read/write family data
- ✅ Only family owner can delete family
- ✅ Confirmations are immutable (can't be edited)
- ✅ Each user can only confirm their own events

---

## 💰 Billing & Quotas

### Plan: Blaze (Pay-as-you-go)

**Firestore quotas:**
- Read: 1 million reads/day free
- Write: 1 million writes/day free
- Delete: 20,000 deletes/day free

**Cloud Functions quotas:**
- 2 million free calls/month

**Estimated costs (production):**
- Family with 2 parents, 2 kids, daily events: ~$10-15/month
- Notifications are free with Firebase Cloud Messaging

---

## 🔄 CI/CD & Deployments

### Local Deployment
```bash
# From project root with nvm activated:
firebase deploy --only functions,firestore:rules,firestore:indexes
```

### Manual Deployment Steps
1. Modify code in `/functions` or `firestore.rules`
2. Test locally: `firebase emulators:start`
3. Deploy: `firebase deploy`

### Git Workflow
- Main branch deploys to production
- Rules and functions auto-deploy via CI/CD

---

## 📞 Support & Debugging

### Check Function Logs
```bash
export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
firebase functions:log
```

### Check Firestore Rules
- Open Firebase Console → Firestore → Rules
- Click "Publish" if in draft state

### Monitor Performance
- Firebase Console → Performance
- Look for slow reads/writes

### View Errors
- Firebase Console → Monitoring & Events
- Check "Errors" section

---

## ✅ Checklist

- [x] Firebase project created
- [x] Firestore database enabled
- [x] Authentication configured
- [x] Cloud Functions deployed
- [x] Android config added
- [x] iOS config pending (requires Mac)
- [x] Firestore rules deployed
- [x] Budget alerts configured
- [x] Cloud Scheduler enabled
- [ ] APNs key uploaded (for iOS notifications)
- [ ] Firebase Dynamic Links configured (optional)
- [ ] Analytics events tracked (optional)

---

**Last Updated:** November 10, 2025  
**Status:** ✅ Production Ready (Android)

