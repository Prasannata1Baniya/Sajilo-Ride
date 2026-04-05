import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:esewa_flutter_sdk/esewa_flutter_sdk.dart';
import 'package:esewa_flutter_sdk/esewa_config.dart';
import 'package:esewa_flutter_sdk/esewa_payment.dart';
import 'package:sajilo_ride/data/model/car_model.dart';
import 'package:sajilo_ride/screens/passenger/booking_confirm.dart';

class PassengerHomeContent extends StatefulWidget {
  const PassengerHomeContent({super.key});

  @override
  State<PassengerHomeContent> createState() => _PassengerHomeContentState();
}

class _PassengerHomeContentState extends State<PassengerHomeContent> {
  final MapController _mapController = MapController();

  LatLng _currentCenter = const LatLng(27.7172, 85.3240);
  LatLng? pickupLocation;
  LatLng? dropOffLocation;
  List<LatLng> routePoints = [];

  double distance = 0;
  double fare = 0;
  CarModel? selectedCar;
  String selectedPayment = "Cash";

  String _pickupAddress = "Select Pickup Point";
  String _dropoffAddress = "Select Drop-off Point";
  bool isSelectingPickup = true;


  static const String clientId = "JB0BBQ4aD0UqIThFJwAKBgAXEUkEGQUBBAwdOgABHD4DChwUAB0R";
  static const String secretKey = "BhwIWQQADhIYSxILExMcAgFXFhcOBwAKBgAXEQ==";

