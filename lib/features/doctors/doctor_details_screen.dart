import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/dr_room_fonts.dart';
import '../../core/utils/api_client.dart';
import 'doctor_details_about.dart';
import 'doctor_details_hero.dart';
import 'doctor_details_location.dart';
import 'doctor_details_models.dart';
import 'doctor_details_schedule.dart';
import 'doctor_details_services.dart';
import 'doctor_details_sheets.dart';
import 'doctor_details_video.dart';
import 'doctor_reviews_screen.dart';

class DoctorDetailsScreen extends StatefulWidget {
  final int doctorId;
  final String name;
  final String specialty;
  final String image;

  final Map<String, dynamic>? initialDoctor;

  const DoctorDetailsScreen({
    super.key,
    required this.doctorId,
    required this.name,
    required this.specialty,
    required this.image,
    this.initialDoctor,
  });

  @override
  State<DoctorDetailsScreen> createState() => _DoctorDetailsScreenState();
}

class _DoctorDetailsScreenState extends State<DoctorDetailsScreen> {
  static const double _carouselHeight = 258;
  static const double _heroHeight = _carouselHeight + 80;

  Map<String, dynamic>? _doctor;
  List<dynamic> _services = [];
  List<BookableDay> _days = [];
  bool _slotsLoading = true;

  bool _loading = true;
  bool _loadFailed = false;
  bool _isBooking = false;
  bool _bioExpanded = false;
  bool _videoStarted = false;

  int? _selectedServiceId;
  int _dayIndex = 0;
  int _timeIndex = -1;
  int _heroPage = 0;

  final _scrollController = ScrollController();
  final _scheduleKey = GlobalKey();
  final _heroPageController = PageController();

  VideoPlayerController? _videoController;
  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();

    final handedOver = widget.initialDoctor;
    if (handedOver != null) {
      _doctor = handedOver;
      _loading = false;
      _services = (handedOver['services'] as List?) ?? const [];
      _selectedServiceId = _services.isNotEmpty
          ? _asInt(_services.first['id'])
          : null;
      _startVideo();
    }

