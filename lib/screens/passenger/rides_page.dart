import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:sajilo_ride/auth/auth_provider.dart';

class MyRidesPage extends StatelessWidget {
  const MyRidesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderMethod>(context);
    final userId = authProvider.user?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("My Active Rides")),
      // REAL-TIME STREAM: Listens to the 'bookings' collection
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('passengerId', isEqualTo: userId)
            .where('status', whereIn: ['pending', 'accepted', 'ongoing']) // Show all active states
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildNoRidesPlaceholder();
          }

          // If there are active rides, show them in a list
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var bookingData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return _buildActiveRideCard(bookingData);
            },
          );
        },
      ),
    );
  }

  Widget _buildActiveRideCard(Map<String, dynamic> data) {
    // Dynamic status colors for a professional feel
    Color statusColor = data['status'] == 'pending' ? Colors.orange : Colors.green;

    return Card(
      margin: const EdgeInsets.all(15),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(data['carModel'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(data['status'].toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const Divider(height: 30),
            const Row(
              children: [
                Icon(Icons.location_on, color: Colors.red, size: 20),
                SizedBox(width: 10),
                Text("Pickup: Kathmandu, Nepal"), // Replace with real data if available
              ],
            ),
            const SizedBox(height: 20),
            if (data['status'] == 'pending')
              const Text("Searching for nearby drivers...", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
            else
              const LinearProgressIndicator(),
          ],
        ),
      ),
    );
  }

// Use your existing _buildNoRidesPlaceholder here...
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