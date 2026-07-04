import 'package:flutter/material.dart';
import 'package:sajilo_ride/screens/driver/profile/help_support_screen.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  // Toggle states
  bool autoAccept = false;
  bool soundAlerts = true;
  bool darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),
      appBar: AppBar(
        title: const Text("App Settings", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: [
          // 1. DRIVER PREFERENCES
          _buildSectionHeader("DRIVER PREFERENCES"),
          _buildSwitchTile("Auto-Accept Rides", "Automatically accept nearby requests",
              autoAccept, (val) => setState(() => autoAccept = val)),
          _buildSwitchTile("Ride Request Sound", "Play sound on new request",
              soundAlerts, (val) => setState(() => soundAlerts = val)),

          const SizedBox(height: 20),

          // 2. DISPLAY & SYSTEM
          _buildSectionHeader("DISPLAY & SYSTEM"),
          _buildSwitchTile("Dark Mode", "Use dark theme for night driving", darkMode, (val) => setState(() => darkMode = val)),
          _buildTile(Icons.language, "App Language", "English"),

          const SizedBox(height: 20),

          // 3. ABOUT
          _buildSectionHeader("ABOUT"),
          _buildTile(Icons.description_outlined, "Terms of Service", null),
          _buildTile(Icons.privacy_tip_outlined, "Privacy Policy", null),

          const SizedBox(height: 20),
          ListTile(
            title: Text('Help and Support'),
            onTap: ()=>Navigator.push(context, MaterialPageRoute(builder: (_)=>HelpSupportScreen())),

          ),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text("Sajilo Ride Driver v1.0.0",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 12)),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.orange,
      ),
    );
  }

  Widget _buildTile(IconData icon, String title, String? trailing) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.orange),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: trailing != null ? Text(trailing, style: const TextStyle(color: Colors.grey)) : const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () {},
      ),
    );
  }
}