import 'package:flutter/material.dart';

import 'brand_assets.dart';
import 'styles/brand_palette.dart';

enum BrandFlavor { hoya, seiko }

/// Global app brand registry and active brand switch.
class AppBrand {
  const AppBrand({
    required this.appName,
    required this.assets,
    required this.palette,
  });

  final String appName;
  final BrandAssets assets;
  final BrandPalette palette;

  static const BrandFlavor defaultFlavor = BrandFlavor.hoya;

  static final ValueNotifier<BrandFlavor> flavorNotifier = ValueNotifier(
    defaultFlavor,
  );

  static BrandFlavor get currentFlavor => flavorNotifier.value;

  static AppBrand get current => byFlavor(currentFlavor);

  static void setFlavor(BrandFlavor flavor) {
    if (flavorNotifier.value == flavor) return;
    flavorNotifier.value = flavor;
  }

  static AppBrand byFlavor(BrandFlavor flavor) {
    return switch (flavor) {
      BrandFlavor.hoya => _hoya,
      BrandFlavor.seiko => _seiko,
    };
  }

  static const AppBrand _hoya = AppBrand(
    appName: 'HOYA Vision Care',
    assets: BrandAssets(
      authLogoSvg: 'assets/branding/logos/wordmark.svg',
      authLogoPng: 'assets/branding/logos/wordmark.png',
      logomark: 'assets/branding/logos/logomark.png',
      appIconForeground: 'assets/branding/icons/app_icon_foreground.png',
    ),
    palette: BrandPalette(
      primary: Color(0xFF0057BC),
      secondary: Color(0xFFF0F1F4),
      tertiary: Color(0xFFE7E8ED),
      positiveAccent: Color(0xFF0057BC),
      negativeAccent: Color(0xFF2D2A28),
      scaffoldBackground: Color.fromRGBO(244, 244, 246, 1),
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

  static const AppBrand _seiko = AppBrand(
    appName: 'SEIKO Vision',
    assets: BrandAssets(
      authLogoSvg: 'assets/branding/seiko/logos/authLogo.svg',
      authLogoPng: 'assets/branding/seiko/logos/auth_logo.png',
      logomark: 'assets/branding/seiko/logos/logomark.png',
      appIconForeground: 'assets/branding/seiko/icons/app_icon_foreground.png',
    ),
    palette: BrandPalette(
      primary: Color(0xFFD28C00),
      secondary: Color(0xFF333333),
      tertiary: Color(0xFF3D3D3D),
      positiveAccent: Color(0xFF118163),
      negativeAccent: Color(0xFF9B166F),
      scaffoldBackground: Color(0xFF000000),
      surface: Color(0xFF333333),
      surfaceMuted: Color(0xFF2B2B2B),
      surfaceStrong: Color(0xFF000000),
      overlay: Color(0xAA000000),
      textPrimary: Color(0xFFFFFFFF),
      textSecondary: Color(0xFFAAAAAA),
      iconMuted: Color(0xB3AAAAAA),
      border: Color(0xFF4A4A4A),
      onPrimary: Color(0xFF000000),
      onSurface: Color(0xFFFFFFFF),
      accentSoft: Color(0x33118163),
      segmentSelected: Color(0xFFD28C00),
      onSegmentSelected: Color(0xFF000000),
    ),
  );
}
