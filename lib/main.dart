import 'package:flutter/material.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lens App',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF6F6F7),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6B57B6)),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

enum AuthView { login, register, gdprConsent, reset }

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  AuthView _view = AuthView.login;
  bool _loggedIn = false;

  String _name = 'Demo User';
  String _email = 'demo@mail.com';
  String _password = 'password123';
  String? _pendingName;
  String? _pendingEmail;
  String? _pendingPassword;

  void _go(AuthView view) => setState(() => _view = view);

  void _beginRegistration(String name, String email, String password) {
    setState(() {
      _pendingName = name.trim();
      _pendingEmail = email.trim();
      _pendingPassword = password;
      _view = AuthView.gdprConsent;
    });
  }

  void _confirmRegistrationWithConsent() {
    if (_pendingName == null || _pendingEmail == null || _pendingPassword == null) {
      setState(() => _view = AuthView.register);
      return;
    }

    setState(() {
      _name = _pendingName!;
      _email = _pendingEmail!;
      _password = _pendingPassword!;
      _pendingName = null;
      _pendingEmail = null;
      _pendingPassword = null;
      _view = AuthView.login;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account created. Please login.')),
    );
  }

  void _login(String email, String password) {
    final valid =
        email.trim().toLowerCase() == _email.toLowerCase() && password == _password;

    if (!valid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid email or password.')),
      );
      return;
    }

    setState(() => _loggedIn = true);
  }

  void _resetPassword(String email) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reset link sent to ${email.trim()}')),
    );
  }

  void _logout() {
    setState(() {
      _loggedIn = false;
      _view = AuthView.login;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loggedIn) {
      return LensCoreShell(
        userName: _name,
        userEmail: _email,
        onLogout: _logout,
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: SingleChildScrollView(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: switch (_view) {
                    AuthView.login => LoginView(
                      key: const ValueKey('login'),
                      onLogin: _login,
                      onForgot: () => _go(AuthView.reset),
                      onCreate: () => _go(AuthView.register),
                    ),
                    AuthView.register => RegisterView(
                      key: const ValueKey('register'),
                      onRegister: _beginRegistration,
                      onBack: () => _go(AuthView.login),
                    ),
                    AuthView.gdprConsent => GdprConsentView(
                      key: const ValueKey('gdpr'),
                      onAccept: _confirmRegistrationWithConsent,
                      onBack: () => _go(AuthView.register),
                    ),
                    AuthView.reset => ResetView(
                      key: const ValueKey('reset'),
                      onSend: _resetPassword,
                      onBack: () => _go(AuthView.login),
                    ),
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginView extends StatefulWidget {
  const LoginView({
    super.key,
    required this.onLogin,
    required this.onForgot,
    required this.onCreate,
  });

  final void Function(String email, String password) onLogin;
  final VoidCallback onForgot;
  final VoidCallback onCreate;

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 42),
          const Text(
            'LOGO',
            style: TextStyle(fontSize: 72, height: 1.0, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text('Brand', style: TextStyle(fontSize: 46, color: Colors.black45)),
          const SizedBox(height: 88),
          FormInput(
            label: 'E-Mail',
            hint: 'Input',
            controller: _email,
            validator: validateEmail,
          ),
          const SizedBox(height: 14),
          FormInput(
            label: 'Password',
            hint: '******',
            controller: _password,
            obscure: true,
            validator: validatePassword,
          ),
          const SizedBox(height: 28),
          Center(
            child: PrimaryPillButton(
              text: 'Login',
              onTap: () {
                if (_form.currentState!.validate()) {
                  widget.onLogin(_email.text, _password.text);
                }
              },
            ),
          ),
          const SizedBox(height: 30),
          Center(
            child: TextButton(
              onPressed: widget.onForgot,
              child: const Text(
                'Forgot password?',
                style: TextStyle(
                  color: Colors.black87,
                  decoration: TextDecoration.underline,
                  fontSize: 30,
                ),
              ),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: widget.onCreate,
              child: const Text(
                'Create Account',
                style: TextStyle(
                  color: Colors.black87,
                  decoration: TextDecoration.underline,
                  fontSize: 30,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RegisterView extends StatefulWidget {
  const RegisterView({
    super.key,
    required this.onRegister,
    required this.onBack,
  });

  final void Function(String name, String email, String password) onRegister;
  final VoidCallback onBack;

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 82),
          FormInput(
            label: 'Name',
            hint: 'Name',
            controller: _name,
            validator: (value) {
              if ((value ?? '').trim().isEmpty) return 'Enter your name';
              return null;
            },
          ),
          const SizedBox(height: 14),
          FormInput(
            label: 'E-Mail',
            hint: 'Input',
            controller: _email,
            validator: validateEmail,
          ),
          const SizedBox(height: 14),
          FormInput(
            label: 'Password',
            hint: '******',
            controller: _password,
            obscure: true,
            validator: validatePassword,
          ),
          const SizedBox(height: 120),
          Center(
            child: SecondaryPillButton(
              text: 'Continue',
              onTap: () {
                if (!_form.currentState!.validate()) return;
                widget.onRegister(_name.text, _email.text, _password.text);
              },
            ),
          ),
          Center(
            child: TextButton(
              onPressed: widget.onBack,
              child: const Text('Back to login'),
            ),
          ),
        ],
      ),
    );
  }
}

class GdprConsentView extends StatelessWidget {
  const GdprConsentView({
    super.key,
    required this.onAccept,
    required this.onBack,
  });

  final VoidCallback onAccept;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 72),
        const Text(
          'GDPR Consent',
          style: TextStyle(fontSize: 44, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFEEE8F2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text(
            'By continuing, you agree that your data is processed to provide app functionality.\n\n'
            'Stored data includes registered lenses, ratings, and selected optician preferences.',
            style: TextStyle(fontSize: 15, height: 1.4),
          ),
        ),
        const SizedBox(height: 30),
        Center(
          child: PrimaryPillButton(
            text: 'I agree',
            onTap: onAccept,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: onBack,
            child: const Text('Back to registration'),
          ),
        ),
      ],
    );
  }
}

class ResetView extends StatefulWidget {
  const ResetView({
    super.key,
    required this.onSend,
    required this.onBack,
  });

  final void Function(String email) onSend;
  final VoidCallback onBack;

  @override
  State<ResetView> createState() => _ResetViewState();
}

class _ResetViewState extends State<ResetView> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 140),
          FormInput(
            label: 'E-Mail',
            hint: 'Input',
            controller: _email,
            validator: validateEmail,
          ),
          const SizedBox(height: 42),
          Center(
            child: SecondaryPillButton(
              text: 'Send reset link',
              onTap: () {
                if (_form.currentState!.validate()) {
                  widget.onSend(_email.text);
                }
              },
            ),
          ),
          const SizedBox(height: 120),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEEE8F2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Info Text', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
                SizedBox(height: 4),
                Text(
                  'Supporting line text lorem ipsum dolor sit amet, consectetur.',
                  style: TextStyle(fontSize: 14, height: 1.35),
                ),
              ],
            ),
          ),
          Center(
            child: TextButton(onPressed: widget.onBack, child: const Text('Back to login')),
          ),
        ],
      ),
    );
  }
}

