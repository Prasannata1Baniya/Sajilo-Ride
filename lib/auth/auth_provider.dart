import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../navbar/navbar_config.dart';

class AuthProviderMethod extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user;

  AuthProviderMethod() {
    _auth.authStateChanges().listen((User? user) {
      this.user = user;
      notifyListeners();
    });
  }

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final String _cloudinaryCloudName = dotenv.get("CLOUDINARY_CLOUD_NAME");
  final String _cloudinaryUploadPreset = dotenv.get("CLOUDINARY_PRESET_NAME");

  /// Uploads a local file directly to Cloudinary using an unsigned preset
  Future<String?> _uploadToCloudinary(XFile file) async {
    try {
      final url = Uri.parse(
          'https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/upload');

      // Initialize a standard Multi-Part Request matching Cloudinary's schema rules
      var request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = _cloudinaryUploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        String secureUrl = responseData['secure_url'];
        debugPrint("DEBUG: Uploaded successfully to Cloudinary: $secureUrl");
        return secureUrl;
      } else {
        debugPrint("DEBUG: Cloudinary Error Status -> ${response.statusCode}");
        debugPrint("DEBUG: Cloudinary Error Body -> ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("DEBUG: Exception during Cloudinary file transfer: $e");
      return null;
    }
  }

  /// Registers user to Firebase and handles Cloudinary + Firestore links
  Future<String> signUpWithEmailAndPassword(String name,
      String email,
      String password,
      String phone,
      String role, {
        XFile? licenseFile,
        List<double>? faceEmbeddings,
      }) async {
    try {
      // 1. Upload the license file to Cloudinary first (if provided)
      String licenseUrl = "";
      if (licenseFile != null) {
        String? uploadedUrl = await _uploadToCloudinary(licenseFile);
        if (uploadedUrl == null) {
          return "Failed to upload document to media server. Registration aborted.";
        }
        licenseUrl = uploadedUrl;
      }

      // 2. Create the user authentication profile inside Firebase Auth
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      // 3. Save everything to Cloud Firestore
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'licenseUrl': licenseUrl,
        // Saved Cloudinary link
        'faceEmbeddings': faceEmbeddings,
        // Array of local TFLite numbers saved cleanly
        'createdAt': FieldValue.serverTimestamp(),
        'isVerified': false,
        // Pending review status
      });

      return 'Success';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return "This email is already registered. Please login instead.";
      }
      return e.message ?? "An authentication error occurred.";
    } catch (e) {
      return e.toString();
    }
  }

  Future<UserRole> getCurrentUserRole() async {
    if (user == null) return UserRole.passenger;
    String roleString = await getUserRole(user!.uid);
    return roleString == 'driver' ? UserRole.driver : UserRole.passenger;
  }

  // --- FETCH ROLE ---
  Future<String> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        return doc.get('role') as String;
      }
      return 'passenger';
    } catch (e) {
      return 'passenger';
    }
  }

  // --- LOGIN (Now with Automatic Token Save) ---
  Future<String?> loginWithEmailAndPassword(String email,
      String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password
      );

      User? loggedInUser = credential.user;

      if (loggedInUser != null) {
        // Check the role from Firestore
        String role = await getUserRole(loggedInUser.uid);

        // If they are a driver, register their notification device token immediately
        if (role == 'driver') {
          await saveDeviceToken(loggedInUser.uid);
        }
      }

      return 'Success';
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An unknown error occurred.';
    } catch (e) {
      return e.toString();
    }
  }

  /*Future<void> signOut() async {
    // clear token field on sign-out to prevent stale tracking
    if (user != null) {
      try {
        String role = await getUserRole(user!.uid);
        if (role == 'driver') {
          await _firestore.collection('drivers').doc(user!.uid).update({
            'deviceToken': FieldValue.delete(),
          });
        }
      } catch (_) {}
    }
    await _auth.signOut();
  }*/

  Future<void> signOut() async {
    if (user != null) {
      try {
        // Delete token from 'users' collection to match save logic
        await _firestore.collection('users').doc(user!.uid).update({
          'deviceToken': FieldValue.delete(),
        });
      } catch (e) {
        debugPrint("Error clearing token on sign-out: $e");
      }
    }
    await _auth.signOut();
  }

  // --- DEVICE TOKEN MANAGEMENT ---
  Future<void> saveDeviceToken(String driverId) async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;

      // 1. Request notification permissions (vital for iOS and Android 13+)
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // 2. Get the unique FCM token
        String? token = await messaging.getToken();

        if (token != null) {
          // 🛠️ FIXED: Changed collection from 'drivers' to 'users' to keep document data synced
          await _firestore.collection('users').doc(driverId).set({
            'deviceToken': token,
          }, SetOptions(merge: true));

          debugPrint("FCM Token successfully saved for driver: $token");
        }
      } else {
        debugPrint(
            "User declined or has not accepted notification permissions.");
      }
    } catch (e) {
      debugPrint("Error saving device token: $e");
    }
  }
}