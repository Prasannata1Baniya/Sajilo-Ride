import 'package:flutter/material.dart';
import 'package:sajilo_ride/screens/auth_page/login_page.dart';

class OnBoardingPage extends StatefulWidget {
  const OnBoardingPage({super.key});

  @override
  State<OnBoardingPage> createState() => _OnBoardingPageState();
}

class _OnBoardingPageState extends State<OnBoardingPage> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isDesktop = width > 650;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: const Text(
                    //'SAJILO YATRA',
                    'SAJILO RIDE',
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),

                const Spacer(),

                _buildGetStartedButton(context),
              ],
            ),
          ),
        ),
      ),
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
        child: Container(
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: Colors.orangeAccent,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.orangeAccent.withValues(alpha: 0.4),
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
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}







/*import 'package:flutter/material.dart';
import 'package:sajilo_ride/screens/auth_page/login_page.dart';
import 'package:sajilo_ride/utils/text_styles.dart';

class OnBoardingPage extends StatefulWidget {
  const OnBoardingPage({super.key});

  @override
  State<OnBoardingPage> createState() => _OnBoardingPageState();
}

class _OnBoardingPageState extends State<OnBoardingPage> {

  final GlobalKey _heroKey = GlobalKey();
  final GlobalKey _carKey = GlobalKey();
  final GlobalKey _footerKey = GlobalKey();

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
  void scrollTo(GlobalKey key) {
    final context = key.currentContext;

    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final bool isDesktop = width > 650;

   /* final List<CarCard> previewCars = [
    //  CarCard(car: car, pickupLocation: pickupLocation)
     /* CarModel(model: "Fortuner GR", distance: 870, pricePerHour: 45,
          fuelCapacity: 50, image: "assets/images/car1.jpg", driverId: '1'),
      CarModel(model: "Tesla Model X", distance: 400, pricePerHour: 55,
          fuelCapacity: 100, image: "assets/images/car3.jpg", driverId: '2'),
      CarModel(model: "Land Cruiser", distance: 500, pricePerHour: 60,
          fuelCapacity: 80, image: "assets/images/car2.jpg", driverId: '3'),*/
    ];*/

    return Scaffold(
      //backgroundColor: Colors.white,
      body: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          primary: true,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // --- 1. HERO SECTION ---
              Container(
                key: _heroKey,
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.96,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: isDesktop
                        ? const AssetImage("assets/images/onboarding_bg.png")
                        : const AssetImage("assets/images/onboarding_bg(mobile)1.png"),
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

                        //GET STARTED
                        _buildGetStartedButton(context),

                        const SizedBox(height: 16),
                        //Arrow down key
                        GestureDetector(
                          onTap: () => scrollTo(_carKey),
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

        
              // --- 2. FOOTER SECTION ---
              Container(
                key: _footerKey,
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
      ),
    );
  }


  Widget _buildTopNav(bool isDesktop) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child:  isDesktop ? const Text('SAJILO YATRA', style: AppTextStyles.headingWhiteLogo) :
          const Text('SAJILO YATRA', style: TextStyle(fontSize: 17)),
        ),

        // DESKTOP MENU
        if (isDesktop)
          Row(
            children: [
              TextButton(
                onPressed: () => scrollTo(_heroKey),
                child: const Text('Home', style: AppTextStyles.smallTextWhite),
              ),
              TextButton(
                onPressed: () => scrollTo(_carKey),
                child: const Text('About', style: AppTextStyles.smallTextWhite),
              ),
              TextButton(
                onPressed: () => scrollTo(_footerKey),
                child: const Text('Contact', style: AppTextStyles.smallTextWhite),
              ),
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
*/