import 'package:cloud_firestore/cloud_firestore.dart';

import 'lens_passport_data.dart';

/// Firestore representation of a user-owned registered lens.
class AppLens {
  const AppLens({
    required this.id,
    required this.name,
    required this.purchaseDate,
    required this.optician,
    this.passportData,
  });

  final String id;
  final String name;
  final String purchaseDate;
  final String optician;
  final LensPassportData? passportData;

  factory AppLens.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return AppLens(
      id: doc.id,
      name: (data['name'] ?? '') as String,
      purchaseDate: (data['purchaseDate'] ?? '') as String,
      optician: (data['optician'] ?? '') as String,
      passportData: LensPassportData.fromMap(
        (data['passportData'] as Map<String, dynamic>?),
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'purchaseDate': purchaseDate,
      'optician': optician,
      'passportData': passportData?.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
