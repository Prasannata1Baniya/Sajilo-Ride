import 'package:flutter/material.dart';
import 'package:sajilo_ride/screens/auth_page/login_page.dart';
import 'package:sajilo_ride/utils/text_styles.dart';


class OnBoardingPage extends StatelessWidget {
  const OnBoardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/onboarding_bg.png"),
            fit: BoxFit.cover,
          ),
        ),
        // 1. Use SafeArea to avoid system UI (status bar, etc.)
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              // The Column now fills the vertical space of the SafeArea
              children: [
                // --- TOP ROW ---
                Row(
                  children: [
                    const Text(
                        'SAJILO YATRA', style: AppTextStyles.headingWhiteLogo),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                          'Home', style: AppTextStyles.smallTextWhite),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                          'About', style: AppTextStyles.smallTextWhite),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                          'Contact', style: AppTextStyles.smallTextWhite),
                    ),
                  ],
                ),

                // --- 2. SPACER ---
                // This is the magic widget. It expands to take up all available
                // vertical space, pushing everything after it to the bottom.
                const Spacer(),

                // --- BOTTOM BUTTON ---
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.orangeAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 15), // Make button bigger
                    ),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    child: const Text(
                      "Get Started",
                      style: AppTextStyles.bodyTextWhite,
                    ),
                  ),
                ),

                // 3. Add some bottom padding so the button isn't stuck to the edge
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
