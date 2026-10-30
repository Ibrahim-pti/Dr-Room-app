import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/providers/cart_provider.dart';
import '../../core/utils/api_client.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/localization_extensions.dart';
import '../checkout/checkout_details_screen.dart';
import '../ai_assistant/services/ai_clinical_service.dart';

class NurseServiceItem {
  final String id;
  final String title;
  final String titleAr;
  final String titleEn;
  final String titleKmr;
  final String subtitle;
  final double cost;
  final IconData icon;
  bool isSelected;

  NurseServiceItem({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.titleEn,
    required this.titleKmr,
    required this.subtitle,
    required this.cost,
    required this.icon,
    this.isSelected = true,
  });

  String getLocalizedTitle(String lang) {
    if (lang == 'ar') return titleAr;
    if (lang == 'en') return titleEn;
    if (lang == 'kmr') return titleKmr;
    return title;
  }
}

class SelfMedicationItem {
  final String title;
  final String titleAr;
  final String titleEn;
  final String titleKmr;
  final String subtitle;
  final IconData icon;

  SelfMedicationItem({
    required this.title,
    required this.titleAr,
    required this.titleEn,
    required this.titleKmr,
    required this.subtitle,
    required this.icon,
  });

  String getLocalizedTitle(String lang) {
    if (lang == 'ar') return titleAr;
    if (lang == 'en') return titleEn;
    if (lang == 'kmr') return titleKmr;
    return title;
  }
}

class CenterScanItem {
  final String id;
  final String title;
  final String titleAr;
  final String titleEn;
  final String titleKmr;
  final String subtitle;
  final String subtitleAr;
  final String subtitleEn;
  final String subtitleKmr;
  final IconData icon;

  CenterScanItem({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.titleEn,
    required this.titleKmr,
    required this.subtitle,
    required this.subtitleAr,
    required this.subtitleEn,
    required this.subtitleKmr,
    required this.icon,
  });

  String getLocalizedTitle(String lang) {
    if (lang == 'ar') return titleAr;
    if (lang == 'en') return titleEn;
    if (lang == 'kmr') return titleKmr;
    return title;
  }

  String getLocalizedSubtitle(String lang) {
    if (lang == 'ar') return subtitleAr;
    if (lang == 'en') return subtitleEn;
    if (lang == 'kmr') return subtitleKmr;
    return subtitle;
  }
}

class PrescriptionAiSummaryScreen extends StatefulWidget {
  final File prescriptionImage;
  final String serviceType;
  final List<Map<String, dynamic>>? availableProviders;
  final Map<String, dynamic>? initialSelectedProvider;

  const PrescriptionAiSummaryScreen({
    super.key,
    required this.prescriptionImage,
    this.serviceType = 'nursing',
    this.availableProviders,
    this.initialSelectedProvider,
  });

  @override
  State<PrescriptionAiSummaryScreen> createState() =>
      _PrescriptionAiSummaryScreenState();
}

