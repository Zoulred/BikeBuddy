import 'dart:async';
import 'package:flutter/material.dart';
import '../models/weather.dart';
import '../services/weather_service.dart';
import '../services/LocationInfo.dart';

class WeatherViewModel extends ChangeNotifier {
  final WeatherService _service = WeatherService();
  final LocationService _location = LocationService();
  Weather? _weather;
  bool _isLoading = false;
  Timer? _timer;

  Weather? get weather => _weather;
  bool get isLoading => _isLoading;

  WeatherViewModel() {
    _fetch();
    _timer = Timer.periodic(const Duration(minutes: 10), (_) => _fetch());
  }

  Future<void> _fetch() async {
    _isLoading = true;
    notifyListeners();
    try {
      final pos = await _location.getCurrentPosition();
      if (pos != null) {
        final w = await _service.fetchCurrent(pos.latitude, pos.longitude);
        _weather = w;
      }
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
