# ElderShield — GTM Implementation Plan

> **Core insight:** The caregiver (adult child, 25–40, metro) is the buyer. The parent (60+, Tier 2) is the user. Acquire the child, protect the parent.

---

## Phase 1 — Onboarding Redesign

**Goal:** Replace current 3-screen onboarding with role-based split flow.
**Touches:** `lib/features/onboarding/`, `lib/presentation/onboarding/`, `SettingsService`, ARB files
**Dependencies:** None — builds on existing onboarding infrastructure

### What changes

**New first screen — Role Selection**
```
"Who is setting this up?"
  [ I'm setting this up for my parent / family member ]
  [ I want to protect myself ]
```

**Path A — Caregiver flow (3 screens)**

| Screen | Purpose | Data stored |
|--------|---------|-------------|
| 1. Name the person | Preset options: Maa, Papa, Dadi, Dada, Nani, Nana, custom | `protectedPersonName` in SettingsService |
| 2. Add yourself as guardian | Caregiver enters their WhatsApp number | `guardianContact` (name + number) in SettingsService |
| 3. Permissions | SMS read + overlay permission grants | Same as current `OnboardingPermissionsScreen` |

**Path B — Self-protection flow (2 screens)**

| Screen | Purpose | Data stored |
|--------|---------|-------------|
| 1. Your name | Simple name input | `protectedPersonName` in SettingsService |
| 2. Permissions + optional guardian | Permission grants + "Add a family contact?" link | Same as current + optional `guardianContact` |

### Implementation details

- Add to `SettingsService`:
  - `userRole` — `caregiver` or `self` (persisted in EncryptedSharedPreferences)
  - `protectedPersonName` — String
  - `guardianContact` — `TrustedContact` (reuse existing model: name + phone)
- Refactor `OnboardingFlow` widget to branch based on role selection
- Remove `OnboardingTrustedContactScreen` (replaced by guardian contact step)
- Keep existing trusted contacts feature in Settings for emergency contacts (separate concept)
- Add all new strings to 9 ARB files + run `flutter gen-l10n`
- After onboarding, both paths land on the same `MainShell`

### What stays the same

- Permission request logic (SMS, overlay, DND)
- Post-onboarding mark-complete flow via `SettingsService`
- `LaunchGate` routing logic
- All detection, alerting, and database code

---

## Phase 2 — Guardian Alert Service

**Goal:** When a high-risk SMS is detected on the parent's phone, alert the guardian via WhatsApp/SMS.
**Touches:** New `lib/services/guardian_alert_service.dart`, `SecurityController`, Kotlin native layer
**Dependencies:** Phase 1 (guardian contact must exist)

### What gets built

**`GuardianAlertService`** — new service class

```
Responsibilities:
- Read guardian contact from SettingsService
- Compose alert message (sender ID + risk level + time, never message body)
- Fire WhatsApp intent (primary) or SMS intent (fallback)
- Rate-limit: max 1 alert per 10 minutes to avoid spam
- Dedup: don't alert for same sender within 1 hour
```

**Alert message template:**
```
🛡️ ElderShield Alert
A suspicious message was detected on [Name]'s phone.
Sender: [SENDER_ID]
Risk: High
Time: [HH:MM AM/PM]

[Name] is protected — the message has been flagged.
```

**Integration points:**
- `SecurityController.onSmsEvent()` — after `HeuristicDetector.analyze()` returns high risk, call `GuardianAlertService.alert()` if guardian is configured
- Kotlin `SmsReceiver.kt` — when app is killed and `SimpleRiskCheck` detects high risk, fire WhatsApp intent from the receiver (new Kotlin code)

### Privacy guardrails

- Never include message body in the alert
- Only share: sender ID, risk level, timestamp, protected person's name
- Guardian contact stored in EncryptedSharedPreferences (already encrypted)

### Rate limiting

| Rule | Value |
|------|-------|
| Min interval between any alerts | 10 minutes |
| Same sender cooldown | 1 hour |
| Max alerts per day | 10 |

Store last alert timestamps in memory (reset on app restart — acceptable for v1).

---

## Phase 3 — Free & Paid Tiers + Google Play Billing

**Goal:** Introduce subscription model. Core protection stays free. Guardian features are paid.
**Touches:** New `lib/services/subscription_service.dart`, new paywall UI, `pubspec.yaml`
**Dependencies:** Phase 2 (guardian alerts must exist to gate)

### Tier breakdown

**Free (forever)**
| Feature | Status |
|---------|--------|
| Full heuristic SMS scanning | Already built |
| On-device risk alerts (all levels) | Already built |
| All 9 regional languages | Already built |
| URL expansion checks | Already built |
| Call + SMS combined risk boost | Already built |
| Config updates (same cadence) | Already built |
| Self-protection onboarding | Phase 1 |

**Paid — "Guardian Plan"**
| Feature | Phase |
|---------|-------|
| Guardian WhatsApp/SMS alerts | Phase 2, gated in Phase 3 |
| Daily safety heartbeat | Phase 4 |
| Weekly scam summary to guardian | Phase 4 |
| Protect up to 3 family members | Phase 3 |

