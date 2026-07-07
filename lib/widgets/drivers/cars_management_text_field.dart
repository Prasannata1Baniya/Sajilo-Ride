import 'package:flutter/material.dart';

Widget buildTextField(TextEditingController controller, String label, String hint, IconData icon) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: TextFormField(
      controller: controller,
      cursorColor: Colors.orange.shade700,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade50,
        prefixIcon: Icon(icon, color: Colors.orange.shade700),

        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 2),
        ),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.orange.shade700, width: 2),
        ),

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),

        labelStyle: TextStyle(color: Colors.grey.shade600),
        floatingLabelStyle: TextStyle(color: Colors.orange.shade700, fontWeight: FontWeight.bold),
      ),
      validator: (value) => value == null || value.isEmpty ? "Required field" : null,
    ),
  );
}