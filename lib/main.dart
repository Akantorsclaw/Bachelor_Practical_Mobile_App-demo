import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/session_controller.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/user_profile_service.dart';

/// Initializes Firebase and wires the app-level session controller.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (_) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Enforce logged-out startup behavior per project requirement.
  await FirebaseAuth.instance.signOut();

  final controller = SessionController(
    authService: AuthService(FirebaseAuth.instance),
    userProfileService: UserProfileService(FirebaseFirestore.instance),
  );

  runApp(LensApp(controller: controller));
}
