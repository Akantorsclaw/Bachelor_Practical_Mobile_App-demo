# MyLens_App_bachelor_practical

Multi-brand Flutter mobile app for digital lens workflows, built as a bachelor practical project.

## Overview

The app provides:
- Firebase email/password authentication
- GDPR consent onboarding flow
- Profile management (with confirmation on update)
- QR-based lens registration
- User-linked lens storage in Firestore
- Digital Lens Passport views (details, prescription, frame measurements)
- Lens and optician rating flows (Firestore-backed)
- Brandable UI system via centralized theme/assets
- Runtime brand switching between `HOYA` and `SEIKO`
- Privacy preferences and sharing consents persisted in Firestore

## Current App IDs

- Dart package name: `mylens_app_bachelor_practical`
- Android applicationId: `com.example.mylens_app_bachelor_practical`
- iOS bundle ID: `com.dominikbien.mylensapp.bachelorpractical`
- macOS bundle ID: `com.dominikbien.mylensapp.bachelorpractical`

## Tech Stack

- Flutter / Dart
- Firebase Core
- Firebase Authentication
- Cloud Firestore
- `mobile_scanner` (QR)
- `flutter_svg` (SVG brand assets)

## Project Structure

- `lib/main.dart`: startup + Firebase init + app bootstrap
- `lib/app/`: app shell and session controller
- `lib/auth/`: login/register/GDPR/reset views
- `lib/core/`: authenticated shell + feature screens
- `lib/services/`: Firebase gateways + QR/parser services
- `lib/models/`: typed domain models
- `lib/shared/`: reusable widgets + validators
- `lib/branding/`: brand palette + brand assets config
- `assets/branding/`: logos/icons
- `docs/`: architecture/branding/function/workflow docs

## Firebase Setup

Required files:
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

Important:
- Firebase app identifiers must match this project’s IDs exactly.
- `lib/firebase_options.dart` must stay in sync with your iOS plist values.

### iOS (Xcode)

1. Open workspace:
   - `open ios/Runner.xcworkspace`
2. Select `Runner` target -> `Signing & Capabilities`
3. Enable automatic signing and select your Team
4. Confirm Bundle Identifier:
   - `com.dominikbien.mylensapp.bachelorpractical`
5. Ensure `GoogleService-Info.plist` is in Runner target resources

## Branding / Rebranding

Main configuration:
- `lib/branding/brand.dart`

Assets:
- `assets/branding/logos/authLogo.svg` (preferred)
- `assets/branding/logos/auth_logo.png` (fallback)
- `assets/branding/logos/logomark.png`
- `assets/branding/icons/app_icon_foreground.png`
- `assets/branding/seiko/logos/authLogo.svg`
- `assets/branding/seiko/logos/auth_logo.png`
- `assets/branding/seiko/logos/logomark.png`
- `assets/branding/seiko/icons/app_icon_foreground.png`

## Run

```bash
flutter pub get
flutter run
```

Useful targets:
- Android emulator/device: `flutter run -d android`
- iOS simulator: `flutter run -d ios`

## Quality Checks

```bash
flutter analyze
flutter test
```

## Key Behaviors Implemented

- Register -> GDPR consent -> Login -> Home
- Consent withdrawal flow with logout and loading state
- Email change via Firebase verification flow
- `Rate Lens` requires selecting a registered lens first
- If no lens exists, `Rate Lens` shows `No lens registered.`
- `My Lenses` supports `Update Review` per lens
- Privacy screen stores:
  - `consentActive`
  - `shareWithOptician`
  - `shareWithCompany`
- Rating and passport info sheets follow the active brand palette
- Rating controls were enlarged for better accessibility
- On app-side profile update:
  - name updates immediately
  - email updates after verification sync
- Native back behavior integrated in authenticated shell
- Logout confirmation dialogs

## Checkpoints / Restore

Stable restore points are documented in:
- `CHECKPOINTS.md`

Examples:
- `checkpoint/001-refactor-firebase-qr-loaders`
- `checkpoint/002-branding-passport-profile-ux`

Restore examples:
```bash
git reset --hard checkpoint/001-refactor-firebase-qr-loaders
git reset --hard <commit_sha>
```

## Documentation

- `docs/ARCHITECTURE_OVERVIEW.md`
- `docs/FUNCTIONS_EXPLAINED.md`
- `docs/BRANDING.md`
- `docs/BACHELOR_PRACTICAL_WORKFLOW.md`
- `docs/DESIGN_WORKFLOW.md`
