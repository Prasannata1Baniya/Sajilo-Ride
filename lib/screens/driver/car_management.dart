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

  // Controllers to handle text input
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  String _fuelType = 'Petrol'; // Default value

  bool _isLoading = false;

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
        // Listen to this specific driver's car details
        stream: FirebaseFirestore.instance.collection('drivers').doc(driverId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // If data exists, pre-fill the controllers
          if (snapshot.hasData && snapshot.data!.exists) {
            var data = snapshot.data!.data() as Map<String, dynamic>;
            _modelController.text = data['carModel'] ?? '';
            _plateController.text = data['plateNumber'] ?? '';
            _colorController.text = data['carColor'] ?? '';
            _fuelType = data['fuelType'] ?? 'Petrol';
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Icon(Icons.directions_car_filled, size: 80, color: Colors.orange),
                  ),
                  const SizedBox(height: 20),
                  const Text("Vehicle Information", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text("Update your car details so passengers can identify you.", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 30),

                  _buildTextField(_modelController, "Car Model", "e.g. Toyota Corolla", Icons.car_rental),
                  _buildTextField(_plateController, "License Plate", "e.g. BA 1 PA 1234", Icons.numbers),
                  _buildTextField(_colorController, "Car Color", "e.g. White", Icons.color_lens),

                  const SizedBox(height: 20),
                  const Text("Fuel Type", style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    isExpanded: true,
                    value: _fuelType,
                    items: ['Petrol', 'Diesel', 'Electric', 'Hybrid'].map((String value) {
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() => _fuelType = newValue!);
                    },
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading ? null : () => _saveCarDetails(driverId!),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("SAVE VEHICLE DETAILS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  // --- HELPER: TEXT FIELD UI ---
  Widget _buildTextField(TextEditingController controller, String label, String hint, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) => value!.isEmpty ? "Required field" : null,
      ),
    );
  }

  // --- LOGIC: SAVE TO FIRESTORE ---
  Future<void> _saveCarDetails(String driverId) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance.collection('drivers').doc(driverId).set({
          'carModel': _modelController.text,
          'plateNumber': _plateController.text,
          'carColor': _colorController.text,
          'fuelType': _fuelType,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)); // Use merge to keep other profile data safe

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Vehicle details updated successfully!"), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}