class LensCoreShell extends StatefulWidget {
  const LensCoreShell({
    super.key,
    required this.userName,
    required this.userEmail,
    required this.onLogout,
  });

  final String userName;
  final String userEmail;
  final VoidCallback onLogout;

  @override
  State<LensCoreShell> createState() => _LensCoreShellState();
}

class _LensCoreShellState extends State<LensCoreShell> {
  int _index = 0;
  RatingData? _lensRating;
  RatingData? _opticianRating;
  final List<LensItem> _lenses = [
    LensItem(name: 'Lens Name', purchaseDate: '2024-02-16', optician: 'Optician A'),
    LensItem(name: 'Lens Name', purchaseDate: '2024-06-04', optician: 'Optician B'),
  ];

  void _addLens(String serial, String optician) {
    setState(() {
      _lenses.insert(
        0,
        LensItem(
          name: serial.isEmpty ? 'Lens Name' : serial,
          purchaseDate: '2026-02-10',
          optician: optician.isEmpty ? 'Unknown' : optician,
        ),
      );
      _index = 1;
    });
  }

  void _selectTab(int index) {
    setState(() => _index = index);
  }

  void _navigateFromOverlay(int index) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    if (!mounted) return;
    setState(() => _index = index);
  }

  Future<void> _openRegisterLens() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RegisterLensScreen(
          onRegisterLens: _addLens,
          onTabSelected: _navigateFromOverlay,
        ),
      ),
    );
  }

  void _openPassport(LensItem lens) {
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

  Future<void> _openRateLens(LensItem lens) async {
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

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardScreen(
        onGoRegister: _openRegisterLens,
        onGoLenses: () => setState(() => _index = 1),
        onRate: _openRateOptician,
        onLogout: widget.onLogout,
      ),
      LensesListScreen(lenses: _lenses, onOpenDetails: _openPassport),
      ProfileOverviewScreen(
        name: widget.userName,
        email: widget.userEmail,
        selectedOptician: _lenses.isEmpty ? 'No optician selected' : _lenses.first.optician,
        onNotificationSettings: _openNotificationSettings,
        onPrivacy: _openPrivacyDataProtection,
        onTabSelected: _selectTab,
      ),
    ];

    return Scaffold(
      body: SafeArea(child: pages[_index]),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: _index,
        onSelected: _selectTab,
      ),
    );
  }

  Future<void> _openNotificationSettings() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationSettingsScreen(onTabSelected: _navigateFromOverlay),
      ),
    );
  }

  Future<void> _openPrivacyDataProtection() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PrivacyDataProtectionScreen(
          onTabSelected: _navigateFromOverlay,
          onWithdrawConsent: _withdrawConsentAndLogout,
        ),
      ),
    );
  }

  void _withdrawConsentAndLogout() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    widget.onLogout();
  }
}

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
  final VoidCallback onLogout;

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
          TextButton(onPressed: onLogout, child: const Text('Logout')),
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
            BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1)),
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
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
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

  @override
  void dispose() {
    _serial.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Lens Registration'),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(28, 30, 28, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FormInput(
              label: 'Number',
              hint: 'Serial Number',
              controller: _serial,
            ),
            const SizedBox(height: 24),
            SecondaryPillButton(text: 'scan QR code', onTap: () {}),
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
                    DropdownMenuItem(value: 'Optician A', child: Text('Optician A')),
                    DropdownMenuItem(value: 'Optician B', child: Text('Optician B')),
                    DropdownMenuItem(value: 'Optician C', child: Text('Optician C')),
                  ],
                  onChanged: (value) => setState(() => _selectedOptician = value),
                ),
              ],
            ),
            const Spacer(),
            Center(
              child: SecondaryPillButton(
                text: 'Register Lens',
                onTap: () {
                  widget.onRegisterLens(_serial.text.trim(), _selectedOptician ?? '');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lens registered successfully.')),
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
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 8),
              const Center(child: Icon(Icons.person_2_outlined, size: 48, color: Color(0xFFB8A5E2))),
              const SizedBox(height: 10),
              const Text('Lens Info', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Lens Name: ${lens.name}', style: const TextStyle(fontSize: 16, color: Colors.black54)),
              Text('Purchase Date: ${lens.purchaseDate}', style: const TextStyle(fontSize: 16, color: Colors.black54)),
              Text('Optician: ${lens.optician}', style: const TextStyle(fontSize: 16, color: Colors.black54)),
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
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              const Center(child: Icon(Icons.person_2_outlined, size: 52, color: Color(0xFFD2C2F4))),
              const SizedBox(height: 16),
              _passportLine('Lens Type', 'Single Vision'),
              _passportLine('Coating', 'Blue Light Filter'),
              _passportLine('Diopter Values', '-1.50 / -1.25'),
              _passportLine('Purchase Location', lens.optician),
              _passportLine('Purchase Date', lens.purchaseDate),
              const Spacer(),
              Center(
                child: PrimaryPillButton(text: 'Rate this Lens', onTap: onRateLens),
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
            TextSpan(text: '$label: ', style: const TextStyle(color: Colors.white70)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

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

class _RateLensScreenState extends State<RateLensScreen> {
  late final TextEditingController _commentController;
  int _rating = 0;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating?.stars ?? 0;
    _commentController = TextEditingController(text: widget.initialRating?.comment ?? 'Lorem');
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submit() {
    final data = RatingData(
      stars: _rating == 0 ? 5 : _rating,
      comment: _commentController.text.trim().isEmpty ? 'Lorem' : _commentController.text.trim(),
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
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 34, 24, 22),
          children: [
            const SizedBox(height: 30),
            Center(
              child: Text(
                widget.title,
                style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(height: 24),
            const Center(child: Icon(Icons.image_outlined, size: 120, color: Colors.black87)),
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
              child: SecondaryPillButton(text: widget.submitLabel, onTap: _submit),
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

class _EditRatingScreenState extends State<EditRatingScreen> {
  late final TextEditingController _commentController;
  late int _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating.stars;
    _commentController = TextEditingController(text: widget.initialRating.comment);
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
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
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
            const Center(child: Icon(Icons.image_outlined, size: 120, color: Colors.black87)),
            const SizedBox(height: 58),
            Center(
              child: RatingStarsRow(
                rating: _rating,
                onSelected: (value) => setState(() => _rating = value),
                selectedFill: const Color(0xFFD7CCEF),
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

class ProfileOverviewScreen extends StatelessWidget {
  const ProfileOverviewScreen({
    super.key,
    required this.name,
    required this.email,
    required this.selectedOptician,
    required this.onNotificationSettings,
    required this.onPrivacy,
    required this.onTabSelected,
  });

  final String name;
  final String email;
  final String selectedOptician;
  final Future<void> Function() onNotificationSettings;
  final Future<void> Function() onPrivacy;
  final ValueChanged<int> onTabSelected;

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
                  const SnackBar(content: Text('Edit profile flow not implemented yet.')),
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
                  const SnackBar(content: Text('Change optician flow not implemented yet.')),
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

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key, required this.onTabSelected});

  final ValueChanged<int> onTabSelected;

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _ratingReminders = true;
  bool _serviceNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Notification Settings'),
      ),
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
              onChanged: (value) => setState(() => _serviceNotifications = value),
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

class PrivacyDataProtectionScreen extends StatefulWidget {
  const PrivacyDataProtectionScreen({
    super.key,
    required this.onTabSelected,
    required this.onWithdrawConsent,
  });

  final ValueChanged<int> onTabSelected;
  final VoidCallback onWithdrawConsent;

  @override
  State<PrivacyDataProtectionScreen> createState() => _PrivacyDataProtectionScreenState();
}

class _PrivacyDataProtectionScreenState extends State<PrivacyDataProtectionScreen> {
  bool _consentGranted = true;

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

    if (confirmed != true) {
      return;
    }

    setState(() => _consentGranted = false);
    widget.onWithdrawConsent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Privacy & Data Protection'),
      ),
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
                    style: TextStyle(fontSize: 15, height: 1.4, fontWeight: FontWeight.w600),
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
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14, color: Colors.black54)),
        ],
      ),
    );
  }
}

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
                color: selected ? selectedFill : Colors.white,
                borderRadius: BorderRadius.circular(19),
                border: Border.all(color: const Color(0xFFC6C0CF)),
              ),
              child: Icon(
                Icons.stars_rounded,
                size: 20,
                color: selected ? const Color(0xFF4E3B8E) : const Color(0xFF5C596B),
              ),
            ),
          ),
        );
      }),
    );
  }
}

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
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      backgroundColor: const Color(0xFFEDE8F1),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.stars_outlined),
          selectedIcon: Icon(Icons.stars),
          label: 'Lenses',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}

