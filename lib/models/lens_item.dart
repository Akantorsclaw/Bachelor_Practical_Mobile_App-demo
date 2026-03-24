import '../models/lens_passport_data.dart';

/// Simple in-memory lens model used by prototype flows.
class LensItem {
  const LensItem({
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
}
