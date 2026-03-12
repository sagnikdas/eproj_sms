## Elder Shield – Phased Product & Tech Plan

This plan describes how to evolve the current app into the full “remote caregiver + self-serve parent” product, in small shippable phases. Each phase has **objectives**, **scope**, and **exit criteria**. You can decide to stop after any phase and still have a coherent product.

Phases are designed to be compatible with the existing Flutter codebase (current `OnboardingFlow → LaunchGate → MainShell` flow) and the subscription/paywall design in `SUBSCRIPTION_AND_PAYWALL_DESIGN.md`.

---

## Phase 0 – UX Wrapper & Story (no backend)

**Goal:** Validate and polish the startup experience for caregivers and parents, without needing any backend or payment integration.

### Objectives
- Introduce the **Setup Mode** concept (“for my parent” vs “for myself”).
- Introduce the **Get Protected** screen with the two key actions:
  - “Activate with link/code”
  - “Subscribe now” (stub only)
- Keep the rest of the app behavior unchanged once “activated” is considered true locally.

### Scope – App (Flutter) changes
- Add `SetupModeScreen` before existing `OnboardingFlow`:
  - Two large buttons: “I’m setting this up for my parent” / “I’m setting this up for myself”.
  - Store chosen mode in secure storage (for analytics and copy tweaks later).
- Add `GetProtectedScreen` after `SetupModeScreen`:
  - Primary actions:
    - “I already have a link or code” (navigates to a stubbed activation screen).
    - “Subscribe now” (for now: informational; later opens web paywall).
  - Secondary:
    - “Ask family to sponsor me” (for now: opens a pre-filled share message only).
- Add a simple `ActivationScreen`:
  - Text field for a code.
  - “Activate” button that just **pretends** success (sets `activated=true` locally).
  - Copy tuned for both modes (caregiver vs self).
- Update `app.dart`:
  - New gate:
    - If onboarding not complete:
      - Show `SetupModeScreen` → `GetProtectedScreen` → `ActivationScreen` → existing `OnboardingFlow`.
    - If onboarding complete:
      - Existing behavior → `LaunchGate` → `MainShell`.
- No network calls, no real payment/activation.

### Scope – Backend / Infra / Dashboard
- None in this phase.

### Exit criteria
- You can build and run the app and walk a user through:
  - Caregiver-mode startup.
  - Self-mode startup.
- Copy, flow, and visual design feel coherent and understandable to a non-technical tester.

---

## Phase 1 – Minimal Backend, Web Paywall & Activation Codes (Caregiver Pays)

**Goal:** Allow a caregiver to pay on a web page, receive an activation code or link, and have the parent activate the app on their phone.

### Objectives
- Implement a simple backend service (+ database) to:
  - Accept web paywall callbacks / hosted checkout success.
  - Create `Subscription` and `Activation` records.
  - Provide a `POST /activate` API for the app.
- Wire the app’s `ActivationScreen` to call `POST /activate`.
- Keep self-serve “Subscribe now” in the app as a stub (no live payment yet).

### Scope – Backend & Dashboard
- Backend stack of your choice (e.g. Node/Express, FastAPI, NestJS, etc.).
- Data tables (or collections):
  - `subscriptions`: `{ id, payerEmail, plan, status, providerRef, createdAt, expiresAt }`.
  - `activations`: `{ id, subscriptionId, code, deviceId?, parentLabel?, usedAt }`.
- Integrate with a hosted payment solution (Stripe Checkout, Razorpay, Paddle, etc.):
  - Hosted checkout session creation endpoint.
  - Webhook/callback handler that:
    - Verifies successful payment.
    - Creates `Subscription` + `Activation` code.
  - Simple success page:
    - Shows activation code + pre-composed “Send to parent” message.
- API for the app:
  - `POST /activate`:
    - Request: `{ code, deviceId, parentPhoneOrName? }`.
    - Response: `{ activated: true/false, reason?, expiresAt? }`.
  - Throttling and basic logging.
- Admin/debug dashboard (can be very simple, even raw DB viewer initially):
  - List of subscriptions.
  - List of activations and their status (used/unused, deviceId, parent label).

### Scope – App (Flutter)
- `ActivationScreen`:
  - On “Activate”, call backend `POST /activate`.
  - On success: persist `activationToken`/`expiresAt` + `activated=true` in `SettingsService`.
  - On failure: show clear error and allow retry.
