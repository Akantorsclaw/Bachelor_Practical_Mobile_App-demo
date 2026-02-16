import 'package:flutter/material.dart';

import 'brand_assets.dart';
import 'styles/brand_palette.dart';

/// Global app brand configuration.
///
/// Rebrand by editing this file and replacing files in `assets/branding/`.
class AppBrand {
  const AppBrand({
    required this.appName,
    required this.assets,
    required this.palette,
  });

  final String appName;
  final BrandAssets assets;
  final BrandPalette palette;

  static const AppBrand current = AppBrand(
    appName: 'HOYA Vision Care',
    assets: BrandAssets(
      authLogoSvg: 'assets/branding/logos/authLogo.svg',
      authLogoPng: 'assets/branding/logos/auth_logo.png',
      logomark: 'assets/branding/logos/logomark.png',
      appIconForeground: 'assets/branding/icons/app_icon_foreground.png',
    ),
    palette: BrandPalette(
      primary: Color(0xFF0057BC),
      secondary: Color(0xFFF0F1F4),
      tertiary: Color(0xFFE7E8ED),
      scaffoldBackground: Color(0xFFF4F4F6),
      surface: Color(0xFFFFFFFF),
      surfaceMuted: Color(0xFFF0F1F4),
      surfaceStrong: Color(0xFF2D2A28),
      overlay: Color(0x88000000),
      textPrimary: Color(0xFF2D2A28),
      textSecondary: Color(0xFF6E7183),
      iconMuted: Color(0x8A6E7183),
      border: Color(0xFFDADCE2),
      onPrimary: Color(0xFFFFFFFF),
      onSurface: Color(0xFF2D2A28),
      accentSoft: Color(0xFFF0F1F4),
      segmentSelected: Color(0xFF0057BC),
      onSegmentSelected: Color(0xFFFFFFFF),
    ),
  );
}
