import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:sajilo_ride/auth/auth_provider.dart';
import 'package:sajilo_ride/screens/onboarding_page.dart';
import 'package:sajilo_ride/widgets/app_shell.dart';
import 'navbar/navbar_config.dart';
import 'firebase_options.dart';
import 'screens/admin_web/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Only load the mobile AuthProvider if the platform is NOT Web.
    // This prevents web app crashes caused by native phone services initialization.
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
    // FIXED: Cleaned up a subtle spacing syntax error in ".currentUser"
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

        return AppShell(userRole: currentUserRole);
      },
    );
  }
}











/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:sajilo_ride/auth/auth_provider.dart';
import 'package:sajilo_ride/screens/onboarding_page.dart';
import 'package:sajilo_ride/widgets/app_shell.dart';
import 'navbar/navbar_config.dart';
import 'firebase_options.dart';
import 'screens/admin_web/admin_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_)=> AuthProviderMethod(),
       child:  const MaterialApp(
         debugShowCheckedModeBanner: false,
          title: 'Sajilo Ride',
         // home: AuthWrapper(),
         home: kIsWeb ? AdminDashboardPage() : AuthWrapper(),
        ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
   return Consumer<AuthProviderMethod>(builder: (context, authProvider, child) {
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

  @override Widget build(BuildContext context) {
    // Get the current user's UID safely.
    final String? uid = FirebaseAuth.instance. currentUser?.uid;
// If for some reason there is no UID, show an error or login page.
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Error: User not logged in.")),
      );
    }
    return FutureBuilder<DocumentSnapshot>(
      // The future now correctly fetches the document for the current user.
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        // 1. Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Handle error state
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text("Error: ${snapshot.error}")),
          );
        }

        // 3. Handle "no data" or "document doesn't exist" state
        if (!snapshot.hasData || !snapshot.data!.exists) {
          // This can happen if user record was not created properly
          context.read<AuthProviderMethod>().signOut();
          return const Scaffold(
            body: Center(
                child: Text("User data not found. Please log in again.")),
          );
        }

        // 4. If we have data, extract the role.
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final String roleString = data['role'] ??
            'passenger';

        UserRole currentUserRole;
        if (roleString == 'driver') {
          currentUserRole = UserRole.driver;
        } else {
          currentUserRole = UserRole.passenger;
        }
        // 6. FINALLY: Return the AppShell with the correct role.
        return AppShell(userRole: currentUserRole);
      },
    );
  }
}
*/