- `GetProtectedScreen`:
  - “Activate with link/code” now uses the real `ActivationScreen`.
  - “Subscribe now” still shows an informational message + link to the caregiver web paywall (in browser).

### Exit criteria
- End-to-end demo:
  - Caregiver pays on web → sees activation code → sends to parent.
  - Parent installs app → enters code → app unlocks and runs as today.
- Logs and DB records are correct and traceable for support.

---

## Phase 2 – User Accounts (Caregivers), Basic Portal & Data Model Hardening

**Goal:** Introduce proper caregiver accounts and a simple portal to see/manage their subscriptions and activated devices.

### Objectives
- Add **user accounts for caregivers** (email/OTP or email+password).
- Extend backend data model to include `users` and `protectionLinks` (caregiver ↔ device).
- Build a small caregiver portal dashboard.

### Scope – Backend & Portal
- Add `users` table:
  - `{ id, email, role (caregiver|self), createdAt, consentFlags }`.
- Associate `subscriptions.ownerUserId` with `users.id`.
- Add `protection_links` table:
  - `{ id, caregiverUserId, deviceId, label, status, createdAt }`.
- Caregiver portal (web app):
  - Auth (email-based, or delegate to Firebase Auth).
  - Screen: “My subscriptions & protected devices”:
    - For each subscription:
      - plan, status, renewal date.
      - linked devices (from activations/protection_links).
  - Basic actions:
    - Rename device label (e.g. “Mom”, “Dad”).
    - Revoke a device (marks an activation as invalid, optional at this stage).
- Update paywall:
  - Require caregiver login or quick account creation as part of checkout flow.

### Scope – App (Flutter)
- No major new UI required; primary change is that activations now map to a `user` and `protectionLink` on backend.
- Optionally:
  - During activation, allow the parent or caregiver to confirm / adjust the parent label (e.g. “This phone belongs to: [Name]”).

### Exit criteria
- Caregiver can log into portal and see:
  - Subscriptions they own.
  - Which devices are protected under each.
- Backend schema for `User`, `Subscription`, `Activation`, `ProtectionLink` is stable for future phases.

---

## Phase 3 – Firebase Integration (Authentication & Push Notifications)

**Goal:** Introduce Firebase for authentication (optional) and device notifications, to support reminders and future caregiver alerts.

### Objectives
- Use **Firebase Cloud Messaging (FCM)** for device push notifications.
- Optionally move auth to **Firebase Authentication** (for caregivers), or integrate it with existing auth system.

### Scope – Backend & Infra
- Set up a Firebase project:
  - Enable FCM.
  - (Optionally) Enable Firebase Auth with email/OTP or email/password.
- Backend:
  - Store FCM `pushToken` for each `device` record.
  - Expose endpoints for the app to register/update `pushToken`.
  - Implement server-side send helpers for:
    - Onboarding completion reminders (e.g. if onboarding not finished within X hours).
    - Subscription status updates (renewal failed, about to expire, etc.).

### Scope – App (Flutter)
- Integrate Firebase (for Android initially):
  - FCM setup.
  - On first run (or post-onboarding), register device with backend:
    - `{ deviceId, platform, appVersion, locale, pushToken }`.
- Use push notifications sparingly and only with clear in-app consent:
  - “Allow important safety alerts and reminders?” (opt-in).

### Exit criteria
- Devices can receive and display push notifications triggered by backend.
- Device registration info is visible in backend/portal (e.g. lastSeen, appVersion).

---

## Phase 4 – Self-Serve Parent Subscription & Sponsorship Flow

**Goal:** Allow parents to pay themselves or request sponsorship seamlessly, while keeping caregiver-pay flow intact.

### Objectives
- Make “Subscribe now” in the app fully functional.
- Implement “Ask family to sponsor me” links that connect a payment to a specific device.

### Scope – Backend & Portal
- Extend hosted paywall to support:
  - **Self** subscriptions, where the payer is also the device owner.
  - **Sponsorship** links, tied to a specific `deviceId`.
- Flows:
  - Self-subscribe:
    - Parent taps “Subscribe now” in app → opens paywall with context `mode=self&deviceId=...`.
    - On success: backend creates user (role=self), subscription, and activation bound directly to that `deviceId` (no code entry).
  - Sponsorship:
    - Parent taps “Ask family to sponsor me” in app:
      - Backend creates a sponsorship link (associated with this `deviceId`).
      - Parent shares link (WhatsApp/SMS).
    - Caregiver opens link, pays.
    - Backend links new subscription to that `deviceId`.
