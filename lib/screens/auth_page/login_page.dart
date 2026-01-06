import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sajilo_ride/auth/auth_provider.dart';
import 'package:sajilo_ride/screens/auth_page/register_page.dart';
import 'package:sajilo_ride/utils/input_decoration.dart';
import 'package:sajilo_ride/utils/text_styles.dart';
import '../../main.dart';


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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      isLoading = true;
      error = null;
    });

    // Use `context.read` to get the provider. It's concise and clear.
    final message = await context.read<AuthProviderMethod>().loginWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    // The 'mounted' check protects all subsequent context-dependent code.
    if (!mounted) return;

    if (message == 'Success') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
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
          // ... your background container ...
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
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Container(
                        height: 500,
                        width:700,
                        padding: const EdgeInsets.all(20.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(width: 1.5, color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset("assets/images/SajiloRide_logo.png", height: 120),
                              const SizedBox(height: 20),
                              // ... TextFormFields ...
                              TextFormField(
                                controller: _emailController,
                                style: const TextStyle(color: Colors.white),
                                keyboardType: TextInputType.emailAddress,
                                decoration: inputDecorate.buildInputDecoration("Email"),
                                validator: (value) => (value == null || !value.contains('@')) ? 'Enter a valid email' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                style: const TextStyle(color: Colors.white),
                                obscureText: true,
                                decoration: inputDecorate.buildInputDecoration("Password"),
                                validator: (value) => (value == null || value.length < 6) ? 'Password must be at least 6 characters' : null,
                              ),
                              if (error != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 15, bottom: 5),
                                  child: Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: 150,
                                height: 50,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    elevation: 5,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    backgroundColor: Colors.orangeAccent,
                                  ),
                                  // Call the handler method here.
                                  onPressed: isLoading ? null : _handleLogin,
                                  child: isLoading
                                      ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 3)
                                      : const Text("Login", style: AppTextStyles.bodyTextWhite),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));
                                },
                                child: const Text("Create new account", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
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






/*class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? error;
  bool isLoading =false;
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderMethod>(context);
    //final isWide = MediaQuery.of(context).size.width > 600;
    final InputDecorate inputDecorate=InputDecorate();


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
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                  // const SizedBox(height: 20,),
                   const Text("Login", style: AppTextStyles.headingWhite),

                   const SizedBox(height: 20),
                   ClipRRect(
                     borderRadius: BorderRadius.circular(25),
                     child: BackdropFilter(
                     filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                     child: Container(
                       width: 600,
                       height: 400,
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
                             Image.asset("assets/images/SajiloRide_logo.png", height: 150),
                             TextFormField(
                               controller: _emailController,
                               style: const TextStyle(color: Colors.white),
                               decoration: inputDecorate.buildInputDecoration("Email"),
                               validator: (value) {
                                 if (value == null || !value.contains('@')) return 'Enter a valid email';
                                 return null;
                               },
                             ),

                             const SizedBox(height: 16),

                             TextFormField(
                               controller: _passwordController,
                               style: const TextStyle(color: Colors.white),
                               obscureText: true,
                               decoration: inputDecorate.buildInputDecoration("Password"),
                               validator: (value) {
                                 if (value == null || value.length < 6) return 'Password must be at least 6 characters';
                                 return null;
                               },
                             ),

                             if (error != null)
                               Padding(
                                 padding: const EdgeInsets.only(top: 10),
                                 child: Text(error!, style: const TextStyle(color: Colors.red)),
                               ),

                             const SizedBox(height: 20),

                             SizedBox(
                               width: 150,
                               child: ElevatedButton(
                                 style: ElevatedButton.styleFrom(
                                   elevation: 5,
                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                   backgroundColor: Colors.orangeAccent,
                                 ),
                                 onPressed: isLoading
                                     ? null
                                     : () async {
                                   if (!_formKey.currentState!.validate()) return;

                                   FocusScope.of(context).unfocus();
                                   setState(() {
                                     error = null;
                                     isLoading = true;
                                   });

                                   final message = await authProvider.loginWithEmailAndPassword(
                                     _emailController.text.trim(),
                                     _passwordController.text.trim(),
                                   );

                                   if (!mounted) return;

                                   setState(() => isLoading = false);

                                   if (message != null) {
                                     setState(() => error = message);
                                   }
                                 },
                                 child: isLoading
                                     ? const CircularProgressIndicator(color: Colors.white)
                                     : const Text("Login",style: AppTextStyles.bodyTextWhite),
                               ),
                             ),

                             TextButton(
                               onPressed: () {
                                 Navigator.push(
                                   context,
                                   MaterialPageRoute(builder: (_) => const RegisterPage()),
                                 );
                               },
                               child: const Text("Create new account",
                                   style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
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
/*class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController= TextEditingController();
  final TextEditingController _passwordController= TextEditingController();
  String? error;


  @override
  Widget build(BuildContext context) {
    final screenWidth= MediaQuery.of(context).size.width;
    final bool isWideScreen = screenWidth > 600;
    final authProvider= Provider.of<AuthProviderMethod>(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: isWideScreen ? double.infinity :500,
              height: 100,
              decoration:const BoxDecoration(
                color: Colors.blue,
              ),
              child:const  Column(
                children: [
                  Icon(Icons.car_rental, color: Colors.orangeAccent,size: 60,),
                  Text(" Sajilo Ride"),
                  Text("Cab Booking"),
                ],
              ),
            ),

            const SizedBox(width: 60,),
            const Text("Login"),

            const SizedBox(width: 30,),
            //email
            SizedBox(
              width: 500,
              child: TextField(
                controller: _emailController,
                decoration:const InputDecoration(
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.email),
                  labelText: "email",
                  labelStyle: TextStyle(color: Colors.grey),
                ),
              ),
            ),

              const SizedBox(width: 20,),
              //password text Field
              SizedBox(
                width: 500,
                child: TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.password),
                    labelText: "password",
                    labelStyle: TextStyle(color: Colors.grey),
                  ),
                ),
              ),

            const SizedBox(width: 20,),
            //Elevated Button
            SizedBox(
              width: 500,
              child: ElevatedButton(

                  onPressed: () async{
                    String email= _emailController.text.trim();
                    String password = _passwordController.text.trim();
                     final String? message= await authProvider.loginWithEmailAndPassword(email, password);

                    if(message !=null){
                      setState(() {
                        error=message;
                      });
                    }
              },
                  child: const Text( "Login"),
              ),
            ),

            TextButton(
                onPressed: (){
              setState(() {
                Navigator.push(context, MaterialPageRoute(builder: (_)=> const RegisterPage()));
              });
            }, child:const  Text("Create a new Account")),
          ],
        ),
      ),
    );
  }
}*/