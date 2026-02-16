import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../app/session_controller.dart';
import '../branding/brand_context.dart';
import '../shared/app_widgets.dart';

/// Main authenticated shell with bottom-tab navigation.
class LensCoreShell extends StatefulWidget {
  const LensCoreShell({super.key, required this.controller});

  final SessionController controller;

  @override
  State<LensCoreShell> createState() => _LensCoreShellState();
}

class _LensCoreShellState extends State<LensCoreShell> {
  int _index = 0;
  bool _isTransitioning = false;
  RatingData? _opticianRating;
  final List<LensItem> _lenses = [
    LensItem(
      name: 'Lens Name',
      purchaseDate: '2024-02-16',
      optician: 'Optician A',
    ),
    LensItem(
      name: 'Lens Name',
      purchaseDate: '2024-06-04',
      optician: 'Optician B',
    ),
  ];

  /// Adds a lens item to in-memory list and switches to lens list tab.
  void _addLens(String serial, String optician) {
    setState(() {
      _lenses.insert(
        0,
        LensItem(
          name: serial.isEmpty ? 'Lens Name' : serial,
          purchaseDate: DateTime.now().toIso8601String().split('T').first,
          optician: optician.isEmpty ? 'Unknown' : optician,
        ),
      );
      _index = 1;
    });
  }

  /// Updates active bottom-tab index.
  Future<void> _showTransitionLoader() async {
    setState(() => _isTransitioning = true);
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    setState(() => _isTransitioning = false);
  }

  Future<void> _selectTab(int index) async {
    await _showTransitionLoader();
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
    await _showTransitionLoader();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterLensScreen(
          onRegisterLens: _addLens,
          onTabSelected: _navigateFromOverlay,
        ),
      ),
    );
  }

  /// Opens passport details for the selected lens.
  Future<void> _openPassport(LensItem lens) async {
    await _showTransitionLoader();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            LensPassportScreen(lens: lens, onTabSelected: _navigateFromOverlay),
      ),
    );
  }

  /// Opens optician rating flow and stores latest result in memory.
  Future<void> _openRateOptician() async {
    await _showTransitionLoader();
    if (!mounted) return;
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
    await _showTransitionLoader();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            NotificationSettingsScreen(onTabSelected: _navigateFromOverlay),
      ),
    );
  }

  /// Opens profile privacy and data protection screen.
  Future<void> _openPrivacyDataProtection() async {
    await _showTransitionLoader();
    if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    final pages = [
      DashboardScreen(
        onGoRegister: _openRegisterLens,
        onGoLenses: () => setState(() => _index = 1),
        onRate: _openRateOptician,
      ),
      LensesListScreen(lenses: _lenses, onOpenDetails: _openPassport),
      ProfileOverviewScreen(
        name: widget.controller.userName,
        email: widget.controller.userEmail,
        selectedOptician: _lenses.isEmpty
            ? 'No optician selected'
            : _lenses.first.optician,
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
            SafeArea(child: pages[_index]),
            if (_isTransitioning || widget.controller.busy)
              Positioned.fill(
                child: ColoredBox(
                  color: palette.overlay,
                  child: Center(child: CircularProgressIndicator()),
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
    required this.onGoRegister,
    required this.onGoLenses,
    required this.onRate,
  });

  final Future<void> Function() onGoRegister;
  final VoidCallback onGoLenses;
  final VoidCallback onRate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 20),
      children: [
        _dashboardTile(
          context,
          title: 'Register new\nlenses',
          onTap: () => onGoRegister(),
        ),
        const SizedBox(height: 14),
        _dashboardTile(context, title: 'My Lenses', onTap: onGoLenses),
        const SizedBox(height: 14),
        _dashboardTile(context, title: 'Rate my\nexperience', onTap: onRate),
      ],
    );
  }

  Widget _dashboardTile(
    BuildContext context, {
    required String title,
    required VoidCallback onTap,
  }) {
    final palette = context.brandPalette;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: palette.accentSoft,
              child: Text(
                'A',
                style: TextStyle(
                  color: palette.primary,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: palette.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: palette.iconMuted, size: 30),
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
    required this.onTabSelected,
  });

  final void Function(String serial, String optician) onRegisterLens;
  final ValueChanged<int> onTabSelected;

  @override
  State<RegisterLensScreen> createState() => _RegisterLensScreenState();
}

