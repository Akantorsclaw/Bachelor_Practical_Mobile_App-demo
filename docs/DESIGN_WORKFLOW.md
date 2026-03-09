# Design Workflow (Screenshot Trace)

This document tracks the UI evolution per screen and links each state to saved screenshots.

## Screenshot Storage Convention

- Folder: `docs/screenshots/design/`
- Format: `.png`
- Naming:
  - `01_auth_login_v1.png`
  - `02_auth_register_v1.png`
  - `03_auth_reset_v1.png`
  - `10_home_dashboard_v1.png`
  - `20_lens_registration_v1.png`
  - `30_my_lenses_v1.png`
  - `40_digital_passport_lens_details_v1.png`
  - `41_digital_passport_prescription_v1.png`
  - `42_digital_passport_frame_measurements_v1.png`
  - `50_profile_settings_v1.png`
  - `51_notification_settings_v1.png`
  - `52_privacy_data_protection_v1.png`
  - `60_rate_lens_v1.png`
  - `61_rate_optician_v1.png`
  - `62_edit_review_v1.png`

When you revise a screen, increment the suffix:
- `*_v2.png`, `*_v3.png`, ...

## Current Design Workflow

## 1. Authentication
- Login: `docs/screenshots/design/01_auth_login_v1.png`
- Registration: `docs/screenshots/design/02_auth_register_v1.png`
- Password Reset: `docs/screenshots/design/03_auth_reset_v1.png`
- Notes:
  - Full-screen layouts (no card containers).
  - Brand logo loaded from `authLogo.svg` (SVG-first, PNG fallback).

## 2. Core Navigation and Home
- Home/Dashboard: `docs/screenshots/design/10_home_dashboard_v1.png`
- Notes:
  - Dynamic greeting with user name.
  - Dynamic overview stats and quick actions.
  - Existing bottom navigation is retained.

## 3. Lens Flows
- Lens Registration: `docs/screenshots/design/20_lens_registration_v1.png`
- My Lenses: `docs/screenshots/design/30_my_lenses_v1.png`
- Notes:
  - Lenses are persisted to Firestore per user.
  - My Lenses supports delete and `Update Review`.

## 4. Digital Lens Passport
- Lens Details: `docs/screenshots/design/40_digital_passport_lens_details_v1.png`
- Prescription: `docs/screenshots/design/41_digital_passport_prescription_v1.png`
- Frame Measurements: `docs/screenshots/design/42_digital_passport_frame_measurements_v1.png`
- Notes:
  - Data is parsed from QR payload URL query parameters.
  - Tapping field labels opens explanation cards.

## 5. Profile and Settings
- Profile Settings: `docs/screenshots/design/50_profile_settings_v1.png`
- Notification Settings: `docs/screenshots/design/51_notification_settings_v1.png`
- Privacy & Data Protection: `docs/screenshots/design/52_privacy_data_protection_v1.png`
- Notes:
  - Profile overview uses a branded hero header, elevated identity card, account cards, activity stats, and settings shortcuts.
  - Notification settings uses a branded hero header, channel cards, grouped notification-type rows, and a dedicated save action.
  - Profile updates require confirmation.
  - Logout is prominent and requires confirmation.
  - GDPR withdrawal action remains explicit.

## 6. Ratings
- Rate Lens: `docs/screenshots/design/60_rate_lens_v1.png`
- Rate Optician: `docs/screenshots/design/61_rate_optician_v1.png`
- Edit Review: `docs/screenshots/design/62_edit_review_v1.png`
- Notes:
  - `Rate Lens` requires selecting a registered lens first.
  - Empty state guard: `No lens registered.`
  - Reviews are saved/updated in Firestore.

## Update Checklist (Per New UI Assignment)

1. Save updated screenshot(s) in `docs/screenshots/design/` with incremented version.
2. Update affected section paths in this file.
3. Add one short change note under the relevant screen group.
4. If behavior changed too, update:
   - `README.md`
   - `docs/ARCHITECTURE_OVERVIEW.md`
   - `docs/FUNCTIONS_EXPLAINED.md`
   - `docs/BACHELOR_PRACTICAL_WORKFLOW.md` (assignment log)
