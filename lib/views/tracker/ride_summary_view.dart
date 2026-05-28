import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/bike_viewmodel.dart';
import '../../models/bike.dart';
import '../../models/ride.dart';
import '../../widgets/offline_map_preview.dart';

class RideSummaryView extends StatefulWidget {
  final Ride ride;

  const RideSummaryView({super.key, required this.ride});

  @override
  State<RideSummaryView> createState() => _RideSummaryViewState();
}

class _RideSummaryViewState extends State<RideSummaryView> {
  late TextEditingController _notesController;
  SharedPreferences? _prefs;
  Ride get ride => widget.ride;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _loadNotes();
  }

  String _bikeName(BuildContext context) {
    try {
      final bikes = Provider.of<BikeViewModel>(context, listen: false).bikes;
      final bike = bikes.firstWhere(
        (b) => b.id == ride.bikeId,
        orElse: () => Bike(
          id: null,
          name: 'Unknown Bike',
          type: BikeType.other,
          purchaseDate: DateTime.now(),
        ),
      );
      final bikesAll = Provider.of<BikeViewModel>(context, listen: false).bikes;
      final isActive =
          bikesAll.isNotEmpty &&
          bike.id != null &&
          bike.id == bikesAll.first.id;
      return isActive ? '${bike.name} (Active)' : bike.name;
    } catch (_) {
      return 'Unknown Bike';
    }
  }

  Future<void> _loadNotes() async {
    _prefs = await SharedPreferences.getInstance();
    final key = _noteKey();
    _notesController.text = _prefs?.getString(key) ?? '';
    setState(() {});
  }

  String _noteKey() {
    final idPart =
        widget.ride.id?.toString() ??
        widget.ride.dateTime.millisecondsSinceEpoch.toString();
    return 'ride_note_$idPart';
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: AppColors.white,
                  ),
                ),

                const Expanded(
                  child: Center(
                    child: Text(
                      'Ride Summary',
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          child: Column(
            children: [
              // ================= HEADER =================
              _buildRideHeader(),

              const SizedBox(height: 18),

              // ================= MAP =================
              _buildMapPreview(),

              const SizedBox(height: 18),

              // ================= STATS =================
              _buildStatsCard(),

              const SizedBox(height: 18),

              // ================= DETAILS =================
              _buildDetailsCard(),

              const SizedBox(height: 18),

              // ================= NOTES =================
              _buildNotesCard(),

              const SizedBox(height: 22),

              // ================= BUTTONS =================
              Row(
                children: [
                  Expanded(child: _buildShareButton(context)),

                  const SizedBox(width: 14),

                  Expanded(child: _buildSaveButton(context)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildRideHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.greenAccent, width: 2),
          ),
          child: const Center(
            child: Icon(
              Icons.check_rounded,
              color: AppColors.greenAccent,
              size: 38,
            ),
          ),
        ),

        const SizedBox(width: 18),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Great Ride!',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'You crushed your goal today.',
                style: TextStyle(color: AppColors.textBody, fontSize: 15),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.navyBlue.withOpacity(0.65),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Row(
            children: const [
              Icon(
                Icons.emoji_events_rounded,
                color: AppColors.greenAccent,
                size: 24,
              ),

              SizedBox(width: 10),

              Text(
                '+120 XP',
                style: TextStyle(
                  color: AppColors.greenAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // =========================================================
  // MAP
  // =========================================================
  Widget _buildMapPreview() {
    if (ride.route.isEmpty) {
      return GlassBox(
        child: Container(
          height: 360,
          alignment: Alignment.center,
          child: const Text(
            'No Route Data',
            style: TextStyle(color: AppColors.textBody),
          ),
        ),
      );
    }

    return GlassBox(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 360,
          width: double.infinity,
          child: FutureBuilder<ConnectivityResult>(
            future: Connectivity().checkConnectivity(),
            builder: (context, snap) {
              final offline =
                  snap.hasData && snap.data == ConnectivityResult.none;
              if (offline) {
                return OfflineMapPreview(
                  center: ride.route.first,
                  accuracyMeters: null,
                  route: ride.route,
                );
              }
              return Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: ride.route.first,
                      zoom: 13,
                    ),
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: false,
                    tiltGesturesEnabled: false,
                    rotateGesturesEnabled: false,
                    markers: {
                      Marker(
                        markerId: const MarkerId('start'),
                        position: ride.route.first,
                      ),
                      Marker(
                        markerId: const MarkerId('end'),
                        position: ride.route.last,
                      ),
                    },
                    polylines: {
                      Polyline(
                        polylineId: const PolylineId('ride_route'),
                        points: ride.route,
                        color: AppColors.greenAccent,
                        width: 5,
                      ),
                    },
                  ),
                  Positioned(
                    bottom: 14,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            '26°C',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 10),
                          Icon(Icons.wb_sunny, color: Colors.amber, size: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
  // =========================================================
  // STATS CARD
  // =========================================================

  Widget _buildStatsCard() {
    final stats = [
      {
        'title': 'Distance',
        'value': ride.distance.toStringAsFixed(2),
        'unit': 'km',
        'icon': Icons.place_rounded,
        'color': AppColors.greenAccent,
      },
      {
        'title': 'Duration',
        'value': _formatDuration(ride.duration),
        'unit': '',
        'icon': Icons.access_time_filled,
        'color': AppColors.electricBlue,
      },
      {
        'title': 'Avg Speed',
        'value': ride.averageSpeed.toStringAsFixed(1),
        'unit': 'km/h',
        'icon': Icons.speed_rounded,
        'color': Colors.amber,
      },
      {
        'title': 'Max Speed',
        'value': ride.maxSpeed.toStringAsFixed(1),
        'unit': 'km/h',
        'icon': Icons.flash_on_rounded,
        'color': Colors.redAccent,
      },
      {
        'title': 'Elevation Gain',
        'value': ride.elevation.toStringAsFixed(0),
        'unit': 'm',
        'icon': Icons.landscape_rounded,
        'color': Colors.cyanAccent,
      },
      {
        'title': 'Calories',
        'value': '${ride.calories}',
        'unit': 'kcal',
        'icon': Icons.local_fire_department,
        'color': Colors.deepOrange,
      },
    ];

    return GlassBox(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final spacing = 12.0;
            final totalWidth = constraints.maxWidth;
            final itemWidth = (totalWidth - spacing * 2) / 3;
            final itemHeight = itemWidth * 0.95;

            return Wrap(
              spacing: spacing,
              runSpacing: 12,
              children: stats.map((stat) {
                return SizedBox(
                  width: itemWidth,
                  height: itemHeight,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withOpacity(0.04)),
                      borderRadius: BorderRadius.circular(18),
                      color: AppColors.navyBlue.withOpacity(0.25),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          stat['icon'] as IconData,
                          color: stat['color'] as Color,
                          size: 26,
                        ),
                        const SizedBox(height: 8),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              stat['value'] as String,
                              maxLines: 1,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 16,
                          child: Text(
                            stat['unit'] as String,
                            style: TextStyle(
                              color: AppColors.textBody,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Flexible(
                          child: Text(
                            stat['title'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textBody,
                              fontSize: 13,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  // =========================================================
  // DETAILS CARD
  // =========================================================

  Widget _buildDetailsCard() {
    return GlassBox(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ride Details',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            _buildDetailRow(
              Icons.calendar_today_rounded,
              'Date',
              _formatDate(ride.dateTime),
            ),

            _divider(),

            _buildDetailRow(
              Icons.access_time_rounded,
              'Start Time',
              _formatTime(ride.dateTime),
            ),

            _divider(),

            _buildDetailRow(
              Icons.timer_outlined,
              'End Time',
              _calculateEndTime(),
            ),

            _divider(),

            _buildDetailRow(
              Icons.pedal_bike_rounded,
              'Bike',
              _bikeName(context),
            ),

            _divider(),

            _buildDetailRow(Icons.route_rounded, 'Ride Type', 'Road Cycling'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.white, size: 24),

          const SizedBox(width: 16),

          Expanded(
            child: Text(
              title,
              style: TextStyle(color: AppColors.textBody, fontSize: 18),
            ),
          ),

          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 1,
      color: Colors.white12,
    );
  }

  // =========================================================
  // NOTES CARD
  // =========================================================
  Widget _buildNotesCard() {
    return GlassBox(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.note_alt_rounded,
              color: AppColors.greenAccent,
              size: 28,
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notes',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: _notesController,
                    maxLines: 4,
                    style: const TextStyle(color: AppColors.white),
                    decoration: InputDecoration(
                      hintText: 'Add your ride notes...',
                      hintStyle: TextStyle(color: AppColors.textBody),
                      border: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // BUTTONS
  // =========================================================

  Widget _buildShareButton(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
        backgroundColor: AppColors.navyBlue.withOpacity(0.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: () {
        final summary =
            '${ride.title}\n'
            'Distance: ${ride.distance.toStringAsFixed(2)} km\n'
            'Avg Speed: ${ride.averageSpeed.toStringAsFixed(1)} km/h\n'
            'Calories: ${ride.calories} kcal\n'
            'Notes: ${_notesController.text}';

        Clipboard.setData(ClipboardData(text: summary));

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ride summary copied')));
      },
      icon: const Icon(Icons.share_rounded, color: AppColors.white),
      label: const Text(
        'Share Ride',
        style: TextStyle(
          color: AppColors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.electricBlue,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: () async {
        final key = _noteKey();
        await _prefs?.setString(key, _notesController.text);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ride saved')));
      },
      icon: const Icon(Icons.save_rounded, color: AppColors.white),
      label: const Text(
        'Save Ride',
        style: TextStyle(
          color: AppColors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // =========================================================
  // HELPERS
  // =========================================================

  String _formatDuration(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');

    final m = (d.inMinutes % 60).toString().padLeft(2, '0');

    final s = (d.inSeconds % 60).toString().padLeft(2, '0');

    return '$h:$m:$s';
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12 ? dt.hour - 12 : dt.hour;

    final period = dt.hour >= 12 ? 'PM' : 'AM';

    return '$hour:${dt.minute.toString().padLeft(2, '0')} $period';
  }

  String _calculateEndTime() {
    final end = ride.dateTime.add(ride.duration);

    return _formatTime(end);
  }
}
