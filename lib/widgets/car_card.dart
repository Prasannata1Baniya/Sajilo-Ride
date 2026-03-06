import 'package:flutter/material.dart';
import 'package:sajilo_ride/data/model/car_model.dart';
import 'package:sajilo_ride/utils/text_styles.dart';
import '../screens/passenger/car_detail_page.dart';

class CarCard extends StatelessWidget {
  final CarModel car;
  const CarCard({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // Navigate to the detail page when the card is tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CarDetailPage(car: car), // Pass the car data
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias, // Ensures the image respects the card's rounded corners
        color: Colors.white,
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch children to fill width
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Image.asset(
                car.image,
                fit: BoxFit.cover,
              ),
            ),

            // --- DETAILS SECTION ---
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(car.model, style: AppTextStyles.bodyTextBlack),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                    icon: Icons.gps_fixed,
                    label: 'Distance',
                    value: '${car.distance.toStringAsFixed(0)} km',
                  ),
                  _buildInfoRow(
                    icon: Icons.local_gas_station_outlined, // Better icon for fuel
                    label: 'Fuel',
                    value: '${car.fuelCapacity.toStringAsFixed(0)} L',
                  ),
                  _buildInfoRow(
                    icon: Icons.price_change_outlined, // Better icon for price
                    label: 'Price',
                    value: '\$${car.pricePerHour.toStringAsFixed(0)}/hr',
                  ),
                ],
              ),
            ),

            const Spacer(),

            // --- BOOKING BUTTON ---
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    elevation: 5,
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    )),
                // The onPressed logic is now handled by the InkWell wrapper
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CarDetailPage(car: car),
                    ),
                  );
                },
                child: const Center(
                    child: Text(
                      "View Details",
                      style: AppTextStyles.smallTextWhite,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.black54),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
