import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:sajilo_ride/auth/auth_provider.dart';


class ProfileContent extends StatelessWidget {
  const ProfileContent({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. Use a Consumer to listen to your AuthProviderMethod
    return Consumer<AuthProviderMethod>(
      builder: (context, authProvider, child) {
        final User? user = authProvider.user;

        if (user == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
            ),
          );
        }

        // --- Once we have the user, build the main profile UI ---
        return Scaffold(
          appBar: AppBar(
            title: const Text("My Profile"),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black,
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // --- PROFILE HEADER (Avatar & Name) ---
                // This FutureBuilder is now safe because we know user.uid is not null.
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (!snapshot.hasData || snapshot.data?.data() == null) {
                      return const Text("Could not load user data.");
                    }

                    // Get data from Firestore
                    final data = snapshot.data!.data() as Map<String, dynamic>;

                    // 3. CORRECTED: Use 'name' from your Firestore document
                    final String name = data['name'] ?? "Passenger";
                    final String email = data['email'] ?? user.email ?? "No email";

                    return Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.orange.shade100,
                          child: const Icon(Icons.person, size: 50, color: Colors.orange),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          name,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          email,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 30),
                const Divider(),

                // All the options remain the same
                _buildProfileOption(icon: Icons.history, title: "Ride History", onTap: () {}),
                _buildProfileOption(icon: Icons.payment, title: "Payment Methods", onTap: () {}),
                _buildProfileOption(icon: Icons.settings, title: "Settings", onTap: () {}),
                _buildProfileOption(icon: Icons.help_outline, title: "Help & Support", onTap: () {}),
                const Divider(),

                // --- LOGOUT BUTTON ---
                _buildProfileOption(
                  icon: Icons.logout,
                  title: "Logout",
                  textColor: Colors.red,
                  iconColor: Colors.red,
                  onTap: () async {
                    bool? confirm = await _showLogoutDialog(context);
                    if (confirm == true) {
                      // 4. Use the provider instance from the Consumer to sign out
                      await authProvider.signOut();
                      // No navigation needed, the AuthWrapper will handle it!
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper widget for list items
  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color textColor = Colors.black,
    Color iconColor = Colors.orange,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }

  // Logout Confirmation Dialog
  Future<bool?> _showLogoutDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout from Sajilo Ride?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Logout", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}