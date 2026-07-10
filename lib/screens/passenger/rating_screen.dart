import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RatingScreen extends StatefulWidget {
  final String bookingId;
  final String driverId;
  const RatingScreen({super.key, required this.bookingId, required this.driverId});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a rating")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final driverRef = FirebaseFirestore.instance.collection('drivers').doc(widget.driverId);
      final bookingRef = FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final driverSnapshot = await transaction.get(driverRef);
        final bookingSnapshot = await transaction.get(bookingRef);

        if (!bookingSnapshot.exists) throw Exception("Booking not found.");
        if (!driverSnapshot.exists) throw Exception("Driver not found.");

        if (bookingSnapshot.data()?['status'] == 'reviewed') {
          throw Exception("This ride has already been rated.");
        }

        final currentRating = (driverSnapshot.data()?['averageRating'] ?? 0.0).toDouble();
        final totalRatings = (driverSnapshot.data()?['totalRatings'] ?? 0).toInt();

        final newTotalRatings = totalRatings + 1;
        final newAverage = ((currentRating * totalRatings) + _rating) / newTotalRatings;

        transaction.update(bookingRef, {
          'rating': _rating,
          'feedback': _feedbackController.text.trim(),
          'status': 'reviewed',
        });

        transaction.update(driverRef, {
          'averageRating': newAverage,
          'totalRatings': newTotalRatings,
          'totalRides': FieldValue.increment(1),
        });
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceAll("Exception: ", "")))
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: const Text("Rate Your Trip", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  const CircleAvatar(radius: 35, backgroundColor: Colors.orange, child: Icon(Icons.person, size: 40, color: Colors.white)),
                  const SizedBox(height: 15),

                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('drivers').doc(widget.driverId).get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text("Loading driver...", style: TextStyle(fontSize: 18));
                      }

                      // Check if document exists and has data
                      if (snapshot.hasData && snapshot.data!.exists) {
                        var driverData = snapshot.data!.data() as Map<String, dynamic>;

                        String driverName = driverData['driverName'] ?? 'Driver';
                        return Text("Rate your driver: $driverName", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
                      }

                      return const Text("Rate your driver", style: TextStyle(fontSize: 18));
                    },
                  ),
                  const SizedBox(height: 5),
                  const Text("How was your trip?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(index < _rating ? Icons.star : Icons.star_border, color: Colors.orange, size: 40),
                        onPressed: () => setState(() => _rating = index + 1),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _feedbackController,
                    maxLines: 4,
                    decoration: InputDecoration(
                        hintText: "Tell us about your experience...",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    height: 55,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitRating,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: _isSubmitting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("SUBMIT FEEDBACK", style: TextStyle(fontSize: 16, color:Colors.white,
                          fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}