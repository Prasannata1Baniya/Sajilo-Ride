import 'package:flutter/material.dart';

class MyRidesPage extends StatelessWidget {
  const MyRidesPage({super.key});

  @override
  Widget build(BuildContext context) {
    // For now, we will show a placeholder.
    // In the future, you would use a StreamBuilder to fetch active bookings from Firestore.

    final bool hasActiveRide = false; // Change to true to see the other view

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Active Rides"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: hasActiveRide
            ? _buildActiveRideCard() // Display this if a ride is active
            : _buildNoRidesPlaceholder(), // Display this if there are no active rides
      ),
    );
  }

  // Placeholder for when there are no active rides
  Widget _buildNoRidesPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.car_rental_outlined,
          size: 80,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 20),
        const Text(
          "No Active Rides",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        const Text(
          "Your upcoming rides will appear here.",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }

  // An example card to show when a ride is active
  Widget _buildActiveRideCard() {
    return Card(
      margin: const EdgeInsets.all(20),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: const Padding(
        padding:  EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children:  [
            Text(
              "Driver is on the way!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
            SizedBox(height: 20),
            Text("Fortuner GR-S", style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text("Plate No: BA 12 PA 3456"),
            SizedBox(height: 20),
            LinearProgressIndicator(), // To show progress
          ],
        ),
      ),
    );
  }
}