import 'package:flutter/material.dart';
import 'package:sajilo_ride/screens/driver/profile.dart';
import '../screens/driver/active_ride.dart';
import '../screens/driver/car_management.dart';
import '../screens/driver/driver_home_page.dart';
import '../screens/driver/earning.dart';

// Step 1: Define a model for our navigation items for a single source of truth.
class NavItem {
  final String label;
  final IconData icon;
  final Widget screen;

  const NavItem({required this.label, required this.icon, required this.screen});
}

class NavigationShell extends StatefulWidget {
  const NavigationShell({super.key});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _currentIndex = 0;

  final List<NavItem> _destinations = const [
    NavItem(label: 'Home', icon: Icons.home_outlined, screen: DriverHomeContent()),
    NavItem(label: 'Earning', icon: Icons.monetization_on_outlined, screen: CarManagementContent()),
    NavItem(label: 'Booking', icon: Icons.book_online_outlined, screen: ActiveRideContent()),
    NavItem(label: 'Earning', icon: Icons.monetization_on_outlined, screen: EarningContent()),
    NavItem(label: 'Profile', icon: Icons.person_outline, screen: ProfileContent()),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      body: Row(
        children: [
          // If the screen is wide, show the persistent side navigation rail.
          if (isWide)
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onItemTapped,
              labelType: NavigationRailLabelType.all,
              leading: Image.asset("assets/images/car_logo1.png", height: 80), // Your logo
              destinations: _destinations.map((item) {
                return NavigationRailDestination(
                  icon: Icon(item.icon),
                  label: Text(item.label),
                );
              }).toList(),
            ),

          // The main content of the selected page. It expands to fill the remaining space.
          Expanded(
            child: _destinations[_currentIndex].screen,
          ),
        ],
      ),

      // If the screen is NOT wide, show the bottom navigation bar.
      bottomNavigationBar: isWide
          ? null // Don't show a bottom bar on wide screens
          : BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
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