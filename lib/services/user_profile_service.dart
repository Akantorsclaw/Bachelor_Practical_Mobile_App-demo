import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user_profile.dart';

/// Firestore gateway for the `users/{uid}` profile document.
class UserProfileService {
  UserProfileService(this._firestore);

  final FirebaseFirestore _firestore;

  /// Users collection reference.
  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  /// Watches a user profile in real time.
  Stream<AppUserProfile?> watchUserProfile(String uid) {
    return _users.doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return null;
      return AppUserProfile.fromMap(data);
    });
  }

  /// Creates or updates a user profile document.
  ///
  /// `gdprConsentAt` is written on initial sign-up consent.
  Future<void> upsertUserProfile({
    required String uid,
    required String email,
    required String name,
    required bool includeGdprConsentAt,
  }) {
    final now = FieldValue.serverTimestamp();
    return _users.doc(uid).set({
      'uid': uid,
      'email': email,
      'name': name,
      'consentActive': true,
      'consentWithdrawnAt': null,
      'updatedAt': now,
      if (includeGdprConsentAt) 'gdprConsentAt': now,
      'createdAt': now,
    }, SetOptions(merge: true));
  }

  /// Deletes a user profile document.
  Future<void> deleteUserProfile(String uid) {
    return _users.doc(uid).delete();
  }

  /// Marks an existing user profile as consent-withdrawn while keeping data.
  Future<void> markConsentWithdrawn(String uid) {
    final now = FieldValue.serverTimestamp();
    return _users.doc(uid).set({
      'consentActive': false,
      'consentWithdrawnAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }
}
