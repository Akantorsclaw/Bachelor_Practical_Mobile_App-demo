import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/session_controller.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/user_profile_service.dart';

/// Entry point for the mobile Flutter application.
///
/// Initializes Firebase and wires the app-level session controller.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isAndroid) {
    // Android reads config from android/app/google-services.json.
    await Firebase.initializeApp();
  } else {
    // iOS remains explicitly initialized from firebase_options.dart.
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Product requirement: never persist a logged-in session across app restarts.
  await FirebaseAuth.instance.signOut();

  final controller = SessionController(
    authService: AuthService(FirebaseAuth.instance),
    userProfileService: UserProfileService(FirebaseFirestore.instance),
  );

  runApp(LensApp(controller: controller));
}
