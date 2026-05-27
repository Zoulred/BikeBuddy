import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../services/location_service.dart';
import '../../models/ride.dart';
import '../../viewmodels/ride_viewmodel.dart';
import 'ride_summary_view.dart';

class TrackerView extends StatefulWidget {
  const TrackerView({super.key});

  @override
  State<TrackerView> createState() => _TrackerViewState();
}

class _TrackerViewState extends State<TrackerView> {
  final LocationService _locationService = LocationService();
  GoogleMapController? _mapController;
  LatLng? _pendingCenter;
  final List<LatLng> _routePoints = [];
  final Set<Marker> _markers = {};
  bool _isTracking = false;
  double _distance = 0.0;
  DateTime? _startTime;
  Timer? _timer;
  Duration _duration = Duration.zero;

  @override
  void dispose() {
    _timer?.cancel();
    _locationService.stopTracking();
    super.dispose();
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

    setState(() {
      _isTracking = true;
      _startTime = DateTime.now();
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
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(startPoint, 16));
    }

    _locationService.startTracking();
    _locationService.locationStream.listen((position) {
      if (!_isTracking) return;
      final newPoint = LatLng(position.latitude, position.longitude);
      setState(() {
        if (_routePoints.isNotEmpty) {
          _distance +=
              _locationService.calculateDistance(_routePoints.last, newPoint) /
              1000;
        }
        _routePoints.add(newPoint);
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
      _mapController?.animateCamera(CameraUpdate.newLatLng(newPoint));
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _duration = DateTime.now().difference(_startTime!);
      });
    });
  }

  void _stopRide() async {
    setState(() {
      _isTracking = false;
    });
    _timer?.cancel();
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

  void _centerMap() async {
    final position = await _locationService.getCurrentPosition();
    if (position == null) return;
    final target = LatLng(position.latitude, position.longitude);
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 16));
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
    if (_duration.inSeconds == 0 || _distance == 0) return '0.0';
    final speed = _distance / (_duration.inSeconds / 3600);
    return speed.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(14.5995, 120.9842),
              zoom: 14,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              if (_pendingCenter != null) {
                _mapController?.animateCamera(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailCard(
                'Distance',
                '${_distance.toStringAsFixed(2)} km',
              ),
              const SizedBox(width: 16),
              _buildDetailCard('Duration', _formattedDuration),
            ],
          ),
          const SizedBox(height: 16),
          GlassBox(
            borderRadius: BorderRadius.circular(28),
            opacity: 0.12,
            blur: 20,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SPEED',
                        style: TextStyle(
                          color: AppColors.textBody,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_currentSpeed km/h',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'AVG ${(_distance / (_duration.inSeconds / 3600 + 0.0001)).toStringAsFixed(1)} km/h',
                        style: const TextStyle(
                          color: AppColors.textBody,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color.fromRGBO(37, 99, 235, 0.6),
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _currentSpeed,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
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
                      padding: const EdgeInsets.symmetric(vertical: 18),
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
              children: [
                Expanded(
                  child: _buildActionButton(
                    Icons.lock_outline,
                    'Lock',
                    AppColors.white,
                    AppColors.navyBlue,
                    () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    Icons.pause,
                    'Pause',
                    Colors.red,
                    AppColors.white,
                    () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    Icons.stop,
                    'End',
                    AppColors.electricBlue,
                    AppColors.white,
                    _stopRide,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    Icons.flag,
                    'Lap',
                    AppColors.white,
                    AppColors.navyBlue,
                    () {},
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(String label, String value) {
    return Expanded(
      child: GlassBox(
        borderRadius: BorderRadius.circular(24),
        opacity: 0.12,
        blur: 20,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.textBody, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color backgroundColor,
    Color textColor,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
