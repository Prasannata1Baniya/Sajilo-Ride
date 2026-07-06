import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:sajilo_ride/auth/auth_provider.dart';
import 'package:sajilo_ride/screens/driver/active_ride.dart';
import '../../widgets/driver_car_avatar_widget.dart';
import '../driver/driver_map_page.dart';

class DriverHomeContent extends StatefulWidget {
  const DriverHomeContent({super.key});

  @override
  State<DriverHomeContent> createState() => _DriverHomeContentState();
}

class _DriverHomeContentState extends State<DriverHomeContent> {

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProviderMethod>(context, listen: false);
      final driverId = authProvider.user?.uid;
      if (driverId != null) {
        authProvider.saveDeviceToken(driverId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderMethod>(context);
    final driverId = authProvider.user?.uid;

    if (driverId == null) return const Scaffold(body: Center(child: Text("Not logged in")));
    //authProvider.saveDeviceToken(driverId);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('driverId', isEqualTo: driverId)
          //.where('status', isEqualTo: 'accepted')
          .where('status', whereIn: ['accepted', 'ongoing'])
          .snapshots(),
      builder: (context, tripSnapshot) {
        if (tripSnapshot.hasData && tripSnapshot.data!.docs.isNotEmpty) {
          return ActiveRideContent(
            bookingId: tripSnapshot.data!.docs.first.id,
            bookingData: tripSnapshot.data!.docs.first.data() as Map<String, dynamic>,
          );
        }

        // 2. SECOND LEVEL: If no active trip, check account verification status
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(driverId).snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.orange)));
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const Scaffold(body: Center(child: Text("Record not found.")));
            }

            var userData = userSnapshot.data!.data() as Map<String, dynamic>;
            String rawStatus = (userData['verificationStatus'] ?? userData['status'] ?? 'pending').toString().toLowerCase().trim();
            bool isApproved = userData['isApproved'] == true || userData['approved'] == true || userData['isVerified'] == true;

            // 3. FINAL ROUTING: Show Dashboard, Rejected, or Review screens
            if (rawStatus == 'approved' || rawStatus == 'verified' || isApproved) {
              return _buildRequestsDashboard(driverId);
            }
            if (rawStatus == 'rejected' || rawStatus == 'failed') {
              return _buildRejectedScreen();
            }
            return _buildReviewingScreen();
          },
        );
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
            //.orderBy('timestamp', descending: true)
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
              return _buildRequestCard(context, doc.id, data, driverId,key: ValueKey(doc.id),);
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
  Widget _buildRequestCard(BuildContext context, String docId, Map<String, dynamic> data, String driverId,
      {Key? key}) {
    //String? carImagePath = data['image']?.toString();
    debugPrint("DEBUG: Image URL found in booking: ${data['image']}");
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                DriverCarAvatarWidget(driverId: data['driverId'] ?? 'unknown'),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['model'] ?? "Ride Request", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text("Payment: ${data['paymentMethod'] ?? 'Cash'}",
                          style: TextStyle(color: data['paymentStatus'] == 'paid' ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                    ],
                  ),
                ),
                Text("Rs ${data['fare'] ?? '0'}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
              ],
            ),
            //const Divider(height: 30),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1),
            ),

            // --- REPLACEMENT FOR THE LOCATION ROW ---
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  // PICKUP ROW
                  Row(
                    children: [
                      const Icon(Icons.radio_button_checked, color: Colors.green, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("PICKUP", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                            Text(data['pickupAddress'] ?? 'Fetching...', style: const TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  // CONNECTOR LINE
                  Container(height: 20, width: 2, margin: const EdgeInsets.only(left: 9), color: Colors.grey.shade300),
                  // DROP-OFF ROW
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("DROP-OFF", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                            Text(data['dropoffAddress'] ?? 'Fetching...', style: const TextStyle(fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Row(
              children: [
               TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DriverMapPage(
                          pickupLocation: LatLng(
                            (data['pickupLat'] as num?)?.toDouble() ?? 0.0,
                            (data['pickupLng'] as num?)?.toDouble() ?? 0.0,
                          ),
                          bookingId: docId,
                          bookingData: data,
                          driverId: driverId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map, size: 18),
                 label: const Text("VIEW MAP & ACCEPT"),
                ),
              ],
            ),

            const SizedBox(height: 16),
            OutlinedButton(
              onPressed:() => _declineRide(context, docId, driverId),
              style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              foregroundColor: Colors.red),
              child: const Text("DECLINE"),
            )
          ],
        ),
      ),
    );
  }

   Future<void> _declineRide(BuildContext context, String bookingId, String driverId) async {
    try {
      // We use a transaction to ensure data integrity
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentReference bookingRef = FirebaseFirestore.instance.collection('bookings').doc(bookingId);

        transaction.update(bookingRef, {
          // 1. Mark that this specific driver rejected it
          'rejected_by': FieldValue.arrayUnion([driverId]),

          // Set status back to 'searching' so that dispatch logic tries again
          'status': 'searching',

          // Remove current driver reference if it exists
          'driverId': FieldValue.delete(),
        });
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ride declined by you..."), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      debugPrint("Error declining ride: $e");
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

