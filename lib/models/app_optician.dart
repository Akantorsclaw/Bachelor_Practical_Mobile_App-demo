import 'package:cloud_firestore/cloud_firestore.dart';

class AppOptician {
  final String id;
  final String externalId;
  final String name;
  final String address;
  final String zipCode;
  final String city;
  final String? state;
  final String? phone;
  final String? email;
  final String? website;
  final GeoPoint? location;
  final List<String> openingHours;
  final bool isPremium;
  final List<String> campaigns;

  const AppOptician({
    required this.id,
    required this.externalId,
    required this.name,
    required this.address,
    required this.zipCode,
    required this.city,
    this.state,
    this.phone,
    this.email,
    this.website,
    this.location,
    required this.openingHours,
    required this.isPremium,
    required this.campaigns,
  });

  factory AppOptician.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    return AppOptician(
      id: doc.id,
      externalId: d['externalId'] as String? ?? '',
      name: d['name'] as String? ?? '',
      address: d['address'] as String? ?? '',
      zipCode: d['zipCode'] as String? ?? '',
      city: d['city'] as String? ?? '',
      state: d['state'] as String?,
      phone: d['phone'] as String?,
      email: d['email'] as String?,
      website: d['website'] as String?,
      location: d['location'] as GeoPoint?,
      openingHours: List<String>.from(d['openingHours'] as List? ?? []),
      isPremium: d['isPremium'] as bool? ?? false,
      campaigns: List<String>.from(d['campaigns'] as List? ?? []),
    );
  }
}
