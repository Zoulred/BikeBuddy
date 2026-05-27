import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Ride {
  final int? id;
  final int bikeId;
  final String title;
  final List<LatLng> route;
  final double distance;
  final Duration duration;
  final double averageSpeed;
  final double maxSpeed;
  final double elevation;
  final int calories;
  final DateTime dateTime;
  final String? weather;

  Ride({
    this.id,
    required this.bikeId,
    required this.title,
    required this.route,
    required this.distance,
    required this.duration,
    required this.averageSpeed,
    required this.maxSpeed,
    required this.elevation,
    required this.calories,
    required this.dateTime,
    this.weather,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bikeId': bikeId,
      'title': title,
      'route': json.encode(
        route.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      ),
      'distance': distance,
      'duration': duration.inSeconds,
      'averageSpeed': averageSpeed,
      'maxSpeed': maxSpeed,
      'elevation': elevation,
      'calories': calories,
      'dateTime': dateTime.toIso8601String(),
      'weather': weather,
    };
  }

  factory Ride.fromMap(Map<String, dynamic> map) {
    var routeList = json.decode(map['route']) as List;
    return Ride(
      id: map['id'],
      bikeId: map['bikeId'],
      title: map['title'],
      route: routeList.map((p) => LatLng(p['lat'], p['lng'])).toList(),
      distance: map['distance']?.toDouble() ?? 0.0,
      duration: Duration(seconds: map['duration'] ?? 0),
      averageSpeed: map['averageSpeed']?.toDouble() ?? 0.0,
      maxSpeed: map['maxSpeed']?.toDouble() ?? 0.0,
      elevation: map['elevation']?.toDouble() ?? 0.0,
      calories: map['calories'] ?? 0,
      dateTime: DateTime.parse(map['dateTime']),
      weather: map['weather'],
    );
  }
}
