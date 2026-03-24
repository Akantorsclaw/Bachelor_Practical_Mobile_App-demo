# API and Function Reference

**Project:** Bachelor_Practical_Mobile_App
**Scope:** All public and significant private functions across the application

---

## 1. Application Entry

### `main()` — `lib/main.dart`

Performs startup sequencing:

1. `WidgetsFlutterBinding.ensureInitialized()` — prepares the Flutter engine binding before any async operations.
2. `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` — establishes the Firebase connection.
3. Instantiates `SessionController` and calls `runApp(LensApp(...))`.

---

## 2. App Gate

### `LensApp.build(BuildContext context)` — `lib/app/app.dart`

Wraps the widget tree in an `AnimatedBuilder` bound to `SessionController`. Renders `AuthFlow` when the controller reports no active session, or `LensCoreShell` when a session is active.

---

## 3. Session Controller — `lib/app/session_controller.dart`

`SessionController` extends `ChangeNotifier`. All state mutations call `notifyListeners()` on completion.

### `goToAuthView(AuthView view)`
Sets the active auth sub-screen. Valid values: `login`, `register`, `gdprConsent`, `reset`.

### `signIn({required String email, required String password}) → Future<String?>`
Calls `AuthService.signIn`. Returns `null` on success; returns a localised error string on failure.

### `beginRegistration({required String name, required String email, required String password})`
Stores pending registration credentials in memory and navigates to the GDPR consent screen. Does not create a Firebase account.

### `completeRegistrationWithConsent() → Future<String?>`
Executes the deferred registration:
1. Calls `AuthService.signUp` with stored credentials.
2. Writes the user profile to Firestore via `UserProfileService.upsertUserProfile`.
3. Signs the user out to enforce the Register → GDPR → Login → Home flow.

### `sendPasswordReset(String email) → Future<String?>`
Calls `AuthService.sendPasswordResetEmail`. Returns `null` on success or an error string.

### `signOut() → Future<void>`
Signs the current user out of Firebase Auth. Clears session state.

### `withdrawConsentAndLogout() → Future<String?>`
1. Deletes the Firestore profile document.
2. Attempts to delete the Firebase Auth account.
3. Signs the user out regardless of step 2 outcome.
Returns `null` on success or an error message.

### `updateProfile({required String name, required String email}) → Future<String?>`
Updates the display name in Firebase Auth and the profile document in Firestore. Returns `null` on success.

### `updatePrivacyPreferences({required bool consentActive, required bool shareWithOptician, required bool shareWithCompany}) → Future<String?>`
Persists the three privacy preference fields to the Firestore `users/{uid}` document. Returns `null` on success.

### `_onAuthStateChanged(User? user)` *(private)*
Firebase Auth state listener. On sign-in, starts the `UserProfileService.watchUserProfile` stream. On sign-out, clears all session state.

### `_mapAuthError(FirebaseAuthException e) → String` *(private)*
Converts Firebase error codes into user-facing messages.

---

## 4. Service Layer — `lib/services/`

### `AuthService`

| Method | Signature | Description |
|---|---|---|
| `authStateChanges` | `Stream<User?>` | Emits on every auth state change. |
| `signIn` | `(String email, String password) → Future<UserCredential>` | Firebase email/password sign-in. |
| `signUp` | `(String email, String password) → Future<UserCredential>` | Creates a Firebase Auth account. |
| `sendPasswordResetEmail` | `(String email) → Future<void>` | Sends a password reset email. |
| `signOut` | `() → Future<void>` | Signs the current user out. |
| `deleteCurrentUser` | `() → Future<void>` | Deletes the Firebase Auth account for the current user. |

### `UserProfileService`

| Method | Signature | Description |
|---|---|---|
| `watchUserProfile` | `(String uid) → Stream<AppUserProfile?>` | Real-time stream of the `users/{uid}` document. |
| `upsertUserProfile` | `(String uid, AppUserProfile profile) → Future<void>` | Creates or merges the user profile document. |
| `deleteUserProfile` | `(String uid) → Future<void>` | Deletes the `users/{uid}` document. |

### `LensService`

| Method | Signature | Description |
|---|---|---|
| `watchLenses` | `(String uid) → Stream<List<AppLens>>` | Real-time stream of `users/{uid}/lenses`. |
| `createLens` | `(String uid, AppLens lens) → Future<void>` | Writes a new lens document. |
| `deleteLens` | `(String uid, String lensId) → Future<void>` | Removes a lens document. |

### `ReviewService`

