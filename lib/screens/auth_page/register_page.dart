import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:sajilo_ride/screens/auth_page/passenger_final_register.dart';
import 'package:sajilo_ride/utils/input_decoration.dart';
import 'package:sajilo_ride/utils/text_styles.dart';
import 'license_verify/driver_verification_page.dart';
import 'login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _numController = TextEditingController();

  final FocusNode _phoneFocusNode = FocusNode();
  String _phoneNumber = "";
  int currentStep = 1;

  final List<String> roles = ['passenger', 'driver'];
  String? selectedRole;
  String? error;
  bool _isLoading = false;

  final InputDecorate inputDecorate = InputDecorate();
  bool _isPasswordObscured = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _numController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  bool _isCurrentStepValid() {
    if (currentStep == 1) return _step1Key.currentState!.validate();
    if (currentStep == 2) return _step2Key.currentState!.validate();
    if (currentStep == 3) {
      if (!_step3Key.currentState!.validate()) return false;
      return selectedRole != null;
    }
    return false;
  }

  Future<void> _onNextPressed() async {
    // 1. Reset error and start loading
    setState(() {
      error = null;
      _isLoading = true;
    });

    try {
      // 2. Perform the Firestore check
      bool exists = await emailExists(_emailController.text.trim());

      if (!mounted) return;

      if (exists) {
        setState(() {
          error = "This email is already registered.";
          _isLoading = false;
        });
        return;
      }

      // 3. If we reach here, email is fine!
      // Stop loading BEFORE navigating
      setState(() => _isLoading = false);

      // 4. Navigate
      if (selectedRole == 'driver') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DriverVerificationPage(
                  name: _nameController.text.trim(),
                  email: _emailController.text.trim(),
                  password: _passwordController.text.trim(),
                  phone: _phoneNumber,
                ),
          ),
        );
      } else {
        final result = await  Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PassengerFinalRegisterPage(
                  name: _nameController.text.trim(),
                  email: _emailController.text.trim(),
                  password: _passwordController.text.trim(),
                  phone: _phoneNumber,
                  role: 'passenger',
                ),
          ),
        );
        if (result is String) {
          setState(() {
            error = result;     // Show the error message
            currentStep = 1;    // Send them back to the email field
            _isLoading = false;
          });
        }
      }
    }catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Error checking email: $e");
    }
  }

  Future<bool> emailExists(String email) async {
    final String normalizedEmail = email.toLowerCase().trim();

    debugPrint("DEBUG: Searching for email: $normalizedEmail");

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: normalizedEmail)
        .get();

    debugPrint("DEBUG: Found ${snapshot.docs.length} documents.");

    return snapshot.docs.isNotEmpty;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Password is required";
    }

    if (value.length < 8) {
      return "Password must be at least 8 characters";
    }

    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return "Password must contain an uppercase letter";
    }

    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return "Password must contain a lowercase letter";
    }

    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return "Password must contain a number";
    }

    if (!RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return "Password must contain a special character";
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          Positioned.fill(
            child: Image.asset(
              "assets/images/car_background.png",
              fit: BoxFit.cover,
            ),
          ),

          // Dark Gradient Overlay
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Create Account", style: AppTextStyles.headingWhite),
                  const SizedBox(height: 6),
                  Text(
                    "Join us for a premium riding experience",
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset("assets/images/SajiloRide_logo.png", height: 65),
                          const SizedBox(height: 12),

                          // Step Indicator
                          Text(
                            "Step $currentStep of 3",
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 25),

                          //REGISTER FORM
                          IndexedStack(
                            index: currentStep - 1,
                            children: [
                              // STEP 1: IDENTITY
                              Form(
                                key: _step1Key,
                                //autovalidateMode: AutovalidateMode.onUserInteraction,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextFormField(
                                      controller: _nameController,
                                      style: const TextStyle(color: Colors.black, fontSize: 15),
                                      decoration: inputDecorate.buildInputDecoration("Full Name").copyWith(
                                        suffixIcon: Icon(Icons.person_outline_rounded, color: Colors.orange.withValues(alpha: 0.8), size: 20),
                                      ),
                                      validator: (value) => value == null || value.trim().isEmpty ? "Required" : null,
                                    ),
                                    const SizedBox(height: 18),
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      style: const TextStyle(color: Colors.black, fontSize: 15),
                                      decoration: inputDecorate.buildInputDecoration("Email").copyWith(
                                        suffixIcon: Icon(Icons.email_outlined, color: Colors.orange.withValues(alpha: 0.8), size: 20),
                                      ),
                                        onEditingComplete: () async {
                                          FocusScope.of(context).unfocus();

                                          bool exists = await emailExists(_emailController.text.trim());

                                          if (exists) {
                                            setState(() {
                                              error = "This email is already registered.";
                                            });
                                          } else {
                                            setState(() {
                                              error = null;
                                            });
                                          }
                                        },
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return "Email is required";
                                        }
                                        // This regex pattern: text + @ + text + . + 2-4 letter domain
                                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[a-zA-Z]{2,4}$');
                                        if (!emailRegex.hasMatch(value.trim())) {
                                          return "Enter a valid email address";
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),

                              // --- STEP 2: SECURITY & PHONE ---
                              Form(
                                key: _step2Key,
                                //autovalidateMode: AutovalidateMode.onUserInteraction,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IntlPhoneField(
                                      controller: _numController,
                                      focusNode: _phoneFocusNode,
                                      style: const TextStyle(color: Colors.black, fontSize: 15),
                                      decoration: inputDecorate.buildInputDecoration("Phone Number"),
                                      initialCountryCode: 'NP',
                                      onChanged: (phone) => _phoneNumber = phone.completeNumber,
                                      validator: (value) => (value == null || value.number.length < 10) ? 'Enter 10 digit number' : null,
                                    ),
                                    const SizedBox(height: 18),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _isPasswordObscured,
                                      style: const TextStyle(color: Colors.black, fontSize: 15),
                                      decoration: inputDecorate.buildInputDecoration("Password").copyWith(
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _isPasswordObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                            color: Colors.orange.withValues(alpha: 0.8),
                                            size: 20,
                                          ),
                                          onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
                                        ),
                                      ),
                                      validator:validatePassword,
                                    ),
                                  ],
                                ),
                              ),

                              // --- STEP 3: ROLE SELECTION ---
                              Form(
                                key: _step3Key,
                                //autovalidateMode: AutovalidateMode.onUserInteraction,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "Choose your registration path",
                                      style: TextStyle(color: Colors.black.withValues(alpha: 0.7), fontWeight: FontWeight.w600, fontSize: 15),
                                    ),
                                    const SizedBox(height: 20),
                                    DropdownButtonFormField<String>(
                                      initialValue: selectedRole,
                                      decoration: inputDecorate.buildInputDecoration("Select Role"),
                                      dropdownColor: Colors.white,
                                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
                                      items: roles.map((role) => DropdownMenuItem(value: role, child: Text(role.toUpperCase()))).toList(),
                                      onChanged: (value) => setState(() {
                                        selectedRole = value;
                                        error = null;
                                      }),
                                      validator: (value) => value == null ? "Please select a role" : null,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          if (error != null)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(top: 16),
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
                                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 18),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      error!,
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 30),

                          // --- NAVIGATION BUTTONS ---
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF9F43),
                                shadowColor: const Color(0xFFFF9F43).withValues(alpha: 0.35),
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),

                              onPressed: _isLoading ? null : () async {
                                // 1. First, validate the form for the current step
                                if (!_isCurrentStepValid()) return;
                                // 2. If at Step 1, run the email check immediately
                                if (currentStep == 1) {
                                  setState(() => _isLoading = true);
                                  bool exists = await emailExists(_emailController.text.trim());
                                  if (exists) {
                                    setState(() {
                                      error = "This email is already registered.";
                                      _isLoading = false;
                                    });
                                    return; // Stop here! Do not go to Step 2.
                                  }

                                  // Email is fine, move to step 2
                                  setState(() {
                                    error = null;
                                    _isLoading = false;
                                    currentStep++;
                                  });
                                }
                                // 3. For other steps, just handle the increment or final navigation
                                else if (currentStep < 3) {
                                  setState(() => currentStep++);
                                } else {
                                  _onNextPressed(); // This is for the final Step 3 action
                                }
                              },

                              child: _isLoading
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text(
                                currentStep < 3 ? "NEXT" : (selectedRole == 'driver' ? "CONTINUE" : "REGISTER"),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 15),
                              ),
                            ),
                          ),

                          if (currentStep > 1 && !_isLoading)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: TextButton(
                                onPressed: () {
                                  if (currentStep == 1) _step1Key.currentState?.reset();
                                  if (currentStep == 2) _step2Key.currentState?.reset();
                                  if (currentStep == 3) _step3Key.currentState?.reset();
                                  setState(() => currentStep--);
                                },
                                child: Text(
                                  "Back",
                                  style: TextStyle(color: Colors.black.withValues(alpha: 0.5), fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ),
                            ),

                          if (currentStep == 1) ...[
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Already have an account? ",
                                  style: TextStyle(color: Colors.black.withValues(alpha: 0.6), fontSize: 14),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                                  child: const Text(
                                    "Login Now",
                                    style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
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
