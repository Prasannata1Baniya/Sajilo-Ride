import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../widgets/custom_expansion_tile.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: const Text("Help & Support", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Frequently Asked Questions",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),

            // Custom Expansion Tiles
            CustomExpansionTile(
                title: "How to cancel a ride?",
                content: "Go to 'My Rides', select the active ride, and tap the 'Cancel Ride' button."),
            CustomExpansionTile(
                title:"Is my data safe?",
                content:"Yes, we prioritize your privacy. Your location is tracked only for safety reasons while on a trip."),
            CustomExpansionTile(title: "How can I pay?",
                content: "Currently, we support 'Cash on Arrival'. Stay tuned for eSewa integration!"),

            const SizedBox(height: 40),

            // Premium Support Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15)],
              ),
              child: Column(
                children: [
                  const Icon(Icons.support_agent, size: 50, color: Colors.orange),
                  const SizedBox(height: 15),
                  const Text("Still need help?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text("Our support team is available 24/7 to assist you with any ride issues.",
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () => _launchWhatsApp(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.messenger),
                      label: const Text("CHAT ON WHATSAPP", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _launchWhatsApp() async {
    final Uri url = Uri.parse("https://wa.me/977XXXXXXXXXX");
    if (await canLaunchUrl(url)) await launchUrl(url);
  }
}