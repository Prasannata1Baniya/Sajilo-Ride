import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sajilo_ride/screens/passenger/bookings_page.dart';

class AppNotification {
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;

  AppNotification({required this.title, required this.body, required this.timestamp, this.isRead = false});
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
          title: const Text("Notifications"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder(
        stream:currentUserId == null
            ? const Stream.empty()
            : FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('notifications')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No notifications yet"));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final bool isRead = docs[index]['isRead'] ?? false;
              return ListTile(
                leading: const Icon(Icons.notifications_active, color: Colors.orange),
                title: Text(docs[index]['title'],style: TextStyle(
                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold, // Bold if new
                ),),
                subtitle: Text(docs[index]['body']),
                onTap: () async {
                  // 1. Mark as read in Firestore
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(currentUserId)
                      .collection('notifications')
                      .doc(docs[index].id)
                      .update({'isRead': true});

                   if (!context.mounted) return;

                  final String type = docs[index]['type'] ?? '';

                  if (type == 'ride_update' ) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => MyBookingsPage()));
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
