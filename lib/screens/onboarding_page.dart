import 'package:flutter/material.dart';
import 'package:sajilo_ride/screens/auth_page/login_page.dart';
import 'package:sajilo_ride/utils/text_styles.dart';
import 'package:sajilo_ride/widgets/car_card.dart';
import 'package:latlong2/latlong.dart';
import '../../data/model/car_model.dart';

class OnBoardingPage extends StatefulWidget {
  const OnBoardingPage({super.key});

  @override
  State<OnBoardingPage> createState() => _OnBoardingPageState();
}

class _OnBoardingPageState extends State<OnBoardingPage> {
  bool _isPressed = false;

  void _openDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _menuItem("Home"),
              _menuItem("About"),
              _menuItem("Contact"),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isDesktop = width > 650;

    final List<CarModel> previewCars = [
      CarModel(model: "Fortuner GR", distance: 870, pricePerHour: 45,
          fuelCapacity: 50, image: "assets/images/car1.jpg", driverId: '1'),
      CarModel(model: "Tesla Model X", distance: 400, pricePerHour: 55,
          fuelCapacity: 100, image: "assets/images/car3.jpg", driverId: '2'),
      CarModel(model: "Land Cruiser", distance: 500, pricePerHour: 60,
          fuelCapacity: 80, image: "assets/images/car2.jpg", driverId: '3'),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        primary: true,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // --- 1. HERO SECTION ---
            Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.96,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: isDesktop
                      ? const AssetImage("assets/images/onboarding_bg.png")
                      : const AssetImage("assets/images/onboarding_bg(mobile).png"),
                  fit: BoxFit.cover,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0,),
                  child: Column(
                    children: [
                      //navbar
                      _buildTopNav(isDesktop),
                      const Spacer(),
                      /*const Text(
                        "Premium Rides\nEverywhere in Nepal",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black45, blurRadius: 10)],
                        ),
                      ),
                      const SizedBox(height: 20),*/
                      _buildGetStartedButton(context),
                      const SizedBox(height: 16),
                      const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 40),

                    ],
                  ),
                ),
              ),
            ),

            // 2. CAR PREVIEW SECTION
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
              child: Column(
                children: [
                  const Text("Explore Our Fleet", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Text("Login to book these premium vehicles", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 40),

                  // Grid of cars
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: previewCars.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isDesktop ? 3 : 1,
                      childAspectRatio: isDesktop ? 0.9 : 0.8,
                      mainAxisSpacing: 25,
                      crossAxisSpacing: 25,
                    ),
                    itemBuilder: (context, index) {
                      return AbsorbPointer(
                        child: CarCard(car: previewCars[index],
                            pickupLocation: const LatLng(27.7, 85.3)),
                      );
                    },
                  ),
                ],
              ),
            ),

            // --- 3. FOOTER SECTION ---
            Container(
              width: double.infinity,
              color: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
              child: Column(
                children: [
                  const Text("SAJILO YATRA", style: AppTextStyles.headingWhiteLogo),
                  const SizedBox(height: 30),
                  _buildContactItem(Icons.phone, "+977 9806800001"),
                  _buildContactItem(Icons.email, "support@sajiloride.com"),
                  _buildContactItem(Icons.location_on, "Kathmandu, Nepal"),
                  const SizedBox(height: 30),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 20),
                  const Text("© 2025 Sajilo Ride. All rights reserved.", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildTopNav(bool isDesktop) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Flexible(
          child: Text('SAJILO YATRA', style: AppTextStyles.headingWhiteLogo),
        ),

        // DESKTOP MENU
        if (isDesktop)
          Row(
            children: [
              TextButton(onPressed: () {},
                  child: const Text('Home', style: AppTextStyles.smallTextWhite)),
              TextButton(onPressed: () {},
                  child: const Text('About', style: AppTextStyles.smallTextWhite)),
              TextButton(onPressed: () {},
                  child: const Text('Contact', style: AppTextStyles.smallTextWhite)),
            ],
          ),

        //MOBILE MENU
        if (!isDesktop)
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              _openDrawer();
            },
          ),
      ],
    );
  }

  Widget _buildGetStartedButton(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.96 : 1,
      duration: const Duration(milliseconds: 100),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 42, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.orangeAccent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.orangeAccent,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.orangeAccent,
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Text(
              "GET STARTED",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.orangeAccent, size: 20),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _menuItem(String title) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      onTap: () {
        Navigator.pop(context);
      },
    );
  }
}

