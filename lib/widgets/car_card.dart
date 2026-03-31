import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart'; // Ensure you have this import
import 'package:sajilo_ride/data/model/car_model.dart';
import 'package:sajilo_ride/utils/text_styles.dart';
import '../screens/passenger/car_detail_page.dart';

class CarCard extends StatelessWidget {
  final CarModel car;
  final LatLng pickupLocation;

  const CarCard({
    super.key,
    required this.car,
    required this.pickupLocation,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _navigateToDetails(context),
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1.5,
              child: car.image.startsWith('http')
                  ? Image.network(car.image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.directions_car, size: 50),
              )
                  : Image.asset(
                car.image,
                fit: BoxFit.cover,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    car.model,
                    style: AppTextStyles.bodyTextBlack,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  _buildInfoRow(
                    icon: Icons.gps_fixed,
                    label: 'Dist',
                    value: '${car.distance.toStringAsFixed(0)} km',
                  ),
                  _buildInfoRow(
                    icon: Icons.local_gas_station_outlined,
                    label: 'Fuel',
                    value: '${car.fuelCapacity.toStringAsFixed(0)} L',
                  ),
                  _buildInfoRow(
                    icon: Icons.price_change_outlined,
                    label: 'Price',
                    value: 'Rs ${car.pricePerHour.toStringAsFixed(0)}/hr',
                  ),
                ],
              ),
            ),

            // Use a bit of padding for the button
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8.0, vertical: 4.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  minimumSize: const Size(double.infinity, 36),
                  // Smaller height
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _navigateToDetails(context),
                child: const Text(
                  "View Details",
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToDetails(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CarDetailPage(
              car: car,
              pickupLocation: pickupLocation,
            ),
      ),
    );
  }

  Widget _buildInfoRow(
      {required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2.0),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.black54),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
