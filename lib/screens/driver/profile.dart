import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sajilo_ride/auth/auth_provider.dart';
import '../auth_page/login_page.dart';

class DriverProfileContent extends StatelessWidget {
  const DriverProfileContent({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the user data and logout method from your AuthProvider
    final authProvider = Provider.of<AuthProviderMethod>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. HEADER SECTION (User Info)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 15),
                Text(
                  user?.displayName ?? "Sajilo User",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  user?.email ?? "email@example.com",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. MENU OPTIONS
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              children: [
                _buildProfileOption(
                  icon: Icons.history,
                  title: "Ride History",
                  onTap: () {
                    // Navigate to a history page if you have one
                  },
                ),
                _buildProfileOption(
                  icon: Icons.payment,
                  title: "Payment Methods",
                  onTap: () {},
                ),
                _buildProfileOption(
                  icon: Icons.help_outline,
                  title: "Support & Help",
                  onTap: () {},
                ),
                _buildProfileOption(
                  icon: Icons.settings,
                  title: "App Settings",
                  onTap: () {},
                ),

                const Divider(height: 40),

                // 3. LOGOUT BUTTON
                ListTile(
                  onTap: () => _showLogoutDialog(context, authProvider),
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    "Logout",
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
                ),
              ],
            ),
          ),

          // VERSION FOOTER
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text("Sajilo Ride v1.0.0", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // --- HELPER: MENU ITEM UI ---
  Widget _buildProfileOption({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
    );
  }

  // --- LOGIC: LOGOUT DIALOG ---
  void _showLogoutDialog(BuildContext context, AuthProviderMethod auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to log out of Sajilo Ride?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await auth.signOut(); // Call your Firebase Sign Out logic
              if (context.mounted) {
                // Clear the navigation stack and go to Login
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                      (Route<dynamic> route) => false,
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