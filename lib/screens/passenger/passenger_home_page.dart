import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sajilo_ride/data/model/car_model.dart';
import 'package:sajilo_ride/widgets/car_card.dart';

class PassengerHomeContent extends StatefulWidget {
  const PassengerHomeContent({super.key});

  @override
  State<PassengerHomeContent> createState() => _PassengerHomeContentState();
}

class _PassengerHomeContentState extends State<PassengerHomeContent> {
  LatLng _currentCenter = const LatLng(27.7172, 85.3240);
  final MapController _mapController = MapController();

  final List<CarModel> carList = [
    CarModel(model: "Fortuner GR", distance: 870, pricePerHour: 45, fuelCapacity: 50,
        image:"assets/images/car1.jpg"),
    CarModel(model: "Fortuner GR", distance: 870, pricePerHour: 45, fuelCapacity: 50,
        image:"assets/images/car2.jpg"),
    CarModel(model: "Fortuner GR", distance: 870, pricePerHour: 45, fuelCapacity: 50,
        image:"assets/images/car3.jpg"),
    CarModel(model: "Fortuner GR", distance: 870, pricePerHour: 45, fuelCapacity: 50,
        image:"assets/images/car4.jpg"),
    CarModel(model: "Fortuner GR", distance: 870, pricePerHour: 45, fuelCapacity: 50,
        image:"assets/images/car2.jpg"),
    CarModel(model: "Fortuner GR", distance: 870, pricePerHour: 45, fuelCapacity: 50,
        image:"assets/images/car3.jpg"),
  ];

  @override
  Widget build(BuildContext context) {
    // Detect if we are on a wide screen (Web/Tablet)
    bool isWideScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sajilo Ride - Choose Pickup"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: isWideScreen ? _buildWebView() : _buildMobileView(),
    );
  }

  // --- WEB VIEW: Side-by-Side ---
  Widget _buildWebView() {
    return Row(
      children: [
        // Left Side: The Map (Takes 60% of screen)
        Expanded(flex: 3, child: _buildMap()),

        // Right Side: Car List (Takes 40% of screen)
        Expanded(
          flex: 2,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Available Rides", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              Expanded(child: _buildCarGrid(2)), // 2 columns for web sidebar
            ],
          ),
        ),
      ],
    );
  }

  // --- MOBILE VIEW: Top-and-Bottom ---
  Widget _buildMobileView() {
    return Column(
      children: [
        // Top: Smaller Map (40% of height)
        SizedBox(height: MediaQuery.of(context).size.height * 0.4, child: _buildMap()),

        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text("Select a Car", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),

        // Bottom: Scrollable List (60% of height)
        Expanded(child: _buildCarGrid(2)),
      ],
    );
  }

  // REUSABLE MAP WIDGET
  Widget _buildMap() {
    return Stack(
      children: [
        // 1. THE ACTUAL MAP
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentCenter,
            initialZoom: 14.0,
            onPositionChanged: (pos, hasGesture) {
              // We only update the center if the user actually moved the map (hasGesture)
              if (hasGesture) {
                setState(() {
                  _currentCenter = pos.center;
                });
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.sajilo_ride.app',
            ),
          ],
        ),

        // 2. FIXED CENTER PIN (The Selector)
        const Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: 35),
            child: Icon(Icons.location_on, color: Colors.red, size: 45),
          ),
        ),

        // 3. THE COORDINATE BOX (ADD THIS HERE)
        Positioned(
          top: 10,
          left: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Colors.orange),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Pickup: ${_currentCenter.latitude.toStringAsFixed(4)}, ${_currentCenter.longitude.toStringAsFixed(4)}",
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // REUSABLE CAR GRID
  Widget _buildCarGrid(int crossAxisCount) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.65,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: carList.length,
      itemBuilder: (context, index) {
        return CarCard(car: carList[index], pickupLocation: _currentCenter);
      },
    );
  }
}
