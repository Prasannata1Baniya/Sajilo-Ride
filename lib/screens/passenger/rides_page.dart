import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:sajilo_ride/auth/auth_provider.dart';
import '../../navbar/navbar_page.dart';

class MyRidesPage extends StatelessWidget {
  const MyRidesPage({super.key});

  // --- FEATURE: PROFESSIONAL CANCELLATION & REFUND LOGIC ---
  Future<void> _handleCancelRide(BuildContext context, String docId, Map<String, dynamic> data) async {
    final String paymentStatus = data['paymentStatus'] ?? 'unpaid';
    final String paymentMethod = data['paymentMethod'] ?? 'Cash';
    final bool isPaid = paymentStatus == 'paid';

    try {
      bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Cancel Ride?", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(isPaid
              ? "This ride was paid via $paymentMethod. A full refund will be automatically initiated to your account."
              : "Are you sure you want to cancel this ride?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("GO BACK")),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("CANCEL RIDE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ) ?? false;

      if (!confirm) return;

      await FirebaseFirestore.instance.collection('bookings').doc(docId).update({
        'status': 'cancelled',
        'paymentStatus': isPaid ? 'refund_initiated' : 'unpaid',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isPaid ? "Refund Initiated to $paymentMethod" : "Ride Cancelled Successfully"),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderMethod>(context);
    final userId = authProvider.user?.uid;

    return Scaffold(
      // --- FIX: USE A LIGHT GREY BACKGROUND TO MAKE WHITE CARDS POP ---
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: const Text("My Active Rides",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.orange),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const NavigationShell(
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
            .where('status', whereIn: ['pending', 'accepted', 'ongoing'])
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
    String status = data['status'] ?? 'pending';
    bool isPaid = data['paymentStatus'] == 'paid';
    bool canCancel = status == 'pending' || status == 'accepted';

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
            // 1. TOP SECTION (Driver Info / Car Info)
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
                        Text(data['carModel'] ?? "Ride",
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

            // 2. MIDDLE SECTION (Trip Info)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildInfoTile(Icons.circle_outlined, "Pickup Location", "Kathmandu, Nepal", Colors.blue),
                  const SizedBox(height: 12),
                  _buildInfoTile(Icons.payments_outlined, "Estimated Fare", "\$${data['price']}", Colors.green),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // 3. BOTTOM ACTION SECTION
            Container(
              padding: const EdgeInsets.all(20),
              color: const Color(0xFFF9FAFB),
              child: Column(
                children: [
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
                          onPressed: () {}, // SOS Feature
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, elevation: 0, shape: const StadiumBorder()),
                          child: const Text("SOS", style: TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],

                  if (canCancel) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orange.shade100)),
                      child: const Center(child: Text("Verification OTP: 4 8 2 1", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orange, letterSpacing: 2))),
                    ),
                    const SizedBox(height: 15),
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
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
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
