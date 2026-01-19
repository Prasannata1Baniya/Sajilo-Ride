import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class AuthProviderMethod extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =FirebaseFirestore.instance;
  User? user;

  AuthProviderMethod() {
    _auth.authStateChanges().listen((User? user) {
      this.user = user;
      notifyListeners();
    });
  }

  Future<String?> loginWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return 'Success';
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An unknown error occurred.';
    }
  }

  Future<String?> signUpWithEmailAndPassword(String name, String email, String password, String role) async {
    // 1. Create the user in Firebase Auth
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Update display name
      await credential.user!.updateDisplayName(name);

      // 3. Save to Firestore
      try {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'name': name,
          'email': email,
          'role': role,
          'uid': credential.user!.uid,
        });
      } catch (firestoreError) {
        debugPrint('Firestore error: $firestoreError');
        await credential.user!.delete();  // Clean up the auth user
        return 'Failed to save user data. Please try again.';
      }
     /// await credential.user!.sendEmailVerification();
      return 'Success';
    }on FirebaseAuthException catch (e) {
      return e.message ?? 'An unknown error occurred. Please try again.';
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}











/*class AuthProviderMethod extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user;

  AuthProviderMethod() {
    _auth.authStateChanges().listen((User? user) {
      this.user = user;
      notifyListeners();
    });
  }

  Future<String?> loginWithEmailAndPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return 'Success';
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'An unknown error occurred.';
    } catch (e) {
      // Catch any other exceptions (e.g., network issues)
      debugPrint('Login error: $e');  // For debugging
      return 'An unexpected error occurred. Please try again.';
    }
  }

  Future<String?> signUpWithEmailAndPassword(String name, String email, String password, String role) async {
    try {
      // 1. Create the user in Firebase Auth
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Update display name
      await credential.user!.updateDisplayName(name);

      // 3. Save to Firestore (handle potential failures)
      try {
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'name': name,
          'email': email,
          'role': role,
          'uid': credential.user!.uid,
        });
      } catch (firestoreError) {
        debugPrint('Firestore error: $firestoreError');
        await credential.user!.delete();  // Clean up the auth user
        return 'Failed to save user data. Please try again.';
      }

      // 4. Send email verification (don't let it fail the whole process)
      try {
        await credential.user!.sendEmailVerification();
      } catch (verificationError) {
        debugPrint('Email verification error: $verificationError');
      }
      return 'Success';
    } on FirebaseAuthException catch (e) {
      // Handle auth-specific errors
      return e.message ?? 'An unknown error occurred. Please try again.';
    } catch (e) {
      // Catch any other exceptions (e.g., network, unexpected errors)
     debugPrint('Signup error: $e');  // For debugging
      return 'An unexpected error occurred. Please try again.';
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }
}

 */