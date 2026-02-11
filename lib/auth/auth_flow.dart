import 'package:flutter/material.dart';

import '../app/session_controller.dart';
import '../shared/app_widgets.dart';
import '../shared/validators.dart';

/// Container for all unauthenticated screens.
class AuthFlow extends StatefulWidget {
  const AuthFlow({super.key, required this.controller});

  final SessionController controller;

  @override
  State<AuthFlow> createState() => _AuthFlowState();
}

/// State holder for auth flow view switching and async handlers.
class _AuthFlowState extends State<AuthFlow> {
  SessionController get _controller => widget.controller;
  bool _isTransitioning = false;

  Future<void> _transitionTo(AuthView view) async {
    setState(() => _isTransitioning = true);
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    _controller.goToAuthView(view);
    setState(() => _isTransitioning = false);
  }

  /// Builds auth subview based on [SessionController.authView].
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: switch (_controller.authView) {
                        AuthView.login => LoginView(
                          key: const ValueKey('login'),
                          onLogin: _handleLogin,
                          onForgot: () => _transitionTo(AuthView.reset),
                          onCreate: () => _transitionTo(AuthView.register),
                        ),
                        AuthView.register => RegisterView(
                          key: const ValueKey('register'),
                          onRegister: _handleBeginRegistration,
                          onBack: () => _transitionTo(AuthView.login),
                        ),
                        AuthView.gdprConsent => GdprConsentView(
                          key: const ValueKey('gdpr'),
                          onAccept: _handleGdprAccept,
                          onBack: () => _transitionTo(AuthView.register),
                        ),
                        AuthView.reset => ResetView(
                          key: const ValueKey('reset'),
                          onSend: _handleResetPassword,
                          onBack: () => _transitionTo(AuthView.login),
                        ),
                      },
                    ),
                  ),
                  if (_controller.busy || _isTransitioning)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Color(0x88000000),
                        child: Center(child: CircularProgressIndicator()),
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

  /// Attempts login and shows any resulting user-facing error.
  Future<void> _handleLogin(String email, String password) async {
    final error = await _controller.signIn(email: email, password: password);
    if (!mounted) return;
    if (error != null) {
      _showSnack(error);
    }
  }

  /// Starts registration flow and advances to GDPR screen on success.
  Future<void> _handleBeginRegistration(
    String name,
    String email,
    String password,
  ) async {
    final error = await _controller.beginRegistration(
      name: name,
      email: email,
      password: password,
    );
    if (!mounted) return;
    if (error != null) {
      _showSnack(error);
    }
  }

  /// Finalizes registration after GDPR consent.
  Future<void> _handleGdprAccept() async {
    final error = await _controller.completeRegistrationWithConsent();
    if (!mounted) return;
    if (error != null) {
      _showSnack(error);
      return;
    }
    _showSnack('Account created. Please login.');
  }

  /// Sends reset-password email for the entered email address.
  Future<void> _handleResetPassword(String email) async {
    final error = await _controller.sendPasswordReset(email);
    if (!mounted) return;
    if (error != null) {
      _showSnack(error);
      return;
    }
    _showSnack('Password reset link sent to ${email.trim()}');
  }

  /// Shared snackbar helper for auth flows.
  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

/// Login screen (email + password).
class LoginView extends StatefulWidget {
  const LoginView({
    super.key,
    required this.onLogin,
    required this.onForgot,
    required this.onCreate,
  });

  final Future<void> Function(String email, String password) onLogin;
  final VoidCallback onForgot;
  final VoidCallback onCreate;

  @override
  State<LoginView> createState() => _LoginViewState();
}

/// State for login form validation and submit behavior.
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
            style: TextStyle(
              fontSize: 72,
              height: 1.0,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Brand',
            style: TextStyle(fontSize: 46, color: Colors.black45),
          ),
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

/// Registration screen (name + email + password).
class RegisterView extends StatefulWidget {
  const RegisterView({
    super.key,
    required this.onRegister,
    required this.onBack,
  });

  final Future<void> Function(String name, String email, String password)
  onRegister;
  final VoidCallback onBack;

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

/// State for registration form validation and transition handling.
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

/// GDPR consent screen shown between register and login.
class GdprConsentView extends StatelessWidget {
  const GdprConsentView({
    super.key,
    required this.onAccept,
    required this.onBack,
  });

  final Future<void> Function() onAccept;
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
          child: PrimaryPillButton(text: 'I agree', onTap: onAccept),
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

/// Password reset screen.
class ResetView extends StatefulWidget {
  const ResetView({super.key, required this.onSend, required this.onBack});

  final Future<void> Function(String email) onSend;
  final VoidCallback onBack;

  @override
  State<ResetView> createState() => _ResetViewState();
}

/// State class for the password reset screen.
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
                Text(
                  'Info Text',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 4),
                Text(
                  'Supporting line text lorem ipsum dolor sit amet, consectetur.',
                  style: TextStyle(fontSize: 14, height: 1.35),
                ),
              ],
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
