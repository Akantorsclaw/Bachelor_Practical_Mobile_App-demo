import 'package:flutter/material.dart';

import '../../branding/brand_context.dart';
import '../../models/app_news_item.dart';
import '../../models/lens_item.dart';
import '../../models/app_review.dart';

// ---------------------------------------------------------------------------
// Alert model (locally computed — no Firestore write needed)
// ---------------------------------------------------------------------------

enum AlertType { serviceReminder, ratingReminder }

class AppAlert {
  const AppAlert({
    required this.type,
    required this.lensId,
    required this.lensName,
    this.daysOld,
  });

  final AlertType type;
  final String lensId;
  final String lensName;
  final int? daysOld; // only set for serviceReminder

  /// Unique identifier used to persist dismissals.
  String get key => '${type.name}_$lensId';

  String get title {
    switch (type) {
      case AlertType.serviceReminder:
        return 'Checkup Recommended';
      case AlertType.ratingReminder:
        return 'Rate Your Lenses';
    }
  }

  String get body {
    switch (type) {
      case AlertType.serviceReminder:
        return '$lensName — $daysOld days in use.';
      case AlertType.ratingReminder:
        return 'Share your experience with $lensName.';
    }
  }

  Color get accentColor {
    switch (type) {
      case AlertType.serviceReminder:
        return const Color(0xFF1A56DB);
      case AlertType.ratingReminder:
        return const Color(0xFFB45309);
    }
  }

  Color get backgroundColor {
    switch (type) {
      case AlertType.serviceReminder:
        return const Color(0xFFEEF4FF);
      case AlertType.ratingReminder:
        return const Color(0xFFFFFBEB);
    }
  }

  IconData get icon {
    switch (type) {
      case AlertType.serviceReminder:
        return Icons.calendar_month_outlined;
      case AlertType.ratingReminder:
        return Icons.star_border_rounded;
    }
  }
}

// ---------------------------------------------------------------------------
// Helper: compute alerts from lenses + reviews
// ---------------------------------------------------------------------------

List<AppAlert> computeAlerts({
  required List<LensItem> lenses,
  required List<AppReview> reviews,
  Set<String> dismissedKeys = const {},
  int serviceThresholdDays = 150,
}) {
  final alerts = <AppAlert>[];
  final now = DateTime.now();

  for (final lens in lenses) {
    final purchaseDate = DateTime.tryParse(lens.purchaseDate);
    if (purchaseDate != null) {
      final age = now.difference(purchaseDate).inDays;
      if (age >= serviceThresholdDays) {
        final alert = AppAlert(
          type: AlertType.serviceReminder,
          lensId: lens.id,
          lensName: lens.name,
          daysOld: age,
        );
        if (!dismissedKeys.contains(alert.key)) alerts.add(alert);
      }
    }

    final ratingAlert = AppAlert(
      type: AlertType.ratingReminder,
      lensId: lens.id,
      lensName: lens.name,
    );
    final hasReview = reviews.any((r) => r.id == 'lens_${lens.id}');
    if (!hasReview && !dismissedKeys.contains(ratingAlert.key)) {
      alerts.add(ratingAlert);
    }
  }

  return alerts;
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class UpdatesScreen extends StatelessWidget {
  const UpdatesScreen({
    super.key,
    required this.alerts,
    required this.newsItems,
    required this.onTabSelected,
    required this.onRateLens,
    required this.onDismissAlert,
  });

  final List<AppAlert> alerts;
  final List<AppNewsItem> newsItems;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onRateLens;
  final void Function(String key) onDismissAlert;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    final hasAlerts = alerts.isNotEmpty;
    final hasNews = newsItems.isNotEmpty;

    if (!hasAlerts && !hasNews) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.notifications_none_outlined,
                size: 56,
                color: palette.iconMuted,
              ),
              const SizedBox(height: 16),
              Text(
                'All caught up!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'No alerts or news right now.',
                style: TextStyle(fontSize: 15, color: palette.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
        children: [
          Text(
            'Updates',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
          ),
          if (hasAlerts) ...[
            const SizedBox(height: 2),
            Text(
              '${alerts.length} active alert${alerts.length == 1 ? '' : 's'}',
              style: TextStyle(fontSize: 15, color: palette.textSecondary),
            ),
          ],
          const SizedBox(height: 20),
          if (hasAlerts) ...[
            _sectionHeader(context, 'Alerts'),
            const SizedBox(height: 10),
            ...alerts.map((a) => _AlertCard(
              alert: a,
              onRateLens: onRateLens,
              onDismiss: onDismissAlert,
            )),
            const SizedBox(height: 24),
          ],
          if (hasNews) ...[
            _sectionHeader(context, 'Latest News'),
            const SizedBox(height: 10),
            ...newsItems.map((n) => _NewsCard(item: n)),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    final palette = context.brandPalette;
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: palette.textSecondary,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Alert card
// ---------------------------------------------------------------------------

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.onRateLens,
    required this.onDismiss,
  });

  final AppAlert alert;
  final VoidCallback onRateLens;
  final void Function(String key) onDismiss;

  @override
  Widget build(BuildContext context) {
    final accent = alert.accentColor;
    final bg = alert.backgroundColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: Key(alert.key),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDismiss(alert.key),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.delete_outline, color: accent, size: 26),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent, width: 1.5),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: alert.type == AlertType.ratingReminder ? onRateLens : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    alert.body,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: GestureDetector(
                      onTap: () => onDismiss(alert.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E7EB),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Dismiss',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF374151),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// News card
// ---------------------------------------------------------------------------

class _NewsCard extends StatefulWidget {
  const _NewsCard({required this.item});

  final AppNewsItem item;

  @override
  State<_NewsCard> createState() => _NewsCardState();
}

class _NewsCardState extends State<_NewsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    final item = widget.item;
    final dateStr = _formatDate(item.publishedAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _CategoryChip(category: item.category),
                    const Spacer(),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: palette.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                if (_expanded) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.body,
                    style: TextStyle(
                      fontSize: 14,
                      color: palette.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// ---------------------------------------------------------------------------
// Category chip
// ---------------------------------------------------------------------------

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    final label = category[0].toUpperCase() + category.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: palette.primary,
        ),
      ),
    );
  }
}
