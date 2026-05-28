import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_theme.dart';
import '../../viewmodels/bike_viewmodel.dart';
import '../../models/bike.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'Addbikes.dart';

class GarageView extends StatelessWidget {
  const GarageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyBlue,
      body: SafeArea(
        child: Consumer<BikeViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.electricBlue),
              );
            }

            if (viewModel.bikes.isEmpty) {
              return _buildEmptyState(context);
            }

            final bike = viewModel.activeBike ?? (viewModel.bikes.isNotEmpty ? viewModel.bikes.first : null);

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                if (viewModel.bikes.isNotEmpty) ...[
                  _buildBikeSelector(context, viewModel),
                  const SizedBox(height: 20),
                ],
                if (bike != null) _buildActiveBikeCard(context, bike),
                const SizedBox(height: 24),
                  _buildSectionHeader(
                    'Maintenance Overview',
                    'View Calendar',
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  _buildOverviewRow(),
                  const SizedBox(height: 24),
                  _buildReminderCard(),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    'Maintenance History',
                    'See All',
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  _buildTimeline(),
                  const SizedBox(height: 24),
                  _buildAddRecordButton(context),
                ],
              );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
        const Text(
          'Maintenance Log',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        GlassBox(
          borderRadius: BorderRadius.circular(16),
          opacity: 0.18,
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Icon(
              Icons.notifications_none,
              color: AppColors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FontAwesomeIcons.bicycle,
              size: 80,
              color: AppColors.textBody.withOpacity(0.35),
            ),
            const SizedBox(height: 24),
            const Text(
              'Your garage is empty',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Add a bike to manage maintenance tasks, reminders, and repair history.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textBody, height: 1.4),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddBikeView()),
              ),
              child: const Text('Add Bike'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBikeCard(BuildContext context, Bike bike) {
    return GlassBox(
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.electricBlue.withOpacity(0.4),
                  width: 2,
                ),
                color: AppColors.electricBlue.withOpacity(0.1),
              ),
              child: const Icon(
                FontAwesomeIcons.bicycle,
                color: AppColors.electricBlue,
                size: 34,
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ACTIVE BIKE',
                    style: TextStyle(
                      color: AppColors.electricBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bike.name,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.greenAccent.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Good Condition',
                          style: TextStyle(
                            color: AppColors.greenAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        bike.type.name.toUpperCase(),
                        style: TextStyle(
                          color: AppColors.textBody,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddBikeView()),
              ),
              child: const Text('Change Bike'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBikeSelector(BuildContext context, BikeViewModel vm) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: vm.bikes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final b = vm.bikes[index];
          final selected = vm.activeBikeId == b.id;
          return GestureDetector(
            onTap: () => vm.setActiveBike(b.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppColors.electricBlue : Colors.white.withOpacity(0.06),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  ClipOval(
                    child: b.imagePath != null
                        ? Image.asset(b.imagePath!, width: 64, height: 64, fit: BoxFit.cover)
                        : const Icon(FontAwesomeIcons.bicycle, size: 36, color: AppColors.electricBlue),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 80,
                    child: Text(
                      b.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.textBody, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    String actionLabel, {
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        GestureDetector(
          onTap: onTap,
          child: Text(
            actionLabel,
            style: const TextStyle(
              color: AppColors.electricBlue,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewRow() {
    final cards = [
      _buildOverviewCard(
        Icons.link_rounded,
        'Chain',
        'Good',
        '350 km left',
        AppColors.greenAccent,
      ),
      _buildOverviewCard(
        Icons.circle,
        'Tires',
        'Good',
        '1,120 km left',
        AppColors.electricBlue,
      ),
      _buildOverviewCard(
        Icons.blur_circular,
        'Brakes',
        'Good',
        '620 km left',
        const Color(0xFF9F7AEA),
      ),
      _buildOverviewCard(
        Icons.settings,
        'Gears',
        'Good',
        '2,000 km left',
        const Color(0xFFF5B84B),
      ),
      _buildOverviewCard(
        Icons.sensors,
        'Suspension',
        'Good',
        '1,500 km left',
        const Color(0xFFF58A3C),
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: cards
            .map(
              (card) => Padding(
                padding: const EdgeInsets.only(right: 12),
                child: card,
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildOverviewCard(
    IconData icon,
    String title,
    String status,
    String subtitle,
    Color accent,
  ) {
    return GlassBox(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              status,
              style: const TextStyle(
                color: AppColors.greenAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: AppColors.textBody, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard() {
    return GlassBox(
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.greenAccent.withOpacity(0.18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                color: AppColors.greenAccent,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Next Maintenance Reminder',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Chain check due in 350 km or 15 days',
                    style: TextStyle(color: AppColors.textBody, fontSize: 13),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'View All',
                style: TextStyle(color: AppColors.electricBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    final items = [
      _GarageTimelineItem(
        icon: Icons.link_rounded,
        iconColor: AppColors.greenAccent,
        title: 'Chain Replacement',
        subtitle: 'May 20, 2024 | 2,000 km',
        description: 'Shimano Deore Chain',
        statusLabel: 'Completed',
        statusColor: AppColors.greenAccent,
      ),
      _GarageTimelineItem(
        icon: Icons.tire_repair,
        iconColor: AppColors.electricBlue,
        title: 'Tire Replacement',
        subtitle: 'May 10, 2024 | 1,800 km',
        description: 'Maxxis Ardent 29x2.25',
        statusLabel: 'Completed',
        statusColor: AppColors.greenAccent,
      ),
      _GarageTimelineItem(
        icon: Icons.branding_watermark_outlined,
        iconColor: const Color(0xFF9F7AEA),
        title: 'Brake Maintenance',
        subtitle: 'Apr 28, 2024 | 1,650 km',
        description: 'Disc Brake Service',
        statusLabel: 'Completed',
        statusColor: AppColors.greenAccent,
      ),
      _GarageTimelineItem(
        icon: Icons.settings,
        iconColor: const Color(0xFFF5B84B),
        title: 'Gear Tuning',
        subtitle: 'Apr 15, 2024 | 1,400 km',
        description: 'Derailleur Adjustment',
        statusLabel: 'Due Soon',
        statusColor: const Color(0xFFF5B84B),
      ),
      _GarageTimelineItem(
        icon: Icons.sensors,
        iconColor: const Color(0xFFF58A3C),
        title: 'Suspension Service',
        subtitle: 'Mar 20, 2024 | 1,000 km',
        description: 'Fork Lower Leg Service',
        statusLabel: 'Completed',
        statusColor: AppColors.greenAccent,
      ),
    ];

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: item,
            ),
          )
          .toList(),
    );
  }

  Widget _buildAddRecordButton(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.electricBlue,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: () {},
      icon: const Icon(Icons.add_rounded, color: AppColors.white),
      label: const Text(
        'Add Maintenance Record',
        style: TextStyle(color: AppColors.white, fontSize: 16),
      ),
    );
  }
}

class _GarageTimelineItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String description;
  final String statusLabel;
  final Color statusColor;

  const _GarageTimelineItem({
    // ignore: unused_element_parameter
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            Container(
              width: 2,
              height: 120,
              margin: const EdgeInsets.symmetric(vertical: 6),
              color: AppColors.textBody.withOpacity(0.2),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: GlassBox(
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(18),
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(color: AppColors.textBody, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
