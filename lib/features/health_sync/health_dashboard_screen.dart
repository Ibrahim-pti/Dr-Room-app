import 'package:flutter/material.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/health_provider.dart';

class HealthDashboardScreen extends StatefulWidget {
  const HealthDashboardScreen({super.key});

  @override
  State<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends State<HealthDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate initial load if not synced
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<HealthProvider>(context, listen: false);
      if (!provider.isSynced) {
        // provider.toggleSync(true); // Auto sync on open can be optional
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final healthProvider = Provider.of<HealthProvider>(context);
    final isSynced = healthProvider.isSynced;
    final isLoading = healthProvider.isLoading;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(context),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'health_data_sync'.tr(),
          style: GoogleFonts.poppins(
            color: AppColors.getTextTitle(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.getTextTitle(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Sync Banner ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.getBorder(context)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: isLoading 
                      ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: Color(0xFFEF4444), strokeWidth: 2))
                      : const Icon(Icons.favorite, color: Color(0xFFEF4444), size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Apple Health / Google Fit',
                          style: GoogleFonts.poppins(
                            color: AppColors.getTextTitle(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isLoading 
                            ? 'Syncing data...' 
                            : (isSynced ? 'Connected and syncing' : 'Tap to sync your health data'),
                          style: GoogleFonts.poppins(
                            color: isSynced && !isLoading ? const Color(0xFF10B981) : AppColors.getTextSubtitle(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: isSynced || isLoading,
                    activeColor: const Color(0xFF3B82F6),
                    onChanged: isLoading ? null : (val) {
                      healthProvider.toggleSync(val);
                    },
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1, end: 0),
            
            const SizedBox(height: 32),
            
            Text(
              'Today\'s Metrics',
              style: GoogleFonts.poppins(
                color: AppColors.getTextTitle(context),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ).animate(delay: 100.ms).fadeIn(),
            const SizedBox(height: 16),

            // ── Metrics Grid ──
            if (!isSynced && !isLoading)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      const Icon(Iconsax.health, size: 48, color: Color(0xFF94A3B8)),
                      const SizedBox(height: 16),
                      Text(
                        'Sync data to view metrics',
                        style: GoogleFonts.poppins(
                          color: AppColors.getTextSubtitle(context),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              Row(
                children: [
                  Expanded(child: _buildMetricCard('steps'.tr(), '${healthProvider.steps}', 'steps', Icons.directions_walk, const Color(0xFF3B82F6), healthProvider.steps / 12000)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMetricCard('heart_rate'.tr(), '${healthProvider.heartRate}', 'bpm'.tr(), Iconsax.heart, const Color(0xFFEF4444), healthProvider.heartRate / 120)),
                ],
              ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1, end: 0),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildMetricCard('sleep'.tr(), healthProvider.sleepTime, 'hours'.tr(), Iconsax.moon, const Color(0xFF8B5CF6), 0.8)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildMetricCard('calories'.tr(), '${healthProvider.calories}', 'kcal'.tr(), Iconsax.flash, const Color(0xFFF59E0B), healthProvider.calories / 3000)),
                ],
              ).animate(delay: 300.ms).fadeIn().slideY(begin: 0.1, end: 0),
              
              const SizedBox(height: 32),
              
              // ── Activity Chart Placeholder ──
              Text(
                'Weekly Activity',
                style: GoogleFonts.poppins(
                  color: AppColors.getTextTitle(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ).animate(delay: 400.ms).fadeIn(),
              const SizedBox(height: 16),
              Container(
                height: 200,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.getSurface(context),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.getBorder(context)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildBar(healthProvider.weeklyActivity[0], 'Mon'),
                    _buildBar(healthProvider.weeklyActivity[1], 'Tue'),
                    _buildBar(healthProvider.weeklyActivity[2], 'Wed'),
                    _buildBar(healthProvider.weeklyActivity[3], 'Thu'),
                    _buildBar(healthProvider.weeklyActivity[4], 'Fri'),
                    _buildBar(healthProvider.weeklyActivity[5], 'Sat'),
                    _buildBar(healthProvider.weeklyActivity[6], 'Sun'),
                  ],
                ),
              ).animate(delay: 500.ms).fadeIn().slideY(begin: 0.1, end: 0),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String unit, IconData icon, Color color, double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.getBorder(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.getBorder(context),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeWidth: 4,
                  strokeCap: StrokeCap.round,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: AppColors.getTextSubtitle(context),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.poppins(
                  color: AppColors.getTextTitle(context),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: GoogleFonts.poppins(
                  color: AppColors.getTextSubtitle(context),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double heightFactor, String label) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 24,
          height: 120 * heightFactor,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: AppColors.getTextSubtitle(context),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
