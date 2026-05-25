import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sajilo_ride/auth/auth_provider.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:geolocator/geolocator.dart';

class CarManagementContent extends StatefulWidget {
  const CarManagementContent({super.key});

  @override
  State<CarManagementContent> createState() => _CarManagementContentState();
}

class _CarManagementContentState extends State<CarManagementContent> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _numController = TextEditingController();

  String _fuelType = 'Petrol';
  String? _carImageUrl;
  Uint8List? _webImage;
  File? _mobileImage;
  bool _isLoading = false;
  bool _isDataLoaded = false;

  // Controls whether we display the beautiful summary or the input fields
  bool _isEditingMode = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _modelController.dispose();
    _plateController.dispose();
    _colorController.dispose();
    _priceController.dispose();
    _distanceController.dispose();
    _numController.dispose();
    super.dispose();
  }

  void _loadData(Map<String, dynamic> data) {
    if (_isDataLoaded) return;
    _modelController.text = data['model'] ?? '';
    _plateController.text = data['carNumber'] ?? '';
    _numController.text = data['phone'] ?? '';
    _priceController.text = (data['pricePerKm'] ?? '').toString();
    _distanceController.text = (data['distance'] ?? '').toString();
    _carImageUrl = data['image'];
    _colorController.text = data['carColor'] ?? '';
    _fuelType = data['vehicleType'] ?? 'Petrol';
    _isDataLoaded = true;
  }

  // ... Keep your _pickImage, _uploadToCloudinary exactly as they are ...
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() => _webImage = bytes);
      } else {
        setState(() => _mobileImage = File(pickedFile.path));
      }
    }
  }

  Future<String?> _uploadToCloudinary() async {
    const cloudName = "dvezp7njs";
    const uploadPreset = "sajilo_preset";
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    var request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = uploadPreset;
    if (kIsWeb) {
      request.files.add(http.MultipartFile.fromBytes('file', _webImage!, filename: 'upload.jpg'));
    } else {
      request.files.add(await http.MultipartFile.fromPath('file', _mobileImage!.path));
    }
    final response = await request.send();
    final resBody = await response.stream.bytesToString();
    if (response.statusCode == 200) return jsonDecode(resBody)['secure_url'];
    return null;
  }

  Future<void> _saveCarDetails(String driverId) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProviderMethod>(context, listen: false);
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
      );
      String hash = GeoHasher().encode(position.longitude, position.latitude);

      String? finalImageUrl = _carImageUrl;
      if (_webImage != null || _mobileImage != null) {
        finalImageUrl = await _uploadToCloudinary();
      }

      await FirebaseFirestore.instance.collection('drivers').doc(driverId).set({
        'location': {'geohash': hash, 'geopoint': GeoPoint(position.latitude, position.longitude)},
        'latitude': position.latitude, 'longitude': position.longitude,
        'model': _modelController.text.trim(),
        'carNumber': _plateController.text.trim(),
        'driverName': authProvider.user?.displayName ?? 'Unknown Driver',
        'phone': _numController.text.trim(),
        'image': finalImageUrl,
        'driverId': driverId,
        'plateNumber': _plateController.text.trim(),
        'carColor': _colorController.text.trim(),
        'vehicleType': _fuelType,
        'pricePerKm': double.tryParse(_priceController.text) ?? 0.0,
        'distance': double.tryParse(_distanceController.text) ?? 0.0,
        'isOnline': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Vehicle details updated successfully!"), backgroundColor: Colors.green)
        );
        setState(() => _isEditingMode = false); // Flip back to view mode cleanly
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderMethod>(context);
    final driverId = authProvider.user?.uid;

    if (driverId == null) {
      return const Scaffold(body: Center(child: Text("Error: Not logged in.")));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('drivers').doc(driverId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.orange)));
        }

        bool hasExistingData = snapshot.hasData && snapshot.data!.exists;
        if (hasExistingData) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          _loadData(data);
        }

        // --- LOOK HERE: IF DATA EXISTS AND WE ARE NOT EDITING, SHOW THE PRETTY DISPLAY ---
        if (hasExistingData && !_isEditingMode) {
          return _buildReadOnlyProfileView();
        }

        // --- OTHERWISE, SHOW THE CLEAN INPUT FORM ---
        return _buildEditableFormView(driverId);
      },
    );
  }

  // ==========================================
  // VIEW 1: THE CLEAN READ-ONLY PROFILE (NO TEXTFIELDS)
  // ==========================================
  Widget _buildReadOnlyProfileView() {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Vehicle Details"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _isEditingMode = true),
            icon: const Icon(Icons.edit, color: Colors.white, size: 18),
            label: const Text("EDIT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle Large Image Container
            Container(
              height: 220, width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200], borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                image: _carImageUrl != null
                    ? DecorationImage(image: NetworkImage(_carImageUrl!), fit: BoxFit.cover)
                    : null,
              ),
              child: _carImageUrl == null
                  ? const Icon(Icons.directions_car, size: 80, color: Colors.grey)
                  : null,
            ),
            const SizedBox(height: 24),

            // Car Model & Badge Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_modelController.text, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(_colorController.text, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                  child: Text(_fuelType, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            const Divider(height: 40),

            // Information Grid Layout
            _buildProfileDataRow(Icons.pin, "License Plate", _plateController.text),
            _buildProfileDataRow(Icons.phone, "Driver Contact", _numController.text),
            _buildProfileDataRow(Icons.payments_outlined, "Rate per Kilometer", "Rs. ${_priceController.text} / km"),
            _buildProfileDataRow(Icons.map_outlined, "Base Search Range", "${_distanceController.text} km"),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileDataRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        children: [
          CircleAvatar(radius: 22, backgroundColor: Colors.grey[100], child: Icon(icon, color: Colors.orange)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
            ],
          )
        ],
      ),
    );
  }

  // ==========================================
  // VIEW 2: THE FORM VIEW (ONLY FOR NEW REGISTER OR EDIT MODE)
  // ==========================================
  Widget _buildEditableFormView(String driverId) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_carImageUrl == null ? "Register Vehicle" : "Edit Vehicle Details"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        leading: _carImageUrl != null
            ? IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _isEditingMode = false))
            : null,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text("Upload Car Photo", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180, width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100], borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.orange.withOpacity(0.5)),
                    image: _webImage != null
                        ? DecorationImage(image: MemoryImage(_webImage!), fit: BoxFit.cover)
                        : (_mobileImage != null
                        ? DecorationImage(image: FileImage(_mobileImage!), fit: BoxFit.cover)
                        : (_carImageUrl != null
                        ? DecorationImage(image: NetworkImage(_carImageUrl!), fit: BoxFit.cover)
                        : null)),
                  ),
                  child: (_webImage == null && _mobileImage == null && _carImageUrl == null)
                      ? const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.orange),
                      SizedBox(height: 8),
                      Text("Tap to browse gallery", style: TextStyle(color: Colors.grey)),
                    ],
                  ) : null,
                ),
              ),

              const SizedBox(height: 24),
              _buildTextField(_modelController, "Car Model", "e.g. Toyota Corolla", Icons.car_rental),
              _buildTextField(_plateController, "License Plate", "e.g. BA 1 PA 1234", Icons.tag),
              _buildTextField(_numController, "Contact Phone", "e.g. 98XXXXXXXX", Icons.phone),
              _buildTextField(_colorController, "Car Color", "e.g. White", Icons.color_lens),

              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _fuelType,
                items: ['Petrol', 'Diesel', 'Electric', 'Hybrid']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (val) => setState(() => _fuelType = val!),
                decoration: const InputDecoration(labelText: "Fuel Type", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),

              _buildTextField(_priceController, "Price per km (Rs)", "e.g. 45", Icons.payment),
              _buildTextField(_distanceController, "Search Distance Profile (km)", "e.g. 10", Icons.social_distance),

              const SizedBox(height: 24),
              Row(
                children: [
                  if (_carImageUrl != null) ...[
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52), side: const BorderSide(color: Colors.orange)),
                        onPressed: () => setState(() => _isEditingMode = false),
                        child: const Text("CANCEL", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, minimumSize: const Size(0, 52)),
                      onPressed: _isLoading ? null : () => _saveCarDetails(driverId),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, hintText: hint, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        validator: (value) => value == null || value.isEmpty ? "Required field" : null,
      ),
    );
  }
}










