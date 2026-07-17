import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/model/car_model.dart';

class CarDriverDetailPage extends StatefulWidget {
  final CarModel car;
  const CarDriverDetailPage({super.key, required this.car});

  @override
  State<CarDriverDetailPage> createState() => _CarDriverDetailPageState();
}

class _CarDriverDetailPageState extends State<CarDriverDetailPage> {

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    } catch (e) {
      debugPrint("Could not launch phone dialer: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Booking Details", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                image: DecorationImage(
                  image: widget.car.image.startsWith('http')
                      ? NetworkImage(widget.car.image)
                      : AssetImage(widget.car.image.isNotEmpty ? widget.car.image : 'assets/images/car1.jpg') as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildSectionCard(
                    title: "Vehicle Information",
                    icon: Icons.directions_car,
                    child: Column(
                      children: [
                        _buildDetailRow("Model", widget.car.model, Icons.model_training),
                        const Divider(),
                        _buildDetailRow("Plate Number", widget.car.carNumber, Icons.numbers),
                        const Divider(),
                        _buildDetailRow("Fuel Type", "Petrol", Icons.local_gas_station),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  _buildSectionCard(
                    title: "Driver Details",
                    icon: Icons.person,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rating Row
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('drivers')
                              .doc(widget.car.driverId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData || !snapshot.data!.exists) {
                              return Row(children: [const Icon(Icons.star, color: Colors.amber, size: 18),
                                Text(widget.car.rating.toString())]);
                            }

                            var data = snapshot.data!.data() as Map<String, dynamic>;
                            double rating = (data['averageRating'] ?? 0.0).toDouble();
                            // we can also fetch total rides if you store that in Firestore
                            var totalRides = data['totalRides'] ?? 0;

                            return Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(" ($totalRides+ Rides)", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.orange.shade100,
                              child: const Icon(Icons.person, color: Colors.orange),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(widget.car.driverName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const Text("Verified Sajilo Partner", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            // Corrected Call Button
                            IconButton(
                              onPressed: () => _makePhoneCall(widget.car.phone),
                              icon: const Icon(Icons.call, color: Colors.blue, size: 28),
                            ),
                          ],
                        ),
                        const Divider(height: 30),
                        _buildDetailRow("Phone", widget.car.phone, Icons.phone_android),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 4. PRICE SUMMARY
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Rate per km", style: TextStyle(color: Colors.white70)),
                        Text("Rs ${widget.car.pricePerKm.toStringAsFixed(0)}",
                            style: const TextStyle(color: Colors.orange, fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),

      // 5.BOTTOM ACTION BUTTON
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("CONFIRM THIS RIDE",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
        ),
      ),
    );
  }

  // Helper methods remain the same
  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.orange.shade300),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.black54)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }
}