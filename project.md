# FAMILYCAL — MVP PRD (Agent-Ready)
**One-liner:** A calendar-first family app that assigns roles to kid events ("drop-off / pick-up"), syncs them to your device calendar for reminders, and lets the responsible adult confirm **"Dropped off / Picked up"** with one tap (time-window + biometric), then notifies the partner.

---

## Table of Contents
1. [Scope at a Glance](#0-scope-at-a-glance)
2. [Users & Roles](#1-users--roles)
3. [Primary Flows (User Stories + Acceptance)](#2-primary-flows-user-stories--acceptance)
4. [UX Spec (Condensed)](#3-ux-spec-condensed)
5. [Data Model (Firestore Collections)](#4-data-model-firestore-collections)
6. [API (Cloud Functions)](#5-api-cloud-functions)
7. [Notifications & Calendar Sync](#6-notifications--calendar-sync)
8. [Security](#7-security)
9. [Tech Stack](#8-tech-stack)
10. [Analytics](#9-analytics-firebase)
11. [Edge Cases & Error Handling](#10-edge-cases--error-handling)
12. [Acceptance Test Checklist](#11-acceptance-test-checklist)
13. [Release Plan](#12-release-plan)
14. [Implementation Tasks (Agent Sprint Plan)](#13-implementation-tasks-agent-sprint-plan)
15. [Environment & Config](#14-environment--config)

---

## 0) Scope at a Glance

**In-scope (MVP)**
- Mobile app (Flutter)
- Auth (email + magic link or phone OTP)
- Family space (invite partner)
- Children CRUD
- Calendar views: **Day/Week/Month**
- Event with role ("drop" / "pickup"), time window, recurring RRULE
- **Native calendar sync** (events auto-add to device calendar with reminders)
- One-tap self confirmation (within window) with **FaceID/PIN**
- Push notifications (assignments, confirmations & unassigned alerts)
- Activity log per child; **monthly PDF export**
- Basic analytics

**Out-of-scope (MVP)**
- Teacher/coach confirmations
- Fairness/rotas, carpooling
- Payments, chat
- Two-way calendar sync (device calendar → app); ICS import/export; Google Calendar API integration
- Multi-family circles/teams
- Shared custody/split-family schedules

---

## 1) Users & Roles
- **User:** adult in a family (parent/caregiver)
- **Family owner:** first user; can invite/remove members
- **All adults:** can create/confirm events they are responsible for

---

## 2) Primary Flows (User Stories + Acceptance)

### US-01 Create Family & Invite Partner
- As a new user, I create a family, add my children, invite partner.
- **Accept:** Family exists; child persisted; partner gets invite link; both see same data after join.

### US-02 Add Recurring Event with Role
- As a user, I add a recurring **drop-off** for Mia at School, Mon–Fri **08:00–08:40**, responsible: Me.
- **Accept:** Event instances render in Day/Week/Month views; editing updates future instances; conflicting events for the same child warn.

### US-03 Calendar Sync & One-Tap Confirmation
- As the responsible adult, when an event is assigned to me, it's added to my phone calendar; during the time window I tap **"Dropped off"** → biometric → success.
- **Accept:** Event appears in device calendar with reminders; confirmation writes a log with timestamp; partner receives "Done ✅" push.

### US-04 Unassigned Event Alert
- If I create an event without assigning it to anyone, the family owner receives a notification to assign someone.
- **Accept:** Owner receives push notification; can assign from notification or in-app; once assigned, assignee gets notification + calendar sync.

### US-05 Activity Log & Export
- I can view all confirmations for the month and export a **PDF** per child.
- **Accept:** PDF contains date/time/place/user; shares via native share sheet.

### US-06 Offline
- If I'm offline, I can confirm with PIN/biometric; confirmation recorded locally and syncs later.
- **Accept:** Local queue flushes on reconnect; idempotent server confirm.

---

## 3) UX Spec (Condensed)

**Navigation tabs:** Calendar | Settings

**Calendar**
- **View modes:** Day | Week | Month (segmented button toggle)
- **Header:** Month/Year label with navigation arrows, "Today" button
- **Month view:** Grid calendar with event indicators
- **Week view:** 7-day horizontal scroll with timeline
- **Day view:** Vertical timeline with event cards (child color, role tag, place chip)
- **Quick add:** Inline form appears on selected date
  - Fields: Child, Place (free text), Role (drop/pickup), Time window, Responsible adult
  - Days selection for recurring events
- Tap event → details sheet with: Edit | Delete | Confirm (if in window)
- Keyboard navigation: Arrow keys to change dates, 'n' for new event, 't' for today

**Settings**
- **Children:** List with color avatars; Add child with name + color picker
- **Family members:** List with owner badge; Add/Invite member with optional email/phone
- **Calendar Sync:** 
  - Toggle: "Sync my events to device calendar"
  - Calendar picker: Choose which calendar to use (default, work, family, etc.)
  - Sync status indicator
- **Activity Log** (navigates to separate screen):
  - Filters: child dropdown, month dropdown
  - List: cards showing "Child • Role • Date/Time • Place • Confirmed by"
  - Export PDF and Share buttons in app bar
- **Notifications:** 
  - Toggle: Assignment notifications
  - Toggle: Confirmation notifications
  - Toggle: Unassigned event alerts (owner only)
- Privacy copy

**Microcopy examples**
- Assignment: "You're now responsible for Mia drop-off at School on Mon, Nov 6 at 08:00. Added to your calendar."
- Reassignment: "Sarah assigned you Emma pickup at Daycare tomorrow at 15:30."
- Unassigned alert (to owner): "Reminder: Mia drop-off at School on Wed needs someone assigned."
- Confirmation success: "Dropped off Mia • 08:17 ✅"
- Partner notification: "Done ✅ — Sarah confirmed Mia drop-off at School at 08:17."
- Event updated: "Updated: Mia drop-off changed to 08:15 at School Main Entrance."
- Calendar sync error banner: "⚠️ Calendar sync failed. Tap to retry or check permissions."

---

## 4) Data Model (Firestore Collections)

```json
// users/{userId}
{
  "id": "string",
  "family_id": "string",
  "name": "string",
  "email": "string?",
  "phone": "string?",
  "devices": [{"platform":"ios|android","fcm_token":"string","device_id":"string"}],
  "created_at": 0,
  "tz": "IANA/TZ",
  "settings": {
    "calendar_sync_enabled": true,
    "calendar_id": "string?", // device calendar ID to sync to
    "notifications": {
      "assignments": true,
      "confirmations": true,
      "unassigned_alerts": true // only for owner
    }
  }
}

// families/{familyId}
{
  "id": "string",
  "owner_id": "userId",
  "member_ids": ["userId"],
  "settings": { "tz": "IANA/TZ", "locale": "en|he|..." }
}

// children/{childId}
{
  "id": "string",
  "family_id": "string",
  "name": "string",
  "color": "#AABBCC",
  "created_at": 0
}

// events/{eventId}
{
  "id": "string",
  "family_id": "string",
  "child_id": "childId",
  "place": "string",
  "type": "drop|pickup",
  "start_ts": 0,
  "end_ts": 0,
  "rrule": "RFC5545 string or null",
  "responsible_user_id": "userId or null",
  "created_by": "userId",
  "created_at": 0,
  "updated_at": 0,
  "calendar_synced_for": ["userId"] // tracks which users have this in their device calendar
}

// confirmations/{logId}
{
  "id": "string",
  "family_id": "string",
  "event_id": "eventId",
  "child_id": "childId",
  "user_id": "userId",
  "type": "drop|pickup",
  "ts": 0,
  "device_ok": true,
  "note": "string?",
  "source": "online|offline-queued"
}
```

**Indexes**
- `events` composite on `(family_id, child_id, start_ts)`
- `confirmations` composite on `(family_id, child_id, ts desc)`

---

## 5) API (Cloud Functions)

_All endpoints authenticate via Firebase Auth; enforce `family_id` scoping._

```
POST /event.create
  Body: { child_id, place, type, start_ts, end_ts, rrule?, responsible_user_id? }
  Returns: { event_id }
  Validations: window < 6h; start < end; no past-only RRULE; warn on overlap same child&type.
  Triggers:
    - If responsible_user_id provided → send "assigned" notification to user
    - If responsible_user_id is null → schedule unassigned alert to owner (24h delay if event within 7 days)

POST /event.update
  Body: { event_id, ...fields }
  Returns: { ok: true }
  Triggers:
    - If responsible_user_id changed → send "reassigned" notification to new user
    - If time/place changed → send "event updated" notification to responsible user
    - Update calendar_synced_for users' device calendars via client-side sync

POST /event.calendar_synced
  Body: { event_id, user_id, device_calendar_id }
  Returns: { ok: true }
  Purpose: Client reports successful calendar sync; updates calendar_synced_for array

POST /event.delete
  Body: { event_id }
  Returns: { ok: true }
  Triggers:
    - Send "event deleted" notification to responsible user
    - Client removes event from device calendar

GET /calendar.range
  Query: start_ts, end_ts
  Returns: { instances: [ {event_id, child_id, place, start_ts, end_ts, type, responsible_user_id} ] }
  Notes: Expand RRULE on server; include only due instances.

POST /event.confirm
  Body: { event_id, ts_client, device_id }
  Server checks:
    - within window (± grace 5 min)
    - user == responsible_user_id
  Writes ConfirmationLog; sends partner push.
  Returns: { ok: true, server_ts }

GET /log.month
  Query: child_id, month (YYYY-MM)
  Returns: { logs: [...] }

POST /export.monthly_pdf
  Body: { child_id, month }
  Returns: { url } // expiring link (or client-generated base64)
```

---

## 6) Notifications & Calendar Sync

### Calendar Integration
- **Auto-sync to device calendar:** When an event is assigned to you (or you assign it to yourself), it's automatically added to your phone's native calendar with:
  - Event title: "{Child name} {role} at {place}"
  - Time window: start_ts to end_ts
  - Calendar reminders handled by phone's calendar app (user configurable in their calendar settings)
  - Include note: "FamilyCal event - confirm in app when complete"

### Push Notifications (FCM)
- **Event assigned to you:** "You're now responsible for {child} {drop/pick} at {place} on {date} {time}. Added to your calendar."
- **Event reassigned to you:** "{Member} assigned you {child} {drop/pick} at {place} on {date} {time}."
- **Unassigned event alert (to family owner only):** "Reminder: {child} {drop/pick} at {place} on {date} needs someone assigned."
- **On partner confirm:** "Done ✅ — {Member} confirmed {child} {drop/pick} at {place} at {time}."
- **Event edited (to responsible user):** "Updated: {child} {drop/pick} changed to {new_time} at {new_place}."
- **Event deleted (to responsible user):** "{child} {drop/pick} at {place} on {date} was removed."

_Deduplicate multi-device; respect quiet hours; batch notifications when possible._

---

## 7) Security
- **Biometric/PIN:** require OS biometric or 4-digit PIN when confirming.
- **Privacy:** confirmations are time-stamped only; no location data collected.
- **Rules:** Firestore Security Rules—documents readable/writable only if `request.auth.uid` is in `family.member_ids`.

---

## 8) Tech Stack
- **Mobile:** Flutter
- **Backend:** Firebase Auth, Firestore, Cloud Functions (Node 20), FCM
- **Calendar sync:** 
  - iOS: EventKit framework (calendar read/write permissions)
  - Android: CalendarContract API (READ_CALENDAR, WRITE_CALENDAR permissions)
  - Flutter plugin: `device_calendar` or similar
- **Local/offline:** SQLite + queued confirmations & calendar syncs
- **PDF:** client-side generation (dart_pdf) → share sheet
- **Analytics:** Firebase Analytics + Crashlytics/Sentry

---

## 9) Analytics (Firebase)

**Events**
- `signup_complete`, `invite_sent`, `invite_accepted`
- `event_created`, `event_assigned`, `event_reassigned`
- `calendar_sync_success`, `calendar_sync_failed`
- `unassigned_alert_sent`, `unassigned_alert_opened`
- `event_confirm_press`, `event_confirm_success`
- `notification_opened` (generic for all notification types)
- `pdf_export`

**KPIs**
- Families with ≥1 recurring event in 48h
- Daily confirmations per active family
- Calendar sync success rate
- % events assigned within 24h of creation
- Notification → action conversion rate
- D7 / D30 retention

---

## 10) Edge Cases & Error Handling
- **DST/timezones:** store in UTC; render in user TZ; calendar events sync with correct local time.
- **Overlap:** same child & type overlapping windows → block or warn + require override.
- **Offline:** queue `/event.confirm` with idempotency key; show "Synced ✔︎" when posted. Calendar sync also queued.
- **Concurrent confirm:** first write wins; subsequent calls return `{ok:true, duplicate:true}`.
- **Calendar permission denied:** Event still created in app; show banner "Enable calendar sync in settings to get reminders." App remains functional.
- **Calendar sync failure:** Log error; retry once; if fails, mark event with "⚠️ Calendar sync failed" badge; allow manual retry.
- **Recurring event limits:** If calendar provider has limits (e.g., some Android calendars), expand only next 90 days; refresh as time passes.
- **Recurring event confirmation:** When user confirms one instance, it only marks that specific occurrence as confirmed; future instances remain in calendar until individually confirmed.
- **Calendar deleted externally:** On next app open, detect missing calendar events; offer to re-sync or disable calendar sync.
- **Unassigned event timing:** Send alert to owner 24h after event creation if still unassigned AND event start_ts is within 7 days.

---

## 11) Acceptance Test Checklist
- [ ] Create family, invite partner, both see same child/place  
- [ ] Create recurring event; instances render in Day/Week/Month views  
- [ ] Assign event to self → appears in device calendar with reminder  
- [ ] Create unassigned event → owner receives notification alert
- [ ] Assign event to partner → partner receives notification + calendar sync  
- [ ] Confirm within window → partner receives "Done ✅" push  
- [ ] Confirm outside window → blocked with error  
- [ ] Edit/delete assigned event → responsible user notified + calendar updated  
- [ ] Offline confirm queues and syncs later  
- [ ] Log filters by child and month; monthly PDF exports and opens  
- [ ] Security rules: user cannot access other family's docs

---

## 12) Release Plan
- **Beta footprint:** iOS TestFlight + Android Internal
- **Device targets:** iOS 15+, Android 9+
- **Perf budget:** app launch < 2.5s; confirm action < 300ms (local) + async server ack
- **Privacy copy:** "FAMILYCAL does not collect location data. Confirmations are time-stamped only."

---

## 13) Implementation Tasks (Agent Sprint Plan)

**Sprint 1 (Infra + CRUD)**
- Auth, family space, invite flow
- Children & places CRUD (places as free text)
- Day/Week/Month calendar views with inline quick add

**Sprint 2 (Events & Sync)**
- Event create/edit/delete + RRULE expansion service
- Native calendar sync (iOS EventKit / Android Calendar Provider)
- Assignment notifications (assigned, reassigned, unassigned alerts)
- Local cache & filters

**Sprint 3 (Confirmations)**
- Confirm button UI + biometric/PIN
- Time-window verification on server
- Partner confirmation notifications
- Calendar updates on edit/delete
- Offline queue + idempotency

**Sprint 4 (Log & Export)**
- Log screen with filters
- Monthly PDF export
- Basic analytics & crash reporting
- Store metadata & privacy text

---

## 14) Environment & Config
- `.env` (client): `FIREBASE_API_KEY`, `FIREBASE_PROJECT_ID`, `SENTRY_DSN?`
- Cloud Functions config: 
  - `TIME_WINDOW_GRACE_MINUTES=5`
  - `UNASSIGNED_ALERT_DELAY_HOURS=24` (how long to wait before alerting owner about unassigned events)
- **iOS:** 
  - Permissions: Calendar (read/write), Notifications, Biometric
  - Background modes: remote notifications
- **Android:** 
  - Permissions: READ_CALENDAR, WRITE_CALENDAR, POST_NOTIFICATIONS, USE_BIOMETRIC
  - Notification channels: assignments, confirmations, alerts