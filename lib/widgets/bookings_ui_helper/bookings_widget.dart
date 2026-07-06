import 'package:flutter/material.dart';

Widget buildStatusBadge(String status) {
  Color color = status == 'ongoing' ? Colors.blue : (status == 'pending' ? Colors.orange : Colors.green);
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
    child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
  );
}

// for info rows
Widget buildInfoTile(IconData icon, String label, String value, Color iconColor) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: iconColor),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ],
  );
}

Widget buildNoRidesPlaceholder() {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow:
          [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20)]),
          child: Icon(Icons.no_transfer, size: 80, color: Colors.grey[300]),
        ),
        const SizedBox(height: 25),
        const Text("No Active Rides Found", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        const Text("Time to explore! Start your first ride today.", style: TextStyle(color: Colors.grey, fontSize: 15)),
      ],
    ),
  );
}