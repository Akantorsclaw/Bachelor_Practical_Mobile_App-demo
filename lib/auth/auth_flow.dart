import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

import '../app/session_controller.dart';
import '../branding/brand.dart';
import '../branding/brand_context.dart';
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

  Future<void> _transitionTo(AuthView view) async {
    _controller.goToAuthView(view);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _responsiveHorizontalPadding(context),
            vertical: _responsiveVerticalPadding(context),
          ),
          child: Stack(
            children: [
              AnimatedSwitcher(
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
              if (_controller.busy)
                Positioned.fill(
                  child: ColoredBox(
                    color: palette.scaffoldBackground.withValues(alpha: 0.9),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin(String email, String password) async {
    final error = await _controller.signIn(email: email, password: password);
    if (!mounted) return;
    if (error != null) {
      _showSnack(error);
    }
  }

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

  Future<void> _handleGdprAccept() async {
    final error = await _controller.completeRegistrationWithConsent();
    if (!mounted) return;
    if (error != null) {
      _showSnack(error);
      return;
    }
    _showSnack('Account created. Please login.');
  }

  Future<void> _handleResetPassword(String email) async {
    final error = await _controller.sendPasswordReset(email);
    if (!mounted) return;
    if (error != null) {
      _showSnack(error);
      return;
    }
    _showSnack('Password reset link sent to ${email.trim()}');
  }

  void _showSnack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

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
    return _AuthViewport(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: _vh(context, 0.08, min: 28, max: 64)),
            Center(
              child: _BrandWordmark(
                height: _vh(context, 0.085, min: 56, max: 92),
              ),
            ),
            SizedBox(height: _vh(context, 0.09, min: 36, max: 88)),
            _AuthField(
              label: 'MAIL',
              hint: 'Input',
              controller: _email,
              validator: validateEmail,
            ),
            SizedBox(height: _vh(context, 0.022, min: 12, max: 24)),
            _AuthField(
              label: 'PASSWORD',
              hint: '••••••••',
              controller: _password,
              obscure: true,
              validator: validatePassword,
            ),
            SizedBox(height: _vh(context, 0.08, min: 28, max: 72)),
            _AuthPrimaryButton(
              text: 'Login',
              onTap: () {
                if (_form.currentState!.validate()) {
                  widget.onLogin(_email.text, _password.text);
                }
              },
            ),
            SizedBox(height: _vh(context, 0.032, min: 16, max: 30)),
            _AuthTextLink(text: 'Forgot password?', onTap: widget.onForgot),
            SizedBox(height: _vh(context, 0.004, min: 2, max: 6)),
            _AuthTextLink(text: 'Create Account', onTap: widget.onCreate),
            SizedBox(height: _vh(context, 0.04, min: 18, max: 34)),
          ],
        ),
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

  final Future<void> Function(String name, String email, String password)
  onRegister;
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
    return _AuthViewport(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AuthTitle(title: 'Registration'),
            SizedBox(height: _vh(context, 0.036, min: 16, max: 34)),
            _AuthField(
              label: 'NAME',
              hint: 'Input',
              controller: _name,
              validator: (value) {
                if ((value ?? '').trim().isEmpty) return 'Enter your name';
                return null;
              },
            ),
            SizedBox(height: _vh(context, 0.018, min: 10, max: 18)),
            _AuthField(
              label: 'E-MAIL',
              hint: 'Input',
              controller: _email,
              validator: validateEmail,
            ),
            SizedBox(height: _vh(context, 0.018, min: 10, max: 18)),
            _AuthField(
              label: 'PASSWORD',
              hint: '••••••••',
              controller: _password,
              obscure: true,
              validator: validatePassword,
            ),
            SizedBox(height: _vh(context, 0.04, min: 18, max: 36)),
            _AuthPrimaryButton(
              text: 'Create account',
              onTap: () {
                if (!_form.currentState!.validate()) return;
                widget.onRegister(_name.text, _email.text, _password.text);
              },
            ),
            SizedBox(height: _vh(context, 0.014, min: 8, max: 14)),
            _AuthTextLink(text: 'Back to Login', onTap: widget.onBack),
            SizedBox(height: _vh(context, 0.03, min: 14, max: 24)),
          ],
        ),
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

  final Future<void> Function() onAccept;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return _AuthViewport(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AuthTitle(title: 'Registration'),
          SizedBox(height: _vh(context, 0.03, min: 14, max: 28)),
          Text(
            'Data Processing Consent (GDPR)',
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: _responsiveFont(context, 26, min: 22, max: 30),
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: _vh(context, 0.018, min: 10, max: 18)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(_vw(context, 0.045, min: 14, max: 22)),
            decoration: BoxDecoration(
              color: palette.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'By continuing, you agree that your data is processed to provide app functionality.\n\n'
              'Stored data includes registered lenses, ratings, and selected optician preferences.',
              style: TextStyle(
                fontSize: _responsiveFont(context, 15, min: 14, max: 17),
                height: 1.4,
                color: palette.textSecondary,
              ),
            ),
          ),
          SizedBox(height: _vh(context, 0.05, min: 20, max: 46)),
          _AuthPrimaryButton(text: 'Create account', onTap: onAccept),
          SizedBox(height: _vh(context, 0.014, min: 8, max: 14)),
          _AuthTextLink(text: 'Back to Login', onTap: onBack),
        ],
      ),
    );
  }
}

