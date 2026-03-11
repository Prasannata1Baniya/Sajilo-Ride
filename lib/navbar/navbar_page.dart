import 'package:flutter/material.dart';
import 'package:sajilo_ride/screens/driver/driver_home_page.dart';
import 'package:sajilo_ride/screens/passenger/rides_page.dart';
import '../screens/driver/car_management.dart';
import '../screens/driver/earning.dart';
import '../screens/driver/profile.dart';
import '../screens/passenger/passenger_home_page.dart';
import '../screens/passenger/profile.dart';
import '../screens/passenger/ride_history.dart';


// Role Enum
enum UserRole { passenger, driver }

class NavItem {
  final String label;
  final IconData icon;
  final Widget screen;
  const NavItem({required this.label, required this.icon, required this.screen});
}

class NavigationShell extends StatefulWidget {
  final UserRole userRole; // <--- Pass the role here

  const NavigationShell({super.key, required this.userRole});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  int _currentIndex = 0;

  // Define Passenger Menu
  final List<NavItem> _passengerDestinations = [
    const NavItem(label: 'Home', icon: Icons.home, screen: PassengerHomeContent()),
    const NavItem(label: "Booking", icon: Icons.book_online_outlined, screen: MyRidesPage()),
    const NavItem(label: 'History', icon: Icons.history_outlined, screen: RideHistoryContent()),
    const NavItem(label: 'Profile', icon: Icons.person_outline, screen: PassengerProfileContent()),
  ];

  // Define Driver Menu
  final List<NavItem> _driverDestinations = [
    const NavItem(label: 'Home', icon: Icons.home_outlined, screen: DriverHomeContent()),
    const NavItem(label: 'Car', icon: Icons.directions_car, screen: CarManagementContent()),
    const NavItem(label: 'Earning', icon: Icons.monetization_on_outlined, screen: DriversEarningContent()),
    const NavItem(label: 'Profile', icon: Icons.person_outline, screen: DriverProfileContent()),
  ];

  @override
  Widget build(BuildContext context) {
    // Pick the list based on the role passed from Login
    final List<NavItem> activeDestinations =
    widget.userRole == UserRole.driver ? _driverDestinations : _passengerDestinations;

    final bool isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) => setState(() => _currentIndex = i),
              labelType: NavigationRailLabelType.all,
              leading: Image.asset("assets/images/SajiloRide_logo.png", height: 50),
              destinations: activeDestinations.map((item) {
                return NavigationRailDestination(
                  icon: Icon(item.icon),
                  label: Text(item.label),
                );
              }).toList(),
            ),
          Expanded(
            child: activeDestinations[_currentIndex].screen,
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: widget.userRole == UserRole.driver ? Colors.orange : Colors.blue,
        items: activeDestinations.map((item) {
          return BottomNavigationBarItem(
            icon: Icon(item.icon),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }
}