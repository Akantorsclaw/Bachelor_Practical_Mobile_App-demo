# Architecture Overview

**Project:** Bachelor_Practical_Mobile_App
**Platform:** Flutter (Android / iOS)
**Backend:** Firebase Authentication, Cloud Firestore

---

## 1. Application Layers

The application is structured in five layers. Each layer has a single defined responsibility and communicates only with the layer directly below it.

| Layer | Responsibility |
|---|---|
| Presentation | Screen widgets and navigation |
| Shell | Authenticated state management and navigation control |
| Session | Auth lifecycle, user profile stream, consent management |
| Service | Firebase access (Auth, Firestore) |
| Model | Typed data structures |

---

## 2. Entry Point

**`lib/main.dart`**

Initializes the Flutter engine binding, connects to Firebase, instantiates `SessionController`, and mounts `LensApp`.

---

## 3. App Gate

**`lib/app/app.dart`**

`LensApp` listens to `SessionController` via `AnimatedBuilder`. It renders:

- `AuthFlow` — when no authenticated session exists
- `LensCoreShell` — when a valid session is active

---

## 4. Session Controller

**`lib/app/session_controller.dart`**

`SessionController` extends `ChangeNotifier` and serves as the single source of truth for:

- Authentication state and current auth flow step (`login`, `register`, `gdprConsent`, `reset`)
- User profile data (real-time Firestore stream)
- GDPR consent status and privacy preferences
- All auth operations (sign-in, registration, password reset, consent withdrawal, profile update)

---

## 5. Service Layer

**`lib/services/`**

| File | Responsibility |
|---|---|
| `auth_service.dart` | Firebase Auth wrappers (sign-in, sign-up, sign-out, password reset) |
| `user_profile_service.dart` | Firestore `users/{uid}` document CRUD and real-time stream |
| `lens_service.dart` | Firestore `users/{uid}/lenses` CRUD and real-time stream |
| `review_service.dart` | Firestore `users/{uid}/reviews` CRUD and real-time stream |
| `lens_pass_qr_parser.dart` | Parses MyHOYA QR URL query parameters into `LensPassportData` |
| `lens_parameter_info_service.dart` | Returns explanatory text for lens parameter codes |

---

## 6. Authenticated Shell

**`lib/core/lens_core_shell.dart`**

`LensCoreShell` manages the authenticated session UI:

- Holds real-time subscriptions to the user's lens and review collections
- Owns all navigation callbacks passed to child screens
- Renders the three-tab bottom navigation (Home, Lenses, Profile)
- Delegates all screen content to the files in `lib/core/screens/`

The shell contains no screen-level UI code. It is solely responsible for data ownership and navigation orchestration.

---

## 7. Screen Files

**`lib/core/screens/`**

Each file contains exactly one primary screen and its private helper widgets.

| File | Screen | Contents |
|---|---|---|
| `dashboard_screen.dart` | Home tab | Stats summary, latest lens card, quick action grid, check-up reminder |
| `register_lens_screen.dart` | Lens registration | Name input, QR scan, optician picker, register action; also `QrScannerScreen` |
| `lenses_list_screen.dart` | My Lenses tab | Per-lens cards with delete confirmation and review shortcut |
| `lens_passport_screen.dart` | Digital Lens Passport | Three-tab passport: Lens Details, Prescription, Frame Measurements; all `_Passport*` helpers |
| `rate_lens_screen.dart` | Rating | `RateLensScreen` (new review), `EditRatingScreen` (edit/delete); all rating helper widgets |
| `profile_overview_screen.dart` | Profile tab | Member card, account info, activity stats, settings shortcuts, logout; `_EditProfileDialog` |
| `notification_settings_screen.dart` | Notification Settings | Channel toggles (push, email), notification-type toggles, save action |
| `privacy_data_protection_screen.dart` | Privacy & Data Protection | GDPR status, consent toggle, sharing preferences, rights cards, consent withdrawal |

---

## 8. Authentication Screens

**`lib/auth/auth_flow.dart`**

Handles the unauthenticated flow: login, registration, GDPR consent gate, and password reset. All state transitions delegate to `SessionController`.

---

## 9. Models

**`lib/models/`**

| File | Purpose |
|---|---|
| `app_user_profile.dart` | Firestore user profile document model |
| `app_lens.dart` | Firestore lens document model |
| `app_review.dart` | Firestore review document model |
| `lens_passport_data.dart` | QR-parsed lens passport fields |
| `lens_item.dart` | Lightweight UI lens model used by core screens |
| `rating_data.dart` | In-memory rating payload transferred between rating screens and shell |

`LensItem` and `AppLens` are intentionally separate. `AppLens` is the Firestore-bound model; `LensItem` is the UI representation used by screens.

---

## 10. Shared Components

**`lib/shared/`**

| File | Contents |
|---|---|
| `app_widgets.dart` | `TopBackAppBar`, `AppBottomNavigation`, and other reusable layout widgets |
| `validators.dart` | `validateEmail`, `validatePassword` — form field validators |

---

## 11. Branding System

**`lib/branding/`**

The branding system supports runtime-switchable brand themes. The active brand is read globally via `context.brandPalette`.

| File | Responsibility |
|---|---|
| `brand.dart` | Brand enum (`BrandFlavor`), registry, and `AppBrand.setFlavor(...)` entry point |
| `brand_context.dart` | `BuildContext` extension: `context.brandPalette` |
| `brand_assets.dart` | Asset path resolution per brand (logos, icons) |
| `brand_theme_extension.dart` | Flutter `ThemeExtension` integration |
| `styles/brand_palette.dart` | Colour token definitions for each brand |

Currently registered brands: `BrandFlavor.hoya`, `BrandFlavor.seiko`.

---

## 12. Data Flow

```
UI widget
  └─ calls SessionController method
       └─ SessionController calls Service
            └─ Service calls Firebase
                 └─ Firebase emits update
                      └─ SessionController calls notifyListeners()
                           └─ UI rebuilds
```

For lens and review data, `LensCoreShell` holds direct `StreamSubscription` instances. The shell maps Firestore documents to UI models (`AppLens` → `LensItem`) and passes the resulting lists down to screens as constructor parameters.

---

## 13. Firestore Data Paths

| Collection | Path |
|---|---|
| User profile | `users/{uid}` |
| User lenses | `users/{uid}/lenses/{lensId}` |
| User reviews | `users/{uid}/reviews/{reviewId}` |

---

## 14. Key Entry Points for Navigation

| Starting point | File |
|---|---|
| App entry | `lib/main.dart` |
| Auth / session gate | `lib/app/session_controller.dart` |
| Authenticated shell | `lib/core/lens_core_shell.dart` |
| Unauthenticated flow | `lib/auth/auth_flow.dart` |
