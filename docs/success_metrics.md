# Elder Shield — Phase 1 Success Metrics

All metrics are measured on-device or via Play Store console. No user data is transmitted to measure these.

---

## Metric 1 — False-Positive Rate on Legitimate OTPs

| Field | Detail |
|---|---|
| **What it measures** | How often the detector flags a real bank/service OTP as medium or high risk |
| **Why it matters** | High false-positive rate erodes user trust and causes alert fatigue |
| **Measurement method** | Manual test suite: run ≥ 50 known-legitimate SMS fixtures through the detector; count flags |
| **Phase 1 target** | ≤ 15% of legitimate OTP fixtures flagged as medium or high |

---

## Metric 2 — True-Positive Rate on Scam Fixtures

| Field | Detail |
|---|---|
| **What it measures** | How often the detector correctly flags a known scam SMS as medium or high risk |
| **Why it matters** | Core safety value of the app |
| **Measurement method** | Manual test suite: run ≥ 50 known-scam SMS fixtures; count correct detections |
| **Phase 1 target** | ≥ 80% of scam fixtures flagged as medium or high |

---

## Metric 3 — Onboarding Completion Rate

| Field | Detail |
|---|---|
| **What it measures** | Percentage of users who reach the Home screen after first install (i.e., complete onboarding) |
| **Why it matters** | Protection is only active after onboarding; drop-offs mean unprotected users |
| **Measurement method** | Track `onboarding_complete` flag in local storage; compare against install count via Play Console |
| **Phase 1 target** | ≥ 70% of installs complete onboarding within 24 hours |

---

## Metric 4 — Alert-to-Action Rate

| Field | Detail |
|---|---|
| **What it measures** | Percentage of high-risk alerts where the user takes an action (Mark Safe, Mark Scam, or Call Trusted Contact) vs. dismisses without acting |
| **Why it matters** | Shows whether alert UI is understandable and actionable for elderly users |
| **Measurement method** | Local SQLite counter: alerts shown vs. actions recorded; reported in a dev-only debug screen |
| **Phase 1 target** | ≥ 50% of high-risk alerts result in an explicit action |

---

## Metric 5 — Crash-Free Session Rate

| Field | Detail |
|---|---|
| **What it measures** | Percentage of app sessions that complete without a fatal crash |
| **Why it matters** | Elderly users are unlikely to retry after a crash; reliability is non-negotiable |
| **Measurement method** | Google Play Vitals — Android Vitals crash-free sessions dashboard |
| **Phase 1 target** | ≥ 99% crash-free sessions within 14 days of launch |
