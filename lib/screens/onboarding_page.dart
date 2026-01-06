import 'package:flutter/material.dart';
import 'package:sajilo_ride/screens/auth_page/login_page.dart';
import 'package:sajilo_ride/utils/text_styles.dart';


class OnBoardingPage extends StatelessWidget {
  const OnBoardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/car_onboarding1.jpg"),
                fit: BoxFit.cover,
              ),
            ),

              child:  Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/images/SajiloRide_logo.png",
                        height: 400,
                        semanticLabel: 'Sajilo Ride App Logo',
                      ),

                      const SizedBox(height: 3,),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          backgroundColor: Colors.orangeAccent,
                        ),
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                          );
                        },
                        child: const Text(
                          "Get Started",
                          style: AppTextStyles.bodyTextWhite,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}



/*class OnBoardingPage extends StatefulWidget {
  const OnBoardingPage({super.key});

  @override
  State<OnBoardingPage> createState() => _OnBoardingPageState();
}

class _OnBoardingPageState extends State<OnBoardingPage> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isWideScreen= screenWidth > 600;

    return Scaffold(
      body: Stack(
        children: [
      Positioned.fill(child:Image.asset("assets/images/car_onboarding.jpg",fit: BoxFit.fill,),),

          Column(
            children: [
              Image.asset("assets/images/car_logo1.png",height: 200,),
              const SizedBox(height:20),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Colors.orangeAccent,
                  ),
                  onPressed: (){
                    Navigator.push(context, MaterialPageRoute(builder: (_)=>const  LoginPage()));
                  }, child: const Text("Get Started",style: AppTextStyles.bodyTextWhite,)
              ),
            ],
          ),


        ],
      ),
    );
  }
}
*/