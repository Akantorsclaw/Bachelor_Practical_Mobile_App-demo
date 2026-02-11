import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../app/session_controller.dart';
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
  RatingData? _lensRating;
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
        builder: (_) => LensPassportScreen(
          lens: lens,
          onRateLens: () => _openRateLens(lens),
          onTabSelected: _navigateFromOverlay,
        ),
      ),
    );
  }

  /// Opens lens rating flow and stores latest result in memory.
  Future<void> _openRateLens(LensItem lens) async {
    await _showTransitionLoader();
    if (!mounted) return;
    final result = await Navigator.of(context).push<RatingData>(
      MaterialPageRoute(
        builder: (_) => RateLensScreen(
          title: 'Your Lens',
          submitLabel: 'Submit rating',
          initialRating: _lensRating,
          onTabSelected: _navigateFromOverlay,
        ),
      ),
    );
    if (result != null) {
      setState(() => _lensRating = result);
    }
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
  Future<void> _handleWithdrawConsent() async {
    final error = await widget.controller.withdrawConsentAndLogout();
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Consent withdrawn. Please re-register to use the app.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        onGoRegister: _openRegisterLens,
        onGoLenses: () => setState(() => _index = 1),
        onRate: _openRateOptician,
        onLogout: widget.controller.signOut,
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
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(child: pages[_index]),
          if (_isTransitioning || widget.controller.busy)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x88000000),
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
    required this.onLogout,
  });

  final Future<void> Function() onGoRegister;
  final VoidCallback onGoLenses;
  final VoidCallback onRate;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
      child: Column(
        children: [
          _dashboardTile('Register new lenses', () => onGoRegister()),
          const SizedBox(height: 14),
          _dashboardTile('My Lenses', onGoLenses),
          const SizedBox(height: 14),
          _dashboardTile('Rate my experience', onRate),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _placeholderCard()),
                const SizedBox(width: 8),
                Expanded(child: _placeholderCard()),
                const SizedBox(width: 8),
                Expanded(child: _placeholderCard()),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: () => onLogout(), child: const Text('Logout')),
        ],
      ),
    );
  }

  Widget _dashboardTile(String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE8E3EC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFD4C8EE),
              child: Text(
                title.characters.first,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.cloud, color: Colors.black26),
            const SizedBox(width: 6),
            const Icon(Icons.settings, color: Colors.black26),
            const SizedBox(width: 6),
            const Icon(Icons.square, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _placeholderCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8E3EC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(Icons.widgets_outlined, color: Colors.black26, size: 46),
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

/// State for lens registration form interactions.
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
    return Scaffold(
      appBar: const TopBackAppBar(title: 'Lens Registration'),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(28, 30, 28, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _serial,
              style: const TextStyle(fontSize: 20),
              decoration: const InputDecoration(
                labelText: 'Number',
                hintText: 'Serial Number',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                filled: true,
                fillColor: Color(0xFFE8E3EC),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.black38),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SecondaryPillButton(text: 'scan QR code', onTap: _scanQrCode),
            const SizedBox(height: 34),
            Row(
              children: [
                const Icon(Icons.stars_rounded, size: 16),
                const SizedBox(width: 8),
                const Text('Select Optician', style: TextStyle(fontSize: 18)),
                const Spacer(),
                DropdownButton<String>(
                  value: _selectedOptician,
                  hint: const Text('Choose'),
                  items: const [
                    DropdownMenuItem(
                      value: 'Optician A',
                      child: Text('Optician A'),
                    ),
                    DropdownMenuItem(
                      value: 'Optician B',
                      child: Text('Optician B'),
                    ),
                    DropdownMenuItem(
                      value: 'Optician C',
                      child: Text('Optician C'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedOptician = value),
                ),
              ],
            ),
            const Spacer(),
            Center(
              child: SecondaryPillButton(
                text: 'Register Lens',
                onTap: () {
                  widget.onRegisterLens(
                    _serial.text.trim(),
                    _selectedOptician ?? '',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Lens registered successfully.'),
                    ),
                  );
                  Navigator.of(context).pop();
                },
              ),
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
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      itemCount: lenses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final lens = lenses[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  lens.name,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Icon(
                  Icons.person_2_outlined,
                  size: 48,
                  color: Color(0xFFB8A5E2),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Lens Info',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Lens Name: ${lens.name}',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              Text(
                'Purchase Date: ${lens.purchaseDate}',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              Text(
                'Optician: ${lens.optician}',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2D2D30),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => onOpenDetails(lens),
                  child: const Text('Details'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Digital lens passport detail screen.
class LensPassportScreen extends StatelessWidget {
  const LensPassportScreen({
    super.key,
    required this.lens,
    required this.onRateLens,
    required this.onTabSelected,
  });

  final LensItem lens;
  final VoidCallback onRateLens;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Digital Lens Passport')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF292A2D),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  lens.name,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Icon(
                  Icons.person_2_outlined,
                  size: 52,
                  color: Color(0xFFD2C2F4),
                ),
              ),
              const SizedBox(height: 16),
              _passportLine('Lens Type', 'Single Vision'),
              _passportLine('Coating', 'Blue Light Filter'),
              _passportLine('Diopter Values', '-1.50 / -1.25'),
              _passportLine('Purchase Location', lens.optician),
              _passportLine('Purchase Date', lens.purchaseDate),
              const Spacer(),
              Center(
                child: PrimaryPillButton(
                  text: 'Rate this Lens',
                  onTap: onRateLens,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: 1,
        onSelected: onTabSelected,
      ),
    );
  }

  Widget _passportLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 20, color: Colors.white),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(color: Colors.white70),
            ),
            TextSpan(text: value),
          ],
        ),
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
    return Scaffold(
      appBar: const TopBackAppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 34, 24, 22),
          children: [
            const SizedBox(height: 30),
            Center(
              child: Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Icon(
                Icons.image_outlined,
                size: 120,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 58),
            Center(
              child: RatingStarsRow(
                rating: _rating,
                onSelected: (value) => setState(() => _rating = value),
              ),
            ),
            const SizedBox(height: 56),
            const Text('Comment Text Area', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 10),
            TextField(
              controller: _commentController,
              maxLines: 3,
              style: const TextStyle(fontSize: 34),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 80),
            Center(
              child: SecondaryPillButton(
                text: widget.submitLabel,
                onTap: _submit,
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
    return Scaffold(
      appBar: const TopBackAppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 34, 24, 22),
          children: [
            const SizedBox(height: 30),
            const Center(
              child: Text(
                'Your Lens / Your Optician',
                style: TextStyle(fontSize: 38, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 24),
            const Center(
              child: Icon(
                Icons.image_outlined,
                size: 120,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 58),
            Center(
              child: RatingStarsRow(
                rating: _rating,
                onSelected: (value) => setState(() => _rating = value),
              ),
            ),
            const SizedBox(height: 56),
            const Text('Comment Text Area', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 10),
            TextField(
              controller: _commentController,
              maxLines: 3,
              style: const TextStyle(fontSize: 34),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 80),
            Center(
              child: SecondaryPillButton(text: 'Update', onTap: _update),
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

/// Profile overview screen under the Profile tab.
class ProfileOverviewScreen extends StatelessWidget {
  const ProfileOverviewScreen({
    super.key,
    required this.name,
    required this.email,
    required this.selectedOptician,
    required this.onNotificationSettings,
    required this.onPrivacy,
  });

  final String name;
  final String email;
  final String selectedOptician;
  final Future<void> Function() onNotificationSettings;
  final Future<void> Function() onPrivacy;

  @override
  Widget build(BuildContext context) {
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
  final Future<void> Function() onWithdrawConsent;

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
    await widget.onWithdrawConsent();
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