class RatingData {
  const RatingData({
    required this.stars,
    required this.comment,
  });

  final int stars;
  final String comment;
}

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
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(fontSize: 20),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: const Color(0xFFE8E3EC),
        labelStyle: const TextStyle(fontSize: 14, color: Colors.black54),
        hintStyle: const TextStyle(fontSize: 24, color: Colors.black87),
        suffixIcon: IconButton(
          onPressed: controller.clear,
          icon: const Icon(Icons.cancel_outlined, color: Colors.black54),
        ),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black38),
        ),
      ),
    );
  }
}

class PrimaryPillButton extends StatelessWidget {
  const PrimaryPillButton({
    super.key,
    required this.text,
    required this.onTap,
  });

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.stars_rounded, size: 16),
      label: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF6B57B6),
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
      ),
    );
  }
}

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
    return FilledButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.stars_rounded, size: 16),
      label: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFE9E4EF),
        foregroundColor: const Color(0xFF6B57B6),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
    );
  }
}

String? validateEmail(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return 'Enter your email';
  if (!text.contains('@') || !text.contains('.')) return 'Enter a valid email';
  return null;
}

String? validatePassword(String? value) {
  final text = value ?? '';
  if (text.isEmpty) return 'Enter your password';
  if (text.length < 6) return 'Minimum 6 characters';
  return null;
}
