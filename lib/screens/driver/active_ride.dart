import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../navbar/navbar_config.dart';
import '../../widgets/app_shell.dart';

class ActiveRideContent extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const ActiveRideContent({super.key, required this.bookingId, required this.bookingData});

  @override
  State<ActiveRideContent> createState() => _ActiveRideContentState();
}

class _ActiveRideContentState extends State<ActiveRideContent> {
  String _currentStatus = '';

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.bookingData['status'];
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').doc(
          widget.bookingId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final bookingData = snapshot.data!.data() as Map<String, dynamic>;
        final status = bookingData['status'];

        if (status == 'completed') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const AppShell(userRole: UserRole.driver, initialIndex: 0)),
                  (route) => false,
            );
          });
        }

        if (status == 'cancelled') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Ride Cancelled by Passenger")));
            Navigator.pop(context);
          });
        }

        _currentStatus = status;

        final double pickupLat = (widget.bookingData['pickupLat'] ?? 27.7172)
            .toDouble();
        final double pickupLng = (widget.bookingData['pickupLng'] ?? 85.3240)
            .toDouble();
        final double dropoffLat = (widget.bookingData['dropoffLat'] ?? 27.7172)
            .toDouble();
        final double dropoffLng = (widget.bookingData['dropoffLng'] ?? 85.3240)
            .toDouble();

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7F9),
          appBar: AppBar(
            title: Text(_currentStatus == 'accepted'
                ? "Navigate to Pickup"
                : "Trip Ongoing"),
            backgroundColor: Colors.orange.shade700,
            foregroundColor: Colors.white,
          ),
          body: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(pickupLat, pickupLng),
                  initialZoom: 15.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.prasannata.sajilo_ride',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(pickupLat, pickupLng),
                        child: const Icon(
                            Icons.my_location, color: Colors.green, size: 40),
                      ),
                      Marker(
                        point: LatLng(dropoffLat, dropoffLng),
                        child: const Icon(
                            Icons.location_on, color: Colors.red, size: 40),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                        top: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 10)
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(radius: 25, backgroundColor: Colors
                              .orange, child: Icon(
                              Icons.person, color: Colors.white)),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Passenger Request",
                                    style: TextStyle(color: Colors.grey)),
                                Text(widget.bookingData['model'] ?? 'Ride',
                                    style: const TextStyle(fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Text("Rs. ${widget.bookingData['fare'] ?? '0'}",
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 25),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _currentStatus == 'accepted'
                                ? Colors.blue
                                : Colors.green,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _updateTripStatus(status,bookingData),
                          child: Text(status == 'accepted' ? "ARRIVED & START TRIP" : "ARRIVED & COMPLETE TRIP",
                            style: const TextStyle(color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  Future<void> _updateTripStatus(String currentStatus,Map<String, dynamic> liveData) async {
    final messenger = ScaffoldMessenger.of(context);

    if (currentStatus == 'accepted') {
      final otpController = TextEditingController();

      final bool? confirmed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 20, left: 20, right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Verify Passenger", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: "Enter 4-digit OTP",
                  labelStyle: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange, width: 1.0)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange, width: 2.0)),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                 if (otpController.text.trim() == liveData['otp'].toString().trim()) {
                    Navigator.pop(context, true);
                  } else {
                    messenger.showSnackBar(const SnackBar(
                        content: Text("Invalid OTP"), backgroundColor: Colors.red));
                  }

                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text("START TRIP", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );

      if (confirmed != true) return;
    }


    final String nextStatus = currentStatus == 'accepted' ? 'ongoing' : 'completed';

    try {
      Map<String, dynamic> updateData = {'status': nextStatus};

      if (nextStatus == 'ongoing') {
        updateData['startedAt'] = FieldValue.serverTimestamp();
      } else if (nextStatus == 'completed') {
        updateData['completedAt'] = FieldValue.serverTimestamp();
        if (liveData['paymentStatus'] != 'paid') {
          updateData['paymentStatus'] = 'cash_collected';
        }
      }

      await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).update(updateData);

      if (mounted && nextStatus == 'completed') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Trip Completed Successfully!")));
      }
    } catch (e) {
      debugPrint("Status Update Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
      }
    }
  }
}
