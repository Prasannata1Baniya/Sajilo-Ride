import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sajilo_ride/auth/auth_provider.dart';
import 'package:sajilo_ride/screens/auth_page/forgot_password.dart';
import 'package:sajilo_ride/screens/auth_page/register_page.dart';
import 'package:sajilo_ride/utils/input_decoration.dart';
import 'package:sajilo_ride/utils/text_styles.dart';
import '../../navbar/navbar_config.dart';
import '../../widgets/app_shell.dart';
import '../no_internet_screens.dart';

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

      final message = await authProvider.loginWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;

      if (message == "NO_INTERNET") {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const NoInternetScreen(),
          ),
        );
        return;
      }

      if (message == 'Success') {
        String roleString = await authProvider.getUserRole(authProvider.user!.uid);
        debugPrint("Logged in as: $roleString");

        final role = (roleString.toLowerCase().trim() == 'driver')
            ? UserRole.driver
            : UserRole.passenger;

        if (!mounted) return;

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
          Positioned.fill(
            child: Image.asset(
              "assets/images/car_background.png",
              fit: BoxFit.cover,
            ),
          ),

          // Dark Overlay Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                      "Sajilo Yatra",
                      style: AppTextStyles.headingWhite
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Your premium journey starts here",
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                        letterSpacing: 0.3
                    ),
                  ),
                  const SizedBox(height: 35),

                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 36.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.93),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          width: 1,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 25,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              "assets/images/SajiloRide_logo.png",
                              height: 65,
                            ),
                            const SizedBox(height: 35),

                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              style: const TextStyle(color: Colors.black, fontSize: 15),
                              keyboardType: TextInputType.emailAddress,
                              decoration: inputDecorate.buildInputDecoration(
                                "Email",
                                suffixIcon: Icon(
                                  Icons.email_outlined,
                                  color: Colors.orange.withValues(alpha: 0.8),
                                  size: 20,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Please enter your password";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              style: const TextStyle(color: Colors.black, fontSize: 15),
                              obscureText: _isPasswordObscured,
                              decoration: inputDecorate.buildInputDecoration(
                                "Password",
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordObscured
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.orange.withValues(alpha: 0.8),
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
                                ),
                              ),
                              validator: (value) =>
                              (value == null || value.length < 6)
                                  ? 'Short password'
                                  : null,
                            ),

                            // Forgot Password
                            Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: TextButton(
                                  onPressed: () =>Navigator.push(context, MaterialPageRoute(builder: (_)=>ForgotPassword())),
                                  style: TextButton.styleFrom(
                                    minimumSize: Size.zero,
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    "Forgot Password?",
                                    style: TextStyle(
                                      color: Colors.orangeAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            if (error != null)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(top: 12, bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.2),
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: Colors.redAccent,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        error!,
                                        style: const TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 24),

                            // Login Button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  backgroundColor: const Color(0xFFFF9F43),
                                  shadowColor: const Color(0xFFFF9F43).withValues(alpha: 0.35),
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                ),
                                onPressed: isLoading ? null : _handleLogin,
                                child: isLoading
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                                    : const Text(
                                  "LOGIN",
                                  style: TextStyle(
                                    letterSpacing: 1.2,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Register Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                    "New here? ",
                                    style: TextStyle(color: Colors.black.withValues(alpha: 0.6), fontSize: 14)
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const RegisterPage()),
                                  ),
                                  child: const Text(
                                    "Create Account",
                                    style: TextStyle(
                                      color: Colors.orangeAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
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


