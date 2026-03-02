import 'package:cloud_firestore/cloud_firestore.dart';

enum ReviewTargetType { lens, optician }

class AppReview {
  const AppReview({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.targetName,
    required this.targetSubtitle,
    required this.overallRating,
    required this.aspectRatings,
    required this.comment,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final ReviewTargetType targetType;
  final String targetId;
  final String targetName;
  final String targetSubtitle;
  final int overallRating;
  final Map<String, int> aspectRatings;
  final String comment;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AppReview.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final rawAspects = (data['aspectRatings'] as Map<String, dynamic>?) ?? {};
    return AppReview(
      id: doc.id,
      targetType: (data['targetType'] ?? 'optician') == 'lens'
          ? ReviewTargetType.lens
          : ReviewTargetType.optician,
      targetId: (data['targetId'] ?? '') as String,
      targetName: (data['targetName'] ?? '') as String,
      targetSubtitle: (data['targetSubtitle'] ?? '') as String,
      overallRating: ((data['overallRating'] ?? 0) as num).toInt(),
      aspectRatings: rawAspects.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      ),
      comment: (data['comment'] ?? '') as String,
      createdAt: _asDateTime(data['createdAt']),
      updatedAt: _asDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'targetType': targetType == ReviewTargetType.lens ? 'lens' : 'optician',
      'targetId': targetId,
      'targetName': targetName,
      'targetSubtitle': targetSubtitle,
      'overallRating': overallRating,
      'aspectRatings': aspectRatings,
      'comment': comment,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }
}
