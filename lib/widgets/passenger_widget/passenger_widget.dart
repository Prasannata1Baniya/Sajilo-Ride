import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';



BoxDecoration panelDecoration({bool isMobile = false}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: isMobile ? const BorderRadius.vertical(top: Radius.circular(30)) : BorderRadius.circular(20),
    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 15, spreadRadius: 5)],
  );
}
