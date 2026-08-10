import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../checkout/checkout_details_screen.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/providers/cart_provider.dart';

class NursingServicesScreen extends StatefulWidget {
  const NursingServicesScreen({super.key});

  @override
  State<NursingServicesScreen> createState() => _NursingServicesScreenState();
}

class _NursingServicesScreenState extends State<NursingServicesScreen> {
  final List<Map<String, dynamic>> _services = [
    {
      'titleKey': 'injection',
      'subtitleKey': 'injection_desc',
      'icon': Iconsax.health,
      'color': const Color(0xFF3B82F6),
      'selected': false,
    },
    {
      'titleKey': 'cannula',
      'subtitleKey': 'cannula_desc',
      'icon': Iconsax.activity,
      'color': const Color(0xFF10B981),
      'selected': false,
    },
    {
      'titleKey': 'wound_dressing',
      'subtitleKey': 'wound_desc',
      'icon': Icons.healing_outlined,
      'color': const Color(0xFFF59E0B),
      'selected': false,
    },
    {
      'titleKey': 'quick_care',
      'subtitleKey': 'quick_care_desc',
      'icon': Iconsax.heart,
      'color': const Color(0xFFEF4444),
      'selected': false,
    },
  ];

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
                                service['titleKey'].toString().tr(),
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.getTextTitle(context),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                service['subtitleKey'].toString().tr(),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.getTextSubtitle(context),
                                ),
                              ),
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
                              
                              for (var s in _services.where((s) => s['selected'] == true)) {
                                cart.addItem(CartItem(
                                  id: s['titleKey'],
                                  name: s['titleKey'].toString().tr(),
                                  price: 25.00, // Default price for nursing services
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