- Caregiver portal:
  - Shows which devices were self-subscribed vs sponsored.

### Scope – App (Flutter)
- `GetProtectedScreen`:
  - “Subscribe now” → open external browser with paywall URL including `deviceId` and mode.
  - On return (via deep link or polling):
    - Call backend to verify subscription state for this `deviceId`.
    - If active: mark `activated=true` and proceed as usual.
- “Ask family to sponsor me”:
  - Call backend to generate sponsorship link (or use install/deviceId to build).
  - Open share sheet with pre-filled explainer and link.

### Exit criteria
- Parent can:
  - Subscribe themselves.
  - Or ask family to pay and be activated once payment is done.
- Caregiver-pay and self-pay paths coexist without UX confusion.

---

## Phase 5 – Remote Assist & Setup Progress (Optional but Valuable)

**Goal:** Help remote caregivers guide parents through onboarding and permissions without being physically present.

### Objectives
- Let the app report **high-level setup progress** to backend (no sensitive content).
- Let caregivers see progress in portal and get non-intrusive hints on how to help.

### Scope – Backend & Portal
- Add `setup_progress` tracking per `device`:
  - Example states: `not_started`, `mode_selected`, `activated`, `permissions_granted`, `trusted_contact_set`, `onboarding_complete`.
- Portal:
  - For each device:
    - Show a simple progress bar or checklist.
    - Provide text hints (“Ask your parent to enable SMS permissions in step 2”).

### Scope – App (Flutter)
- At key milestones, send small progress updates:
  - After `SetupModeScreen` → `mode_selected`.
  - After successful activation → `activated`.
  - After permissions screen → `permissions_granted`.
  - After trusted contact screen → `trusted_contact_set`.
  - When onboarding ends → `onboarding_complete`.
- Optional:
  - “I need help” button on key screens that explains what to tell the caregiver.

### Exit criteria
- Caregiver can glance at portal and know roughly **where** the parent is stuck during setup, without any privacy violations.

---

## Phase 6 – Future Premium: Location Safety for Dementia/Parkinson’s

**Goal:** Provide a high-trust, opt-in location feature to help find a parent in emergencies.

### Objectives
- Add a robust, consent-driven location safety feature as a premium layer.

### Scope – Backend & Portal
- Extend data model with a `locations` table:
  - `{ id, deviceId, lat, lng, capturedAt }` with strict retention.
- APIs:
  - `POST /location` (from app, when sharing is enabled).
  - `GET /location/latest` (for authorized caregivers).
- Portal:
  - Simple map view showing last known location for a protected device.
  - Audit log of location requests (who, when).

### Scope – App (Flutter)
- Settings screen:
  - “Location safety” section with:
    - Toggle to enable/disable location sharing for caregiver(s).
    - Clear explanation and link to privacy details.
- Location service:
  - Background-safe implementation for Android (with persistent notification as required).
  - Respect OS and user controls; pause when toggled off.

### Exit criteria
- For devices with explicit consent:
  - Caregiver can request and view last known location via portal.
- Parent can pause or disable sharing at any time.

---

## Phase 7 – Future Cross-App Invitations (Re-use of Trust)

**Goal:** Allow ethically sound invitations to future related apps without undermining Elder Shield’s trust.

### Objectives
- Implement a minimal marketing-consent system and messaging workflow.

### Scope – Backend & Portal
- Add `consentFlags` on `users`:
  - e.g. `{ futureAppsEmail: true/false }`.
- Expose a simple admin/ops interface to:
  - Query users who opted in.
  - Trigger low-frequency announcements about new safety apps.

### Scope – App (Flutter)
- During onboarding or in settings:
  - Checkbox: “Tell me about future safety apps we build” (opt-in).
  - Separate from mandatory transactional emails/notifications.

### Exit criteria
- You can send occasional, clearly-labeled invites to future products to only those users who explicitly opted in, with an easy way to opt out.

---

This overall plan is intentionally modular. You can:
- Ship early with Phase 1 (caregiver pays on web + activation).
- Layer in Firebase, self-serve, remote assist, and location as your user base and needs grow.
