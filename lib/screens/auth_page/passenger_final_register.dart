import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sajilo_ride/auth/auth_provider.dart';
import 'package:sajilo_ride/screens/auth_page/login_page.dart';

import '../../navbar/navbar_config.dart';
import '../../widgets/app_shell.dart';

class PassengerFinalRegisterPage extends StatefulWidget {
  final String name;
  final String email;
  final String password;
  final String phone;
  final String role;

  const PassengerFinalRegisterPage({
    super.key,
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.role,
  });

  @override
  State<PassengerFinalRegisterPage> createState() =>
      _PassengerFinalRegisterPageState();
}

class _PassengerFinalRegisterPageState
    extends State<PassengerFinalRegisterPage> {
  bool _isLoading = false;
  String? error;

  Future<void> _registerPassenger() async {
    setState(() {
      _isLoading = true;
      error = null;
    });

    final authProvider =
    Provider.of<AuthProviderMethod>(context, listen: false);

    final message = await authProvider.signUpWithEmailAndPassword(
      widget.name,
      widget.email,
      widget.password,
      widget.phone,
      widget.role,
    );

    if (!mounted) return;

    if (message == 'Success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account created successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AppShell(userRole: UserRole.passenger)),
            (route) => false,
      );
    } else {
      setState(() {
        _isLoading = false;
        error = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Complete Registration"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person, size: 80, color: Colors.orange),

              const SizedBox(height: 20),

              const Text(
                "Final Step",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              const Text(
                "Create your passenger account",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),

              const SizedBox(height: 30),

              if (error != null)
                Text(
                  error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _registerPassenger,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "CREATE ACCOUNT",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
