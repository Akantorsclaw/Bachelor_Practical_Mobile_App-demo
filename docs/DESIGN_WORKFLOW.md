# Design Workflow and UI Traceability

**Project:** Bachelor_Practical_Mobile_App

---

## 1. Purpose

This document establishes the workflow for recording, tracking, and validating UI changes across the application lifecycle. It serves as the traceability record between design intent and implemented screens.

---

## 2. Screenshot Storage Convention

All design screenshots are stored under `docs/screenshots/design/`.

**Format:** `.png`

**Naming scheme:** `{screen_id}_{screen_name}_v{version}.png`

| Screen ID | Screen |
|---|---|
| `01` | Auth — Login |
| `02` | Auth — Registration |
| `03` | Auth — Password Reset |
| `10` | Home — Dashboard |
| `20` | Lens Registration |
| `30` | My Lenses |
| `40` | Digital Passport — Lens Details |
| `41` | Digital Passport — Prescription |
| `42` | Digital Passport — Frame Measurements |
| `50` | Profile Overview |
| `51` | Notification Settings |
| `52` | Privacy & Data Protection |
| `60` | Rate Lens |
| `61` | Rate Optician |
| `62` | Edit Review |

When a screen is revised, increment the version suffix: `_v2.png`, `_v3.png`, and so on. Do not overwrite existing version files.

---

## 3. AI-Assisted Design Workflow

AI models are used as implementation support tooling, not as decision-making authorities. Human review and approval are required at every stage.

### Permitted AI support tasks

- Converting visual references into structured implementation tasks
- Mapping design intent to reusable Flutter widgets and palette tokens
- Identifying inconsistencies between design mockups and the current UI
- Proposing responsive layout adjustments prior to implementation
- Translating brand guidelines into concrete colour, spacing, and component changes

### Human review requirements

The following decisions require human approval regardless of AI involvement:

- Final brand fidelity validation
- Business constraint compliance (B2B2C model, mandatory optician role)
- Legal and privacy-sensitive wording
- Release decisions and checkpoint tagging

### Documentation requirement for AI-assisted steps

When an AI model supports a redesign iteration, record the following:

1. Target screen
2. Input material provided (mockup, screenshot, brand guideline)
3. Implementation outcome
4. Validation performed (static analysis, runtime test, visual review)

---

## 4. Screen Design Records

### 4.1 Authentication

**Files:** `01_auth_login_v1.png`, `02_auth_register_v1.png`, `03_auth_reset_v1.png`

- Full-screen layouts without card containers.
- Brand logo loaded from `authLogo.svg`; falls back to `auth_logo.png` if SVG is absent.

---

### 4.2 Home — Dashboard

**File:** `10_home_dashboard_v1.png`

- Dynamic greeting using authenticated user's display name.
- Activity stats row (lens count, rating count, days since last rating).
- Current lens card with inline rating display.
- Quick action grid: Register Lens, My Lenses, Rate Experience, Lens Passport.
- Upcoming check-up reminder calculated from lens purchase date (180-day interval).

---

### 4.3 Lens Registration

**File:** `20_lens_registration_v1.png`

- Name input field pre-filled on successful QR scan.
- QR scan button launches `QrScannerScreen`; parsed fields populate form automatically.
- Optician selector (dropdown).
- Registered lenses are persisted to Firestore under `users/{uid}/lenses`.

---

### 4.4 My Lenses

**File:** `30_my_lenses_v1.png`

- Per-lens card showing name, purchase date, optician, and rating badge.
- Delete action with confirmation dialog.
- `Rate / Update Review` shortcut per lens card.

---

### 4.5 Digital Lens Passport

**Files:** `40_digital_passport_lens_details_v1.png`, `41_digital_passport_prescription_v1.png`, `42_digital_passport_frame_measurements_v1.png`

- Segmented control for three tabs: Lens Details, Prescription, Frame Measurements.
- Data is sourced from QR payload URL query parameters parsed by `LensPassQrParser`.
- Tapping a field label opens a bottom sheet explanation sourced from `LensParameterInfoService`.
- Info sheets and overlays adapt to the active brand palette, including SEIKO dark chrome.

---

### 4.6 Profile Overview

**File:** `50_profile_settings_v1.png`

- Branded gradient hero header with identity card (avatar initials, name, member since, lens count badge).
- Account information section: email (editable), optician (placeholder).
- Activity metrics: lenses owned, reviews given, average rating.
- Settings shortcuts: Notification Settings, Privacy & Data Protection.
- Logout action requires confirmation dialog.
- Profile updates require confirmation dialog.

---

### 4.7 Notification Settings

**File:** `51_notification_settings_v1.png`

- Branded gradient hero header.
- Channel cards: Push Notifications, Email Notifications.
- Notification type rows: Rating Reminders, Service Notifications, New Lens Alerts.
- Informational card.
- Save action (currently persists to local state only; backend persistence is a pending Should-Have item).

---

### 4.8 Privacy & Data Protection

**File:** `52_privacy_data_protection_v1.png`

- Branded gradient hero header.
- GDPR compliance status card.
- Data Processing Consent toggle with active/inactive status indicator.
- Data Sharing toggles: Share with Optician, Share with Company (disabled when consent is inactive).
- Data We Store: informational cards listing stored data categories.
- Your Rights: Download My Data and View Privacy Policy (placeholder flows).
- Save Privacy Settings action persists preferences to Firestore.
- Withdraw Consent section with destructive confirmation flow and loading overlay.

---

### 4.9 Rating — Create

**File:** `60_rate_lens_v1.png`, `61_rate_optician_v1.png`

- `Rate Lens` requires selecting a registered lens from a bottom sheet picker.
- Empty state: `No lens registered.` snackbar when no lenses exist.
- Overall star rating (enlarged for touch accessibility).
- Per-aspect rating rows.
- Comment text field.
- Reviews saved to Firestore via `ReviewService.upsertReview`.

---

### 4.10 Rating — Edit

**File:** `62_edit_review_v1.png`

- Pre-populated from existing `AppReview` document.
- Update action overwrites the existing review document.
- Delete action removes the review document.

---

## 5. Update Checklist

For every UI assignment or screen revision:

1. Save updated screenshot(s) in `docs/screenshots/design/` with an incremented version suffix.
2. Update the corresponding file path entry in Section 4 of this document.
3. If the screenshot represents a specific brand variant (e.g. SEIKO dark theme), note this alongside the file path.
4. If AI support was used, add a brief note in the relevant screen section describing the support task and validation outcome.
5. If a new colour role or reusable style rule was introduced, update `docs/BRANDING.md`.
6. If behaviour or structure changed, update:
   - `docs/ARCHITECTURE_OVERVIEW.md`
   - `docs/FUNCTIONS_EXPLAINED.md`
   - `docs/BACHELOR_PRACTICAL_WORKFLOW.md` (assignment log section)
