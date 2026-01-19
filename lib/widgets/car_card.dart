import 'package:flutter/material.dart';
import 'package:sajilo_ride/data/model/car_model.dart';
import 'package:sajilo_ride/utils/text_styles.dart';
import '../screens/passenger/car_detail_page.dart';

class CarCard extends StatelessWidget {
  final CarModel car;
  const CarCard({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    // InkWell makes the whole card tappable for navigation
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
            // --- RESPONSIVE IMAGE ---
            // The image no longer has a fixed height. It's flexible.
            // Using AspectRatio is great for maintaining shape.
            AspectRatio(
              aspectRatio: 16 / 10, // A common aspect ratio for images
              child: Image.asset(
                car.image,
                fit: BoxFit.cover, // Ensures the image covers the area without distortion
              ),
            ),

            // --- DETAILS SECTION ---
            // Padding contains the text content
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

            // Pushes the button to the bottom if there's extra space
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
                      style: AppTextStyles.bodyTextWhite,
                    )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to create consistent info rows and avoid repeated code
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



/*import 'package:flutter/material.dart';

import 'package:sajilo_ride/data/model/car_model.dart';
import 'package:sajilo_ride/utils/text_styles.dart';

class CarCard extends StatelessWidget {
  final CarModel car;
   const CarCard({super.key, required this.car});


  @override
  Widget build(BuildContext context) {
  
    //final ht =MediaQuery.of(context).size.height >600;
   // final isHt = ht>600;

    //final wt =MediaQuery.of(context).size.width;
    //final isWt = wt>600;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        color: Colors.white,
        elevation:5,
        child: Container(
          width: 200,
          margin: const EdgeInsets.all(12),
          child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
            children:[

              Image.asset(car.image, height: 200,),
              const SizedBox(height:10),
              Text(car.model, style: AppTextStyles.bodyTextBlack),

              const SizedBox(height: 10,),
                Row(
                  children: [
                    const Icon(Icons.gps_fixed),
                    Text('Distance: ${car.distance.toStringAsFixed(0)} km'),
                  ],
                ),

              Row(
                children: [
                  const Icon(Icons.heat_pump_outlined),
                  Text('Price: ${car.pricePerHour.toStringAsFixed(0)} km'),
                ],
              ),

                Row(
                  children: [
                    const Icon(Icons.heat_pump_outlined),
                    Text('Fuel Capacity: ${car.fuelCapacity.toStringAsFixed(0)} km'),
                  ],
                ),
              const SizedBox(height: 10,),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                 elevation: 5,
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  )
                ),
                  onPressed: (){

              },
                  child:const Center(
                      child: Text("Book this Car",style: AppTextStyles.bodyTextWhite,)
                  ),
              ),

            ]
          ),
        ),
      ),
    );
  }
}
*/