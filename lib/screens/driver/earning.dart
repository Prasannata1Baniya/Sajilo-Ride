import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sajilo_ride/auth/auth_provider.dart';

class DriversEarningContent extends StatelessWidget {
  const DriversEarningContent({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderMethod>(context);
    final driverId = authProvider.user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Earnings"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Only show rides that are 'completed' and belong to THIS driver
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('driverId', isEqualTo: driverId)
            .where('status', isEqualTo: 'completed')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          // CALCULATE TOTAL EARNINGS
          double total = 0;
          for (var doc in snapshot.data!.docs) {
            total += (doc['price'] ?? 0).toDouble();
          }

          return Column(
            children: [
              // 1. TOTAL SUMMARY HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                color: Colors.black,
                child: Column(
                  children: [
                    const Text("Total Balance", style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 10),
                    Text("Rs. ${total.toStringAsFixed(2)}",
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 36, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Recent History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),

              // 2. LIST OF COMPLETED RIDES
              Expanded(
                child: ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    return ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.check, color: Colors.white)),
                      title: Text(data['carModel'] ?? "Ride"),
                      subtitle: Text("Payment: ${data['paymentMethod']}"),
                      trailing: Text("Rs. ${data['price']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey),
          Text("No earnings yet. Complete some rides!", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}