import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../checkout/checkout_details_screen.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/utils/api_client.dart';

class NursingServicesScreen extends StatefulWidget {
  final int? nurseId;
  final Map<String, dynamic>? nurse;

  const NursingServicesScreen({
    super.key,
    this.nurseId,
    this.nurse,
  });

  @override
  State<NursingServicesScreen> createState() => _NursingServicesScreenState();
}

class _NursingServicesScreenState extends State<NursingServicesScreen> {
  final List<Map<String, dynamic>> _services = [];

  @override
  void initState() {
    super.initState();
    _initServices();
    _fetchDynamicCategories();
  }

  Future<void> _fetchDynamicCategories() async {
    try {
      final res = await ApiClient.get('/service-categories?scope=nursing');
      if (res.statusCode == 200 && mounted) {
        final List list = jsonDecode(res.body);
        final nurseFee = widget.nurse != null && widget.nurse!['fee'] != null
            ? (double.tryParse(widget.nurse!['fee'].toString()) ?? 25000.0)
            : 25000.0;

        for (final cat in list) {
          final id = 'cat_${cat['id']}';
          final name = cat['name'] ?? '';
          final nameEn = cat['name_en'] ?? '';
          final nameAr = cat['name_ar'] ?? '';

          // Check if already in standard list
          final exists = _services.any((s) => s['title'] == name || s['id'] == id);
          if (!exists && name.toString().isNotEmpty) {
            setState(() {
              _services.add({
                'id': id,
                'titleKey': null,
                'title': name,
                'title_en': nameEn,
                'title_ar': nameAr,
                'subtitleKey': null,
                'subtitle': 'خزمەتگوزاری پەرستاری',
                'icon': Iconsax.health,
                'color': const Color(0xFF0D9488),
                'price': nurseFee,
                'selected': false,
              });
            });
          }
        }
      }
    } catch (_) {}
  }