  // Fallback Data
  final List<CarModel> carList = [
    CarModel(model: "Sajilo Moto", distance: 0, pricePerHour: 20,
        fuelCapacity: 0, image: "assets/images/car1.jpg", driverId: 'demo1'),
    CarModel(model: "Sajilo Car", distance: 0, pricePerHour: 50,
        fuelCapacity: 0, image: "assets/images/car2.jpg", driverId: 'demo2'),
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final current = LatLng(position.latitude, position.longitude);
      _updateLocationState(current, true);
    } catch (e) {
      _updateLocationState(const LatLng(27.7172, 85.3240), true);
    }
  }

  void _updateLocationState(LatLng pos, bool isPickup) {
    setState(() {
      if (isPickup) {
        pickupLocation = pos;
        _currentCenter = pos;
      } else {
        dropOffLocation = pos;
      }
    });
    _mapController.move(pos, 14);
    _getAddress(pos, isPickup);
    if (pickupLocation != null && dropOffLocation != null) _getRoute();
  }

  Future<void> _getAddress(LatLng position, bool isPickup) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}');
      final response = await http.get(url, headers: {'User-Agent': 'sajilo_ride'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (isPickup) {
            _pickupAddress = data['display_name'] ?? "Current Location";
          } else {
            _dropoffAddress = data['display_name'] ?? "Target Location";
          }
        });
      }
    } catch (e) { debugPrint("Geo Error: $e"); }
  }

  Future<void> _getRoute() async {
    final url = Uri.parse("https://router.project-osrm.org/route/v1/driving/${pickupLocation!.longitude},${pickupLocation!.latitude};${dropOffLocation!.longitude},${dropOffLocation!.latitude}?overview=full&geometries=geojson");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final coords = data['routes'][0]['geometry']['coordinates'];
      setState(() {
        routePoints = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
        distance = data['routes'][0]['distance'] / 1000.0;
        if (selectedCar != null) fare = distance * selectedCar!.pricePerHour;
      });
    }
  }

  void _processEsewaSDKPayment() {
    try {
      EsewaFlutterSdk.initPayment(
        esewaConfig: EsewaConfig(environment: Environment.test, clientId: clientId, secretId: secretKey),
        esewaPayment: EsewaPayment(
          productId: "ride_${DateTime.now().millisecondsSinceEpoch}",
          productName: selectedCar!.model,
          productPrice: fare.toStringAsFixed(0),
          callbackUrl: '',
        ),
        onPaymentSuccess: (data) => _confirmBooking(paymentStatus: "paid", method: "eSewa"),
        onPaymentFailure: (data) => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Payment Failed"))),
        onPaymentCancellation: (data) => debugPrint("Cancelled"),
      );
    } catch (e) { debugPrint("eSewa Error: $e"); }
  }

  Future<void> _confirmBooking({String paymentStatus = "unpaid", String method = "Cash"}) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    await FirebaseFirestore.instance.collection('bookings').add({
      'passengerId': userId,
      'driverId': selectedCar!.driverId,
      'status': 'pending',
      'pickupAddress': _pickupAddress,
      'dropoffAddress': _dropoffAddress,
      'pickupLat': pickupLocation!.latitude,
      'pickupLng': pickupLocation!.longitude,
      'dropoffLat': dropOffLocation!.latitude,
      'dropoffLng': dropOffLocation!.longitude,
      'price': fare.toStringAsFixed(0),
      'carModel': selectedCar!.model,
      'paymentStatus': paymentStatus,
      'paymentMethod': method,
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) => BookingConfirmContent(car: selectedCar!)));
  }



  @override
  Widget build(BuildContext context) {
    bool isWide = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      body: Stack(
        children: [
          _buildMap(),
          isWide ? _buildWebPanel() : _buildMobilePanel(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentCenter,
        initialZoom: 14,
        onTap: (tapPos, point) => _updateLocationState(point, isSelectingPickup),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.prasannata.sajilo_ride',
        ),
        if (routePoints.isNotEmpty) PolylineLayer(
            polylines: [Polyline(points: routePoints, strokeWidth: 5, color: Colors.blueAccent)]),
        MarkerLayer(markers: [
          if (pickupLocation != null) Marker(point: pickupLocation!,
              child: const Icon(Icons.my_location, color: Colors.green, size: 30)),
          if (dropOffLocation != null) Marker(point: dropOffLocation!, child: const Icon(Icons.location_on, color: Colors.red, size: 40)),
        ]),
      ],
    );
  }

  Widget _buildWebPanel() {
    return Positioned(
      right: 20, top: 20, bottom: 20,
      child: Container(width: 450, decoration: _panelDecoration(), child: _buildBookingContent()),
    );
  }

  Widget _buildMobilePanel() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: _panelDecoration(isMobile: true),
        child: _buildBookingContent(),
      ),
    );
  }

  BoxDecoration _panelDecoration({bool isMobile = false}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: isMobile ? const BorderRadius.vertical(top: Radius.circular(30)) : BorderRadius.circular(20),
      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15, spreadRadius: 5)],
    );
  }

  Widget _buildBookingContent() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Where are you going?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _locationTile(Icons.circle, Colors.green, "Pickup", _pickupAddress, isSelectingPickup, () => setState(() => isSelectingPickup = true)),
          const SizedBox(height: 12),
          _locationTile(Icons.location_on, Colors.red, "Drop-off", _dropoffAddress, !isSelectingPickup, () => setState(() => isSelectingPickup = false)),
          const Divider(height: 40),
          Expanded(child: _buildRideSelector()),
          if (distance > 0 && selectedCar != null) _buildFareFooter(),
        ],
      ),
    );
  }

  Widget _locationTile(IconData icon, Color color, String label, String address, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: active ? Colors.orange.withValues(alpha: 0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? Colors.orange : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 15),
            Expanded(child: Text(address, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.bold : FontWeight.normal))),
          ],
        ),
      ),
    );
  }

  Widget _buildRideSelector() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('drivers').snapshots(),
      builder: (context, snapshot) {
        List<CarModel> liveCars = [];
        if (snapshot.hasData) {
          liveCars = snapshot.data!.docs.map((doc) {
            var d = doc.data() as Map<String, dynamic>;
            return CarModel(model: d['carModel'] ?? "Car", distance: 0, pricePerHour: 45, fuelCapacity: 0, image: d['carImage'] ?? "", driverId: doc.id);
          }).toList();
        }
        final all = [...liveCars, ...carList];
        return ListView.separated(
          itemCount: all.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            bool isSel = selectedCar?.driverId == all[index].driverId;
            return ListTile(
              onTap: () => setState(() {
                selectedCar = all[index];
                if (distance > 0) fare = distance * all[index].pricePerHour;
              }),
              leading: CircleAvatar(radius: 25, backgroundImage: all[index].image.startsWith('http') ? NetworkImage(all[index].image) : AssetImage(all[index].image) as ImageProvider),
              title: Text(all[index].model, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("⚡ Close by • 4 Seats"),
              trailing: Text("Rs ${(distance * all[index].pricePerHour).toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold)),
              selected: isSel,
              selectedTileColor: Colors.orange.withValues(alpha:0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSel ? Colors.orange : Colors.transparent)),
            );
          },
        );
      },
    );
  }

   Widget _buildFareFooter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 30),

        const Text("Payment Method",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Row(
          children: [
            _paymentChip("Cash", Icons.payments_outlined),
            const SizedBox(width: 12),
            _paymentChip("eSewa", Icons.account_balance_wallet_outlined),
          ],
        ),

        const SizedBox(height: 25),


        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => selectedPayment == "eSewa"
                ? _processEsewaSDKPayment()
                : _confirmBooking(),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bolt, color: Colors.orangeAccent),
                const SizedBox(width: 8),
                Text(
                  "CONFIRM ${selectedCar!.model.toUpperCase()}",
                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _paymentChip(String title, IconData icon) {
    bool isSelected = selectedPayment == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedPayment = title),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            // When selected, it turns black like Uber
            color: isSelected ? Colors.orangeAccent: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.orangeAccent: Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : Colors.black54,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


