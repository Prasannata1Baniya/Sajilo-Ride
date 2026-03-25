import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sajilo_ride/auth/auth_provider.dart';
import 'package:sajilo_ride/screens/auth_page/register_page.dart';
import 'package:sajilo_ride/utils/input_decoration.dart';
import 'package:sajilo_ride/utils/text_styles.dart';
import 'package:sajilo_ride/navbar/navbar_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? error;
  bool isLoading = false;

  final InputDecorate inputDecorate = InputDecorate();

  // --- UPDATED LOGIC ---
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      isLoading = true;
      error = null;
    });

    final authProvider = context.read<AuthProviderMethod>();

    // 1. Authenticate
    final message = await authProvider.loginWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;

    if (message == 'Success') {
      // 2. Fetch the role from Firestore
      String roleString = await authProvider.getUserRole(authProvider.user!.uid);

      // 3. Convert to Enum
      UserRole roleEnum = (roleString == 'Driver') ? UserRole.driver : UserRole.passenger;

      if (!mounted) return;

      // 4. Navigate to NavigationShell with the correct role
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => NavigationShell(userRole: roleEnum),
        ),
      );
    } else {
      setState(() {
        isLoading = false;
        error = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(image: AssetImage("assets/images/car_background.png"), fit: BoxFit.cover),
            ),
          ),
          Center(
            child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Login", style: AppTextStyles.headingWhite),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    width: 1.5,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset("assets/images/SajiloRide_logo.png", height: 100),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(color: Colors.black),
                        keyboardType: TextInputType.emailAddress,
                        decoration: inputDecorate.buildInputDecoration("Email"),
                        validator: (value) => (value == null || !value.contains('@')) ? 'Enter a valid email' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        style: const TextStyle(color: Colors.black),
                        obscureText: true,
                        decoration: inputDecorate.buildInputDecoration("Password"),
                        validator: (value) => (value == null || value.length < 6) ? 'Password must be at least 6 characters' : null,
                      ),

                      // FIX 3: Error Text visibility
                      if (error != null)
                        Container(
                          margin: const EdgeInsets.only(top: 15),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ),

                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity, // Full width button looks better on mobile
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0, // Flat looks better with Glassmorphism
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: Colors.orangeAccent,
                          ),
                          onPressed: isLoading ? null : _handleLogin,
                          child: isLoading
                              ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          )
                              : const Text("Login", style: AppTextStyles.bodyTextWhite),
                        ),
                      ),
                      const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text(
                                "Don't have an account? ",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w400)
                            ),
                            TextButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));
                                },
                                child: Text("Register ",
                                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w400),
                                ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
          ),
        ],
      ),
    );
  }
}