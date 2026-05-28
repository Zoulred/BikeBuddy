import 'dart:async';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/ride.dart';
import '../../services/LocationInfo.dart';
import '../../services/Datehandle.dart';
import 'ride_timer_service.dart';
import 'package:geolocator/geolocator.dart';

class RideTrackingService {
  RideTrackingService._internal();
  static final RideTrackingService instance = RideTrackingService._internal();

  final LocationService _locationService = LocationService();
  final DatabaseService _db = DatabaseService();
  final RideTimerService _timer = RideTimerService.instance;

  bool _isTracking = false;
  bool _isPaused = false;
  bool _isLocked = false;

  final List<LatLng> _route = [];
  double _distanceKm = 0.0;
  double _currentSpeedKmh = 0.0;
  Position? _lastPosition;
  StreamSubscription<Position>? _posSub;

  final List<Duration> laps = [];

  final _isTrackingCtrl = StreamController<bool>.broadcast();
  final _distanceCtrl = StreamController<double>.broadcast();
  final _speedCtrl = StreamController<double>.broadcast();
  final _routeCtrl = StreamController<List<LatLng>>.broadcast();

  Stream<bool> get isTrackingStream => _isTrackingCtrl.stream;
  Stream<double> get distanceStream => _distanceCtrl.stream;
  Stream<double> get speedStream => _speedCtrl.stream;
  Stream<List<LatLng>> get routeStream => _routeCtrl.stream;

  bool get isTracking => _isTracking;
  bool get isPaused => _isPaused;
  bool get isLocked => _isLocked;
  double get distanceKm => _distanceKm;
  double get currentSpeedKmh => _currentSpeedKmh;
  List<LatLng> get route => List.unmodifiable(_route);

  Future<bool> start() async {
    final ok = await _locationService.checkPermissions();
    if (!ok) return false;

    if (!_isTracking) {
      _isTracking = true;
      _isPaused = false;
      _distanceKm = 0.0;
      _route.clear();
      laps.clear();
      _lastPosition = null;
      await _timer.start();
      _subscribeLocation();
      _isTrackingCtrl.add(true);
      _distanceCtrl.add(_distanceKm);
      _routeCtrl.add(route);
    }
    return true;
  }

  Future<void> pause() async {
    if (!_isTracking) return;
    if (_isPaused) return;
    _isPaused = true;
    _posSub?.cancel();
    await _timer.pause();
    _isTrackingCtrl.add(false);
  }

  Future<void> resume() async {
    if (!_isTracking || !_isPaused) return;
    _isPaused = false;
    await _timer.start();
    _subscribeLocation();
    _isTrackingCtrl.add(true);
  }

  void toggleLock() {
    _isLocked = !_isLocked;
    // no stream; UI can query property
  }

  void lap() {
    final elapsed = _timer.getElapsed();
    laps.add(elapsed);
  }

  Future<Ride> stop({required int bikeId, String title = 'Ride'}) async {
    // finalize
    _posSub?.cancel();
    await _timer.pause();
    final duration = _timer.getElapsed();
    final avgSpeed = duration.inSeconds > 0
        ? (_distanceKm / (duration.inSeconds / 3600))
        : 0.0;

    final ride = Ride(
      bikeId: bikeId,
      title: title,
      route: _route,
      distance: _distanceKm,
      duration: duration,
      averageSpeed: avgSpeed,
      maxSpeed: _currentSpeedKmh,
      elevation: 0.0,
      calories: (_distanceKm * 30).toInt(),
      dateTime: DateTime.now(),
    );

    await _db.insertRide(ride);
    // reset
    _isTracking = false;
    _isPaused = false;
    _isLocked = false;
    _distanceKm = 0.0;
    _route.clear();
    laps.clear();
    _lastPosition = null;
    _isTrackingCtrl.add(false);
    _distanceCtrl.add(_distanceKm);
    _routeCtrl.add(route);
    return ride;
  }

  void _subscribeLocation() {
    _locationService.startTracking();
    _posSub = _locationService.locationStream.listen((position) {
      if (!_isTracking || _isPaused) return;
      if (position.accuracy > 50) return;

      final newPoint = LatLng(position.latitude, position.longitude);

      double addedMeters = 0.0;
      if (_lastPosition != null) {
        addedMeters = _locationService.calculateDistance(
          LatLng(_lastPosition!.latitude, _lastPosition!.longitude),
          newPoint,
        );
        if (addedMeters > 1000) {
          _lastPosition = position;
          return;
        }
      }

      _route.add(newPoint);
      _distanceKm += (addedMeters / 1000.0);

      // compute speed
      final prevTs = _lastPosition?.timestamp ?? DateTime.now();
      final currTs = position.timestamp;
      final dt = currTs.difference(prevTs).inMilliseconds / 1000.0;
      final instSpeed = dt > 0 ? (addedMeters / dt) * 3.6 : 0.0;
      final deviceSpeed = (position.speed.isFinite
          ? position.speed * 3.6
          : double.nan);
      double used = instSpeed;
      if (deviceSpeed.isFinite &&
          deviceSpeed > 0 &&
          (deviceSpeed - instSpeed).abs() < 15)
        used = deviceSpeed;
      // simple smoothing
      _currentSpeedKmh = (_currentSpeedKmh * 0.6) + (used * 0.4);

      _lastPosition = position;

      _distanceCtrl.add(_distanceKm);
      _speedCtrl.add(_currentSpeedKmh);
      _routeCtrl.add(route);
    });
  }

  void dispose() {
    _posSub?.cancel();
    _isTrackingCtrl.close();
    _distanceCtrl.close();
    _speedCtrl.close();
    _routeCtrl.close();
  }
}
