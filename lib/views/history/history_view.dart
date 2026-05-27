import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../viewmodels/ride_viewmodel.dart';
import '../../models/ride.dart';
import '../tracker/ride_summary_view.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  String _searchQuery = '';
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ride History')),
      body: Consumer<RideViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredRides = _applyFilters(viewModel.rides);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(viewModel.rides),
                const SizedBox(height: 20),
                _buildTabBar(),
                const SizedBox(height: 20),
                _buildSearchAndSortRow(),
                const SizedBox(height: 20),
                if (filteredRides.isEmpty)
                  _buildEmptyState()
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredRides.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _buildRideCard(context, filteredRides[index]);
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Ride> _applyFilters(List<Ride> rides) {
    final now = DateTime.now();
    final lowerQuery = _searchQuery.toLowerCase();
    final filteredByQuery = rides.where((ride) {
      return ride.title.toLowerCase().contains(lowerQuery) ||
          ride.dateTime.toIso8601String().contains(lowerQuery) ||
          ride.distance.toStringAsFixed(1).contains(lowerQuery);
    }).toList();

    return filteredByQuery.where((ride) {
      switch (_selectedTab) {
        case 1:
          return ride.dateTime.isAfter(now.subtract(const Duration(days: 7)));
        case 2:
          return ride.dateTime.isAfter(now.subtract(const Duration(days: 30)));
        case 3:
          return ride.dateTime.isAfter(now.subtract(const Duration(days: 365)));
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildHeader(List<Ride> rides) {
    final tabRides = _applyFilters(rides);
    final totalDistance = tabRides.fold<double>(
      0.0,
      (sum, ride) => sum + ride.distance,
    );
    final totalDuration = tabRides.fold<Duration>(
      Duration.zero,
      (sum, ride) => sum + ride.duration,
    );
    final totalCalories = tabRides.fold<int>(
      0,
      (sum, ride) => sum + ride.calories,
    );

    return GlassBox(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Cycling Summary',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryCard(
                  'Total Rides',
                  '${tabRides.length}',
                  AppColors.greenAccent,
                ),
                _buildSummaryCard(
                  'Distance',
                  '${totalDistance.toStringAsFixed(1)} km',
                  AppColors.electricBlue,
                ),
                _buildSummaryCard(
                  'Duration',
                  _formatDuration(totalDuration),
                  Colors.amber,
                ),
                _buildSummaryCard(
                  'Calories',
                  '$totalCalories',
                  Colors.redAccent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.navyBlue.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: AppColors.textBody, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final tabs = ['All Rides', 'This Week', 'This Month', 'This Year'];
    return GlassBox(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(tabs.length, (index) {
            final selected = index == _selectedTab;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = index),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.electricBlue
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      tabs[index],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: selected ? AppColors.white : AppColors.textBody,
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSearchAndSortRow() {
    return Row(
      children: [
        Expanded(
          child: GlassBox(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                style: const TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  hintText: 'Search rides...',
                  hintStyle: TextStyle(color: AppColors.textBody),
                  border: InputBorder.none,
                  icon: const Icon(Icons.search, color: AppColors.textBody),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        GlassBox(
          child: InkWell(
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: const [
                  Text(
                    'Sort: Newest',
                    style: TextStyle(color: AppColors.white),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.keyboard_arrow_down, color: AppColors.white),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 80,
            color: AppColors.textBody.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          const Text(
            'No rides recorded',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your cycling adventures will appear here',
            style: TextStyle(color: AppColors.textBody),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(BuildContext context, Ride ride) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RideSummaryView(ride: ride)),
      ),
      child: GlassBox(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _buildRideMapPreview(ride),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${ride.dateTime.day}/${ride.dateTime.month}/${ride.dateTime.year} · ${_formatTime(ride.dateTime)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.textBody, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildStatChip(
                          Icons.place,
                          '${ride.distance.toStringAsFixed(2)} km',
                        ),
                        _buildStatChip(
                          Icons.access_time,
                          ride.duration.toString().split('.').first,
                        ),
                        _buildStatChip(
                          Icons.speed,
                          '${_getAverageSpeed(ride)} km/h',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRideMapPreview(Ride ride) {
    if (ride.route.isEmpty) {
      return Container(
        width: 120,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.navyBlue.withOpacity(0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(child: Icon(Icons.map, color: AppColors.textBody)),
      );
    }

    final initialPosition = _routeCenter(ride);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 120,
        height: 100,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialPosition,
            zoom: 13,
          ),
          onMapCreated: (controller) {
            final bounds = _routeBounds(ride);
            if (bounds != null) {
              controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 8));
            }
          },
          markers: _routeMarkers(ride),
          polylines: _routePolylines(ride),
          mapType: MapType.normal,
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
          scrollGesturesEnabled: false,
          zoomGesturesEnabled: false,
          tiltGesturesEnabled: false,
          rotateGesturesEnabled: false,
        ),
      ),
    );
  }

  LatLng _routeCenter(Ride ride) {
    final lats = ride.route.map((p) => p.latitude).toList();
    final lngs = ride.route.map((p) => p.longitude).toList();
    final centerLat = (lats.reduce((a, b) => a + b) / lats.length);
    final centerLng = (lngs.reduce((a, b) => a + b) / lngs.length);
    return LatLng(centerLat, centerLng);
  }

  LatLngBounds? _routeBounds(Ride ride) {
    if (ride.route.length < 2) return null;
    final south = ride.route
        .map((p) => p.latitude)
        .reduce((a, b) => a < b ? a : b);
    final north = ride.route
        .map((p) => p.latitude)
        .reduce((a, b) => a > b ? a : b);
    final west = ride.route
        .map((p) => p.longitude)
        .reduce((a, b) => a < b ? a : b);
    final east = ride.route
        .map((p) => p.longitude)
        .reduce((a, b) => a > b ? a : b);
    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }

  Set<Marker> _routeMarkers(Ride ride) {
    return {
      Marker(
        markerId: const MarkerId('start_marker'),
        position: ride.route.first,
      ),
      Marker(markerId: const MarkerId('end_marker'), position: ride.route.last),
    };
  }

  Set<Polyline> _routePolylines(Ride ride) {
    return {
      Polyline(
        polylineId: const PolylineId('route_preview'),
        points: ride.route,
        color: AppColors.greenAccent,
        width: 3,
      ),
    };
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.navyBlue.withOpacity(0.7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppColors.electricBlue),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: AppColors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return [
      if (hours > 0) hours.toString().padLeft(2, '0'),
      minutes.toString().padLeft(2, '0'),
      seconds.toString().padLeft(2, '0'),
    ].join(':');
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getAverageSpeed(Ride ride) {
    if (ride.duration.inSeconds == 0) return '0.0';
    final speed = ride.distance / (ride.duration.inSeconds / 3600);
    return speed.toStringAsFixed(1);
  }
}
