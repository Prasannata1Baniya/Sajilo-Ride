import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> saveTokenToFirestore(String token) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        debugPrint("Cannot save token: user not logged in yet.");
        return;
      }
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmToken': token,
        'tokenUpdatedAt': FieldValue.serverTimestamp(),
      },SetOptions(merge: true));
      debugPrint("FCM token saved to Firestore successfully.");
    } catch (e) {
      debugPrint("Error saving device token: $e");
    }
  }

  static Future<void> initialize() async {
    NotificationSettings settings =
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    debugPrint("STEP 1: Requesting permission");

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(
          message.notification!.title ?? "New Ride",
          message.notification!.body ?? "Check your app for details",
        );
      }
    });

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint("User denied notification permission.");
      return;
    }

    debugPrint('Notification permission: ${settings.authorizationStatus}');
    debugPrint("STEP 2: Calling getToken()");

    try {

      String? token = await FirebaseMessaging.instance.getToken();
      debugPrint("STEP 3: Token received");
      debugPrint("TOKEN = $token");

      if (token != null) {
        debugPrint("FCM TOKEN: $token");
        await saveTokenToFirestore(token);
      }
      debugPrint("STEP 4: Token saved to Firestore");
    } catch (e,stackTrace) {
      debugPrint("GET TOKEN ERROR: $e");
      debugPrint("ERROR OCCURRED");
      debugPrint(e.toString());
      debugPrint(stackTrace.toString());
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      debugPrint("FCM token refreshed.");
      await saveTokenToFirestore(newToken);
    });

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
    InitializationSettings(android: androidSettings);
    await _notificationsPlugin.initialize(initSettings);

    await createChannel();


  }

   static Future<void> saveTokenAfterLogin() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await saveTokenToFirestore(token);
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
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}
