import 'package:flutter/material.dart';
import 'package:sajilo_ride/data/model/car_model.dart';
import 'package:sajilo_ride/utils/text_styles.dart';

class CarCard extends StatelessWidget {
  final CarModel car;
   const CarCard({super.key, required this.car});


  @override
  Widget build(BuildContext context) {
  
    //final ht =MediaQuery.of(context).size.height >600;
   // final isHt = ht>600;

    //final wt =MediaQuery.of(context).size.width;
    //final isWt = wt>600;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        color: Colors.white,
        elevation:5,
        child: Container(
          width: 200,
          margin: const EdgeInsets.all(12),
          child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
            children:[

              Image.asset(car.image, height: 200,),
              const SizedBox(height:10),
              Text(car.model, style: AppTextStyles.bodyTextBlack),

              const SizedBox(height: 10,),
                Row(
                  children: [
                    const Icon(Icons.gps_fixed),
                    Text('Distance: ${car.distance.toStringAsFixed(0)} km'),
                  ],
                ),

              Row(
                children: [
                  const Icon(Icons.heat_pump_outlined),
                  Text('Price: ${car.pricePerHour.toStringAsFixed(0)} km'),
                ],
              ),

                Row(
                  children: [
                    const Icon(Icons.heat_pump_outlined),
                    Text('Fuel Capacity: ${car.fuelCapacity.toStringAsFixed(0)} km'),
                  ],
                ),
              const SizedBox(height: 10,),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                 elevation: 5,
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  )
                ),
                  onPressed: (){

              },
                  child:const Center(
                      child: Text("Book this Car",style: AppTextStyles.bodyTextWhite,)
                  ),
              ),

            ]
          ),
        ),
      ),
    );
  }
}
