import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/utils/api_client.dart';
import '../../core/providers/cart_provider.dart';
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
  bool _isUploading = false;
  List<Map<String, dynamic>> _labs = [];
  Map<String, dynamic>? _selectedLab;

  @override
  void initState() {
    super.initState();
    _fetchLabs();
  }

  Future<void> _fetchLabs() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.get('/labs');
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final list = (decoded['data'] as List? ?? []);
        if (list.isNotEmpty) {
          _labs = list.map((e) => Map<String, dynamic>.from(e)).toList();
          if (_labs.isNotEmpty) {
            _selectedLab = _labs.first;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading labs: $e');
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

  Future<void> _proceedToCheckout() async {
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

    setState(() => _isUploading = true);

    String? uploadedUrl;
    String? uploadedPath;

    try {
      final uploadRes = await ApiClient.uploadMultipart(
        '/upload/prescription',
        fileField: 'image',
        filePath: _imageFile!.path,
      );

      if (uploadRes.statusCode == 200) {
        final decoded = jsonDecode(uploadRes.body);
        if (decoded['success'] == true) {
          uploadedUrl = decoded['url'];
          uploadedPath = decoded['path'];
        }
      }
    } catch (e) {
      debugPrint('Error uploading prescription image to server: $e');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }

    if (!mounted) return;

    final cart = context.read<CartProvider>();
    cart.clearCart();
    cart.setServiceType('lab', extraFee: 0.0);

    final finalUrl = uploadedUrl ?? _imageFile?.path;
    final finalPath = uploadedPath ?? _imageFile?.path;

    cart.addItem(CartItem(
      id: 'prescription_${DateTime.now().millisecondsSinceEpoch}',
      name: 'prescription_order_name'.tr(),
      price: 0.0,
      quantity: 1,
      extraData: {
        'prescription_path': finalPath,
        'prescription_url': finalUrl,
        'prescription_image': finalUrl,
        'lab_id': _selectedLab!['id'],
        'lab_name': _selectedLab!['name'],
        'lab_user_id': _selectedLab!['user_id'] ?? _selectedLab!['id'],
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
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top Title & Description ──
                  Text(
                    'upload_your_doc'.tr(),
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'upload_doc_subtitle'.tr(),
                    style: const TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── 1. Upload Card / Preview ──
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _imageFile != null ? const Color(0xFF10B981) : borderColor,
                          width: _imageFile != null ? 2 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: _imageFile == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
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
                                const SizedBox(height: 16),
                                Text(
                                  'tap_to_capture_or_upload'.tr(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'jpg_png_pdf_hint'.tr(),
                                  style: const TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 12,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(
                                    _imageFile!,
                                    height: 240,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'change_image'.tr(),
                                      style: const TextStyle(
                                        fontFamily: 'Rabar',
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── 2. Select Laboratory (دەستنیشانکردنی تاقیگە) ──
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
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'دیاریکراوە',
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Laboratory List
                  if (_labs.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'هیچ تاقیگەیەک نەدۆزرایەوە',
                          style: TextStyle(fontFamily: 'Rabar', color: isDark ? Colors.white60 : Colors.black54),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _labs.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, idx) {
                        final lab = _labs[idx];
                        final isSelected = _selectedLab?['id'] == lab['id'];

                        return GestureDetector(
                          onTap: () => setState(() => _selectedLab = lab),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF2563EB).withValues(alpha: 0.06)
                                  : cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF2563EB) : borderColor,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: isSelected
                                      ? const Color(0xFF2563EB).withValues(alpha: 0.12)
                                      : Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Iconsax.hospital, color: Color(0xFF2563EB), size: 26),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        lab['name'] ?? '',
                                        style: TextStyle(
                                          fontFamily: 'Rabar',
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Icon(Iconsax.location, size: 13, color: const Color(0xFF64748B)),
                                          const SizedBox(width: 4),
                                          Text(
                                            lab['city'] ?? 'Erbil',
                                            style: const TextStyle(
                                              fontFamily: 'Rabar',
                                              fontSize: 12,
                                              color: Color(0xFF64748B),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                                          const SizedBox(width: 3),
                                          Text(
                                            '${lab['rating'] ?? 4.8}',
                                            style: const TextStyle(
                                              fontFamily: 'Rabar',
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF2563EB) : borderColor,
                                      width: 2,
                                    ),
                                    color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
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
              onPressed: _isUploading ? null : _proceedToCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isUploading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'خەریکی ناردنی وێنەیە بۆ سێرڤەر...',
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : Row(
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