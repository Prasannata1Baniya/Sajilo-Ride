import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SajiloAdminApp extends StatelessWidget {
  const SajiloAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sajilo Ride Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFFF5F5F7),
        useMaterial3: true,
      ),
      home: const AdminDashboardPage(),
    );
  }
}

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // to quickly handle approving the driver document
  Future<void> _approveDriver(String uid, String name) async {
    try {
      await _db.collection('users').doc(uid).update({
        'isVerified': true,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$name approved successfully!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      _showErrorSnackBar("Failed to approve driver: $e");
    }
  }

  // to handle rejecting / deleting unverified entries safely
  Future<void> _rejectDriver(String uid, String name) async {
    try {
      // You can either delete the doc or update a status like 'isRejected: true'
      await _db.collection('users').doc(uid).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$name verification application rejected."), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      _showErrorSnackBar("Failed to reject driver: $e");
    }
  }

  void _showErrorSnackBar(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text(
          "Sajilo Ride — Driver Verification Center Desk",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () => setState(() {}),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // Sidebar Navigation Panel for Admin Look and Feel
          Container(
            width: 260,
            color: Colors.black.withValues(alpha: 0.9),
            child: const Column(
              children: [
                SizedBox(height: 30),
                CircleAvatar(radius: 40, backgroundColor: Colors.orange, child: Icon(Icons.admin_panel_settings, size: 40, color: Colors.white)),
                SizedBox(height: 12),
                Text("System Admin", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 40),
                ListTile(
                  leading: Icon(Icons.pending_actions, color: Colors.orangeAccent),
                  title: Text("Pending Drivers", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                Divider(color: Colors.white24),
              ],
            ),
          ),

          // Main Body Area showing real-time Firestore stream
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Pending Driver Registrations", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 8),
                  const Text("Review the license document file and match carefully before granting operational platform access.", style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 24),

                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      // Real-time listener filters directly for unverified users where role is 'driver'
                      stream: _db.collection('users')
                          .where('role', isEqualTo: 'driver')
                          .where('isVerified', isEqualTo: false)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(child: Text("Error fetching records: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Colors.orange));
                        }
                        if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                          return _buildEmptyState();
                        }

                        final docs = snapshot.data!.docs;

                        return GridView.builder(
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 500,
                            mainAxisExtent: 440,
                            crossAxisSpacing: 24,
                            mainAxisSpacing: 24,
                          ),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final driver = docs[index].data() as Map<String, dynamic>;
                            final String uid = docs[index].id;
                            final String name = driver['name'] ?? 'Unknown Name';
                            final String email = driver['email'] ?? 'N/A';
                            final String phone = driver['phone'] ?? 'N/A';
                            final String licenseUrl = driver['licenseUrl'] ?? '';
                            final String selfieUrl = driver['selfieUrl'] ?? '';

                            return _buildDriverVerificationCard(uid, name, email, phone, licenseUrl,selfieUrl);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.green.withValues(alpha: 0.6)),
          const SizedBox(height: 16),
          const Text("All Caught Up!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 6),
          const Text("There are currently no drivers waiting for document validation approval.", style: TextStyle(color: Colors.black38)),
        ],
      ),
    );
  }

  Widget _buildDriverVerificationCard(String uid, String name, String email, String phone, String licenseUrl,String selfieUrl) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cloudinary License Image Viewer Section
          Expanded(
            child: GestureDetector(
              onTap: () => _showLicenseInspector(context, licenseUrl,selfieUrl, name),
              child: Container(
                color: Colors.grey[200],
                width: double.infinity,
                child: Stack(
                  children: [
                    licenseUrl.isNotEmpty
                        ? Image.network(
                      licenseUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Icon(Icons.broken_image, size: 48, color: Colors.black38));
                      },
                    )
                        : const Center(child: Text("No license image uploaded.", style: TextStyle(color: Colors.black38))),

                    const Positioned(
                      bottom: 8,
                      child: Chip(
                        avatar: Icon(Icons.zoom_in, size: 16),
                        label: Text("Click to Inspect"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Driver Text Details Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 16, color: Colors.black54),
                    const SizedBox(width: 8),
                    Text(email, style: const TextStyle(color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone_android_outlined, size: 16, color: Colors.black54),
                    const SizedBox(width: 8),
                    Text(phone, style: const TextStyle(color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 16),

                // 3. Action Buttons Section
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _rejectDriver(uid, name),
                        child: const Text("REJECT", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        onPressed: () => _approveDriver(uid, name),
                        child: const Text("APPROVE", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  void _showLicenseInspector(BuildContext context, String licenseUrl, String selfieUrl, String driverName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 800,
          height: 600,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("Verification: $driverName",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ),

              // Side-by-Side Comparison
              Expanded(
                child: Row(
                  children: [
                    _buildInspectorPanel("Driver License", licenseUrl),
                    const VerticalDivider(width: 1),
                    _buildInspectorPanel("Selfie Check", selfieUrl),
                  ],
                ),
              ),

              // Close Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade200,
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CLOSE"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInspectorPanel(String title, String imageUrl) {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
          ),
        ],
      ),
    );
  }
}
