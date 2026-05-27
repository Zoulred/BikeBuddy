import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../models/ride.dart';

class RideSummaryView extends StatelessWidget {
  final Ride ride;
  const RideSummaryView({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ride Summary')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildStatsHeader(),
            const SizedBox(height: 24),
            _buildMapPreview(),
            const SizedBox(height: 24),
            _buildDetailsGrid(),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Column(
      children: [
        const Text(
          'GREAT RIDE!',
          style: TextStyle(
            color: AppColors.electricBlue,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          ride.title,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${ride.dateTime.day}/${ride.dateTime.month}/${ride.dateTime.year}',
          style: TextStyle(color: AppColors.textBody),
        ),
      ],
    );
  }

  Widget _buildMapPreview() {
    if (ride.route.isEmpty) {
      return GlassBox(
        child: Container(
          height: 250,
          width: double.infinity,
          padding: const EdgeInsets.all(2),
          child: const Center(
            child: Text(
              'No route data available',
              style: TextStyle(color: AppColors.textBody),
            ),
          ),
        ),
      );
    }

    final initialPosition = ride.route.first;
    return GlassBox(
      child: SizedBox(
        height: 250,
        width: double.infinity,
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialPosition,
            zoom: 14,
          ),
          markers: {
            Marker(
              markerId: const MarkerId('start_location'),
              position: ride.route.first,
              infoWindow: const InfoWindow(title: 'Start'),
            ),
            Marker(
              markerId: const MarkerId('end_location'),
              position: ride.route.last,
              infoWindow: const InfoWindow(title: 'End'),
            ),
          },
          polylines: {
            Polyline(
              polylineId: const PolylineId('ride_route_preview'),
              points: ride.route,
              color: AppColors.greenAccent,
              width: 5,
            ),
          },
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
        ),
      ),
    );
  }

  Widget _buildDetailsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 16) / 2; // two items per row
        final items = [
          _buildDetailItem(
            'Distance',
            '${ride.distance.toStringAsFixed(2)} km',
            itemWidth,
          ),
          _buildDetailItem('Time', _formatDuration(ride.duration), itemWidth),
          _buildDetailItem(
            'Avg Speed',
            '${ride.averageSpeed.toStringAsFixed(1)} km/h',
            itemWidth,
          ),
          _buildDetailItem('Calories', '${ride.calories} kcal', itemWidth),
        ];

        return Wrap(spacing: 16, runSpacing: 16, children: items);
      },
    );
  }

  Widget _buildDetailItem(String label, String value, double width) {
    return SizedBox(
      width: width,
      child: GlassBox(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: AppColors.textBody, fontSize: 12),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}
