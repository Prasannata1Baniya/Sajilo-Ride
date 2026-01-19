import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sajilo_ride/auth/auth_provider.dart';
import 'package:sajilo_ride/utils/input_decoration.dart';
import 'package:sajilo_ride/utils/text_styles.dart';
import 'login_page.dart';
import 'dart:ui';

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

  final List<String> roles = ['Passenger', 'Driver'];
  String? selectedRole;
  String? error;
  bool _isLoading = false;

  final InputDecorate inputDecorate = InputDecorate();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String? addImage(){

    return null;
  }


  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      error = null;
    });

    final authProvider = Provider.of<AuthProviderMethod>(context, listen: false);
    final message = await authProvider.signUpWithEmailAndPassword(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text.trim(),
      selectedRole!,
    );
    debugPrint('AuthProvider returned: "$message"');

    if (!mounted) return;

    if (message == 'Success') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully!')),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }else {
      setState(() {
        _isLoading = false;
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
              image: DecorationImage(
                image: AssetImage("assets/images/car_background.png"),
                fit: BoxFit.cover,
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
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        //height: 550,
                        height: MediaQuery.of(context).size.height * 0.8,  // Responsive height
                        width: MediaQuery.of(context).size.width * 0.6,   // Responsive width
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            width: 1.5,
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset("assets/images/SajiloRide_logo.png", height: 100),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _nameController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: inputDecorate.buildInputDecoration("Full Name"),
                                  validator: (value) =>
                                  value == null || value.isEmpty ? "Please enter your name" : null,
                                ),

                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: inputDecorate.buildInputDecoration("Email"),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Please enter your email';
                                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                    if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: true,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: inputDecorate.buildInputDecoration("Password"),
                                  validator: (value) =>
                                  value == null || value.length < 6 ? "Password must be at least 6 characters" : null,
                                ),

                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: selectedRole,
                                  decoration: inputDecorate.buildInputDecoration("Select Role"),
                                  dropdownColor: Colors.black.withOpacity(0.8),
                                  style: const TextStyle(color: Colors.white),
                                  items: roles.map((role) {
                                    return DropdownMenuItem(value: role, child: Text(role));
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() => selectedRole = value);
                                  },
                                  validator: (value) {
                                    if(value==null){
                                      return "Please enter a role";
                                    }
                                    return null;
                                  }
                                ),

                                if(selectedRole == 'Driver' )
                                  Container(
                                    key: _formKey,
                                    height:50,
                                    width: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                        onPressed: addImage,
                                        icon: const Icon(Icons.add)
                                    ),
                                  ),

                                // This block will now display the error message from the state
                                if (error != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 15, bottom: 5),
                                    child: Text(
                                      error!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Colors.redAccent,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),

                                const SizedBox(height: 20),
                                SizedBox(
                                  width: 150,
                                  height: 50,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orangeAccent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    onPressed: _isLoading ? null : _handleRegister,
                                    child: _isLoading
                                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                                        : const Text("Register", style: AppTextStyles.bodyTextWhite),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Already have an account?", style: TextStyle(color: Colors.white70)),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pushReplacement(
                                            context, MaterialPageRoute(builder: (_) => const LoginPage()));
                                      },
                                      child: const Text("Login Now",
                                          style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
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

/*
the no-cost quotas for Cloud Storage are generally only available for buckets
 located in specific regions like us-central1 , us-west1 ,
and us-east1 . If your buckets are in other regions, standard Google Cloud Storage pricing will apply.
 */

/*class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  final List<String> roles = ['Passenger', 'Driver'];
  String? selectedRole;
  String? error;
  bool _isLoading = false;

  final InputDecorate inputDecorate = InputDecorate();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // 1. Validate form and hide keyboard
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. Start loading and clear previous error
    setState(() {
      _isLoading = true;
      error = null; // Clear any old errors before trying again
    });

    final authProvider = Provider.of<AuthProviderMethod>(context, listen: false);

    // 3. Call authentication method with CORRECT parameters
    final message = await authProvider.signUpWithEmailAndPassword(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text.trim(),
      selectedRole!,
    );

    // 4. Check if the widget is still on screen
    if (!mounted) return;

    // 5. Handle the result
    if (message == 'Success') {
      // On success, just navigate. You could show a dialog here if you wish.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } else {
      // On failure, stop loading and set the error message to be displayed.
      setState(() {
        _isLoading = false;
        error = message; // Set the error string from the provider
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
              image: DecorationImage(
                image: AssetImage("assets/images/car_background.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Create Account", style: AppTextStyles.heading1),
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.8,  // use Flexible/Expanded
                        width: MediaQuery.of(context).size.width * 0.9,
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            width: 1.5,
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset("assets/images/SajiloRide_logo.png", height: 100),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _nameController,
                                style: const TextStyle(color: Colors.white),
                                decoration: inputDecorate.buildInputDecoration("Full Name"),
                                validator: (value) =>
                                value == null || value.isEmpty ? "Please enter your name" : null,
                              ),

                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: Colors.white),
                                decoration: inputDecorate.buildInputDecoration("Email"),
                                validator: (value) =>
                                value == null || !value.contains('@') ? "Enter a valid email" : null,
                              ),

                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                style: const TextStyle(color: Colors.white),
                                decoration: inputDecorate.buildInputDecoration("Password"),
                                validator: (value) =>
                                value == null || value.length < 6 ? "Password must be at least 6 characters" : null,
                              ),

                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: selectedRole,
                                decoration: inputDecorate.buildInputDecoration("Select Role"),
                                dropdownColor: Colors.black.withOpacity(0.8),
                                style: const TextStyle(color: Colors.white),
                                items: roles.map((role) {
                                  return DropdownMenuItem(value: role, child: Text(role));
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => selectedRole = value);
                                },
                                validator: (value) => value == null ? "Please select a role" : null,
                              ),

                              // This block will now display the error message from the state
                              if (error != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 15, bottom: 5),
                                  child: Text(
                                    error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.redAccent,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),

                              const SizedBox(height: 20),
                              SizedBox(
                                width: 150,
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orangeAccent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: _isLoading ? null : _handleRegister,
                                  child: _isLoading
                                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                                      : const Text("Register", style: AppTextStyles.bodyTextWhite),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("Already have an account?", style: TextStyle(color: Colors.white70)),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushReplacement(
                                          context, MaterialPageRoute(builder: (_) => const LoginPage()));
                                    },
                                    child: const Text("Login Now",
                                        style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
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

*/
/*class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final List<String> roles = ['Passenger', 'Driver'];
  String? selectedRole;
  String? error;

InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      contentPadding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.orangeAccent, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderMethod>(context);
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      body:Container(
        height: double.infinity,
          width: double.infinity,
          decoration:const BoxDecoration(
              image:DecorationImage(
        image:AssetImage("assets/images/car_onboarding1.jpg",),
            fit: BoxFit.fill,)
              ),

              child:  Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Image.asset("assets/images/car_logo1.png",height: 200,),
                      const SizedBox(height: 10),
                      const Text("Register", style: AppTextStyles.heading1),

                      const SizedBox(height: 15),
                      Container(
                        height: 350,
                        width: 600,
                        decoration:  BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(width: 1 ,color: Colors.black),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                decoration: const InputDecoration(
                                  fillColor: Colors.blue,
                                  focusColor: Colors.orangeAccent,
                                  labelText: "Email",
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || !value.contains('@')) {
                                    return "Enter valid email";
                                  }
                                  return null;
                                },
                                controller: _emailController,
                              ),

                              const SizedBox(height: 16),

                              TextFormField(
                                controller: _passwordController,
                                obscureText: true,
                                decoration: const InputDecoration(
                                  labelText: "Password",
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.length < 6) {
                                    return "Password must be at least 6 characters";
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              DropdownButtonFormField<String>(
                                value: selectedRole,
                                decoration: const InputDecoration(
                                  labelText: "Select Role",
                                  border: OutlineInputBorder(),
                                ),
                                items: roles.map((role) {
                                  return DropdownMenuItem(
                                    value: role,
                                    child: Text(role),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() => selectedRole = value);
                                },
                                validator: (value) =>
                                value == null ? "Please select role" : null,
                              ),

                              if (error != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Text(error!, style: const TextStyle(color: Colors.red)),
                                ),

                              const SizedBox(height: 20),
                              const SizedBox(width: double.infinity,),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: Colors.orangeAccent,
                                ),
                                onPressed: () async {
                                  final message= await authProvider.signUpWithEmailAndPassword(
                                      _emailController.toString().trim(), _passwordController.toString().trim());
                                  if(message != null){
                                    error =message;
                                  }
                                }, child: const Text("Register",
                                  style: AppTextStyles.bodyTextWhite),
                              ),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                // crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text(" Already Registered?"),
                                  TextButton(onPressed: (){
                                    Navigator.push(context, MaterialPageRoute(builder: (_)=>const LoginPage()));
                                  },
                                    child:const Text("Login Page"),
                                  ),
                                ],
                              ),

                            ],
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
*/







/*class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final List<String> roles = ['Passenger', 'Driver'];
  String? selectedRole;
  String? error;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderMethod>(context);
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  height: 170,
                  width:double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.car_rental, color: Colors.orangeAccent,size: 60,),
                      Text(" Sajilo Ride",style: AppTextStyles.headingWhite,),
                      Text("Cab Booking",style: AppTextStyles.bodyTextWhite,),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                const Text("Register", style: AppTextStyles.heading1),

                const SizedBox(height: 15),
                Center(
                  child: Container(
                    height: 350,
                    width: 600,
                    decoration: const BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey,
                          blurRadius: 15,
                          spreadRadius: 1,
                          offset: Offset(4,-4),
                        ),
                        BoxShadow(
                          color: Colors.grey,
                          blurRadius: 15,
                          spreadRadius: 1,
                          offset: Offset(-4,4),
                        )
                      ]
                    ),
                    child: Card(
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            TextFormField(
                              decoration: const InputDecoration(
                                labelText: "Email",
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || !value.contains('@')) {
                                  return "Enter valid email";
                                }
                                return null;
                              },
                              controller: _emailController,
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: "Password",
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.length < 6) {
                                  return "Password must be at least 6 characters";
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            DropdownButtonFormField<String>(
                              value: selectedRole,
                              decoration: const InputDecoration(
                                labelText: "Select Role",
                                border: OutlineInputBorder(),
                              ),
                              items: roles.map((role) {
                                return DropdownMenuItem(
                                  value: role,
                                  child: Text(role),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() => selectedRole = value);
                              },
                              validator: (value) =>
                              value == null ? "Please select role" : null,
                            ),

                            if (error != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Text(error!, style: const TextStyle(color: Colors.red)),
                              ),

                            const SizedBox(height: 20),
                            const SizedBox(width: double.infinity,),
                            ElevatedButton(
                             style: ElevatedButton.styleFrom(
                               elevation: 5,
                               shape: RoundedRectangleBorder(
                                 borderRadius: BorderRadius.circular(12),
                               ),
                               backgroundColor: Colors.black,
                             ),
                              onPressed: () async {
                                final message= await authProvider.signUpWithEmailAndPassword(
                                    _emailController.toString().trim(), _passwordController.toString().trim());
                                if(message != null){
                                  error =message;
                                }
                              }, child: const Text("Register",
                              style: AppTextStyles.bodyTextWhite),
                            ),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                             // crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(" Already Registered?"),
                                TextButton(onPressed: (){
                                  Navigator.push(context, MaterialPageRoute(builder: (_)=>const LoginPage()));
                                },
                                  child:const Text("Login Page"),
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
        ],
      ),
    );
  }
}
*/

