import 'package:flutter/material.dart';
import 'package:sajilo_ride/data/model/car_model.dart';
import '../../navbar/navbar_config.dart';
import '../../widgets/app_shell.dart';

class BookingConfirmContent extends StatelessWidget {
  final CarModel car;
  final UserRole userRole;
  final double fare;
  final double distance;

  const BookingConfirmContent({
    super.key,
    required this.car,
    required this.userRole,
    required this.fare,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.green,
                      child: Icon(Icons.check, size: 60, color: Colors.white),
                    ),
                    const SizedBox(height: 30),


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


                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow("Distance", "${distance.toStringAsFixed(1)} km"),
                          const Divider(),
                          _buildSummaryRow("Total Fare", "Rs ${fare.toStringAsFixed(0)}"),
                          const Divider(),
                          _buildSummaryRow("Status", "Confirmed", isStatus: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),


                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AppShell(
                                userRole: userRole, // Use dynamic role
                                initialIndex: 0,
                              ),
                            ),
                                (route) => false,
                          );
                        },
                        child: const Text("Back to Home",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AppShell(
                              userRole: userRole,
                              initialIndex: 1,
                            ),
                          ),
                              (route) => false,
                        );
                      },
                      child: const Text("View My Rides",
                          style: TextStyle(color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

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

