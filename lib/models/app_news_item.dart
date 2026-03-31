import 'package:cloud_firestore/cloud_firestore.dart';

/// A news or announcement item from the `news/` Firestore collection.
class AppNewsItem {
  const AppNewsItem({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.publishedAt,
    this.imageUrl,
  });

  final String id;
  final String title;
  final String body;

  /// e.g. 'product', 'service', 'offer', 'recall'
  final String category;
  final DateTime publishedAt;
  final String? imageUrl;

  factory AppNewsItem.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return AppNewsItem(
      id: doc.id,
      title: (data['title'] ?? '') as String,
      body: (data['body'] ?? '') as String,
      category: (data['category'] ?? 'general') as String,
      publishedAt: _asDateTime(data['publishedAt']) ?? DateTime.now(),
      imageUrl: data['imageUrl'] as String?,
    );
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
