import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
    _initNotifications();

    _requestNotificationPermission();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProviderMethod>(context, listen: false);
      final driverId = authProvider.user?.uid;
      if (driverId != null) {
        authProvider.saveDeviceToken(driverId);
      }
    });

    // Listen for messages while the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        // Using flutter_local_notifications to display the notification
        _displayLocalNotification(
          message.notification!.title ?? "New Ride",
          message.notification!.body ?? "Check your app for a new request!",
        );
      }
    });

  }
  Future<void> _initNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    await FlutterLocalNotificationsPlugin().initialize(
      const InitializationSettings(android: androidSettings),
    );
  }

  Future<void> _requestNotificationPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    }
  }

  // Helper method to display the notification
  Future<void> _displayLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'your_channel_id',
      'Ride Requests',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await FlutterLocalNotificationsPlugin().show(
      0, title, body, platformDetails,
    );
  }

  bool _isAccepting = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderMethod>(context);
    final driverId = authProvider.user?.uid;

    if (driverId == null) return const Scaffold(body: Center(child: Text("Not logged in")));
    authProvider.saveDeviceToken(driverId);

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
      //elevation: 5,
      //shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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

            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.red),
                const SizedBox(width: 10),
                Expanded(
                  child: Text("Pickup: ${data['pickupAddress'] ?? 'Fetching...'}",
                      style: const TextStyle(color: Colors.black54, fontSize: 13,)
                  ),
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
                    //onPressed: () => _acceptRide(context, docId, driverId, data),
                    onPressed: _isAccepting ? null : () async {
                      setState(() => _isAccepting = true);
                      await _acceptRide(context, docId, driverId, data);
                      if (mounted) setState(() => _isAccepting = false);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    child: _isAccepting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                        : const Text("ACCEPT RIDE"),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: _isAccepting ? null : () => _declineRide(context, docId, driverId),
                  style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  foregroundColor: Colors.red),
                  child: const Text("DECLINE"),
                ),
              ],
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

  Future<void> _acceptRide(BuildContext context, String docId, String driverId, Map<String, dynamic> data) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('bookings').doc(docId);

      // Transaction ensures the write only happens if status is still 'pending'
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (snapshot.data()?['status'] != 'pending') {
          throw Exception("Ride already taken!");
        }
        transaction.update(docRef, {
          'status': 'accepted',
          'driverId': driverId,
          'acceptedAt': FieldValue.serverTimestamp(),
        });
      });
      /*if (context.mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ActiveRideContent(bookingId: docId, bookingData: data)));
      }*/
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))));
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

