import 'package:flutter/material.dart';
import '../models/ride.dart';
import '../services/database_service.dart';

class RideViewModel extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<Ride> _rides = [];
  bool _isLoading = false;

  List<Ride> get rides => _rides;
  bool get isLoading => _isLoading;

  RideViewModel() {
    loadRides();
  }

  Future<void> loadRides() async {
    _isLoading = true;
    notifyListeners();
    _rides = await _dbService.getRides();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addRide(Ride ride) async {
    await _dbService.insertRide(ride);
    await loadRides();
  }
}
