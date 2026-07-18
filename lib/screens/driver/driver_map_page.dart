import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sajilo_ride/screens/driver/active_ride.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverMapPage extends StatefulWidget {
  final LatLng pickupLocation;
  final String bookingId;
  final Map<String, dynamic> bookingData;
  final String driverId;

  const DriverMapPage({
    super.key,
    required this.pickupLocation,
    required this.bookingId,
    required this.bookingData,
    required this.driverId,
  });

  @override
  State<DriverMapPage> createState() => _DriverMapPageState();
}

class _DriverMapPageState extends State<DriverMapPage> {
  void _launchNavigation() async {
    final url = 'google.navigation:q=${widget.pickupLocation.latitude},${widget.pickupLocation.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }


  Future<void> _acceptRide(BuildContext context, String docId, String driverId) async {
    try {
      final docRef = FirebaseFirestore.instance.collection('bookings').doc(docId);


      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (snapshot.data()?['status'] != 'pending') {
          throw Exception("This ride has already been taken by another driver.");
        }
        transaction.update(docRef, {
          'status': 'accepted',
          'driverId': driverId,
          'acceptedAt': FieldValue.serverTimestamp(),
        });

        transaction.update(
          FirebaseFirestore.instance.collection('drivers').doc(driverId),
          {
            'isAvailable': false,
          },
        );

      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))),
        );
      }
      rethrow;
    }
  }

  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    // Safe dropoff coordinates
    final double dropoffLat =
    (widget.bookingData['dropoffLat'] ?? widget.pickupLocation.latitude).toDouble();
    final double dropoffLng =
    (widget.bookingData['dropoffLng'] ?? widget.pickupLocation.longitude).toDouble();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Pickup Location"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 1. MAP showing pickup and dropoff pins
          FlutterMap(
            options: MapOptions(
              initialCenter: widget.pickupLocation,
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
                    point: widget.pickupLocation,
                    width: 80,
                    height: 80,
                    child: const Column(
                      children: [
                        Icon(Icons.my_location, color: Colors.green, size: 40),
                        Text("Pickup",
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.green)),
                      ],
                    ),
                  ),
                  // Dropoff marker (red)
                  Marker(
                    point: LatLng(dropoffLat, dropoffLng),
                    width: 80,
                    height: 80,
                    child: const Column(
                      children: [
                        Icon(Icons.location_on, color: Colors.red, size: 40),
                        Text("Drop-off",
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. BOTTOM INFO CARD
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Passenger is waiting here",
                    style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.bookingData['pickupAddress'] ?? "Navigate to pickup location",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Fare: Rs ${widget.bookingData['fare'] ?? '0'}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                            fontSize: 16),
                      ),

                      if (widget.bookingData['passengerPhone'] != null && widget.bookingData['passengerPhone'].toString().isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.phone, color: Colors.blue),
                          onPressed: () async {
                            final phone = widget.bookingData['passengerPhone'];
                            final url = Uri.parse("tel:$phone");
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.navigation, color: Colors.white),
                      label: const Text("NAVIGATE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                      onPressed: _launchNavigation,
                    ),
                  ),

                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child:ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: _isProcessing ? null : () async {
                        setState(() => _isProcessing = true);
                        try {
                          await _acceptRide(context, widget.bookingId, widget.driverId);
                          if (context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ActiveRideContent(
                                  bookingId: widget.bookingId,
                                  bookingData: widget.bookingData,
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          setState(() => _isProcessing = false);
                        }
                      },
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("ACCEPT RIDE",
                        style: TextStyle(color: Colors.white),),
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
}

