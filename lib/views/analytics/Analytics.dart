import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';

class AnalyticsView extends StatelessWidget {
  const AnalyticsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Performance Analytics')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Progress',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildWeeklyChart(),
            const SizedBox(height: 30),
            const Text(
              'Monthly Distance',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildMonthlyChart(),
            const SizedBox(height: 30),
            _buildPersonalBests(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart() {
    return GlassBox(
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(20),
        child: BarChart(
          BarChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: [
              _buildBarGroup(0, 5),
              _buildBarGroup(1, 10),
              _buildBarGroup(2, 7),
              _buildBarGroup(3, 15),
              _buildBarGroup(4, 9),
              _buildBarGroup(5, 12),
              _buildBarGroup(6, 4),
            ],
          ),
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: AppColors.electricBlue,
          width: 15,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildMonthlyChart() {
    return GlassBox(
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(20),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: const [
                  FlSpot(0, 3),
                  FlSpot(1, 4),
                  FlSpot(2, 3.5),
                  FlSpot(3, 5),
                  FlSpot(4, 4),
                  FlSpot(5, 6),
                ],
                isCurved: true,
                color: AppColors.greenAccent,
                barWidth: 4,
                dotData: FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.greenAccent.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalBests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personal Bests',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildBestItem(
          'Longest Ride',
          '52.4 km',
          Icons.workspace_premium_rounded,
        ),
        const SizedBox(height: 12),
        _buildBestItem('Max Speed', '42.1 km/h', Icons.speed_rounded),
        const SizedBox(height: 12),
        _buildBestItem('Total Elevation', '1,240 m', Icons.terrain_rounded),
      ],
    );
  }

  Widget _buildBestItem(String label, String value, IconData icon) {
    return GlassBox(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Colors.amber),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: AppColors.white),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.electricBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
