# Checkpoints

This file tracks stable restore points for this project.

## How to restore

- Restore to a checkpoint tag:
  - `git reset --hard <tag>`
- Restore to a specific commit:
  - `git reset --hard <commit_sha>`

## Checkpoint List

### 005 - Multi-Brand + Privacy + Accessibility
- Tag: `checkpoint/005-multibrand-privacy-accessibility`
- Contains:
  - Runtime-switchable brand registry with `HOYA` and `SEIKO`
  - SEIKO dark-theme palette, gold navigation highlights, and magenta destructive accent
  - Brand-aware app chrome for app bars, bottom navigation, and info bottom sheets
  - Privacy & Data Protection redesign with Firestore-backed consent and sharing preferences
  - Larger, more accessible rating controls with refined single-row star layouts
  - Updated branding, workflow, design, and README documentation

### 004 - Branding v0.2
- Tag: `checkpoint/004-branding-v0.2`
- Contains:
  - Dashboard redesign with dynamic user greeting and overview stats
  - Dynamic current-lens, quick-action, and upcoming check-up cards
  - Updated profile/notification/privacy branding refinements
  - Removal of legacy dashboard header label
  - iOS bundle/Firebase alignment updates and README/MoSCoW docs updates

### 002 - Branding + Passport + Profile Edit + UX Fixes
- Tag: `checkpoint/002-branding-passport-profile-ux`
- Contains:
  - Branding system rollout (assets + palette-driven screens)
  - Auth screen redesign and asset-based logo usage
  - Digital Lens Passport data parsing from QR URL parameters
  - Lens persistence in Firestore under `users/{uid}/lenses`
  - Lens delete support from list view
  - Profile edit flow with confirmation before update
  - Logout confirmation and lifecycle logout behavior
  - Profile overflow fix (screen now scrolls on smaller viewports)
  - Multiple UI updates across home/lens/rating/passport flows

### 001 - Refactor + Firebase + QR + Loaders
- Tag: `checkpoint/001-refactor-firebase-qr-loaders`
- Commit: `49261c7`
- Contains:
  - Refactor from single-file prototype into feature-based structure (`lib/app`, `lib/auth`, `lib/core`, `lib/services`, `lib/models`, `lib/shared`)
  - Firebase Auth + Firestore integration
  - User profile persistence in `users/{uid}`
  - GDPR onboarding step and consent withdrawal flow
  - Profile/notification/privacy screens
  - QR scanner integration in lens registration
  - Transition loading overlays for auth/core flows
  - Documentation files (`docs/ARCHITECTURE_OVERVIEW.md`, `docs/FUNCTIONS_EXPLAINED.md`)

### Baseline Backup (pre-refactor)
- Commit: `bb51aa5`
- Contains:
  - Original backup snapshot before full refactor/Firebase integration

## Naming Convention for future checkpoints

- Format:
  - `checkpoint/<number>-<short-name>`
- Examples:
  - `checkpoint/002-rating-polish`
  - `checkpoint/003-optician-admin`

## Stable Checkpoint Checklist (before creating a new one)

1. `flutter analyze` passes
2. `flutter test` passes
3. Main flow manually smoke-tested
4. Commit message describes scope clearly
5. Tag message summarizes feature set
