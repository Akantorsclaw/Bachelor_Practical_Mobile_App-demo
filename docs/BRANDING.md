# Branding System Reference

**Project:** Bachelor_Practical_Mobile_App
**Module:** `lib/branding/`

---

## 1. Overview

The branding system provides runtime-switchable brand theming. All colour tokens, asset paths, and chrome behaviour are encapsulated within the branding module. UI code accesses the active brand exclusively through `context.brandPalette` and `BrandAssets`.

---

## 2. Registered Brands

| Identifier | Description |
|---|---|
| `BrandFlavor.hoya` | HOYA brand palette; light chrome; default startup brand |
| `BrandFlavor.seiko` | SEIKO brand palette; dark chrome |

---

## 3. HOYA Palette

The HOYA palette uses a light background with a teal-blue primary accent. Chrome surfaces (app bars, navigation) are light with primary-coloured active states.

---

## 4. SEIKO Palette

The SEIKO palette uses a full dark-chrome configuration.

| Token | Value |
|---|---|
| Scaffold background | `#000000` |
| Primary accent | `#D28C00` (golden-brown) |
| Card / surface | Charcoal hierarchy (`#333333` and variants) |
| Accent green | `#118163` |
| Accent magenta | `#9B166F` |
| Destructive actions | Magenta accent with white foreground |

Navigation and primary interactions use the gold accent. App bars and info sheets adapt to the dark surface automatically.

---

## 5. Switching Brands

### Runtime switch

```dart
AppBrand.setFlavor(BrandFlavor.seiko);
AppBrand.setFlavor(BrandFlavor.hoya);
```

`setFlavor` updates `AppBrand.flavorNotifier`, which triggers a full rebuild of the root application widget.

### Default startup brand

Set `AppBrand.defaultFlavor` in `lib/branding/brand.dart` before the app initialises.

---

## 6. Accessing Brand Tokens in Widgets

```dart
final palette = context.brandPalette;
// Use palette.primary, palette.textPrimary, palette.surface, etc.
```

`context.brandPalette` is a `BuildContext` extension defined in `lib/branding/brand_context.dart`. It is available in any widget's `build` method without additional setup.

---

## 7. Asset Structure

### Default brand assets

```
assets/branding/
  logos/
    authLogo.svg          ← preferred (SVG)
    auth_logo.png         ← fallback (PNG)
    logomark.png
  icons/
    app_icon_foreground.png
```

### SEIKO-specific assets

```
assets/branding/seiko/
  logos/
    authLogo.svg
    auth_logo.png
    logomark.png
  icons/
    app_icon_foreground.png
```

If brand-specific asset files are absent, the auth and startup views fall back to a text representation rather than throwing a runtime error.

---

## 8. Brand-Aware Components

The following components read from `context.brandPalette` and adapt automatically when the active brand changes:

| Component | Adaptive behaviour |
|---|---|
| `AppBottomNavigation` | Selected-item colour uses `palette.primary` |
| App bars (all screens) | Background and foreground colours adapt to light/dark palette |
| Passport info sheets | Overlay and surface colours follow the active brand |
| Rating info sheets | Overlay and surface colours follow the active brand |
| Startup / auth logo | Loaded from brand-specific asset path; falls back to text |

---

## 9. File Responsibilities

| File | Responsibility |
|---|---|
| `lib/branding/brand.dart` | `BrandFlavor` enum, `AppBrand` registry, `setFlavor`, palette definitions |
| `lib/branding/brand_context.dart` | `BuildContext.brandPalette` extension |
| `lib/branding/brand_assets.dart` | Asset path resolution per `BrandFlavor` |
| `lib/branding/brand_theme_extension.dart` | Flutter `ThemeExtension` bridge for Material theme integration |
| `lib/branding/styles/brand_palette.dart` | `BrandPalette` class with named colour tokens |

---

## 10. Adding a New Brand

1. Add a new value to `BrandFlavor` in `lib/branding/brand.dart`.
2. Define a `BrandPalette` instance for the new flavor in `brand_palette.dart`.
3. Register the palette in the brand registry inside `brand.dart`.
4. Create an asset folder at `assets/branding/{flavor_name}/` with the required logo and icon files.
5. Register the asset paths in `lib/branding/brand_assets.dart`.
6. Register the asset folder in `pubspec.yaml` under `flutter.assets`.

---

## 11. Maintenance Notes

- Do not hard-code colour values in screen files. Use `context.brandPalette` tokens exclusively.
- Keep asset file names stable. If a path changes, update the corresponding entry in `lib/branding/brand_assets.dart`.
- When a screen-level redesign alters a colour role or introduces a new style rule, record the change in `docs/DESIGN_WORKFLOW.md` and update this document if a new palette token is required.
