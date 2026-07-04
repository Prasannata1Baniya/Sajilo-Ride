import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sajilo_ride/auth/auth_provider.dart';

class DriversEarningContent extends StatelessWidget {
  const DriversEarningContent({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderMethod>(context);
    final driverId = authProvider.user?.uid;

    // Guard: not logged in
    if (driverId == null) {
      return const Scaffold(
        body: Center(child: Text("Error: Not logged in.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Earnings"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('driverId', isEqualTo: driverId)
            .where('status', isEqualTo: 'completed')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading earnings.\n${snapshot.error}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          // Safely parse price whether stored as String or number
          double total = 0;
          for (var doc in snapshot.data!.docs) {
            final raw = doc['fare'];
            total += double.tryParse(raw.toString()) ?? 0.0;
          }

          return Column(
            children: [
              // 1. TOTAL SUMMARY HEADER
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade700, Colors.orange.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      "Total Balance",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Rs. ${total.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "${snapshot.data!.docs.length} ride${snapshot.data!.docs.length == 1 ? '' : 's'} completed",
                      style: const TextStyle(color: Colors.white54, fontSize: 13,fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Recent History",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // 2. LIST OF COMPLETED RIDES
              Expanded(
                child: ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final data = snapshot.data!.docs[index].data()
                    as Map<String, dynamic>;

                    // Safely parse price
                    final String priceDisplay =
                        "Rs. ${data['fare'] ?? '0'}";

                    // Safely parse date
                    final DateTime? date =
                    (data['completedAt'] as Timestamp?)?.toDate();
                    final String dateDisplay = date != null
                        ? DateFormat('MMM dd, yyyy - hh:mm a').format(date)
                        : "Date unavailable";

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: ListTile(
                        /*leading:  CircleAvatar(
                          backgroundColor: Colors.green.shade50,
                          child: Icon(Icons.check, color: Colors.white),
                        ),*/
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.currency_rupee, color: Colors.green),
                        ),
                        title: Text(
                          data['model'] ?? "Ride",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle:Text(dateDisplay, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        trailing:Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(priceDisplay, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16)),
                            Text(data['paymentMethod'] ?? 'Cash', style: const TextStyle(fontSize: 10, color: Colors.orange)),
                          ],
                        ),

                        isThreeLine: true,
                      ),
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
          Icon(Icons.account_balance_wallet_outlined,
              size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "No earnings yet.",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey),
          ),
          Text(
            "Complete some rides to see your balance!",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}









/*import 'package:cloud_firestore/cloud_firestore.dart';
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
        backgroundColor: Colors.orange,
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
                      title: Text(data['model'] ?? "Ride"),
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
 */