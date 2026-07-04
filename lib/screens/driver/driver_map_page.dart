import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sajilo_ride/screens/driver/active_ride.dart';
import 'package:url_launcher/url_launcher.dart';

class DriverMapPage extends StatelessWidget {
  final LatLng pickupLocation;
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const DriverMapPage({
    super.key,
    required this.pickupLocation,
    required this.bookingId,
    required this.bookingData,
  });


  void _launchNavigation() async {
    final url = 'google.navigation:q=${pickupLocation.latitude},${pickupLocation.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safe dropoff coordinates
    final double dropoffLat =
    (bookingData['dropoffLat'] ?? pickupLocation.latitude).toDouble();
    final double dropoffLng =
    (bookingData['dropoffLng'] ?? pickupLocation.longitude).toDouble();

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
              initialCenter: pickupLocation,
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
                    point: pickupLocation,
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
                    bookingData['pickupAddress'] ?? "Navigate to pickup location",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Fare: Rs ${bookingData['fare'] ?? '0'}",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                            fontSize: 16),
                      ),

                      if (bookingData['passengerPhone'] != null && bookingData['passengerPhone'].toString().isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.phone, color: Colors.blue),
                          onPressed: () async {
                            final phone = bookingData['passengerPhone'];
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
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue), // Navigation is blue
                      onPressed: _launchNavigation, // Use your defined function!
                    ),
                  ),

                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _goToActiveRide(context),
                      child: const Text(
                        "START RIDE",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
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


  void _goToActiveRide(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveRideContent(
          bookingId: bookingId,
          bookingData: bookingData,
        ),
      ),
    );
  }
}

