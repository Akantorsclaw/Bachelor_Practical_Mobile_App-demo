import 'package:flutter/material.dart';

import '../../branding/brand_context.dart';
import '../../models/lens_item.dart';

/// Dashboard screen under the Home tab.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.userName,
    required this.lensesCount,
    required this.ratingsCount,
    required this.lastRatedLabel,
    required this.currentLens,
    required this.currentLensRating,
    required this.daysUntilCheckup,
    required this.onGoRegister,
    required this.onGoLenses,
    required this.onRate,
    required this.onOpenPassport,
  });

  final String userName;
  final int lensesCount;
  final int ratingsCount;
  final String lastRatedLabel;
  final LensItem? currentLens;
  final int? currentLensRating;
  final int daysUntilCheckup;
  final Future<void> Function() onGoRegister;
  final VoidCallback onGoLenses;
  final Future<void> Function() onRate;
  final Future<void> Function() onOpenPassport;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    final firstName = userName
        .trim()
        .split(' ')
        .firstWhere((part) => part.isNotEmpty, orElse: () => 'User');
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      children: [
        Text(
          'Welcome back, $firstName',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Here's your vision care overview",
          style: TextStyle(fontSize: 17, color: palette.textSecondary),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _statCard(context, value: '$lensesCount', label: 'Lenses'),
            const SizedBox(width: 10),
            _statCard(context, value: '$ratingsCount', label: 'Ratings'),
            const SizedBox(width: 10),
            _statCard(context, value: lastRatedLabel, label: 'Last rated'),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          'Latest Lens',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        _currentLensCard(context),
        const SizedBox(height: 20),
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _quickActionCard(
                context,
                icon: Icons.add,
                title: 'Register New Lens',
                emphasized: true,
                onTap: () => onGoRegister(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _quickActionCard(
                context,
                icon: Icons.shopping_bag_outlined,
                title: 'My Lenses',
                onTap: onGoLenses,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _quickActionCard(
                context,
                icon: Icons.star_border_rounded,
                title: 'Rate Experience',
                onTap: () => onRate(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _quickActionCard(
                context,
                icon: Icons.workspace_premium_outlined,
                title: 'Lens Passport',
                onTap: () => onOpenPassport(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: palette.surfaceMuted,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: palette.surface,
                child: Icon(
                  Icons.calendar_month_outlined,
                  color: palette.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upcoming Check-up',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your next optician visit is in $daysUntilCheckup days',
                      style: TextStyle(
                        fontSize: 15,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCard(
    BuildContext context, {
    required String value,
    required String label,
  }) {
    final palette = context.brandPalette;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        decoration: BoxDecoration(
          color: palette.secondary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: palette.primary,
                fontSize: 30,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: palette.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _currentLensCard(BuildContext context) {
    final palette = context.brandPalette;
    final lens = currentLens;
    if (lens == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          'No lens registered yet.',
          style: TextStyle(fontSize: 15, color: palette.textSecondary),
        ),
      );
    }

    return InkWell(
      onTap: () => onOpenPassport(),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.border),
              ),
              child: Icon(
                Icons.accessibility_new_rounded,
                color: palette.iconMuted,
                size: 36,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lens.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Progressive Lenses',
                    style: TextStyle(
                      color: palette.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.star, color: palette.primary, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        currentLensRating == null
                            ? 'No rating'
                            : currentLensRating!.toStringAsFixed(1),
                        style: TextStyle(
                          color: palette.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.remove_red_eye_outlined,
              color: palette.primary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool emphasized = false,
  }) {
    final palette = context.brandPalette;
    final background = emphasized ? palette.primary : palette.secondary;
    final foreground = emphasized ? palette.onPrimary : palette.primary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 132,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: foreground.withValues(
                alpha: emphasized ? 0.22 : 0.1,
              ),
              child: Icon(icon, color: foreground, size: 24),
            ),
            Text(
              title,
              style: TextStyle(
                color: foreground,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
