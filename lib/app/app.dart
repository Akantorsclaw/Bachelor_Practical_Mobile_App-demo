import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';

import '../branding/brand.dart';
import '../branding/brand_theme_extension.dart';
import '../auth/auth_flow.dart';
import '../core/lens_core_shell.dart';
import 'session_controller.dart';

/// Root widget that switches between auth flow and core app shell.
///
/// The switch is driven by [SessionController.isLoggedIn].
class LensApp extends StatelessWidget {
  const LensApp({super.key, required this.controller});

  final SessionController controller;

  @override
  Widget build(BuildContext context) {
    return _StartupGate(controller: controller);
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate({required this.controller});

  final SessionController controller;

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate>
    with WidgetsBindingObserver {
  bool _showStartup = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _showStartup = false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      unawaited(widget.controller.signOutSilently());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.controller, AppBrand.flavorNotifier]),
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppBrand.current.appName,
          theme: ThemeData(
            scaffoldBackgroundColor:
                AppBrand.current.palette.scaffoldBackground,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppBrand.current.palette.primary,
            ),
            extensions: [
              BrandThemeExtension(palette: AppBrand.current.palette),
            ],
            useMaterial3: true,
          ),
          home: _showStartup
              ? const _StartupScreen()
              : (widget.controller.isLoggedIn
                    ? LensCoreShell(controller: widget.controller)
                    : AuthFlow(controller: widget.controller)),
        );
      },
    );
  }
}

enum _StartupLogoAsset { svg, png, none }

class _StartupScreen extends StatefulWidget {
  const _StartupScreen();

  @override
  State<_StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<_StartupScreen> {
  Future<_StartupLogoAsset> _resolveAsset() async {
    try {
      await rootBundle.load(AppBrand.current.assets.authLogoSvg);
      return _StartupLogoAsset.svg;
    } catch (_) {}

    try {
      await rootBundle.load(AppBrand.current.assets.authLogoPng);
      return _StartupLogoAsset.png;
    } catch (_) {}

    return _StartupLogoAsset.none;
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<BrandThemeExtension>()!.palette;
    return Scaffold(
      body: Center(
        child: FutureBuilder<_StartupLogoAsset>(
          future: _resolveAsset(),
          builder: (context, snapshot) {
            final choice = snapshot.data;
            if (choice == _StartupLogoAsset.svg) {
              return SvgPicture.asset(
                AppBrand.current.assets.authLogoSvg,
                height: 88,
                fit: BoxFit.contain,
              );
            }
            if (choice == _StartupLogoAsset.png) {
              return Image.asset(
                AppBrand.current.assets.authLogoPng,
                height: 88,
                fit: BoxFit.contain,
              );
            }
            return Text(
              AppBrand.current.appName,
              style: TextStyle(
                color: palette.primary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            );
          },
        ),
      ),
    );
  }
}
