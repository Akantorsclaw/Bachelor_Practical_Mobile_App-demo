import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_review.dart';

class ReviewService {
  ReviewService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _reviews(String uid) {
    return _firestore.collection('users').doc(uid).collection('reviews');
  }

  Stream<List<AppReview>> watchReviews(String uid) {
    return _reviews(uid).orderBy('updatedAt', descending: true).snapshots().map(
      (snapshot) {
        return snapshot.docs.map(AppReview.fromDoc).toList();
      },
    );
  }

  Future<void> upsertReview(String uid, AppReview review) async {
    final doc = _reviews(uid).doc(review.id);
    await doc.set(<String, dynamic>{
      'id': review.id,
      'createdAt': FieldValue.serverTimestamp(),
      ...review.toMap(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteReview(String uid, String reviewId) async {
    await _reviews(uid).doc(reviewId).delete();
  }
}
