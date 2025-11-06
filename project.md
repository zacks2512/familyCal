# FAMILYCAL — MVP PRD (Agent-Ready)
**One-liner:** A calendar-first family app that assigns roles to kid events ("drop-off / pick-up") and lets the responsible adult confirm **"Dropped off / Picked up"** with one tap (time-window + biometric), then pings the partner.

---

## Table of Contents
1. [Scope at a Glance](#0-scope-at-a-glance)
2. [Users & Roles](#1-users--roles)
3. [Primary Flows (User Stories + Acceptance)](#2-primary-flows-user-stories--acceptance)
4. [UX Spec (Condensed)](#3-ux-spec-condensed)
5. [Data Model (Firestore Collections)](#4-data-model-firestore-collections)
6. [API (Cloud Functions)](#5-api-cloud-functions)
7. [Notifications Matrix (FCM)](#6-notifications-matrix-fcm)
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
- One-tap self confirmation (within window) with **FaceID/PIN**
- Push notifications (reminders & partner updates)
- Activity log per child; **monthly PDF export**
- Basic analytics

**Out-of-scope (MVP)**
- Teacher/coach confirmations
- Fairness/rotas, carpooling
- Payments, chat
- ICS writeback; Google full sync (read-only import is stretch)
- Multi-family circles/teams

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
- **Accept:** Event instances render in Day; editing updates future instances; conflicting events for the same child warn.

### US-03 Reminder & One-Tap Confirmation
- As the responsible adult, I get a push at **T−15 min** and at window open; during the time window I tap **"Dropped off"** → biometric → success.
- **Accept:** Confirmation writes a log with timestamp; partner receives "Done ✅" push.

### US-04 Late Nudge
- If not confirmed by **window_end−5 min**, I receive “5 minutes left” push; at window end partner gets “Not marked—check in?”.
- **Accept:** Notifications fire according to schedule; multiple devices deduplicated.

### US-05 Activity Log & Export
- I can view all confirmations for the month and export a **PDF** per child.
- **Accept:** PDF contains date/time/place/user; shares via native share sheet.

### US-06 Offline
- If I'm offline, I can confirm with PIN/biometric; confirmation recorded locally and syncs later.
- **Accept:** Local queue flushes on reconnect; idempotent server confirm.

---

## 3) UX Spec (Condensed)

**Navigation tabs:** Today | Calendar | Add (+) | Log | Settings

**Today**
- “Now / Next” cards by child
- Big primary button: **Dropped off / Picked up** (enabled only during window; shows countdown)
- Tiny chips: place, role icon (🍼 drop / 🚗 pickup)

**Calendar**
- **Day view** (default): vertical timeline with event cards (child color, role tag, place chip)
- **Agenda view**: list for today/tomorrow with quick actions
- Tap event → details sheet with: Edit | Delete | Confirm (if in window)

**Add (+)**
- Quick sheet: Child, Place, Role, Days, Start–End, Responsible
- Save as Template (optional); RRULE preview

**Log**
- Filters: child, place, month
- List: "2025-10-21 08:12 • School • Dropped off • You"
- Export PDF

**Settings**
- Family management, invites
- Notifications toggles
- Privacy copy

**Microcopy examples**
- Reminder: "08:00–08:40 • School drop-off (You). Mark 'Dropped off'?"
- Success: "Dropped off Mia • 08:17 ✅"
- Late: "Pickup window ends in 5 min. Need to send 'Running late 10 min'?"

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
  "tz": "IANA/TZ"
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

// places/{placeId}
{
  "id": "string",
  "family_id": "string",
  "name": "string",
  "created_at": 0
}

// events/{eventId}
{
  "id": "string",
  "family_id": "string",
  "child_id": "childId",
  "place_id": "placeId",
  "type": "drop|pickup",
  "start_ts": 0,
  "end_ts": 0,
  "rrule": "RFC5545 string or null",
  "responsible_user_id": "userId",
  "created_by": "userId",
  "created_at": 0,
  "updated_at": 0
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
  Body: { child_id, place_id, type, start_ts, end_ts, rrule?, responsible_user_id }
  Returns: { event_id }
  Validations: window < 6h; start < end; no past-only RRULE; warn on overlap same child&type.

POST /event.update
  Body: { event_id, ...fields }
  Returns: { ok: true }

POST /event.delete
  Body: { event_id }
  Returns: { ok: true }

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

## 6) Notifications Matrix (FCM)

- **T−15 min (responsible):** “Window opens soon.”
- **T=window start (responsible):** “You’re on duty now.”
- **T=window_end−5 (responsible):** “5 minutes left.”
- **On confirm (partner):** “Done ✅ — {child} {drop/pick} at {place}, {time}.”
- **T=window end (partner, optional):** “Not marked—check in?”

_Deduplicate multi-device; respect quiet hours._

---

## 7) Security
- **Biometric/PIN:** require OS biometric or 4-digit PIN when confirming.
- **Privacy:** confirmations are time-stamped only; no location data collected.
- **Rules:** Firestore Security Rules—documents readable/writable only if `request.auth.uid` is in `family.member_ids`.

---

## 8) Tech Stack
- **Mobile:** React Native (Expo) **or** Flutter; RTL ready
- **Backend:** Firebase Auth, Firestore, Cloud Functions (Node 20), FCM
- **Local/offline:** SQLite + queued confirmations
- **PDF:** client-side generation (e.g., pdfkit/dart_pdf) → share sheet
- **Analytics:** Firebase Analytics + Crashlytics/Sentry

---

## 9) Analytics (Firebase)

**Events**
- `signup_complete`, `invite_sent`, `invite_accepted`
- `event_created`, `event_confirm_press`, `event_confirm_success`
- `reminder_opened`, `late_warning_opened`
- `pdf_export`

**KPIs**
- Families with ≥1 recurring event in 48h
- Daily confirmations per active family
- Reminder → confirm conversion rate
- D7 / D30 retention

---

## 10) Edge Cases & Error Handling
- **DST/timezones:** store in UTC; render in user TZ.
- **Overlap:** same child & type overlapping windows → block or warn + require override.
- **Offline:** queue `/event.confirm` with idempotency key; show "Synced ✔︎" when posted.
- **Concurrent confirm:** first write wins; subsequent calls return `{ok:true, duplicate:true}`.

---

## 11) Acceptance Test Checklist
- [ ] Create family, invite partner, both see same child/place  
- [ ] Create recurring event; instances render in Day & Agenda  
- [ ] Receive T−15 and T0 reminders; confirm within window → partner push  
- [ ] Confirm outside window → blocked with error  
- [ ] Offline confirm queues and syncs later  
- [ ] Log filters by child; monthly PDF exports and opens  
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
- Day/Agenda calendar scaffolding

**Sprint 2 (Events)**
- Event create/edit/delete + RRULE expansion service
- Local cache & filters
- Reminder scheduler (Cloud Functions)

**Sprint 3 (Confirmations)**
- Confirm button UI + biometric/PIN
- Time-window verification on server
- Partner & late notifications
- Offline queue + idempotency

**Sprint 4 (Log & Export)**
- Log screen with filters
- Monthly PDF export
- Basic analytics & crash reporting
- Store metadata & privacy text

---

## 14) Environment & Config
- `.env` (client): `FIREBASE_API_KEY`, `FIREBASE_PROJECT_ID`, `SENTRY_DSN?`
- Cloud Functions config: `TIME_WINDOW_GRACE_MINUTES=5`
- iOS: Background modes (notifications); Android: notification channels for reminders