    if (handedOver == null) {
      _fetchDoctor();
    }
    _fetchAvailability();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _heroPageController.dispose();
    _videoController?.dispose();
    _youtubeController?.close();
    super.dispose();
  }

  // ─────────────────────────── data ───────────────────────────

  Future<void> _fetchDoctor() async {
    try {
      final response = await ApiClient.get('/doctors/${widget.doctorId}');
      if (response.statusCode == 200) {
        if (mounted) _applyDoctor(jsonDecode(response.body));
        return;
      }
    } catch (_) {}
    if (mounted && _doctor == null) {
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  void _applyDoctor(Map<String, dynamic> data) {
    setState(() {
      _doctor = data;
      _loading = false;
      _loadFailed = false;
      _services = (data['services'] as List?) ?? const [];
      _selectedServiceId ??= _services.isNotEmpty
          ? _asInt(_services.first['id'])
          : null;
    });
    _startVideo();
  }

  Future<void> _fetchAvailability() async {
    try {
      final response = await ApiClient.get(
        '/doctors/${widget.doctorId}/availability',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final days = <BookableDay>[];
        for (final raw in (data['days'] as List?) ?? const []) {
          final day = BookableDay.fromJson(Map<String, dynamic>.from(raw));
          if (day != null) days.add(day);
        }
        if (!mounted) return;
        setState(() {
          _days = days;
          _slotsLoading = false;
          if (_dayIndex >= _days.length) _dayIndex = 0;
          _timeIndex = -1;
        });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _slotsLoading = false);
  }

  List<Slot> get _slots => _days.isEmpty || _dayIndex >= _days.length
      ? const []
      : _days[_dayIndex].slots;

  // ─────────────────────── value helpers ───────────────────────

  static int? _asInt(dynamic v) =>
      v == null ? null : int.tryParse(v.toString());

  static double _asDouble(dynamic v) =>
      v == null ? 0 : double.tryParse(v.toString()) ?? 0;

  String get _doctorName {
    final locale = context.locale.languageCode;
    final localized = _doctor?['user']?['name_$locale']?.toString();
    if (localized != null && localized.trim().isNotEmpty)
      return localized.trim();
    return _doctor?['user']?['name']?.toString() ?? widget.name;
  }

  String get _doctorSpecialty {
    final locale = context.locale.languageCode;
    final localized = _doctor?['specialty_$locale']?.toString();
    if (localized != null && localized.isNotEmpty) return localized;
    final fallback = _doctor?['specialty']?.toString();
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return widget.specialty;
  }

  String get _doctorImage {
    final path = _doctor?['image_path']?.toString();
    if (path != null && path.isNotEmpty) return ApiClient.getImageUrl(path);
    return widget.image;
  }

  List<String> get _heroImages {
    final images = <String>{};
    if (_doctorImage.isNotEmpty) images.add(_doctorImage);
    for (final item in (_doctor?['gallery'] as List?) ?? const []) {
      final path = item.toString();
      if (path.isNotEmpty) images.add(ApiClient.getImageUrl(path));
    }
    return images.isEmpty ? [widget.image] : images.toList();
  }

  String _serviceName(Map service) {
    final locale = context.locale.languageCode;
    for (final key in [
      'name_$locale',
      'name_ckb',
      'name_en',
      'name_ar',
      'name',
    ]) {
      final value = service[key]?.toString();
      if (value != null && value.trim().isNotEmpty) return value;
    }
    return 'dd_service'.tr();
  }

  String _money(double price) {
    if (price <= 0) return 'free'.tr();
    return '${NumberFormat('#,###').format(price)} ${'dd_currency'.tr()}';
  }

  Map<String, dynamic>? get _selectedService {
    if (_selectedServiceId == null) return null;
    for (final s in _services) {
      if (_asInt(s['id']) == _selectedServiceId) {
        return Map<String, dynamic>.from(s as Map);
      }
    }
    return null;
  }

  double get _selectedPrice {
    final service = _selectedService;
    if (service != null) return _asDouble(service['price']);
    return _asDouble(_doctor?['consultation_fee']);
  }

  double get _selectedSaving {
    final service = _selectedService;
    if (service == null || service['has_discount'] != true) return 0;
    final saving =
        _asDouble(service['old_price']) - _asDouble(service['price']);
    return saving > 0 ? saving : 0;
  }

  DateTime? get _selectedDateTime =>
      _timeIndex >= 0 && _timeIndex < _slots.length
      ? _slots[_timeIndex].dateTime
      : null;

  ImageProvider _imageProvider(String path) {
    if (path.isEmpty) return const AssetImage('assets/images/doctor.png');
    if (path.startsWith('assets/')) return AssetImage(path);
    final url = path.startsWith('http') ? path : ApiClient.getImageUrl(path);
    return CachedNetworkImageProvider(url);
  }

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = date.difference(today).inDays;
    if (diff == 0) return 'dd_today'.tr();
    if (diff == 1) return 'dd_tomorrow'.tr();
    return _weekdayName(date);
  }

  String _weekdayName(DateTime date) => 'wd_${date.weekday}'.tr();
  String _monthName(DateTime date) => 'mo_${date.month}'.tr();

  String _fullDate(DateTime date) =>
      '${_weekdayName(date)} • ${date.day} ${_monthName(date)} ${date.year}';

  String _clock(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour < 12 ? 'am'.tr() : 'pm'.tr();
    return '$hour:$minute $period';
  }

  // ───────────────────────── booking ─────────────────────────

  void _scrollToSchedule() {
    final ctx = _scheduleKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      alignment: 0.1,
    );
  }

  Future<void> _onBookPressed() async {
    if (_selectedDateTime == null) {
      _scrollToSchedule();
      _toast('dd_select_time_first'.tr(), AppColors.warning);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      showDoctorLoginPrompt(context);
      return;
    }
    _showSummarySheet();
  }

  Future<void> _submitBooking(StateSetter refreshSheet) async {
    final slot = _selectedDateTime;
    if (slot == null) return;

    _isBooking = true;
    refreshSheet(() {});

    var booked = false;
    var slotGone = false;
    try {
      final body = <String, dynamic>{
        'doctor_id': widget.doctorId,
        'appointment_date': DateFormat('yyyy-MM-dd HH:mm:ss').format(slot),
        'type': 'in_person',
        if (_selectedServiceId != null) 'service_id': _selectedServiceId,
      };

      final response = await ApiClient.post('/appointments', body: body);
      booked = response.statusCode == 200 || response.statusCode == 201;
      slotGone = response.statusCode == 409;
    } catch (_) {
      booked = false;
    }

    if (!mounted) return;
    _isBooking = false;

    if (booked) {
      Navigator.pop(context);
      _toast('dd_booked'.tr(), AppColors.success);
      setState(() => _timeIndex = -1);
      _fetchAvailability();
    } else if (slotGone) {
      Navigator.pop(context);
      _toast('dd_slot_taken'.tr(), AppColors.warning);
      _fetchAvailability();
    } else {
      refreshSheet(() {});
      _toast('dd_book_failed'.tr(), AppColors.error);
    }
  }

  void _toast(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _callDoctor() async {
    final phone = _doctor?['phone']?.toString();
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _showSummarySheet() {
    final slot = _selectedDateTime;
    if (slot == null) return;

    showBookingSummarySheet(
      context: context,
      doctorName: _doctorName,
      service: _selectedService,
      slot: slot,
      price: _selectedPrice,
      saving: _selectedSaving,
      isBooking: _isBooking,
      serviceName: _serviceName,
      money: _money,
      fullDate: _fullDate,
      clock: _clock,
      asDouble: _asDouble,
      onConfirm: _submitBooking,
    );
  }

  // ───────────────────────── video ─────────────────────────

  String? get _videoUrl {
    final url = _doctor?['video_url']?.toString();
    return (url == null || url.isEmpty) ? null : url;
  }

  bool get _isYoutube {
    final url = _videoUrl;
    if (url == null) return false;
    return _doctor?['video_type'] == 'youtube' ||
        url.contains('youtube.com') ||
        url.contains('youtu.be');
  }

  String _youtubeId(String url) {
    if (url.contains('v=')) return url.split('v=')[1].split('&').first;
    if (url.contains('youtu.be/'))
      return url.split('youtu.be/')[1].split('?').first;
    if (url.contains('/embed/'))
      return url.split('/embed/')[1].split('?').first;
    return url;
  }

  void _startVideo() {
    final url = _videoUrl;
    if (url == null || _videoStarted || !mounted) return;

    if (_isYoutube) {
      final id = _youtubeId(url);
      if (id.isEmpty) return;
      _youtubeController = YoutubePlayerController.fromVideoId(
        videoId: id,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          showVideoAnnotations: false,
          strictRelatedVideos: true,
        ),
      );
    } else {
      final full = url.startsWith('http') ? url : ApiClient.getImageUrl(url);
      _videoController = VideoPlayerController.networkUrl(Uri.parse(full))
        ..initialize()
            .then((_) {
              _videoController?.setLooping(true);
              _videoController?.play();
              if (mounted) setState(() {});
            })
            .catchError((_) {});
    }
    setState(() => _videoStarted = true);
  }

  // ───────────────────── location helpers ─────────────────────

  double? get _latitude =>
      double.tryParse(_doctor?['latitude']?.toString() ?? '');
  double? get _longitude =>
      double.tryParse(_doctor?['longitude']?.toString() ?? '');
  bool get _hasLocation => _latitude != null && _longitude != null;

  Future<void> _openInMaps() async {
    final lat = _latitude;
    final lng = _longitude;
    if (lat == null || lng == null) return;

    final label = Uri.encodeComponent(
      _doctor?['clinic_name']?.toString().trim().isNotEmpty == true
          ? _doctor!['clinic_name'].toString()
          : _doctorName,
    );
    final uri = Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }
    await launchUrl(
      Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng'),
      mode: LaunchMode.externalApplication,
    );
  }

  void _openReviews() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorReviewsScreen(
          doctorId: widget.doctorId,
          doctorName: _doctorName,
          rating: _asDouble(_doctor?['rating']).toStringAsFixed(1),
        ),
      ),
    );
  }

  // ───────────────────────── build ─────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = AppColors.getBackground(context);

    return Scaffold(
      backgroundColor: background,
      body: _loadFailed && _doctor == null
          ? _buildErrorState()
          : CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                DoctorDetailsHero(
                  isDark: isDark,
                  carouselHeight: _carouselHeight,
                  heroHeight: _heroHeight,
                  doctorId: widget.doctorId,
                  doctorName: _doctorName,
                  doctorSpecialty: _doctorSpecialty,
                  doctorImage: _doctorImage,
                  rating: _asDouble(_doctor?['rating']),
                  heroImages: _heroImages,
                  heroPage: _heroPage,
                  heroPageController: _heroPageController,
                  onPageChanged: (i) => setState(() => _heroPage = i),
                  onBack: () => Navigator.pop(context),
                  imageProvider: _imageProvider,
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      _loading && _doctor == null
                          ? _buildSkeleton(isDark)
                          : _buildSections(isDark),
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: _doctor == null && _loading
          ? null
          : _buildBottomBar(isDark),
    );
  }

  List<Widget> _buildSections(bool isDark) {
    final locale = context.locale.languageCode;

    var bio = _doctor?['bio_$locale']?.toString().trim();
    if (bio == null || bio.isEmpty) {
      bio = _doctor?['bio']?.toString().trim() ?? '';
    }

    final sections = <Widget>[
      DoctorDetailsAbout(
        isDark: isDark,
        bio: bio,
        bioExpanded: _bioExpanded,
        onToggleBio: () => setState(() => _bioExpanded = !_bioExpanded),
        rating: _asDouble(_doctor?['rating']),
        reviews: _asInt(_doctor?['total_reviews']) ?? 0,
        experienceYears: _asInt(_doctor?['experience_years']) ?? 0,
        phone: _doctor?['phone']?.toString().trim() ?? '',
        onCallDoctor: _callDoctor,
        onOpenReviews: _openReviews,
      ),
    ];

    if (_videoUrl != null) {
      sections
        ..add(const SizedBox(height: 22))
        ..add(
          DoctorDetailsVideo(
            videoStarted: _videoStarted,
            videoController: _videoController,
            youtubeController: _youtubeController,
            onStartVideo: _startVideo,
            imageProvider: _imageProvider,
            doctorImage: _doctorImage,
          ),
        );
    }

    sections
      ..add(const SizedBox(height: 24))
      ..add(
        DoctorDetailsServices(
          isDark: isDark,
          services: _services,
          selectedServiceId: _selectedServiceId,
          onServiceSelected: (id) => setState(() => _selectedServiceId = id),
          serviceName: _serviceName,
          money: _money,
        ),
      )
      ..add(const SizedBox(height: 24))
      ..add(
        DoctorDetailsSchedule(
          isDark: isDark,
          slotsLoading: _slotsLoading,
          days: _days,
          dayIndex: _dayIndex,
          timeIndex: _timeIndex,
          onDaySelected: (i) => setState(() {
            _dayIndex = i;
            _timeIndex = -1;
          }),
          onTimeSelected: (i) => setState(() => _timeIndex = i),
          dayLabel: _dayLabel,
          monthName: _monthName,
          clock: _clock,
          scheduleKey: _scheduleKey,
        ),
      );

    var address = _doctor?['address_$locale']?.toString().trim();
    if (address == null || address.isEmpty) {
      address = _doctor?['address']?.toString().trim() ?? '';
    }

    var clinic = _doctor?['clinic_name_$locale']?.toString().trim();
    if (clinic == null || clinic.isEmpty) {
      clinic = _doctor?['clinic_name']?.toString().trim() ?? '';
    }

    if (_hasLocation || address.isNotEmpty || clinic.isNotEmpty) {
      sections
        ..add(const SizedBox(height: 24))
        ..add(
          DoctorDetailsLocation(
            isDark: isDark,
            doctorId: widget.doctorId,
            clinicName: clinic,
            address: address,
            latitude: _latitude,
            longitude: _longitude,
            onOpenInMaps: _openInMaps,
          ),
        );
    }

    return sections
        .animate(interval: 40.ms)
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.06, end: 0, curve: Curves.easeOut);
  }

  // ── bottom bar ──

  Widget _buildBottomBar(bool isDark) {
    final ready = _selectedDateTime != null;
    final price = _selectedPrice;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        border: Border(top: BorderSide(color: AppColors.getDivider(context))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'total_price'.tr(),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppColors.getTextSubtitle(context),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_selectedSaving > 0) ...[
                      Text(
                        _money(_asDouble(_selectedService?['old_price'])),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textLight,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: AppColors.textLight,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      _money(price),
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _onBookPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ready
                        ? AppColors.primary
                        : AppColors.primary.withValues(alpha: 0.5),
                    foregroundColor: Colors.white,
                    elevation: ready ? 6 : 0,
                    shadowColor: AppColors.primary.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    'dd_book_now'.tr(),
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── loading / error ──

  List<Widget> _buildSkeleton(bool isDark) {
    Widget bar(double height, double widthFactor) => FractionallySizedBox(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.getSurfaceSecondary(context),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    return [
          bar(86, 1),
          const SizedBox(height: 24),
          bar(20, 0.4),
          const SizedBox(height: 12),
          bar(90, 1),
          const SizedBox(height: 24),
          bar(20, 0.5),
          const SizedBox(height: 12),
          bar(70, 1),
          const SizedBox(height: 12),
          bar(70, 1),
        ]
        .animate(onPlay: (c) => c.repeat())
        .fadeIn(duration: 700.ms)
        .then()
        .fadeOut(duration: 700.ms, begin: 0.4);
  }

  Widget _buildErrorState() {
    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: AppColors.getTextTitle(context),
              ),
            ),
          ),
          const Spacer(),
          Icon(Iconsax.cloud_cross, size: 56, color: AppColors.textLight),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'dd_load_failed'.tr(),
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                height: 1.7,
                color: AppColors.getTextSubtitle(context),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _loading = true;
                _loadFailed = false;
              });
              _fetchDoctor();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'dd_retry'.tr(),
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}
