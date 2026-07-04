import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sajilo_ride/auth/auth_provider.dart';
import 'package:sajilo_ride/screens/passenger/bookings_page.dart';
import 'package:sajilo_ride/screens/shared/help_support_page.dart';

import '../auth_page/login_page.dart';

class PassengerProfileContent extends StatelessWidget {
  const PassengerProfileContent({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderMethod>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. USER INFO CARD
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    user?.displayName ?? "Passenger Name",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    user?.email ?? "passenger@example.com",
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            const Divider(thickness: 1, indent: 20, endIndent: 20),

            // 2. PASSENGER OPTIONS
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  _buildProfileTile(
                    icon: Icons.history,
                    title: "My Ride History",
                    subtitle: "View your past trips and receipts",
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_)=>MyBookingsPage()));
                    },
                  ),
                  _buildProfileTile(
                    icon: Icons.payment,
                    title: "Payment Methods",
                    subtitle: "Manage your eSewa and Cash options",
                    onTap: () {},
                  ),
                  _buildProfileTile(
                    icon: Icons.notifications_none,
                    title: "Notifications",
                    subtitle: "Manage your alerts and news",
                    onTap: () {},
                  ),
                  _buildProfileTile(
                    icon: Icons.help_outline,
                    title: "Help & Support",
                    subtitle: "Get help with your rides",
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpSupportPage()));
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. LOGOUT BUTTON
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _handleLogout(context, authProvider),
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text("Logout", style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
            const Text("Sajilo Ride - Passenger v1.0", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // --- TILE UI ---
  Widget _buildProfileTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.orangeAccent),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
    );
  }

  // --- LOGOUT ---
  void _handleLogout(BuildContext context, AuthProviderMethod auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Column(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent, size: 40),
            SizedBox(height: 10),
            Text("Sign Out", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          ],
        ),
        content: const Text(
          "Are you sure you want to log out of Sajilo Ride?",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
            ),
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                      (route) => false,
                );
              }
            },
            child: const Text("LOGOUT", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

