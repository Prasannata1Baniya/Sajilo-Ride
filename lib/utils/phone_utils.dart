// lib/core/utils/emergency_service.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyService {
  static const String policeNumber = "100";

  static Future<void> showSOSDialog(BuildContext context) async {
    bool confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emergency SOS", style: TextStyle(color: Colors.red)),
        content: const Text("This will open your dialer to call Nepal Police (100). Do you want to continue?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Call 100", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await _launchPhone(policeNumber);
    }
  }

  static Future<void> _launchPhone(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }
}