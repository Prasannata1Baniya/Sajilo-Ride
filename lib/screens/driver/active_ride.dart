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
                          onPressed: () => _updateTripStatus(),
                          child: Text(
                            _currentStatus == 'accepted'
                                ? "ARRIVED & START TRIP"
                                : "ARRIVED & COMPLETE TRIP",
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
  Future<void> _updateTripStatus() async {
    final messenger = ScaffoldMessenger.of(context);

    // 1. Handle OTP Verification for starting the trip
    if (_currentStatus == 'accepted') {
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
                 if (otpController.text.trim() == widget.bookingData['otp'].toString().trim()) {
                    Navigator.pop(context, true);
                  } else {
                    // Use the captured messenger here
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

      // If OTP was not confirmed, stop the function here
      if (confirmed != true) return;
    }

    // 2. Perform the Firestore Update
    final String nextStatus = _currentStatus == 'accepted' ? 'ongoing' : 'completed';

    try {
      Map<String, dynamic> updateData = {'status': nextStatus};

      if (nextStatus == 'ongoing') {
        updateData['startedAt'] = FieldValue.serverTimestamp();
      } else if (nextStatus == 'completed') {
        updateData['completedAt'] = FieldValue.serverTimestamp();
        // Handle payment status
        if (widget.bookingData['paymentStatus'] != 'paid') {
          updateData['paymentStatus'] = 'cash_collected';
        }
      }

      await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).update(updateData);

      // Optional: add a success message
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



  /*Future<void> _updateTripStatus() async {


    if (_currentStatus == 'accepted') {
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
                  labelStyle: TextStyle(color: Colors.orange,fontWeight: FontWeight.bold),
                  //focusColor: Colors.orange,

                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange, width: 1.0),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.orange, width: 2.0),
                  ),

                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async{
                  //Navigator.pop(context, true);
                  if (otpController.text.trim() == widget.bookingData['otp'].toString()) {
                    // 3. Close the modal and send 'true' back to the calling function
                    Navigator.pop(context, true);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid OTP"),
                        backgroundColor: Colors.red));
                  }
                },

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      "START TRIP",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

            ],
          ),
        ),
      );

      if (confirmed != true) return;

      if (otpController.text.trim() != widget.bookingData['otp'].toString()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid OTP"), backgroundColor: Colors.red));
        }
        return;
      }
    }

    /*final String nextStatus = _currentStatus == 'accepted' ? 'ongoing' : 'completed';
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).update({
        'status': nextStatus,
        if (nextStatus == 'completed') 'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Status Update Error: $e");
    }*/


    final String nextStatus = _currentStatus == 'accepted' ? 'ongoing' : 'completed';
    try {
      Map<String, dynamic> updateData = {
        'status': nextStatus,
      };

      if (nextStatus == 'ongoing') {
        updateData['startedAt'] = FieldValue.serverTimestamp();
      } else if (nextStatus == 'completed') {
        updateData['completedAt'] = FieldValue.serverTimestamp();
        if (widget.bookingData['paymentStatus'] != 'paid') {
          updateData['paymentStatus'] = 'cash_collected';
        }
      }

      if (nextStatus == 'completed') {
        updateData['completedAt'] = FieldValue.serverTimestamp();

        // If it's a cash ride, mark as 'cash_collected'
        // If it was already 'paid' (eSewa), mark it as 'paid'
        if (widget.bookingData['paymentStatus'] != 'paid') {
          updateData['paymentStatus'] = 'cash_collected';
        }
      }

      await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).update(updateData);
    } catch (e) {
      debugPrint("Status Update Error: $e");
    }
  }*/



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