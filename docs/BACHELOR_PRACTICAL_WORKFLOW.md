# Bachelor Practical Project Workflow Documentation

Project: `MyLens_App_bachelor_practical`  
Author: Dominik Bien  
Report generated: 2026-02-16

## 1. Project Purpose

This project implements a branded Flutter mobile application for HOYA digital lens workflows. The practical objective is to design, build, and iteratively improve a production-like app that covers:

- account onboarding and authentication,
- GDPR consent flow,
- QR-based lens registration,
- user-linked lens persistence,
- digital lens passport display,
- rating/feedback flow,
- maintainable architecture and documentation.

### 1.1 Business Model Constraint (B2B2C)

An important project constraint is the **B2B2C model**:

- HOYA does not interact with the end customer only in a direct D2C manner.
- The **optician is a mandatory intermediary** in the product and service chain.
- Therefore, the app scope and UX must not bypass the optician role.

Practical implications for this project:

- Optician context is retained in lens registration and profile-related flows.
- Product decisions prioritize customer + optician collaboration, not pure self-service.
- Future features must preserve the optician as part of onboarding, support, and follow-up workflows.

## 2. Working Methodology

The implementation process follows an iterative assignment-based workflow:

1. Requirement clarification and scope definition per assignment.
2. Local codebase analysis before each change.
3. Targeted implementation with minimal disruption to existing behavior.
4. Validation after each change (`flutter analyze`, `flutter test`).
5. UX refinement and bug fixing.
6. Checkpoint commits and tags for stable restore points.

This approach allowed continuous progress while keeping the app runnable and testable after each assignment.

## 3. Technical Stack

- Flutter (Dart)
- Firebase Authentication
- Cloud Firestore
- mobile_scanner (QR scanning)
- flutter_svg (SVG branding assets)
- Android + iOS targets

## 4. Architecture Strategy

The project was refactored from a baseline prototype into a feature-structured architecture.

Core folders:

- `lib/app/` app bootstrap and session control
- `lib/auth/` unauthenticated flow screens
- `lib/core/` authenticated app shell and feature screens
- `lib/services/` Firebase and parser services
- `lib/models/` typed data models
- `lib/shared/` reusable widgets/validators
- `lib/branding/` centralized branding and style tokens
- `docs/` architecture/function/branding and workflow documentation

Key design choices:

- separation of state/control (`SessionController`) from UI,
- service layer isolation for Firebase interactions,
- centralized brand tokens and asset paths,
- incremental feature evolution with checkpoints.

Additional domain constraint:

- flows are designed to remain compatible with a B2B2C operating model, where optician interaction is not removed from the user journey.

## 5. Major Implementation Milestones

### 5.1 Baseline and Refactor

- established first backup baseline,
- refactored from single-file prototype into modular structure.

### 5.2 Firebase Integration

- connected Firebase Auth and Firestore,
- implemented register/login/reset flow,
- introduced profile storage and session observer logic.

### 5.3 GDPR Flow

- registration gated by GDPR consent,
- consent withdrawal deactivates access and returns to login,
- implemented user-facing loading/feedback states.

### 5.4 QR Registration and Passport

- integrated QR scanning,
- added QR parser service for digital quality card links,
- mapped query parameters into typed passport model,
- rendered passport tabs (Lens Details / Prescription / Frame Measurements).

### 5.5 Branding System

- introduced `lib/branding` as single-source theming module,
- added asset folder strategy (`assets/branding/...`),
- SVG-first brand logo loading with PNG fallback,
- redesigned auth/core screens with guideline-driven visual updates.

### 5.6 Data Persistence and User Relation

- connected lenses to authenticated user path in Firestore (`users/{uid}/lenses/{lensId}`),
- live lens list subscription per user,
- delete lens workflow with confirmation,
- retained optician linkage in lens records to reflect B2B2C process requirements.

### 5.7 UX & Navigation Enhancements

- native back behavior improvements in app shell,
- logout confirmation in profile,
- startup/login session behavior control,
- transition polish (reduced intrusive dark overlays).

