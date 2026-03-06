import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:esewa_flutter/esewa_flutter.dart'; // Official package
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sajilo_ride/data/model/car_model.dart';
import 'package:sajilo_ride/screens/passenger/booking_confirm.dart';
import '../../auth/auth_provider.dart';

class CarDetailPage extends StatefulWidget {
  final CarModel car;
  const CarDetailPage({super.key, required this.car});

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
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15.0),
                child: Image.asset(
                  widget.car.image,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.car.model, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  Text('\$${widget.car.pricePerHour}/hr', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Specifications', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSpecChip('Distance', '${widget.car.distance} km'),
                  _buildSpecChip('Fuel', '${widget.car.fuelCapacity} L'),
                  _buildSpecChip('Type', 'SUV'),
                ],
              ),
              const SizedBox(height: 24),

              // --- PAYMENT METHOD SELECTION ---
              const Text('Select Payment Method', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _paymentOption("Cash", Icons.money),
                  const SizedBox(width: 12),
                  _paymentOption("eSewa", Icons.account_balance_wallet),
                ],
              ),
              const SizedBox(height: 24),

              const Text('Description', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text(
                'A spacious and powerful SUV perfect for family trips. Secure and comfortable for all road conditions.',
                style: TextStyle(fontSize: 16, color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),

      // --- BOTTOM ACTION AREA ---
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: selectedPayment == "eSewa"
              ? _buildEsewaButton() // Show eSewa Button
              : _buildCashButton(), // Show Standard Button
        ),
      ),
    );
  }

  // --- ESEWA BUTTON (OFFICIAL WIDGET) ---
  Widget _buildEsewaButton() {
    return EsewaPayButton(
      paymentConfig: ESewaConfig.dev(
        amt: widget.car.pricePerHour.toDouble(), // amount
        pid: "ride_${DateTime.now().millisecondsSinceEpoch}", // product id
        su: 'https://developer.esewa.com.np/success', // success url
        fu: 'https://developer.esewa.com.np/failure', // failure url
      ),
      onSuccess: (result) async {
        // You can check result.productId if you need to log it
        debugPrint("eSewa Success for: ${result.productId}");
        _saveBookingToFirestore("paid");
      },
      onFailure: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("eSewa Error: $error"), backgroundColor: Colors.red),
          );
        }
      },
    );
  }

  // --- STANDARD CASH BUTTON ---
  Widget _buildCashButton() {
    return FloatingActionButton.extended(
      backgroundColor: Colors.black,
      onPressed: () => _saveBookingToFirestore("unpaid"),
      label: const Text(
        'Confirm Booking (Cash)',
        style: TextStyle(fontSize: 18, color: Colors.white),
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
          color: isSelected ? Colors.orange : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.orange : Colors.transparent, width: 2),
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
        'pickupLocation': 'Current Location',
        'carImage': widget.car.image,
      });

      if (mounted) {
        Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => BookingConfirmContent(car: widget.car))
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Widget _buildSpecChip(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 16, color: Colors.black54)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

