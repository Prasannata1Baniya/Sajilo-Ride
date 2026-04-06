import 'dart:ui';
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

  /*Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      isLoading = true;
      error = null;
    });
    final authProvider = context.read<AuthProviderMethod>();
    final message = await authProvider.loginWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;
    if (message == 'Success') {
      String roleString = await authProvider.getUserRole(authProvider.user!.uid);

      UserRole roleEnum = (roleString == 'Driver') ? UserRole.driver : UserRole.passenger;

      if (!mounted) return;

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
  }*/
  /*Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() { isLoading = true; error = null; });

    try {
      final authProvider = context.read<AuthProviderMethod>();
      final message = await authProvider.loginWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (!mounted) return;

      if (message == 'Success') {
        String roleString = await authProvider.getUserRole(authProvider.user!.uid);
        if (!mounted) return;
        final role = roleString == 'driver' ? UserRole.driver : UserRole.passenger;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => NavigationShell(userRole: role)),
        );
      } else {
        setState(() { error = message; });
      }
    } finally {
      if (mounted) setState(() { isLoading = false; });
    }
  }*/

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() { isLoading = true; error = null; });

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
        String roleString = await authProvider.getUserRole(authProvider.user!.uid);

        debugPrint("Logged in as: $roleString");

        // 4. CRITICAL FIX: Trim and lowercase the comparison
        final role = (roleString.toLowerCase().trim() == 'driver')
            ? UserRole.driver
            : UserRole.passenger;

        if (!mounted) return;

        // 5. Navigate to the Shell with the CORRECT role
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => AppShell(userRole: role)),
        );
      } else {
        setState(() { error = message; });
      }
    } catch (e) {
      setState(() { error = "Login Error: $e"; });
    } finally {
      if (mounted) setState(() { isLoading = false; });
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

          ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 450,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                child: Container(
                  padding: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      width: 1.5,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset("assets/images/SajiloRide_logo.png", height: 100),
                        const SizedBox(height: 30),

                        // Email Field
                        TextFormField(
                          controller: _emailController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.emailAddress,
                          decoration: inputDecorate.buildInputDecoration("Email").copyWith(
                            labelStyle: const TextStyle(color: Colors.white70),
                            suffixIcon: Icon(Icons.email, color: Colors.white70,),
                          ),
                          validator: (value) => (value == null || !value.contains('@'))
                              ? 'Enter a valid email' : null,
                        ),
                        const SizedBox(height: 20),

                        TextFormField(
                          controller: _passwordController,
                          style: const TextStyle(color: Colors.white),
                          obscureText: _isPasswordObscured,
                          decoration: inputDecorate.buildInputDecoration("Password").copyWith(
                          labelStyle: const TextStyle(color: Colors.white70),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordObscured ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordObscured = !_isPasswordObscured;
                              });
                            },
                          ),
                        ),
                          validator: (value) => (value == null || value.length < 6) ?
                          'Password must be at least 6 characters' : null,
                        ),

                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Text(
                              error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),

                        const SizedBox(height: 32),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              backgroundColor: Colors.orangeAccent,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: isLoading ? null : _handleLogin,
                            child: isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Text("LOGIN", style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Register
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account? ", style: TextStyle(color: Colors.white70)),
                            GestureDetector(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())),
                              child: const Text("Register", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
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