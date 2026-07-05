import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:sajilo_ride/auth/auth_provider.dart';
import '../../../navbar/navbar_config.dart';
import '../../../widgets/app_shell.dart';
import 'face_recognition_service.dart';

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
  XFile? _licenseFile;
  XFile? _selfieFile;

  bool _isLoading = false;
  String? error;

  final FaceRecognitionService _faceService = FaceRecognitionService();

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _faceService.initModel();
    }
  }

  @override
  void dispose() {
    _faceService.close();
    super.dispose();
  }

  void _showDialog({
    required String title,
    required String message,
    required VoidCallback onRetry,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Column(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 50),
            SizedBox(height: 10),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () {
              Navigator.pop(context);
              onRetry();
            },
            child: const Text("RETRY", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, bool isSelfie) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: isSelfie ? 60 : 90,
        maxWidth: isSelfie ? 1024 : 1920,
        preferredCameraDevice: isSelfie ? CameraDevice.front : CameraDevice.rear,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      setState(() {
        if (isSelfie) {
          _selfieData = bytes;
          _selfieFile = pickedFile;
        } else {
          _licenseData = bytes;
          _licenseFile = pickedFile;
        }
      });
    } catch (e) {
      _showSnackBar("Camera error: $e", isError: true);
    }
  }

  Future<void> _completeRegistration() async {
    if (_licenseFile == null || _selfieFile == null) {
      _showSnackBar("Please complete both License and Face verification", isError: true);
      return;
    }

    final authProvider = Provider.of<AuthProviderMethod>(context, listen: false);

    setState(() => _isLoading = true);
    _showSnackBar("Processing biometric validation...", isError: false);

    List<double>? licenseEmbeddings = await _extractEmbeddings(_licenseFile!, isDocument: true);
    if (licenseEmbeddings == null) {
      _showSnackBar("Could not read a clear face from your Driving License. Try a well-lit, closer photo.", isError: true);
      setState(() => _isLoading = false);
      return;
    }

    List<double>? selfieEmbeddings = await _extractEmbeddings(_selfieFile!, isDocument: false);
    if (selfieEmbeddings == null) {
      _showSnackBar("Could not read a clear face from your Selfie live photo.", isError: true);
      setState(() => _isLoading = false);
      return;
    }

    double distance = _calculateDistance(licenseEmbeddings, selfieEmbeddings);
    debugPrint("DEBUG: Calculated face biometric distance -> $distance");

    if (distance > 0.7) {
      _showDialog(
          title: "Verification Mismatch",
          message: "The selfie doesn't match the license clearly. Ensure you are in a bright area, remove glasses, and look directly at the camera.",
          onRetry: () => setState(() => _isLoading = false)
      );

      return;
    }

    _showSnackBar("Biometrics matched! finalising registration...", isError: false);

    final message = await authProvider.signUpWithEmailAndPassword(
      widget.name,
      widget.email,
      widget.password,
      widget.phone,
      'driver',
      licenseFile: _licenseFile,
      selfieFile: _selfieFile,
      faceEmbeddings: selfieEmbeddings,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (message == 'Success') {
      _showSnackBar("Account created! Welcome onboard.", isError: false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const AppShell(userRole: UserRole.driver),
        ),
            (route) => false,
      );
    } else {
      setState(() => _isLoading = false);
      _showSnackBar(message, isError: true);
    }

  }

  ///calculate Distance
  double _calculateDistance(List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) return 999.0;
    double sum = 0.0;
    for (int i = 0; i < embedding1.length; i++) {
      double diff = embedding1[i] - embedding2[i];
      sum += diff * diff;
    }
    return sqrt(sum);
  }


  ///Extract embeddings
  Future<List<double>?> _extractEmbeddings(XFile file, {required bool isDocument}) async {
    if (kIsWeb) return null;

    /*final options = FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: isDocument ? 0.05 : 0.1,
    );*/

    final options = FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      minFaceSize: 0.01,
      enableLandmarks: false,
      enableContours: false,
    );
    final faceDetector = FaceDetector(options: options);

    try {
      final inputImage = InputImage.fromFilePath(file.path);

      debugPrint("DEBUG: Processing ML Kit Image Detection...");
      List<Face> faces = await faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        debugPrint("DEBUG: ❌ ML Kit found ZERO faces.");
        await faceDetector.close();
        return null;
      }

      debugPrint("DEBUG: Found ${faces.length} face(s). Extracting boundaries safely...");
      Face face = faces.first;
      Rect boundingBox = face.boundingBox;

      final rawImageBytes = await File(file.path).readAsBytes();
      final cmd = img.Command()..decodeImage(rawImageBytes);

      final originalImage = await cmd.getImage();
      if (originalImage == null) {
        debugPrint("DEBUG: ❌ Image library failed to decode raw bytes.");
        await faceDetector.close();
        return null;
      }

      int x = boundingBox.left.toInt().clamp(0, originalImage.width - 1);
      int y = boundingBox.top.toInt().clamp(0, originalImage.height - 1);
      int width = boundingBox.width.toInt().clamp(1, originalImage.width - x);
      int height = boundingBox.height.toInt().clamp(1, originalImage.height - y);

      debugPrint("DEBUG: Cropping image zone: x=$x, y=$y, w=$width, h=$height");

      img.Image croppedFace = img.copyCrop(
          originalImage,
          x: x,
          y: y,
          width: width,
          height: height
      );

      img.Image resizedFace = img.copyResize(croppedFace, width: 112, height: 112);

      await faceDetector.close();

      debugPrint("DEBUG: 🚀 Sending cropped face matrix to FaceRecognitionService inference...");

      return _faceService.runInference(resizedFace);

    }catch (e) {
      debugPrint("DEBUG: 🚨 Error inside processing pipeline: $e");
      await faceDetector.close();
    }finally{
      await faceDetector.close();
    }
    return null;
  }

  // UI rendering methods remain identical...
  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          elevation: 0,
          title: const Text("Driver Verification"),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Last Step!", style: TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("Submit your documents to start verification.", style: TextStyle(color: Colors.black87, fontSize: 15)),
              const SizedBox(height: 40),
              _buildUploadCard(
                title: "Driving License",
                subtitle: "Upload a clear, glare-free close-up",
                data: _licenseData,
                onTap: () => _pickImage(ImageSource.gallery, false),
                onDelete: () => setState(() {
                  _licenseData = null;
                  _licenseFile = null;
                }),
              ),
              const SizedBox(height: 20),
              _buildUploadCard(
                title: "Selfie Verification",
                subtitle: "Take a live front-facing photo",
                data: _selfieData,
                icon: Icons.face_retouching_natural,
                onTap: () => _pickImage(ImageSource.camera, true),
                onDelete: () => setState(() {
                  _selfieData = null;
                  _selfieFile = null;
                }),
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
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text("FINISH REGISTRATION",
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
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
        Text(title, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: data == null ? onTap : null,
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: data == null ? Colors.orangeAccent.withValues(alpha: 0.5) : Colors.green, width: 2),
            ),
            child: data == null
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.orangeAccent, size: 40),
                const SizedBox(height: 8),
                Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            )
                : Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Image.memory(data, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.red.withValues(alpha: 0.8),
                    child: IconButton(
                      padding: EdgeInsets.zero,
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
