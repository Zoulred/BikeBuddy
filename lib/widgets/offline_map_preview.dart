import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/app_colors.dart';

class OfflineMapPreview extends StatelessWidget {
  final LatLng? center;
  final double? accuracyMeters;
  final List<LatLng> route;

  const OfflineMapPreview({
    super.key,
    this.center,
    this.accuracyMeters,
    this.route = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off, size: 48, color: Colors.white54),
              const SizedBox(height: 8),
              const Text(
                'Offline - map tiles unavailable',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              if (center != null)
                SizedBox(
                  width: 260,
                  height: 260,
                  child: CustomPaint(
                    painter: OfflineMapPainter(accuracy: accuracyMeters ?? 30),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.place,
                            color: AppColors.greenAccent,
                            size: 36,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${center!.latitude.toStringAsFixed(5)}, ${center!.longitude.toStringAsFixed(5)}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Accuracy: ${accuracyMeters?.toStringAsFixed(0) ?? "~"} m',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Container(
                  height: 120,
                  alignment: Alignment.center,
                  child: const Text(
                    'No location available',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class OfflineMapPainter extends CustomPainter {
  final double accuracy;
  OfflineMapPainter({required this.accuracy});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white10;
    canvas.drawRect(Offset.zero & size, paint);

    final center = Offset(size.width / 2, size.height / 2);
    final circlePaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.fill;

    final r = (accuracy / 5).clamp(12.0, size.width / 2 - 8);
    canvas.drawCircle(center, r, circlePaint);

    final border = Paint()
      ..color = Colors.white30
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, r, border);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
