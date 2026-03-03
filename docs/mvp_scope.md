# Elder Shield — MVP Scope

## In-Scope Features (Phase 1)

1. **SMS Risk Detection** — On-device heuristic analysis of incoming SMS messages for scam indicators (suspicious URLs, OTP phishing, urgency keywords, bank/KYC bait phrases).
2. **Call-State Awareness** — Detect active phone calls and boost risk score if an OTP SMS arrives during a call (a common social-engineering pattern).
3. **Real-Time Alerts** — Push a local notification for medium-risk messages; show an in-app warning sheet for high-risk messages with one-tap actions.
4. **Risk History Screen** — A scrollable list of recently analyzed messages with a colour-coded risk badge (low / medium / high), persisted locally via SQLite.
5. **Trusted Contact (Emergency Call)** — Store 1–3 trusted contacts; expose a single large "Call Trusted Contact" button on the home screen and on every warning sheet.
6. **Sensitivity Mode Setting** — Let the user choose Conservative / Balanced / Sensitive detection thresholds without exposing raw numbers.
7. **Local-Only Data Storage** — All analyzed messages and settings stored on-device; no data ever leaves the device in Phase 1.

---

## Out-of-Scope Features (Phase 1)

1. **Cloud / Server-Side Analysis** — No message content is sent to any external server. Cloud ML models are deferred to Phase 2.
2. **Call Recording or Transcription** — The app does not record, transcribe, or listen to call audio.
3. **Automatic SMS Blocking** — Blocking requires the app to be the default SMS handler; this UX friction is deferred.
4. **Spam Caller ID / CNAM Lookup** — Phone-number reputation lookup against an external database is out of scope.
5. **Multi-Language / Regional Script Support** — Phase 1 targets English keywords only; regional language packs are deferred.
6. **Caregiver Remote Dashboard** — A family-member monitoring portal is deferred to Phase 2.
7. **User Accounts / Sign-In** — No authentication, no cloud profile. The app works fully offline and account-free.

---

## Non-Goals

- This app is **not** a replacement for law enforcement or bank fraud teams.
- This app does **not** guarantee catching every scam; it is a best-effort on-device heuristic aid.
- This app will **not** read, store, or transmit SMS body content off-device.
- Accessibility compliance beyond basic font scaling is not a Phase 1 deliverable (tracked for Phase 2).

---

## Risks and Assumptions

| # | Risk / Assumption | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| 1 | Google Play's SMS permission policy may require proof of "core functionality" justification. | Medium | High | Prepare detailed Play Console declaration; position app as a safety tool for elderly users. |
| 2 | Android 10+ restricts background SMS access for non-default SMS apps. | High | High | App requests `RECEIVE_SMS` and documents justification; guide users through permission grant at onboarding. |
| 3 | Heuristic detector produces false positives on legitimate bank OTPs. | High | Medium | Default to Conservative threshold; let users mark messages as safe; tune keywords conservatively. |
| 4 | Elderly users may not complete onboarding (e.g., default SMS step is confusing). | Medium | Medium | Use plain-language copy, skip steps gracefully, and allow re-run from Settings. |
| 5 | Solo developer timeline (2–4 weeks) is tight; scope creep risks delay. | Medium | High | Strict block-by-block execution; defer any nice-to-have to Phase 2 backlog. |
