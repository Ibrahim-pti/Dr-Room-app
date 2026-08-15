import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/api_client.dart';
import '../../core/providers/appointment_provider.dart';
import 'promo_carousel.dart';
import 'widgets/emergency_sos_banner.dart';
import 'widgets/home_header.dart';
import 'widgets/services_category_grid.dart';
import 'widgets/top_doctors_section.dart';
import 'widgets/top_labs_section.dart';
import 'widgets/top_pharmacies_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  String _userName = '';
  List<dynamic> _banners = [];
  List<dynamic> _topDoctors = [];
  List<dynamic> _topPharmacies = [];

  @override
  void initState() {
    super.initState();
    _fetchHomeData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppointmentProvider>().fetchAppointments();
    });
  }

  Future<void> _fetchHomeData() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final un = prefs.getString('user_name') ?? '';
      final userName = un.isNotEmpty ? un : 'guest_user'.tr();

      final response = await ApiClient.get('/home');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _banners = data['banners'] ?? [];
            _topDoctors = data['top_doctors'] ?? [];
            _topPharmacies = data['top_pharmacies'] ?? [];
            _userName = userName;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching home data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: RefreshIndicator(
        onRefresh: _fetchHomeData,
        color: const Color(0xFF3B82F6),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top Curved Header & Search ──
                  HomeHeader(userName: _userName),

                  // ── Banners / Promo Carousel ──
                  if (_isLoading)
                    _buildBannerSkeleton(context)
                  else
                    PromoCarousel(banners: _banners)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),

                  // ── Emergency SOS Banner ──
                  const SizedBox(height: 12),
                  const EmergencySosBanner(),

                  // ── Services Categories Grid ──
                  const SizedBox(height: 14),
                  const ServicesCategoryGrid(),

                  // ── Top Doctors Section ──
                  const SizedBox(height: 16),
                  TopDoctorsSection(topDoctors: _topDoctors),

                  // ── Top Laboratories Section ──
                  const SizedBox(height: 16),
                  const TopLabsSection(),

                  // ── Top Pharmacies Section ──
                  const SizedBox(height: 16),
                  TopPharmaciesSection(topPharmacies: _topPharmacies),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerSkeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 155,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: index == 0 ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
