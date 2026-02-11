# Checkpoints

This file tracks stable restore points for this project.

## How to restore

- Restore to a checkpoint tag:
  - `git reset --hard <tag>`
- Restore to a specific commit:
  - `git reset --hard <commit_sha>`

## Checkpoint List

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

