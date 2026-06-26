import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:esewa_flutter_sdk/esewa_flutter_sdk.dart';
import 'package:esewa_flutter_sdk/esewa_config.dart';
import 'package:esewa_flutter_sdk/esewa_payment.dart';
import 'package:sajilo_ride/core/constants/payment_config.dart';
import 'package:sajilo_ride/data/model/car_model.dart';
import 'package:sajilo_ride/screens/passenger/booking_confirm.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../navbar/navbar_config.dart';
import '../../widgets/booking_components.dart';

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

  List<CarModel> liveCars = [];
  StreamSubscription<QuerySnapshot>? _driverSubscription;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _listenToLiveDrivers();
  }

  @override
  void dispose() {
    _driverSubscription?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _listenToLiveDrivers() {
    _driverSubscription = FirebaseFirestore.instance
        .collection('drivers')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .listen((snapshot) {
      List<CarModel> updatedCars = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();

        if (data['latitude'] != null && data['longitude'] != null) {
          try {
            updatedCars.add(CarModel.fromMap(data, doc.id));
          } catch (e) {
            debugPrint("Error parsing driver document ${doc.id}: $e");
          }
        }
      }

      setState(() {
        liveCars = updatedCars;

        if (selectedCar == null && updatedCars.isNotEmpty) {
          selectedCar = updatedCars.first;
        } else if (selectedCar != null) {
          bool stillOnline = updatedCars.any((car) => car.driverId == selectedCar!.driverId);
          if (stillOnline) {
            selectedCar = updatedCars.firstWhere((car) => car.driverId == selectedCar!.driverId);
          } else {
            selectedCar = updatedCars.isNotEmpty ? updatedCars.first : null;
          }
        }
      });
    }, onError: (error) => debugPrint("Driver Stream Error: $error"));
  }

  // --- CORE SYSTEM FUNCTIONALITIES (OSRM, Geo, Payments, FCM) ---

  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        _showErrorSnackBar('Location permissions permanently denied. Enable them in settings.');
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final current = LatLng(position.latitude, position.longitude);
      setState(() {
        pickupLocation = current;
        _currentCenter = current;
      });
      _mapController.move(current, 15);
      await _getAddress(current, true);
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  void _updateLocationState(LatLng pos, bool isPickup) {
    setState(() {
      if (isPickup) {
        pickupLocation = pos;
      } else {
        dropOffLocation = pos;
      }
      routePoints = [];
      fare = 0;
    });

    if (pickupLocation != null && dropOffLocation != null) {
      final bounds = LatLngBounds.fromPoints([pickupLocation!, dropOffLocation!]);
      _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
      _getRoute();
    } else {
      _mapController.move(pos, 14);
    }
    _getAddress(pos, isPickup);
  }

  Future<void> _getAddress(LatLng position, bool isPickup) async {
    try {
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}');
      final response = await http.get(url, headers: {'User-Agent': 'com.prasannata.sajilo_ride'});
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
    } catch (e) {
      debugPrint("Geo Error: $e");
    }
  }

  Future<void> _getRoute() async {
    final url = Uri.parse("https://router.project-osrm.org/route/v1/driving/${pickupLocation!.longitude},${pickupLocation!.latitude};${dropOffLocation!.longitude},${dropOffLocation!.latitude}?overview=full&geometries=geojson");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final routes = data['routes'] as List;
        if (routes.isEmpty) return;
        final coords = routes[0]['geometry']['coordinates'];
        setState(() {
          routePoints = coords.map<LatLng>((c) => LatLng(c[1], c[0])).toList();
          distance = routes[0]['distance'] / 1000.0;
          if (selectedCar != null) fare = distance * selectedCar!.pricePerKm;
        });
      }
    } catch (e) {
      debugPrint("Route error: $e");
    }
  }

  void _processEsewaSDKPayment() {
    try {
      EsewaFlutterSdk.initPayment(
        esewaConfig: EsewaConfig(
            environment: Environment.test,
            clientId: PaymentConfig.clientId,
            secretId: PaymentConfig.secretKey
        ),
        esewaPayment: EsewaPayment(
          productId: "ride_${DateTime.now().millisecondsSinceEpoch}",
          productName: selectedCar!.model,
          productPrice: fare.toStringAsFixed(0),
          callbackUrl: '',
        ),
        onPaymentSuccess: (data) => _confirmBooking(paymentStatus: "paid", method: "eSewa"),
        onPaymentFailure: (data) => _showErrorSnackBar("Payment Failed"),
        onPaymentCancellation: (data) => debugPrint("Cancelled"),
      );
    } catch (e) {
      debugPrint("eSewa Error: $e");
    }
  }

  Future<void> payWithEsewaWeb(double amount) async {
    final pid = DateTime.now().millisecondsSinceEpoch.toString();
    final url = Uri.parse("https://uat.esewa.com.np/epay/main?amt=${amount.toStringAsFixed(0)}&pdc=0&psc=0&txAmt=0&tAmt=${amount.toStringAsFixed(0)}&pid=$pid&scd=EPAYTEST&su=https://your-success-url.com&fu=https://your-failure-url.com");

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      _showErrorSnackBar('Could not open eSewa portal');
    }
  }

  Future<void> _sendNotificationToDriver(String driverId, String pickupAddr, String tripFare) async {
    try {
      DocumentSnapshot driverDoc = await FirebaseFirestore.instance.collection('drivers').doc(driverId).get();
      if (!driverDoc.exists) return;

      var driverData = driverDoc.data() as Map<String, dynamic>;
      String? deviceToken = driverData['deviceToken'];
      if (deviceToken == null || deviceToken.isEmpty) return;

      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final serviceAccountCredentials = auth.ServiceAccountCredentials.fromJson({
        "type": "service_account",
        "project_id": dotenv.get("FCM_PROJECT_ID"),
        "private_key_id": dotenv.get("FCM_PRIVATE_KEY_ID"),
        "private_key": dotenv.get("FCM_PRIVATE_KEY").replaceAll(r'\n', '\n'),
        "client_email": dotenv.get("FCM_CLIENT_EMAIL"),
      });

      final client = await auth.clientViaServiceAccount(serviceAccountCredentials, scopes);
      final String accessToken = client.credentials.accessToken.data;

      await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/${dotenv.get("FCM_PROJECT_ID")}/messages:send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'message': {
            'token': deviceToken,
            'notification': {
              'title': '🚖 New Booking Request!',
              'body': 'Pickup: $pickupAddr\nFare: Rs. $tripFare',
            },
            'android': {
              'priority': 'high',
              'notification': {'sound': 'default', 'channel_id': 'high_importance_channel'},
            },
          }
        }),
      );
      client.close();
    } catch (e) {
      debugPrint("Notification Delivery Error: $e");
    }
  }

  Future<void> _confirmBooking({String paymentStatus = "unpaid", String method = "Cash"}) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      final String targetedDriverId = selectedCar!.driverId;
      final String finalFareString = fare.toStringAsFixed(0);

      await FirebaseFirestore.instance.collection('bookings').add({
        'passengerId': userId,
        'driverId': targetedDriverId,
        'status': 'pending',
        'pickupAddress': _pickupAddress,
        'dropoffAddress': _dropoffAddress,
        'pickupLat': pickupLocation!.latitude,
        'pickupLng': pickupLocation!.longitude,
        'dropoffLat': dropOffLocation!.latitude,
        'dropoffLng': dropOffLocation!.longitude,
        'fare': finalFareString,
        'model': selectedCar!.model,
        'paymentStatus': paymentStatus,
        'paymentMethod': method,
        'timestamp': FieldValue.serverTimestamp(),
        'otp': (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString(),
      });

      await _sendNotificationToDriver(targetedDriverId, _pickupAddress, finalFareString);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Booking Confirmed 🚖"), backgroundColor: Colors.green, duration: Duration(seconds: 1)),
      );

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingConfirmContent(
            car: selectedCar!,
            userRole: UserRole.passenger,
            fare: fare,
            distance: distance,
          ),
        ),
      );
    } catch (e) {
      if (mounted) _showErrorSnackBar("Booking failed: $e");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }

  // --- COMPONENT MASTER LAYOUT ARCHITECTURE ---
  @override
  Widget build(BuildContext context) {
    bool isWide = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
        if (routePoints.isNotEmpty)
          PolylineLayer(polylines: [Polyline(points: routePoints, strokeWidth: 5, color: Colors.blueAccent)]),
        MarkerLayer(
          markers: [
            if (pickupLocation != null)
              Marker(point: pickupLocation!, child: const Icon(Icons.my_location, color: Colors.green, size: 30)),
            if (dropOffLocation != null)
              Marker(point: dropOffLocation!, child: const Icon(Icons.location_on, color: Colors.red, size: 40)),
            ...liveCars.map((driver) => Marker(
              point: LatLng(driver.latitude, driver.longitude),
              width: 40, height: 40,
              child: GestureDetector(
                onTap: () => setState(() => selectedCar = driver),
                child: Icon(Icons.directions_car, color: Colors.orange.shade700, size: 30),
              ),
            )).toList(),
          ],
        ),
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
    bool showFooter = selectedCar != null && routePoints.isNotEmpty;
    double panelHeightFactor = showFooter ? 0.65 : 0.58;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: MediaQuery.of(context).size.height * panelHeightFactor,
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
          const SizedBox(height: 16),

          LocationInputField(
            icon: Icons.circle, color: Colors.green, label: "Pickup",
            address: _pickupAddress, active: isSelectingPickup,
            onTap: () => setState(() => isSelectingPickup = true),
          ),
          const SizedBox(height: 12),
          LocationInputField(
            icon: Icons.location_on, color: Colors.red, label: "Drop-off",
            address: _dropoffAddress, active: !isSelectingPickup,
            onTap: () => setState(() => isSelectingPickup = false),
          ),

          const Divider(height: 20),

          Expanded(
            child: NearByRideSelector(
              liveCars: liveCars,
              pickupLocation: pickupLocation,
              selectedCar: selectedCar,
              distance: distance,
              onCarSelected: (car, updatedFare) {
                setState(() {
                  selectedCar = car;
                  fare = updatedFare;
                });
              },
            ),
          ),

          if (selectedCar != null && routePoints.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: FareFooterSection(
                selectedCar: selectedCar!,
                selectedPayment: selectedPayment,
                fare: fare,
                pickupLocation: pickupLocation,
                dropOffLocation: dropOffLocation,
                onPaymentMethodChanged: (method) => setState(() => selectedPayment = method),
                onConfirmPressed: () {
                  if (selectedPayment == "eSewa") {
                    kIsWeb ? payWithEsewaWeb(fare) : _processEsewaSDKPayment();
                  } else {
                    _confirmBooking();
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}