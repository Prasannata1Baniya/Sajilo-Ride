import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sajilo_ride/auth/auth_provider.dart';
import 'package:sajilo_ride/screens/auth_page/login_page.dart';
import 'package:sajilo_ride/screens/onboarding_page.dart';
import 'package:sajilo_ride/screens/passenger/passenger_home_page.dart';
import 'package:sajilo_ride/widgets/app_shell.dart';
import 'navbar/navbar_config.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

    // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_)=> AuthProviderMethod(),
       child:  MaterialApp(
         debugShowCheckedModeBanner: false,
          title: 'Sajilo Ride',
          home: PassengerHomeContent(),
          //OnBoardingPage(),
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
       return const LoginPage();
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
          // This can happen if user record was not created properly.
          // It's good to sign them out and let them try again.
          context.read<AuthProviderMethod>().signOut();
          return const Scaffold(
            body: Center(
                child: Text("User data not found. Please log in again.")),
          );
        }

        // 4. If we have data, extract the role.
        final data = snapshot.data!.data() as Map<String, dynamic>;
        final String roleString = data['role'] ??
            'passenger'; // Default to passenger if role is null

        // 5. Convert the role string to our UserRole enum.
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



/*class RoleWrapper extends StatelessWidget {
  const RoleWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final uid= FirebaseAuth.instance.currentUser!.uid;
    return FutureBuilder(future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
        builder: (context,snapshot){
      if(snapshot.connectionState==ConnectionState.waiting){
        return const Scaffold(
          body: CircularProgressIndicator(),
        );
      }

      if(!snapshot.hasData || !snapshot.data!.exists){
        return const Scaffold(
          body: Center(child: Text("User Not found"),),
        );
      }

      final role= snapshot.data!['role'];

      if(role == 'driver'){
        return const DriverHomeScreen();
      }else{
        return PassengerHomeScreen();
      }
    });
  }
}


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sajilo_ride/auth/auth_provider.dart';
import 'package:sajilo_ride/config/navigation_config.dart';
import 'package:sajilo_ride/screens/app_shell.dart';

class RoleWrapper extends StatelessWidget {
  const RoleWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // You would get the user's role from your AuthProvider or by fetching from Firestore
    // This is a placeholder for that logic.
    UserRole currentUserRole = getRoleFromAuthProvider(context); // This is a hypothetical function

    // Return the AppShell with the correct role
    return AppShell(userRole: currentUserRole);
  }

  // --- EXAMPLE of how you might get the role ---
  // (You need to implement the actual logic for fetching the role from Firestore
  // in your AuthProvider after a user logs in).
  UserRole getRoleFromAuthProvider(BuildContext context) {
    // In a real app, you would fetch the user document from Firestore
    // and check the 'role' field.
    // For this example, we'll just pretend.
    String roleString = 'driver'; // This would come from your user data model

    if (roleString == 'driver') {
      return UserRole.driver;
    } else {
      return UserRole.passenger;
    }
  }
}
 */