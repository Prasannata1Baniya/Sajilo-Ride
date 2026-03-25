import 'package:flutter/material.dart';
import 'package:sajilo_ride/data/model/car_model.dart';
import '../../navbar/navbar_config.dart';
import '../../widgets/app_shell.dart';


class BookingConfirmContent extends StatelessWidget {
  final CarModel car;

  const BookingConfirmContent({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- 1. SUCCESS ICON ---
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.green,
                child: Icon(Icons.check, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 30),

              // --- 2. SUCCESS TEXT ---
              const Text(
                "Booking Confirmed!",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "Your ride with ${car.model} has been successfully booked.",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // --- 3. SUMMARY CARD ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow("Car Model", car.model),
                    const Divider(),
                    _buildSummaryRow("Price", "\$${car.pricePerHour}/hr"),
                    const Divider(),
                    _buildSummaryRow("Status", "Reserved", isStatus: true),
                  ],
                ),
              ),
              const SizedBox(height: 50),

              // --- ACTION BUTTONS ---
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text("Back to Home", style: TextStyle(color: Colors.white, fontSize: 18)),
                ),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AppShell(
                        userRole: UserRole.passenger,
                        initialIndex: 1,
                      ),
                    ),
                        (route) => false,
                  );
                },
                child: const Text("View My Rides", style: TextStyle(color: Colors.orange, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Row for Summary
  Widget _buildSummaryRow(String title, String value, {bool isStatus = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, color: Colors.black54)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isStatus ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
