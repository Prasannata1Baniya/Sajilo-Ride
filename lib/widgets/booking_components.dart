import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../data/model/car_model.dart';
import '../screens/passenger/car_driver_detail.dart';


// COMPONENT 1: LOCATION INPUT ACTION FIELD
class LocationInputField extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String address;
  final bool active;
  final VoidCallback onTap;

  const LocationInputField({
    super.key, required this.icon, required this.color, required this.label,
    required this.address, required this.active, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active ? Colors.orange.withValues(alpha: 0.08) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? Colors.orange : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                address,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.bold : FontWeight.normal),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


//  GEOLOCATION DRIVER SELECTOR
class NearByRideSelector extends StatelessWidget {
  final List<CarModel> liveCars;
  final LatLng? pickupLocation;
  final CarModel? selectedCar;
  final double tripDistanceKm;
  final Function(CarModel car, double calculatedFare) onCarSelected;

  const NearByRideSelector({
    super.key,required this.liveCars, required this.pickupLocation, required this.selectedCar,
    required this.tripDistanceKm, required this.onCarSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (pickupLocation == null) {
      return const Center(child: Text("Please select a pickup point"));
    }

    String passengerHash = GeoHasher().encode(pickupLocation!.longitude, pickupLocation!.latitude);
    String searchPrefix = passengerHash.substring(0, 4);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('drivers')
          .where('isOnline', isEqualTo: true)
          .where('location.geohash', isGreaterThanOrEqualTo: searchPrefix)
          .where('location.geohash', isLessThanOrEqualTo: '$searchPrefix\uf8ff')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.orange));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No drivers nearby 📍"));
        }

        List<CarModel> rawDrivers = snapshot.data!.docs.map((doc) {
          return CarModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        List<CarModel> nearbyCars = rawDrivers.where((driver) {
          double distInMeters = Geolocator.distanceBetween(
            pickupLocation!.latitude, pickupLocation!.longitude,
            driver.latitude, driver.longitude,
          );
          return distInMeters <= 5000;
        }).toList();

        if (nearbyCars.isEmpty) {
          return const Center(child: Text("Drivers are nearby, but too far for pickup."));
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: nearbyCars.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final currentCar = nearbyCars[index];
            bool isSel = selectedCar?.driverId == currentCar.driverId;

            double currentFare = tripDistanceKm > 0
                ? (tripDistanceKm * currentCar.pricePerKm)
                : 0;

            return ListTile(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CarDriverDetailPage(car: currentCar)),
                );

                if (result == true) {
                  onCarSelected(currentCar, currentFare);
                }
              },
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey[200],
                backgroundImage: (currentCar.image.isNotEmpty && currentCar.image.startsWith('http'))
                    ? NetworkImage(currentCar.image)
                    : const AssetImage('assets/images/car1.jpg') as ImageProvider,
              ),
              title: Row(
                children: [
                  Expanded(
                      child: Text(currentCar.model,
                          style: const TextStyle(fontWeight: FontWeight.bold,overflow: TextOverflow.ellipsis,))),
                  const SizedBox(width: 8),
                  _buildFuelBadge(currentCar.vehicleType),
                ],
              ),
              subtitle: Text("⚡ ${currentCar.carNumber} • 4 Seats"),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    tripDistanceKm > 0 ? "Rs ${currentFare.toStringAsFixed(0)}" : "Fare Info",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16),
                  ),
                  if (tripDistanceKm > 0)
                    //Text("${currentCar.pricePerKm}/km", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    Text(
                      "${tripDistanceKm.toStringAsFixed(1)} km",
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),),
                ],
              ),
              selected: isSel,
              selectedTileColor: Colors.orange.withValues(alpha: 0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isSel ? Colors.orange : Colors.transparent, width: 2),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFuelBadge(String? type) {
    final fuelType = type?.toLowerCase() ?? 'petrol';
    bool isEV = fuelType == 'electric';
    Color badgeColor = isEV ? Colors.green : Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        fuelType.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
      ),
    );
  }
}


// COMPONENT 3: FARE FOOTER & GATEWAY ACTION
class FareFooterSection extends StatelessWidget {
  final CarModel selectedCar;
  final String selectedPayment;
  final double fare;
  final LatLng? pickupLocation;
  final LatLng? dropOffLocation;
  final Function(String paymentMethod) onPaymentMethodChanged;
  final VoidCallback onConfirmPressed;

  const FareFooterSection({
    super.key, required this.selectedCar, required this.selectedPayment,
    required this.fare, required this.pickupLocation, required this.dropOffLocation,
    required this.onPaymentMethodChanged, required this.onConfirmPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 30),
        const Text("Payment Method", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildPaymentChip("Cash", Icons.payments_outlined),
            const SizedBox(width: 12),
            _buildPaymentChip("eSewa", Icons.account_balance_wallet_outlined),
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
            onPressed: (pickupLocation == null || dropOffLocation == null) ? null : onConfirmPressed,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.bolt, color: Colors.orangeAccent),
                const SizedBox(width: 8),
                Text(
                  "CONFIRM ${selectedCar.model.toUpperCase()}",
                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentChip(String title, IconData icon) {
    bool isSelected = selectedPayment == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => onPaymentMethodChanged(title),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.orangeAccent : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? Colors.orangeAccent : Colors.grey.shade300, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.black54),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}