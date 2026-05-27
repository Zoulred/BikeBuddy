import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../models/ride.dart';
import '../../viewmodels/ride_viewmodel.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  int _selectedTab = 0;

  static const _tabs = ['All Rides', '7 Days', '4 Weeks', '6 Months'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      body: SafeArea(
        child: Consumer<RideViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.electricBlue),
              );
            }

            final rides = viewModel.rides;
            if (rides.isEmpty) {
              return _buildEmptyProfileState();
            }

            final filteredRides = _filterRides(rides);
            final totals = _calculateTotals(filteredRides);
            final chartData = _chartPoints(filteredRides);
            final insights = _calculateInsights(filteredRides);
            final bests = _calculatePersonalBests(filteredRides);

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(context),
                  const SizedBox(height: 24),
                  _buildPeriodTabs(),
                  const SizedBox(height: 24),
                  _buildSummaryGrid(totals),
                  const SizedBox(height: 24),
                  _buildLineChartCard(chartData),
                  const SizedBox(height: 24),
                  _buildInsightsRow(insights),
                  const SizedBox(height: 24),
                  _buildSpeedAnalysisCard(filteredRides),
                  const SizedBox(height: 24),
                  _buildPersonalBestsCard(bests),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyProfileState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'No rides yet',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Start tracking your first ride to see analytics, totals, and personal bests here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textBody,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Ride> _filterRides(List<Ride> rides) {
    final now = DateTime.now();
    switch (_selectedTab) {
      case 1:
        return rides
            .where(
              (ride) =>
                  ride.dateTime.isAfter(now.subtract(const Duration(days: 7))),
            )
            .toList();
      case 2:
        return rides
            .where(
              (ride) =>
                  ride.dateTime.isAfter(now.subtract(const Duration(days: 28))),
            )
            .toList();
      case 3:
        return rides
            .where(
              (ride) => ride.dateTime.isAfter(
                now.subtract(const Duration(days: 182)),
              ),
            )
            .toList();
      default:
        return rides;
    }
  }

  Map<String, String> _calculateTotals(List<Ride> rides) {
    final totalDistance = rides.fold<double>(
      0.0,
      (sum, ride) => sum + ride.distance,
    );
    final totalDuration = rides.fold<Duration>(
      Duration.zero,
      (sum, ride) => sum + ride.duration,
    );
    final totalElevation = rides.fold<double>(
      0.0,
      (sum, ride) => sum + ride.elevation,
    );
    final totalCalories = rides.fold<int>(
      0,
      (sum, ride) => sum + ride.calories,
    );

    return {
      'distance': '${totalDistance.toStringAsFixed(1)} km',
      'duration': _formatDuration(totalDuration),
      'elevation': '${totalElevation.toStringAsFixed(0)} m',
      'calories': '$totalCalories kcal',
    };
  }

  List<double> _chartPoints(List<Ride> rides) {
    final now = DateTime.now();
    final lastSevenDays = List.generate(
      7,
      (index) => now.subtract(Duration(days: 6 - index)),
    );
    final dailyTotals = <double>[];
    for (final day in lastSevenDays) {
      final dayTotal = rides
          .where(
            (ride) =>
                ride.dateTime.year == day.year &&
                ride.dateTime.month == day.month &&
                ride.dateTime.day == day.day,
          )
          .fold<double>(0.0, (sum, ride) => sum + ride.distance);
      dailyTotals.add(dayTotal);
    }
    return dailyTotals;
  }

  Map<String, String> _calculateInsights(List<Ride> rides) {
    if (rides.isEmpty) {
      return {
        'bestDay': 'N/A',
        'bestDistance': '0 km',
        'avgSpeed': '0.0 km/h',
        'consistency': '0 Days',
      };
    }

    final bestRide = rides.reduce((a, b) => a.distance > b.distance ? a : b);
    final avgSpeed =
        rides.fold<double>(0.0, (sum, ride) => sum + ride.averageSpeed) /
        rides.length;
    final uniqueDays = rides
        .map(
          (ride) => DateTime(
            ride.dateTime.year,
            ride.dateTime.month,
            ride.dateTime.day,
          ),
        )
        .toSet()
        .length;

    return {
      'bestDay': _weekdayName(bestRide.dateTime),
      'bestDistance': '${bestRide.distance.toStringAsFixed(1)} km',
      'avgSpeed': '${avgSpeed.toStringAsFixed(1)} km/h',
      'consistency': '$uniqueDays Days',
    };
  }

  Map<String, String> _calculatePersonalBests(List<Ride> rides) {
    if (rides.isEmpty) {
      return {
        'farthest': '0 km',
        'farthestDate': '-',
        'longest': '0h 0m',
        'longestDate': '-',
        'highest': '0 m',
        'highestDate': '-',
        'fastest': '0.0 km/h',
        'fastestDate': '-',
      };
    }

    final farthest = rides.reduce((a, b) => a.distance > b.distance ? a : b);
    final longest = rides.reduce((a, b) => a.duration > b.duration ? a : b);
    final highest = rides.reduce((a, b) => a.elevation > b.elevation ? a : b);
    final fastest = rides.reduce(
      (a, b) => a.averageSpeed > b.averageSpeed ? a : b,
    );

    return {
      'farthest': '${farthest.distance.toStringAsFixed(1)} km',
      'farthestDate': _formatShortDate(farthest.dateTime),
      'longest': _formatDuration(longest.duration),
      'longestDate': _formatShortDate(longest.dateTime),
      'highest': '${highest.elevation.toStringAsFixed(0)} m',
      'highestDate': _formatShortDate(highest.dateTime),
      'fastest': '${fastest.averageSpeed.toStringAsFixed(1)} km/h',
      'fastestDate': _formatShortDate(fastest.dateTime),
    };
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  String _formatShortDate(DateTime dateTime) {
    return '${_weekdayName(dateTime)} ${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _weekdayName(DateTime dateTime) {
    return const [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ][dateTime.weekday - 1];
  }

  Widget _buildTopBar(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: GlassBox(
            borderRadius: BorderRadius.circular(16),
            opacity: 0.18,
            child: const Padding(
              padding: EdgeInsets.all(10),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.white,
                size: 18,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Performance Analytics',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Track your progress and level up every ride',
                style: TextStyle(color: AppColors.textBody, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        GlassBox(
          borderRadius: BorderRadius.circular(16),
          opacity: 0.18,
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Icon(Icons.calendar_today, color: AppColors.white, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodTabs() {
    return GlassBox(
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: List.generate(_tabs.length, (index) {
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
                      _tabs[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildSummaryGrid(Map<String, String> totals) {
    final cards = [
      _buildSummaryCard(
        'Total Distance',
        totals['distance'] ?? '0 km',
        Icons.alt_route,
        AppColors.greenAccent,
      ),
      _buildSummaryCard(
        'Total Time',
        totals['duration'] ?? '0h 0m',
        Icons.watch_later,
        AppColors.electricBlue,
      ),
      _buildSummaryCard(
        'Elevation Gain',
        totals['elevation'] ?? '0 m',
        Icons.terrain,
        const Color(0xFF9F7AEA),
      ),
      _buildSummaryCard(
        'Calories Burned',
        totals['calories'] ?? '0 kcal',
        Icons.local_fire_department,
        Colors.deepOrangeAccent,
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.05,
      children: cards,
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color cardColor,
  ) {
    return GlassBox(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: cardColor, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(color: AppColors.textBody, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChartCard(List<double> points) {
    final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return GlassBox(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Distance Over Time',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.navyBlue.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Text(
                        'Kilometers',
                        style: TextStyle(color: AppColors.white, fontSize: 12),
                      ),
                      SizedBox(width: 6),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 180,
              child: CustomPaint(
                painter: _LineChartPainter(points: points),
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: labels
                        .map(
                          (label) => Text(
                            label,
                            style: TextStyle(
                              color: AppColors.textBody,
                              fontSize: 11,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsRow(Map<String, String> insights) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'Performance Insights',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'View All Insights',
              style: TextStyle(color: AppColors.electricBlue, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _buildInsightCard(
                'Best Day',
                insights['bestDay'] ?? 'N/A',
                insights['bestDistance'] ?? '0 km',
                AppColors.greenAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInsightCard(
                'Avg Speed',
                insights['avgSpeed'] ?? '0.0 km/h',
                'Calculated from rides',
                AppColors.electricBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInsightCard(
                'Consistency',
                insights['consistency'] ?? '0 Days',
                'Days ridden',
                const Color(0xFF10B981),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInsightCard(
    String title,
    String value,
    String subtitle,
    Color accent,
  ) {
    return GlassBox(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.star, color: accent, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(color: AppColors.textBody, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(color: AppColors.textBody, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedAnalysisCard(List<Ride> rides) {
    final averageSpeed = rides.isEmpty
        ? 0.0
        : rides.fold<double>(0.0, (sum, ride) => sum + ride.averageSpeed) /
              rides.length;
    final maxSpeed = rides.isEmpty
        ? 0.0
        : rides.map((ride) => ride.averageSpeed).reduce(max);
    final bestKm = maxSpeed;

    return GlassBox(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Speed Analysis',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'View Details',
                  style: TextStyle(color: AppColors.electricBlue, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _buildSpeedMetric(
                  'Average Speed',
                  '${averageSpeed.toStringAsFixed(1)} km/h',
                  'Calculated from rides',
                  AppColors.electricBlue,
                ),
                const SizedBox(width: 12),
                _buildSpeedMetric(
                  'Max Speed',
                  '${maxSpeed.toStringAsFixed(1)} km/h',
                  'Highest ride avg',
                  const Color(0xFF9F7AEA),
                ),
                const SizedBox(width: 12),
                _buildSpeedMetric(
                  'Best 1km',
                  '${bestKm.toStringAsFixed(1)} km/h',
                  'Best segment',
                  Colors.deepOrangeAccent,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 180,
              child: CustomPaint(
                painter: _MultiLineChartPainter(
                  series: [
                    [12, 16, 14, 18, 20, 19, 17],
                    [28, 30, 32, 35, 38, 36, 34],
                    [22, 26, 24, 28, 31, 29, 27],
                  ],
                  colors: [
                    AppColors.electricBlue,
                    const Color(0xFF9F7AEA),
                    Colors.deepOrangeAccent,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeedMetric(
    String label,
    String value,
    String trend,
    Color accent,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textBody, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(trend, style: TextStyle(color: accent, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPersonalBestsCard(Map<String, String> bests) {
    return GlassBox(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Personal Bests',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'View All',
                  style: TextStyle(color: AppColors.electricBlue, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildPersonalBestItem(
                    'Farthest Ride',
                    bests['farthest'] ?? '0 km',
                    bests['farthestDate'] ?? '-',
                    AppColors.greenAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPersonalBestItem(
                    'Longest Time',
                    bests['longest'] ?? '0h 0m',
                    bests['longestDate'] ?? '-',
                    AppColors.electricBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildPersonalBestItem(
                    'Highest Elevation',
                    bests['highest'] ?? '0 m',
                    bests['highestDate'] ?? '-',
                    const Color(0xFF9F7AEA),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPersonalBestItem(
                    'Fastest Speed',
                    bests['fastest'] ?? '0.0 km/h',
                    bests['fastestDate'] ?? '-',
                    Colors.deepOrangeAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalBestItem(
    String title,
    String value,
    String subtitle,
    Color accent,
  ) {
    return GlassBox(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.show_chart, color: accent, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(color: AppColors.textBody, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(color: AppColors.textBody, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> points;
  _LineChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.electricBlue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..shader = LinearGradient(
        colors: [AppColors.electricBlue.withOpacity(0.25), Colors.transparent],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    if (points.isEmpty) return;

    final maxPoint = points.reduce(max);
    final minPoint = points.reduce(min);
    final range = (maxPoint - minPoint).clamp(0.0, double.infinity);

    final count = points.length;
    final stepX = count == 1 ? size.width / 2 : size.width / (count - 1);
    final path = Path();
    final fillPath = Path();

    for (var i = 0; i < count; i++) {
      final x = count == 1 ? size.width / 2 : stepX * i;
      final y = range == 0
          ? size.height / 2
          : size.height - ((points[i] - minPoint) / range) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }

      canvas.drawCircle(Offset(x, y), 4, Paint()..color = AppColors.white);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fill);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MultiLineChartPainter extends CustomPainter {
  final List<List<double>> series;
  final List<Color> colors;

  _MultiLineChartPainter({required this.series, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;

    final allPoints = series.expand((list) => list).toList();
    if (allPoints.isEmpty) return;

    final maxPoint = allPoints.reduce(max);
    final minPoint = allPoints.reduce(min);
    final range = (maxPoint - minPoint).clamp(0.0, double.infinity);

    final pointCount = series.first.length;
    if (pointCount == 0) return;
    final stepX = pointCount == 1
        ? size.width / 2
        : size.width / (pointCount - 1);

    for (var s = 0; s < series.length; s++) {
      final paint = Paint()
        ..color = colors[s % colors.length]
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      final seriesList = series[s];
      for (var i = 0; i < seriesList.length; i++) {
        final x = pointCount == 1 ? size.width / 2 : stepX * i;
        final y = range == 0
            ? size.height / 2
            : size.height - ((seriesList[i] - minPoint) / range) * size.height;

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
        canvas.drawCircle(
          Offset(x, y),
          3,
          Paint()..color = colors[s % colors.length],
        );
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
