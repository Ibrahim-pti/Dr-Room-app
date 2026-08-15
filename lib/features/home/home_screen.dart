import 'package:cached_network_image/cached_network_image.dart';
import 'package:dr_room/features/nursing/nursing_services_screen.dart';
import '../ai_assistant/ai_symptom_checker_screen.dart';
import '../prescriptions/pill_reminder_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' hide Consumer;
import 'dart:ui';
import '../../core/theme/app_colors.dart';
import '../../core/models/appointment_model.dart';
import '../../core/providers/appointment_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../categories/all_categories_screen.dart';
import '../appointments/all_schedules_screen.dart';
import '../discover/article_details_screen.dart';
import '../doctors/all_doctors_screen.dart';
import '../pharmacy/screens/pharmacies_screen.dart';
import '../pharmacy/screens/pharmacy_detail_screen.dart';
import '../pharmacy/models/pharmacy_model.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../doctors/doctor_details_screen.dart';
import '../notifications/notifications_screen.dart';
import '../lab/all_labs_screen.dart';
import 'promo_carousel.dart';
import '../records/medical_records_screen.dart';
import '../emergency/sos_screen.dart';
import '../emergency/emergency_sos_modal.dart';
import '../lab/lab_details_screen.dart';
import '../search/global_search_screen.dart';
import '../../core/widgets/tinder_swipe_card.dart';

