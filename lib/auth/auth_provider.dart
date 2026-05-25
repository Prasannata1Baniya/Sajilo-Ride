import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

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

  // --- FETCH ROLE ---
  Future<String> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.get('role') as String;
      }
      return 'passenger';
    } catch (e) {
      return 'passenger';
    }
  }

  // --- LOGIN (Now with Automatic Token Save) ---
  Future<String?> loginWithEmailAndPassword(String email, String password) async {
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

  // --- REGISTER ---
  Future<String> signUpWithEmailAndPassword(
      String name, String email, String password, String phone, String role) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? firebaseUser = result.user;

      await firebaseUser!.updateDisplayName(name);

      String dummyLicenseUrl = "";

      if (role.toLowerCase() == 'driver') {
        dummyLicenseUrl = "https://cdn-icons-png.flaticon.com/512/3524/3524752.png";
      }

      await _firestore.collection('users').doc(firebaseUser.uid).set({
        'uid': firebaseUser.uid,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.toLowerCase(),
        'licenseImageUrl': dummyLicenseUrl,
        'isVerified': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // If they are registering directly as a driver, capture the token right away
      if (role.toLowerCase() == 'driver') {
        await saveDeviceToken(firebaseUser.uid);
      }

      return 'Success';
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
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
          // 3. Save it to the driver's document using merge to prevent overwriting location configurations
          await _firestore.collection('drivers').doc(driverId).set({
            'deviceToken': token,
          }, SetOptions(merge: true));

          debugPrint("FCM Token successfully saved for driver: $token");
        }
      } else {
        debugPrint("User declined or has not accepted notification permissions.");
      }
    } catch (e) {
      debugPrint("Error saving device token: $e");
    }
  }
}





/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

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

  // --- FETCH ROLE ---
  Future<String> getUserRole(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.get('role') as String;
      }
      return 'passenger';
    } catch (e) {
      return 'passenger';
    }
  }

  // --- LOGIN ---
  Future<String?> loginWithEmailAndPassword(String email, String password) async {
    try {

      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return 'Success';
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An unknown error occurred.';
    }
  }

  // --- REGISTER ---
  Future<String> signUpWithEmailAndPassword(
      String name, String email, String password,String phone,String role) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? firebaseUser = result.user;

      await firebaseUser!.updateDisplayName(name);

      String dummyLicenseUrl = "";

      if (role.toLowerCase() == 'driver') {
        dummyLicenseUrl = "https://cdn-icons-png.flaticon.com/512/3524/3524752.png";
      }

      await _firestore.collection('users').doc(firebaseUser.uid).set({
        'uid': firebaseUser.uid,
        'name': name,
        'email': email,
        'phone':phone,
        'role': role.toLowerCase(),
        'licenseImageUrl': dummyLicenseUrl,
        'isVerified': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return 'Success';
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

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
          // 3. Save it to the driver's document using merge to prevent overwriting other fields
          await FirebaseFirestore.instance
              .collection('drivers')
              .doc(driverId)
              .set({
            'deviceToken': token,
          }, SetOptions(merge: true));

          debugPrint("FCM Token successfully saved for driver: $token");
        }
      } else {
        debugPrint("User declined or has not accepted notification permissions.");
      }
    } catch (e) {
      debugPrint("Error saving device token: $e");
    }
  }
}
*/