**Pricing (suggested):** ₹99/month or ₹799/year (~33% savings)

### Implementation details

**Google Play Billing integration:**
- Add `in_app_purchase` package to `pubspec.yaml`
- New `SubscriptionService` class:
  - Check purchase state on app start
  - Expose `isPremium` stream (Riverpod provider)
  - Handle purchase flow, restoration, and cancellation
  - No server-side receipt validation in v1 (local verification only)

**New Riverpod provider:**
```dart
final subscriptionProvider = StreamProvider<bool>((ref) {
  return ref.watch(subscriptionServiceProvider).isPremiumStream;
});
```

**Paywall moment:**
- Caregiver onboarding Path A → after entering guardian number → soft paywall:
  ```
  "Enable Guardian Alerts"
  Get notified on WhatsApp when [Name] receives a suspicious message.

  [ ₹99/month ]  [ ₹799/year — Save 33% ]

  [ Maybe later ] ← still completes onboarding, guardian contact saved but alerts disabled
  ```
- Settings screen → "Guardian Plan" section with upgrade button (for self-protection users who add a guardian later)
- Guardian alerts in Phase 2 check `isPremium` before firing

**What is NOT gated:**
- Detection engine — always runs at full capability
- On-device alerts — always shown to the parent
- URL expansion — always available
- Config updates — same schedule for all users

---

## Phase 4 — Daily Heartbeat & Weekly Summary

**Goal:** Give caregivers passive assurance that protection is active.
**Touches:** New Kotlin `WorkManager` job, new `lib/services/heartbeat_service.dart`
**Dependencies:** Phase 3 (paid feature)

### Daily heartbeat

**What:** Every day at 10:00 AM, parent's phone auto-sends a WhatsApp message to guardian:
```
🛡️ ElderShield Daily Check-in
[Name]'s phone is protected.
[N] suspicious messages blocked yesterday.
App is running normally.
```

**How:**
- Android `WorkManager` periodic task (24-hour interval, flex window ±1 hour)
- Kotlin code composes and fires WhatsApp intent
- Works even if Flutter engine is not running
- If WhatsApp unavailable → fallback to SMS

**Dead man's switch effect:** If guardian stops receiving daily messages, they know something is wrong (app uninstalled, phone off, etc.). The absence IS the alert.

### Weekly summary

**What:** Every Sunday at 10:00 AM, a more detailed message:
```
🛡️ ElderShield Weekly Summary for [Name]

This week:
• [N] messages scanned
• [N] suspicious messages flagged
• [N] high-risk messages blocked
• Top threat types: [UPI fraud, KYC scam]

[Name] is protected. No action needed.
```

**How:**
- Query `AppDatabase` for last 7 days of `analyzed_messages`
- Aggregate counts by risk band
- Group top reasons
- Compose and send via same WhatsApp/SMS mechanism

### Native implementation

- New `HeartbeatWorker.kt` extending `CoroutineWorker`
- Registered in `MainActivity.kt` on app start (if premium + guardian configured)
- Reads guardian number from SharedPreferences (synced from Flutter)
- `WorkManager.enqueueUniquePeriodicWork()` to prevent duplicates

---

## Phase 5 — Caregiver-Side Experience (Pre-Backend)

**Goal:** Give the caregiver something useful on their own phone before a full backend exists.
**Touches:** Caregiver mode in the same APK
**Dependencies:** Phase 1–3

### What the caregiver sees on their phone

When a caregiver installs ElderShield on **their own phone** and selects "Setting up for my parent":

**Screen: "Help [Name] Install"**
```
Step 1: Send [Name] the app
  [ Share via WhatsApp → ]
  (pre-composed message in parent's language with Play Store link)

Step 2: Call [Name] and help them set up
  It takes 2 minutes. We'll guide you both.

Step 3: Done!
  You'll receive alerts on this phone when
  [Name] gets a suspicious message.
```

**Pre-composed WhatsApp message (localized):**

Hindi example:
```
[Name], maine aapke phone ke liye ek safety app bheja hai.
Isko install karo, main call karke set up kara dunga. 🙏
[Play Store Link]
```

**Caregiver's app after setup:**
- Minimal UI — just a status card:
  ```
  🛡️ Protecting: Maa
  Status: Waiting for [Name] to install
  ```
- Once parent installs and starts sending heartbeats, status updates to:
  ```
  🛡️ Protecting: Maa
  Last active: Today, 10:00 AM
  Threats this week: 2 blocked
  ```
- This data comes from WhatsApp messages — caregiver's app can optionally parse incoming WhatsApp notifications from ElderShield (using `NotificationListenerService`) to display status. No backend needed.

### Limitations (acceptable for v1)

- No real-time sync — caregiver sees status only from heartbeat messages
- No remote config changes — caregiver can't adjust parent's settings remotely
- No multi-caregiver — one guardian per parent
- Linking is manual (phone call + WhatsApp), not automatic

