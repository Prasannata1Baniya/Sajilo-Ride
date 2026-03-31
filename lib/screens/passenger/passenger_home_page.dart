import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sajilo_ride/data/model/car_model.dart';
import 'package:sajilo_ride/widgets/car_card.dart';
import 'package:geocoding/geocoding.dart';

class PassengerHomeContent extends StatefulWidget {
  const PassengerHomeContent({super.key});

  @override
  State<PassengerHomeContent> createState() => _PassengerHomeContentState();
}

class _PassengerHomeContentState extends State<PassengerHomeContent> {
  LatLng _currentCenter = const LatLng(27.7172, 85.3240);
  final MapController _mapController = MapController();

  //  1. HARDCODED FALLBACK DATA
  final List<CarModel> carList = [
    CarModel(model: "Fortuner GR",
        distance: 870, pricePerHour: 45, fuelCapacity: 50,
        image: "assets/images/car1.jpg",driverId: ''),
    CarModel(model: "Land Cruiser", distance: 500, pricePerHour: 60,
        fuelCapacity: 80, image: "assets/images/car2.jpg", driverId: ''),
    CarModel(model: "Tesla Model X", distance: 400, pricePerHour: 55,
        fuelCapacity: 100, image: "assets/images/car3.jpg", driverId: ''),
    CarModel(model: "Hyundai Tucson", distance: 600, pricePerHour: 35,
        fuelCapacity: 55, image: "assets/images/car4.jpg", driverId: ''),
    CarModel(model: "Kia Sportage", distance: 700, pricePerHour: 38,
        fuelCapacity: 60, image: "assets/images/car2.jpg", driverId: ''),
    CarModel(model: "Suzuki Vitara", distance: 900, pricePerHour: 30,
        fuelCapacity: 45, image: "assets/images/car3.jpg", driverId: ''),
  ];

  String _address = "Fetching address...";

  Future<void> _updateAddress(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _address = "${place.name}, ${place.street}, ${place.locality}";
        });
      }
    } catch (e) {
      setState(() => _address = "Unknown Location");
    }
  }

  @override
  void initState() {
    super.initState();
    _updateAddress(_currentCenter);
  }

  @override
  Widget build(BuildContext context) {
    bool isWideScreen = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sajilo Ride - Choose Pickup"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('drivers').snapshots(),
        builder: (context, snapshot) {
          // While loading, show the hardcoded list so it's not blank
          if (snapshot.connectionState == ConnectionState.waiting) {
            return isWideScreen ? _buildWebView(carList) : _buildMobileView(carList);
          }

          // 2. FETCH LIVE DATA
          List<CarModel> liveCarList = [];
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            liveCarList = snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return CarModel(
                driverId: doc.id,
                model: data['carModel'] ?? 'Unknown',
                pricePerHour: (data['pricePerHour'] ?? 0).toDouble(),
                distance: (data['distance'] ?? 0).toDouble(),
                fuelCapacity: (data['fuelCapacity'] ?? 0).toDouble(),
                image: data['carImage'] ?? 'assets/images/placeholder.jpg',
              );
            }).toList();
          }

          // 3. COMBINE BOTH LISTS
          // Put the real drivers from Firebase at the top, then our assets
          final List<CarModel> allCars = [...liveCarList, ...carList];

          return isWideScreen ? _buildWebView(allCars) : _buildMobileView(allCars);
        },
      ),
    );
  }


  Widget _buildWebView(List<CarModel> cars) {
    return Row(
      children: [
        Expanded(flex: 3, child: _buildMap()),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Available Rides", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              Expanded(child: _buildCarGrid(2, cars)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileView(List<CarModel> cars) {
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.4, child: _buildMap()),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Text("Select a Car", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragStart: (_) {},
            child: _buildCarGrid(2, cars)
        ),
        ),
      ],
    );
  }

  Widget _buildMap() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentCenter,
            initialZoom: 14.0,
            onPositionChanged: (pos, hasGesture) {
              if (hasGesture) {
                setState(() => _currentCenter = pos.center);
                _updateAddress(pos.center);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.prasannata.sajilo_ride',
            ),
          ],
        ),
        const Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: 35),
            child: Icon(Icons.location_on, color: Colors.red, size: 45),
          ),
        ),
        Positioned(
          top: 10, left: 10, right: 10,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.orange),
                const SizedBox(width: 10),
                Expanded(child: Text(_address, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCarGrid(int crossAxisCount, List<CarModel> cars) {
    bool isDesktop = MediaQuery.of(context).size.width > 600;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const AlwaysScrollableScrollPhysics(),
      primary: true,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: isDesktop ? 0.75 : 0.6,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: cars.length,
      itemBuilder: (context, index) {
        return CarCard(car: cars[index], pickupLocation: _currentCenter);
      },
    );
  }
}

