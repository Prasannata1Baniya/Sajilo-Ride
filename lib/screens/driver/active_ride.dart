import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentStatus == 'accepted' ? "Navigate to Pickup" : "Trip Ongoing"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // 1. LIVE MAP
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(widget.bookingData['pickupLat'], widget.bookingData['pickupLng']),
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.sajilo_ride.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(widget.bookingData['pickupLat'], widget.bookingData['pickupLng']),
                    child: const Icon(Icons.location_on, color: Colors.red, size: 40),
                  ),
                ],
              ),
            ],
          ),

          // 2. TRIP CONTROL PANEL
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(radius: 25, backgroundColor: Colors.orange, child: Icon(Icons.person, color: Colors.white)),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Passenger Request", style: TextStyle(color: Colors.grey)),
                            Text(widget.bookingData['carModel'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Text("Rs. ${widget.bookingData['price']}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 25),

                  // DYNAMIC BUTTON BASED ON STATUS
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentStatus == 'accepted' ? Colors.blue : Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _updateTripStatus(),
                      child: Text(
                        _currentStatus == 'accepted' ? "ARRIVED & START TRIP" : "ARRIVED & COMPLETE TRIP",
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
  }

  // --- LOGIC: UPDATE STATUS ---
  Future<void> _updateTripStatus() async {
    String nextStatus = _currentStatus == 'accepted' ? 'started' : 'completed';

    try {
      await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).update({
        'status': nextStatus,
        if (nextStatus == 'completed') 'completedAt': FieldValue.serverTimestamp(),
      });

      if (nextStatus == 'completed') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Trip Completed! Money added to earnings.")));
          Navigator.pop(context); // Go back to dashboard
        }
      } else {
        setState(() => _currentStatus = nextStatus);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}