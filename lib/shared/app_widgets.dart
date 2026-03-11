import 'package:flutter/material.dart';

import '../branding/brand_context.dart';

bool _usesDarkChrome(BuildContext context) {
  return context.brandPalette.scaffoldBackground.computeLuminance() < 0.08;
}

/// Shared styled text input used across auth and core screens.
class FormInput extends StatelessWidget {
  const FormInput({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.obscure = false,
    this.validator,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscure;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: palette.secondary,
        labelStyle: TextStyle(fontSize: 13, color: palette.textSecondary),
        hintStyle: TextStyle(fontSize: 20, color: palette.textPrimary),
        suffixIcon: IconButton(
          onPressed: controller.clear,
          icon: Icon(Icons.cancel_outlined, color: palette.textSecondary),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: palette.border),
        ),
      ),
    );
  }
}

/// Primary call-to-action pill button.
class PrimaryPillButton extends StatelessWidget {
  const PrimaryPillButton({super.key, required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return FilledButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.stars_rounded, size: 16),
      label: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: palette.primary,
        foregroundColor: palette.onPrimary,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
      ),
    );
  }
}

/// Secondary action pill button.
class SecondaryPillButton extends StatelessWidget {
  const SecondaryPillButton({
    super.key,
    required this.text,
    required this.onTap,
  });

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return FilledButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.stars_rounded, size: 16),
      label: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: palette.secondary,
        foregroundColor: palette.primary,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      ),
    );
  }
}

/// Shared bottom navigation used by all core and detail views.
class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: _usesDarkChrome(context)
            ? palette.surfaceStrong
            : palette.surfaceMuted,
        indicatorColor: palette.primary.withValues(
          alpha: _usesDarkChrome(context) ? 0.16 : 0.12,
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? palette.primary : palette.textSecondary,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? palette.primary : palette.textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        backgroundColor: _usesDarkChrome(context)
            ? palette.surfaceStrong
            : palette.surfaceMuted,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.remove_red_eye_outlined),
            selectedIcon: Icon(Icons.remove_red_eye),
            label: 'Lenses',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// Reusable 5-star rating selector.
class RatingStarsRow extends StatelessWidget {
  const RatingStarsRow({
    super.key,
    required this.rating,
    required this.onSelected,
    this.selectedFill = const Color(0xFFD7CCEF),
  });

  final int rating;
  final ValueChanged<int> onSelected;
  final Color selectedFill;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final number = index + 1;
        final selected = number <= rating;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => onSelected(number),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected ? selectedFill : palette.surface,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: palette.border),
              ),
              child: Icon(
                Icons.stars_rounded,
                size: 20,
                color: selected ? palette.primary : palette.textSecondary,
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Common app bar with an optional title and left back button.
class TopBackAppBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBackAppBar({super.key, this.title});

  final String? title;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    final darkChrome = _usesDarkChrome(context);
    return AppBar(
      backgroundColor: darkChrome ? palette.surfaceStrong : palette.surface,
      foregroundColor: darkChrome ? palette.onSurface : palette.textPrimary,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back),
      ),
      title: title == null ? null : Text(title!),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
