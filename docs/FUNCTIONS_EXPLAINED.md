# Functions Explained (Beginner Friendly)

This file explains the most important functions used in this app in simple terms.

## 1) App Startup

### `main()` in `lib/main.dart`
- This is the first function that runs when the app starts.
- It does 3 important things:
1. `WidgetsFlutterBinding.ensureInitialized()`
   - Prepares Flutter internals before async setup.
2. `Firebase.initializeApp(...)`
   - Connects your app to Firebase.
3. Creates `SessionController` and runs `LensApp`.

Think of `main()` as: "turn everything on, then show the app".

---

## 2) Navigation Between Logged-Out and Logged-In Parts

### `build()` in `LensApp` (`lib/app/app.dart`)
- Uses `AnimatedBuilder` to rebuild UI whenever `SessionController` changes.
- Chooses which screen tree to show:
  - `AuthFlow` if user is not logged in.
  - `LensCoreShell` if user is logged in.

This is the app's main gatekeeper.

---

## 3) Session and Auth Logic

All these live in `lib/app/session_controller.dart`.

### `goToAuthView(AuthView view)`
- Changes which auth sub-screen is shown (`login`, `register`, `gdprConsent`, `reset`).
- Calls `notifyListeners()` so UI updates.

### `signIn({email, password})`
- Calls Firebase Auth sign-in.
- Returns `null` on success.
- Returns a readable error message on failure.

### `beginRegistration({name, email, password})`
- Stores registration data temporarily.
- Moves user to GDPR consent screen.

### `completeRegistrationWithConsent()`
- Runs only after user accepts GDPR.
- Creates Firebase user with email/password.
- Creates/updates Firestore doc in `users/{uid}`.
- Signs out user to preserve your flow:
  - Register -> GDPR -> Login -> Home

### `sendPasswordReset(email)`
- Sends reset email using Firebase Auth.

### `signOut()`
- Logs out current user.
- Sends app back to login flow.

### `withdrawConsentAndLogout()`
- Deletes profile document from Firestore.
- Tries to delete Firebase Auth user.
- Signs out afterward.
- Used in privacy settings when user withdraws consent.

### `_onAuthStateChanged(User? user)`
- Called automatically when login state changes.
- If logged in: starts listening to user's Firestore profile in real time.
- If logged out: clears profile state.

### `_mapAuthError(FirebaseAuthException e)`
- Converts technical Firebase error codes into simple messages for users.

---

## 4) Firebase Service Functions

These are in `lib/services/`.

## `AuthService` (`lib/services/auth_service.dart`)

### `authStateChanges()`
- Stream that emits whenever user logs in/out.

### `signIn(...)`, `signUp(...)`
- Wrapper functions for Firebase email/password login/signup.

### `sendPasswordResetEmail(email)`
- Sends reset email.

### `signOut()`
- Logs current user out.

## `UserProfileService` (`lib/services/user_profile_service.dart`)

### `watchUserProfile(uid)`
- Real-time stream of `users/{uid}` doc.
- Updates UI automatically when profile data changes.

### `upsertUserProfile(...)`
- Creates or updates user profile doc.
- `upsert` means "update if exists, create if not".

### `deleteUserProfile(uid)`
- Deletes profile doc.

---

## 5) Auth Screen Callback Functions

These are in `lib/auth/auth_flow.dart` inside `_AuthFlowState`.

### `_handleLogin(...)`
- Calls controller `signIn`.
- Shows error snack bar if needed.

### `_handleBeginRegistration(...)`
- Calls controller `beginRegistration`.

### `_handleGdprAccept()`
- Calls controller `completeRegistrationWithConsent`.
- Shows success message.

### `_handleResetPassword(email)`
- Calls controller `sendPasswordReset`.
- Shows success/error message.

### `_showSnack(text)`
- Small helper to show temporary messages at bottom.

---

## 6) Core App Navigation/Feature Functions

These are in `lib/core/lens_core_shell.dart`.

### `_selectTab(index)`
- Changes selected bottom navigation tab.

### `_navigateFromOverlay(index)`
- Used when user is in a pushed detail screen.
- Goes back to root shell and selects a tab.

### `_openRegisterLens()`
- Opens lens registration screen.

### `_openPassport(lens)`
- Opens digital passport screen for a specific lens.

### `_openRateLens(lens)`
- Opens rating screen for lens.
- Saves rating result in local state.

### `_openRateOptician()`
- Opens rating screen for optician.
- Saves rating result in local state.

### `_openNotificationSettings()` and `_openPrivacyDataProtection()`
- Open profile sub-pages.

### `_handleWithdrawConsent()`
- Calls `SessionController.withdrawConsentAndLogout()`.
- Shows status message.

### `_addLens(serial, optician)`
- Adds a new lens to in-memory list used by prototype UI.

---

## 7) Model/Utility Functions

### `AppUserProfile.fromMap(...)` in `lib/models/app_user_profile.dart`
- Converts Firestore map data into a Dart object.

### `validateEmail(...)` and `validatePassword(...)` in `lib/shared/validators.dart`
- Input checks used by forms.
- Return `null` when valid, or an error string when invalid.

---

## 8) Common Pattern Used in This App

### `notifyListeners()`
- Used by `SessionController` (which extends `ChangeNotifier`).
- Means: "state changed, rebuild widgets that are listening".

### `Future<T>` and `async/await`
- Used for operations that take time (network/Firebase).
- `await` means: pause this function until result arrives.

### `Stream<T>`
- Used for real-time updates (auth state, Firestore snapshots).
- Think of stream as a continuous data feed.

---

## 9) Quick Mental Model

- `main.dart`: startup + Firebase init
- `SessionController`: app brain/state
- `services/`: talking to Firebase
- `auth_flow.dart`: logged-out screens
- `lens_core_shell.dart`: logged-in screens
- `shared/`: reusable UI + validators
- `models/`: typed data objects

