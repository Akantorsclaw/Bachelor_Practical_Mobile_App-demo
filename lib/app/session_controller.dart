import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user_profile.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';

/// Auth sub-views shown before the user enters the authenticated shell.
enum AuthView { login, register, gdprConsent, reset }

/// App-wide state controller for authentication and user profile data.
///
/// Responsibilities:
/// - Maintain auth onboarding flow state.
/// - Execute Firebase auth operations.
/// - Create/watch Firestore user profile documents.
/// - Expose loading and user-facing state to UI.
class SessionController extends ChangeNotifier {
  SessionController({
    required AuthService authService,
    required UserProfileService userProfileService,
  }) : _authService = authService,
       _userProfileService = userProfileService {
    _authSubscription = _authService.authStateChanges().listen(
      _onAuthStateChanged,
    );
  }

  final AuthService _authService;
  final UserProfileService _userProfileService;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<AppUserProfile?>? _profileSubscription;

  AuthView _authView = AuthView.login;
  bool _busy = false;

  User? _firebaseUser;
  AppUserProfile? _profile;

  String? _pendingName;
  String? _pendingEmail;
  String? _pendingPassword;

  /// Current pre-login auth screen to display.
  AuthView get authView => _authView;

  /// Whether an async auth/profile operation is running.
  bool get busy => _busy;

  /// Whether the user is authenticated.
  bool get isLoggedIn => _firebaseUser != null;

  /// Firestore-backed user profile data for the current user.
  AppUserProfile? get profile => _profile;

  /// Best-effort display name for the UI.
  String get userName {
    final profileName = _profile?.name;
    if (profileName != null && profileName.trim().isNotEmpty) {
      return profileName;
    }
    return _firebaseUser?.email?.split('@').first ?? 'User';
  }

  /// Best-effort email for the UI.
  String get userEmail => _profile?.email ?? _firebaseUser?.email ?? '';

  /// Currently authenticated Firebase uid, if available.
  String? get userId => _firebaseUser?.uid;

  /// Switches the currently displayed auth sub-view.
  void goToAuthView(AuthView view) {
    _authView = view;
    notifyListeners();
  }

  /// Signs in an existing user with email/password.
  ///
  /// Returns `null` on success, otherwise a user-facing error string.
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    _setBusy(true);
    try {
      await _authService.signIn(email: normalizedEmail, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    } catch (_) {
      return 'Login failed. Please try again.';
    } finally {
      _setBusy(false);
    }
  }

  /// Stores registration inputs and advances to GDPR consent step.
  Future<String?> beginRegistration({
    required String name,
    required String email,
    required String password,
  }) async {
    _pendingName = name.trim();
    _pendingEmail = email.trim();
    _pendingPassword = password;
    _authView = AuthView.gdprConsent;
    notifyListeners();
    return null;
  }

  /// Completes sign-up only after GDPR consent is accepted.
  ///
  /// Creates Firebase auth user, upserts Firestore profile, then signs out to
  /// preserve the `Register -> GDPR -> Login -> Home` flow.
  Future<String?> completeRegistrationWithConsent() async {
    final pendingName = _pendingName;
    final pendingEmail = _pendingEmail;
    final pendingPassword = _pendingPassword;

    if (pendingName == null ||
        pendingEmail == null ||
        pendingPassword == null) {
      _authView = AuthView.register;
      notifyListeners();
      return 'Registration data missing. Please register again.';
    }

    _setBusy(true);
    try {
      final credential = await _authService.signUp(
        email: pendingEmail,
        password: pendingPassword,
      );
      final uid = credential.user?.uid;
      if (uid == null) {
        return 'Unable to create user. Try again.';
      }

      await _userProfileService.upsertUserProfile(
        uid: uid,
        email: pendingEmail,
        name: pendingName,
        includeGdprConsentAt: true,
      );

      _pendingName = null;
      _pendingEmail = null;
      _pendingPassword = null;

      // Keep workflow as Register -> GDPR -> Login -> Home
      await _authService.signOut();
      _authView = AuthView.login;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    } catch (_) {
      return 'Registration failed. Please try again.';
    } finally {
      _setBusy(false);
    }
  }

  /// Sends a password reset email.
  Future<String?> sendPasswordReset(String email) async {
    _setBusy(true);
    try {
      await _authService.sendPasswordResetEmail(email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e);
    } catch (_) {
      return 'Could not send reset email. Try again.';
    } finally {
      _setBusy(false);
    }
  }

  /// Updates profile name/email and persists to Firestore.
  ///
  /// If email changes, Firebase Auth email is updated first.
  Future<String?> updateProfile({
    required String name,
    required String email,
  }) async {
    final user = _firebaseUser;
    if (user == null) return 'No authenticated user.';

    final nextName = name.trim();
    final nextEmail = email.trim().toLowerCase();
    if (nextName.isEmpty) return 'Name cannot be empty.';
    if (nextEmail.isEmpty) return 'Email cannot be empty.';

    _setBusy(true);
    try {
      final currentEmail = user.email?.trim().toLowerCase() ?? '';
      if (nextEmail != currentEmail) {
        await _authService.updateEmail(nextEmail);
      }
      await _userProfileService.updateUserProfile(
        uid: user.uid,
        email: nextEmail,
        name: nextName,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return 'For security, please log in again before changing your email.';
      }
      return _mapAuthError(e);
    } catch (_) {
      return 'Profile update failed. Please try again.';
    } finally {
      _setBusy(false);
    }
  }

  /// Signs out and returns the app to auth flow.
  Future<void> signOut() async {
    _setBusy(true);
    try {
      await _authService.signOut();
      _authView = AuthView.login;
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  /// Signs out without triggering loading UI.
  ///
  /// Used for lifecycle-driven logout when the app is being closed.
  Future<void> signOutSilently() async {
    if (_firebaseUser == null) return;
    try {
      await _authService.signOut();
      _authView = AuthView.login;
      notifyListeners();
    } catch (_) {
      // Best effort for lifecycle shutdown.
    }
  }

  /// Processes GDPR withdrawal and logs the user out.
  ///
  /// Attempts to delete the profile document and auth user record.
  Future<String?> withdrawConsentAndLogout() async {
    final user = _firebaseUser;
    if (user == null) return 'No authenticated user.';

    _setBusy(true);
    try {
      // Keep user data for business reporting while disabling app access.
      await _userProfileService.markConsentWithdrawn(user.uid);
      await user.delete();
      await _authService.signOut();
      _authView = AuthView.login;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ??
          'Could not fully deactivate account. Please login again and retry immediately.';
    } catch (_) {
      return 'Could not process withdrawal. Please try again.';
    } finally {
      _setBusy(false);
    }
  }

  /// Handles Firebase auth-state updates and profile stream subscription.
  void _onAuthStateChanged(User? user) {
    _firebaseUser = user;
    _profileSubscription?.cancel();
    _profileSubscription = null;

    if (user == null) {
      _busy = false;
      _profile = null;
      notifyListeners();
      return;
    }

    _profileSubscription = _userProfileService
        .watchUserProfile(user.uid)
        .listen((data) {
          _profile = data;
          notifyListeners();
        });
    notifyListeners();
  }

  /// Updates loading state.
  void _setBusy(bool value) {
    _busy = value;
    notifyListeners();
  }

  /// Maps Firebase auth error codes to user-friendly messages.
  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'Invalid email format.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'Email is already in use.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }
}
