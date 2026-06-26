class CarModel {
  final String? id;
  final String model;
  final String carNumber;
  final String image;
  final String driverId;
  final String driverName;
  final String phone;
  final String vehicleType;
  final double pricePerKm;
  final double rating;
  final bool isOnline;
  final double latitude;
  final double longitude;

  CarModel({
    this.id,
    required this.model,
    required this.carNumber,
    required this.image,
    required this.driverId,
    required this.driverName,
    required this.phone,
    required this.vehicleType,
    required this.pricePerKm,
    required this.rating,
    required this.isOnline,
    required this.latitude,
    required this.longitude,
  });

  factory CarModel.fromMap(Map<String, dynamic> map, String docId) => CarModel(
    id: docId,
    model: map['model'] ?? 'Unknown',
    carNumber: map['plateNumber'] ?? '',
    image: map['image'] ?? '',
    driverId: map['driverId'] ?? '',
    driverName: map['driverName'] ?? 'Driver',
    phone: map['phone'] ?? '',
    vehicleType: map['vehicleType'] ?? 'Standard',
    pricePerKm: double.tryParse(map['pricePerKm']?.toString() ?? '0.0') ?? 0.0,
    rating: (map['rating'] as num? ?? 0.0).toDouble(),
    isOnline: map['isOnline'] ?? false,
    latitude: (map['latitude'] as num? ?? 0.0).toDouble(),
    longitude: (map['longitude'] as num? ?? 0.0).toDouble(),
  );

  Map<String, dynamic> toMap() => {
    'model': model,
    'plateNumber': carNumber,
    'image': image,
    'driverId': driverId,
    'driverName': driverName,
    'phone': phone,
    'vehicleType': vehicleType,
    'pricePerKm': pricePerKm,
    'rating': rating,
    'isOnline': isOnline,
    'latitude': latitude,
    'longitude': longitude,
  };
}