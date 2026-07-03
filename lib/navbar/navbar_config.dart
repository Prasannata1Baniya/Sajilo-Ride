import 'package:flutter/material.dart';
import '../screens/passenger/passenger_home_page.dart';
import '../screens/passenger/bookings_page.dart';
import '../screens/passenger/ride_history.dart';
import '../screens/passenger/profile.dart';
import '../screens/driver/driver_home_page.dart';
import '../screens/driver/car_management.dart';
import '../screens/driver/earning.dart';
import '../screens/driver/profile.dart';

enum UserRole { passenger, driver }

class NavItem {
  final String label;
  final IconData icon;
  final Widget screen;
  const NavItem({required this.label, required this.icon, required this.screen});
}


const List<NavItem> passengerDestinations = [
  NavItem(label: 'Home', icon: Icons.home, screen: PassengerHomeContent()),
  NavItem(label: "Booking", icon: Icons.book_online_outlined, screen: MyBookingsPage()),
  NavItem(label: 'History', icon: Icons.history_outlined, screen: RideHistoryContent()),
  NavItem(label: 'Profile', icon: Icons.person_outline, screen: PassengerProfileContent()),
];

const List<NavItem> driverDestinations = [
  NavItem(label: 'Home', icon: Icons.home_outlined, screen: DriverHomeContent()),
  NavItem(label: 'Car', icon: Icons.directions_car, screen: CarManagementContent()),
  NavItem(label: 'Earning', icon: Icons.monetization_on_outlined, screen: DriversEarningContent()),
  NavItem(label: 'Profile', icon: Icons.person_outline, screen: DriverProfileContent()),
];

List<NavItem> getDestinationsForRole(UserRole role) {
  return role == UserRole.driver ? driverDestinations : passengerDestinations;
}


/*List<NavItem> getDestinationsForRole(UserRole role) {
  switch (role) {
    case UserRole.passenger:
      return passengerDestinations;
    case UserRole.driver:
      return driverDestinations;
  }
}
*/