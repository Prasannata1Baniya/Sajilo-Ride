import 'package:flutter/material.dart';


class InputDecorate {
  InputDecoration buildInputDecoration(String label, {Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      suffixIcon: suffixIcon,

      labelStyle: TextStyle(
        color: Colors.black.withValues(alpha: 0.5),
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      ),
      floatingLabelStyle: const TextStyle(
        color: Colors.orangeAccent,
        fontWeight: FontWeight.w600,
        fontSize: 15,
        letterSpacing: 0.2,
      ),

      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.6),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 20.0,
        horizontal: 20.0,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.black.withValues(alpha: 0.08),
          width: 1.0,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.orangeAccent,
          width: 1.5,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.redAccent.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),

      errorStyle: const TextStyle(
        color: Colors.redAccent,
        fontWeight: FontWeight.w500,
        fontSize: 13,
      ),
    );
  }
}

/*class InputDecorate {  InputDecoration buildInputDecoration(String label, {Widget? suffixIcon}) {
  return InputDecoration(
    labelText: label,
    suffixIcon: suffixIcon,
    labelStyle: const TextStyle(color: Colors.black, fontSize: 14),
    floatingLabelStyle: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold),
    filled: true,
    //fillColor: Colors.grey[200],
    fillColor: Colors.grey.withValues(alpha: 0.3),
    //fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(vertical: 18.0,
        horizontal: 16.0),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.3)),
     // borderSide: BorderSide(color: Colors.white),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Colors.orangeAccent, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(
        color: Colors.red.withValues(alpha: 0.6),
        width: 3,
      ),
    ),

    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(
        color: Colors.red,
        width: 3,
      ),
    ),

    errorStyle: const TextStyle(
      color: Colors.red,
      fontWeight: FontWeight.w500,
      fontSize: 16,
    ),
  );
}
}*/