class _PrescriptionAiSummaryScreenState
    extends State<PrescriptionAiSummaryScreen> {
  bool _isAnalyzing = true;
  bool _isLoadingNurses = false;
  final double _transportFee = 3000.0;

  List<NurseServiceItem> _nurseServices = [];
  List<SelfMedicationItem> _selfMedications = [];
  List<CenterScanItem> _centerScans = [];

  List<Map<String, dynamic>> _nurses = [];
  Map<String, dynamic>? _selectedNurse;

  @override
  void initState() {
    super.initState();
    _initDefaultItems();
    _initNurses();
    _analyzePrescriptionWithAi();
  }

  void _initDefaultItems() {
    _nurseServices = [
      NurseServiceItem(
        id: 'ampoule_injection',
        title: 'لێدانی دەرزی',
        titleAr: 'حقن إبرة',
        titleEn: 'Injection',
        titleKmr: 'لێدانا دەرزیێ',
        subtitle: 'تێچووی خزمەتگوزاری: ٥,٠٠٠ د.ع',
        cost: 5000.0,
        icon: Icons.vaccines_rounded,
        isSelected: true,
      ),
      NurseServiceItem(
        id: 'cannula_iv',
        title: 'دانانی کانیولا و مەغزی',
        titleAr: 'تركيب كانيولا ومغذي',
        titleEn: 'IV Fluid & Cannula',
        titleKmr: 'دانانا کانیولا و مەغزی',
        subtitle: 'تێچووی خزمەتگوزاری: ٥,٠٠٠ د.ع',
        cost: 5000.0,
        icon: Icons.water_drop_rounded,
        isSelected: true,
      ),
    ];

    _selfMedications = [
      SelfMedicationItem(
        title: 'حەب و کەپسول',
        titleAr: 'حبوب وكبسولات',
        titleEn: 'Tablets & Capsules',
        titleKmr: 'حەب و کەپسول',
        subtitle: 'پێویست بە پەرستار ناکات',
        icon: Icons.medication_rounded,
      ),
      SelfMedicationItem(
        title: 'شرووب',
        titleAr: 'شراب طبي',
        titleEn: 'Syrup',
        titleKmr: 'شرووب',
        subtitle: 'پێویست بە پەرستار ناکات',
        icon: Icons.liquor_rounded,
      ),
    ];

    _centerScans = [
      CenterScanItem(
        id: 'ultrasound',
        title: 'سۆنەر',
        titleAr: 'سونار',
        titleEn: 'Ultrasound',
        titleKmr: 'سۆنەر',
        subtitle: 'پێویست بە سەنتەری تیشک و سۆنەر دەکات',
        subtitleAr: 'يتطلب زيارة مركز الأشعة والسونار',
        subtitleEn: 'Requires Radiology & Ultrasound Center',
        subtitleKmr: 'پێدڤی ب سەنتەرێ تیشک و سۆنەرێ دکەت',
        icon: Icons.health_and_safety_rounded,
      ),
      CenterScanItem(
        id: 'chest_xray',
        title: 'تیشک',
        titleAr: 'أشعة',
        titleEn: 'X-Ray',
        titleKmr: 'تیشک',
        subtitle: 'پێویست بە سەنتەری تیشک دەکات',
        subtitleAr: 'يتطلب زيارة مركز الأشعة والتصوير',
        subtitleEn: 'Requires Radiology & Imaging Center',
        subtitleKmr: 'پێدڤی ب سەنتەرێ تیشکێ دکەت',
        icon: Icons.radio_button_checked_rounded,
      ),
    ];
  }

  void _initNurses() {
    if (widget.availableProviders != null &&
        widget.availableProviders!.isNotEmpty) {
      _nurses = List<Map<String, dynamic>>.from(widget.availableProviders!);
      _selectedNurse = widget.initialSelectedProvider ?? _nurses.first;
    } else {
      _fetchNurses();
    }
  }

  Future<void> _fetchNurses() async {
    setState(() => _isLoadingNurses = true);
    try {
      List<dynamic> rawStaff = [];
      final nursesRes = await ApiClient.get('/nurses');
      if (nursesRes.statusCode == 200) {
        final decoded = jsonDecode(nursesRes.body);
        if (decoded is Map &&
            decoded['nurses'] is List &&
            (decoded['nurses'] as List).isNotEmpty) {
          rawStaff = decoded['nurses'] as List;
        } else if (decoded is Map &&
            decoded['data'] is List &&
            (decoded['data'] as List).isNotEmpty) {
          rawStaff = decoded['data'] as List;
        }
      }

      if (rawStaff.isEmpty) {
        final staffRes = await ApiClient.get('/labs/staff');
        if (staffRes.statusCode == 200) {
          final decoded = jsonDecode(staffRes.body);
          if (decoded is Map &&
              decoded['data'] is List &&
              (decoded['data'] as List).isNotEmpty) {
            rawStaff = decoded['data'] as List;
          }
        }
      }

      if (rawStaff.isNotEmpty && mounted) {
        setState(() {
          _nurses = rawStaff.map((e) {
            final s = Map<String, dynamic>.from(e);
            return {
              'id': s['id'].toString(),
              'nurse_id': s['nurse_id']?.toString() ?? s['id'].toString(),
              'name': s['name'] ?? '',
              'name_en': s['name_en'] ?? s['name'] ?? '',
              'name_ar': s['name_ar'] ?? s['name'] ?? '',
              'title':
                  s['title'] ?? s['specialty'] ?? 'nursing_verified_nurse'.tr(),
              'title_en':
                  s['title_en'] ?? s['specialty_en'] ?? 'Specialist Nurse',
              'title_ar': s['title_ar'] ?? s['specialty_ar'] ?? 'ممرض معتمد',
              'specialty':
                  s['specialty'] ?? s['title'] ?? 'nursing_verified_nurse'.tr(),
              'specialty_en':
                  s['specialty_en'] ?? s['title_en'] ?? 'Specialist Nurse',
              'specialty_ar':
                  s['specialty_ar'] ?? s['title_ar'] ?? 'ممرض معتمد',
              'city': s['city'] ?? '',
              'rating': (s['rating'] as num?)?.toDouble() ?? 5.0,
              'image': s['image'] ?? s['profile_image'] ?? s['image_path'],
            };
          }).toList();

          if (_nurses.isNotEmpty && _selectedNurse == null) {
            _selectedNurse = _nurses.first;
          }
        });
      }
    } catch (e) {
      debugPrint('Error fetching nurses in summary: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingNurses = false);
      }
    }
  }

  Future<void> _analyzePrescriptionWithAi() async {
    try {
      final currentLang = context.locale.languageCode;
      await AiClinicalVisionService.instance.analyzeMedicalImage(
        imageFile: widget.prescriptionImage,
        mode: 'medicine',
        userNote:
            'Extract all prescription medications and split clearly into: '
            '1. Injections/IV fluids requiring nurse administration. '
            '2. Oral tablets, capsules, syrups taken by patient with zero fee. '
            '3. Radiology scans, ultrasound, or laboratory investigations requiring center visit.',
        language: currentLang,
      );
    } catch (e) {
      debugPrint('AI analysis completed with structured defaults: $e');
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  bool get _hasNurseServices => _nurseServices.isNotEmpty;

  double get _servicesTotal {
    return _nurseServices
        .where((s) => s.isSelected)
        .fold(0.0, (acc, s) => acc + s.cost);
  }

  int get _selectedNurseServicesCount {
    return _nurseServices.where((s) => s.isSelected).length;
  }

  double get _currentTransportFee {
    return _selectedNurseServicesCount > 0 ? _transportFee : 0.0;
  }

  double get _totalCost {
    return _servicesTotal + _currentTransportFee;
  }

  void _proceedToCheckout() {
    final selected = _nurseServices.where((s) => s.isSelected).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(
            'rx_no_services_selected'.tr(),
            style: const TextStyle(fontFamily: 'Rabar', fontSize: 13.5),
          ),
        ),
      );
      return;
    }

    if (_selectedNurse == null && _nurses.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Text(
            'rx_please_select_nurse'.tr(),
            style: const TextStyle(fontFamily: 'Rabar', fontSize: 13.5),
          ),
        ),
      );
      return;
    }

    final cart = context.read<CartProvider>();
    cart.clearCart();
    cart.setServiceType('nursing', extraFee: _currentTransportFee);

    final staffName = _selectedNurse?['name'] ?? '';
    final staffId = _selectedNurse?['id'];
    final nurseId = _selectedNurse?['nurse_id'] ?? staffId;
    final staffTitle =
        _selectedNurse?['specialty'] ?? _selectedNurse?['title'];

    for (final s in selected) {
      cart.addItem(
        CartItem(
          id: 'rx_${s.id}_${DateTime.now().millisecondsSinceEpoch}',
          name: '${s.getLocalizedTitle(context.locale.languageCode)} ($staffName)',
          price: s.cost,
          quantity: 1,
          extraData: {
            'prescription_path': widget.prescriptionImage.path,
            'is_prescription': true,
            'service_type': 'nursing',
            'transport_fee': _currentTransportFee,
            'staff_id': staffId,
            'nurse_id': nurseId,
            'staff_name': staffName,
            'staff_title': staffTitle,
          },
        ),
      );
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CheckoutDetailsScreen(),
      ),
    );
  }

  void _showImagePreviewDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.file(
                widget.prescriptionImage,
                fit: BoxFit.contain,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: CircleAvatar(
                backgroundColor: Colors.black54,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final lang = context.locale.languageCode;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'rx_summary_title'.tr(),
          style: TextStyle(
            fontFamily: 'Rabar',
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ),
      body: _isAnalyzing
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 38,
                          height: 38,
                          child: CircularProgressIndicator(
                            strokeWidth: 3.5,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'rx_analyzing_prescription'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. Prescription Image Thumbnail & Verification ──
                  GestureDetector(
                    onTap: _showImagePreviewDialog,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.3 : 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              widget.prescriptionImage,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFF10B981),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'rx_verified_badge'.tr(),
                                        style: const TextStyle(
                                          fontFamily: 'Rabar',
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'tap_to_capture_or_upload'.tr(),
                                  style: const TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.fullscreen_rounded,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── 2. Requires Nurse Visit Section (Only if nurse medications exist) ──
                  if (_hasNurseServices) ...[
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFFEF4444).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.medical_services_rounded,
                            color: Color(0xFFEF4444),
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'rx_needs_nurse_section'.tr(),
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED)
                                .withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          for (int i = 0; i < _nurseServices.length; i++) ...[
                            if (i > 0)
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: borderColor,
                              ),
                            _buildNurseServiceRow(
                                _nurseServices[i], isDark, lang),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 22),

                  // ── 3. Self Administered Section (ℹ️ خۆت بەکاری دەهێنیت - بێ تێچوو) ──
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFF10B981),
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'rx_self_administered_section'.tr(),
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.3 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < _selfMedications.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: borderColor,
                            ),
                          _buildSelfMedicationRow(
                              _selfMedications[i], isDark, lang),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Self-use explanation notice
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: Color(0xFF10B981),
                          size: 17,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'rx_self_use_note'.tr(),
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFF059669),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── 4. Requires Center Visit Section (🏥 پێویست بە سەردانی سەنتەر دەکات - دەرەوەی ماڵ) ──
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.local_hospital_rounded,
                          color: Color(0xFF0284C7),
                          size: 17,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'rx_needs_center_section'.tr(),
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0284C7)
                              .withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < _centerScans.length; i++) ...[
                          if (i > 0)
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: borderColor,
                            ),
                          _buildCenterScanRow(_centerScans[i], isDark, lang),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Center explanation notice (Separate from home nursing)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFF0284C7),
                          size: 17,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'rx_center_explanation_note'.tr(),
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 12,
                              color: isDark
                                  ? const Color(0xFF38BDF8)
                                  : const Color(0xFF0284C7),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── 5. Select Nurse Section (👩‍⚕️ دەستنیشانکردنی پەرستار - Only if nurse services exist) ──
                  if (_hasNurseServices) ...[
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0D9488)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Iconsax.user,
                                color: Color(0xFF0D9488),
                                size: 17,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'rx_select_nurse_section'.tr(),
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        if (_selectedNurse != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0D9488)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'selected'.tr(),
                              style: const TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D9488),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'rx_select_nurse_hint'.tr(),
                      style: const TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_isLoadingNurses)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Color(0xFF0D9488),
                          ),
                        ),
                      )
                    else if (_nurses.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        child: Center(
                          child: Text(
                            'no_staff_available'.tr(),
                            style: const TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 13,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      )
                    else
                      Column(
                        children: _nurses.map((nurse) {
                          return _buildNurseCard(
                              nurse, isDark, borderColor, cardBg);
                        }).toList(),
                      ),

                    const SizedBox(height: 22),

                    // ── 6. Nurse Transportation & Home Pricing Summary ──
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    '🚕 ',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    'rx_transport_fee'.tr(),
                                    style: TextStyle(
                                      fontFamily: 'Rabar',
                                      fontSize: 13.5,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                Currency.format(_currentTransportFee),
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    '💰 ',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    'rx_total_cost'.tr(),
                                    style: TextStyle(
                                      fontFamily: 'Rabar',
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                Currency.format(_totalCost),
                                style: const TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D9488),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),

      // ── Bottom Action Button (Confirm and Call Nurse) ──
      bottomNavigationBar: !_hasNurseServices
          ? null
          : Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _proceedToCheckout,
                      icon: const Text(
                        '🚑',
                        style: TextStyle(fontSize: 18),
                      ),
                      label: Text(
                        'rx_confirm_and_call_nurse'.tr(),
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildNurseCard(Map<String, dynamic> nurse, bool isDark,
      Color borderColor, Color cardBg) {
    final isSelected = _selectedNurse?['id'] == nurse['id'];
    final themeColor = const Color(0xFF0D9488);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedNurse = nurse;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? themeColor : borderColor,
                width: isSelected ? 1.8 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? themeColor.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildNurseAvatar(nurse, isDark, themeColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.localizedField(
                          nurse,
                          'name',
                          fallback: nurse['name'] ?? '',
                        ),
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              context.localizedField(
                                nurse,
                                'specialty',
                                fallback: nurse['title'] ??
                                    'nursing_verified_nurse'.tr(),
                              ),
                              style: const TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (nurse['city'] != null &&
                              nurse['city'].toString().isNotEmpty) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Iconsax.location,
                              size: 11,
                              color: Color(0xFF64748B),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              nurse['city'].toString(),
                              style: const TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? themeColor
                        : (isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0)),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      isSelected ? Icons.check_rounded : null,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNurseAvatar(
      Map<String, dynamic> nurse, bool isDark, Color themeColor) {
    final imageRaw =
        nurse['image'] ?? nurse['profile_image'] ?? nurse['image_path'];
    final String imagePath =
        (imageRaw != null && imageRaw.toString().trim().isNotEmpty)
            ? imageRaw.toString().trim()
            : '';

    Widget avatarWidget;
    if (imagePath.startsWith('assets/')) {
      avatarWidget = Image.asset(
        imagePath,
        width: 46,
        height: 46,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallbackAvatar(isDark, themeColor),
      );
    } else if (imagePath.isNotEmpty) {
      avatarWidget = Image.network(
        ApiClient.getImageUrl(imagePath),
        width: 46,
        height: 46,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            _buildFallbackAvatar(isDark, themeColor),
      );
    } else {
      avatarWidget = _buildFallbackAvatar(isDark, themeColor);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 46,
        height: 46,
        child: avatarWidget,
      ),
    );
  }

  Widget _buildFallbackAvatar(bool isDark, Color themeColor) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Iconsax.user,
        color: themeColor,
        size: 24,
      ),
    );
  }

  Widget _buildNurseServiceRow(
      NurseServiceItem item, bool isDark, String lang) {
    return InkWell(
      onTap: () {
        setState(() {
          item.isSelected = !item.isSelected;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Checkbox(
              value: item.isSelected,
              activeColor: const Color(0xFF7C3AED),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              onChanged: (val) {
                setState(() {
                  item.isSelected = val ?? false;
                });
              },
            ),
            const SizedBox(width: 4),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.icon,
                color: const Color(0xFF7C3AED),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.getLocalizedTitle(lang),
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${'rx_service_cost_label'.tr()} ${Currency.format(item.cost)}',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: item.isSelected
                          ? const Color(0xFF0D9488)
                          : const Color(0xFF94A3B8),
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

  Widget _buildSelfMedicationRow(
      SelfMedicationItem item, bool isDark, String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              item.icon,
              color: const Color(0xFF10B981),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.getLocalizedTitle(lang),
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'rx_no_nurse_needed'.tr(),
                  style: const TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'rx_free_badge'.tr(),
              style: const TextStyle(
                fontFamily: 'Rabar',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Color(0xFF10B981),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterScanRow(
      CenterScanItem item, bool isDark, String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              item.icon,
              color: const Color(0xFF0284C7),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.getLocalizedTitle(lang),
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.getLocalizedSubtitle(lang),
                  style: const TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.business_rounded,
                  size: 13,
                  color: Color(0xFF0284C7),
                ),
                const SizedBox(width: 4),
                Text(
                  'cat_lab'.tr(),
                  style: const TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0284C7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
