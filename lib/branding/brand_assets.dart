/// Asset paths used for branding.
///
/// Put brand files under `assets/branding/` and update these constants.
class BrandAssets {
  const BrandAssets({
    required this.authLogoSvg,
    required this.authLogoPng,
    required this.logomark,
    required this.appIconForeground,
  });

  final String authLogoSvg;
  final String authLogoPng;
  final String logomark;
  final String appIconForeground;
}