class ResetView extends StatefulWidget {
  const ResetView({super.key, required this.onSend, required this.onBack});

  final Future<void> Function(String email) onSend;
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
    final palette = context.brandPalette;
    return _AuthViewport(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AuthTitle(title: 'Password Reset'),
            SizedBox(height: _vh(context, 0.04, min: 18, max: 34)),
            _AuthField(
              label: 'E-MAIL',
              hint: 'Input',
              controller: _email,
              validator: validateEmail,
            ),
            SizedBox(height: _vh(context, 0.035, min: 18, max: 34)),
            _AuthPrimaryButton(
              text: 'Send reset link',
              icon: Icons.access_time_outlined,
              onTap: () {
                if (_form.currentState!.validate()) {
                  widget.onSend(_email.text);
                }
              },
            ),
            SizedBox(height: _vh(context, 0.04, min: 18, max: 36)),
            Divider(color: palette.border),
            SizedBox(height: _vh(context, 0.03, min: 14, max: 26)),
            Text(
              'Info Text',
              style: TextStyle(
                fontSize: _responsiveFont(context, 30, min: 24, max: 34),
                fontWeight: FontWeight.w600,
                color: palette.textPrimary,
              ),
            ),
            SizedBox(height: _vh(context, 0.01, min: 4, max: 10)),
            Text(
              'Supporting line text lorem ipsum dolor sit amet, consectetur.',
              style: TextStyle(
                fontSize: _responsiveFont(context, 15, min: 14, max: 16),
                height: 1.35,
                color: palette.textSecondary,
              ),
            ),
            SizedBox(height: _vh(context, 0.03, min: 14, max: 24)),
            _AuthTextLink(text: 'Back to Login', onTap: widget.onBack),
          ],
        ),
      ),
    );
  }
}

class _AuthViewport extends StatelessWidget {
  const _AuthViewport({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        );
      },
    );
  }
}

class _AuthTitle extends StatelessWidget {
  const _AuthTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Text(
      title,
      textAlign: TextAlign.left,
      style: TextStyle(
        fontSize: _responsiveFont(context, 42, min: 34, max: 48),
        fontWeight: FontWeight.w700,
        color: palette.textPrimary,
      ),
    );
  }
}

enum _BrandLogoAsset { svg, png, none }

class _BrandWordmark extends StatefulWidget {
  const _BrandWordmark({required this.height});

  final double height;

  @override
  State<_BrandWordmark> createState() => _BrandWordmarkState();
}

