import 'package:flutter/material.dart';

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
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Lens App',
          theme: ThemeData(
            scaffoldBackgroundColor: const Color(0xFFF6F6F7),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6B57B6),
            ),
            useMaterial3: true,
          ),
          home: controller.isLoggedIn
              ? LensCoreShell(controller: controller)
              : AuthFlow(controller: controller),
        );
      },
    );
  }
}
