import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- IMPORTS FOR YOUR SCREENS ---
import '../navbar/navbar_config.dart';
import '../screens/driver/driver_home_page.dart';
import '../screens/passenger/rides_page.dart';
import '../screens/driver/car_management.dart';
import '../screens/driver/earning.dart';
import '../screens/driver/profile.dart';
import '../screens/passenger/passenger_home_page.dart';
import '../screens/passenger/profile.dart';
import '../screens/passenger/ride_history.dart';

class AppShell extends StatefulWidget {
  final UserRole userRole;
  final int initialIndex;

  const AppShell({
    super.key,
    required this.userRole,
    this.initialIndex = 0,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;
  late List<NavItem> _destinations;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _buildDestinations();
    _setupPushNotifications();
  }

  void _buildDestinations() {
    if (widget.userRole == UserRole.passenger) {
      _destinations = [
        const NavItem(label: 'Home', icon: Icons.home, screen: PassengerHomeContent()),
        const NavItem(label: "Booking", icon: Icons.book_online_outlined, screen: MyRidesPage()),
        const NavItem(label: 'History', icon: Icons.history_outlined, screen: RideHistoryContent()),
        const NavItem(label: 'Profile', icon: Icons.person_outline, screen: PassengerProfileContent()),
      ];
    } else {
      _destinations = [
        const NavItem(label: 'Home', icon: Icons.home_outlined, screen: DriverHomeContent()),
        const NavItem(label: 'Car', icon: Icons.directions_car, screen: CarManagementContent()),
        const NavItem(label: 'Earning', icon: Icons.monetization_on_outlined, screen: DriversEarningContent()),
        const NavItem(label: 'Profile', icon: Icons.person_outline, screen: DriverProfileContent()),
      ];
    }
  }

  void _setupPushNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permissions for Android 13+
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get the FCM Token
      String? token = await messaging.getToken();

      if (token != null) {
        String uid = FirebaseAuth.instance.currentUser!.uid;
        // Determine correct collection
        String collection = widget.userRole == UserRole.driver ? 'drivers' : 'users';

        // Save token to Firestore
        await FirebaseFirestore.instance.collection(collection).doc(uid).update({
          'fcmToken': token,
        });
        debugPrint("FCM Token Saved: $token");
      }
    }

    // Listen for Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Notification: ${message.notification?.body ?? 'New Request!'}"),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Responsive check: Sidebar for Web/Tablet (> 720px), BottomBar for Mobile
    final bool isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar for Wide Screens (Web)
          if (isWide)
            NavigationRail(
              backgroundColor: Colors.orange.shade800,
              selectedIndex: _currentIndex,
              onDestinationSelected: _onItemTapped,
              labelType: NavigationRailLabelType.all,
              unselectedIconTheme: const IconThemeData(color: Colors.white70),
              selectedIconTheme: const IconThemeData(color: Colors.white),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Image.asset("assets/images/SajiloRide_logo.png", height: 50),
              ),
              destinations: _destinations.map((item) {
                return NavigationRailDestination(
                  icon: Icon(item.icon),
                  label: Text(item.label, style: const TextStyle(color: Colors.white)),
                );
              }).toList(),
            ),

          // Main Content
          Expanded(
            child: _destinations[_currentIndex].screen,
          ),
        ],
      ),

      // Bottom Navigation for Mobile
      bottomNavigationBar: isWide
          ? null
          : BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey[600],
        items: _destinations.map((item) {
          return BottomNavigationBarItem(
            icon: Icon(item.icon),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }
}
