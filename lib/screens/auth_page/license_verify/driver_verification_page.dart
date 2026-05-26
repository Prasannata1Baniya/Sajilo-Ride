import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:sajilo_ride/auth/auth_provider.dart';
import 'package:sajilo_ride/screens/auth_page/login_page.dart';
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
  // Use our safely abstract platform wrapper
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

  Future<void> _pickImage(ImageSource source, bool isSelfie) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 1024,
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

  /*Future<void> _completeRegistration() async {
    if (_licenseFile == null || _selfieFile == null) {
      _showSnackBar("Please complete both License and Face verification", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    _showSnackBar("Processing biometric validation...", isError: false);

    List<double>? licenseEmbeddings = await _extractEmbeddings(_licenseFile!);
    if (licenseEmbeddings == null) {
      _showSnackBar("Could not read a clear face from your Driving License.", isError: true);
      setState(() => _isLoading = false);
      return;
    }

    List<double>? selfieEmbeddings = await _extractEmbeddings(_selfieFile!);
    if (selfieEmbeddings == null) {
      _showSnackBar("Could not read a clear face from your Selfie live photo.", isError: true);
      setState(() => _isLoading = false);
      return;
    }

    double distance = _calculateDistance(licenseEmbeddings, selfieEmbeddings);
    debugPrint("DEBUG: Calculated face biometric distance -> $distance");

    if (distance > 0.6) {
      _showSnackBar("Face Verification Failed! The selfie face does not match your driving license document.", isError: true);
      setState(() => _isLoading = false);
      return;
    }

    _showSnackBar("Biometrics matched! finalising registration...", isError: false);

    final authProvider = Provider.of<AuthProviderMethod>(context, listen: false);

    final message = await authProvider.signUpWithEmailAndPassword(
      widget.name,
      widget.email,
      widget.password,
      widget.phone,
      'driver',
      licenseFile: _licenseFile,
      faceEmbeddings: selfieEmbeddings,
    );

    if (!mounted) return;

    if (message == 'Success') {
      _showSnackBar("Account created! Welcome onboard.", isError: false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    } else {
      setState(() => _isLoading = false);
      _showSnackBar(message, isError: true);
    }
  }*/

  Future<void> _completeRegistration() async {
    if (_licenseFile == null || _selfieFile == null) {
      _showSnackBar("Please complete both License and Face verification", isError: true);
      return;
    }

    // FIX: Read the provider here, completely BEFORE the first async gap
    final authProvider = Provider.of<AuthProviderMethod>(context, listen: false);

    setState(() => _isLoading = true);
    _showSnackBar("Processing biometric validation...", isError: false);

    // --- Async Gap 1 ---
    List<double>? licenseEmbeddings = await _extractEmbeddings(_licenseFile!);
    if (licenseEmbeddings == null) {
      _showSnackBar("Could not read a clear face from your Driving License.", isError: true);
      setState(() => _isLoading = false);
      return;
    }

    // --- Async Gap 2 ---
    List<double>? selfieEmbeddings = await _extractEmbeddings(_selfieFile!);
    if (selfieEmbeddings == null) {
      _showSnackBar("Could not read a clear face from your Selfie live photo.", isError: true);
      setState(() => _isLoading = false);
      return;
    }

    double distance = _calculateDistance(licenseEmbeddings, selfieEmbeddings);
    debugPrint("DEBUG: Calculated face biometric distance -> $distance");

    if (distance > 0.6) {
      _showSnackBar("Face Verification Failed! The selfie face does not match your driving license document.", isError: true);
      setState(() => _isLoading = false);
      return;
    }

    _showSnackBar("Biometrics matched! finalising registration...", isError: false);

    // --- Async Gap 3 ---
    // Safe to use here now because we are referencing a local variable instead of searching the context tree late
    final message = await authProvider.signUpWithEmailAndPassword(
      widget.name,
      widget.email,
      widget.password,
      widget.phone,
      'driver',
      licenseFile: _licenseFile,
      faceEmbeddings: selfieEmbeddings,
    );

    // Guard safety check for the navigation context lookup below
    if (!mounted) return;

    if (message == 'Success') {
      _showSnackBar("Account created! Welcome onboard.", isError: false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    } else {
      setState(() => _isLoading = false);
      _showSnackBar(message, isError: true);
    }
  }

  double _calculateDistance(List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) return 999.0;
    double sum = 0.0;
    for (int i = 0; i < embedding1.length; i++) {
      double diff = embedding1[i] - embedding2[i];
      sum += diff * diff;
    }
    return sqrt(sum);
  }

  Future<List<double>?> _extractEmbeddings(XFile file) async {
    // Fail-safe protection if this triggers inside an unsupported web browser environment
    if (kIsWeb) return null;

    final options = FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate);
    final faceDetector = FaceDetector(options: options);
    final inputImage = InputImage.fromFilePath(file.path);

    try {
      List<Face> faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      if (faces.isEmpty) return null;

      Face face = faces.first;
      Rect boundingBox = face.boundingBox;

      final rawImageBytes = await File(file.path).readAsBytes();
      img.Image? originalImage = img.decodeImage(rawImageBytes);
      if (originalImage == null) return null;

      int x = boundingBox.left.toInt().clamp(0, originalImage.width);
      int y = boundingBox.top.toInt().clamp(0, originalImage.height);
      int width = boundingBox.width.toInt().clamp(1, originalImage.width - x);
      int height = boundingBox.height.toInt().clamp(1, originalImage.height - y);

      img.Image croppedFace = img.copyCrop(originalImage, x: x, y: y, width: width, height: height);
      img.Image resizedFace = img.copyResize(croppedFace, width: 112, height: 112);

      // Run via our decoupled platform-safe architecture instance runner wrapper
      return _faceService.runInference(resizedFace);
    } catch (e) {
      debugPrint("Error extracting embeddings: $e");
    }
    return null;
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: isError ? Colors.red : Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keeping your exact user interface build context structural configuration unchanged...
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
                subtitle: "Upload a clear photo of your license",
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
                      : const Text("FINISH REGISTRATION", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
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





/*import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img; // Used for high-performance image cropping
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

// Assumptions based on your file imports
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
  XFile? _licenseFile;
  XFile? _selfieFile;

  bool _isLoading = false;
  Interpreter? _tfliteInterpreter;

  @override
  void initState() {
    super.initState();
    _initTfliteModel();
  }

  @override
  void dispose() {
    _tfliteInterpreter?.close();
    super.dispose();
  }

  // Initialize your local TFLite Model for Face Recognition
  Future<void> _initTfliteModel() async {
    try {
      // Loads mobilefacenet.tflite or similar from assets folder
      _tfliteInterpreter = await Interpreter.fromAsset('assets/mobilefacenet.tflite');
      debugPrint("DEBUG: TFLite Face Recognition Model loaded successfully.");
    } catch (e) {
      debugPrint("DEBUG: Failed to load TFLite model: $e");
    }
  }

  Future<void> _pickImage(ImageSource source, bool isSelfie) async {
    debugPrint("DEBUG: Starting image pick. Source: $source");
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 50, // Keep quality moderate so ML kit reads lines easily
        maxWidth: 1024,
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

  /// The Full ML Pipeline: Detect Face -> Crop Face -> Get TFLite Embeddings
  Future<List<double>?> _processFaceVerification() async {
    if (_selfieFile == null) return null;

    // 1. Initialize ML Kit Face Detector
    final options = FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
    );
    final faceDetector = FaceDetector(options: options);
    final inputImage = InputImage.fromFilePath(_selfieFile!.path);

    try {
      List<Face> faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      if (faces.isEmpty) {
        _showSnackBar("No face detected in the selfie. Please reposition your camera.", isError: true);
        return null;
      }
      if (faces.length > 1) {
        _showSnackBar("Multiple faces detected. Please make sure only you are in frame.", isError: true);
        return null;
      }

      // Get the bounding rectangle coordinates around the detected face
      Face face = faces.first;
      Rect boundingBox = face.boundingBox;

      // 2. Crop Face from original image data using package:image
      final rawImageBytes = await File(_selfieFile!.path).readAsBytes();
      img.Image? originalImage = img.decodeImage(rawImageBytes);
      if (originalImage == null) return null;

      // Ensure cropping coordinates fit within image limits safely
      int x = boundingBox.left.toInt().clamp(0, originalImage.width);
      int y = boundingBox.top.toInt().clamp(0, originalImage.height);
      int width = boundingBox.width.toInt().clamp(1, originalImage.width - x);
      int height = boundingBox.height.toInt().clamp(1, originalImage.height - y);

      img.Image croppedFace = img.copyCrop(originalImage, x: x, y: y, width: width, height: height);

      // 3. Preprocess for your specific TFLite Model (MobileFaceNet uses 112x112 input)
      img.Image resizedFace = img.copyResize(croppedFace, width: 112, height: 112);

      // Convert image matrix pixels to standard Float32 modern model formats [1, 112, 112, 3]
      var input = _convertImageToMatrix(resizedFace);

      // Output allocation array for 128 embedding floats matching model architecture output
      var output = List.filled(1 * 128, 0.0).reshape([1, 128]);

      // 4. Run Model Prediction Inference
      if (_tfliteInterpreter != null) {
        _tfliteInterpreter!.run(input, output);
        List<double> embeddings = List<double>.from(output[0]);
        debugPrint("DEBUG: Face Embeddings Generated successfully: ${embeddings.sublist(0, 5)}...");
        return embeddings;
      } else {
        debugPrint("DEBUG: TFLite interpreter was null, skipping running inference.");
      }
    } catch (e) {
      debugPrint("DEBUG: Error processing ML pipeline: $e");
      _showSnackBar("Error interpreting biometric validation: $e", isError: true);
    }
    return null;
  }

  // Helper method converting package:image pixel streams into neural network input matrices
  List _convertImageToMatrix(img.Image image) {
    var convertedBytes = Float32List(1 * 112 * 112 * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        var pixel = image.getPixel(x, y);
        // Normalize pixel maps to scales from -1 to 1 or 0 to 1 depending on model training styles
        buffer[pixelIndex++] = (pixel.r - 127.5) / 127.5;
        buffer[pixelIndex++] = (pixel.g - 127.5) / 127.5;
        buffer[pixelIndex++] = (pixel.b - 127.5) / 127.5;
      }
    }
    return convertedBytes.reshape([1, 112, 112, 3]);
  }

  Future<void> _completeRegistration() async {
    if (_licenseFile == null || _selfieFile == null) {
      _showSnackBar("Please complete both License and Face verification", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    _showSnackBar("Processing biometric validation...", isError: false);

    // 1. Extract embeddings for License face
    List<double>? licenseEmbeddings = await _extractEmbeddings(_licenseFile!);
    if (licenseEmbeddings == null) {
      _showSnackBar("Could not read a clear face from your Driving License.", isError: true);
      setState(() => _isLoading = false);
      return;
    }

    // 2. Extract embeddings for Selfie face
    List<double>? selfieEmbeddings = await _extractEmbeddings(_selfieFile!);
    if (selfieEmbeddings == null) {
      _showSnackBar("Could not read a clear face from your Selfie live photo.", isError: true);
      setState(() => _isLoading = false);
      return;
    }

    // 3. Compare them using Euclidean Distance
    double distance = _calculateDistance(licenseEmbeddings, selfieEmbeddings);
    debugPrint("DEBUG: Calculated face biometric distance -> $distance");

    // Threshold check (0.6 is typical for MobileFaceNet)
    if (distance > 0.6) {
      _showSnackBar("Face Verification Failed! The selfie face does not match your driving license document.", isError: true);
      setState(() => _isLoading = false);
      return;
    }

    _showSnackBar("Biometrics matched! finalising registration...", isError: false);

    // 4. Everything matches! Pass the data down to Cloudinary & Firebase
    final authProvider = Provider.of<AuthProviderMethod>(context, listen: false);

    final message = await authProvider.signUpWithEmailAndPassword(
      widget.name,
      widget.email,
      widget.password,
      widget.phone,
      'driver',
      licenseFile: _licenseFile,
      faceEmbeddings: selfieEmbeddings, // Save the clean live selfie embeddings to Firestore
    );

    if (!mounted) return;

    if (message == 'Success') {
      _showSnackBar("Account created! Welcome onboard.", isError: false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
      );
    } else {
      setState(() => _isLoading = false);
      _showSnackBar(message, isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // 1. HELPER: Calculate the distance between two embedding arrays
  double _calculateDistance(List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) return 999.0; // Fail safe

    double sum = 0.0;
    for (int i = 0; i < embedding1.length; i++) {
      double diff = embedding1[i] - embedding2[i];
      sum += diff * diff;
    }
    return sqrt(sum); // Requires 'import 'dart:math';' at the top of your file
  }

  // 2. CORE PIPELINE: Extract embeddings from a single file path
  Future<List<double>?> _extractEmbeddings(XFile file) async {
    final options = FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate);
    final faceDetector = FaceDetector(options: options);
    final inputImage = InputImage.fromFilePath(file.path);

    try {
      List<Face> faces = await faceDetector.processImage(inputImage);
      await faceDetector.close();

      if (faces.isEmpty) return null;

      Face face = faces.first;
      Rect boundingBox = face.boundingBox;

      final rawImageBytes = await File(file.path).readAsBytes();
      img.Image? originalImage = img.decodeImage(rawImageBytes);
      if (originalImage == null) return null;

      int x = boundingBox.left.toInt().clamp(0, originalImage.width);
      int y = boundingBox.top.toInt().clamp(0, originalImage.height);
      int width = boundingBox.width.toInt().clamp(1, originalImage.width - x);
      int height = boundingBox.height.toInt().clamp(1, originalImage.height - y);

      img.Image croppedFace = img.copyCrop(originalImage, x: x, y: y, width: width, height: height);
      img.Image resizedFace = img.copyResize(croppedFace, width: 112, height: 112);

      var input = _convertImageToMatrix(resizedFace);
      var output = List.filled(1 * 128, 0.0).reshape([1, 128]);

      if (_tfliteInterpreter != null) {
        _tfliteInterpreter!.run(input, output);
        return List<double>.from(output[0]);
      }
    } catch (e) {
      debugPrint("Error extracting embeddings: $e");
    }
    return null;
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
              const Text("Last Step!",
                  style: TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("Submit your documents to start verification.",
                  style: TextStyle(color: Colors.black87, fontSize: 15)),
              const SizedBox(height: 40),

              _buildUploadCard(
                title: "Driving License",
                subtitle: "Upload a clear photo of your license",
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

*/