import 'dart:convert';
import '../../core/utils/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pharmacy/providers/cart_provider.dart';
import '../pharmacy/screens/cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  List<dynamic> _banners = [];
  List<dynamic> _topDoctors = [];
  List<dynamic> _topPharmacies = [];
  String _userName = '';

  bool _isLoadingArticles = true;
  List<dynamic> _articles = [];

  final List<Map<String, dynamic>> _fallbackDoctors = [
    {
      'id': 101,
      'user': {'name': 'د. ئارام عوسمان'},
      'specialty': 'پسپۆڕی دڵ و بۆرییەکانی خوێن',
      'rating': 4.9,
      'total_reviews': 128,
      'image_path': null,
    },
    {
      'id': 102,
      'user': {'name': 'د. ژینۆ ئەحمەد'},
      'specialty': 'پسپۆڕی نەخۆشییەکانی منداڵان',
      'rating': 4.8,
      'total_reviews': 95,
      'image_path': null,
    },
    {
      'id': 103,
      'user': {'name': 'د. سەرۆک عومەر'},
      'specialty': 'پسپۆڕی ئێسک و جومگە',
      'rating': 4.9,
      'total_reviews': 142,
      'image_path': null,
    },
    {
      'id': 104,
      'user': {'name': 'د. کاروان کامەران'},
      'specialty': 'پسپۆڕی پێست و جوانکاری',
      'rating': 4.7,
      'total_reviews': 76,
      'image_path': null,
    },
    {
      'id': 105,
      'user': {'name': 'د. ڕۆژان محەمەد'},
      'specialty': 'پسپۆڕی ئافرەتان و منداڵبوون',
      'rating': 4.9,
      'total_reviews': 210,
      'image_path': null,
    },
    {
      'id': 106,
      'user': {'name': 'د. هەورامان عەلی'},
      'specialty': 'پسپۆڕی نەخۆشییەکانی چاو',
      'rating': 4.8,
      'total_reviews': 105,
      'image_path': null,
    },
    {
      'id': 107,
      'user': {'name': 'د. نەبەز جەمال'},
      'specialty': 'پسپۆڕی هەناوی و شەکرە',
      'rating': 4.7,
      'total_reviews': 88,
      'image_path': null,
    },
  ];

  final List<Map<String, dynamic>> _fallbackPharmacies = [
    {
      'id': 201,
      'name': 'دەرمانخانەی سۆران ناوەندی',
      'city': 'هەولێر',
      'time': '٢٤ کاتژمێر بەردەوام',
      'rating': 4.9,
      'delivery_fee': 1500.0,
      'profile_image': null,
    },
    {
      'id': 202,
      'name': 'دەرمانخانەی بەختیاری',
      'city': 'سلێمانی',
      'time': '٨ بەیانی - ١٢ شەو',
      'rating': 4.8,
      'delivery_fee': 2000.0,
      'profile_image': null,
    },
    {
      'id': 203,
      'name': 'دەرمانخانەی ئازادی',
      'city': 'دهۆک',
      'time': '٢٤ کاتژمێر',
      'rating': 4.9,
      'delivery_fee': 1500.0,
      'profile_image': null,
    },
    {
      'id': 204,
      'name': 'دەرمانخانەی شاری پزیشکی',
      'city': 'هەولێر',
      'time': '٢٤ کاتژمێر',
      'rating': 4.7,
      'delivery_fee': 1000.0,
      'profile_image': null,
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchHomeData();
    _fetchArticles();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AppointmentProvider>().fetchAppointments();
    });
  }

  Future<void> _fetchArticles() async {
    try {
      final response = await ApiClient.get('/articles');
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _articles = jsonDecode(response.body);
        });
      }
    } catch (e) {
      debugPrint('Error fetching articles: $e');
    } finally {
      if (mounted) setState(() => _isLoadingArticles = false);
    }
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Fixed Background Watermarks (Middle/Bottom)
          Positioned(
            left: -40,
            bottom: 100,
            child:
                Transform.rotate(
                      angle: -0.2,
                      child: const Icon(
                        Icons.local_hospital_outlined,
                        size: 200,
                        color: Colors.black,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fade(begin: 0.015, end: 0.025, duration: 6000.ms)
                    .moveX(
                      begin: 0,
                      end: 15,
                      duration: 7000.ms,
                      curve: Curves.easeInOut,
                    )
                    .rotate(begin: -0.03, end: 0.03, duration: 9000.ms),
          ),
          Positioned(
            right: -20,
            bottom: 350,
            child:
                Transform.rotate(
                      angle: 0.2,
                      child: const Icon(
                        Icons.healing_outlined,
                        size: 150,
                        color: Colors.black,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fade(begin: 0.01, end: 0.02, duration: 5000.ms)
                    .moveX(
                      begin: 0,
                      end: -15,
                      duration: 8000.ms,
                      curve: Curves.easeInOut,
                    )
                    .rotate(begin: -0.02, end: 0.02, duration: 10000.ms),
          ),

          // Scrollable Content
          RefreshIndicator(
            onRefresh: _fetchHomeData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: ClampingScrollPhysics(),
              ),
              child: Padding(
                // Extra bottom padding for the floating navigation bar
                padding: const EdgeInsetsDirectional.only(bottom: 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Top Section with Blue Background ──
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Blue Gradient Background
                        ClipPath(
                          clipper: OvalBottomBorderClipper(),
                          child: Container(
                            height: 280,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFF3B82F6), // Strong Blue
                                  Color(0xFF8BB5F8), // Lighter Blue
                                  Color(0xFFE2EAF8), // Fades to background
                                ],
                                stops: [0.0, 0.7, 1.0],
                              ),
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Large Medical Icon (Right)
                                Positioned(
                                  right: -30,
                                  top: -20,
                                  child:
                                      Transform.rotate(
                                            angle: -0.2,
                                            child: const Icon(
                                              Icons.medical_services_outlined,
                                              size: 180,
                                              color: Colors.white,
                                            ),
                                          )
                                          .animate(
                                            onPlay: (c) =>
                                                c.repeat(reverse: true),
                                          )
                                          .fade(
                                            begin: 0.03,
                                            end: 0.05,
                                            duration: 4000.ms,
                                          )
                                          .moveX(
                                            begin: 0,
                                            end: -12,
                                            duration: 5000.ms,
                                            curve: Curves.easeInOut,
                                          )
                                          .rotate(
                                            begin: -0.01,
                                            end: 0.01,
                                            duration: 7000.ms,
                                          ),
                                ),

                                // Smaller Heart/Health Icon (Left)
                                Positioned(
                                  left: -20,
                                  top: 80,
                                  child:
                                      Transform.rotate(
                                            angle: 0.3,
                                            child: const Icon(
                                              Icons.monitor_heart_outlined,
                                              size: 120,
                                              color: Colors.white,
                                            ),
                                          )
                                          .animate(
                                            onPlay: (c) =>
                                                c.repeat(reverse: true),
                                          )
                                          .fade(
                                            begin: 0.02,
                                            end: 0.04,
                                            duration: 5000.ms,
                                          )
                                          .moveX(
                                            begin: 0,
                                            end: 12,
                                            duration: 6000.ms,
                                            curve: Curves.easeInOut,
                                          )
                                          .rotate(
                                            begin: -0.02,
                                            end: 0.02,
                                            duration: 8000.ms,
                                          ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Content over background
                        SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 10),
                                // ── App Bar ──
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          // User Avatar
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: AppColors.getSurface(
                                                  context,
                                                ),
                                                width: 2,
                                              ),
                                              image: const DecorationImage(
                                                image: AssetImage(
                                                  'assets/images/doctor2.png',
                                                ),
                                                fit: BoxFit.cover,
                                                alignment: Alignment.topCenter,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          // User Greeting
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  _userName.isNotEmpty && _userName.toLowerCase() != 'slaw'
                                                      ? 'سڵاو، $_userName'
                                                      : 'سڵاو، بەخێربێن',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontFamily: 'Rabar',
                                                    color: Colors.white,
                                                    fontSize: 15.5,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const Text(
                                                  'هیوای تەندروستییەکی باش',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontFamily: 'Rabar',
                                                    color: Colors.white70,
                                                    fontSize: 11.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Cart Icon
                                        Consumer(
                                          builder: (context, ref, child) {
                                            final cartState = ref.watch(cartProvider);
                                            return GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => const CartScreen(),
                                                  ),
                                                );
                                              },
                                              child: Stack(
                                                children: [
                                                  Container(
                                                    width: 42,
                                                    height: 42,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white.withValues(alpha: 0.2),
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(Iconsax.shopping_cart, color: Colors.white, size: 20),
                                                  ),
                                                  if (cartState.totalItems > 0)
                                                    PositionedDirectional(
                                                      top: 6,
                                                      end: 6,
                                                      child: Container(
                                                        padding: const EdgeInsets.all(4),
                                                        decoration: const BoxDecoration(
                                                          color: Colors.redAccent,
                                                          shape: BoxShape.circle,
                                                        ),
                                                        child: Text(
                                                          cartState.totalItems.toString(),
                                                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                        const SizedBox(width: 8),
                                        // Notification Icon
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => const NotificationsScreen(),
                                              ),
                                            );
                                          },
                                          child: Stack(
                                            children: [
                                              Container(
                                                width: 42,
                                                height: 42,
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.2),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Iconsax.notification, color: Colors.white, size: 20),
                                              ),
                                              PositionedDirectional(
                                                top: 10,
                                                end: 10,
                                                child: Container(
                                                  width: 7,
                                                  height: 7,
                                                  decoration: const BoxDecoration(
                                                    color: Colors.redAccent,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        // Menu Icon
                                        GestureDetector(
                                          onTap: () {
                                            Scaffold.of(context).openEndDrawer();
                                          },
                                          child: Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withValues(alpha: 0.2),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Iconsax.menu_1, color: Colors.white, size: 20),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
                                const SizedBox(height: 50),
                                // ── Search Bar ──
                                GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const GlobalSearchScreen(),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        height: 56, // Slightly slimmer
                                        padding:
                                            const EdgeInsetsDirectional.only(
                                              start: 20,
                                              end: 6,
                                            ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF3B82F6,
                                              ).withValues(alpha: 0.05),
                                              blurRadius: 24,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Iconsax.search_normal_1,
                                              color: Color(0xFF64748B),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              'search_doctors'.tr(),
                                              style: GoogleFonts.poppins(
                                                color: const Color(0xFF94A3B8),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const Spacer(),
                                            Container(
                                                  width: 44,
                                                  height: 44,
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFF3B82F6,
                                                    ).withValues(alpha: 0.08),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Iconsax.microphone,
                                                    color: Color(0xFF3B82F6),
                                                    size: 20,
                                                  ),
                                                )
                                                .animate(
                                                  onPlay: (controller) =>
                                                      controller.repeat(),
                                                )
                                                .shimmer(
                                                  duration: 2500.ms,
                                                  color: const Color(
                                                    0xFF3B82F6,
                                                  ).withValues(alpha: 0.2),
                                                ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .animate()
                                    .fadeIn(delay: 200.ms, duration: 400.ms)
                                    .slideY(begin: 0.2, end: 0),

                                const SizedBox(height: 28),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ── Banners / Promo Carousel ──
                    if (_isLoading)
                      _buildBannerSkeleton(context)
                    else
                      PromoCarousel(banners: _banners)
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.1, end: 0, curve: Curves.easeOut),

                    // ── Emergency SOS Banner ──
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GestureDetector(
                        onTap: () => EmergencySosModal.show(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.emergency, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'حاڵەتی لەناکاو و فریاکەوتن (SOS)',
                                      style: TextStyle(
                                        fontFamily: 'Rabar',
                                        color: Colors.white,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'پەیوەندیی دەستبەجێ بە فریاکەوتنی ١٢٢ و نەخۆشخانەکان',
                                      style: TextStyle(
                                        fontFamily: 'Rabar',
                                        color: Colors.white70,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.call, color: Color(0xFFDC2626), size: 14),
                                    SizedBox(width: 4),
                                    Text(
                                      'پەیوەندی',
                                      style: TextStyle(
                                        fontFamily: 'Rabar',
                                        color: Color(0xFFDC2626),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.05, end: 0),

                    // ── Categories (Grid) ──
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'categories'.tr(),
                            style: GoogleFonts.poppins(
                              color: AppColors.getTextTitle(context),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AllCategoriesScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'see_all'.tr(),
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF3B82F6),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 350.ms),

                    const SizedBox(height: 16),

                    _buildCategoryGrid(context)
                        .animate()
                        .fadeIn(delay: 400.ms)
                        .slideY(begin: 0.2, end: 0),

                    // ── Upcoming Appointment ──
                    const SizedBox(height: 16),
                    _buildUpcomingAppointmentCard(context),

                    // ── Top Doctors Header ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'top_doctors'.tr(),
                            style: GoogleFonts.poppins(
                              color: AppColors.getTextTitle(context),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const AllDoctorsScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'see_all'.tr(),
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF3B82F6),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 450.ms),

                    const SizedBox(height: 16),

                    // ── Doctor List Card ──
                    Builder(
                      builder: (context) {
                        final isDark = Theme.of(context).brightness == Brightness.dark;
                        final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
                        final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
                        final doctorsList = _topDoctors.isNotEmpty
                            ? _topDoctors
                            : _fallbackDoctors;

                        return SizedBox(
                          height: 228,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: doctorsList.length,
                            itemBuilder: (context, index) {
                              final doc = doctorsList[index];
                              final name = doc['user'] != null
                                  ? doc['user']['name']
                                  : (doc['name'] ?? 'د. ئارام عوسمان');
                              final specialty =
                                  doc['specialty'] ?? 'پسپۆڕی پزیشکی';
                              final rating = doc['rating']?.toString() ?? '4.8';
                              final totalReviews = doc['total_reviews'] ?? 45;
                              final reviews = '($totalReviews)';

                              final fallbackImages = [
                                'assets/images/doctor1.png',
                                'assets/images/doctor2.png',
                                'assets/images/doctor3.png',
                                'assets/images/doctor.png',
                              ];
                              final fallbackImage =
                                  fallbackImages[index % fallbackImages.length];

                              final rawPath = doc['image_path']?.toString();
                              final image = (rawPath != null && rawPath.isNotEmpty)
                                  ? (rawPath.startsWith('assets/')
                                      ? rawPath
                                      : ApiClient.getImageUrl(rawPath))
                                  : fallbackImage;
                              final isNetworkImg = image.startsWith('http');
                              final doctorId = doc['id'];

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DoctorDetailsScreen(
                                        doctorId: doctorId,
                                        name: name,
                                        specialty: specialty,
                                        image: image,
                                        initialDoctor:
                                            Map<String, dynamic>.from(doc),
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 165,
                                  margin: const EdgeInsetsDirectional.only(
                                    end: 14,
                                    bottom: 6,
                                    top: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: borderColor),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: isDark ? 0.25 : 0.05,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top Image Container
                                      Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(19),
                                            ),
                                            child: Container(
                                              height: 98,
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: isDark
                                                      ? [
                                                          const Color(0xFF0F172A),
                                                          const Color(0xFF1E293B),
                                                        ]
                                                      : [
                                                          const Color(0xFFEFF6FF),
                                                          const Color(0xFFDBEAFE),
                                                        ],
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                ),
                                              ),
                                              child: isNetworkImg
                                                  ? CachedNetworkImage(
                                                      imageUrl: image,
                                                      fit: BoxFit.cover,
                                                      alignment: Alignment.topCenter,
                                                      errorWidget: (context, url, error) => const Icon(
                                                        Icons.person,
                                                        size: 45,
                                                        color: Color(0xFF3B82F6),
                                                      ),
                                                    )
                                                  : Image.asset(
                                                      image,
                                                      fit: BoxFit.cover,
                                                      alignment: Alignment.topCenter,
                                                    ),
                                            ),
                                          ),
                                          // Verified Tag
                                          PositionedDirectional(
                                            top: 6,
                                            start: 6,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 2.5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF10B981),
                                                borderRadius: BorderRadius.circular(6),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: const [
                                                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 10),
                                                  SizedBox(width: 3),
                                                  Text(
                                                    'باوەڕپێکراو',
                                                    style: TextStyle(
                                                      fontFamily: 'Rabar',
                                                      color: Colors.white,
                                                      fontSize: 8.5,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          // Favorite Icon
                                          PositionedDirectional(
                                            top: 6,
                                            end: 6,
                                            child: Container(
                                              width: 26,
                                              height: 26,
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(alpha: 0.35),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.favorite_border_rounded,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Content
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: TextStyle(
                                                fontFamily: 'Rabar',
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 1),
                                            Text(
                                              specialty,
                                              style: TextStyle(
                                                fontFamily: 'Rabar',
                                                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                                fontSize: 10.5,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Icons.star_rounded,
                                                  color: Color(0xFFF59E0B),
                                                  size: 13,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  rating,
                                                  style: const TextStyle(
                                                    fontFamily: 'Rabar',
                                                    color: Color(0xFFD97706),
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  reviews,
                                                  style: TextStyle(
                                                    fontFamily: 'Rabar',
                                                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                                    fontSize: 9.5,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            // Book Now Button
                                            Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(
                                                vertical: 4.5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF3B82F6),
                                                borderRadius: BorderRadius.circular(10),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: const [
                                                  Icon(
                                                    Iconsax.calendar_1,
                                                    color: Colors.white,
                                                    size: 12,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'نۆرەگرتن',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontFamily: 'Rabar',
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate().fadeIn(delay: (500 + (index * 80)).ms).slideX(begin: 0.1, end: 0);
                            },
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 7),

                    // ── Top Labs Header ──
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'top_labs'.tr(),
                            style: GoogleFonts.poppins(
                              color: AppColors.getTextTitle(context),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AllLabsScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'see_all'.tr(),
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF3B82F6),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 550.ms),

                    const SizedBox(height: 8),

                    // ── Top Labs Horizontal List ──
                    Builder(
                      builder: (context) {
                        final isDark = Theme.of(context).brightness == Brightness.dark;
                        final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
                        final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

                        return SizedBox(
                          height: 198,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: 4,
                            itemBuilder: (context, index) {
                              final labs = [
                                {
                                  'name': 'تاقیگەی ناوەندی هەولێر',
                                  'city': 'Erbil',
                                  'time': '25-35 min',
                                  'image': 'assets/images/lab1.jpg',
                                },
                                {
                                  'name': 'تاقیگەی سلێمانی نموونەیی',
                                  'city': 'Sulaymaniyah',
                                  'time': '30-40 min',
                                  'image': 'assets/images/lab2.jpg',
                                },
                                {
                                  'name': 'تاقیگەی دهۆک',
                                  'city': 'Duhok',
                                  'time': '20-30 min',
                                  'image': 'assets/images/lab3.jpg',
                                },
                                {
                                  'name': 'تاقیگەی کەرکوک مێدیکا',
                                  'city': 'Kirkuk',
                                  'time': '15-25 min',
                                  'image': 'assets/images/lab4.jpg',
                                },
                              ];
                              final lab = labs[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          LabDetailsScreen(lab: lab),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 175,
                                  margin: const EdgeInsetsDirectional.only(
                                    end: 14,
                                    bottom: 6,
                                    top: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: borderColor),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: isDark ? 0.25 : 0.05,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top Image Section
                                      Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(19),
                                            ),
                                            child: Container(
                                              height: 92,
                                              width: double.infinity,
                                              color: const Color(0xFFF8FAFC),
                                              child: Image.asset(
                                                lab['image']!,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          // Rating Badge
                                          PositionedDirectional(
                                            bottom: 6,
                                            end: 6,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 7,
                                                vertical: 2.5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.95),
                                                borderRadius: BorderRadius.circular(10),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.15),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: const [
                                                  Icon(
                                                    Icons.star_rounded,
                                                    color: Color(0xFFF59E0B),
                                                    size: 13,
                                                  ),
                                                  SizedBox(width: 3),
                                                  Text(
                                                    '4.8',
                                                    style: TextStyle(
                                                      fontFamily: 'Rabar',
                                                      color: Color(0xFF1E293B),
                                                      fontSize: 10.5,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Details Section
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              lab['name']!,
                                              style: TextStyle(
                                                fontFamily: 'Rabar',
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 3),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Iconsax.location,
                                                  color: Color(0xFF3B82F6),
                                                  size: 11,
                                                ),
                                                const SizedBox(width: 3),
                                                Expanded(
                                                  child: Text(
                                                    lab['city']!,
                                                    style: TextStyle(
                                                      fontFamily: 'Rabar',
                                                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                                      fontSize: 10.5,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Iconsax.clock,
                                                  color: Color(0xFF94A3B8),
                                                  size: 11,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  lab['time']!,
                                                  style: TextStyle(
                                                    fontFamily: 'Rabar',
                                                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                                    fontSize: 10,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: const [
                                                      Icon(
                                                        Iconsax.shield_tick,
                                                        color: Color(0xFF10B981),
                                                        size: 10,
                                                      ),
                                                      SizedBox(width: 2),
                                                      Text(
                                                        'کراوەیە',
                                                        style: TextStyle(
                                                          fontFamily: 'Rabar',
                                                          color: Color(0xFF10B981),
                                                          fontSize: 9.5,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .animate()
                              .fadeIn(delay: (500 + (index * 80)).ms)
                              .slideY(begin: 0.08, end: 0);
                            },
                          ),
                        );
                      },
                    ),

                    // ── Top Pharmacies ──
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'top_pharmacies'.tr(),
                            style: GoogleFonts.poppins(
                              color: AppColors.getTextTitle(context),
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PharmaciesScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'see_all'.tr(),
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF3B82F6),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 600.ms),
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final isDark = Theme.of(context).brightness == Brightness.dark;
                        final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
                        final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
                        final pharmaciesList = _topPharmacies.isNotEmpty
                            ? _topPharmacies
                            : _fallbackPharmacies;

                        return SizedBox(
                          height: 198,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: pharmaciesList.length,
                            itemBuilder: (context, index) {
                              final pharm = pharmaciesList[index];
                              final name = pharm['name'] ?? 'دەرمانخانەی سۆران';
                              final city = pharm['city'] ?? 'هەولێر';
                              final time = pharm['time'] ?? '٢٤ کاتژمێر';
                              final profileImage = pharm['profile_image'];

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          PharmacyDetailScreen(
                                            pharmacy: Pharmacy(
                                              id: pharm['id'] ?? 1,
                                              name:
                                                  pharm['name'] ?? 'دەرمانخانە',
                                              rating:
                                                  double.tryParse(
                                                    pharm['rating']
                                                            ?.toString() ??
                                                        '4.8',
                                                  ) ??
                                                  4.8,
                                              deliveryFee:
                                                  double.tryParse(
                                                    pharm['delivery_fee']
                                                            ?.toString() ??
                                                        '1500.0',
                                                  ) ??
                                                  1500.0,
                                              profileImage:
                                                  pharm['profile_image'],
                                            ),
                                          ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 175,
                                  margin: const EdgeInsetsDirectional.only(
                                    end: 14,
                                    bottom: 6,
                                    top: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: borderColor),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: isDark ? 0.25 : 0.05,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top Image Section
                                      Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: const BorderRadius.vertical(
                                              top: Radius.circular(19),
                                            ),
                                            child: Container(
                                              height: 92,
                                              width: double.infinity,
                                              color: const Color(0xFFF8FAFC),
                                              child: profileImage != null
                                                  ? CachedNetworkImage(
                                                      imageUrl: ApiClient.getImageUrl(profileImage),
                                                      fit: BoxFit.cover,
                                                      errorWidget: (context, url, error) => Image.asset(
                                                        'assets/images/pharmacy1.jpg',
                                                        fit: BoxFit.cover,
                                                      ),
                                                    )
                                                  : Image.asset(
                                                      'assets/images/pharmacy1.jpg',
                                                      fit: BoxFit.cover,
                                                    ),
                                            ),
                                          ),
                                          // Rating Badge
                                          PositionedDirectional(
                                            bottom: 6,
                                            end: 6,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 7,
                                                vertical: 2.5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.95),
                                                borderRadius: BorderRadius.circular(10),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.15),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: const [
                                                  Icon(
                                                    Icons.star_rounded,
                                                    color: Color(0xFFF59E0B),
                                                    size: 13,
                                                  ),
                                                  SizedBox(width: 3),
                                                  Text(
                                                    '4.9',
                                                    style: TextStyle(
                                                      fontFamily: 'Rabar',
                                                      color: Color(0xFF1E293B),
                                                      fontSize: 10.5,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Details Section
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: TextStyle(
                                                fontFamily: 'Rabar',
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 3),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Iconsax.location,
                                                  color: Color(0xFF3B82F6),
                                                  size: 11,
                                                ),
                                                const SizedBox(width: 3),
                                                Expanded(
                                                  child: Text(
                                                    city,
                                                    style: TextStyle(
                                                      fontFamily: 'Rabar',
                                                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                                      fontSize: 10.5,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                const Icon(
                                                  Iconsax.clock,
                                                  color: Color(0xFF94A3B8),
                                                  size: 11,
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  time,
                                                  style: TextStyle(
                                                    fontFamily: 'Rabar',
                                                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                                    fontSize: 10,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: const [
                                                      Icon(
                                                        Iconsax.verify,
                                                        color: Color(0xFF10B981),
                                                        size: 10,
                                                      ),
                                                      SizedBox(width: 2),
                                                      Text(
                                                        'باوەڕپێکراو',
                                                        style: TextStyle(
                                                          fontFamily: 'Rabar',
                                                          color: Color(0xFF10B981),
                                                          fontSize: 9.5,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate().fadeIn(delay: (500 + (index * 80)).ms).slideX(begin: 0.1, end: 0);
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingAppointmentCard(BuildContext context) {
    final appointmentProvider = context.watch<AppointmentProvider>();
    final upcoming =
        appointmentProvider.appointments
            .where(
              (a) => a.isUpcoming && a.status != AppointmentStatus.cancelled,
            )
            .toList()
          ..sort((a, b) => a.appointmentDate.compareTo(b.appointmentDate));

    if (upcoming.isEmpty) return const SizedBox.shrink();
    final next = upcoming.first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.2),
                ),
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.trash, color: Colors.redAccent, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'appointment_cancelled'.tr(),
                    style: GoogleFonts.poppins(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          TinderSwipeCard(
            onSwiped: () async {
              final success =
                  await appointmentProvider.cancelAppointment(next.id);
              
              if (success) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'appointment_cancelled'.tr(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Failed to cancel appointment on server.',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
              return success;
            },
            child:
                GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AllSchedulesScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.getSurface(context),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: const Color(
                              0xFF3B82F6,
                            ).withValues(alpha: 0.15),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // ── Header: Title & Status ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'upcoming_appointments'.tr(),
                                  style: GoogleFonts.poppins(
                                    color: AppColors.getTextTitle(context),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: next.status.color.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    next
                                        .status
                                        .kurdiName, // Kurdish translation for status
                                    style: GoogleFonts.poppins(
                                      color: next.status.color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // ── Doctor Info ──
                            Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(
                                      0xFF3B82F6,
                                    ).withValues(alpha: 0.1),
                                    image: next.doctorImageUrl != null
                                        ? DecorationImage(
                                            image: CachedNetworkImageProvider(
                                              next.doctorImageUrl!,
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: next.doctorImageUrl == null
                                      ? const Icon(
                                          Iconsax.user,
                                          color: Color(0xFF3B82F6),
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        next.doctorName.isNotEmpty
                                            ? next.doctorName
                                            : 'Doctor',
                                        style: GoogleFonts.poppins(
                                          color: AppColors.getTextTitle(
                                            context,
                                          ),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        next.doctorSpecialty.isNotEmpty
                                            ? next.doctorSpecialty
                                            : 'پزیشکی گشتی',
                                        style: GoogleFonts.poppins(
                                          color: AppColors.getTextSubtitle(
                                            context,
                                          ),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEFF6FF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Iconsax.arrow_left_2, // Left arrow for RTL
                                    color: Color(0xFF3B82F6),
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),
                            const Divider(color: Color(0xFFF1F5F9), height: 1),
                            const SizedBox(height: 16),

                            // ── Date & Time (Moved down nicely) ──
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Iconsax.calendar_1,
                                        color: Color(0xFF64748B),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        next.formattedDate,
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF475569),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Iconsax.clock,
                                        color: Color(0xFF64748B),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        next.formattedTime,
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF475569),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .moveX(
                      begin: -0.5,
                      end: 0.5,
                      curve: Curves.easeInOutSine,
                      delay: 3500.ms,
                      duration: 2500.ms,
                    )
                    .rotate(
                      begin: -0.002,
                      end: 0.002,
                      curve: Curves.easeInOutSine,
                      delay: 3500.ms,
                      duration: 2500.ms,
                    ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1, end: 0);
  }

  /// Placeholder shown while `/home` is in flight. It mirrors the promo
  /// carousel's exact footprint — card, gap and page dots — so nothing on the
  /// page jumps when the real banners arrive.
  Widget _buildBannerSkeleton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Column(
        children: [
          Container(
            height: 130,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              2,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: index == 0 ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 78,
            child: _buildGridCard(
              context,
              imagePath: 'assets/images/lab.png',
              titleKey: 'cat_lab',
              id: 'lab',
              isActive: true,
              accentColor: const Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 78,
            child: _buildGridCard(
              context,
              imagePath: 'assets/images/doctor_bag.png',
              titleKey: 'cat_nursing',
              id: 'nursing',
              isActive: true,
              accentColor: const Color(0xFF0D9488),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 78,
            child: _buildGridCard(
              context,
              imagePath: 'assets/images/doctor.png',
              titleKey: 'cat_doctor',
              id: 'doctor',
              isActive: true,
              accentColor: const Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 78,
            child: _buildGridCard(
              context,
              imagePath: 'assets/images/medicine.png',
              titleKey: 'cat_pharmacy',
              id: 'pharmacy',
              isActive: true,
              accentColor: const Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 78,
            child: _buildGridCard(
              context,
              imagePath: 'assets/images/add.png',
              titleKey: 'cat_ambulance',
              id: 'ambulance',
              isActive: true,
              accentColor: const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 78,
            child: _buildGridCard(
              context,
              icon: Iconsax.health,
              titleKey: 'ai_assistant',
              id: 'ai_assistant',
              isActive: true,
              accentColor: const Color(0xFF06B6D4),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 78,
            child: _buildGridCard(
              context,
              icon: Iconsax.clock,
              titleKey: 'pill_reminder',
              id: 'pill_reminder',
              isActive: true,
              accentColor: const Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 78,
            child: _buildGridCard(
              context,
              imagePath: 'assets/images/xray.png',
              titleKey: 'cat_xray',
              id: 'xray',
              isActive: false,
              accentColor: const Color(0xFF6366F1),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 78,
            child: _buildGridCard(
              context,
              imagePath: 'assets/images/apps.png',
              titleKey: 'cat_more',
              id: 'more',
              isActive: true,
              accentColor: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard(
    BuildContext context, {
    String? imagePath,
    IconData? icon,
    required String titleKey,
    required String id,
    required bool isActive,
    Color accentColor = const Color(0xFF3B82F6),
  }) {
    assert(imagePath != null || icon != null, 'a grid card needs an image or an icon');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        if (!isActive) {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (context) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.getSurface(context),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Icon
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: imagePath != null
                            ? Image.asset(imagePath, fit: BoxFit.cover)
                            : Icon(icon, color: accentColor, size: 38),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Title
                    Text(
                      titleKey.tr(),
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextTitle(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Description from translations (e.g., desc_doctor)
                    Text(
                      'desc_$id'.tr(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.getTextTitle(context),
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Coming soon box
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFF3B82F6),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'coming_soon_msg'.tr(),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // OK Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'ok'.tr(),
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              );
            },
          );
        } else {
          if (id == 'lab') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AllLabsScreen(),
              ),
            );
          } else if (id == 'nursing') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NursingServicesScreen(),
              ),
            );
          } else if (id == 'doctor') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AllDoctorsScreen()),
            );
          } else if (id == 'pharmacy') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => PharmaciesScreen()),
            );
          } else if (id == 'ambulance') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SosScreen()),
            );
          } else if (id == 'ai_assistant') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AiSymptomCheckerScreen(),
              ),
            );
          } else if (id == 'pill_reminder') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PillReminderScreen(),
              ),
            );
          } else if (id == 'more') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AllCategoriesScreen(),
              ),
            );
          }
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            accentColor.withValues(alpha: 0.18),
                            const Color(0xFF1E293B),
                          ]
                        : [
                            accentColor.withValues(alpha: 0.12),
                            Colors.white,
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: accentColor.withValues(alpha: isDark ? 0.25 : 0.15),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: isDark ? 0.15 : 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Opacity(
                    opacity: isActive ? 1.0 : 0.55,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: imagePath != null
                          ? Image.asset(imagePath, fit: BoxFit.contain)
                          : Center(
                              child: Icon(
                                icon,
                                color: accentColor,
                                size: 28,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                titleKey.tr(),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Rabar',
                  color: isActive
                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                      : const Color(0xFF94A3B8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (!isActive)
            PositionedDirectional(
              top: -4,
              end: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  'coming_soon'.tr(),
                  style: const TextStyle(
                    fontFamily: 'Rabar',
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class OvalBottomBorderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 50,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
