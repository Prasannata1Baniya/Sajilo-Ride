import 'package:flutter/material.dart';
import 'package:sajilo_ride/data/model/car_model.dart';
import 'package:sajilo_ride/widgets/car_card.dart';

class PassengerHomeContent extends StatelessWidget {
  PassengerHomeContent({super.key});

  final List<CarModel> carList=[
    CarModel(model: "Fortuner GR", distance: 870, pricePerHour: 45, fuelCapacity: 50,
        image:"assets/images/car1.jpg"),
    CarModel(model: "Fortuner GR", distance: 870, pricePerHour: 45, fuelCapacity: 50,
        image:"assets/images/car2.jpg"),
    CarModel(model: "Fortuner GR", distance: 870, pricePerHour: 45, fuelCapacity: 50,
        image:"assets/images/car3.jpg"),
    CarModel(model: "Fortuner GR", distance: 870, pricePerHour: 45, fuelCapacity: 50,
        image:"assets/images/car4.jpg"),
    CarModel(model: "Fortuner GR", distance: 870, pricePerHour: 45, fuelCapacity: 50,
        image:"assets/images/car2.jpg"),
    CarModel(model: "Fortuner GR", distance: 870, pricePerHour: 45, fuelCapacity: 50,
        image:"assets/images/car3.jpg"),

  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Choose Your Ride"),
      ),
      body: GridView.extent(
        // On a phone: 1 column. On a tablet: 2-3 columns. On a desktop: 4+ columns.
        maxCrossAxisExtent: 350,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,  // Adjust this ratio to get the card shape you like
        children: carList.map((car) {
          // We use .map to convert the list of CarModel into a list of CarCard widgets
          return CarCard(car: car);
        }).toList(),
      ),
    );
  }
}


/*import 'package:flutter/material.dart';
import 'package:sajilo_ride/data/model/car_model.dart';
import 'package:sajilo_ride/widgets/car_card.dart';

class PassengerHomeContent extends StatelessWidget {
   PassengerHomeContent({super.key});

  final List<CarModel> carList=[
    CarModel(model: "Fortuner GR", distance: 870, pricePerHour: 45, fuelCapacity: 50,
        image:"assets/images/car1.jpg"),
    CarModel(model: "Fortuner GR", distance: 870, pricePerHour: 45, fuelCapacity: 50,
    image:"assets/images/car2.jpg"),
    CarModel(model: "Fortuner GR", distance: 870, pricePerHour: 45, fuelCapacity: 50,
    image:"assets/images/car3.jpg"),
    CarModel(model: "Fortuner GR", distance: 870, pricePerHour: 45, fuelCapacity: 50,
        image:"assets/images/car4.jpg"),
    CarModel(model: "Fortuner GR", distance: 870, pricePerHour: 45, fuelCapacity: 50,
        image:"assets/images/car2.jpg"),
    CarModel(model: "Fortuner GR", distance: 870, pricePerHour: 45, fuelCapacity: 50,
        image:"assets/images/car3.jpg"),

  ];

 // final List<Widget> _pages=[];


  @override
  Widget build(BuildContext context) {
    final bool isWideScreen = MediaQuery.of(context).size.width >=600;

    return Scaffold(
      body: isWideScreen ? GridView.builder(
            itemCount: carList.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.9,
            //childAspectRatio: 4/5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context,index){
            return CarCard(car: carList[index]
            );

      }) : ListView.builder(
          itemCount: carList.length,
          itemBuilder: (context,index){
        return Padding(
          padding: const EdgeInsets.only(bottom:12.0),
          child: CarCard(car: carList[index]),
        );
      })
    );
  }
}
*/