class _RegisterLensScreenState extends State<RegisterLensScreen> {
  final _serial = TextEditingController();
  String? _selectedOptician;

  Future<void> _scanQrCode() async {
    final scannedValue = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => const QrScannerScreen()));
    if (!mounted || scannedValue == null || scannedValue.isEmpty) return;
    setState(() => _serial.text = scannedValue);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR code scanned successfully.')),
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
            'ITEM',
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
              hintText: 'Serial Number',
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
            onPressed: () {
              widget.onRegisterLens(
                _serial.text.trim(),
                _selectedOptician ?? '',
              );
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
    required this.onOpenDetails,
  });

  final List<LensItem> lenses;
  final void Function(LensItem lens) onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
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
              _PassportTab.prescription => const _PassportPrescription(
                key: ValueKey('prescription'),
              ),
              _PassportTab.frameMeasurements =>
                const _PassportFrameMeasurements(
                  key: ValueKey('frame-measurements'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _passportInfoRow(context, 'Lens Design', 'Hoyalux iD MySense'),
        _passportInfoRow(context, 'Antireflex Coating', 'Hi-Vision MEIRYO'),
        _passportInfoRow(context, 'Material', '1.60'),
        _passportInfoRow(context, 'Design Variation Code', '309'),
        _passportInfoRow(context, 'My Design Selection', '000002'),
        const SizedBox(height: 12),
        Text(
          'Registered Lens: ${lens.name} • ${lens.purchaseDate} • ${lens.optician}',
          style: TextStyle(color: palette.textSecondary, fontSize: 13),
        ),
      ],
    );
  }

  Widget _passportInfoRow(BuildContext context, String label, String value) {
    final palette = context.brandPalette;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: palette.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 14, color: palette.textPrimary),
              ),
              const SizedBox(width: 6),
              Icon(Icons.info_rounded, color: palette.textPrimary, size: 16),
            ],
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
}

class _PassportPrescription extends StatelessWidget {
  const _PassportPrescription({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
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
        const _PassportDualValueRow(
          label: 'Sphere Power',
          rightValue: '-1.03',
          leftValue: '-2.52',
        ),
        const _PassportDualValueRow(
          label: 'Cylinder Power',
          rightValue: '-0.98',
          leftValue: '-0.76',
        ),
        const _PassportDualValueRow(
          label: 'Cylinder Axis (°)',
          rightValue: '175',
          leftValue: '45',
        ),
        const _PassportDualValueRow(
          label: 'Addition Power',
          rightValue: '2.01',
          leftValue: '2.01',
        ),
      ],
    );
  }
}

class _PassportFrameMeasurements extends StatelessWidget {
  const _PassportFrameMeasurements({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
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
        const _PassportDualValueRow(
          label: 'Pupil Distance (mm)',
          rightValue: '32.0',
          leftValue: '32.0',
        ),
        const _PassportDualValueRow(
          label: 'Eyepoint Height (mm)',
          rightValue: '25.0',
          leftValue: '25.0',
        ),
        const _PassportDualValueRow(
          label: 'Inset (mm)',
          rightValue: '2.25',
          leftValue: '2.29',
        ),
        const _PassportDualValueRow(
          label: 'Cornea Vertex Distance (mm)',
          rightValue: '16.50',
          leftValue: '16.50',
        ),
        const _PassportDualValueRow(
          label: 'Axial Length (mm)',
          rightValue: '23',
          leftValue: '23',
        ),
        const _PassportDualValueRow(
          label: 'Pantoscopic Angle (°)',
          rightValue: '5.15°',
          leftValue: '5.12',
        ),
        const _PassportDualValueRow(
          label: 'Frame or Lens Measurements',
          rightValue: 'F',
          leftValue: 'F',
        ),
        const _PassportDualValueRow(
          label: 'Frame Face Angle (°)',
          rightValue: '7.1',
          leftValue: '7.1',
        ),
      ],
    );
  }
}

