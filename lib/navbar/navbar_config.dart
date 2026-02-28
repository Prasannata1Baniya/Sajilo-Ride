import 'package:flutter/material.dart';
import 'package:sajilo_ride/screens/driver/driver_home_page.dart';
import 'package:sajilo_ride/screens/passenger/booking_confirm.dart';
import 'package:sajilo_ride/screens/passenger/rides_page.dart';

import '../screens/driver/active_ride.dart';
import '../screens/driver/car_management.dart';
import '../screens/driver/earning.dart';
import '../screens/driver/profile.dart';
import '../screens/passenger/passenger_home_page.dart';
import '../screens/passenger/ride_history.dart';
import '../screens/profile_page.dart';

// A simple enum to represent user roles. This is safer than using strings.
enum UserRole { passenger, driver }

// The model for a navigation item remains the same.
class NavItem {
  final String label;
  final IconData icon;
  final Widget screen;

  const NavItem({required this.label, required this.icon, required this.screen});
}

// --- DEFINE THE NAVIGATION ITEMS FOR EACH ROLE ---

// Navigation items for the Passenger
 List<NavItem> passengerDestinations = [
  NavItem(label: 'Home', icon: Icons.home, screen: PassengerHomeContent()),
  const NavItem(label: "Booking", icon: Icons.book_online_outlined, screen: MyRidesPage());
  //const NavItem(label: 'Booking', icon: Icons.book_online_outlined,screen: BookingConfirmContent(car: null,)),
  const NavItem(label: 'History', icon: Icons.history_outlined, screen: RideHistoryContent()),
  const NavItem(label: 'Profile', icon: Icons.person_outline, screen: ProfileContent()),
];

// Navigation items for the Driver
const List<NavItem> driverDestinations = [
  NavItem(label: 'Home', icon: Icons.home_outlined, screen: DriverHomeContent()),
  NavItem(label: 'Earning', icon: Icons.monetization_on_outlined, screen: CarManagementContent()),
  NavItem(label: 'Booking', icon: Icons.book_online_outlined, screen: ActiveRideContent()),
  NavItem(label: 'Earning', icon: Icons.monetization_on_outlined, screen: EarningContent()),
  NavItem(label: 'Profile', icon: Icons.person_outline, screen: ProfileScreen()),
];

// A helper function to get the correct list based on the role.
List<NavItem> getDestinationsForRole(UserRole role) {
  switch (role) {
    case UserRole.passenger:
      return passengerDestinations;
    case UserRole.driver:
      return driverDestinations;
  }
}