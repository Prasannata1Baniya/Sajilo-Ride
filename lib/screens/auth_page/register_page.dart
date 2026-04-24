import 'package:flutter/material.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:provider/provider.dart';
import 'package:sajilo_ride/auth/auth_provider.dart';
import 'package:sajilo_ride/utils/input_decoration.dart';
import 'package:sajilo_ride/utils/text_styles.dart';
import 'driver_verification_page.dart';
import 'login_page.dart';
import 'package:flutter/foundation.dart';

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
  final _numController =TextEditingController();

  FocusNode focusNode = FocusNode();
  String _phoneNumber="";

  //final List<String> roles = ['Passenger', 'Driver'];
  final List<String> roles = ['passenger', 'driver'];
  String? selectedRole;
  String? error;
  bool _isLoading = false;

  Uint8List? _imageData;

  final InputDecorate inputDecorate = InputDecorate();
  bool _isPasswordObscured = true;


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneNumber;
    super.dispose();
  }


  /*Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 25
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _imageData = bytes;
        error = null;
      });
    }
  }*/

  // --- LOGIC: HANDLE REGISTRATION ---
  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    // Check for image if driver
    if (selectedRole == 'driver' && _imageData == null) {
      setState(() => error = "Please upload your Driver's License first");
      return;
    }

    setState(() {
      _isLoading = true;
      error = null;
    });

    final authProvider = Provider.of<AuthProviderMethod>(context, listen: false);

    final message = await authProvider.signUpWithEmailAndPassword(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _numController.text,
      selectedRole!,
    );

    if (!mounted) return;

    if (message == 'Success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Account created successfully! Verification complete.'),
            backgroundColor: Colors.green
        ),
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
  }

  void _onNextPressed() {
    if (!_formKey.currentState!.validate()) return;

    if (selectedRole == 'driver') {
      // Navigate to the License Upload Page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DriverVerificationPage(
            name: _nameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            phone: _numController.text,
          ),
        ),
      );
    } else {
      // If passenger, just register normally
      _handleRegister();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

         /* Positioned.fill(
            child: Image.asset(
              "assets/images/car_background.png",
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              height: double.infinity,
              width: double.infinity,
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
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.85,
                        padding: const EdgeInsets.all(24.0),
                        decoration: BoxDecoration(
                          //color: Colors.white.withValues(alpha: 0.8),
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(width: 1.5, color: Colors.white.withValues(alpha:0.2)),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset("assets/images/SajiloRide_logo.png", height: 80),
                              const SizedBox(height: 20),

                              //Name
                              TextFormField(
                                controller: _nameController,
                                style: const TextStyle(color: Colors.black,
                                    fontWeight: FontWeight.bold),
                                decoration: inputDecorate.buildInputDecoration("Full Name").copyWith(
                                  labelStyle: const TextStyle(color: Colors.black),
                                    suffixIcon: Icon(Icons.person,color: Colors.orange,)
                                ),
                                validator: (value) => value == null || value.isEmpty ? "Required" : null,
                              ),
                              const SizedBox(height: 16),

                              //email
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: Colors.black,
                                    fontWeight: FontWeight.bold),
                                decoration: inputDecorate.buildInputDecoration("Email").copyWith(
                                  labelStyle: const TextStyle(color: Colors.black),
                                  suffixIcon: Icon(Icons.email, color: Colors.orange,),
                                ),
                                validator: (value) => (value == null || !value.contains('@'))
                                    ? "Invalid email" : null,
                              ),
                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _passwordController,
                                validator: (value) =>
                                (value == null || value.length < 6)
                                    ? 'Short password'
                                    : null,
                                  style: const TextStyle(color: Colors.black),
                                  obscureText: _isPasswordObscured,
                                  decoration: inputDecorate.buildInputDecoration("Password").copyWith(
                                    labelStyle: const TextStyle(color: Colors.black),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordObscured ? Icons.visibility_off : Icons.visibility,
                                        color: Colors.orange,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordObscured = !_isPasswordObscured;
                                        });
                                      },
                                    ),
                              ),
                              ),

                              const SizedBox(height: 16),

                              //Number
                              IntlPhoneField(
                                validator: (value)=>(value==null ||
                                    value.number.length<10)
                                ? 'Enter 10 digit number'
                                : null,
                                controller: _numController,
                                style: const TextStyle(color: Colors.black),
                                dropdownTextStyle: const TextStyle(color: Colors.black),
                                cursorColor: Colors.orangeAccent,
                                decoration: inputDecorate.buildInputDecoration("Phone Number").copyWith(
                                  counterStyle: const TextStyle(color: Colors.white),
                                ),
                                initialCountryCode: 'NP',
                                onChanged: (phone) {
                                  _phoneNumber = phone.completeNumber;
                                },
                                // This makes the country picker popup look modern too
                                pickerDialogStyle: PickerDialogStyle(
                                  //backgroundColor: Colors.grey[900],
                                  backgroundColor: Colors.white,
                                  countryCodeStyle: const TextStyle(color: Colors.black),
                                  countryNameStyle: const TextStyle(color: Colors.black),
                                  searchFieldInputDecoration: InputDecoration(
                                    labelText: 'Search Country',
                                    labelStyle: const TextStyle(color: Colors.black),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                initialValue: selectedRole,
                                decoration: inputDecorate.buildInputDecoration("Select Role"),
                                dropdownColor: Colors.black87,
                                style: const TextStyle(color: Colors.white),
                                borderRadius: BorderRadius.circular(25),
                                items: roles.map((role) => DropdownMenuItem(value: role, child: Text(role))).toList(),
                                onChanged: (value) => setState(() {
                                  selectedRole = value;
                                  error = null;
                                }),
                                validator: (value) => value == null ? "Required" : null,
                              ),


                             /* // --- DRIVER LICENSE UI ---
                              if (selectedRole == 'driver') ...[
                                const SizedBox(height: 20),
                                const Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(" License Document", style: TextStyle(color: Colors.white70, fontSize: 13)),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    height: 110,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(color: Colors.white24, width: 1.5),
                                    ),
                                    child: _imageData == null
                                        ? const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_a_photo_outlined, color: Colors.orangeAccent, size: 30),
                                        SizedBox(height: 5),
                                        Text("Tap to upload License",
                                            style: TextStyle(color: Colors.white60, fontSize: 11)),
                                      ],
                                    )
                                        : ClipRRect(
                                      borderRadius: BorderRadius.circular(15),
                                      child: Image.memory(
                                        _imageData!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    ),
                                  ),
                                ),
                              ],*/


                              if (error != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 15),
                                  child: Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                                ),

                              const SizedBox(height: 25),

                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orangeAccent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: _isLoading ? null : _onNextPressed,
                                  /*child: _isLoading
                                      ? const SizedBox(height: 20, width: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : const Text("Register", style: TextStyle(color: Colors.white,
                                      fontSize: 16, fontWeight: FontWeight.bold)),*/
                                  child: _isLoading
                                      ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                  )
                                      : Text(
                                    selectedRole == 'driver' ? "Continue" : "Register",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 15),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("Already have an account?",
                                      style: TextStyle(color: Colors.black)),
                                  TextButton(
                                    onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage())),
                                    child: const Text("Login Now",
                                        style: TextStyle(color: Colors.orangeAccent,
                                            fontWeight: FontWeight.bold)),
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
