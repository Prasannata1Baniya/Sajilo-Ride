import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:sajilo_ride/auth/auth_provider.dart';
import 'package:sajilo_ride/screens/onboarding_page.dart';
import 'package:sajilo_ride/utils/notification_service.dart';
import 'package:sajilo_ride/widgets/app_shell.dart';
import 'navbar/navbar_config.dart';
import 'firebase_options.dart';
import 'screens/admin_web/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  try {
    await dotenv.load(fileName: ".env");
    debugPrint("DOTENV LOADED SUCCESSFULLY");
  } catch (e) {
    debugPrint("CRITICAL ERROR: Could not load .env file: $e");
  }

  if (!kIsWeb) {
    try {
      await NotificationService.initialize();
    } catch (e) {
      debugPrint("Notification Service failed to init: $e");
    }
  }
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Sajilo Ride Admin Panel',
        home: AdminDashboardPage(),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => AuthProviderMethod(),
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Sajilo Ride',
        home: AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProviderMethod>(
      builder: (context, authProvider, child) {
        if (authProvider.user == null) {
          return const OnBoardingPage();
        } else {
          return const RoleWrapper();
        }
      },
    );
  }
}

class RoleWrapper extends StatelessWidget {
  const RoleWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Error: User not logged in.")),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text("Error: ${snapshot.error}")),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.read<AuthProviderMethod>().signOut();
            }
          });

          return const Scaffold(
            body: Center(child: Text("User data not found. Please log in again.")),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final String roleString = data['role'] ?? 'passenger';

        UserRole currentUserRole;
        if (roleString == 'driver') {
          currentUserRole = UserRole.driver;
        } else {
          currentUserRole = UserRole.passenger;
        }
        NotificationService.saveTokenAfterLogin();

        return AppShell(userRole: currentUserRole);
      },
    );
  }
}
