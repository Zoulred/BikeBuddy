import 'dart:convert';

enum BikeType { mountain, road, gravel, folding, bmx, other }

class Bike {
  final int? id;
  final String name;
  final BikeType type;
  final String? imagePath;
  final DateTime purchaseDate;
  final double totalKilometers;
  final String maintenanceStatus;

  Bike({
    this.id,
    required this.name,
    required this.type,
    this.imagePath,
    required this.purchaseDate,
    this.totalKilometers = 0.0,
    this.maintenanceStatus = 'Good',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'imagePath': imagePath,
      'purchaseDate': purchaseDate.toIso8601String(),
      'totalKilometers': totalKilometers,
      'maintenanceStatus': maintenanceStatus,
    };
  }

  factory Bike.fromMap(Map<String, dynamic> map) {
    return Bike(
      id: map['id'],
      name: map['name'],
      type: BikeType.values[map['type']],
      imagePath: map['imagePath'],
      purchaseDate: DateTime.parse(map['purchaseDate']),
      totalKilometers: map['totalKilometers']?.toDouble() ?? 0.0,
      maintenanceStatus: map['maintenanceStatus'] ?? 'Good',
    );
  }

  String toJson() => json.encode(toMap());

  factory Bike.fromJson(String source) => Bike.fromMap(json.decode(source));
}
