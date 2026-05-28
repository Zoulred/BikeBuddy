import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../services/LocationInfo.dart';
import '../../models/ride.dart';
import '../../viewmodels/ride_viewmodel.dart';
import 'ride_summary_view.dart';
import '../../widgets/offline_map_preview.dart';

class TrackerView extends StatefulWidget {
  const TrackerView({super.key});

  @override
  State<TrackerView> createState() => _TrackerViewState();
}

class _TrackerViewState extends State<TrackerView> {
  final LocationService _locationService = LocationService();
  GoogleMapController? _mapController;
  StreamSubscription<ConnectivityResult>? _connectivitySub;
  bool _isOffline = false;
  LatLng? _pendingCenter;
  final List<LatLng> _routePoints = [];
  final Set<Marker> _markers = {};
  bool _isTracking = false;
  bool _isPaused = false;
  double _distance = 0.0;
  double _currentSpeedKmh = 0.0;
  Position? _lastPosition;
  final double _minMoveDistanceMeters = 5.0;
  DateTime? _runningSince;
  Duration _accumulatedDuration = Duration.zero;
  Timer? _timer;
  StreamSubscription<Position>? _locationSubscription;
  Duration _duration = Duration.zero;
  double? _lastAccuracyMeters;

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _timer?.cancel();
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _locationService.stopTracking();
    _mapController = null;
    super.dispose();
  }

  Future<void> _safeAnimate(CameraUpdate update) async {
    if (_mapController == null) return;
    try {
      await _mapController!.animateCamera(update);
    } catch (_) {
      // controller may be disposed; ignore
    }
  }

  void _subscribeToLocation() {
    _locationSubscription?.cancel();
    _locationSubscription = _locationService.locationStream.listen(
      _onPosition,
      onError: (_) {},
    );
  }

  void _onPosition(Position position) {
    if (!_isTracking || _isPaused) return;
    if (!mounted) return;

    final newPoint = LatLng(position.latitude, position.longitude);
    _lastAccuracyMeters = position.accuracy;

    double segmentMeters = 0.0;
    if (_routePoints.isNotEmpty) {
      segmentMeters = _locationService.calculateDistance(
        _routePoints.last,
        newPoint,
      );
    }

    final accuracy = (position.accuracy.isFinite && position.accuracy > 0)
        ? position.accuracy
        : _minMoveDistanceMeters;
    final threshold = max(_minMoveDistanceMeters, accuracy);

    double timeDeltaSeconds = 1.0;
    if (_lastPosition?.timestamp != null) {
      try {
        timeDeltaSeconds =
            position.timestamp
                .difference(_lastPosition!.timestamp)
                .inMilliseconds /
            1000.0;
        if (timeDeltaSeconds <= 0) timeDeltaSeconds = 1.0;
      } catch (_) {
        timeDeltaSeconds = 1.0;
      }
    }

    double computedSpeedKmh = 0.0;
    if (segmentMeters > 0 && timeDeltaSeconds > 0) {
      computedSpeedKmh = (segmentMeters / timeDeltaSeconds) * 3.6;
    }

    final hasDeviceSpeed = position.speed.isFinite && position.speed >= 0;
    if (hasDeviceSpeed) {
      _currentSpeedKmh = position.speed * 3.6;
    } else {
      _currentSpeedKmh = computedSpeedKmh;
    }

    setState(() {
      if (_routePoints.isEmpty) {
        // always add the first fix
        _routePoints.add(newPoint);
      } else if (segmentMeters >= threshold) {
        _distance += segmentMeters / 1000.0;
        _routePoints.add(newPoint);
      }

      _markers.removeWhere(
        (marker) => marker.markerId.value == 'current_location',
      );
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: newPoint,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    });

    _lastPosition = position;
    if (segmentMeters >= 1) {
      _safeAnimate(CameraUpdate.newLatLng(newPoint));
    }
  }

  @override
  void initState() {
    super.initState();
    Connectivity().checkConnectivity().then((res) {
      _isOffline = res == ConnectivityResult.none;
      setState(() {});
    });
    _connectivitySub = Connectivity().onConnectivityChanged.listen((res) {
      final offline = res == ConnectivityResult.none;
      if (offline != _isOffline) {
        setState(() {
          _isOffline = offline;
        });
      }
    });
    _setInitialLocation();
  }

  Future<void> _setInitialLocation() async {
    Position? pos = await _locationService.getCurrentPosition();
    if (!mounted) return;
    bool startedTrackingForPreview = false;
    if (pos == null || (pos.accuracy > 50)) {
      try {
        startedTrackingForPreview = true;
        _locationService.startTracking();
        final p = await _locationService.locationStream
            .firstWhere((p) => p.accuracy <= 50)
            .timeout(const Duration(seconds: 5));
        pos = p;
      } catch (_) {
        // ignore timeout or no accurate fix
      } finally {
        if (startedTrackingForPreview) _locationService.stopTracking();
      }
    }

    if (pos == null) return;
    _pendingCenter = LatLng(pos.latitude, pos.longitude);
    _lastAccuracyMeters = pos.accuracy;
    if (_mapController != null) {
      _safeAnimate(CameraUpdate.newLatLngZoom(_pendingCenter!, 16));
      _pendingCenter = null;
    } else {
      setState(() {});
    }
  }

  void _startRide() async {
    bool hasPermission = await _locationService.checkPermissions();
    if (!hasPermission) {
      _showPermissionDialog();
      return;
    }

    final currentPos = await _locationService.getCurrentPosition();
    final startPoint = currentPos != null
        ? LatLng(currentPos.latitude, currentPos.longitude)
        : null;

    if (!mounted) return;
    setState(() {
      _isTracking = true;
      _isPaused = false;
      _runningSince = DateTime.now();
      _accumulatedDuration = Duration.zero;
      _routePoints.clear();
      _markers.clear();
      _distance = 0.0;
      _duration = Duration.zero;
      if (startPoint != null) {
        _routePoints.add(startPoint);
        _markers.add(
          Marker(
            markerId: const MarkerId('current_location'),
            position: startPoint,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          ),
        );
      }
    });

    if (startPoint != null) {
      _pendingCenter = startPoint;
      _safeAnimate(CameraUpdate.newLatLngZoom(startPoint, 16));
    }

    _locationService.startTracking();
    if (!mounted) {
      _locationService.stopTracking();
      return;
    }
    _lastPosition = currentPos;
    _subscribeToLocation();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        final running = _runningSince != null
            ? DateTime.now().difference(_runningSince!)
            : Duration.zero;
        _duration = _accumulatedDuration + running;
      });
    });
  }

  void _stopRide() async {
    if (mounted) {
      setState(() {
        _isTracking = false;
      });
    }
    _timer?.cancel();
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _locationService.stopTracking();
    final avgSpeed = _distance / (_duration.inSeconds / 3600 + 0.0001);
    final ride = Ride(
      bikeId: 1,
      title: 'Morning Ride',
      route: _routePoints,
      distance: _distance,
      duration: _duration,
      averageSpeed: avgSpeed,
      maxSpeed: avgSpeed * 1.2,
      elevation: 0.0,
      calories: (_distance * 30).toInt(),
      dateTime: DateTime.now(),
    );

    await context.read<RideViewModel>().addRide(ride);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RideSummaryView(ride: ride)),
    );
  }

  void _togglePause() async {
    if (!_isTracking) return;
    if (!_isPaused) {
      _isPaused = true;
      if (_runningSince != null) {
        _accumulatedDuration += DateTime.now().difference(_runningSince!);
        _runningSince = null;
      }
      _timer?.cancel();
      _locationSubscription?.cancel();
      _locationSubscription = null;
      _locationService.stopTracking();
      _lastPosition = null;
      setState(() {});
    } else {
      _isPaused = false;
      _runningSince = DateTime.now();
      _locationService.startTracking();
      _lastPosition = null;
      _subscribeToLocation();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() {
          final running = _runningSince != null
              ? DateTime.now().difference(_runningSince!)
              : Duration.zero;
          _duration = _accumulatedDuration + running;
        });
      });
      setState(() {});
    }
  }

  void _centerMap() async {
    final position = await _locationService.getCurrentPosition();
    if (position == null) return;
    final target = LatLng(position.latitude, position.longitude);
    _safeAnimate(CameraUpdate.newLatLngZoom(target, 16));
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'The app needs location permission to track your ride and show your current position on the map.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String get _formattedDuration {
    final hours = _duration.inHours.toString().padLeft(2, '0');
    final minutes = _duration.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = _duration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String get _currentSpeed {
    final speed = _currentSpeedKmh > 0
        ? _currentSpeedKmh
        : (_duration.inSeconds == 0 || _distance == 0)
        ? 0.0
        : _distance / (_duration.inSeconds / 3600);
    return speed.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _isOffline
              ? OfflineMapPreview(
                  center:
                      _pendingCenter ??
                      (_routePoints.isNotEmpty ? _routePoints.last : null),
                  accuracyMeters: _lastAccuracyMeters,
                  route: _routePoints,
                )
              : GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(14.5995, 120.9842),
                    zoom: 14,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    if (_pendingCenter != null) {
                      _safeAnimate(
                        CameraUpdate.newLatLngZoom(_pendingCenter!, 16),
                      );
                      _pendingCenter = null;
                    }
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  markers: _markers,
                  polylines: {
                    Polyline(
                      polylineId: const PolylineId('ride_route'),
                      points: _routePoints,
                      color: AppColors.greenAccent,
                      width: 6,
                    ),
                  },
                ),
          if (_isOffline)
            Positioned(
              top: 110,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Offline — map tiles unavailable. Showing last known location.',
                  style: TextStyle(color: Colors.black87),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          Positioned(
            top: 40,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GlassBox(
                  borderRadius: BorderRadius.circular(28),
                  opacity: 0.18,
                  blur: 20,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isTracking ? Colors.green : Colors.yellow,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _isTracking ? 'Riding' : 'Ready',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _formattedDuration,
                          style: const TextStyle(
                            color: AppColors.textBody,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GlassBox(
                  borderRadius: BorderRadius.circular(20),
                  opacity: 0.18,
                  blur: 20,
                  child: IconButton(
                    onPressed: _centerMap,
                    icon: const Icon(Icons.gps_fixed, color: AppColors.white),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 130,
            right: 16,
            child: Column(
              children: [
                _buildSidebarButton(Icons.settings),
                const SizedBox(height: 12),
                _buildSidebarButton(Icons.layers),
                const SizedBox(height: 12),
                _buildSidebarButton(Icons.volume_up_rounded),
              ],
            ),
          ),
          Positioned(left: 0, right: 0, bottom: 0, child: _buildBottomPanel()),
        ],
      ),
    );
  }

  Widget _buildSidebarButton(IconData icon) {
    return GlassBox(
      borderRadius: BorderRadius.circular(18),
      opacity: 0.18,
      blur: 20,
      child: IconButton(
        onPressed: () {},
        icon: Icon(icon, color: AppColors.white),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        var diameter = maxWidth * 0.30;
        if (diameter < 100) diameter = 100;
        if (diameter > 180) diameter = 180;
        final leftRightFontSize = maxWidth < 360 ? 14.0 : 16.0;
        final mainNumberSize = maxWidth < 360 ? 32.0 : 44.0;

        return Container(
          decoration: BoxDecoration(
            gradient: AppColors.darkGradient,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: const Color.fromRGBO(0, 0, 0, 0.3),
                blurRadius: 20,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DISTANCE',
                          style: TextStyle(
                            color: AppColors.textBody,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${_distance.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: leftRightFontSize + 4,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('km', style: TextStyle(color: AppColors.textBody)),
                        const SizedBox(height: 12),
                        Text(
                          'AVG SPEED',
                          style: TextStyle(
                            color: AppColors.textBody,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${(_distance / (_duration.inSeconds / 3600 + 0.0001)).toStringAsFixed(1)} km/h',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: leftRightFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: GlassBox(
                        borderRadius: BorderRadius.circular(diameter),
                        opacity: 0.12,
                        blur: 20,
                        child: Container(
                          width: diameter,
                          height: diameter,
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'SPEED',
                                style: TextStyle(
                                  color: AppColors.textBody,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _currentSpeed,
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontSize: mainNumberSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'AVG ${(_distance / (_duration.inSeconds / 3600 + 0.0001)).toStringAsFixed(1)} km/h',
                                  style: TextStyle(
                                    color: AppColors.textBody,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'DURATION',
                          style: TextStyle(
                            color: AppColors.textBody,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _formattedDuration,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'hh:mm:ss',
                          style: TextStyle(color: AppColors.textBody),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'MAX SPEED',
                          style: TextStyle(
                            color: AppColors.textBody,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '${((_distance / (_duration.inSeconds / 3600 + 0.0001)) * 1.2).toStringAsFixed(1)} km/h',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GlassBox(
                borderRadius: BorderRadius.circular(20),
                opacity: 0.06,
                blur: 10,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ELEVATION',
                            style: TextStyle(color: AppColors.textBody),
                          ),
                          Text(
                            '${120.toString()} m',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(height: 36, color: Colors.transparent),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!_isTracking)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _startRide,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Start Ride'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.greenAccent,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 20,
                          ),
                          minimumSize: const Size.fromHeight(56),
                          tapTargetSize: MaterialTapTargetSize.padded,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          GlassBox(
                            borderRadius: BorderRadius.circular(16),
                            opacity: 0.12,
                            blur: 10,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                Icons.lock_outline,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Lock',
                            style: TextStyle(color: AppColors.textBody),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        children: [
                          ElevatedButton(
                            onPressed: _togglePause,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(18),
                              elevation: 4,
                            ),
                            child: Icon(
                              _isPaused ? Icons.play_arrow : Icons.pause,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isPaused ? 'Resume' : 'Pause',
                            style: TextStyle(color: AppColors.textBody),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        children: [
                          ElevatedButton(
                            onPressed: _stopRide,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.electricBlue,
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(18),
                              elevation: 4,
                            ),
                            child: const Icon(
                              Icons.stop,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'End',
                            style: TextStyle(color: AppColors.textBody),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        children: [
                          GlassBox(
                            borderRadius: BorderRadius.circular(40),
                            opacity: 0.12,
                            blur: 10,
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Icon(Icons.flag, color: AppColors.white),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Lap',
                            style: TextStyle(color: AppColors.textBody),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
