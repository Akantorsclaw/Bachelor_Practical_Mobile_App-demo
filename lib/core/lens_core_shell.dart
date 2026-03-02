import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../app/session_controller.dart';
import '../branding/brand_context.dart';
import '../models/app_lens.dart';
import '../models/lens_passport_data.dart';
import '../services/lens_parameter_info_service.dart';
import '../services/lens_service.dart';
import '../services/lens_pass_qr_parser.dart';
import '../shared/app_widgets.dart';
import '../shared/validators.dart';

/// Main authenticated shell with bottom-tab navigation.
class LensCoreShell extends StatefulWidget {
  const LensCoreShell({super.key, required this.controller});

  final SessionController controller;

  @override
  State<LensCoreShell> createState() => _LensCoreShellState();
}

class _LensCoreShellState extends State<LensCoreShell> {
  static const _qrParser = LensPassQrParser();
  final _lensService = LensService(FirebaseFirestore.instance);

  int _index = 0;
  bool _loadingLenses = true;
  RatingData? _opticianRating;
  List<LensItem> _lenses = [];
  StreamSubscription<List<AppLens>>? _lensesSubscription;

  @override
  void initState() {
    super.initState();
    _subscribeLenses();
  }

  @override
  void didUpdateWidget(covariant LensCoreShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller.userId != widget.controller.userId) {
      _subscribeLenses();
    }
  }

  @override
  void dispose() {
    _lensesSubscription?.cancel();
    super.dispose();
  }

  void _subscribeLenses() {
    _lensesSubscription?.cancel();
    final uid = widget.controller.userId;
    if (uid == null) {
      setState(() {
        _lenses = [];
        _loadingLenses = false;
      });
      return;
    }
    setState(() => _loadingLenses = true);
    _lensesSubscription = _lensService
        .watchLenses(uid)
        .listen(
          (data) {
            if (!mounted) return;
            setState(() {
              _lenses = data.map(_toLensItem).toList();
              _loadingLenses = false;
            });
          },
          onError: (_) {
            if (!mounted) return;
            setState(() => _loadingLenses = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not load lenses from Firestore.'),
              ),
            );
          },
        );
  }

  LensItem _toLensItem(AppLens lens) {
    return LensItem(
      id: lens.id,
      name: lens.name,
      purchaseDate: lens.purchaseDate,
      optician: lens.optician,
      passportData: lens.passportData,
    );
  }

  Future<void> _addLens(LensItem lens) async {
    final uid = widget.controller.userId;
    if (uid == null) return;
    try {
      await _lensService.createLens(
        uid,
        AppLens(
          id: lens.id,
          name: lens.name,
          purchaseDate: lens.purchaseDate,
          optician: lens.optician,
          passportData: lens.passportData,
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final message = e.code == 'permission-denied'
          ? 'Saving lens failed: Firestore rules currently deny this write.'
          : 'Saving lens failed. Please try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saving lens failed. Please try again.')),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _index = 1);
  }

  Future<void> _selectTab(int index) async {
    if (!mounted) return;
    setState(() => _index = index);
  }

  /// Returns to root shell and changes the selected tab.
  void _navigateFromOverlay(int index) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    if (!mounted) return;
    setState(() => _index = index);
  }

  /// Opens lens registration as a pushed detail screen.
  Future<void> _openRegisterLens() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterLensScreen(
          onRegisterLens: _addLens,
          qrParser: _qrParser,
          onTabSelected: _navigateFromOverlay,
        ),
      ),
    );
  }

  /// Opens passport details for the selected lens.
  Future<void> _openPassport(LensItem lens) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            LensPassportScreen(lens: lens, onTabSelected: _navigateFromOverlay),
      ),
    );
  }

  /// Opens optician rating flow and stores latest result in memory.
  Future<void> _openRateOptician() async {
    final result = await Navigator.of(context).push<RatingData>(
      MaterialPageRoute(
        builder: (_) => RateLensScreen(
          title: 'Your Optician',
          submitLabel: 'Submit feedback',
          initialRating: _opticianRating,
          onTabSelected: _navigateFromOverlay,
        ),
      ),
    );
    if (result != null) {
      setState(() => _opticianRating = result);
    }
  }

  /// Opens profile notification settings screen.
  Future<void> _openNotificationSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            NotificationSettingsScreen(onTabSelected: _navigateFromOverlay),
      ),
    );
  }

  /// Opens profile privacy and data protection screen.
  Future<void> _openPrivacyDataProtection() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrivacyDataProtectionScreen(
          onTabSelected: _navigateFromOverlay,
          onWithdrawConsent: _handleWithdrawConsent,
        ),
      ),
    );
  }

  /// Runs consent withdrawal process through session controller.
  Future<String?> _handleWithdrawConsent() async {
    final error = await widget.controller.withdrawConsentAndLogout();
    if (!mounted) return error;
    if (error != null) return error;

    // Ensure nested profile routes are removed so auth flow is visible.
    Navigator.of(
      context,
      rootNavigator: true,
    ).popUntil((route) => route.isFirst);
    return null;
  }

  Future<void> _deleteLens(LensItem lens) async {
    final uid = widget.controller.userId;
    if (uid == null) return;
    try {
      await _lensService.deleteLens(uid, lens.id);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      final message = e.code == 'permission-denied'
          ? 'Delete failed: Firestore rules currently deny this delete.'
          : 'Delete failed. Please try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delete failed. Please try again.')),
      );
    }
  }

  Future<String?> _updateProfile({
    required String name,
    required String email,
  }) {
    return widget.controller.updateProfile(name: name, email: email);
  }

  String _formatLastRated(DateTime? ratedAt) {
    if (ratedAt == null) return '--';
    final days = DateTime.now().difference(ratedAt).inDays;
    if (days <= 0) return '0d';
    return '${days}d';
  }

  int _daysUntilCheckup(LensItem? lens) {
    if (lens == null) return 14;
    final purchase = DateTime.tryParse(lens.purchaseDate);
    if (purchase == null) return 14;
    final followUp = purchase.add(const Duration(days: 180));
    final days = followUp.difference(DateTime.now()).inDays;
    return days < 0 ? 0 : days;
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    final currentLens = _lenses.isEmpty ? null : _lenses.first;
    final pages = [
      DashboardScreen(
        userName: widget.controller.userName,
        lensesCount: _lenses.length,
        ratingsCount: _opticianRating == null ? 0 : 1,
        lastRatedLabel: _formatLastRated(_opticianRating?.ratedAt),
        currentLens: currentLens,
        currentLensRating: _opticianRating?.stars,
        daysUntilCheckup: _daysUntilCheckup(currentLens),
        onGoRegister: _openRegisterLens,
        onGoLenses: () => setState(() => _index = 1),
        onRate: _openRateOptician,
        onOpenPassport: () async {
          if (currentLens == null) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Register a lens first.')),
            );
            return;
          }
          await _openPassport(currentLens);
        },
      ),
      LensesListScreen(
        lenses: _lenses,
        loading: _loadingLenses,
        onOpenDetails: _openPassport,
        onDeleteLens: _deleteLens,
      ),
      ProfileOverviewScreen(
        name: widget.controller.userName,
        email: widget.controller.userEmail,
        selectedOptician: _lenses.isEmpty
            ? 'No optician selected'
            : _lenses.first.optician,
        onUpdateProfile: _updateProfile,
        onNotificationSettings: _openNotificationSettings,
        onPrivacy: _openPrivacyDataProtection,
        onLogout: widget.controller.signOut,
      ),
    ];

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_index != 0) {
          setState(() => _index = 0);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: KeyedSubtree(
                  key: ValueKey(_index),
                  child: pages[_index],
                ),
              ),
            ),
            if (widget.controller.busy)
              Positioned.fill(
                child: ColoredBox(
                  color: palette.scaffoldBackground.withValues(alpha: 0.9),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
        bottomNavigationBar: AppBottomNavigation(
          selectedIndex: _index,
          onSelected: (index) {
            _selectTab(index);
          },
        ),
      ),
    );
  }
}

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
  final VoidCallback onRate;
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
          'Current Lens',
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
                onTap: onRate,
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

