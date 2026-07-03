import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DriverCarAvatarWidget extends StatelessWidget {
  final String driverId;

  const DriverCarAvatarWidget({super.key, required this.driverId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      // Fetch the document directly from the 'drivers' collection
      future: FirebaseFirestore.instance.collection('drivers').doc(driverId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircleAvatar(radius: 30, child: CircularProgressIndicator(strokeWidth: 2));
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          var driverData = snapshot.data!.data() as Map<String, dynamic>;
          String? imageUrl = driverData['image'];

          return CircleAvatar(
            radius: 30,
            backgroundColor: Colors.orange.shade100,
            backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                ? NetworkImage(imageUrl)
                : null,
            child: (imageUrl == null || imageUrl.isEmpty)
                ? const Icon(Icons.directions_car, color: Colors.orange)
                : null,
          );
        }

        // Fallback if driver data is missing
        return const CircleAvatar(radius: 30, child: Icon(Icons.person_off));
      },
    );
  }
}