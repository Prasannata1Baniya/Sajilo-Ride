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

    final double pickupLat = (widget.bookingData['pickupLat'] ?? 27.7172).toDouble();
    final double pickupLng = (widget.bookingData['pickupLng'] ?? 85.3240).toDouble();
    final double dropoffLat = (widget.bookingData['dropoffLat'] ?? 27.7172).toDouble();
    final double dropoffLng = (widget.bookingData['dropoffLng'] ?? 85.3240).toDouble();

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
                  // Pickup marker (green)
                  Marker(
                    point: LatLng(pickupLat, pickupLng),
                    child: const Icon(Icons.my_location, color: Colors.green, size: 40),
                  ),
                  // Dropoff marker (red)
                  Marker(
                    point: LatLng(dropoffLat, dropoffLng),
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
                      const CircleAvatar(
                        radius: 25,
                        backgroundColor: Colors.orange,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Passenger Request", style: TextStyle(color: Colors.grey)),
                            Text(
                              widget.bookingData['model'] ?? 'Ride',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "Rs. ${widget.bookingData['fare'] ?? '0'}",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
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


// 2. Updated OTP Verification Logic
  Future<void> _updateTripStatus() async {
  if (_currentStatus == 'accepted') {
  final otpController = TextEditingController();

  // Show OTP Dialog
  final confirmed = await showGeneralDialog<bool>(
  context: context,
  pageBuilder: (context, anim1, anim2) => AlertDialog(
  title: const Text("Enter Passenger OTP"),
  content: TextField(
  controller: otpController,
  keyboardType: TextInputType.number,
  decoration: const InputDecoration(hintText: "Ask passenger for 4-digit code"),
  ),
  actions: [
  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
  ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Start Trip")),
  ],
  ),
  );

  if (confirmed != true) return;

  // Check OTP - Ensure we compare strings to strings
  if (otpController.text.trim() != widget.bookingData['otp'].toString()) {
  if (mounted) {
  ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text("Invalid OTP"), backgroundColor: Colors.red),
  );
  }
  return;
  }
  }

  // 3. Status Transition Logic
  // If 'accepted' -> move to 'ongoing'. If 'ongoing' -> move to 'completed'.
  final String nextStatus = _currentStatus == 'accepted' ? 'ongoing' : 'completed';

  try {
  await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).update({
  'status': nextStatus,
  if (nextStatus == 'completed') 'completedAt': FieldValue.serverTimestamp(),
  });

  if (nextStatus == 'completed') {
  if (mounted) Navigator.pop(context);
  } else {
  setState(() => _currentStatus = nextStatus);
  }
  } catch (e) {
  debugPrint("Status Update Error: $e");
  }
  }

}


// --- LOGIC: OTP VERIFICATION + STATUS UPDATE ---

/*Future<void> _updateTripStatus() async {
    // Ask driver to verify OTP before starting the trip
    if (_currentStatus == 'accepted') {
      final otpController = TextEditingController();
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Verify Passenger OTP", style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            decoration: InputDecoration(
              hintText: "Enter 4-digit OTP",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Verify", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Check OTP matches
      if (otpController.text.trim() != widget.bookingData['otp']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Incorrect OTP! Please ask the passenger."),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    // 'accepted' -> 'ongoing',  'ongoing' -> 'completed'
    final String nextStatus = _currentStatus == 'accepted' ? 'ongoing' : 'completed';

    try {
      await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).update({
        'status': nextStatus,
        if (nextStatus == 'completed') 'completedAt': FieldValue.serverTimestamp(),
      });

      if (nextStatus == 'completed') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Trip Completed!")),
          );
          Navigator.pop(context);
        }
      } else {
        setState(() => _currentStatus = nextStatus);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }*/




/*import 'package:cloud_firestore/cloud_firestore.dart';
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
  late String nextStatus = _currentStatus == 'accepted' ? 'ongoing' : 'completed';



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
                            Text(widget.bookingData['model'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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

 */