## 6. Checkpoint and Versioning Strategy

Stable points are tagged for rapid recovery and demonstration control.

Current checkpoints:

- `checkpoint/001-refactor-firebase-qr-loaders`
- `checkpoint/002-branding-auth-android-startup`
- `checkpoint/003-pre-qr-parser`

Each checkpoint was created only after static analysis and tests passed.

## 7. Quality Assurance Workflow

For nearly every assignment, validation includes:

- `flutter analyze` (static quality and API safety)
- `flutter test` (regression confidence)

Additionally:

- runtime verification on emulator/device,
- fast bug-fix loops from log traces,
- non-destructive workflow using checkpoints.

## 8. Problems Encountered and Resolutions

### 8.1 Android Firebase plugin/build issues

- Resolved through explicit Gradle/Firebase wiring and verification build.

### 8.2 Asset loading and startup branding issues

- Solved by consistent asset paths, pubspec registration, and restart-aware handling.

### 8.3 Firestore permission-denied on lens writes

- identified as security-rule issue on user lens subcollection,
- app-side crash prevention added with graceful error handling,
- rules guidance provided for `users/{uid}/lenses/*` access control.

### 8.4 Auth and navigation behavior mismatches

- adjusted startup session behavior and system back handling to match product expectations.

## 9. Practical Learning Outcomes

This practical project demonstrates:

- end-to-end mobile feature development,
- Firebase-backed data architecture,
- robust handling of asynchronous UI + backend states,
- branded UI system design,
- iterative delivery with real-world debugging and requirement changes,
- translation of business constraints (B2B2C and mandatory optician role) into technical and UX decisions.

## 10. Assignment Log (Live Section)

This section is intended to be updated continuously with each new assignment.

### Assignment 001

- Refactor architecture + Firebase integration baseline.
- Output: modular app structure, auth/profile service layer, QR and loaders.

### Assignment 002

- Branding system + Android support + startup/auth redesign.
- Output: centralized branding module, SVG/PNG logo strategy, auth UX overhaul.

### Assignment 003

- Core screen redesign and navigation/behavior refinements.
- Output: redesigned dashboard/lens/list/passport/rating views, back/logout behavior updates.

### Assignment 004

- QR payload extraction linked to digital lens passport fields.
- Output: parser + model mapping from MyHOYA URL parameters into passport tabs.

### Assignment 005

- Lens persistence by user and deletion workflow.
- Output: Firestore user-linked lens storage, live list sync, delete action with confirmation.

### Assignment 006

- Rating workflow hardening and in-flow review updates.
- Output:
  - `Rate Lens` now requires lens selection from registered lenses.
  - Empty state guard shows `No lens registered.` when no lens exists.
  - `My Lenses` now provides direct `Update Review` action per lens.
  - Firestore-backed review save/update flow aligned with redesigned rating screens.

### Assignment 007

- Documentation alignment and design workflow traceability.
- Output:
  - Updated `README.md`, `docs/ARCHITECTURE_OVERVIEW.md`, and `docs/FUNCTIONS_EXPLAINED.md`.
  - Added `docs/DESIGN_WORKFLOW.md` for screenshot-based UI evolution tracking.
  - Added screenshot storage convention under `docs/screenshots/design/`.

### Assignment 008

- Profile and notification settings visual redesign.
- Output:
  - Reworked profile overview into a branded layout with member summary, account information cards, activity metrics, and settings shortcuts.
  - Reworked notification settings into a branded layout with channel controls, grouped notification types, explanatory info card, and save action.
  - Preserved existing edit-profile, settings navigation, logout confirmation, and notification save behaviors while updating the presentation layer.

---

## Update Protocol for Future Assignments

For every new assignment, this file should be updated with:

1. new requirement summary,
2. implementation scope,
3. files/modules changed,
4. validation results,
5. outcomes and open points.

This ensures traceability for bachelor practical reporting and final presentation.
