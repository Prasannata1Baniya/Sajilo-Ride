import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sajilo_ride/auth/auth_provider.dart';
import 'package:sajilo_ride/screens/auth_page/login_page.dart';

class DriverVerificationPage extends StatefulWidget {
  final String name, email, password, phone;

  const DriverVerificationPage({
    super.key,
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
  });

  @override
  State<DriverVerificationPage> createState() => _DriverVerificationPageState();
}

class _DriverVerificationPageState extends State<DriverVerificationPage> {
  Uint8List? _licenseData;
  Uint8List? _selfieData;
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source, bool isSelfie) async {

    debugPrint("DEBUG: Starting image pick. Source: $source");
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 25,
        maxWidth: 800,
        preferredCameraDevice: isSelfie ? CameraDevice.front : CameraDevice.rear,
      );

      if (pickedFile == null) {
        debugPrint("DEBUG: User cancelled picking");
        return;
      }

      debugPrint("DEBUG: Image picked successfully");
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        if (isSelfie) {
          _selfieData = bytes;
        } else {
          _licenseData = bytes;
        }
      });
    } catch (e) {
      debugPrint("DEBUG: ERROR OCCURRED: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Camera error: $e")),
        );
      }
    }
  }

  Future<void> _completeRegistration() async {
    if (_licenseData == null || _selfieData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please complete both License and Face verification"),
            backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProviderMethod>(context, listen: false);

    final message = await authProvider.signUpWithEmailAndPassword(
      widget.name,
      widget.email,
      widget.password,
      widget.phone,
      'driver',
    );

    if (!mounted) return;

    if (message == 'Success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Account created! Welcome to Sajilo Ride."),
            backgroundColor: Colors.green),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text("Driver Verification"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Last Step!",
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Submit your documents to start earning with Sajilo Ride.",
                style: TextStyle(color: Colors.white60, fontSize: 15)),
            const SizedBox(height: 40),

            _buildUploadCard(
              title: "Driving License",
              subtitle: "Upload a clear photo of your license",
              data: _licenseData,
              onTap: () => _pickImage(ImageSource.gallery, false),
              onDelete: () => setState(() => _licenseData = null),
            ),

            const SizedBox(height: 20),

            _buildUploadCard(
              title: "Selfie Verification",
              subtitle: "Take a live photo for verification",
              data: _selfieData,
              icon: Icons.face_retouching_natural,
              onTap: () => _pickImage(ImageSource.camera, true),
              onDelete: () => setState(() => _selfieData = null),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                onPressed: _isLoading ? null : _completeRegistration,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("FINISH REGISTRATION",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard({
    required String title,
    required String subtitle,
    required Uint8List? data,
    required VoidCallback onTap,
    required VoidCallback onDelete,
    IconData icon = Icons.camera_alt_outlined,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: data == null ? onTap : null,
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                  color: data == null ? Colors.orangeAccent.withValues(alpha: 0.5) : Colors.green,
                  width: 2),
            ),
            child: data == null
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.orangeAccent, size: 40),
                const SizedBox(height: 8),
                Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            )
                : Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Image.memory(data, fit: BoxFit.cover, width: double.infinity),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.red.withValues(alpha: 0.8),
                    child: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                      onPressed: onDelete,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}



/*import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sajilo_ride/auth/auth_provider.dart';
import 'package:sajilo_ride/screens/auth_page/login_page.dart';

class DriverVerificationPage extends StatefulWidget {
  final String name, email, password, phone;

  const DriverVerificationPage({
    super.key,
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
  });

  @override
  State<DriverVerificationPage> createState() => _DriverVerificationPageState();
}

class _DriverVerificationPageState extends State<DriverVerificationPage> {
  Uint8List? _licenseData;
  Uint8List? _selfieData; // Added for camera verification
  bool _isLoading = false;

// Update the pick method to allow choosing source
  Future<void> _pickImage(ImageSource source, bool isSelfie) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 25,
        preferredCameraDevice: isSelfie ? CameraDevice.front : CameraDevice
            .rear,
      );
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          if (isSelfie) {
            _selfieData = bytes;
          } else {
            _licenseData = bytes;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Camera not available on this device: $e")),
        );
      }
    }
  }


  Future<void> _completeRegistration() async {
    if (_licenseData == null || _selfieData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please complete both License and Face verification"),
            backgroundColor: Colors.red
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProviderMethod>(
        context, listen: false);

    // TODO: In the future, call a function to upload the image first:
    // String licenseUrl = await uploadToCloudinary(_licenseData);

    final message = await authProvider.signUpWithEmailAndPassword(
      widget.name,
      widget.email,
      widget.password,
      widget.phone,
      'driver',
      // licenseUrl, // Pass the URL here once your backend is ready
    );

    if (!mounted) return;

    if (message == 'Success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Account created! Welcome to Sajilo Ride."),
            backgroundColor: Colors.green),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text("Verification"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Last Step!",
                style: TextStyle(color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
                "We need a clear photo of your driving license to verify your account.",
                style: TextStyle(color: Colors.white60, fontSize: 15)),
            const SizedBox(height: 40),

            _buildUploadCard(
              title: "Driving License",
              subtitle: "Upload a clear photo of your license",
              data: _licenseData,
              onTap: () => _pickImage(ImageSource.gallery, false),
              // false = not a selfie
              onDelete: () => setState(() => _licenseData = null),
            ),

            const SizedBox(height: 20),

            // --- STEP 2: SELFIE VERIFICATION ---
            _buildUploadCard(
              title: "Selfie Verification",
              subtitle: "Take a photo of yourself for liveness check",
              data: _selfieData,
              icon: Icons.face_retouching_natural,
              onTap: () => _pickImage(ImageSource.camera, true),
              // true = selfie
              onDelete: () => setState(() => _selfieData = null),
            ),

            const SizedBox(height: 40),

            // Bottom Action Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                onPressed: _isLoading ? null : _completeRegistration,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("FINISH REGISTRATION",
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- REUSABLE UI WIDGET FOR UPLOAD CARDS ---
  Widget _buildUploadCard({
    required String title,
    required String subtitle,
    required Uint8List? data,
    required VoidCallback onTap,
    required VoidCallback onDelete,
    IconData icon = Icons.camera_alt_outlined,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: data == null ? onTap : null,
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                  color: data == null
                      ? Colors.orangeAccent.withValues(alpha: 0.5)
                      : Colors.green,
                  width: 2),
            ),
            child: data == null
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.orangeAccent, size: 40),
                const SizedBox(height: 8),
                Text(subtitle, style: const TextStyle(
                    color: Colors.white38, fontSize: 12)),
              ],
            )
                : Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Image.memory(
                      data, fit: BoxFit.cover, width: double.infinity),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.red.withValues(alpha: 0.8),
                    child: IconButton(
                      icon: const Icon(
                          Icons.delete, color: Colors.white, size: 18),
                      onPressed: onDelete,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}*/

            // Image Upload Box
            /*GestureDetector(
              onTap:()=> _pickImage(),
              child: Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: _licenseData == null ? Colors.orangeAccent : Colors.green,
                      width: 2,
                      style: BorderStyle.solid
                  ),
                ),
                child: _licenseData == null
                    ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined, color: Colors.orangeAccent, size: 50),
                    SizedBox(height: 12),
                    Text("Tap to upload License", style: TextStyle(color: Colors.white70)),
                  ],
                )
                    : Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.memory(_licenseData!, fit: BoxFit.cover, width: double.infinity),
                    ),
                    Positioned(
                      right: 10,
                      top: 10,
                      child: CircleAvatar(
                        backgroundColor: Colors.red,
                        child: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white),
                          onPressed: () => setState(() => _licenseData = null),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
        
            const Spacer(),
        
            // Bottom Action Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                ),
                onPressed: _isLoading ? null : _completeRegistration,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("FINISH REGISTRATION",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }*/

