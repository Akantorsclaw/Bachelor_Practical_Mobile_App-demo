import 'package:flutter/material.dart';

/// Single source of truth for app colors.
///
/// Update this file to rebrand the app palette.
class BrandPalette {
  const BrandPalette({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.positiveAccent,
    required this.negativeAccent,
    required this.scaffoldBackground,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceStrong,
    required this.overlay,
    required this.textPrimary,
    required this.textSecondary,
    required this.iconMuted,
    required this.border,
    required this.onPrimary,
    required this.onSurface,
    required this.accentSoft,
    required this.segmentSelected,
    required this.onSegmentSelected,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color positiveAccent;
  final Color negativeAccent;
  final Color scaffoldBackground;
  final Color surface;
  final Color surfaceMuted;
  final Color surfaceStrong;
  final Color overlay;
  final Color textPrimary;
  final Color textSecondary;
  final Color iconMuted;
  final Color border;
  final Color onPrimary;
  final Color onSurface;
  final Color accentSoft;
  final Color segmentSelected;
  final Color onSegmentSelected;
}
