import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../models/app_optician.dart';

class OpticianService {
  OpticianService(this._firestore);

  final FirebaseFirestore _firestore;

  /// One-time fetch of all opticians. The collection is seeded externally
  /// and treated as read-only, so a stream is not needed.
  Future<List<AppOptician>> fetchAll() async {
    final snap = await _firestore.collection('opticians').get();
    return snap.docs.map((d) => AppOptician.fromDoc(d)).toList();
  }

  /// Client-side text filter — matches name, city or postcode (case-insensitive).
  static List<AppOptician> filterByQuery(List<AppOptician> all, String query) {
    if (query.isEmpty) return all;
    final q = query.toLowerCase();
    return all
        .where((o) =>
            o.name.toLowerCase().contains(q) ||
            o.city.toLowerCase().contains(q) ||
            o.zipCode.contains(q))
        .toList();
  }

  /// Returns a copy of [all] sorted by ascending distance from [userLat]/[userLng].
  /// Opticians without a GeoPoint are placed at the end.
  static List<AppOptician> sortByProximity(
    List<AppOptician> all,
    double userLat,
    double userLng,
  ) {
    final sorted = List<AppOptician>.from(all);
    sorted.sort((a, b) {
      final da = distanceKm(a, userLat, userLng);
      final db = distanceKm(b, userLat, userLng);
      return da.compareTo(db);
    });
    return sorted;
  }

  /// Distance in km from an optician to a given coordinate.
  /// Returns [double.infinity] if the optician has no location.
  static double distanceKm(AppOptician o, double lat, double lng) {
    final loc = o.location;
    if (loc == null) return double.infinity;
    final meters = Geolocator.distanceBetween(
      lat,
      lng,
      loc.latitude,
      loc.longitude,
    );
    return meters / 1000;
  }
}
