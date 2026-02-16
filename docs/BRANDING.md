# Branding Guide

Use these two locations to rebrand the app:

1. `lib/branding/brand.dart`
- `appName`
- color palette (`primary`, `secondary`, `tertiary`, etc.)
- brand asset paths

2. `assets/branding/`
- `logos/authLogo.svg` (preferred)
- `logos/auth_logo.png` (fallback)
- `logos/logomark.png`
- `icons/app_icon_foreground.png`

## Notes

- The app theme reads from `AppBrand.current`.
- Shared widgets and loading overlays use `context.brandPalette`.
- Keep file names stable or update paths in `lib/branding/brand.dart`.
