import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_lens.dart';

/// Firestore gateway for user-linked registered lenses.
class LensService {
  LensService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _lenses(String uid) {
    return _firestore.collection('users').doc(uid).collection('lenses');
  }

  Stream<List<AppLens>> watchLenses(String uid) {
    return _lenses(uid).orderBy('updatedAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map(AppLens.fromDoc).toList();
    });
  }

  Future<void> createLens(String uid, AppLens lens) async {
    final doc = _lenses(uid).doc();
    await doc.set(<String, dynamic>{
      'id': doc.id,
      'createdAt': FieldValue.serverTimestamp(),
      ...lens.toMap(),
    });
  }

  Future<void> deleteLens(String uid, String lensId) async {
    await _lenses(uid).doc(lensId).delete();
  }
}