/*import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sajilo_ride/auth/auth_provider.dart';
import 'package:dart_geohash/dart_geohash.dart';
import 'package:geolocator/geolocator.dart';

class CarManagementContent extends StatefulWidget {
  const CarManagementContent({super.key});

  @override
  State<CarManagementContent> createState() => _CarManagementContentState();
}

class _CarManagementContentState extends State<CarManagementContent> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _distanceController = TextEditingController();
  final TextEditingController _numController = TextEditingController();

  String _fuelType = 'Petrol';
  String? _carImageUrl;
  Uint8List? _webImage;
  File? _mobileImage;
  bool _isLoading = false;
  bool _isDataLoaded = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _modelController.dispose();
    _plateController.dispose();
    _colorController.dispose();
    _priceController.dispose();
    _distanceController.dispose();
    _numController.dispose();
    super.dispose();
  }

  // ... (Keep your _pickImage, _buildTextField, and _uploadToCloudinary exactly as they are) ...

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() => _webImage = bytes);
      } else {
        setState(() => _mobileImage = File(pickedFile.path));
      }
    }
  }

  void _loadData(Map<String, dynamic> data) {
    if (_isDataLoaded) return;
    _modelController.text = data['model'] ?? '';
    _plateController.text = data['carNumber'] ?? '';
    _numController.text = data['phone'] ?? '';
    _priceController.text = (data['pricePerKm'] ?? '').toString();
    _distanceController.text = (data['distance'] ?? '').toString();
    _carImageUrl = data['image'];
    _colorController.text = data['carColor'] ?? '';
    _fuelType = data['vehicleType'] ?? 'Petrol';
    _isDataLoaded = true;
  }

  Future<void> _saveCarDetails(String driverId) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProviderMethod>(context, listen: false);

      // 1. Get Current Position for the Geohash
      Position position = await Geolocator.getCurrentPosition(
         locationSettings: LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10,),
          //desiredAccuracy: LocationAccuracy.high
      );

      // 2. Generate Geohash manually
      String hash = GeoHasher().encode(position.longitude, position.latitude);

      // 3. Handle Image Upload
      String? finalImageUrl = _carImageUrl;
      if (_webImage != null || _mobileImage != null) {
        finalImageUrl = await _uploadToCloudinary();
      }

      // 4. Save to Firestore with the correct 'location' structure
      await FirebaseFirestore.instance.collection('drivers').doc(driverId).set({
        'location': {
          'geohash': hash,
          'geopoint': GeoPoint(position.latitude, position.longitude),
        },
        'latitude': position.latitude, // Store these for your Map Markers
        'longitude': position.longitude,
        'model': _modelController.text.trim(),
        'carNumber': _plateController.text.trim(),
        'driverName': authProvider.user?.displayName ?? 'Unknown Driver',
        'phone': _numController.text.trim(),
        'image': finalImageUrl,
        'driverId': driverId,
        'plateNumber': _plateController.text.trim(),
        'carColor': _colorController.text.trim(),
        'vehicleType': _fuelType,
        'pricePerKm': double.tryParse(_priceController.text) ?? 0.0,
        'distance': double.tryParse(_distanceController.text) ?? 0.0,
        'isOnline': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Vehicle details saved!"), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  Widget _buildTextField(TextEditingController controller, String label, String hint, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label, hintText: hint, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        validator: (value) => value == null || value.isEmpty ? "Required field" : null,
      ),
    );
  }

  Future<String?> _uploadToCloudinary() async {
    const cloudName = "dvezp7njs";
    const uploadPreset = "sajilo_preset";
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    var request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = uploadPreset;

    if (kIsWeb) {
      request.files.add(http.MultipartFile.fromBytes('file', _webImage!, filename: 'upload.jpg'));
    } else {
      request.files.add(await http.MultipartFile.fromPath('file', _mobileImage!.path));
    }

    final response = await request.send();
    final resBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(resBody)['secure_url'];
    }
    return null;
  }


  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderMethod>(context);
    final driverId = authProvider.user?.uid;

    if (driverId == null) {
      return const Scaffold(body: Center(child: Text("Error: Not logged in.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Car Management"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('drivers').doc(driverId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>;
            _loadData(data);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const Text("Car Photo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200, width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200], borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.orange),
                        image: _webImage != null
                            ? DecorationImage(image: MemoryImage(_webImage!), fit: BoxFit.cover)
                            : (_mobileImage != null
                            ? DecorationImage(image: FileImage(_mobileImage!), fit: BoxFit.cover)
                            : (_carImageUrl != null
                            ? DecorationImage(image: NetworkImage(_carImageUrl!), fit: BoxFit.cover)
                            : null)),
                      ),
                      child: (_webImage == null && _mobileImage == null && _carImageUrl == null)
                          ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 50, color: Colors.orange),
                          Text("Tap to upload car image"),
                        ],
                      ) : null,
                    ),
                  ),

                  const SizedBox(height: 30),

                  _buildTextField(_modelController, "Car Model", "e.g. Toyota Corolla", Icons.car_rental),
                  _buildTextField(_plateController, "License Plate", "e.g. BA 1 PA 1234", Icons.numbers),
                  _buildTextField(_numController, "Contact Phone", "e.g. 98XXXXXXXX", Icons.phone),
                  _buildTextField(_colorController, "Car Color", "e.g. White", Icons.color_lens),

                  const SizedBox(height: 20),

                  DropdownButtonFormField<String>(
                    initialValue: _fuelType,
                    items: ['Petrol', 'Diesel', 'Electric', 'Hybrid']
                        .map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                    onChanged: (val) => setState(() => _fuelType = val!),
                    decoration: const InputDecoration(labelText: "Fuel Type", border: OutlineInputBorder()),
                  ),

                  const SizedBox(height: 20),
                  _buildTextField(_priceController, "Price per km (Rs)", "e.g. 45", Icons.payment),
                  _buildTextField(_distanceController, "Distance (km)", "e.g. 10", Icons.social_distance),
                  //_buildTextField(_fuelCapacityController, "Fuel Capacity (L)", "e.g. 40", Icons.local_gas_station),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity, height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      onPressed: _isLoading ? null : () => _saveCarDetails(driverId),
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("SAVE VEHICLE DETAILS", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
*/