class _BrandWordmarkState extends State<_BrandWordmark> {
  Future<_BrandLogoAsset> _resolveAsset() async {
    final svgPath = AppBrand.current.assets.authLogoSvg;
    final pngPath = AppBrand.current.assets.authLogoPng;

    try {
      await rootBundle.load(svgPath);
      return _BrandLogoAsset.svg;
    } catch (_) {}

    try {
      await rootBundle.load(pngPath);
      return _BrandLogoAsset.png;
    } catch (_) {}

    return _BrandLogoAsset.none;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BrandLogoAsset>(
      future: _resolveAsset(),
      builder: (context, snapshot) {
        final choice = snapshot.data;
        if (choice == _BrandLogoAsset.svg) {
          return SvgPicture.asset(
            AppBrand.current.assets.authLogoSvg,
            height: widget.height,
            fit: BoxFit.contain,
          );
        }
        if (choice == _BrandLogoAsset.png) {
          return Image.asset(
            AppBrand.current.assets.authLogoPng,
            height: widget.height,
            fit: BoxFit.contain,
          );
        }
        return Text(
          AppBrand.current.appName,
          style: TextStyle(
            fontSize: _responsiveFont(context, 24, min: 20, max: 28),
            fontWeight: FontWeight.w800,
            color: context.brandPalette.primary,
          ),
        );
      },
    );
  }
}

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.label,
    required this.hint,
    required this.controller,
    this.validator,
    this.obscure = false,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: _responsiveFont(context, 14, min: 13, max: 16),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: palette.textSecondary,
          ),
        ),
        SizedBox(height: _vh(context, 0.012, min: 8, max: 12)),
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: obscure,
          style: TextStyle(
            fontSize: _responsiveFont(context, 18, min: 16, max: 20),
            color: palette.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: _responsiveFont(context, 18, min: 16, max: 20),
              color: palette.textSecondary,
            ),
            filled: true,
            fillColor: palette.surfaceMuted,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _vw(context, 0.04, min: 14, max: 18),
              ),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _vw(context, 0.04, min: 14, max: 18),
              ),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                _vw(context, 0.04, min: 14, max: 18),
              ),
              borderSide: BorderSide(color: palette.primary, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: _vw(context, 0.05, min: 14, max: 18),
              vertical: _vh(context, 0.022, min: 12, max: 16),
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthPrimaryButton extends StatelessWidget {
  const _AuthPrimaryButton({
    required this.text,
    required this.onTap,
    this.icon,
  });

  final String text;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    final label = Text(
      text,
      style: TextStyle(
        fontSize: _responsiveFont(context, 19, min: 18, max: 21),
        fontWeight: FontWeight.w600,
      ),
    );

    final style = FilledButton.styleFrom(
      backgroundColor: palette.primary,
      foregroundColor: palette.onPrimary,
      shape: const StadiumBorder(),
      padding: EdgeInsets.symmetric(
        horizontal: _vw(context, 0.04, min: 12, max: 18),
        vertical: _vh(context, 0.022, min: 12, max: 16),
      ),
    );

    return SizedBox(
      width: double.infinity,
      child: icon == null
          ? FilledButton(onPressed: onTap, style: style, child: label)
          : FilledButton.icon(
              onPressed: onTap,
              style: style,
              icon: Icon(
                icon,
                size: _responsiveFont(context, 19, min: 18, max: 21),
              ),
              label: label,
            ),
    );
  }
}

class _AuthTextLink extends StatelessWidget {
  const _AuthTextLink({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.brandPalette;
    return Center(
      child: TextButton(
        onPressed: onTap,
        child: Text(
          text,
          style: TextStyle(
            color: palette.textPrimary,
            decoration: TextDecoration.underline,
            decorationColor: palette.textPrimary,
            fontSize: _responsiveFont(context, 15, min: 14, max: 18),
          ),
        ),
      ),
    );
  }
}

double _responsiveHorizontalPadding(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  return (width * 0.08).clamp(20, 40).toDouble();
}

double _responsiveVerticalPadding(BuildContext context) {
  final height = MediaQuery.sizeOf(context).height;
  return (height * 0.02).clamp(10, 20).toDouble();
}

double _vh(
  BuildContext context,
  double factor, {
  required double min,
  required double max,
}) {
  final height = MediaQuery.sizeOf(context).height;
  return (height * factor).clamp(min, max).toDouble();
}

double _vw(
  BuildContext context,
  double factor, {
  required double min,
  required double max,
}) {
  final width = MediaQuery.sizeOf(context).width;
  return (width * factor).clamp(min, max).toDouble();
}

double _responsiveFont(
  BuildContext context,
  double base, {
  required double min,
  required double max,
}) {
  final width = MediaQuery.sizeOf(context).width;
  final scaled = base * (width / 390);
  return scaled.clamp(min, max).toDouble();
}
