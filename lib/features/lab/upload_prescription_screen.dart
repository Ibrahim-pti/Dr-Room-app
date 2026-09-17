import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/utils/api_client.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/utils/currency.dart';
import '../checkout/checkout_details_screen.dart';

class UploadPrescriptionScreen extends StatefulWidget {
  const UploadPrescriptionScreen({super.key});

  @override
  State<UploadPrescriptionScreen> createState() => _UploadPrescriptionScreenState();
}

class _UploadPrescriptionScreenState extends State<UploadPrescriptionScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  List<Map<String, dynamic>> _labs = [];
  List<Map<String, dynamic>> _staff = [];

  Map<String, dynamic>? _selectedLab;
  Map<String, dynamic>? _selectedStaff;

  @override
  void initState() {
    super.initState();
    _fetchLabsAndStaff();
  }

  Future<void> _fetchLabsAndStaff() async {
    setState(() => _isLoading = true);
    try {
      final resList = await Future.wait([
        ApiClient.get('/labs'),
        ApiClient.get('/labs/staff'),
      ]);

      final labsRes = resList[0];
      final staffRes = resList[1];

      if (labsRes.statusCode == 200) {
        final decoded = jsonDecode(labsRes.body);
        final list = (decoded['data'] as List? ?? []);
        if (list.isNotEmpty) {
          _labs = list.map((e) => Map<String, dynamic>.from(e)).toList();
          if (_labs.isNotEmpty) {
            _selectedLab = _labs.first;
          }
        }
      }

      if (staffRes.statusCode == 200) {
        final decoded = jsonDecode(staffRes.body);
        final list = (decoded['data'] as List? ?? []);
        if (list.isNotEmpty) {
          _staff = list.map((e) => Map<String, dynamic>.from(e)).toList();
        }
      }
    } catch (e) {
      debugPrint('Error loading labs or staff: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'upload_prescription'.tr(),
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Iconsax.gallery, color: Color(0xFF2563EB), size: 22),
                ),
                title: Text(
                  'choose_gallery'.tr(),
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 6),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Iconsax.camera, color: Color(0xFF10B981), size: 22),
                ),
                title: Text(
                  'camera'.tr(),
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      final XFile? image = await _picker.pickImage(source: source, imageQuality: 85);
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    }
  }

  void _proceedToCheckout() {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            'please_upload_image_first'.tr(),
            style: const TextStyle(fontFamily: 'Rabar', fontSize: 13.5),
          ),
        ),
      );
      return;
    }

    if (_selectedLab == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Text(
            'please_select_lab_first'.tr(),
            style: const TextStyle(fontFamily: 'Rabar', fontSize: 13.5),
          ),
        ),
      );
      return;
    }

    final cart = context.read<CartProvider>();
    cart.clearCart();

    final visitFee = _selectedStaff != null
        ? ((_selectedStaff!['visit_fee'] ?? _selectedStaff!['fee']) as num?)?.toDouble() ?? 5000.0
        : 5000.0;

    cart.setServiceType('lab', extraFee: visitFee);
    cart.addItem(CartItem(
      id: 'prescription_${DateTime.now().millisecondsSinceEpoch}',
      name: 'prescription_order_name'.tr(),
      price: 0.0,
      quantity: 1,
      extraData: {
        'prescription_path': _imageFile?.path,
        'lab_id': _selectedLab!['id'],
        'lab_name': _selectedLab!['name'],
        'staff_id': _selectedStaff?['id'],
        'staff_name': _selectedStaff?['name'] ?? 'auto_assign_staff'.tr(),
        'visit_fee': visitFee,
        'is_prescription': true,
      },
    ));

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CheckoutDetailsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : const Color(0xFF0F172A), size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'upload_prescription'.tr(),
          style: TextStyle(
            fontFamily: 'Rabar',
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Instructions
                  Text(
                    'upload_your_doc'.tr(),
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'upload_doc_subtitle'.tr(),
                    style: const TextStyle(
                      fontFamily: 'Rabar',
                      color: Color(0xFF64748B),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── 1. Upload Prescription Card ──
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 230,
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: _imageFile == null ? borderColor : const Color(0xFF2563EB),
                          width: _imageFile == null ? 1.5 : 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        image: _imageFile != null
                            ? DecorationImage(
                                image: FileImage(_imageFile!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _imageFile == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Iconsax.camera,
                                    color: Color(0xFF2563EB),
                                    size: 38,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'tap_to_capture_or_upload'.tr(),
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'jpg_png_pdf_hint'.tr(),
                                  style: const TextStyle(
                                    fontFamily: 'Rabar',
                                    color: Color(0xFF94A3B8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            )
                          : Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.edit, size: 16, color: Color(0xFF2563EB)),
                                      const SizedBox(width: 8),
                                      Text(
                                        'change_image'.tr(),
                                        style: const TextStyle(
                                          fontFamily: 'Rabar',
                                          color: Color(0xFF2563EB),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── 2. Select Laboratory (تاقیگەی مەبەست) ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'select_lab_step'.tr(),
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'select_lab_subtitle'.tr(),
                            style: const TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      if (_selectedLab != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'دیاریکراوە',
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Laboratory List Horizontal Scroll
                  SizedBox(
                    height: 110,
                    child: _labs.isEmpty
                        ? Center(
                            child: Text(
                              'هیچ تاقیگەیەک نەدۆزرایەوە',
                              style: TextStyle(fontFamily: 'Rabar', color: isDark ? Colors.white60 : Colors.black54),
                            ),
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _labs.length,
                            separatorBuilder: (_, _) => const SizedBox(width: 12),
                            itemBuilder: (context, idx) {
                              final lab = _labs[idx];
                              final isSelected = _selectedLab?['id'] == lab['id'];

                              return GestureDetector(
                                onTap: () => setState(() => _selectedLab = lab),
                                child: Container(
                                  width: 220,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF2563EB) : borderColor,
                                      width: isSelected ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isSelected
                                            ? const Color(0xFF2563EB).withValues(alpha: 0.12)
                                            : Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Iconsax.hospital, color: Color(0xFF2563EB), size: 24),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              lab['name'] ?? '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontFamily: 'Rabar',
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              lab['city'] ?? 'Erbil',
                                              style: const TextStyle(
                                                fontFamily: 'Rabar',
                                                fontSize: 11,
                                                color: Color(0xFF64748B),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                                                const SizedBox(width: 3),
                                                Text(
                                                  '${lab['rating'] ?? 4.8}',
                                                  style: const TextStyle(
                                                    fontFamily: 'Rabar',
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB), size: 20),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 28),

                  // ── 3. Select Sampling Staff (دەستنیشانکردنی ستاف) ──
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'select_staff_sample'.tr(),
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'select_staff_subtitle'.tr(),
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Option A: Auto Assign
                  GestureDetector(
                    onTap: () => setState(() => _selectedStaff = null),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _selectedStaff == null
                            ? const Color(0xFF2563EB).withValues(alpha: 0.08)
                            : cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _selectedStaff == null ? const Color(0xFF2563EB) : borderColor,
                          width: _selectedStaff == null ? 1.8 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Iconsax.magic_star, color: Color(0xFF10B981), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'auto_assign_staff'.tr(),
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'تاقیگە خێراترین و نزیکترین پسپۆڕ دەنێرێتە ماڵەوە (کرێ: ٥,٠٠٠ د.ع)',
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_selectedStaff == null)
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB), size: 20),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Option B: Specific Staff List
                  ..._staff.map((st) {
                    final isSelected = _selectedStaff?['id'] == st['id'];
                    final fee = (st['fee'] ?? st['visit_fee'] ?? 5000.0) as num;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedStaff = st),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF2563EB).withValues(alpha: 0.08)
                                : cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF2563EB) : borderColor,
                              width: isSelected ? 1.8 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                child: const Icon(Iconsax.profile_circle, color: Color(0xFF2563EB), size: 26),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      st['name'] ?? '',
                                      style: TextStyle(
                                        fontFamily: 'Rabar',
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${st['title'] ?? 'پسپۆڕی تاقیگە'} • ${st['lab_name'] ?? ''}',
                                      style: const TextStyle(
                                        fontFamily: 'Rabar',
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  Currency.format(fee),
                                  style: const TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB), size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),

      // ── Bottom Continue Button ──
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _proceedToCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.tick_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'continue_checkout'.tr(),
                    style: const TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}