| Method | Signature | Description |
|---|---|---|
| `watchReviews` | `(String uid) → Stream<List<AppReview>>` | Real-time stream of `users/{uid}/reviews`. |
| `upsertReview` | `(String uid, AppReview review) → Future<void>` | Creates or updates a review document. |
| `deleteReview` | `(String uid, String reviewId) → Future<void>` | Removes a review document. |

### `LensPassQrParser`

| Method | Signature | Description |
|---|---|---|
| `parse` | `(String rawValue) → LensPassportData?` | Parses a MyHOYA QR URL. Returns `null` if the URL does not match the expected schema. |

### `LensParameterInfoService`

| Method | Signature | Description |
|---|---|---|
| `explanationForCode` | `(String code) → String` | Returns a descriptive explanation for a lens parameter code (e.g. `LC`, `SR`, `PDR`). |

---

## 5. Authentication Flow — `lib/auth/auth_flow.dart`

Private methods on `_AuthFlowState`:

| Method | Description |
|---|---|
| `_handleLogin(String email, String password)` | Calls `SessionController.signIn`. Displays a snackbar on error. |
| `_handleBeginRegistration(String name, String email, String password)` | Calls `SessionController.beginRegistration`. |
| `_handleGdprAccept()` | Calls `SessionController.completeRegistrationWithConsent`. Displays a success message. |
| `_handleResetPassword(String email)` | Calls `SessionController.sendPasswordReset`. Displays success or error feedback. |

---

## 6. Authenticated Shell — `lib/core/lens_core_shell.dart`

Private methods on `_LensCoreShellState`:

### Subscriptions

| Method | Description |
|---|---|
| `_subscribeLenses()` | Cancels any existing subscription and opens a new `LensService.watchLenses` stream for the current user. Maps `AppLens` documents to `LensItem` UI models. |
| `_subscribeReviews()` | Cancels any existing subscription and opens a new `ReviewService.watchReviews` stream. |

### Navigation

| Method | Description |
|---|---|
| `_selectTab(int index)` | Sets the active bottom navigation tab. |
| `_navigateFromOverlay(int index)` | Pops all routes to root, then sets the active tab. Used by detail screens to return to a specific tab. |
| `_openRegisterLens()` | Pushes `RegisterLensScreen`. |
| `_openPassport(LensItem lens)` | Pushes `LensPassportScreen` for the given lens. |
| `_openRateLensForLens(LensItem lens)` | Pushes `RateLensScreen` if no review exists for the lens; pushes `EditRatingScreen` if one does. |
| `_openRateOptician()` | Pushes `RateLensScreen` or `EditRatingScreen` for the primary optician review (`id: 'optician_primary'`). |
| `_openRateMenu()` | Presents a bottom sheet to choose between rating a lens or an optician. |
| `_openNotificationSettings()` | Pushes `NotificationSettingsScreen`. |
| `_openPrivacyDataProtection()` | Pushes `PrivacyDataProtectionScreen` with current privacy preference values from the session profile. |
| `_pickLensForRating() → Future<LensItem?>` | Presents a bottom sheet lens selector. Returns `null` and shows a snackbar if no lenses are registered. |

### Data Operations

| Method | Description |
|---|---|
| `_addLens(LensItem lens)` | Calls `LensService.createLens`. On success, navigates to the Lenses tab. Handles `permission-denied` with a user-facing message. |
| `_deleteLens(LensItem lens)` | Calls `LensService.deleteLens`. Handles `permission-denied` with a user-facing message. |
| `_updateProfile({name, email})` | Delegates to `SessionController.updateProfile`. |
| `_handleWithdrawConsent() → Future<String?>` | Calls `SessionController.withdrawConsentAndLogout`. On success, pops all routes to expose the auth flow. |

### Utility

| Method | Description |
|---|---|
| `_toLensItem(AppLens lens) → LensItem` | Converts a Firestore `AppLens` to the UI `LensItem` model. |
| `_ratingForLens(LensItem? lens) → int?` | Returns the overall rating for a lens from the in-memory review list, or `null` if no review exists. |
| `_reviewForLens(LensItem lens) → AppReview?` | Returns the `AppReview` matching `lens_${lens.id}`, or `null`. |
| `_firstReviewWhere(bool Function(AppReview) test) → AppReview?` | Linear search helper over the review list. |
| `_formatLastRated(DateTime?) → String` | Returns a day-offset string (e.g. `3d`) or `--` if null. |
| `_daysUntilCheckup(LensItem?) → int` | Calculates days remaining until the 180-day post-purchase follow-up. Returns `14` if no lens or unparseable date. |
| `_formatMemberSince(DateTime?) → String` | Returns a `MMM YYYY` formatted string. |
| `_averageRating() → double` | Returns the mean `overallRating` across all reviews, or `0` if empty. |