---

## Phase 6 — Backend & Beyond (v2)

**Goal:** True caregiver dashboard, remote management, multi-device family plans.
**Not scoped in detail — listed for directional alignment.**

### v2 capabilities (requires backend)

- **Account system** — Firebase Auth or custom auth
- **Caregiver dashboard** — real-time alert feed, parent status, remote sensitivity adjustment
- **Deep link onboarding** — caregiver sends invite link → parent installs → auto-linked, no phone call needed
- **Multi-caregiver** — both children can monitor one parent
- **Multi-parent** — one subscription protects multiple parents
- **Server-side receipt validation** — prevent subscription fraud
- **Push notifications** — replace WhatsApp alerts with proper push (more reliable, less intrusive)
- **Remote config** — server-managed keyword/threshold updates with A/B testing
- **Analytics** — anonymized, aggregated threat intelligence (opt-in)

### Suggested backend stack

- **Firebase** (Auth + Firestore + Cloud Messaging + Cloud Functions) — fastest to ship
- OR **Supabase** (Postgres + Auth + Realtime + Edge Functions) — open source, more control

---

## Implementation Order & Estimates

```
Phase 1 — Onboarding Redesign
  New files:    ~3 (role selection screen, caregiver flow, self flow)
  Modified:     ~4 (SettingsService, OnboardingFlow, app routes, ARB files)
  Risk:         Low (UI-only, no detection logic changes)

Phase 2 — Guardian Alert Service
  New files:    ~2 (GuardianAlertService, Kotlin intent helper)
  Modified:     ~3 (SecurityController, SmsReceiver.kt, SettingsService)
  Risk:         Medium (WhatsApp intent behavior varies across OEMs)

Phase 3 — Subscription + Paywall
  New files:    ~3 (SubscriptionService, paywall screen, subscription provider)
  Modified:     ~3 (pubspec.yaml, GuardianAlertService, settings screen)
  Risk:         Medium (Play Billing edge cases: pending, deferred, grace period)

Phase 4 — Heartbeat & Summary
  New files:    ~2 (HeartbeatWorker.kt, heartbeat_service.dart)
  Modified:     ~2 (MainActivity.kt, database queries)
  Risk:         Medium (WorkManager reliability across OEMs, battery optimization)

Phase 5 — Caregiver-Side Experience
  New files:    ~3 (caregiver home screen, share helper, status parser)
  Modified:     ~2 (MainShell, app routes)
  Risk:         High (NotificationListenerService is fragile and permission-heavy)

Phase 6 — Backend (v2)
  Scope:        Full backend build — separate planning needed
```

---

## Key Technical Decisions Locked In

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Same APK or two apps | Same APK, role-based | Single codebase, simpler maintenance |
| Caregiver visibility | WhatsApp alerts (sender + risk, no content) | Privacy-first, no backend needed |
| Backend in v1 | No | WhatsApp as transport layer |
| Free tier scope | Full protection, no detection limits | Safety is free, peace-of-mind is paid |
| Subscription handler | Google Play Billing (local verification) | No server needed for v1 |
| Alert transport | WhatsApp intent (primary), SMS (fallback) | Universal in Indian market |
| Linking mechanism | Physical setup or WhatsApp instructions + phone call | Friction is a feature — builds trust |

---

## Files to Create (All Phases)

```
lib/
├── features/
│   └── onboarding/
│       └── presentation/
│           ├── role_selection_screen.dart        ← Phase 1
│           ├── caregiver_flow.dart               ← Phase 1
│           └── self_protection_flow.dart         ← Phase 1
├── services/
│   ├── guardian_alert_service.dart               ← Phase 2
│   ├── subscription_service.dart                 ← Phase 3
│   └── heartbeat_service.dart                    ← Phase 4
├── presentation/
│   ├── paywall/
│   │   └── guardian_paywall_screen.dart          ← Phase 3
│   └── caregiver/
│       ├── caregiver_home_screen.dart            ← Phase 5
│       └── share_install_helper.dart             ← Phase 5

android/app/src/main/kotlin/com/eldershield/elder_shield/
├── WhatsAppIntentHelper.kt                       ← Phase 2
└── HeartbeatWorker.kt                            ← Phase 4
```

## Files to Modify (All Phases)

```
lib/features/onboarding/presentation/onboarding_flow.dart   ← Phase 1
lib/features/settings/data/settings_service.dart             ← Phase 1
lib/features/security/application/security_controller.dart   ← Phase 2
lib/features/shell/presentation/main_shell.dart              ← Phase 5
lib/application/app_providers.dart                           ← Phase 3
lib/core/navigation/app_routes.dart                          ← Phase 1, 5
lib/l10n/app_*.arb (9 files)                                 ← Phase 1
pubspec.yaml                                                 ← Phase 3
android/.../SmsReceiver.kt                                   ← Phase 2
android/.../MainActivity.kt                                  ← Phase 4
```
