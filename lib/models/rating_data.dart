/// In-memory rating payload used between rating screens.
class RatingData {
  const RatingData({
    required this.stars,
    required this.comment,
    required this.ratedAt,
    required this.aspectRatings,
  });

  final int stars;
  final String comment;
  final DateTime ratedAt;
  final Map<String, int> aspectRatings;
}
