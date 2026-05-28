import 'package:flutter/material.dart';
import '../models/bike.dart';
import '../services/Datehandle.dart';

class BikeViewModel extends ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  List<Bike> _bikes = [];
  bool _isLoading = false;

  List<Bike> get bikes => _bikes;
  bool get isLoading => _isLoading;

  BikeViewModel() {
    loadBikes();
  }

  Future<void> loadBikes() async {
    _isLoading = true;
    notifyListeners();
    _bikes = await _dbService.getBikes();
    _isLoading = false;
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
