import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../core/utils/api_client.dart';
import 'lab_order_method_screen.dart';
import 'lab_map_screen.dart';

class LabDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> lab;

  const LabDetailsScreen({super.key, required this.lab});

  @override
  State<LabDetailsScreen> createState() => _LabDetailsScreenState();
}

class _LabDetailsScreenState extends State<LabDetailsScreen> {
  late Map<String, dynamic> _labData;
  bool _isFavorite = false;
  List<Map<String, dynamic>> _tests = [];
  final Set<int> _selectedTestIds = {};
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  Timer? _autoPlayTimer;
  int _imagesCount = 4;
  int _selectedTabIndex = 0; // 0: ناساندن, 1: پشکنینەکان, 2: ئۆفەر و پاکێج
  YoutubePlayerController? _youtubeController;

  final List<Map<String, dynamic>> _packages = [
    {
      'id': 101,
      'name': 'پاکێجی پشکنینی گشتی (Full Body Checkup)',
      'desc': 'شاملی سەرەکیترین پشکنینەکانی خوێن (CBC)، چەوری، جگەر، گورچیلە و شەکرە',
      'original_price': 85000,
      'price': 55000,
      'discount': 35,
      'icon': Iconsax.health,
      'test_ids': [1, 2, 3, 5, 6],
    },
    {
      'id': 102,
      'name': 'پاکێجی ڤیتامین و ووزە (Vitamins & Energy)',
      'desc': 'پشکنینی وردی ڤیتامین D، ڤیتامین B12، ڕێژەی ئاسن و کانزاکانی جەستە',
      'original_price': 60000,
      'price': 42000,
      'discount': 30,
      'icon': Iconsax.activity,
      'test_ids': [4],
    },
    {
      'id': 103,
      'name': 'پاکێجی پاراستنی دڵ و چەوری (Cardiac & Lipid Care)',
      'desc': 'شاملی کۆلیسترۆڵ، چەوری سیانی (Triglycerides)، و پشکنینی سێ مانگی شەکرە',
      'original_price': 50000,
      'price': 35000,
      'discount': 30,
      'icon': Iconsax.heart,
      'test_ids': [2, 3],
    },
  ];

  @override
  void initState() {
    super.initState();
    _labData = Map<String, dynamic>.from(widget.lab);
    _initializeTests();
    _fetchLabDetails();
    _startAutoPlay();
    _initYoutubeVideo();
  }

  String _extractYoutubeId(String url) {
    if (url.contains('v=')) return url.split('v=')[1].split('&').first;
    if (url.contains('youtu.be/')) return url.split('youtu.be/')[1].split('?').first;
    if (url.contains('/embed/')) return url.split('/embed/')[1].split('?').first;
    return url;
  }

