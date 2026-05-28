import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bike.dart';
import '../services/Datehandle.dart';

class BikeViewModel extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<Bike> _bikes = [];
  bool _isLoading = false;

  List<Bike> get bikes => _bikes;
  bool get isLoading => _isLoading;
  int? _activeBikeId;

  int? get activeBikeId => _activeBikeId;

  Bike? get activeBike {
    if (_activeBikeId == null) {
      return _bikes.isNotEmpty ? _bikes.first : null;
    }
    try {
      return _bikes.firstWhere((b) => b.id == _activeBikeId);
    } catch (_) {
      return _bikes.isNotEmpty ? _bikes.first : null;
    }
  }

  BikeViewModel() {
    loadBikes();
    _loadActiveBike();
  }

  Future<void> loadBikes() async {
    _isLoading = true;
    notifyListeners();
    _bikes = await _dbService.getBikes();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadActiveBike() async {
    final sp = await SharedPreferences.getInstance();
    final id = sp.getInt('active_bike_id');
    _activeBikeId = id;
    notifyListeners();
  }

  Future<void> setActiveBike(int? id) async {
    _activeBikeId = id;
    final sp = await SharedPreferences.getInstance();
    if (id == null) {
      await sp.remove('active_bike_id');
    } else {
      await sp.setInt('active_bike_id', id);
    }
    notifyListeners();
  }

  Future<void> addBike(Bike bike) async {
    await _dbService.insertBike(bike);
    await loadBikes();
  }

  Future<void> updateBike(Bike bike) async {
    await _dbService.updateBike(bike);
    await loadBikes();
  }

  Future<void> deleteBike(int id) async {
    await _dbService.deleteBike(id);
    await loadBikes();
  }
}
