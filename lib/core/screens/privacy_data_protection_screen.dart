import 'package:flutter/material.dart';

import '../../branding/brand_context.dart';
import '../../shared/app_widgets.dart';

/// Privacy and data protection detail screen.
class PrivacyDataProtectionScreen extends StatefulWidget {
  const PrivacyDataProtectionScreen({
    super.key,
    required this.onTabSelected,
    required this.onWithdrawConsent,
    required this.consentActive,
    required this.shareWithOptician,
    required this.shareWithCompany,
    required this.onSavePreferences,
  });

  final ValueChanged<int> onTabSelected;
  final Future<String?> Function() onWithdrawConsent;
  final bool consentActive;
  final bool shareWithOptician;
  final bool shareWithCompany;
  final Future<String?> Function({
    required bool consentActive,
    required bool shareWithOptician,
    required bool shareWithCompany,
  })
  onSavePreferences;

  @override
  State<PrivacyDataProtectionScreen> createState() =>
      _PrivacyDataProtectionScreenState();
}

/// State for privacy consent controls and withdrawal confirmation.
class _PrivacyDataProtectionScreenState
    extends State<PrivacyDataProtectionScreen> {
  late bool _consentActive;
  late bool _shareWithOptician;
  late bool _shareWithCompany;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _consentActive = widget.consentActive;
    _shareWithOptician = widget.shareWithOptician;
    _shareWithCompany = widget.shareWithCompany;
  }

  Future<void> _savePreferences() async {
    if (_saving) return;
    setState(() => _saving = true);
    final error = await widget.onSavePreferences(
      consentActive: _consentActive,
      shareWithOptician: _shareWithOptician,
      shareWithCompany: _shareWithCompany,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Privacy settings saved.'),
      ),
    );
  }

  /// Confirms account-data withdrawal before executing the action.
  Future<void> _handleWithdrawConsent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Withdrawal'),
          content: const Text(
            'Withdrawing consent will delete your account data, including registered lenses and feedback.\n\n'
            'To use the app again, you will need to create a new account.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Withdraw Consent'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => _WithdrawalLoadingDialog(
        overlay: context.brandPalette.overlay,
        text: context.brandPalette.onPrimary,
      ),
    );

    final error = await widget.onWithdrawConsent();
    if (!mounted) return;

    final rootNavigator = Navigator.of(context, rootNavigator: true);
    if (rootNavigator.canPop()) {
      rootNavigator.pop();
    }

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
        children: [
          Container(
            height: 236,
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
                          'Privacy & Data\nProtection',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: palette.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Padding(
                    padding: const EdgeInsets.only(left: 24),
                    child: Text(
                      'Your data security matters\nto us',
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        color: palette.onPrimary.withValues(alpha: 0.92),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _PrivacyFeatureCard(
              icon: Icons.shield_outlined,
              title: 'GDPR\nCompliant',
              description:
                  'Your personal data is processed in accordance with the General Data Protection Regulation (GDPR).',
              selected: true,
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'DATA PROCESSING\nCONSENT',
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
            child: _DataProcessingConsentCard(
              consentActive: _consentActive,
              onChanged: (value) => setState(() => _consentActive = value),
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'DATA SHARING',
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
                _PrivacySharingCard(
                  icon: Icons.store_mall_directory_outlined,
                  title: 'Share with\nOptician',
                  description:
                      'Allow your optician to access your app data for support and follow-up care.',
                  value: _shareWithOptician,
                  onChanged: _consentActive
                      ? (value) => setState(() => _shareWithOptician = value)
                      : null,
                ),
                const SizedBox(height: 14),
                _PrivacySharingCard(
                  icon: Icons.business_outlined,
                  title: 'Share with\nCompany',
                  description:
                      'Allow the company to use your data for service quality, product improvement, and customer care.',
                  value: _shareWithCompany,
                  onChanged: _consentActive
                      ? (value) => setState(() => _shareWithCompany = value)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'DATA WE STORE',
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
              children: const [
                _PrivacyFeatureCard(
                  icon: Icons.description_outlined,
                  title: 'Lens\nregistrations',
                  description: 'Product details and purchase info',
                ),
                SizedBox(height: 14),
                _PrivacyFeatureCard(
                  icon: Icons.remove_red_eye_outlined,
                  title: 'Ratings and\nfeedback',
                  description: 'Your reviews and comments',
                ),
                SizedBox(height: 14),
                _PrivacyFeatureCard(
                  icon: Icons.shield_outlined,
                  title: 'Selected\noptician',
                  description: 'Your preferred vision care provider',
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'YOUR RIGHTS',
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
                _PrivacyFeatureCard(
                  icon: Icons.download_rounded,
                  title: 'Download My\nData',
                  description: 'Get a copy of your personal data',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Data export flow not implemented yet.'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                _PrivacyFeatureCard(
                  icon: Icons.article_outlined,
                  title: 'View Privacy\nPolicy',
                  description: 'Read our full privacy policy',
                  selected: true,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Privacy policy link flow not implemented yet.',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _savePreferences,
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _saving ? 'Saving...' : 'Save Privacy Settings',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(58),
                  backgroundColor: palette.primary,
                  foregroundColor: palette.onPrimary,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _WithdrawConsentCard(onTap: _handleWithdrawConsent),
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

class _PrivacyFeatureCard extends StatelessWidget {
  const _PrivacyFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: selected ? palette.secondary : palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: selected ? palette.primary : palette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: selected ? palette.primary : palette.secondary,
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: selected ? palette.onPrimary : palette.primary,
              size: 34,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
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
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: content,
      ),
    );
  }
}

class _DataProcessingConsentCard extends StatelessWidget {
  const _DataProcessingConsentCard({
    required this.consentActive,
    required this.onChanged,
  });

  final bool consentActive;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: palette.secondary,
                  borderRadius: BorderRadius.circular(24),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: palette.primary,
                  size: 34,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Data\nProcessing',
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Allow processing of personal data for app functionality',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: consentActive,
                activeTrackColor: palette.primary,
                activeThumbColor: palette.onPrimary,
                inactiveTrackColor: palette.border,
                inactiveThumbColor: palette.surface,
                onChanged: onChanged,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: consentActive
                    ? const Color(0xFFE0F3E6)
                    : const Color(0xFFF2ECE3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                consentActive
                    ? '✓ Active - Your data is being processed securely'
                    : 'Consent inactive - App data processing is disabled',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  color: consentActive
                      ? const Color(0xFF0A8A2A)
                      : const Color(0xFF8A6B00),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacySharingCard extends StatelessWidget {
  const _PrivacySharingCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Opacity(
      opacity: onChanged == null ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: palette.secondary,
                borderRadius: BorderRadius.circular(24),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: palette.primary, size: 34),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
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
      ),
    );
  }
}

class _WithdrawConsentCard extends StatelessWidget {
  const _WithdrawConsentCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7B9B9), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.delete_outline, color: Color(0xFFE00000)),
              const SizedBox(width: 10),
              Text(
                'Danger Zone',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFE00000),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'This action cannot be undone. Your account and all data will be permanently deleted.',
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor: const Color(0xFFE00000),
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Withdraw\nConsent &\nDelete Data',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WithdrawalLoadingDialog extends StatelessWidget {
  const _WithdrawalLoadingDialog({required this.overlay, required this.text});

  final Color overlay;
  final Color text;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: ColoredBox(
        color: overlay,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Withdrawing consent and signing you out...',
                style: TextStyle(color: text),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
