import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../models/bike.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class BikeDetailView extends StatelessWidget {
  final Bike bike;
  const BikeDetailView({super.key, required this.bike});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(bike.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBikeHero(),
            const SizedBox(height: 30),
            _buildStats(),
            const SizedBox(height: 30),
            const Text(
              'Maintenance Log',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildMaintenanceLog(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColors.electricBlue,
        child: const Icon(Icons.build_rounded, color: AppColors.white),
      ),
    );
  }

  Widget _buildBikeHero() {
    return GlassBox(
      child: Container(
        height: 200,
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    bike.type.name.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.electricBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    bike.name,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Acquired ${bike.purchaseDate.year}-${bike.purchaseDate.month}-${bike.purchaseDate.day}',
                    style: TextStyle(color: AppColors.textBody),
                  ),
                ],
              ),
            ),
            const Icon(
              FontAwesomeIcons.bicycle,
              size: 80,
              color: AppColors.electricBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            'Total Dist',
            '${bike.totalKilometers} km',
            Icons.route_rounded,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildInfoCard(
            'Status',
            bike.maintenanceStatus,
            Icons.build_circle_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return GlassBox(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: AppColors.electricBlue),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: AppColors.textBody, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenanceLog() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Text(
          'No maintenance records yet.',
          style: TextStyle(color: AppColors.textBody),
        ),
      ),
    );
  }
}
