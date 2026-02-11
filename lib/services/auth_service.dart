import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around [FirebaseAuth] to keep UI and controller decoupled.
class AuthService {
  AuthService(this._auth);

  final FirebaseAuth _auth;

  /// Emits the current auth state and all subsequent auth state changes.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Currently signed-in Firebase user, if any.
  User? get currentUser => _auth.currentUser;

  /// Signs a user in with email/password credentials.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Creates a user with email/password credentials.
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sends a password reset email to [email].
  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  /// Signs out the currently authenticated user.
  Future<void> signOut() => _auth.signOut();
}