/// Lens registration detail screen.
class RegisterLensScreen extends StatefulWidget {
  const RegisterLensScreen({
    super.key,
    required this.onRegisterLens,
    required this.qrParser,
    required this.onTabSelected,
  });

  final Future<void> Function(LensItem lens) onRegisterLens;
  final LensPassQrParser qrParser;
  final ValueChanged<int> onTabSelected;

  @override
  State<RegisterLensScreen> createState() => _RegisterLensScreenState();
}

class _RegisterLensScreenState extends State<RegisterLensScreen> {
  final _serial = TextEditingController();
  String? _selectedOptician;
  LensPassportData? _parsedPassport;

  Future<void> _scanQrCode() async {
    final scannedValue = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const QrScannerScreen()));
    if (!mounted || scannedValue == null || scannedValue.isEmpty) return;
    final parsed = widget.qrParser.parse(scannedValue);
    setState(() {
      _parsedPassport = parsed;
      _serial.text = parsed?.lensDesign != null && parsed!.lensDesign != '-'
          ? parsed.lensDesign
          : scannedValue;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          parsed == null
              ? 'QR code scanned. No passport fields found.'
              : 'QR code scanned and passport data extracted.',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _serial.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Scaffold(
      appBar: const TopBackAppBar(title: 'Lens Registration'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        children: [
          Text(
            'NAME',
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _serial,
            style: TextStyle(fontSize: 20, color: palette.textPrimary),
            decoration: InputDecoration(
              hintText: 'ENTER NAME',
              hintStyle: TextStyle(color: palette.textSecondary),
              filled: true,
              fillColor: palette.surfaceMuted,
              suffixIcon: Icon(
                Icons.camera_alt_outlined,
                color: palette.iconMuted,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _scanQrCode,
            icon: Icon(Icons.qr_code_scanner, color: palette.textPrimary),
            label: Text(
              'Scan QR code',
              style: TextStyle(
                color: palette.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(58),
              side: BorderSide(color: palette.border, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'STORE',
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedOptician,
            decoration: InputDecoration(
              filled: true,
              fillColor: palette.surfaceMuted,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            hint: const Text('Select Optician'),
            items: const [
              DropdownMenuItem(value: 'Optician A', child: Text('Optician A')),
              DropdownMenuItem(value: 'Optician B', child: Text('Optician B')),
              DropdownMenuItem(value: 'Optician C', child: Text('Optician C')),
            ],
            onChanged: (value) => setState(() => _selectedOptician = value),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () async {
              final nowDate = DateTime.now().toIso8601String().split('T').first;
              final parsed = _parsedPassport;
              final optician = _selectedOptician ?? '';
              await widget.onRegisterLens(
                LensItem(
                  id: '',
                  name: _serial.text.trim().isEmpty
                      ? (parsed?.lensDesign != null && parsed!.lensDesign != '-'
                            ? parsed.lensDesign
                            : 'Lens Name')
                      : _serial.text.trim(),
                  purchaseDate:
                      parsed?.orderDate != null && parsed!.orderDate != '-'
                      ? parsed.orderDate
                      : nowDate,
                  optician: optician.isEmpty ? 'Unknown' : optician,
                  passportData: parsed,
                ),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lens registered successfully.')),
              );
              Navigator.of(context).pop();
            },
            icon: Icon(Icons.adjust_outlined, color: palette.primary),
            label: Text(
              'Register Lens',
              style: TextStyle(
                color: palette.primary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: palette.accentSoft,
              minimumSize: const Size.fromHeight(58),
              shape: const StadiumBorder(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: 0,
        onSelected: widget.onTabSelected,
      ),
    );
  }
}

/// Lens list screen under the Lenses tab.
class LensesListScreen extends StatelessWidget {
  const LensesListScreen({
    super.key,
    required this.lenses,
    required this.loading,
    required this.onOpenDetails,
    required this.onDeleteLens,
  });

  final List<LensItem> lenses;
  final bool loading;
  final void Function(LensItem lens) onOpenDetails;
  final Future<void> Function(LensItem lens) onDeleteLens;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (lenses.isEmpty) {
      return Center(
        child: Text(
          'No registered lenses yet.',
          style: TextStyle(color: palette.textSecondary),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      itemCount: lenses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final lens = lenses[index];
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: palette.accentSoft,
                    child: Icon(
                      Icons.person_outline,
                      color: palette.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      lens.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete lens',
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Lens'),
                          content: Text(
                            'Delete "${lens.name}" from saved lenses?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                      await onDeleteLens(lens);
                    },
                    icon: Icon(
                      Icons.delete_outline,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Lens Info',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Lens Name: ${lens.name}',
                style: TextStyle(fontSize: 15, color: palette.textSecondary),
              ),
              Text(
                'Purchase Date: ${lens.purchaseDate}',
                style: TextStyle(fontSize: 15, color: palette.textSecondary),
              ),
              Text(
                'Optician: ${lens.optician}',
                style: TextStyle(fontSize: 15, color: palette.textSecondary),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => onOpenDetails(lens),
                  style: FilledButton.styleFrom(
                    backgroundColor: palette.primary,
                    foregroundColor: palette.onPrimary,
                    minimumSize: const Size.fromHeight(54),
                    shape: const StadiumBorder(),
                  ),
                  child: const Text(
                    'Details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class LensPassportScreen extends StatefulWidget {
  const LensPassportScreen({
    super.key,
    required this.lens,
    required this.onTabSelected,
  });

  final LensItem lens;
  final ValueChanged<int> onTabSelected;

  @override
  State<LensPassportScreen> createState() => _LensPassportScreenState();
}

enum _PassportTab { lensDetails, prescription, frameMeasurements }

class _LensPassportScreenState extends State<LensPassportScreen> {
  _PassportTab _tab = _PassportTab.lensDetails;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBackAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
        children: [
          Text(
            'My Vision Details',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: context.brandPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 18),
          _PassportSegmentControl(
            selected: _tab,
            onChanged: (tab) => setState(() => _tab = tab),
          ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: switch (_tab) {
              _PassportTab.lensDetails => _PassportLensDetails(
                key: const ValueKey('lens-details'),
                lens: widget.lens,
              ),
              _PassportTab.prescription => _PassportPrescription(
                key: const ValueKey('prescription'),
                lens: widget.lens,
              ),
              _PassportTab.frameMeasurements => _PassportFrameMeasurements(
                key: const ValueKey('frame-measurements'),
                lens: widget.lens,
              ),
            },
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: 1,
        onSelected: widget.onTabSelected,
      ),
    );
  }
}

class _PassportSegmentControl extends StatelessWidget {
  const _PassportSegmentControl({
    required this.selected,
    required this.onChanged,
  });

  final _PassportTab selected;
  final ValueChanged<_PassportTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.segmentSelected),
      ),
      child: Row(
        children: [
          _segmentButton(
            context,
            tab: _PassportTab.lensDetails,
            label: 'Lens Details',
          ),
          _segmentButton(
            context,
            tab: _PassportTab.prescription,
            label: 'Prescription',
          ),
          _segmentButton(
            context,
            tab: _PassportTab.frameMeasurements,
            label: 'Frame Measurements',
          ),
        ],
      ),
    );
  }

  Widget _segmentButton(
    BuildContext context, {
    required _PassportTab tab,
    required String label,
  }) {
    final palette = context.brandPalette;
    final isSelected = selected == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? palette.segmentSelected : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? palette.onSegmentSelected
                  : palette.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _PassportLensDetails extends StatelessWidget {
  const _PassportLensDetails({super.key, required this.lens});

  final LensItem lens;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    final passport = lens.passportData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _passportInfoRow(
          context,
          code: 'LC',
          label: 'Lens Design',
          value: passport?.lensDesign ?? 'Hoyalux iD MySense',
        ),
        _passportInfoRow(
          context,
          code: 'AC',
          label: 'Antireflex Coating',
          value: passport?.antiReflexCoating ?? 'Hi-Vision MEIRYO',
        ),
        _passportInfoRow(
          context,
          code: 'MC',
          label: 'Material',
          value: passport?.material ?? '1.60',
        ),
        _passportInfoRow(
          context,
          code: 'DVC',
          label: 'Design Variation Code',
          value: passport?.designVariationCode ?? '309',
        ),
        _passportInfoRow(
          context,
          code: 'MDS',
          label: 'My Design Selection',
          value: passport?.myDesignSelection ?? '000002',
        ),
        const SizedBox(height: 12),
        Text(
          'Registered Lens: ${lens.name} • ${lens.purchaseDate} • ${lens.optician}'
          '${passport != null ? ' • Order ${passport.orderNumber}' : ''}',
          style: TextStyle(color: palette.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _passportInfoRow(
    BuildContext context, {
    required String code,
    required String label,
    required String value,
  }) {
    final palette = context.brandPalette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _showInfoCard(context, code: code, fieldName: label),
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 14, color: palette.textPrimary),
                ),
                const SizedBox(width: 6),
                Icon(Icons.info_rounded, color: palette.textPrimary, size: 16),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoCard(
    BuildContext context, {
    required String code,
    required String fieldName,
  }) {
    final palette = context.brandPalette;
    final info = LensParameterInfoService.explanationForCode(code);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fieldName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                info,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PassportPrescription extends StatelessWidget {
  const _PassportPrescription({super.key, required this.lens});

  final LensItem lens;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    final right = lens.passportData?.right;
    final left = lens.passportData?.left;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Container(height: 1, color: palette.border)),
            const SizedBox(width: 14),
            Expanded(child: Container(height: 1, color: palette.border)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Right Eye',
                style: TextStyle(color: palette.textSecondary),
              ),
            ),
            Expanded(
              child: Text(
                'Left Eye',
                textAlign: TextAlign.end,
                style: TextStyle(color: palette.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _PassportDualValueRow(
          parameterCodes: const ['SR', 'SL'],
          label: 'Sphere Power',
          rightValue: right?.spherePower ?? '-1.03',
          leftValue: left?.spherePower ?? '-2.52',
        ),
        _PassportDualValueRow(
          parameterCodes: const ['CR', 'CL'],
          label: 'Cylinder Power',
          rightValue: right?.cylinderPower ?? '-0.98',
          leftValue: left?.cylinderPower ?? '-0.76',
        ),
        _PassportDualValueRow(
          parameterCodes: const ['XR', 'XL'],
          label: 'Cylinder Axis (°)',
          rightValue: right?.cylinderAxis ?? '175',
          leftValue: left?.cylinderAxis ?? '45',
        ),
        _PassportDualValueRow(
          parameterCodes: const ['AR', 'AL'],
          label: 'Addition Power',
          rightValue: right?.additionPower ?? '2.01',
          leftValue: left?.additionPower ?? '2.01',
        ),
      ],
    );
  }
}

class _PassportFrameMeasurements extends StatelessWidget {
  const _PassportFrameMeasurements({super.key, required this.lens});

  final LensItem lens;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    final right = lens.passportData?.right;
    final left = lens.passportData?.left;
    final frameFaceAngle = lens.passportData?.frameFaceAngle;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Container(height: 1, color: palette.border)),
            const SizedBox(width: 14),
            Expanded(child: Container(height: 1, color: palette.border)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Right Eye',
                style: TextStyle(color: palette.textSecondary),
              ),
            ),
            Expanded(
              child: Text(
                'Left Eye',
                textAlign: TextAlign.end,
                style: TextStyle(color: palette.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _PassportDualValueRow(
          parameterCodes: const ['PDR', 'PDL'],
          label: 'Pupil Distance (mm)',
          rightValue: right?.pupilDistance ?? '32.0',
          leftValue: left?.pupilDistance ?? '32.0',
        ),
        _PassportDualValueRow(
          parameterCodes: const ['EPR', 'EPL'],
          label: 'Eyepoint Height (mm)',
          rightValue: right?.eyepointHeight ?? '25.0',
          leftValue: left?.eyepointHeight ?? '25.0',
        ),
        _PassportDualValueRow(
          parameterCodes: const ['IR', 'IL'],
          label: 'Inset (mm)',
          rightValue: right?.inset ?? '2.25',
          leftValue: left?.inset ?? '2.29',
        ),
        _PassportDualValueRow(
          parameterCodes: const ['RFC', 'LFC'],
          label: 'Cornea Vertex Distance (mm)',
          rightValue: right?.corneaVertexDistance ?? '16.50',
          leftValue: left?.corneaVertexDistance ?? '16.50',
        ),
        _PassportDualValueRow(
          parameterCodes: const ['ALR', 'ALL'],
          label: 'Axial Length (mm)',
          rightValue: right?.axialLength ?? '23',
          leftValue: left?.axialLength ?? '23',
        ),
        _PassportDualValueRow(
          parameterCodes: const ['RPA', 'LPA'],
          label: 'Pantoscopic Angle (°)',
          rightValue: right?.pantoscopicAngle ?? '5.15',
          leftValue: left?.pantoscopicAngle ?? '5.12',
        ),
        _PassportDualValueRow(
          parameterCodes: const ['FL', 'FL'],
          label: 'Frame or Lens Measurements',
          rightValue: right?.frameOrLensMeasurement ?? 'F',
          leftValue: left?.frameOrLensMeasurement ?? 'F',
        ),
        _PassportDualValueRow(
          parameterCodes: const ['FFA', 'FFA'],
          label: 'Frame Face Angle (°)',
          rightValue: frameFaceAngle ?? '7.1',
          leftValue: frameFaceAngle ?? '7.1',
        ),
      ],
    );
  }
}

class _PassportDualValueRow extends StatelessWidget {
  const _PassportDualValueRow({
    required this.parameterCodes,
    required this.label,
    required this.rightValue,
    required this.leftValue,
  });

  final List<String> parameterCodes;
  final String label;
  final String rightValue;
  final String leftValue;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              rightValue,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: () => _showInfoCard(context),
              borderRadius: BorderRadius.circular(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.2,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.info_rounded,
                    color: palette.textPrimary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Text(
              leftValue,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoCard(BuildContext context) {
    final palette = context.brandPalette;
    final info = LensParameterInfoService.explanationForCode(
      parameterCodes.first,
    );
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                info,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  color: palette.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Rating creation screen for lens/optician.
class RateLensScreen extends StatefulWidget {
  const RateLensScreen({
    super.key,
    required this.title,
    required this.submitLabel,
    required this.onTabSelected,
    this.initialRating,
  });

  final String title;
  final String submitLabel;
  final ValueChanged<int> onTabSelected;
  final RatingData? initialRating;

  @override
  State<RateLensScreen> createState() => _RateLensScreenState();
}

/// State for rating creation interactions.
class _RateLensScreenState extends State<RateLensScreen> {
  late final TextEditingController _commentController;
  int _rating = 0;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating?.stars ?? 0;
    _commentController = TextEditingController(
      text: widget.initialRating?.comment ?? 'Lorem',
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    final data = RatingData(
      stars: _rating == 0 ? 5 : _rating,
      comment: _commentController.text.trim().isEmpty
          ? 'Lorem'
          : _commentController.text.trim(),
      ratedAt: DateTime.now(),
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => EditRatingScreen(
          initialRating: data,
          onTabSelected: widget.onTabSelected,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Scaffold(
      appBar: const TopBackAppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
          children: [
            Center(
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 126,
                height: 126,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: palette.border, width: 2),
                ),
                child: Icon(
                  Icons.image_outlined,
                  size: 58,
                  color: palette.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 34),
            Center(
              child: _RatingStars(
                rating: _rating,
                onSelected: (value) => setState(() => _rating = value),
              ),
            ),
            const SizedBox(height: 34),
            Text(
              'Comment Text Area',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _commentController,
              minLines: 4,
              maxLines: 4,
              style: TextStyle(fontSize: 17, color: palette.textPrimary),
              decoration: InputDecoration(
                hintText: 'Lorem',
                hintStyle: TextStyle(color: palette.textSecondary),
                filled: true,
                fillColor: palette.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.send_outlined),
                label: Text(
                  widget.submitLabel,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: palette.onPrimary,
                  minimumSize: const Size.fromHeight(56),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: 1,
        onSelected: widget.onTabSelected,
      ),
    );
  }
}

/// Rating edit screen shown after submit.
class EditRatingScreen extends StatefulWidget {
  const EditRatingScreen({
    super.key,
    required this.initialRating,
    required this.onTabSelected,
  });

  final RatingData initialRating;
  final ValueChanged<int> onTabSelected;

  @override
  State<EditRatingScreen> createState() => _EditRatingScreenState();
}

/// State for rating edit interactions.
class _EditRatingScreenState extends State<EditRatingScreen> {
  late final TextEditingController _commentController;
  late int _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating.stars;
    _commentController = TextEditingController(
      text: widget.initialRating.comment,
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _update() {
    Navigator.of(context).pop(
      RatingData(
        stars: _rating,
        comment: _commentController.text.trim().isEmpty
            ? widget.initialRating.comment
            : _commentController.text.trim(),
        ratedAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Scaffold(
      appBar: const TopBackAppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
          children: [
            Center(
              child: Text(
                'Your Lens / Your Optician',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 126,
                height: 126,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: palette.border, width: 2),
                ),
                child: Icon(
                  Icons.image_outlined,
                  size: 58,
                  color: palette.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 34),
            Center(
              child: _RatingStars(
                rating: _rating,
                onSelected: (value) => setState(() => _rating = value),
              ),
            ),
            const SizedBox(height: 34),
            Text(
              'Comment Text Area',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _commentController,
              minLines: 4,
              maxLines: 4,
              style: TextStyle(fontSize: 17, color: palette.textPrimary),
              decoration: InputDecoration(
                hintText: 'Lorem',
                hintStyle: TextStyle(color: palette.textSecondary),
                filled: true,
                fillColor: palette.surfaceMuted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _update,
                icon: const Icon(Icons.send_outlined),
                label: const Text(
                  'Update',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: palette.primary,
                  foregroundColor: palette.onPrimary,
                  minimumSize: const Size.fromHeight(56),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: 1,
        onSelected: widget.onTabSelected,
      ),
    );
  }
}

class _RatingStars extends StatelessWidget {
  const _RatingStars({required this.rating, required this.onSelected});

  final int rating;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final number = index + 1;
        final isSelected = number <= rating;
        final borderColor = isSelected ? palette.primary : palette.border;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => onSelected(number),
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isSelected ? palette.secondary : Colors.transparent,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: borderColor, width: 2),
              ),
              child: Icon(
                isSelected ? Icons.star : Icons.star_border,
                color: borderColor,
                size: 30,
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Profile overview screen under the Profile tab.
class ProfileOverviewScreen extends StatelessWidget {
  const ProfileOverviewScreen({
    super.key,
    required this.name,
    required this.email,
    required this.selectedOptician,
    required this.onUpdateProfile,
    required this.onNotificationSettings,
    required this.onPrivacy,
    required this.onLogout,
  });

  final String name;
  final String email;
  final String selectedOptician;
  final Future<String?> Function({required String name, required String email})
  onUpdateProfile;
  final Future<void> Function() onNotificationSettings;
  final Future<void> Function() onPrivacy;
  final Future<void> Function() onLogout;

  Future<void> _editProfile(BuildContext context) async {
    final draft = await showDialog<_ProfileDraft>(
      context: context,
      builder: (context) =>
          _EditProfileDialog(initialName: name, initialEmail: email),
    );
    if (draft == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Profile Update'),
          content: const Text('Do you want to save these profile changes?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;

    final error = await onUpdateProfile(name: draft.name, email: draft.email);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Profile updated successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final palette = context.brandPalette;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 14),
      children: [
        Text(
          'Profile settings',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _ProfileInfoCard(title: 'Name', value: name),
        const SizedBox(height: 12),
        _ProfileInfoCard(title: 'Email', value: email),
        const SizedBox(height: 12),
        _ProfileInfoCard(title: 'Selected Optician', value: selectedOptician),
        const SizedBox(height: 22),
        _ProfileActionButton(
          text: 'Edit Profile',
          onTap: () => _editProfile(context),
        ),
        const SizedBox(height: 14),
        _ProfileActionButton(
          text: 'Change Optician',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Change optician flow not implemented yet.'),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        _ProfileActionButton(
          text: 'Notification Settings',
          onTap: () => onNotificationSettings(),
        ),
        const SizedBox(height: 14),
        _ProfileActionButton(text: 'Privacy & Data', onTap: () => onPrivacy()),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Confirm Logout'),
                    content: const Text(
                      'Do you really want to log out of your account?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Logout'),
                      ),
                    ],
                  );
                },
              );
              if (confirmed == true) {
                await onLogout();
              }
            },
            icon: const Icon(Icons.logout_rounded),
            label: const Text(
              'Logout',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: colors.error,
              foregroundColor: colors.onError,
              shape: const StadiumBorder(),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileDraft {
  const _ProfileDraft({required this.name, required this.email});

  final String name;
  final String email;
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({
    required this.initialName,
    required this.initialEmail,
  });

  final String initialName;
  final String initialEmail;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _save() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    Navigator.of(context).pop(
      _ProfileDraft(
        name: _nameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profile'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter your name',
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) return 'Enter your name';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'name@example.com',
              ),
              validator: validateEmail,
              onFieldSubmitted: (_) => _save(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Continue')),
      ],
    );
  }
}

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
  bool _ratingReminders = true;
  bool _serviceNotifications = true;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Scaffold(
      appBar: const TopBackAppBar(title: 'Notification Settings'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        children: [
          Text(
            'Notification Settings',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          _settingsRow(
            context,
            label: 'Rating reminders',
            value: _ratingReminders,
            onChanged: (value) => setState(() => _ratingReminders = value),
          ),
          Divider(height: 1, color: palette.border),
          _settingsRow(
            context,
            label: 'Service notifications',
            value: _serviceNotifications,
            onChanged: (value) => setState(() => _serviceNotifications = value),
          ),
          Divider(height: 1, color: palette.border),
          const SizedBox(height: 20),
          _ProfileActionButton(
            text: 'Save selection',
            primaryStyle: true,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification settings saved.')),
              );
            },
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

/// Privacy and data protection detail screen.
class PrivacyDataProtectionScreen extends StatefulWidget {
  const PrivacyDataProtectionScreen({
    super.key,
    required this.onTabSelected,
    required this.onWithdrawConsent,
  });

  final ValueChanged<int> onTabSelected;
  final Future<String?> Function() onWithdrawConsent;

  @override
  State<PrivacyDataProtectionScreen> createState() =>
      _PrivacyDataProtectionScreenState();
}

/// State for privacy consent controls and withdrawal confirmation.
class _PrivacyDataProtectionScreenState
    extends State<PrivacyDataProtectionScreen> {
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
      appBar: const TopBackAppBar(title: 'Privacy & Data Protection'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        children: [
          Text(
            'Privacy & Data Protection',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Privacy Information',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _privacyCard(
            context,
            child: Text(
              'Your personal data is processed in accordance with the GDPR.',
              style: TextStyle(
                fontSize: 16,
                height: 1.35,
                color: palette.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Stored data includes:',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _privacyCard(
            context,
            child: Text(
              '• Lens registrations\n• Ratings and feedback\n• Selected optician',
              style: TextStyle(
                fontSize: 16,
                height: 1.55,
                color: palette.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Data Processing Consent',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _privacyCard(
            context,
            child: Text(
              'I agree to the processing of my personal data for app functionality.',
              style: TextStyle(
                fontSize: 16,
                height: 1.35,
                color: palette.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Information',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          _privacyCard(
            context,
            child: Text(
              'If you withdraw consent:\n• Your personal data will be deleted\n• Registered lenses will be removed\n• Ratings will be anonymized',
              style: TextStyle(
                fontSize: 16,
                height: 1.55,
                color: palette.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _ProfileActionButton(
            text: 'Withdraw Consent',
            onTap: _handleWithdrawConsent,
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

/// Read-only profile info tile used on profile overview.
class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              height: 1.2,
              color: palette.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  const _ProfileActionButton({
    required this.text,
    required this.onTap,
    this.primaryStyle = false,
  });

  final String text;
  final VoidCallback onTap;
  final bool primaryStyle;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.watch_later_outlined, size: 24),
        label: Text(
          text,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(60),
          backgroundColor: primaryStyle ? palette.primary : palette.secondary,
          foregroundColor: primaryStyle ? palette.onPrimary : palette.primary,
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}

/// Shared settings row widget used on notification settings.
Widget _settingsRow(
  BuildContext context, {
  required String label,
  required bool value,
  required ValueChanged<bool> onChanged,
}) {
  final palette = context.brandPalette;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: palette.textPrimary,
            ),
          ),
        ),
        Switch(
          value: value,
          activeTrackColor: palette.primary,
          activeThumbColor: palette.onPrimary,
          onChanged: onChanged,
        ),
      ],
    ),
  );
}

/// Shared card container builder for privacy screens.
Widget _privacyCard(BuildContext context, {required Widget child}) {
  final palette = context.brandPalette;
  return Container(
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
    decoration: BoxDecoration(
      color: palette.surfaceMuted,
      borderRadius: BorderRadius.circular(14),
    ),
    child: child,
  );
}

/// Simple in-memory lens model used by prototype flows.
class LensItem {
  const LensItem({
    required this.id,
    required this.name,
    required this.purchaseDate,
    required this.optician,
    this.passportData,
  });

  final String id;
  final String name;
  final String purchaseDate;
  final String optician;
  final LensPassportData? passportData;
}

/// In-memory rating payload used between rating screens.
class RatingData {
  const RatingData({
    required this.stars,
    required this.comment,
    required this.ratedAt,
  });

  final int stars;
  final String comment;
  final DateTime ratedAt;
}

/// Full-screen QR scanner that returns the first detected raw value.
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBackAppBar(title: 'Scan QR code'),
      body: MobileScanner(
        onDetect: (capture) {
          if (_handled) return;
          final barcodes = capture.barcodes;
          if (barcodes.isEmpty) return;
          final value = barcodes.first.rawValue;
          if (value == null || value.isEmpty) return;
          _handled = true;
          Navigator.of(context).pop(value);
        },
      ),
    );
  }
}
