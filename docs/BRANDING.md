# Branding Guide

Use these two locations to rebrand the app:

1. `lib/branding/brand.dart`
- `appName`
- brand registry (`BrandFlavor.hoya`, `BrandFlavor.seiko`)
- active brand switch via `AppBrand.setFlavor(...)`
- color palette (`primary`, `secondary`, `tertiary`, etc.)
- brand asset paths per brand

2. `assets/branding/`
- `logos/authLogo.svg` (preferred)
- `logos/auth_logo.png` (fallback)
- `logos/logomark.png`
- `icons/app_icon_foreground.png`

## Available brands

- `BrandFlavor.hoya`
  - Existing HOYA brand palette and current shared assets
- `BrandFlavor.seiko`
  - Added SEIKO palette using:
    - golden-brown `#D28C00`
    - black `#000000`
    - charcoal `#333333`
    - accent green `#118163`
    - accent magenta `#9B166F`
  - Uses dark chrome:
    - scaffold background `#000000`
    - card/surface hierarchy with darker charcoal surfaces
    - navigation and primary interactions in the gold accent
    - destructive actions in the magenta accent with white text

## How to switch brands

- Runtime:
  - call `AppBrand.setFlavor(BrandFlavor.seiko);`
  - switch back with `AppBrand.setFlavor(BrandFlavor.hoya);`
- Default startup brand:
  - change `AppBrand.defaultFlavor` in `lib/branding/brand.dart`

## SEIKO asset paths

Put SEIKO-specific assets here if you want logos/icons to change too:

- `assets/branding/seiko/logos/authLogo.svg`
- `assets/branding/seiko/logos/auth_logo.png`
- `assets/branding/seiko/logos/logomark.png`
- `assets/branding/seiko/icons/app_icon_foreground.png`

If those files are missing, the auth/startup views fall back to text instead of crashing.

## Notes

- The app theme reads from `AppBrand.current`.
- The root app rebuilds when `AppBrand.flavorNotifier` changes.
- Shared widgets and loading overlays use `context.brandPalette`.
- Shared app chrome is brand-aware:
  - bottom navigation uses the active brand primary color for selected items
  - app bars and passport/rating info sheets adapt to dark brands such as SEIKO
- Keep file names stable or update paths in `lib/branding/brand.dart`.
- Keep design screenshots in `docs/screenshots/design/` and update `docs/DESIGN_WORKFLOW.md` when a screen changes.
