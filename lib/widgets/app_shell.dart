import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../navbar/navbar_config.dart'; // Import your config

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
    // FIX: Get destinations from the central config file
    _destinations = getDestinationsForRole(widget.userRole);
    _setupPushNotifications();
  }

  void _setupPushNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    String? token = await messaging.getToken();
    if (token != null) {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        // FIX: Always use 'users' collection as per your AuthProvider
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fcmToken': token,
        });
      }
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.notification?.body ?? 'New Update!'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              backgroundColor: Colors.black,
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) => setState(() => _currentIndex = i),
              labelType: NavigationRailLabelType.all,
              unselectedIconTheme: const IconThemeData(color: Colors.white70),
              selectedIconTheme: const IconThemeData(color: Colors.orange),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Image.asset("assets/images/SajiloRide_logo.png", height: 50),
              ),
              destinations: _destinations.map((item) => NavigationRailDestination(
                icon: Icon(item.icon),
                label: Text(item.label, style: const TextStyle(color: Colors.white)),
              )).toList(),
            ),

          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _destinations.map((item) => item.screen).toList(),
            ),
          ),
        ],
      ),

      bottomNavigationBar: isWide ? null : BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.white60,
        items: _destinations.map((item) => BottomNavigationBarItem(
          icon: Icon(item.icon),
          label: item.label,
        )).toList(),
      ),
    );
  }
}

