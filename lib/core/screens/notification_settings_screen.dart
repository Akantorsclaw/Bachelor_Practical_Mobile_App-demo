import 'package:flutter/material.dart';

import '../../branding/brand_context.dart';
import '../../shared/app_widgets.dart';

/// Notification settings detail screen.
class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key, required this.onTabSelected});

  final ValueChanged<int> onTabSelected;

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

/// State for notification toggles.
class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _ratingReminders = true;
  bool _serviceNotifications = true;
  bool _newLensAlerts = true;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
        children: [
          Container(
            height: 224,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [palette.primary, palette.primary.withValues(alpha: 0.9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 54, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.chevron_left_rounded,
                          color: palette.onPrimary,
                          size: 38,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Notification Settings',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: palette.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Text(
                      'Manage how you receive updates',
                      style: TextStyle(
                        fontSize: 16,
                        color: palette.onPrimary.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'NOTIFICATION CHANNELS',
              style: TextStyle(
                fontSize: 18,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
                color: palette.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _NotificationChannelCard(
                  icon: Icons.smartphone_outlined,
                  title: 'Push Notifications',
                  subtitle: 'Instant alerts on your\ndevice',
                  value: _pushNotifications,
                  emphasized: true,
                  onChanged: (value) =>
                      setState(() => _pushNotifications = value),
                ),
                const SizedBox(height: 14),
                _NotificationChannelCard(
                  icon: Icons.mail_outline,
                  title: 'Email Notifications',
                  subtitle: 'Weekly summary via\nemail',
                  value: _emailNotifications,
                  onChanged: (value) =>
                      setState(() => _emailNotifications = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'NOTIFICATION TYPES',
              style: TextStyle(
                fontSize: 18,
                letterSpacing: 0.6,
                fontWeight: FontWeight.w700,
                color: palette.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: palette.border),
              ),
              child: Column(
                children: [
                  _NotificationTypeRow(
                    icon: Icons.star_border_rounded,
                    title: 'Rating Reminders',
                    subtitle: 'Get reminded to rate\nyour lenses',
                    value: _ratingReminders,
                    onChanged: (value) =>
                        setState(() => _ratingReminders = value),
                  ),
                  Divider(height: 1, color: palette.border),
                  _NotificationTypeRow(
                    icon: Icons.notifications_none_rounded,
                    title: 'Service Notifications',
                    subtitle: 'Updates from your\noptician',
                    value: _serviceNotifications,
                    onChanged: (value) =>
                        setState(() => _serviceNotifications = value),
                  ),
                  Divider(height: 1, color: palette.border),
                  _NotificationTypeRow(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'New Lens Alerts',
                    subtitle: 'News about HOYA\nproducts',
                    value: _newLensAlerts,
                    onChanged: (value) =>
                        setState(() => _newLensAlerts = value),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              decoration: BoxDecoration(
                color: palette.secondary,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: palette.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: palette.surface,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: palette.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stay Updated',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Notifications help you stay informed about your lens care journey. You can adjust these settings anytime.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 26),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notification settings saved.'),
                    ),
                  );
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text(
                  'Save Changes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(62),
                  backgroundColor: palette.primary,
                  foregroundColor: palette.onPrimary,
                  elevation: 0,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: 2,
        onSelected: widget.onTabSelected,
      ),
    );
  }
}

class _NotificationChannelCard extends StatelessWidget {
  const _NotificationChannelCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.emphasized = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: emphasized ? palette.border : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: palette.surface,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: palette.primary, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: value,
            activeTrackColor: palette.primary,
            activeThumbColor: palette.onPrimary,
            inactiveTrackColor: palette.border,
            inactiveThumbColor: palette.surface,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _NotificationTypeRow extends StatelessWidget {
  const _NotificationTypeRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: palette.secondary,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: palette.primary, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: value,
            activeTrackColor: palette.primary,
            activeThumbColor: palette.onPrimary,
            inactiveTrackColor: palette.border,
            inactiveThumbColor: palette.surface,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
