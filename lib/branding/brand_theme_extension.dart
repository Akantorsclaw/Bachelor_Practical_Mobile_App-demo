import 'package:flutter/material.dart';

import 'styles/brand_palette.dart';

/// ThemeExtension exposing additional brand tokens.
@immutable
class BrandThemeExtension extends ThemeExtension<BrandThemeExtension> {
  const BrandThemeExtension({required this.palette});

  final BrandPalette palette;

  @override
  BrandThemeExtension copyWith({BrandPalette? palette}) {
    return BrandThemeExtension(palette: palette ?? this.palette);
  }

  @override
  BrandThemeExtension lerp(
    ThemeExtension<BrandThemeExtension>? other,
    double t,
  ) {
    if (other is! BrandThemeExtension) return this;
    return BrandThemeExtension(
      palette: BrandPalette(
        primary: Color.lerp(palette.primary, other.palette.primary, t)!,
        secondary: Color.lerp(palette.secondary, other.palette.secondary, t)!,
        tertiary: Color.lerp(palette.tertiary, other.palette.tertiary, t)!,
        scaffoldBackground: Color.lerp(
          palette.scaffoldBackground,
          other.palette.scaffoldBackground,
          t,
        )!,
        surface: Color.lerp(palette.surface, other.palette.surface, t)!,
        surfaceMuted: Color.lerp(
          palette.surfaceMuted,
          other.palette.surfaceMuted,
          t,
        )!,
        surfaceStrong: Color.lerp(
          palette.surfaceStrong,
          other.palette.surfaceStrong,
          t,
        )!,
        overlay: Color.lerp(palette.overlay, other.palette.overlay, t)!,
        textPrimary: Color.lerp(
          palette.textPrimary,
          other.palette.textPrimary,
          t,
        )!,
        textSecondary: Color.lerp(
          palette.textSecondary,
          other.palette.textSecondary,
          t,
        )!,
        iconMuted: Color.lerp(palette.iconMuted, other.palette.iconMuted, t)!,
        border: Color.lerp(palette.border, other.palette.border, t)!,
        onPrimary: Color.lerp(palette.onPrimary, other.palette.onPrimary, t)!,
        onSurface: Color.lerp(palette.onSurface, other.palette.onSurface, t)!,
        accentSoft: Color.lerp(
          palette.accentSoft,
          other.palette.accentSoft,
          t,
        )!,
        segmentSelected: Color.lerp(
          palette.segmentSelected,
          other.palette.segmentSelected,
          t,
        )!,
        onSegmentSelected: Color.lerp(
          palette.onSegmentSelected,
          other.palette.onSegmentSelected,
          t,
        )!,
      ),
    );
  }
}
