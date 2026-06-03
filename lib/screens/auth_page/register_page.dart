import 'dart:ui';
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
  // 🚀 Split into 3 independent keys so they don't validate background steps
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
  final bool _isLoading = false;

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
    if (currentStep == 1) {
      if (!_step1Key.currentState!.validate()) return false;
      final nameValid = _nameController.text.trim().isNotEmpty;
      final emailValid = _emailController.text.trim().contains('@');
      return nameValid && emailValid;
    }

    if (currentStep == 2) {
      if (!_step2Key.currentState!.validate()) return false;
      final phoneValid = _numController.text.length >= 10;
      final passwordValid = _passwordController.text.length >= 6;
      return phoneValid && passwordValid;
    }

    if (currentStep == 3) {
      if (!_step3Key.currentState!.validate()) return false;
      return selectedRole != null;
    }

    return false;
  }

  void _onNextPressed() {
    if (selectedRole == 'driver') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DriverVerificationPage(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            phone: _phoneNumber,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PassengerFinalRegisterPage(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            phone: _phoneNumber,
            role: 'passenger',
          ),
        ),
      );
    }
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
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                children: [
                  const Text("Create Account", style: AppTextStyles.headingWhite),
                  const SizedBox(height: 20),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 450,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.85,
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(width: 1.5, color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset("assets/images/SajiloRide_logo.png", height: 70),
                              const SizedBox(height: 10),

                              // Step Indicator
                              Text("Step $currentStep of 3",
                                  style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 15),

                              // --- REGISTER FORM VIEWS STACK ---
                              IndexedStack(
                                index: currentStep - 1,
                                children: [
                                  // --- STEP 1: IDENTITY ---
                                  Form(
                                    key: _step1Key,
                                    autovalidateMode: AutovalidateMode.onUserInteraction,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextFormField(
                                          controller: _nameController,
                                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                          decoration: inputDecorate.buildInputDecoration("Full Name").copyWith(
                                            suffixIcon: const Icon(Icons.person, color: Colors.orange),
                                          ),
                                          validator: (value) => value == null || value.trim().isEmpty ? "Required" : null,
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: _emailController,
                                          keyboardType: TextInputType.emailAddress,
                                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                          decoration: inputDecorate.buildInputDecoration("Email").copyWith(
                                            suffixIcon: const Icon(Icons.email, color: Colors.orange),
                                          ),
                                          validator: (value) => (value == null || !value.contains('@')) ? "Invalid email" : null,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // --- STEP 2: SECURITY & PHONE ---
                                  Form(
                                    key: _step2Key,
                                    autovalidateMode: AutovalidateMode.onUserInteraction,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IntlPhoneField(
                                          controller: _numController,
                                          focusNode: _phoneFocusNode,
                                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                          decoration: inputDecorate.buildInputDecoration("Phone Number"),
                                          initialCountryCode: 'NP',
                                          onChanged: (phone) => _phoneNumber = phone.completeNumber,
                                          validator: (value) => (value == null || value.number.length < 10) ? 'Enter 10 digit number' : null,
                                        ),
                                        const SizedBox(height: 16),
                                        TextFormField(
                                          controller: _passwordController,
                                          obscureText: _isPasswordObscured,
                                          style: const TextStyle(color: Colors.black),
                                          decoration: inputDecorate.buildInputDecoration("Password").copyWith(
                                            suffixIcon: IconButton(
                                              icon: Icon(_isPasswordObscured ? Icons.visibility_off : Icons.visibility, color: Colors.orange),
                                              onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
                                            ),
                                          ),
                                          validator: (value) => (value == null || value.length < 6) ? 'Short password (min 6 chars)' : null,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // --- STEP 3: ROLE SELECTION ---
                                  Form(
                                    key: _step3Key,
                                    autovalidateMode: AutovalidateMode.onUserInteraction,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text("Choose your role", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 15),
                                        DropdownButtonFormField<String>(
                                          initialValue: selectedRole,
                                          decoration: inputDecorate.buildInputDecoration("Select Role"),
                                          dropdownColor: Colors.white,
                                          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
                                Padding(
                                  padding: const EdgeInsets.only(top: 15),
                                  child: Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                                ),

                              const SizedBox(height: 25),

                              // --- NAVIGATION BUTTONS ---
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orangeAccent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: _isLoading ? null : () {
                                    if (_isCurrentStepValid()) {
                                      if (currentStep < 3) {
                                        setState(() => currentStep++);
                                      } else {
                                        _onNextPressed();
                                      }
                                    }
                                  },
                                  child: _isLoading
                                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : Text(
                                    currentStep < 3 ? "NEXT" : (selectedRole == 'driver' ? "CONTINUE" : "REGISTER"),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),

                              if (currentStep > 1 && !_isLoading)
                                TextButton(
                                  onPressed: () {
                                    if (currentStep == 1) _step1Key.currentState?.reset();
                                    if (currentStep == 2) _step2Key.currentState?.reset();
                                    if (currentStep == 3) _step3Key.currentState?.reset();
                                    setState(() => currentStep--);
                                  },
                                  child: const Text("Back", style: TextStyle(color: Colors.black54)),
                                ),

                              const SizedBox(height: 10),
                              if (currentStep == 1)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Already have an account?", style: TextStyle(color: Colors.black)),
                                    TextButton(
                                      onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                                      child: const Text("Login Now", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
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








/*import 'dart:ui';
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
  final _formKey = GlobalKey<FormState>();
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
  final bool _isLoading = false;

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

  // --- VALIDATE ONLY ACTIVE STEP INPUTS ---
  bool _isCurrentStepValid() {
    if (currentStep == 1) {
      // Validate Name and Email explicitly
      final nameValid = _nameController.text.trim().isNotEmpty;
      final emailValid = _emailController.text.trim().contains('@');

      if (!nameValid || !emailValid) {
        _formKey.currentState!.validate();
        return false;
      }
      return true;
    }

    if (currentStep == 2) {
      // Validate Phone Number and Password explicitly
      final phoneValid = _numController.text.length >= 10;
      final passwordValid = _passwordController.text.length >= 6;

      if (!phoneValid || !passwordValid) {
        _formKey.currentState!.validate();
        return false;
      }
      return true;
    }

    if (currentStep == 3) {
      // Final fallback to make sure dropdown verification clears
      return _formKey.currentState!.validate();
    }

    return false;
  }

 /* Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      error = null;
    });

    final authProvider = Provider.of<AuthProviderMethod>(context, listen: false);

    final message = await authProvider.signUpWithEmailAndPassword(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _numController.text.trim(),
      selectedRole!,
    );

    if (!mounted) return;

    if (message == 'Success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Account created successfully! Verification complete.'),
            backgroundColor: Colors.green),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } else {
      setState(() {
        _isLoading = false;
        error = message;
      });
    }
  }*/

  /*void _onNextPressed() {
    if (selectedRole == 'driver') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DriverVerificationPage(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            phone: _numController.text.trim(),
          ),
        ),
      );
    } else {
      _handleRegister();
    }
  }*/

  void _onNextPressed() {
    if (selectedRole == 'driver') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DriverVerificationPage(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            phone: _numController.text.trim(),
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PassengerFinalRegisterPage(
            name: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            phone: _numController.text.trim(),
            role: 'passenger',
          ),
        ),
      );
    }
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
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                children: [
                  const Text("Create Account", style: AppTextStyles.headingWhite),
                  const SizedBox(height: 20),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 450,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 200, sigmaY: 200),
                        child: Container(
                          width: MediaQuery.of(context).size.width * 0.85,
                          padding: const EdgeInsets.all(24.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(width: 1.5, color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset("assets/images/SajiloRide_logo.png", height: 70),
                                const SizedBox(height: 10),

                                // Step Indicator
                                Text("Step $currentStep of 3",
                                    style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 15),

                                // --- STEP 1: IDENTITY ---
                                if (currentStep == 1) ...[
                                  TextFormField(
                                    controller: _nameController,
                                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                    decoration: inputDecorate.buildInputDecoration("Full Name").copyWith(
                                      suffixIcon: const Icon(Icons.person, color: Colors.orange),
                                    ),
                                    validator: (value) => value == null || value.isEmpty ? "Required" : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                    decoration: inputDecorate.buildInputDecoration("Email").copyWith(
                                      suffixIcon: const Icon(Icons.email, color: Colors.orange),
                                    ),
                                    validator: (value) => (value == null || !value.contains('@')) ? "Invalid email" : null,
                                  ),
                                ],

                                // --- STEP 2: SECURITY & PHONE ---
                                if (currentStep == 2) ...[

                                  IntlPhoneField(
                                    controller: _numController,
                                    focusNode: _phoneFocusNode,
                                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                    decoration: inputDecorate.buildInputDecoration("Phone Number"),
                                    initialCountryCode: 'NP',
                                    onChanged: (phone) => _phoneNumber = phone.completeNumber,
                                    validator: (value) => (value == null || value.number.length < 10) ? 'Enter 10 digit number' : null,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _isPasswordObscured,
                                    style: const TextStyle(color: Colors.black),
                                    decoration: inputDecorate.buildInputDecoration("Password").copyWith(
                                      suffixIcon: IconButton(
                                        icon: Icon(_isPasswordObscured ? Icons.visibility_off : Icons.visibility, color: Colors.orange),
                                        onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
                                      ),
                                    ),
                                    validator: (value) => (value == null || value.length < 6) ? 'Short password' : null,
                                  ),
                                ],

                                // --- STEP 3: ROLE SELECTION ---
                                if (currentStep == 3) ...[
                                  const Text("Choose your role", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 15),
                                  DropdownButtonFormField<String>(
                                    initialValue: selectedRole, // Fixed: changed initialValue to value
                                    decoration: inputDecorate.buildInputDecoration("Select Role"),
                                    dropdownColor: Colors.white,
                                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                    items: roles.map((role) => DropdownMenuItem(value: role, child: Text(role.toUpperCase()))).toList(),
                                    onChanged: (value) => setState(() {
                                      selectedRole = value;
                                      error = null;
                                    }),
                                    validator: (value) => value == null ? "Please select a role" : null,
                                  ),
                                ],

                                if (error != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 15),
                                    child: Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                                  ),

                                const SizedBox(height: 25),

                                // --- NAVIGATION BUTTONS ---
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orangeAccent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: _isLoading ? null : () {
                                      if (_isCurrentStepValid()) { // Fixed: using modular step evaluation logic
                                        if (currentStep < 3) {
                                          setState(() => currentStep++);
                                        } else {
                                          _onNextPressed();
                                        }
                                      }
                                    },
                                    child: _isLoading
                                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : Text(
                                      currentStep < 3 ? "NEXT" : (selectedRole == 'driver' ? "CONTINUE" : "REGISTER"),
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),

                                if (currentStep > 1 && !_isLoading)
                                  TextButton(
                                    onPressed: () => setState(() => currentStep--),
                                    child: const Text("Back", style: TextStyle(color: Colors.black54)),
                                  ),

                                const SizedBox(height: 10),
                                if (currentStep == 1)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Text("Already have an account?", style: TextStyle(color: Colors.black)),
                                      TextButton(
                                        onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                                        child: const Text("Login Now", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
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
*/