  void _initServices() {
    final nurse = widget.nurse;
    final nurseFee = nurse != null && nurse['fee'] != null
        ? (double.tryParse(nurse['fee'].toString()) ?? 25000.0)
        : 25000.0;

    // Standard base services
    _services.addAll([
      {
        'id': 'injection',
        'titleKey': 'injection',
        'title': 'دەرزی لێدان',
        'subtitleKey': 'injection_desc',
        'subtitle': 'دەرزی ماسولکە، دەمار یان ژێر پێست',
        'icon': Iconsax.health,
        'color': const Color(0xFF3B82F6),
        'price': nurseFee,
        'selected': false,
      },
      {
        'id': 'cannula',
        'titleKey': 'cannula',
        'title': 'دانانی کانیۆلا',
        'subtitleKey': 'cannula_desc',
        'subtitle': 'دانان و چاودێریکردنی کانیۆلای دەمار',
        'icon': Iconsax.activity,
        'color': const Color(0xFF10B981),
        'price': nurseFee,
        'selected': false,
      },
      {
        'id': 'wound_dressing',
        'titleKey': 'wound_dressing',
        'title': 'پانسیمان و پێچانەوەی برین',
        'subtitleKey': 'wound_desc',
        'subtitle': 'پاککردنەوە و پێچانەوەی برین و دوای نەشتەرگەری',
        'icon': Icons.healing_outlined,
        'color': const Color(0xFFF59E0B),
        'price': nurseFee,
        'selected': false,
      },
      {
        'id': 'quick_care',
        'titleKey': 'quick_care',
        'title': 'چاودێری خێرا',
        'subtitleKey': 'quick_care_desc',
        'subtitle': 'پشکنینی گشتی و چاودێری نیشانە سەرەکییەکان',
        'icon': Iconsax.heart,
        'color': const Color(0xFFEF4444),
        'price': nurseFee,
        'selected': false,
      },
    ]);

    // If the nurse provided custom services from profile, add them!
    if (nurse != null && nurse['custom_services'] is List) {
      final customList = nurse['custom_services'] as List;
      for (int i = 0; i < customList.length; i++) {
        final cs = customList[i];
        if (cs is Map && (cs['name'] != null && cs['name'].toString().isNotEmpty)) {
          final customPrice = cs['price'] != null
              ? (double.tryParse(cs['price'].toString()) ?? nurseFee)
              : nurseFee;
          
          _services.add({
            'id': 'custom_${i}_${cs['name']}',
            'titleKey': null,
            'title': cs['name'].toString(),
            'title_en': cs['name_en'],
            'title_ar': cs['name_ar'],
            'subtitleKey': null,
            'subtitle': cs['description']?.toString().isNotEmpty == true
                ? cs['description'].toString()
                : 'خزمەتگوزاری تایبەتی پەرستار',
            'icon': Iconsax.verify,
            'color': const Color(0xFF0D9488),
            'price': customPrice,
            'selected': false,
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int selectedCount = _services.where((s) => s['selected']).length;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'nursing_services'.tr(),
          style: GoogleFonts.poppins(
            color: AppColors.getTextTitle(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'what_do_you_need'.tr(),
                  style: GoogleFonts.poppins(
                    color: AppColors.getTextTitle(context),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ).animate().fadeIn().slideX(begin: -0.1, end: 0),
                const SizedBox(height: 8),
                Text(
                  'select_nursing_services'.tr(),
                  style: GoogleFonts.poppins(
                    color: AppColors.getTextSubtitle(context),
                    fontSize: 15,
                    height: 1.5,
                  ),
                ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _services.length,
              itemBuilder: (context, index) {
                final service = _services[index];
                final isSelected = service['selected'] as bool;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      service['selected'] = !isSelected;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsetsDirectional.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
                        width: 2,
                      ),
                              ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: service['color'].withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            service['icon'],
                            color: service['color'],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service['titleKey'] != null
                                    ? service['titleKey'].toString().tr()
                                    : (service['title'] ?? ''),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.getTextTitle(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                service['subtitleKey'] != null
                                    ? service['subtitleKey'].toString().tr()
                                    : (service['subtitle'] ?? ''),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.getTextSubtitle(context),
                                ),
                              ),
                              if (service['price'] != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  '${(service['price'] as num).toInt()} د.ع',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0D9488),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFCBD5E1),
                              width: 2,
                            ),
                            color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
                          ),
                          child: isSelected
                              ? Icon(Icons.check, size: 14, color: AppColors.getSurface(context))
                              : null,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: (200 + index * 100).ms).slideY(begin: 0.1, end: 0),
                );
              },
            ),
          ),
          
          // Bottom Container
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.getSurface(context),
                borderRadius: const BorderRadiusDirectional.only(
                topStart: Radius.circular(32),
                topEnd: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'selected_items'.tr(),
                        style: GoogleFonts.poppins(
                          color: AppColors.getTextSubtitle(context),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '$selectedCount ${'services_count'.tr()}',
                        style: GoogleFonts.poppins(
                          color: AppColors.getTextTitle(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    height: 56,
                    width: 160,
                    child: ElevatedButton(
                      onPressed: selectedCount > 0
                          ? () {
                              final cart = context.read<CartProvider>();
                              cart.clearCart();
                              cart.setServiceType('Nursing Services', extraFee: 0.0);
                              
                              final chosenNurseId = widget.nurse?['id'] ?? widget.nurseId;

                              for (var s in _services.where((s) => s['selected'] == true)) {
                                final itemName = s['titleKey'] != null
                                    ? s['titleKey'].toString().tr()
                                    : (s['title'] ?? 'خزمەتگوزاری پەرستاری');
                                final itemPrice = (s['price'] as num?)?.toDouble() ?? 25000.0;

                                cart.addItem(CartItem(
                                  id: s['id']?.toString() ?? s['titleKey']?.toString() ?? 'nurse_service',
                                  name: itemName,
                                  price: itemPrice,
                                  extraData: chosenNurseId != null ? {'nurse_id': chosenNurseId} : null,
                                ));
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CheckoutDetailsScreen(),
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        disabledBackgroundColor: const Color(0xFF94A3B8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'continue_btn'.tr(),
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.getSurface(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
