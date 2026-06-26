import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:sajilo_ride/auth/auth_provider.dart';

class RideHistoryContent extends StatelessWidget {
  const RideHistoryContent({super.key});

  @override
  Widget build(BuildContext context) {

    final authProvider = Provider.of<AuthProviderMethod>(context);
    final userId = authProvider.user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ride History"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('passengerId', isEqualTo: userId)
            .where('status', whereIn: ['completed', 'cancelled'])
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          final userId = authProvider.user?.uid;
          if (userId == null) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyHistory();
          }

          if (snapshot.hasError) {
            return Center(child: Text("Something went wrong.\n${snapshot.error}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red)));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemBuilder: (context, index) {
              var ride = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return _buildHistoryCard(ride);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> ride) {

    DateTime date = (ride['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    String formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(date);

    bool isCancelled = ride['status'] == 'cancelled';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isCancelled ? Colors.red.shade50 : Colors.green.shade50,
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCancelled ? Icons.close : Icons.directions_car,
            color: isCancelled ? Colors.red : Colors.green,
          ),
        ),
        title: Text(
          ride['model'] ?? "Unknown Car",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(formattedDate, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              isCancelled ? "Ride Cancelled" : "Ride Completed",
              style: TextStyle(
                color: isCancelled ? Colors.red : Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: Text(
          "\$Rs{ride['price']}",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            "No rides yet!",
            style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold),
          ),
          const Text("Your completed trips will appear here."),
        ],
      ),
    );
  }
}