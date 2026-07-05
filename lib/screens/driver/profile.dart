import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sajilo_ride/auth/auth_provider.dart';
import 'package:sajilo_ride/screens/driver/earning.dart';
import 'package:sajilo_ride/screens/driver/profile/app_settings_screen.dart';
import '../auth_page/login_page.dart';
import 'car_management.dart';
import 'package:sajilo_ride/screens/shared/help_support_page.dart';

class DriverProfileContent extends StatelessWidget {
  const DriverProfileContent({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderMethod>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. HEADER SECTION (User Info)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 15),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              children: [
                
                FutureBuilder<DocumentSnapshot>(future: FirebaseFirestore.instance.collection('drivers').doc(user?.uid).get(),
                    builder: (context, snapshot){
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircleAvatar(radius: 50, backgroundColor: Colors.grey);
                      }

                      if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
                        // Return a default "unverified" UI
                        return const CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.orange,
                          child: Icon(Icons.person, size: 50, color: Colors.white),
                        );
                      }

                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      final num rawRating = data['averageRating'] ?? 0.0;
                      final double rating = rawRating.toDouble();
                      final isVerified = data['isVerified'] ?? false;

                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.orange,
                            child: Icon(Icons.person, size: 50, color: Colors.white),
                          ),

                          // Positioned Rating Badge
                          if (isVerified)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.amber, width: 2),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))
                                ],
                              ),
                              child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        rating.toStringAsFixed(1),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                            ),
                          ),
                        ],
                      );
                    }
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
                  icon: Icons.directions_car,
                  title: "My Vehicle Details",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>  CarManagementContent(),
                      ),
                    );
                  },
                ),

                _buildProfileOption(
                  icon: Icons.history,
                  title: "Ride History",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>  DriversEarningContent(),
                      ),
                    );
                  },
                ),
                _buildProfileOption(
                  icon: Icons.help_outline,
                  title: "Support & Help",
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpSupportPage(isDriver: true,)));
                  },
                ),

                _buildProfileOption(
                  icon: Icons.settings,
                  title: "App Settings",
                  onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (context) =>  AppSettingsScreen(),),),
                ),

                const Divider(height: 40),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showLogoutDialog(context, authProvider),
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
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.orange),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
    );
  }

  // LOGOUT DIALOG ---
  void _showLogoutDialog(BuildContext context, AuthProviderMethod auth) {
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