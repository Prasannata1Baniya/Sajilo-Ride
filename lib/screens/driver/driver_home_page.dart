import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:sajilo_ride/auth/auth_provider.dart';
import 'package:sajilo_ride/screens/driver/active_ride.dart';
import '../driver/driver_map_page.dart';

class DriverHomeContent extends StatelessWidget {
  const DriverHomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderMethod>(context);
    final driverId = authProvider.user?.uid;

    if (driverId != null) {
      authProvider.saveDeviceToken(driverId);
    }

    // Check this specific driver's account approval status dynamically
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(driverId)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.orange)),
          );
        }

        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text("Driver record not found.")),
          );
        }

        var userData = userSnapshot.data!.data() as Map<String, dynamic>;

        // Read string fields safely, converting to lowercase to avoid case-mismatch bugs
        String rawStatus = (userData['verificationStatus'] ?? userData['status'] ?? 'pending')
            .toString()
            .toLowerCase()
            .trim();

        // 🛠️ FIXED: Added userData['isVerified'] == true to match your admin panel panel value exactly!
        bool isExplicitlyApproved = userData['isApproved'] == true ||
            userData['approved'] == true ||
            userData['isVerified'] == true;

        // 🚀 ROUTING LOGIC: Evaluate status conditions securely
        if (rawStatus == 'approved' || rawStatus == 'verified' || isExplicitlyApproved) {
          return _buildRequestsDashboard(driverId!);
        }

        if (rawStatus == 'rejected' || rawStatus == 'failed') {
          return _buildRejectedScreen();
        }

        // If 'pending' or anything else undetermined, keep showing the review interface
        return _buildReviewingScreen();
      },
    );
  }

  Widget _buildRequestsDashboard(String driverId) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("New Ride Requests"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('status', isEqualTo: 'pending')
            .where('driverId', isEqualTo: driverId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildNoRequests();
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              return _buildRequestCard(context, doc.id, data, driverId);
            },
          );
        },
      ),
    );
  }

  // --- UI: IN REVIEW SCREEN ---
  Widget _buildReviewingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.gavel_rounded,
                  size: 80,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                "Documents Under Review",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                "Your driving license and biometrics are currently undergoing validation. You will gain access to accept client trips immediately upon approval.",
                style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(color: Colors.orange, strokeWidth: 3),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI: REJECTED SCREEN ---
  Widget _buildRejectedScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.gpp_bad_rounded, size: 80, color: Colors.redAccent),
              ),
              const SizedBox(height: 32),
              const Text(
                "Verification Failed",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              const Text(
                "Your submitted documents could not be verified by our team. Please contact administrative support to re-upload clear credentials.",
                style: TextStyle(fontSize: 15, color: Colors.black54, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI: CARD AND BUILDERS ---
  Widget _buildRequestCard(BuildContext context, String docId, Map<String, dynamic> data, String driverId) {
    String? carImagePath = data['carImage']?.toString();
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.orange.shade100,
                  backgroundImage: carImagePath != null
                      ? (carImagePath.startsWith('http')
                      ? NetworkImage(carImagePath)
                      : AssetImage(carImagePath)) as ImageProvider
                      : null,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['carModel'] ?? "Unknown Car", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Payment: ${data['paymentMethod']}",
                          style: TextStyle(color: data['paymentStatus'] == 'paid' ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
                Text("Rs ${data['fare'] ?? '0'}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
              ],
            ),
            const Divider(height: 30),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 10),
                Expanded(
                  child: Text("Pickup: ${data['pickupAddress'] ?? 'Fetching...'}", style: const TextStyle(color: Colors.black54, fontSize: 13)),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DriverMapPage(
                          pickupLocation: LatLng((data['pickupLat'] as num).toDouble(), (data['pickupLng'] as num).toDouble()),
                          bookingId: docId,
                          bookingData: data,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map, size: 18),
                  label: const Text("VIEW MAP"),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _acceptRide(context, docId, driverId, data),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: const Text("ACCEPT RIDE"),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text("DECLINE"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _acceptRide(BuildContext context, String docId, String driverId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(docId).update({
        'status': 'accepted',
        'driverId': driverId,
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ride Accepted!"), backgroundColor: Colors.green),
        );
        Navigator.push(context, MaterialPageRoute(builder: (context) => ActiveRideContent(bookingId: docId, bookingData: data)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  Widget _buildNoRequests() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("Searching for nearby riders...", style: TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }
}
