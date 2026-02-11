import 'package:cloud_firestore/cloud_firestore.dart';

/// Strongly-typed representation of `users/{uid}` in Firestore.
class AppUserProfile {
  const AppUserProfile({
    required this.uid,
    required this.email,
    required this.name,
    this.createdAt,
    this.updatedAt,
    this.gdprConsentAt,
  });

  final String uid;
  final String email;
  final String name;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? gdprConsentAt;

  /// Builds a profile model from Firestore map data.
  factory AppUserProfile.fromMap(Map<String, dynamic> map) {
    return AppUserProfile(
      uid: (map['uid'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      createdAt: _asDateTime(map['createdAt']),
      updatedAt: _asDateTime(map['updatedAt']),
      gdprConsentAt: _asDateTime(map['gdprConsentAt']),
    );
  }

  /// Converts Firestore timestamps into `DateTime`.
  static DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