---

## 7. Screen-Level Functions

### `RegisterLensScreen` — `lib/core/screens/register_lens_screen.dart`

| Method | Description |
|---|---|
| `_scanQrCode()` | Pushes `QrScannerScreen`. On return, calls `LensPassQrParser.parse` on the raw value and pre-fills the name field with the lens design if available. |

### `LensPassportScreen` — `lib/core/screens/lens_passport_screen.dart`

Renders `_PassportLensDetails`, `_PassportPrescription`, or `_PassportFrameMeasurements` based on the selected tab enum value. Each row and dual-value row calls `LensParameterInfoService.explanationForCode` to populate the info bottom sheet.

### `RateLensScreen` — `lib/core/screens/rate_lens_screen.dart`

| Method | Description |
|---|---|
| `_submit()` | Assembles a `RatingData` object from current state and calls `onSubmit`. On success, calls `onTabSelected(0)`. Handles `FirebaseException` with a localised message. |

### `EditRatingScreen` — `lib/core/screens/rate_lens_screen.dart`

| Method | Description |
|---|---|
| `_update()` | Assembles a `RatingData` object and calls `onUpdate`. On success, calls `onTabSelected(0)`. |
| `_delete()` | Calls `onDelete`, pops the screen, and shows a confirmation snackbar. |

### `ProfileOverviewScreen` — `lib/core/screens/profile_overview_screen.dart`

| Method | Description |
|---|---|
| `_editProfile(BuildContext context)` | Presents `_EditProfileDialog`. On confirmation, calls `onUpdateProfile` and displays the result in a snackbar. |

### `PrivacyDataProtectionScreen` — `lib/core/screens/privacy_data_protection_screen.dart`

| Method | Description |
|---|---|
| `_savePreferences()` | Calls `onSavePreferences` with the current consent toggle state. Displays success or error in a snackbar. |
| `_handleWithdrawConsent()` | Presents a confirmation dialog, then a non-dismissible loading overlay, then calls `onWithdrawConsent`. Dismisses the overlay and handles errors. |

---

## 8. Models — `lib/models/`

### `AppUserProfile`
Firestore document model for `users/{uid}`. Fields include `name`, `email`, `consentActive`, `shareWithOptician`, `shareWithCompany`, `gdprConsentAt`, `createdAt`.

- `AppUserProfile.fromMap(Map<String, dynamic> map)` — deserialises a Firestore document snapshot.
- `AppUserProfile.toMap() → Map<String, dynamic>` — serialises for Firestore writes.

### `AppLens`
Firestore document model for `users/{uid}/lenses/{lensId}`.

- `AppLens.fromMap(String id, Map<String, dynamic> map)` — deserialises a Firestore document.
- `AppLens.toMap() → Map<String, dynamic>` — serialises for Firestore writes.

### `AppReview`
Firestore document model for `users/{uid}/reviews/{reviewId}`. Includes `targetType` (`ReviewTargetType.lens` or `ReviewTargetType.optician`), `overallRating`, `aspectRatings`, `comment`, `updatedAt`.

### `LensPassportData`
In-memory model populated by `LensPassQrParser`. Holds `right` and `left` eye prescription objects, frame measurements, and lens design fields.

### `LensItem`
Lightweight UI model for a lens. Distinct from `AppLens`. Fields: `id`, `name`, `purchaseDate`, `optician`, `passportData`.

### `RatingData`
In-memory payload transferred between rating screens and the shell. Fields: `stars`, `comment`, `ratedAt`, `aspectRatings`.

---

## 9. Shared Utilities — `lib/shared/`

### `validateEmail(String? value) → String?`
Returns `null` if the value is a valid email address. Returns an error string otherwise. Used as a `FormField` validator.

### `validatePassword(String? value) → String?`
Returns `null` if the value meets minimum password requirements. Returns an error string otherwise.

---

## 10. Branding Utilities — `lib/branding/`

### `context.brandPalette → BrandPalette`
Extension on `BuildContext`. Returns the active brand's colour token set. Available in any widget's `build` method.

### `AppBrand.setFlavor(BrandFlavor flavor)`
Switches the active brand at runtime. Triggers a rebuild of the root app via `flavorNotifier`.

### `BrandAssets.logoPath(BrandFlavor flavor) → String`
Returns the asset path for the given brand's auth logo. Falls back to the default brand path if the brand-specific asset is absent.
