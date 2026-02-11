# Read This First

This app is split into a few simple layers so it stays easy to understand.

## 1) Startup
- `lib/main.dart`
- Initializes Firebase.
- Creates one `SessionController`.
- Starts `LensApp`.

## 2) App Gate
- `lib/app/app.dart`
- Decides what to show:
  - `AuthFlow` when logged out
  - `LensCoreShell` when logged in

## 3) App Brain (State)
- `lib/app/session_controller.dart`
- Single source of truth for:
  - auth flow step (login/register/gdpr/reset)
  - login/logout
  - sign up with GDPR consent
  - password reset
  - user profile stream from Firestore

## 4) Firebase Access
- `lib/services/auth_service.dart`
- `lib/services/user_profile_service.dart`
- These files talk to Firebase APIs so UI code stays clean.

## 5) Screens
- `lib/auth/auth_flow.dart` = logged-out screens
- `lib/core/lens_core_shell.dart` = logged-in screens + tabs

## 6) Shared Pieces
- `lib/shared/app_widgets.dart` = reusable buttons/inputs/nav widgets
- `lib/shared/validators.dart` = form validators
- `lib/models/app_user_profile.dart` = typed user profile model

## Data Flow (Simple)
1. UI calls `SessionController` method.
2. `SessionController` calls service (`AuthService` / `UserProfileService`).
3. Service talks to Firebase.
4. `SessionController` updates state and calls `notifyListeners()`.
5. UI rebuilds automatically.

## If You Only Read 3 Files First
1. `lib/main.dart`
2. `lib/app/session_controller.dart`
3. `lib/core/lens_core_shell.dart`

Then read `lib/auth/auth_flow.dart`.
