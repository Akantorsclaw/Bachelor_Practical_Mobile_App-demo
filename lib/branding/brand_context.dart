import 'package:flutter/material.dart';

import 'brand_theme_extension.dart';
import 'styles/brand_palette.dart';

extension BrandContext on BuildContext {
  BrandPalette get brandPalette =>
      Theme.of(this).extension<BrandThemeExtension>()!.palette;
}