  void _initYoutubeVideo() {
    final rawUrl = _labData['youtube_url']?.toString() ?? 'https://www.youtube.com/watch?v=ScMzIvxBSi4';
    final videoId = _extractYoutubeId(rawUrl);
    
    _youtubeController = YoutubePlayerController.fromVideoId(
      videoId: videoId.isNotEmpty ? videoId : 'ScMzIvxBSi4',
      autoPlay: true,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        showControls: true,
        showVideoAnnotations: false,
        strictRelatedVideos: true,
        mute: false,
      ),
    );
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients && _imagesCount > 1) {
        final nextPage = (_currentImageIndex + 1) % _imagesCount;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    _youtubeController?.close();
    super.dispose();
  }

  void _initializeTests() {
    if (_labData['tests'] is List && (_labData['tests'] as List).isNotEmpty) {
      _tests = List<Map<String, dynamic>>.from(
        (_labData['tests'] as List).map((t) => Map<String, dynamic>.from(t)),
      );
    } else {
      // High quality fallback tests
      _tests = [
        {'id': 1, 'name': 'پشکنینی گشتی خوێن (CBC)', 'price': 10000, 'type': 'Blood Test', 'desc': 'Complete Blood Count'},
        {'id': 2, 'name': 'چەوری و کۆلیسترۆڵ (Lipid Profile)', 'price': 15000, 'type': 'Blood Test', 'desc': 'Cholesterol & Triglycerides'},
        {'id': 3, 'name': 'شەکرەی سێ مانگی (HbA1c)', 'price': 15000, 'type': 'Blood Test', 'desc': 'Glycated Hemoglobin'},
        {'id': 4, 'name': 'پشکنینی ڤیتامین دی (Vitamin D)', 'price': 20000, 'type': 'Vitamin Test', 'desc': '25-OH Vitamin D'},
        {'id': 5, 'name': 'کاری جگەر (Liver Function Test)', 'price': 18000, 'type': 'Liver Panel', 'desc': 'ALT, AST, Bilirubin'},
        {'id': 6, 'name': 'کاری گورچیلە (Kidney Function Test)', 'price': 12000, 'type': 'Kidney Panel', 'desc': 'Urea & Creatinine'},
      ];
    }
    // Select first test by default
    if (_tests.isNotEmpty) {
      _selectedTestIds.add(_tests[0]['id'] as int);
    }
  }

  Future<void> _fetchLabDetails() async {
    final labId = _labData['id'];
    if (labId == null) return;

    try {
      final response = await ApiClient.get('/labs/$labId');
      if (response.statusCode == 200 && mounted) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('data')) {
          setState(() {
            _labData = Map<String, dynamic>.from(decoded['data']);
            if (_labData['tests'] is List && (_labData['tests'] as List).isNotEmpty) {
              _tests = List<Map<String, dynamic>>.from(
                (_labData['tests'] as List).map((t) => Map<String, dynamic>.from(t)),
              );
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching lab details: $e');
    }
  }

  int get _totalPrice {
    int total = 0;
    for (final test in _tests) {
      if (_selectedTestIds.contains(test['id'])) {
        total += (test['price'] as num?)?.toInt() ?? 0;
      }
    }
    return total;
  }

  TextStyle _kStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = const Color(0xFF0F172A),
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'Rabar',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  String _tr(String key, BuildContext context) {
    final isKurdish = context.locale.languageCode == 'ckb' || context.locale.languageCode == 'ku';
    final isArabic = context.locale.languageCode == 'ar';

    switch (key) {
      case 'lab_details':
        if (isKurdish) return 'وردەکاریی تاقیگە';
        if (isArabic) return 'تفاصيل المختبر';
        return 'Lab Details';
      case 'about_lab':
        if (isKurdish) return 'دەربارەی تاقیگە';
        if (isArabic) return 'عن المختبر';
        return 'About Laboratory';
      case 'available_tests':
        if (isKurdish) return 'پشکنینە بەردەستەکان';
        if (isArabic) return 'الفحوصات المتاحة';
        return 'Available Tests';
      case 'select_tests':
        if (isKurdish) return 'هەڵبژاردنی پشکنین';
        if (isArabic) return 'اختيار الفحص';
        return 'Select Test';
      case 'open_now':
        if (isKurdish) return 'کراوەیە ئێستا';
        if (isArabic) return 'مفتوح الآن';
        return 'Open Now';
      case 'closed_now':
        if (isKurdish) return 'داخراوە';
        if (isArabic) return 'مغلق';
        return 'Closed';
      case 'discount':
        if (isKurdish) return 'داشکاندن';
        if (isArabic) return 'خصم';
        return 'OFF';
      case 'home_sample':
        if (isKurdish) return 'وەرگرتنی نموونە لە ماڵەوە';
        if (isArabic) return 'سحب العينات منزلياً';
        return 'Home Sample Collection';
      case 'same_day_result':
        if (isKurdish) return 'ئەنجام لە هەمان ڕۆژدا';
        if (isArabic) return 'النتيجة في نفس اليوم';
        return 'Same Day Result';
      case 'working_hours':
        if (isKurdish) return 'کاتی کارکردن';
        if (isArabic) return 'أوقات العمل';
        return 'Working Hours';
      case 'location_address':
        if (isKurdish) return 'ناونیشان و شوێن';
        if (isArabic) return 'العنوان والموقع';
        return 'Location & Address';
      case 'call':
        if (isKurdish) return 'پەیوەندی';
        if (isArabic) return 'اتصال';
        return 'Call';
      case 'chat':
        if (isKurdish) return 'چات';
        if (isArabic) return 'محادثة';
        return 'Chat';
      case 'directions':
        if (isKurdish) return 'نەخشە';
        if (isArabic) return 'الموقع';
        return 'Map';
      case 'add':
        if (isKurdish) return 'زیادکردن';
        if (isArabic) return 'إضافة';
        return 'Add';
      case 'selected':
        if (isKurdish) return 'هەڵبژێردرا';
        if (isArabic) return 'تم الاختيار';
        return 'Selected';
      case 'total':
        if (isKurdish) return 'کۆی گشتی:';
        if (isArabic) return 'المجموع:';
        return 'Total:';
      case 'continue_btn':
        if (isKurdish) return 'بەردەوام بە';
        if (isArabic) return 'المتابعة';
        return 'Continue';
      case 'currency':
        if (isKurdish) return 'د.ع';
        if (isArabic) return 'د.ع';
        return 'IQD';
      default:
        return key.tr();
    }
  }

  void _makePhoneCall(String? phone) async {
    final rawPhone = phone ?? _labData['phone']?.toString() ?? '07505556677';
    final cleanPhone = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri url = Uri.parse('tel:$cleanPhone');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url);
      }
    } catch (e) {
      debugPrint('Error making call: $e');
    }
  }

  void _openMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LabMapScreen(lab: _labData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = _labData['name'] ?? 'تاقیگەی پزیشکی';
    final String location = _labData['location'] ?? 'هەولێر - شەقامی پزیشکان';
    final String rating = '${_labData['rating'] ?? 4.8}';
    final bool isOpen = _labData['is_open'] == true;
    final discount = _labData['discount'];
    final String openingHours = _labData['opening_hours'] ?? '08:00 AM - 10:00 PM';
    final String aboutUs = _labData['about_us'] ??
        'تاقیگەیەکی پزیشکیی پێشکەوتووە لە پێناو دابینکردنی وردترین و خێراترین ئەنجامی پشکنینەکان بە نوێترین ئامێری پزیشکی و ستافێکی پسپۆڕ.';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 10, 20, _selectedTabIndex == 0 ? 40 : 130),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Hero Image Banner Carousel ──
                _buildHeroBanner(discount, isOpen),
                const SizedBox(height: 18),

                // ── 2. Lab Main Identity Card ──
                _buildIdentityCard(name, location, rating, openingHours),
                const SizedBox(height: 16),

                // ── 3. Quick Action Buttons (Call, Directions) ──
                _buildActionButtons(),
                const SizedBox(height: 22),

                // ── 4. Segmented Tab Bar (ناساندن / پشکنینەکان / ئۆفەر و پاکێج) ──
                _buildTabsHeader(),
                const SizedBox(height: 20),

                // ── 5. Dynamic Tab Content ──
                if (_selectedTabIndex == 0) ...[
                  // 📋 تاب ١: ناساندن و تایبەتمەندییەکان
                  _buildHighlightFeatures(),
                  const SizedBox(height: 18),
                  _buildAboutSection(aboutUs),
                  const SizedBox(height: 18),
                  _buildVideoSection(),
                ] else if (_selectedTabIndex == 1) ...[
                  // 🧪 تاب ٢: لیستی پشکنینە بەردەستەکان
                  _buildTestsSection(),
                ] else ...[
                  // 🎁 تاب ٣: پاکێج و ئۆفەرە داشکێنراوەکان
                  _buildPackagesSection(),
                ],
              ],
            ),
          ),

          // ── Sticky Bottom Checkout Bar (Only on Tests & Packages tabs) ──
          if (_selectedTabIndex != 0)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _buildBottomCheckoutBar(),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF8FAFC),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsetsDirectional.only(start: 16),
        child: Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Color(0xFF0F172A),
                size: 16,
              ),
            ),
          ),
        ),
      ),
      title: Text(
        _tr('lab_details', context),
        style: _kStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF0F172A),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 16),
          child: GestureDetector(
            onTap: () {
              setState(() => _isFavorite = !_isFavorite);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _isFavorite ? Icons.favorite_rounded : Iconsax.heart,
                color: _isFavorite ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
                size: 19,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBanner(dynamic discount, bool isOpen) {
    List<String> images = [];
    if (_labData['images'] is List && (_labData['images'] as List).isNotEmpty) {
      images = List<String>.from((_labData['images'] as List).map((e) => e.toString()));
    } else if (_labData['image'] != null && _labData['image'].toString().isNotEmpty) {
      images = [_labData['image'].toString(), 'assets/images/lab2.jpg', 'assets/images/lab3.jpg', 'assets/images/lab4.jpg'];
    } else {
      images = ['assets/images/laboratory.jpg', 'assets/images/lab2.jpg', 'assets/images/lab3.jpg', 'assets/images/lab4.jpg'];
    }

    _imagesCount = images.length;

    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Swipable Carousel
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (index) {
                setState(() => _currentImageIndex = index);
              },
              itemBuilder: (context, index) {
                final img = images[index];
                return Image.asset(
                  img,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: const Color(0xFFEFF6FF),
                    child: const Icon(Iconsax.hospital, color: Color(0xFF3B82F6), size: 48),
                  ),
                );
              },
            ),
          ),

          // 2. Bottom Gradient Shadow
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.0),
                      Colors.black.withValues(alpha: 0.5),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Discount Badge (Top Start)
          if (discount != null)
            PositionedDirectional(
              top: 14,
              start: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_offer_rounded, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '%$discount ${_tr('discount', context)}',
                      style: _kStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 4. Open/Closed Status (Top End)
          PositionedDirectional(
            top: 14,
            end: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isOpen
                    ? const Color(0xFFECFDF5).withValues(alpha: 0.95)
                    : const Color(0xFFF1F5F9).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isOpen ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOpen ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isOpen ? _tr('open_now', context) : _tr('closed_now', context),
                    style: _kStyle(
                      color: isOpen ? const Color(0xFF047857) : const Color(0xFF64748B),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 6. Animated Dots Indicator (Bottom Center)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (idx) {
                final isSel = idx == _currentImageIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isSel ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isSel ? Colors.white : Colors.white.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scaleXY(begin: 0.98);
  }

  Widget _buildIdentityCard(String name, String location, String rating, String hours) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name Row
          Text(
            name,
            style: _kStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),

          // Location & Rating Row
          Row(
            children: [
              const Icon(Iconsax.location, color: Color(0xFF3B82F6), size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  location,
                  style: _kStyle(
                    color: const Color(0xFF475569),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 14),
                    const SizedBox(width: 3),
                    Text(
                      rating,
                      style: _kStyle(
                        color: const Color(0xFFB45309),
                        fontSize: 11.5,
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
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05);
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Iconsax.call,
            label: _tr('call', context),
            color: const Color(0xFF3B82F6),
            bgColor: const Color(0xFFEFF6FF),
            onTap: () => _makePhoneCall(null),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Iconsax.map,
            label: _tr('directions', context),
            color: const Color(0xFF8B5CF6),
            bgColor: const Color(0xFFF5F3FF),
            onTap: _openMap,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 5),
            Text(
              label,
              style: _kStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabsHeader() {
    final tabs = [
      {'id': 0, 'title': 'ناساندن', 'icon': Iconsax.info_circle},
      {'id': 1, 'title': 'پشکنینەکان (${_tests.length})', 'icon': Iconsax.health},
      {'id': 2, 'title': 'ئۆفەر و پاکێج (${_packages.length})', 'icon': Icons.local_offer_rounded},
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: tabs.map((t) {
          final int id = t['id'] as int;
          final bool isSelected = _selectedTabIndex == id;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      t['icon'] as IconData,
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                      size: 16.5,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        t['title'] as String,
                        style: _kStyle(
                          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
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
        }).toList(),
      ),
    );
  }

  Widget _buildHighlightFeatures() {
    final highlights = [
      {
        'icon': Iconsax.document_text_1,
        'title': _tr('same_day_result', context),
        'desc': 'خێرا و مۆدێرن',
        'color': const Color(0xFF3B82F6),
      },
      {
        'icon': Iconsax.home_2,
        'title': _tr('home_sample', context),
        'desc': 'بەردەستە',
        'color': const Color(0xFF10B981),
      },
    ];

    return Row(
      children: highlights.map((h) {
        final color = h['color'] as Color;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(h['icon'] as IconData, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        h['title'] as String,
                        style: _kStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        h['desc'] as String,
                        style: _kStyle(
                          fontSize: 10.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAboutSection(String aboutUs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.info_circle, color: Color(0xFF3B82F6), size: 18),
              const SizedBox(width: 8),
              Text(
                _tr('about_lab', context),
                style: _kStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            aboutUs,
            style: _kStyle(
              fontSize: 13.5,
              color: const Color(0xFF475569),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSection() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 18,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: _youtubeController != null
                ? YoutubePlayer(
                    controller: _youtubeController!,
                    backgroundColor: Colors.black,
                  )
                : Container(
                    color: const Color(0xFF0F172A),
                    child: const Center(
                      child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTestsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Iconsax.health, color: Color(0xFF3B82F6), size: 18),
                const SizedBox(width: 8),
                Text(
                  '${_tr('available_tests', context)} (${_tests.length})',
                  style: _kStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            Text(
              '${_selectedTestIds.length} ${_tr('selected', context)}',
              style: _kStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3B82F6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _tests.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final test = _tests[index];
            final int testId = test['id'] as int;
            final bool isSelected = _selectedTestIds.contains(testId);
            final int price = (test['price'] as num?)?.toInt() ?? 10000;

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedTestIds.remove(testId);
                  } else {
                    _selectedTestIds.add(testId);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? const Color(0xFF3B82F6).withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Checkbox / Indicator icon
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                    const SizedBox(width: 14),

                    // Test Name & Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            test['name']?.toString() ?? 'پشکنین',
                            style: _kStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            test['desc']?.toString() ?? test['type']?.toString() ?? 'پشکنینی پزیشکی',
                            style: _kStyle(
                              fontSize: 11.5,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Price Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${NumberFormat('#,###').format(price)} ${_tr('currency', context)}',
                        style: _kStyle(
                          color: isSelected ? Colors.white : const Color(0xFF1E293B),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPackagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.local_offer_rounded, color: Color(0xFFEF4444), size: 18),
                const SizedBox(width: 8),
                Text(
                  'پاکێج و ئۆفەرە تایبەتەکان (${_packages.length})',
                  style: _kStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _packages.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final pkg = _packages[index];
            final List<int> testIds = List<int>.from(pkg['test_ids'] ?? []);
            final bool isAllSelected = testIds.isNotEmpty && testIds.every((id) => _selectedTestIds.contains(id));

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isAllSelected ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
                  width: isAllSelected ? 1.5 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isAllSelected
                        ? const Color(0xFF3B82F6).withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(pkg['icon'] as IconData, color: const Color(0xFF3B82F6), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    pkg['name'] as String,
                                    style: _kStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '%${pkg['discount']} داشکاندن',
                                    style: _kStyle(
                                      color: const Color(0xFFEF4444),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pkg['desc'] as String,
                              style: _kStyle(
                                fontSize: 11.5,
                                color: const Color(0xFF64748B),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Price Column
                      Row(
                        children: [
                          Text(
                            '${NumberFormat('#,###').format(pkg['price'])} ${_tr('currency', context)}',
                            style: _kStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            NumberFormat('#,###').format(pkg['original_price']),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF94A3B8),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ),

                      // Select Button
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            if (isAllSelected) {
                              _selectedTestIds.removeAll(testIds);
                            } else {
                              _selectedTestIds.addAll(testIds);
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAllSelected ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isAllSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded,
                              color: Colors.white,
                              size: 15,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isAllSelected ? 'هەڵبژێردرا' : 'هەڵبژاردنی پاکێج',
                              style: _kStyle(
                                color: Colors.white,
                                fontSize: 11.5,
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
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomCheckoutBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Total Price Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${_tr('total', context)} (${_selectedTestIds.length})',
                style: _kStyle(
                  color: const Color(0xFF64748B),
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    NumberFormat('#,###').format(_totalPrice),
                    style: _kStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _tr('currency', context),
                    style: _kStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Continue Button
          ElevatedButton(
            onPressed: () {
              if (_selectedTestIds.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'تکایە لانیکەم یەک پشکنین هەڵبژێرە',
                      style: _kStyle(color: Colors.white),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LabOrderMethodScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _tr('continue_btn', context),
                  style: _kStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.3);
  }
}
