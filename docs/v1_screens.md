# Elder Shield — V1 Screen List

Navigation model: bottom nav bar with 3 tabs (Home, Messages, Settings). Onboarding is a one-time flow shown on first launch. Risk Detail is a modal sheet pushed from the Messages list.

---

## Screen 1 — Onboarding: Welcome

**Purpose:** Introduce the app in one sentence; set expectations; reduce anxiety for non-tech users.

**Must-have interactions:**
- Large "Get Started" button advances to next onboarding step.
- App icon and name displayed prominently.
- One-sentence plain-language description: "Elder Shield watches your messages and calls to warn you about scams."

---

## Screen 2 — Onboarding: Permissions Explanation

**Purpose:** Explain in plain English why SMS and phone permissions are needed, before the system dialog appears. Builds informed consent.

**Must-have interactions:**
- Two plain-language bullets explaining each permission (SMS: "to read your messages", Phone: "to know when you're on a call").
- "Allow Permissions" button triggers the Android permission dialogs sequentially.
- If permission denied: show a gentle retry message with a "Try Again" button; allow skipping with a clear warning that protection will be limited.

---

## Screen 3 — Onboarding: Add a Trusted Contact

**Purpose:** Guide user to add at least one trusted contact (family member or caregiver) who can be called in an emergency.

**Must-have interactions:**
- "Add Contact" button opens device contact picker.
- Selected contact name shown with a confirmation checkmark.
- "Skip for now" link (visible but de-emphasised); user can add later in Settings.
- "Done" / "Finish Setup" button completes onboarding and navigates to Home.

---

## Screen 4 — Home

**Purpose:** Daily-use landing screen. Shows protection status at a glance and surfaces the emergency call action prominently.

**Must-have interactions:**
- Protection status indicator: green shield ("Protected") or amber shield ("Permissions needed").
- Today's risk summary: "X suspicious messages detected today" or "No suspicious activity today."
- Large, high-contrast **"Call [Trusted Contact Name]"** button (minimum 56 dp height).
- If no trusted contact set: button replaced with "Add a trusted contact" prompt.
- Tap on risk summary navigates to Messages tab filtered to today.

---

## Screen 5 — Messages (Risk History List)

**Purpose:** Let the user review all messages the app has analyzed, sorted newest-first.

**Must-have interactions:**
- List item shows: sender, message snippet (first ~60 chars), timestamp, risk badge (LOW / MEDIUM / HIGH with colour).
- Tap on any item navigates to Risk Detail sheet.
- Empty state: "No messages analyzed yet. Elder Shield will check new messages automatically."
- Pull-to-refresh (re-queries local DB; no network call).
- Filter chips at top: All / High Risk.

---

## Screen 6 — Risk Detail (Modal Bottom Sheet)

**Purpose:** Show exactly why a message was flagged and give the user clear, simple actions.

**Must-have interactions:**
- Message sender and full body displayed (plain text, large font).
- Risk band label ("HIGH RISK — Possible Scam") with colour coding.
- Reasons list in plain English (e.g., "Contains a suspicious link", "Asks for your OTP", "Pretends to be your bank").
- Three action buttons, large and clearly labelled:
  1. **"This is a Scam"** — saves user feedback label; shows confirmation.
  2. **"This is Safe"** — saves user feedback label; dismisses sheet.
  3. **"Call [Trusted Contact]"** — initiates phone call immediately.
- "Block this sender" link (opens Android messaging app; app does not block directly).

---

## Screen 7 — Settings

**Purpose:** Let the user control sensitivity, manage trusted contacts, and maintain their privacy.

**Must-have interactions:**
- **Sensitivity Mode** toggle/selector: Conservative / Balanced / Sensitive (default: Conservative). Each option has a one-line plain-language description.
- **Trusted Contacts** section: list of saved contacts (max 3) with edit and remove options; "Add Contact" button.
- **Delete All History** button: shows a confirmation dialog before clearing local SQLite data.
- **Re-run Permissions Check** link: re-triggers permission dialogs for users who denied earlier.
- App version displayed at bottom (for support calls).

---

## Screen 8 — High-Risk Warning Sheet (In-App Alert)

**Purpose:** Interrupt the user immediately when a high-risk message arrives while the app is in the foreground. This is distinct from Screen 6 (which is browsable history); this is a proactive alert.

**Must-have interactions:**
- Displayed as a full-screen-height bottom sheet that slides up automatically.
- Large warning header: "Warning: Possible Scam Message"
- Sender and abbreviated message body.
- Top reason in bold (e.g., "Someone is asking for your OTP while you're on a call").
- Three actions identical to Risk Detail (This is a Scam / This is Safe / Call Trusted Contact).
- Sheet is dismissible by swipe-down; dismissal is recorded as "no action taken".
