import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:esewa_flutter_sdk/esewa_flutter_sdk.dart';
import 'package:esewa_flutter_sdk/esewa_config.dart';
import 'package:esewa_flutter_sdk/esewa_payment.dart';
import 'package:esewa_flutter_sdk/esewa_payment_success_result.dart';
import 'package:sajilo_ride/data/model/car_model.dart';
import 'package:sajilo_ride/screens/passenger/booking_confirm.dart';
import '../../auth/auth_provider.dart';

class CarDetailPage extends StatefulWidget {
  final CarModel car;
  final LatLng pickupLocation;

  const CarDetailPage({super.key, required this.car, required this.pickupLocation});

  @override
  State<CarDetailPage> createState() => _CarDetailPageState();
}

class _CarDetailPageState extends State<CarDetailPage> {
  String selectedPayment = "Cash";
  static const String clientId = "JB0BBQ4aD0UqIThFJwAKBgAXEUkEGQUBBAwdOgABHD4DChwUAB0R";
  static const String secretKey= "BhwIWQQADhIYSxILExMcAgFXFhcOBwAKBgAXEQ==";

  // --- ESEWA SDK PAYMENT METHOD ---
  void _processEsewaSDKPayment() {
    try {
      EsewaFlutterSdk.initPayment(
        esewaConfig: EsewaConfig(
          environment: Environment.test,
          clientId: clientId,
          secretId: secretKey,
        ),
        esewaPayment: EsewaPayment(
          productId: "ride_${DateTime.now().millisecondsSinceEpoch}",
          productName: widget.car.model,
          productPrice: widget.car.pricePerHour.toString(),
          callbackUrl: '',
        ),
        onPaymentSuccess: (EsewaPaymentSuccessResult data) {
          debugPrint(":::SUCCESS::: => $data");
          _saveBookingToFirestore(paymentStatus: "paid", method: "eSewa");
        },
        onPaymentFailure: (data) {
          debugPrint(":::FAILURE::: => $data");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Payment Failed. Try again.")),
          );
        },
        onPaymentCancellation: (data) {
          debugPrint(":::CANCELLATION::: => $data");
        },
      );
    } catch (e) {
      debugPrint("EXCEPTION : ${e.toString()}");
    }
  }

  // --- SAVE TO FIRESTORE ---
  Future<void> _saveBookingToFirestore({required String paymentStatus, required String method}) async {
    final authProvider = Provider.of<AuthProviderMethod>(context, listen: false);
    final userId = authProvider.user?.uid;
    if (userId == null) return;

    // Show Loading
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));

    try {
      await FirebaseFirestore.instance.collection('bookings').add({
        'passengerId': userId,
        'carModel': widget.car.model,
        'price': widget.car.pricePerHour,
        'status': 'pending',
        'paymentMethod': method,
        'paymentStatus': paymentStatus,
        'timestamp': FieldValue.serverTimestamp(),
        'pickupLat': widget.pickupLocation.latitude,
        'pickupLng': widget.pickupLocation.longitude,
        'carImage': widget.car.image,
      });

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      Navigator.push(context, MaterialPageRoute(builder: (context) => BookingConfirmContent(car: widget.car)));
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.car.model),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(widget.car.image, height: 250, width: double.infinity, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.car.model, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                      Text('\$${widget.car.pricePerHour}/hr', style: const TextStyle(fontSize: 22, color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Pickup Point', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    height: 180,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: widget.pickupLocation,
                          initialZoom: 15.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.prasannata.sajilo_ride',
                          ),
                          MarkerLayer(markers: [
                            Marker(point: widget.pickupLocation, child: const Icon(Icons.location_on, color: Colors.red, size: 35)),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Select Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _paymentOption("Cash", Icons.money),
                      const SizedBox(width: 12),
                      _paymentOption("eSewa", Icons.account_balance_wallet),
                    ],
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          width: double.infinity, height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedPayment == "eSewa" ? Colors.green : Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (selectedPayment == "eSewa") {
                _processEsewaSDKPayment(); // Calls SDK
              } else {
                _saveBookingToFirestore(paymentStatus: "unpaid", method: "Cash");
              }
            },
            child: Text(
              selectedPayment == "eSewa" ? "Pay via eSewa SDK" : "Confirm Booking (Cash)",
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }

  Widget _paymentOption(String title, IconData icon) {
    bool isSelected = selectedPayment == title;
    return GestureDetector(
      onTap: () => setState(() => selectedPayment = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? (title == "eSewa" ? Colors.green : Colors.orange) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.black54),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}




/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Added for eSewa
import 'package:sajilo_ride/data/model/car_model.dart';
import 'package:sajilo_ride/screens/passenger/booking_confirm.dart';
import '../../auth/auth_provider.dart';

class CarDetailPage extends StatefulWidget {
  final CarModel car;
  final LatLng pickupLocation;

  const CarDetailPage({super.key, required this.car, required this.pickupLocation});

  @override
  State<CarDetailPage> createState() => _CarDetailPageState();
}

class _CarDetailPageState extends State<CarDetailPage> {
  String selectedPayment = "Cash";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.car.model),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Car Image
            Image.asset(widget.car.image, height: 250, width: double.infinity, fit: BoxFit.cover),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.car.model, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                      Text('\$${widget.car.pricePerHour}/hr', style: const TextStyle(fontSize: 22, color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. Map Section (Preserved as requested)
                  const Text('Pickup Point', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    height: 180,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade300)
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: widget.pickupLocation,
                          initialZoom: 15.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.prasannata.sajilo_ride',
                          ),
                          MarkerLayer(markers: [
                            Marker(
                                point: widget.pickupLocation,
                                child: const Icon(Icons.location_on, color: Colors.red, size: 35)
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text('Select Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _paymentOption("Cash", Icons.money),
                      const SizedBox(width: 12),
                      _paymentOption("eSewa", Icons.account_balance_wallet),
                    ],
                  ),
                  const SizedBox(height: 100), // Space for floating button
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedPayment == "eSewa" ? Colors.green : Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (selectedPayment == "eSewa") {
                _processEsewaPayment();
              } else {
                _saveBookingToFirestore(paymentStatus: "unpaid", method: "Cash");
              }
            },
            child: Text(
              selectedPayment == "eSewa" ? "Pay via eSewa" : "Confirm Booking (Cash)",
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }

  // --- ESEWA PAYMENT FLOW (Optimized for Mobile Demo) ---
  Future<void> _processEsewaPayment() async {
    // --- ESEWA PAYMENT FLOW
    // 1. Show Connecting Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.green),
            const SizedBox(height: 20),
            Image.network('https://esp.com.np/wp-content/uploads/2023/02/esewa-logo.png', height: 40),
            const SizedBox(height: 10),
            const Text("Connecting to eSewa...", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );

    // 2. Prepare eSewa UAT URL
    final String amount = widget.car.pricePerHour.toString();
    final String productId = "Ride_${DateTime.now().millisecondsSinceEpoch}";

    final Uri url = Uri.parse(
        "https://uat.esewa.com.np/epay/main"
            "?amt=$amount"
            "&pdc=0"
            "&psc=0"
            "&txAmt=0"
            "&tAmt=$amount"
            "&pid=$productId"
            "&scd=EPAYTEST"
            "&su=https://google.com"
            "&fu=https://google.com"
    );

    await Future.delayed(const Duration(seconds: 1));

    // GUARD: Check if the user is still on this screen before closing dialog
    if (!mounted) return;
    Navigator.pop(context); // Close dialog

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);

        // GUARD: Check again before proceeding to Firestore
        if (!mounted) return;
        _saveBookingToFirestore(paymentStatus: "paid", method: "eSewa");
      } else {
        // GUARD: Check before showing SnackBar
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch eSewa portal")),
        );
      }
    } catch (e) {
      // GUARD: Check before showing Error SnackBar
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // --- SAVE DATA TO FIRESTORE ---
  Future<void> _saveBookingToFirestore({required String paymentStatus, required String method}) async {
    final authProvider = Provider.of<AuthProviderMethod>(context, listen: false);
    final userId = authProvider.user?.uid;
    if (userId == null) return;

    // Show small saving indicator
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator())
    );

    try {
      await FirebaseFirestore.instance.collection('bookings').add({
        'passengerId': userId,
        'carModel': widget.car.model,
        'price': widget.car.pricePerHour,
        'status': 'pending',
        'paymentMethod': method,
        'paymentStatus': paymentStatus,
        'timestamp': FieldValue.serverTimestamp(),
        'pickupLat': widget.pickupLocation.latitude,
        'pickupLng': widget.pickupLocation.longitude,
        'carImage': widget.car.image,
      });

      if (!mounted) return;
      Navigator.pop(context); // Close saving indicator

      // Navigate to Final Success Screen
      Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => BookingConfirmContent(car: widget.car))
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Widget _paymentOption(String title, IconData icon) {
    bool isSelected = selectedPayment == title;
    return GestureDetector(
      onTap: () => setState(() => selectedPayment = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? (title == "eSewa" ? Colors.green : Colors.orange) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.black54),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

*/

/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:sajilo_ride/data/model/car_model.dart';
import 'package:sajilo_ride/screens/passenger/booking_confirm.dart';
import '../../auth/auth_provider.dart';

class CarDetailPage extends StatefulWidget {
  final CarModel car;
  final LatLng pickupLocation;

  const CarDetailPage({super.key, required this.car, required this.pickupLocation});

  @override
  State<CarDetailPage> createState() => _CarDetailPageState();
}

class _CarDetailPageState extends State<CarDetailPage> {
  String selectedPayment = "Cash";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.car.model),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Image
            Image.asset(widget.car.image, height: 250, width: double.infinity, fit: BoxFit.cover),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.car.model, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                      Text('\$${widget.car.pricePerHour}/hr', style: const TextStyle(fontSize: 22, color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. Map Section
                  const Text('Pickup Point', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    height: 180,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: widget.pickupLocation,
                          initialZoom: 15.0,
                        ),
                        children: [
                          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.prasannata.sajilo_ride',),
                          MarkerLayer(markers: [
                            Marker(point: widget.pickupLocation, child: const Icon(Icons.location_on, color: Colors.red, size: 35)),
                          ]),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text('Select Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _paymentOption("Cash", Icons.money),
                      const SizedBox(width: 12),
                      _paymentOption("eSewa", Icons.account_balance_wallet),
                    ],
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedPayment == "eSewa" ? Colors.green : Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (selectedPayment == "eSewa") {
                _processEsewaPayment();
              } else {
                _saveBookingToFirestore(paymentStatus: "unpaid", method: "Cash");
              }
            },
            child: Text(
              selectedPayment == "eSewa" ? "Pay via eSewa" : "Confirm Booking (Cash)",
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }

  // --- ESEWA PAYMENT FLOW (Real Data Flow) ---
  void _processEsewaPayment() {
    // 1. Show a professional "Connecting to eSewa" overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.green),
            const SizedBox(height: 20),
            Image.network('https://esp.com.np/wp-content/uploads/2023/02/esewa-logo.png', height: 40),
            const SizedBox(height: 10),
            const Text("Connecting to eSewa...", style: TextStyle(fontWeight: FontWeight.bold)),
            const Text("Please do not close the app", style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );

    // 2. Wait 2 seconds (Simulating the API call)
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pop(context); // Close the loading dialog

      // 3. Directly trigger the SUCCESS flow and save "Paid" to Firestore
      _saveBookingToFirestore(paymentStatus: "paid", method: "eSewa");
    });
  }

 /* void _processEsewaPayment() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("eSewa Payment Portal", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
            const Divider(),
            const SizedBox(height: 20),
            ListTile(
              title: const Text("Amount to Pay"),
              trailing: Text("\$${widget.car.pricePerHour}", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const TextField(decoration: InputDecoration(labelText: "eSewa ID (Mobile Number)")),
            const TextField(obscureText: true, decoration: InputDecoration(labelText: "MPIN")),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                onPressed: () {
                  Navigator.pop(context); // Close "Portal"
                  _saveBookingToFirestore(paymentStatus: "paid", method: "eSewa");
                },
                child: const Text("PROCEED TO PAY", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }*/

  // --- CORE DATA FLOW: SAVING TO FIRESTORE ---
  Future<void> _saveBookingToFirestore({required String paymentStatus, required String method}) async {
    final authProvider = Provider.of<AuthProviderMethod>(context, listen: false);
    final userId = authProvider.user?.uid;
    if (userId == null) return;

    // Show Loading
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));

    try {
      // 1. Create a Booking Document
      await FirebaseFirestore.instance.collection('bookings').add({
        'passengerId': userId,
        'carModel': widget.car.model,
        'price': widget.car.pricePerHour,
        'status': 'pending', // Pending driver approval
        'paymentMethod': method,
        'paymentStatus': paymentStatus,
        'timestamp': FieldValue.serverTimestamp(),
        'pickupLat': widget.pickupLocation.latitude,
        'pickupLng': widget.pickupLocation.longitude,
        'carImage': widget.car.image,
      });

      if (!mounted) return;
      Navigator.pop(context); // Remove loading

      // 2. Navigate to Confirmation Screen
      Navigator.push(context, MaterialPageRoute(builder: (context) => BookingConfirmContent(car: widget.car)));
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Remove loading
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Firestore Error: $e")));
    }
  }

  Widget _paymentOption(String title, IconData icon) {
    bool isSelected = selectedPayment == title;
    return GestureDetector(
      onTap: () => setState(() => selectedPayment = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? (title == "eSewa" ? Colors.green : Colors.orange) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.black54),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}





/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart'; // Add this
import 'package:sajilo_ride/data/model/car_model.dart';
import 'package:sajilo_ride/screens/passenger/booking_confirm.dart';
import '../../auth/auth_provider.dart';

class CarDetailPage extends StatefulWidget {
  final CarModel car;
  final LatLng pickupLocation;

  const CarDetailPage({super.key, required this.car, required this.pickupLocation});

  @override
  State<CarDetailPage> createState() => _CarDetailPageState();
}

class _CarDetailPageState extends State<CarDetailPage> {
  String selectedPayment = "Cash";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.car.model),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(widget.car.image, height: 250, width: double.infinity, fit: BoxFit.cover),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.car.model, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                      Text('\$${widget.car.pricePerHour}/hr', style: const TextStyle(fontSize: 22, color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Pickup Point', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    height: 180,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: widget.pickupLocation,
                          initialZoom: 15.0,
                          interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.sajilo_ride.app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: widget.pickupLocation,
                                child: const Icon(Icons.location_on, color: Colors.red, size: 35),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Select Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _paymentOption("Cash", Icons.money),
                      const SizedBox(width: 12),
                      _paymentOption("eSewa", Icons.account_balance_wallet),
                    ],
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedPayment == "eSewa" ? Colors.green : Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (selectedPayment == "eSewa") {
                _payWithEsewaManual();
              } else {
                _saveBookingToFirestore("unpaid");
              }
            },
            child: Text(
              selectedPayment == "eSewa" ? "Pay via eSewa" : "Confirm Booking (Cash)",
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }

  // MANUAL ESEWA LAUNCHER (Works on Windows/Chrome/Mobile)
  Future<void> _payWithEsewaManual() async {
    final String amount = widget.car.pricePerHour.toString();
    final String productId = "ride_${DateTime.now().millisecondsSinceEpoch}";

    // We use the Version 1 Test API because it allows GET requests (URL-based)
    // This is perfect for a Windows/Web Demo
    final Uri url = Uri.parse(
        "https://uat.esewa.com.np/epay/main"
            "?amt=$amount"
            "&pdc=0"
            "&psc=0"
            "&txAmt=0"
            "&tAmt=$amount"
            "&pid=$productId"
            "&scd=EPAYTEST"
            "&su=https://google.com" // Success redirect
            "&fu=https://google.com"  // Failure redirect
    );

    try {
      // mode: LaunchMode.externalApplication opens the actual browser
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);

        if (!mounted) return;

        // In a demo, we assume they will complete the payment in the browser
        // and immediately save the booking in our app.
        _saveBookingToFirestore("paid");
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open browser. Please check settings.")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }


  Future<void> _saveBookingToFirestore(String paymentStatus) async {
    final authProvider = Provider.of<AuthProviderMethod>(context, listen: false);
    final userId = authProvider.user?.uid;
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance.collection('bookings').add({
        'passengerId': userId,
        'carModel': widget.car.model,
        'price': widget.car.pricePerHour,
        'status': 'pending',
        'paymentMethod': selectedPayment,
        'paymentStatus': paymentStatus,
        'timestamp': FieldValue.serverTimestamp(),
        'pickupLat': widget.pickupLocation.latitude,
        'pickupLng': widget.pickupLocation.longitude,
        'carImage': widget.car.image,
      });

      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => BookingConfirmContent(car: widget.car)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Widget _paymentOption(String title, IconData icon) {
    bool isSelected = selectedPayment == title;
    return GestureDetector(
      onTap: () => setState(() => selectedPayment = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? (title == "eSewa" ? Colors.green : Colors.orange) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.black54),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
*/

*/