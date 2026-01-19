import 'package:flutter/material.dart';
import 'package:sajilo_ride/data/model/car_model.dart'; // Make sure this path is correct

class CarDetailPage extends StatelessWidget {
  // This page requires a CarModel object to be passed to it.
  final CarModel car;

  // The constructor takes the required 'car' object.
  const CarDetailPage({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The AppBar shows the car's model and has a back button automatically.
      appBar: AppBar(
        title: Text(car.model),
        backgroundColor: Colors.transparent, // Makes it blend with the body
        elevation: 0,
        foregroundColor: Colors.black, // Ensures the back button is visible
      ),
      body: SingleChildScrollView(
        // Makes the page scrollable if content is too long for the screen.
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. Car Image ---
              // Uses ClipRRect to give the image nice rounded corners.
              ClipRRect(
                borderRadius: BorderRadius.circular(15.0),
                child: Image.asset(
                  car.image,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),

              // --- 2. Car Title and Price ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Car Model Name
                  Expanded(
                    child: Text(
                      car.model,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Price per Hour
                  Text(
                    '\$${car.pricePerHour}/hr',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- 3. Specifications Section ---
              const Text(
                'Specifications',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              // This row displays key stats about the car.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSpecChip('Distance', '${car.distance} km'),
                  _buildSpecChip('Fuel', '${car.fuelCapacity} L'),
                  // You can add more specs to your CarModel and display them here
                  _buildSpecChip('Type', 'SUV'),
                ],
              ),
              const SizedBox(height: 24),

              // --- 4. Description Section ---
              const Text(
                'Description',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              // This is placeholder text. You could add a 'description' field to your CarModel.
              const Text(
                'A spacious and powerful SUV perfect for family trips and off-road adventures. Features include a premium sound system, panoramic sunroof, and advanced safety features for a secure and enjoyable ride.',
                style: TextStyle(fontSize: 16, color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 80), // Extra space to not overlap with button
            ],
          ),
        ),
      ),

      // --- 5. "Book Now" Button ---
      // This button is anchored to the bottom of the screen.
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: FloatingActionButton.extended(
            onPressed: () {
              // This is where you will add your booking logic.
              // For now, it just shows a confirmation message.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Booking for ${car.model} initiated!'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            backgroundColor: Colors.black,
            label: const Text(
              'Book This Ride Now',
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }

  // This is a helper widget to avoid repeating code for the spec chips.
  // It makes the main build method cleaner and easier to read.
  Widget _buildSpecChip(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}