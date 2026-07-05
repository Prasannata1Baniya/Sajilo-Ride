import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:sajilo_ride/auth/auth_provider.dart';
import 'package:sajilo_ride/screens/passenger/rating_screen.dart';
import 'package:sajilo_ride/utils/phone_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../navbar/navbar_config.dart';
import '../../widgets/app_shell.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {

  Future<void> _handleCancelRide(BuildContext context, String docId, Map<String, dynamic> data) async {
    final String paymentStatus = data['paymentStatus'] ?? 'unpaid';
    final String paymentMethod = data['paymentMethod'] ?? 'Cash';
    final bool isPaid = paymentStatus == 'paid';

    if (data['status'] == 'cancelled') return;
    try {
      bool confirm = await showDialog(
        context: context,
        builder: (context) =>
            Dialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Decorative Icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                          Icons.warning_amber_rounded, color: Colors.red,
                          size: 40),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Cancel Trip?",
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isPaid
                          ? "This ride was paid via $paymentMethod. A full refund will be automatically initiated to your account."
                          : "Are you sure you want to cancel this ride? This action cannot be undone.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 15, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text("Go Back",
                                style: TextStyle(fontWeight: FontWeight.bold,color: Colors.grey)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text("Cancel Ride",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      ) ?? false;

      if (!confirm) return;

      try {
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(docId)
            .update(
            {
              'status': 'cancelled',
              'paymentStatus': isPaid ? 'refund_initiated' : 'unpaid',
              'cancelledAt': FieldValue.serverTimestamp(),
            });

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isPaid
                  ? "Refund Initiated to $paymentMethod"
                  : "Ride Cancelled Successfully"),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to cancel ride. Please try again.")),
          );
        }
        debugPrint("Firebase Update Error: $e");
      }
    }catch (e) {
      debugPrint("Error: $e");
    }
  }



  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderMethod>(context);
    final userId = authProvider.user?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: const Text("My Active Rides",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.orange),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const AppShell(
                  userRole: UserRole.passenger,
                  initialIndex: 0,
                ),
              ),
                  (route) => false,
            );
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('passengerId', isEqualTo: userId)
            .where('status', whereIn: ['pending', 'accepted', 'ongoing','completed', 'searching'])
           // .where('hiddenFromUser', isNotEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildNoRidesPlaceholder();
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            itemBuilder: (context, index) {
              final docId = snapshot.data!.docs[index].id;
              final bookingData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
              return _buildActiveRideCard(context, docId, bookingData);
            },
          );
        },
      ),
    );
  }


  Widget _buildActiveRideCard(BuildContext context, String docId, Map<String, dynamic> data) {
    final status = data['status'] ?? 'pending';
    bool isPaid = data['paymentStatus'] == 'paid';
    bool canCancel = status == 'pending' || status == 'accepted';

    if (status == 'searching') {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.orange),
                padding: EdgeInsets.zero, // Remove  padding
                constraints: const BoxConstraints(), // Shrink the hit area
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('bookings').doc(docId).update({
                    'status': 'archived'
                  });
                },
              ),
            ),
            const Row(
              children: [
                CircularProgressIndicator(color: Colors.orange, strokeWidth: 2),
                SizedBox(width: 15),
                Expanded(
                  child: Text(
                    "Your previous driver was unavailable. Search again in Home page...",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: Icon(Icons.home,color: Colors.white,),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,

              ),
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const AppShell(userRole: UserRole.passenger, initialIndex: 0)),
                      (route) => false,
                );
              },
              label: const Text("Search Again",style: TextStyle(fontWeight: FontWeight.bold),),
            ),
          ],
        ),
      );
    }

    if (status == 'completed') {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Stack(
          children: [
            // 'X' Button
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                /*onPressed: () async {
                  // Mark as archived so it disappears from the list
                  await FirebaseFirestore.instance.collection('bookings').doc(docId).update({
                    'status': 'archived'
                  });},*/
                // Inside _buildActiveRideCard logic for 'X' button
                onPressed: () async {
                  String newStatus = (status == 'searching') ? 'archived_search' : 'archived_completed';

                  await FirebaseFirestore.instance.collection('bookings').doc(docId).update({
                    'status': newStatus
                  });
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded, color: Colors.green, size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text("Trip Completed!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text("Total Fare: Rs ${data['fare'] ?? '0'}", style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        final String driverId = data['driverId'] ?? '';
                        Navigator.push(context, MaterialPageRoute(builder: (_) => RatingScreen(bookingId: docId, driverId: driverId,)));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange,
                          elevation: 0,
                          foregroundColor: Colors.white),
                      child: const Text("Rate Your Driver",
                          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // If the ride was just cancelled, don't show the card at all
    if (status == 'cancelled') return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.directions_car_filled, color: Colors.orange, size: 28),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['model'] ?? "Ride",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(isPaid ? "Payment Verified (eSewa)" : "Payment: Cash on Arrival",
                            style: TextStyle(color: isPaid ? Colors.green : Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  _buildStatusBadge(status),
                ],
              ),
            ),


            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                children: [
                  //_buildInfoTile(Icons.circle_outlined, "Pickup Location", "Kathmandu, Nepal", Colors.blue),
                  _buildInfoTile(Icons.circle_outlined, "Pickup",
                      data['pickupAddress'] ?? 'Unknown', Colors.blue),
                  const SizedBox(height: 12),
                  _buildInfoTile(Icons.payments_outlined, "Estimated Fare",
                      "Rs ${data['fare']}", Colors.green),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(15),
              color: const Color(0xFFF9FAFB),
              child: Column(
                children: [
                  if (status == 'accepted') ...[
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final driverId = data['driverId'];
                        String? phone = data['phone'] ?? 'Not Provided';

                        if (phone == null || phone.isEmpty) {
                          final driverDoc = await FirebaseFirestore.instance.collection('drivers').doc(driverId).get();
                          phone = driverDoc.data()?['phone'];
                        }
                        if (phone != null && phone.isNotEmpty) {
                          final Uri launchUri = Uri(scheme: 'tel', path: phone);
                          await launchUrl(launchUri);
                        } else {
                          messenger.showSnackBar(
                            const SnackBar(content: Text("Driver phone number not available")),
                          );
                        }
                      },
                      icon: const Icon(Icons.phone),
                      label: const Text("Call Driver"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                    ),
                  ],

                  if (status == 'pending') ...[
                    const LinearProgressIndicator(color: Colors.orange, backgroundColor: Color(0xFFEEEEEE)),
                    const SizedBox(height: 12),
                    const Text("Looking for nearest drivers...", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.black54)),
                  ],

                  if (status == 'ongoing') ...[
                    Row(
                      children: [
                        const Icon(Icons.security, color: Colors.blue, size: 20),
                        const SizedBox(width: 10),
                        const Text("Trip is live", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () => EmergencyService.showSOSDialog(context),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, elevation: 0, shape: const StadiumBorder()),
                          child: const Text("SOS", style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (canCancel) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade100)),
                      child: Center(
                          child: Text("Verification OTP: ${data['otp'] ?? '----'}",
                            style:  TextStyle(fontWeight: FontWeight.bold, fontSize: 16,
                           color: Colors.orange, letterSpacing: 2),
                          ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: TextButton(
                        onPressed: () => _handleCancelRide(context, docId, data),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.red.shade100)),
                        ),
                        child: const Text("CANCEL RIDE", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],


                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- PREMIUM UI HELPERS ---
  Widget _buildStatusBadge(String status) {
    Color color = status == 'ongoing' ? Colors.blue : (status == 'pending' ? Colors.orange : Colors.green);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoRidesPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow:
            [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20)]),
            child: Icon(Icons.no_transfer, size: 80, color: Colors.grey[300]),
          ),
          const SizedBox(height: 25),
          const Text("No Active Rides Found", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("Time to explore! Start your first ride today.", style: TextStyle(color: Colors.grey, fontSize: 15)),
        ],
      ),
    );
  }
}


