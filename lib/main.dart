import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/session_controller.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/user_profile_service.dart';

/// Entry point for the iOS-first Flutter application.
///
/// Initializes Firebase and wires the app-level session controller.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with explicit options.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final controller = SessionController(
    authService: AuthService(FirebaseAuth.instance),
    userProfileService: UserProfileService(FirebaseFirestore.instance),
  );

  runApp(LensApp(controller: controller));
}
