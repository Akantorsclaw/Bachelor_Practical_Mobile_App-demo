import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_news_item.dart';

/// Firestore gateway for the `news/` collection.
class NewsService {
  NewsService(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _news =>
      _firestore.collection('news');

  /// Streams the latest [limit] news items, newest first.
  Stream<List<AppNewsItem>> watchNews({int limit = 30}) {
    return _news
        .orderBy('publishedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (doc) => AppNewsItem.fromDoc(
                  doc as DocumentSnapshot<Map<String, dynamic>>,
                ),
              )
              .toList(),
        );
  }
}
