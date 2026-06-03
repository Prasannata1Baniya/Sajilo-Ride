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

    // Check this specific driver's account approval status
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users') // Assumes your driver metadata lives in 'users' or 'drivers'
          .doc(driverId)
          .snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return const Scaffold(
            body: Center(child: Text("Driver record not found.")),
          );
        }

        var userData = userSnapshot.data!.data() as Map<String, dynamic>;
        String verificationStatus = userData['verificationStatus'] ?? 'pending';

        // If not approved yet, display the Review status screen
        if (verificationStatus == 'pending') {
          return _buildReviewingScreen();
        }

        if (verificationStatus == 'rejected') {
          return _buildRejectedScreen();
        }

        return _buildRequestsDashboard(driverId!);
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
            return const Center(child: CircularProgressIndicator());
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
                  Icons.gavel_rounded, // Cool judge/verification icon
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
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(color: Colors.orange, strokeWidth: 3),
              ),
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

  // --- UI: CARD AND BUILDERS (UNTOUCHED) ---
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








/*import 'package:cloud_firestore/cloud_firestore.dart';
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

    // Trigger token save in the background if driverId is found
    if (driverId != null) {
      authProvider.saveDeviceToken(driverId);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("New Ride Requests"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings').where('status', isEqualTo: 'pending')
            .where('driverId', isEqualTo: driverId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
              // Call the helper method and pass the driverId
              return _buildRequestCard(context, doc.id, data, driverId!);
            },
          );
        },
      ),
    );
  }

  Widget _buildRequestCard(BuildContext context, String docId, Map<String, dynamic> data, String driverId) {
    // 1. Extract Image Path Safely
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
                // 2. Optimized Image Logic (Fixed Web/Mobile & Types)
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
                      Text(data['carModel'] ?? "Unknown Car",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Payment: ${data['paymentMethod']}",
                          style: TextStyle(
                              color: data['paymentStatus'] == 'paid' ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ],
                  ),
                ),
                /*Text("\$${data['price']}",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),*/
                // Inside _buildRequestCard
                Text("Rs ${data['fare'] ?? '0'}", // Use 'fare' to match PassengerHomeContent
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),

              ],
            ),

            const Divider(height: 30),

            /*Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 10),
                Expanded(
                    child: Text("Pickup: ${data['pickupAddress'] ?? 'Fetching...'}",
                        style: const TextStyle(color: Colors.black54, fontSize: 13))
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => DriverMapPage(
                      pickupLocation: LatLng(data['pickupLat'], data['pickupLng']),
                      bookingId: docId, bookingData: data,
                    )));
                  },
                  icon: const Icon(Icons.map, size: 18),
                  label: const Text("VIEW MAP"),
                )
              ],
            ),*/
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Pickup: ${data['pickupAddress'] ?? 'Fetching...'}",
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DriverMapPage(
                          pickupLocation: LatLng(
                            (data['pickupLat'] as num).toDouble(),
                            (data['pickupLng'] as num).toDouble(),
                          ),
                          bookingId: docId,
                          bookingData: data,
                        ),),);
                  },
                  icon: const Icon(Icons.map, size: 18),
                  label: const Text("VIEW MAP"),
                ),],
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    child: const Text("ACCEPT RIDE"),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () {
                    // Logic for decline if needed
                  },
                  style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                  ),
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

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActiveRideContent(
              bookingId: docId,
              bookingData: data,
            ),
          ),
        );
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
          const Text("Searching for nearby riders...",
              style: TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }
}
*/