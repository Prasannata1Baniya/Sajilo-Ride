import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sajilo_ride/utils/input_decoration.dart';


//"Email not found" is not displayed because Firebase's Email Enumeration Protection hides whether an email exists.
// This is a built-in security feature that prevents attackers from identifying registered accounts,
// so the app shows the same message regardless of whether the email is registered.


class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  InputDecorate inputDecorate = InputDecorate();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Reset Password', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_reset_rounded, size: 80, color: Colors.orange),
              const SizedBox(height: 20),
              const Text(
                'Receive an email to reset your password',
                style: TextStyle(fontSize: 18, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: emailController,
                cursorColor: Colors.orange,
                decoration: inputDecorate.buildInputDecoration(
                    'Email Address',
                    suffixIcon: const Icon(Icons.email, color: Colors.orange)
                ),
                validator: (email) => (email != null && !email.contains('@'))
                    ? 'Enter a valid Email'
                    : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    resetPassword();
                  }
                },
                label: const Text('RESET PASSWORD', style: TextStyle(fontWeight: FontWeight.bold)),
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> resetPassword() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.orange)),
    );

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );

      debugPrint("Request successfully sent to Firebase servers.");

      if (!mounted) return;
      emailController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password Reset Email Sent! Check your email'),
          backgroundColor: Colors.green,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase Error: ${e.message}");

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'An error occurred'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    }
  }
}