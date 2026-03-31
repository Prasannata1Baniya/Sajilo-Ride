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
  final TextEditingController _fuelCapacityController = TextEditingController();

  String _fuelType = 'Petrol';
  String? _carImageUrl;

  // WEB + MOBILE SUPPORT
  Uint8List? _webImage;
  File? _mobileImage;

  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImage = bytes;
        });
      } else {
        setState(() {
          _mobileImage = File(pickedFile.path);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderMethod>(context);
    final driverId = authProvider.user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Car Management"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('drivers')
            .doc(driverId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data!.exists) {
            var data = snapshot.data!.data() as Map<String, dynamic>;

            if (_modelController.text.isEmpty) {
              _modelController.text = data['carModel'] ?? '';
            }
            if (_plateController.text.isEmpty) {
              _plateController.text = data['plateNumber'] ?? '';
            }
            if (_colorController.text.isEmpty) {
              _colorController.text = data['carColor'] ?? '';
            }

            _fuelType = data['fuelType'] ?? 'Petrol';
            _carImageUrl = data['carImage'];
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Car Photo",
                      style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.5)),
                        image: _webImage != null
                            ? DecorationImage(
                            image: MemoryImage(_webImage!),
                            fit: BoxFit.cover)
                            : (_mobileImage != null
                            ? DecorationImage(
                            image: FileImage(_mobileImage!),
                            fit: BoxFit.cover)
                            : (_carImageUrl != null
                            ? DecorationImage(
                            image: NetworkImage(_carImageUrl!),
                            fit: BoxFit.cover)
                            : null)),
                      ),
                      child: (_webImage == null &&
                          _mobileImage == null &&
                          _carImageUrl == null)
                          ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo,
                              size: 50, color: Colors.orange),
                          Text("Upload Car Image",
                              style: TextStyle(color: Colors.orange)),
                        ],
                      )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 30),

                  _buildTextField(_modelController, "Car Model",
                      "e.g. Toyota Corolla", Icons.car_rental),
                  _buildTextField(_plateController, "License Plate",
                      "e.g. BA 1 PA 1234", Icons.numbers),
                  _buildTextField(_colorController, "Car Color",
                      "e.g. White", Icons.color_lens),

                  const SizedBox(height: 20),

                  const Text("Fuel Type",
                      style: TextStyle(fontWeight: FontWeight.bold)),

                  DropdownButton<String>(
                    isExpanded: true,
                    value: _fuelType,
                    items: ['Petrol', 'Diesel', 'Electric', 'Hybrid']
                        .map((value) => DropdownMenuItem(
                      value: value,
                      child: Text(value),
                    ))
                        .toList(),
                    onChanged: (newValue) {
                      setState(() => _fuelType = newValue!);
                    },
                  ),

                  _buildTextField(
                    _priceController,
                    "Price per Hour",
                    "e.g. 500",
                    Icons.attach_money,
                  ),

                  _buildTextField(
                    _distanceController,
                    "Distance (km)",
                    "e.g. 10",
                    Icons.social_distance,
                  ),

                  _buildTextField(
                    _fuelCapacityController,
                    "Fuel Capacity (liters)",
                    "e.g. 40",
                    Icons.local_gas_station,
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed:
                      _isLoading ? null : () => _saveCarDetails(driverId!),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                          color: Colors.white)
                          : const Text(
                        "SAVE VEHICLE DETAILS",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
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

  Widget _buildTextField(TextEditingController controller, String label,
      String hint, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) =>
        value == null || value.isEmpty ? "Required field" : null,
      ),
    );
  }

  // CLOUDINARY UPLOAD (WEB + MOBILE)
  Future<String?> _uploadToCloudinary() async {
    const cloudName = "dvezp7njs";
    const uploadPreset = "sajilo_preset";

    final uri =
    Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    try {
      var request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = uploadPreset;

      if (kIsWeb) {
        request.files.add(http.MultipartFile.fromBytes(
          'file',
          _webImage!,
          filename: 'upload.jpg',
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'file',
          _mobileImage!.path,
        ));
      }

      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(resBody);
        return data['secure_url'];
      } else {
        debugPrint("Cloudinary error: $resBody");
        return null;
      }
    } catch (e) {
      debugPrint("Upload error: $e");
      return null;
    }
  }

  Future<void> _saveCarDetails(String driverId) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? finalImageUrl = _carImageUrl;

      if (_webImage != null || _mobileImage != null) {
        finalImageUrl = await _uploadToCloudinary();

        if (finalImageUrl == null) {
          throw Exception("Image upload failed");
        }
      }

      await FirebaseFirestore.instance
          .collection('drivers')
          .doc(driverId)
          .set({
        'carModel': _modelController.text,
        'plateNumber': _plateController.text,
        'carColor': _colorController.text,
        'fuelType': _fuelType,
        'carImage': finalImageUrl,
        'pricePerHour':
        double.tryParse(_priceController.text) ?? 0.0,
        'distance':
        double.tryParse(_distanceController.text) ?? 0.0,
        'fuelCapacity':
        double.tryParse(_fuelCapacityController.text) ?? 0.0,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Details updated!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