class _PassportDualValueRow extends StatelessWidget {
  const _PassportDualValueRow({
    required this.label,
    required this.rightValue,
    required this.leftValue,
  });

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
                Icon(Icons.info_rounded, color: palette.textPrimary, size: 16),
              ],
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
    required this.onNotificationSettings,
    required this.onPrivacy,
    required this.onLogout,
  });

  final String name;
  final String email;
  final String selectedOptician;
  final Future<void> Function() onNotificationSettings;
  final Future<void> Function() onPrivacy;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: Text(
              'Profile settings',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 16),
          _ProfileInfoCard(title: 'Name', value: name),
          const SizedBox(height: 10),
          _ProfileInfoCard(title: 'Email', value: email),
          const SizedBox(height: 10),
          _ProfileInfoCard(title: 'Selected Optician', value: selectedOptician),
          const Spacer(),
          Center(
            child: SecondaryPillButton(
              text: 'Edit Profile',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Edit profile flow not implemented yet.'),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: SecondaryPillButton(
              text: 'Change Optician',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Change optician flow not implemented yet.'),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: SecondaryPillButton(
              text: 'Notification Settings',
              onTap: () => onNotificationSettings(),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: SecondaryPillButton(
              text: 'Privacy & Data',
              onTap: () => onPrivacy(),
            ),
          ),
          const SizedBox(height: 20),
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
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
    return Scaffold(
      appBar: const TopBackAppBar(title: 'Notification Settings'),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
        child: Column(
          children: [
            _settingsToggleTile(
              label: 'Rating reminders',
              value: _ratingReminders,
              onChanged: (value) => setState(() => _ratingReminders = value),
            ),
            const SizedBox(height: 14),
            _settingsToggleTile(
              label: 'Service notifications',
              value: _serviceNotifications,
              onChanged: (value) =>
                  setState(() => _serviceNotifications = value),
            ),
            const Spacer(),
            SecondaryPillButton(
              text: 'Save selection',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notification settings saved.')),
                );
              },
            ),
          ],
        ),
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
  bool _consentGranted = true;

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

    setState(() => _consentGranted = false);

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
      setState(() => _consentGranted = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopBackAppBar(title: 'Privacy & Data Protection'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
        children: [
          _privacyCard(
            child: const Text(
              'Privacy Information\n'
              'Your personal data is processed in accordance with the GDPR.\n\n'
              'Stored data includes:\n'
              '• Lens registrations\n'
              '• Ratings and feedback\n'
              '• Selected optician',
              style: TextStyle(fontSize: 15, height: 1.45),
            ),
          ),
          const SizedBox(height: 14),
          _privacyCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Text(
                    'Data Processing Consent\n\n'
                    'I agree to the processing of my personal data for app functionality',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Switch(
                  value: _consentGranted,
                  onChanged: (value) => setState(() => _consentGranted = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _privacyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Information\n'
                  'If you withdraw consent:\n'
                  '• Your personal data will be deleted\n'
                  '• Registered lenses will be removed\n'
                  '• Ratings will be anonymized',
                  style: TextStyle(fontSize: 15, height: 1.45),
                ),
                const SizedBox(height: 14),
                Center(
                  child: SecondaryPillButton(
                    text: 'Withdraw Consent',
                    onTap: _handleWithdrawConsent,
                  ),
                ),
              ],
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEAF2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

/// Shared toggle tile widget builder for notification settings.
Widget _settingsToggleTile({
  required String label,
  required bool value,
  required ValueChanged<bool> onChanged,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
    decoration: BoxDecoration(
      color: const Color(0xFFEFEAF2),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
        Switch(value: value, onChanged: onChanged),
      ],
    ),
  );
}

/// Shared card container builder for privacy screens.
Widget _privacyCard({required Widget child}) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFEFEAF2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: child,
  );
}

/// Simple in-memory lens model used by prototype flows.
class LensItem {
  const LensItem({
    required this.name,
    required this.purchaseDate,
    required this.optician,
  });

  final String name;
  final String purchaseDate;
  final String optician;
}

/// In-memory rating payload used between rating screens.
class RatingData {
  const RatingData({required this.stars, required this.comment});

  final int stars;
  final String comment;
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
