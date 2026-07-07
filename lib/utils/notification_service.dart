import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> createChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'sajilo_ride_notifications',
      'Ride Requests',
      description: 'Notifications for incoming ride requests',
      importance: Importance.max,
    );

    _notificationsPlugin.resolvePlatformSpecificImplementation;
    AndroidFlutterLocalNotificationsPlugin().createNotificationChannel(channel);
  }

  // --- SAVE TOKEN TO FIRESTORE ---
  static Future<void> _saveTokenToFirestore(String token) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        debugPrint("Cannot save token: user not logged in yet.");
        return;
      }
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint("FCM token saved to Firestore successfully.");
    } catch (e) {
      debugPrint("Error saving device token: $e");
    }
  }

  static Future<void> initialize() async {
    // 1. Request Permission
    NotificationSettings settings =
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint("User denied notification permission.");
      return;
    }

    debugPrint('Notification permission: ${settings.authorizationStatus}');

    // 2. Get and save FCM token
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        debugPrint("FCM TOKEN: $token");
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint("GET TOKEN ERROR: $e");
    }

    // 3. Listen for token refresh and re-save
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      debugPrint("FCM token refreshed.");
      await _saveTokenToFirestore(newToken);
    });

    // 4. Initialize Local Notifications
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
    InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);

    await createChannel();

    // 5. Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(
          message.notification!.title ?? "New Ride",
          message.notification!.body ?? "You have a new request",
        );
      }
    });
  }

  // Call this after login since user may not be logged in during initialize()
  static Future<void> saveTokenAfterLogin() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint("Error saving token after login: $e");
    }
  }

  static Future<void> _showLocalNotification(
      String title, String body) async {
    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'sajilo_ride_notifications',
      'Ride Requests',
      channelDescription: 'Notifications for incoming ride requests',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      fullScreenIntent: true,
    );

    await _notificationsPlugin.show(
      Random().nextInt(100),
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }
}
