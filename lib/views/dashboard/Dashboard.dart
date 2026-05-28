import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/ride_viewmodel.dart';
import '../profile/profile_view.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 30),
              _buildQuickStart(context),
              const SizedBox(height: 30),
              _buildStatsGrid(context),
              const SizedBox(height: 30),
              _buildWeeklySummary(),
              const SizedBox(height: 30),
              _buildRecentActivities(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<RideViewModel>(
      builder: (context, vm, child) {
        final totalDistance = vm.rides.fold<double>(
          0,
          (p, e) => p + e.distance,
        );
        final rideCount = vm.rides.length;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mabuhay, Cyclist!',
                  style: TextStyle(color: AppColors.textBody, fontSize: 16),
                ),
                const Text(
                  'BikeBuddy PH',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${rideCount} rides · ${totalDistance.toStringAsFixed(1)} km',
                  style: TextStyle(color: AppColors.textBody, fontSize: 12),
                ),
              ],
            ),
            GestureDetector(
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileView())),
              child: const CircleAvatar(
                radius: 25,
                backgroundColor: AppColors.electricBlue,
                child: Icon(Icons.person, color: AppColors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickStart(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // In a real app, this might trigger a callback to change index in HomeScreen
      },
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.electricBlue.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                FontAwesomeIcons.personBiking,
                size: 150,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Ready to Ride?',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: const [
                      Text(
                        'Start GPS Tracking',
                        style: TextStyle(color: AppColors.white, fontSize: 16),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    final vm = Provider.of<RideViewModel>(context);
    final now = DateTime.now();
    final todays = vm.rides.where(
      (r) =>
          r.dateTime.year == now.year &&
          r.dateTime.month == now.month &&
          r.dateTime.day == now.day,
    );

    final totalDistance = todays.fold<double>(0.0, (s, r) => s + r.distance);
    final totalDuration = todays.fold<Duration>(
      Duration.zero,
      (s, r) => s + r.duration,
    );
    final totalCalories = todays.fold<int>(0, (s, r) => s + r.calories);
    final avgSpeed = totalDuration.inSeconds > 0
        ? totalDistance / (totalDuration.inSeconds / 3600)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today\'s Activity',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _buildStatCard(
              'Distance',
              '${totalDistance.toStringAsFixed(2)} km',
              Icons.route_rounded,
              AppColors.electricBlue,
            ),
            _buildStatCard(
              'Duration',
              '${totalDuration.inHours.toString().padLeft(2, '0')}:${(totalDuration.inMinutes % 60).toString().padLeft(2, '0')}:${(totalDuration.inSeconds % 60).toString().padLeft(2, '0')}',
              Icons.timer_rounded,
              AppColors.greenAccent,
            ),
            _buildStatCard(
              'Calories',
              '$totalCalories kcal',
              Icons.local_fire_department_rounded,
              Colors.orange,
            ),
            _buildStatCard(
              'Avg Speed',
              '${avgSpeed.toStringAsFixed(1)} km/h',
              Icons.speed_rounded,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return GlassBox(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(color: AppColors.textBody, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Weekly Summary',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GlassBox(
          child: Container(
            height: 100,
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: const Center(
              child: Text(
                'Performance Analytics available in Profile',
                style: TextStyle(color: AppColors.textBody),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activities',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Center(
          child: Text(
            'No recent rides yet.',
            style: TextStyle(color: AppColors.textBody),
          ),
        ),
      ],
    );
  }
}
