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
                else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredRides.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _buildRideCard(context, filteredRides[index]);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildPagination(
                    filteredRides.length,
                    viewModel.rides.length,
                  ),
                ],
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

    final entries = [
      {
        'label': 'Total Rides',
        'value': '${tabRides.length}',
        'color': AppColors.greenAccent,
      },
      {
        'label': 'Distance',
        'value': '${_formatDistanceNumber(totalDistance)} km',
        'color': AppColors.electricBlue,
      },
      {
        'label': 'Duration',
        'value': _formatDuration(totalDuration),
        'color': Colors.amber,
      },
      {
        'label': 'Calories',
        'value': '$totalCalories',
        'color': Colors.redAccent,
      },
    ];

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
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: entries.map((e) {
                    return SizedBox(
                      width: itemWidth,
                      child: _buildSummaryCard(
                        e['label'] as String,
                        e['value'] as String,
                        e['color'] as Color,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0),
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
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 420;
              if (narrow) {
                // Stack vertically on narrow screens
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRideMapPreview(ride),
                    const SizedBox(height: 12),
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
                    Row(
                      children: [
                        Flexible(
                          fit: FlexFit.loose,
                          child: _buildStatCompact(
                            Icons.place,
                            _formatDistanceNumber(ride.distance),
                            'km',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          fit: FlexFit.loose,
                          child: _buildStatCompact(
                            Icons.access_time,
                            _formatDuration(ride.duration),
                            '',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          fit: FlexFit.loose,
                          child: _buildStatCompact(
                            Icons.speed,
                            _getAverageSpeed(ride),
                            'km/h',
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }

              // Default wide layout
              return Row(
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
                          style: TextStyle(
                            color: AppColors.textBody,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Flexible(
                              fit: FlexFit.loose,
                              child: _buildStatColumnSimple(
                                Icons.place,
                                _formatDistanceNumber(ride.distance),
                                'km',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              fit: FlexFit.loose,
                              child: _buildStatColumnSimple(
                                Icons.access_time,
                                _formatDuration(ride.duration),
                                '',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              fit: FlexFit.loose,
                              child: _buildStatColumnSimple(
                                Icons.speed,
                                _getAverageSpeed(ride),
                                'km/h',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // placeholder weather icon
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.navyBlue.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.wb_sunny,
                          color: Colors.orange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.textBody,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumnSimple(IconData icon, String value, String unit) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.electricBlue),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(unit, style: TextStyle(color: AppColors.textBody, fontSize: 12)),
      ],
    );
  }

  Widget _buildStatCompact(IconData icon, String value, String unit) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.electricBlue),
        const SizedBox(width: 6),
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (unit.isNotEmpty) const SizedBox(width: 6),
        if (unit.isNotEmpty)
          Text(unit, style: TextStyle(color: AppColors.textBody, fontSize: 12)),
      ],
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

  // Compact formatting helpers to avoid overflow with very large numbers
  String _formatDistanceNumber(double km) {
    if (km >= 1000) {
      final rounded =
          (km / 1000 * 10).round() / 10; // one decimal for thousands
      return '${_withCommas(rounded.toString())}k';
    }
    return _withCommas(km.toStringAsFixed(km >= 10 ? 1 : 2));
  }

  String _withCommas(String s) {
    if (s.contains('.')) {
      final parts = s.split('.');
      final intPart = parts[0];
      final frac = parts[1];
      final formatted = intPart.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (m) => ',',
      );
      return '$formatted.$frac';
    }
    return s.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',');
  }

  Widget _buildPagination(int showing, int total) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Showing 1 - $showing of $total rides',
            style: TextStyle(color: AppColors.textBody),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.navyBlue.withOpacity(0.6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: null,
                icon: const Icon(Icons.chevron_left, color: AppColors.textBody),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: const Text(
                  '1',
                  style: TextStyle(color: AppColors.white),
                ),
              ),
              IconButton(
                onPressed: null,
                icon: const Icon(
                  Icons.chevron_right,
                  color: AppColors.textBody,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
