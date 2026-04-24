import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sajilo_ride/auth/auth_provider.dart';
import 'package:sajilo_ride/screens/auth_page/register_page.dart';
import 'package:sajilo_ride/utils/input_decoration.dart';
import 'package:sajilo_ride/utils/text_styles.dart';
import '../../navbar/navbar_config.dart';
import '../../widgets/app_shell.dart';


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
  bool _isPasswordObscured = true;
  final InputDecorate inputDecorate = InputDecorate();

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final authProvider = context.read<AuthProviderMethod>();

      // 1. Log in
      final message = await authProvider.loginWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (message == 'Success') {
        // 2. Fetch the role string from Firestore
        String roleString = await authProvider.getUserRole(
            authProvider.user!.uid);

        debugPrint("Logged in as: $roleString");

        // 4. Trim and lowercase the comparison
        final role = (roleString.toLowerCase().trim() == 'driver')
            ? UserRole.driver
            : UserRole.passenger;

        if (!mounted) return;

        // 5. Navigate to the Shell with the CORRECT role
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => AppShell(userRole: role)),
        );
      } else {
        setState(() {
          error = message;
        });
      }
    } catch (e) {
      setState(() {
        error = "Login Error: $e";
      });
    } finally {
      if (mounted) {
        setState(() {
        isLoading = false;
      });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. BACKGROUND IMAGE
         /* Positioned.fill(
            child: Image.asset(
              "assets/images/car_background.png",
              fit: BoxFit.cover,
            ),
          ),

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
          ),*/
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1A1A1A), // Deep Charcoal
                    Color(0xFF000000), // Pure Black
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: 24.0, vertical: 20),
              child: Column(
                children: [
                  // Header Branding
                  const Text("Sajilo Ride", style: AppTextStyles.headingWhite),
                  const SizedBox(height: 8),
                  const Text("Your premium journey starts here",
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 30),

                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 450),
                    child: Container(
                      padding: const EdgeInsets.all(32.0),
                      decoration: BoxDecoration(
                        //color: Colors.white.withValues(alpha: 0.8),
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          width: 1,
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orangeAccent.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset("assets/images/SajiloRide_logo.png",
                                height: 80),
                            const SizedBox(height: 40),

                            // Email
                            TextFormField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.black),
                              keyboardType: TextInputType.emailAddress,
                              decoration: inputDecorate
                                  .buildInputDecoration(
                                "Email",
                                suffixIcon: const Icon(Icons.email_outlined,
                                    color: Colors.orange, size: 20),
                              ),
                              validator: (value) =>
                              (value == null || !value.contains('@'))
                                  ? 'Invalid email'
                                  : null,
                            ),
                            const SizedBox(height: 20),

                            // Password
                            TextFormField(
                              controller: _passwordController,
                              style: const TextStyle(color: Colors.black),
                              obscureText: _isPasswordObscured,
                              decoration: inputDecorate
                                  .buildInputDecoration(
                                "Password",
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordObscured ? Icons
                                        .visibility_off_outlined : Icons
                                        .visibility_outlined,
                                    color: Colors.orange, size: 20,
                                  ),
                                  onPressed: () =>
                                      setState(() =>
                                      _isPasswordObscured =
                                  !_isPasswordObscured),
                                ),
                              ),
                              validator: (value) =>
                              (value == null || value.length < 6)
                                  ? 'Short password'
                                  : null,
                            ),

                            if (error != null)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(top: 20),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.35),
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        error!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 35),

                            // Login Button
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          15)),
                                  //backgroundColor: Colors.orangeAccent,
                                  // shadowColor: Colors.orangeAccent.withValues(alpha: 0.4),
                                  backgroundColor: const Color(0xFFFF9F43),
                                  shadowColor: const Color(0xFFFF9F43).withValues(alpha: 0.3),
                                  foregroundColor: Colors.white,
                                  elevation: 8,
                                ),
                                onPressed: isLoading ? null : _handleLogin,
                                child: isLoading
                                    ? const SizedBox(height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2))
                                    : const Text("LOGIN", style: TextStyle(
                                    letterSpacing: 1.5,
                                    fontWeight: FontWeight.bold)),
                              ),
                            ),

                            const SizedBox(height: 25),

                            // Register Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text("New here? ", style: TextStyle(
                                    color: Colors.black)),
                                GestureDetector(
                                  onTap: () =>
                                      Navigator.push(context,
                                      MaterialPageRoute(builder: (
                                          _) => const RegisterPage())),
                                  child: const Text("Create Account",
                                      style: TextStyle(
                                          color: Colors.orangeAccent,
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration
                                              .underline)),
                                ),
                              ],
                            ),
                          ],
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
