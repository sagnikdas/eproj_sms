# Block 10 — In-App Privacy Policy & Permissions Explained

## Goal

Make the privacy policy and permission explanations **accessible inside the app** so users can read them without leaving the app. This supports store compliance (e.g. Google Play) and builds trust.

## Delivered

1. **Privacy Policy screen** (`lib/presentation/settings/privacy_policy_screen.dart`)
   - Full scrollable privacy policy text matching [privacy_policy_draft.md](privacy_policy_draft.md).
   - Sections: Who we are, Data we process, What we do not do, Permissions, Data retention, Children/sensitive users, Policy changes, Contact.
   - App bar includes app icon. Placeholder in §8 Contact: *[insert your contact email or support URL here]* — replace before release.

2. **Permissions explained screen** (`lib/presentation/settings/permissions_explained_screen.dart`)
   - Short summary of why we need each permission (SMS, Phone state, Phone call, Notifications).
   - Content aligned with [permission_disclosures.md](permission_disclosures.md).

3. **Settings entries**
   - **Legal & information** section with:
     - **Privacy policy** — opens the full policy screen.
     - **Permissions explained** — opens the short permissions summary.

## Manual test

1. Open the app → Settings.
2. Under **Legal & information**, tap **Privacy policy**. Confirm the full policy scrolls and sections are readable.
3. Back → tap **Permissions explained**. Confirm the four permissions are described clearly.
4. Confirm app icon appears in the app bar on both screens.

## Before release

- Replace the contact placeholder in the in-app privacy policy (§8) and in [privacy_policy_draft.md](privacy_policy_draft.md) with your support email or URL.
- If you host the policy online, you can later change the "Privacy policy" row to open that URL in a browser instead of the in-app screen (optional).

---

*Block 10 completed. Next: Block 11 (if defined) or store listing / release.*
