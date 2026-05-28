import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/ride.dart';
import '../../viewmodels/ride_viewmodel.dart';
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xff020817),
      body: SafeArea(
        child: Consumer<RideViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final filteredRides = _applyFilters(viewModel.rides);

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    size.width * .04,
                    14,
                    size.width * .04,
                    30,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildTopBar(size),
                      const SizedBox(height: 26),

                      _buildTabBar(size),
                      const SizedBox(height: 24),

                      _buildSummaryCard(viewModel.rides, size),
                      const SizedBox(height: 20),

                      _buildSearchSort(size),
                      const SizedBox(height: 18),

                      if (filteredRides.isEmpty)
                        _buildEmptyState()
                      else
                        ...filteredRides.map(
                          (ride) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildRideCard(ride, size),
                          ),
                        ),

                      const SizedBox(height: 8),

                      _buildPagination(
                        filteredRides.length,
                        viewModel.rides.length,
                        size,
                      ),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // =========================================================
  // TOP BAR
  // =========================================================

  Widget _buildTopBar(Size size) {
    return Row(
      children: [
        _topIcon(Icons.menu),

        SizedBox(width: size.width * .04),

        Expanded(
          child: Text(
            'Ride History',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: size.width < 400 ? 24 : 30,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),

        _topIcon(Icons.filter_alt_outlined),

        const SizedBox(width: 12),

        _topIcon(Icons.calendar_today_outlined),
      ],
    );
  }

  Widget _topIcon(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(.05)),
        color: Colors.white.withOpacity(.03),
      ),
      child: Icon(icon, color: Colors.white, size: 22),
    );
  }

  // =========================================================
  // TAB BAR
  // =========================================================

  Widget _buildTabBar(Size size) {
    final tabs = ['All Rides', 'This Week', 'This Month', 'This Year'];

    return SizedBox(
      height: 44,
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = _selectedTab == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = index;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected
                          ? AppColors.electricBlue
                          : Colors.white.withOpacity(.08),
                      width: selected ? 3 : 1,
                    ),
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    tabs[index],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected
                          ? AppColors.electricBlue
                          : AppColors.textBody,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: size.width < 400 ? 12 : 15,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // =========================================================
  // SUMMARY CARD
  // =========================================================

  Widget _buildSummaryCard(List<Ride> rides, Size size) {
    final tabRides = _applyFilters(rides);

    final totalDistance = tabRides.fold<double>(
      0,
      (sum, item) => sum + item.distance,
    );

    final totalCalories = tabRides.fold<int>(
      0,
      (sum, item) => sum + item.calories,
    );

    final totalDuration = tabRides.fold<Duration>(
      Duration.zero,
      (sum, item) => sum + item.duration,
    );

    final isMobile = size.width < 700;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _glassDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your Cycling Summary',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withOpacity(.05)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Flexible(
                        child: Text(
                          'This Year',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = constraints.maxWidth < 700
                  ? (constraints.maxWidth - 12) / 2
                  : (constraints.maxWidth - 24) / 4;

              return Wrap(
                spacing: 8,
                runSpacing: 12,
                children: [
                  _summaryItem(
                    width: cardWidth,
                    icon: Icons.route,
                    color: Colors.greenAccent,
                    value: '${tabRides.length}',
                    label: 'Total Rides',
                  ),

                  _summaryItem(
                    width: cardWidth,
                    icon: Icons.timeline,
                    color: AppColors.electricBlue,
                    value: _formatDistance(totalDistance),
                    label: 'Total Distance',
                  ),

                  _summaryItem(
                    width: cardWidth,
                    icon: Icons.access_time_filled_rounded,
                    color: Colors.amber,
                    value: _formatDuration(totalDuration),
                    label: 'Total Duration',
                  ),

                  _summaryItem(
                    width: cardWidth,
                    icon: Icons.local_fire_department,
                    color: Colors.redAccent,
                    value: _withCommas('$totalCalories'),
                    label: 'Total Calories',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _summaryItem({
    required double width,
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return SizedBox(
      width: width,
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),

          const SizedBox(height: 12),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textBody.withOpacity(.85),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SEARCH
  // =========================================================

  Widget _buildSearchSort(Size size) {
    final mobile = size.width < 500;

    return mobile
        ? Column(
            children: [
              Container(
                height: 58,
                decoration: _glassDecoration(),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.textBody.withOpacity(.7),
                    ),
                    hintText: 'Search rides...',
                    hintStyle: TextStyle(
                      color: AppColors.textBody.withOpacity(.7),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                height: 56,
                decoration: _glassDecoration(),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Sort: Newest',
                      style: TextStyle(
                        color: AppColors.electricBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.electricBlue,
                    ),
                  ],
                ),
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: Container(
                  height: 58,
                  decoration: _glassDecoration(),
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.textBody.withOpacity(.7),
                      ),
                      hintText: 'Search rides...',
                      hintStyle: TextStyle(
                        color: AppColors.textBody.withOpacity(.7),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              Container(
                height: 58,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: _glassDecoration(),
                child: Row(
                  children: const [
                    Text(
                      'Sort: Newest',
                      style: TextStyle(
                        color: AppColors.electricBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.electricBlue,
                    ),
                  ],
                ),
              ),
            ],
          );
  }

  // =========================================================
  // RIDE CARD
  // =========================================================

  Widget _buildRideCard(Ride ride, Size size) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RideSummaryView(ride: ride)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: _glassDecoration(),
        child: size.width < 650
            ? _buildMobileRideCard(ride, size)
            : _buildDesktopRideCard(ride),
      ),
    );
  }

  Widget _buildMobileRideCard(Ride ride, Size size) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRideMapPreview(ride, size),

            const SizedBox(width: 12),

            Expanded(
              child: SizedBox(
                height: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size.width < 400 ? 18 : 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      '${ride.dateTime.day}/${ride.dateTime.month}/${ride.dateTime.year} • ${_formatTime(ride.dateTime)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textBody.withOpacity(.85),
                        fontSize: 13,
                      ),
                    ),

                    const Spacer(),

                    Row(
                      children: const [
                        Icon(
                          Icons.wb_sunny_rounded,
                          color: Colors.amber,
                          size: 18,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '26°C',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 6),

            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),

        const SizedBox(height: 18),

        Row(
          children: [
            Expanded(
              child: _rideStat(
                icon: Icons.place,
                value: ride.distance.toStringAsFixed(2),
                unit: 'km',
                color: Colors.greenAccent,
              ),
            ),

            _divider(),

            Expanded(
              child: _rideStat(
                icon: Icons.access_time_filled_rounded,
                value: _formatDuration(ride.duration),
                unit: 'time',
                color: AppColors.electricBlue,
              ),
            ),

            _divider(),

            Expanded(
              child: _rideStat(
                icon: Icons.speed,
                value: _getAverageSpeed(ride),
                unit: 'km/h',
                color: Colors.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopRideCard(Ride ride) {
    return Row(
      children: [
        _buildRideMapPreview(ride, const Size(1000, 1000)),

        const SizedBox(width: 18),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ride.title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                '${ride.dateTime.day}/${ride.dateTime.month}/${ride.dateTime.year} • ${_formatTime(ride.dateTime)}',
                style: TextStyle(
                  color: AppColors.textBody.withOpacity(.85),
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _rideStat(
                      icon: Icons.place,
                      value: ride.distance.toStringAsFixed(2),
                      unit: 'km',
                      color: Colors.greenAccent,
                    ),
                  ),

                  _divider(),

                  Expanded(
                    child: _rideStat(
                      icon: Icons.access_time_filled_rounded,
                      value: _formatDuration(ride.duration),
                      unit: 'time',
                      color: AppColors.electricBlue,
                    ),
                  ),

                  _divider(),

                  Expanded(
                    child: _rideStat(
                      icon: Icons.speed,
                      value: _getAverageSpeed(ride),
                      unit: 'km/h',
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 20),

        Column(
          children: [
            Row(
              children: const [
                Icon(Icons.wb_sunny_rounded, color: Colors.amber),
                SizedBox(width: 6),
                Text('26°C', style: TextStyle(color: Colors.white70)),
              ],
            ),

            const SizedBox(height: 24),

            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ],
    );
  }

  Widget _rideStat({
    required IconData icon,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),

            const SizedBox(width: 6),

            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        Padding(
          padding: const EdgeInsets.only(left: 24),
          child: Text(
            unit,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textBody.withOpacity(.8),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: Colors.white10,
    );
  }

  // =========================================================
  // MAP
  // =========================================================

  Widget _buildRideMapPreview(Ride ride, Size size) {
    final mapWidth = size.width < 400 ? 110.0 : 140.0;

    if (ride.route.isEmpty) {
      return Container(
        width: mapWidth,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withOpacity(.04),
        ),
        child: const Icon(Icons.map, color: Colors.white54),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: mapWidth,
        height: 120,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: ride.route.first,
            zoom: 13,
          ),
          zoomControlsEnabled: false,
          scrollGesturesEnabled: false,
          rotateGesturesEnabled: false,
          tiltGesturesEnabled: false,
          zoomGesturesEnabled: false,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
          markers: {
            Marker(
              markerId: const MarkerId('start'),
              position: ride.route.first,
            ),
            Marker(markerId: const MarkerId('end'), position: ride.route.last),
          },
          polylines: {
            Polyline(
              polylineId: const PolylineId('route'),
              points: ride.route,
              color: Colors.greenAccent,
              width: 5,
            ),
          },
        ),
      ),
    );
  }

  // =========================================================
  // PAGINATION
  // =========================================================

  Widget _buildPagination(int showing, int total, Size size) {
    final mobile = size.width < 600;

    return mobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Showing 1 - $showing of $total rides',
                style: TextStyle(
                  color: AppColors.textBody.withOpacity(.8),
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 16),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _pageButton(Icons.chevron_left),
                    const SizedBox(width: 8),
                    _numberButton('1', true),
                    _numberButton('2', false),
                    _numberButton('3', false),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '...',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                    _numberButton('26', false),
                    const SizedBox(width: 8),
                    _pageButton(Icons.chevron_right),
                  ],
                ),
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: Text(
                  'Showing 1 - $showing of $total rides',
                  style: TextStyle(
                    color: AppColors.textBody.withOpacity(.8),
                    fontSize: 14,
                  ),
                ),
              ),

              Row(
                children: [
                  _pageButton(Icons.chevron_left),

                  const SizedBox(width: 8),

                  _numberButton('1', true),
                  _numberButton('2', false),
                  _numberButton('3', false),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('...', style: TextStyle(color: Colors.white54)),
                  ),

                  _numberButton('26', false),

                  const SizedBox(width: 8),

                  _pageButton(Icons.chevron_right),
                ],
              ),
            ],
          );
  }

  Widget _pageButton(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(.04),
      ),
      child: Icon(icon, color: Colors.white70),
    );
  }

  Widget _numberButton(String text, bool active) {
    return Container(
      width: 42,
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.electricBlue : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          color: active ? Colors.white : Colors.white70,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // =========================================================
  // EMPTY
  // =========================================================

  Widget _buildEmptyState() {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 80, color: Colors.white.withOpacity(.15)),

            const SizedBox(height: 18),

            const Text(
              'No rides found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Your ride history will appear here',
              style: TextStyle(color: AppColors.textBody.withOpacity(.8)),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // DECORATION
  // =========================================================

  BoxDecoration _glassDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xff0B1220), Color(0xff101A2F)],
      ),
      border: Border.all(color: Colors.white.withOpacity(.05)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.25),
          blurRadius: 24,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  // =========================================================
  // FILTERS
  // =========================================================

  List<Ride> _applyFilters(List<Ride> rides) {
    final now = DateTime.now();

    final filteredBySearch = rides.where((ride) {
      final query = _searchQuery.toLowerCase();

      return ride.title.toLowerCase().contains(query) ||
          ride.distance.toString().contains(query);
    }).toList();

    return filteredBySearch.where((ride) {
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

  // =========================================================
  // HELPERS
  // =========================================================

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
    if (ride.duration.inSeconds == 0) {
      return '0.0';
    }

    final speed = ride.distance / (ride.duration.inSeconds / 3600);

    return speed.toStringAsFixed(1);
  }

  String _formatDistance(double value) {
    return _withCommas(value.toStringAsFixed(1));
  }

  String _withCommas(String value) {
    return value.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }
}
