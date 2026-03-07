import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sajilo_ride/auth/auth_provider.dart';
import 'auth_page/login_page.dart';

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
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
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
                    backgroundColor: Colors.blueAccent,
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
                      // Navigate to your RideHistory screen
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
                    onTap: () {},
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

  // --- HELPER: TILE UI ---
  Widget _buildProfileTile({required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.blueAccent),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
    );
  }

  // --- LOGIC: LOGOUT ---
  void _handleLogout(BuildContext context, AuthProviderMethod auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Do you want to sign out of your passenger account?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                      (route) => false,
                );
              }
            },
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}