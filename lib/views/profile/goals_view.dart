import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';

class GoalsView extends StatelessWidget {
  const GoalsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cycling Goals')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildGoalCard('Daily Distance', 10, 8.5, AppColors.electricBlue),
            const SizedBox(height: 20),
            _buildGoalCard('Weekly Rides', 5, 3, AppColors.greenAccent),
            const SizedBox(height: 20),
            _buildGoalCard('Monthly Time', 40, 15, Colors.purple),
            const SizedBox(height: 40),
            ElevatedButton(onPressed: () {}, child: const Text('Set New Goal')),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(
    String title,
    double target,
    double current,
    Color color,
  ) {
    final progress = current / target;
    return GlassBox(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.white.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$current / $target units achieved',
              style: TextStyle(color: AppColors.textBody, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
