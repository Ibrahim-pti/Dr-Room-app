import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../core/utils/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';

class AdminBannersScreen extends StatefulWidget {
  const AdminBannersScreen({super.key});

  @override
  State<AdminBannersScreen> createState() => _AdminBannersScreenState();
}

class _AdminBannersScreenState extends State<AdminBannersScreen> {
  List<dynamic> _banners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBanners();
  }

  Future<void> _fetchBanners() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.get('/admin/banners');
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _banners = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBanner(int id) async {
    try {
      final response = await ApiClient.delete('/admin/banners/$id');
      if (response.statusCode == 204) _fetchBanners();
    } catch (e) {
      debugPrint('Error deleting banner: $e');
    }
  }

  Future<void> _showAddBannerModal() async {
    File? selectedImage;
    final titleController = TextEditingController();
    bool isSubmitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.getBorder(context),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'زیادکردنی ڕیکلامی نوێ',
                    style: TextStyle(
                      color: AppColors.getTextTitle(context),
                      fontFamily: 'Rabar',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.getBackground(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.getBorder(context)),
                    ),
                    child: TextField(
                      controller: titleController,
                      style: TextStyle(
                        color: AppColors.getTextTitle(context),
                        fontFamily: 'Rabar',
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'ناونیشانی ڕیکلام (ئارەزوومەندانە)',
                        hintStyle: TextStyle(
                          color: AppColors.getTextSubtitle(context),
                          fontFamily: 'Rabar',
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final xfile = await picker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 50,
                        maxWidth: 1000,
                      );
                      if (xfile != null) {
                        setModalState(() => selectedImage = File(xfile.path));
                      }
                    },
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.getBackground(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: selectedImage != null
                              ? AppColors.primary
                              : AppColors.getBorder(context),
                          width: 1.5,
                        ),
                      ),
                      child: selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(selectedImage!, fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Iconsax.add_circle, size: 32, color: AppColors.primary),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'وێنەیەک هەڵبژێرە',
                                  style: TextStyle(
                                    color: AppColors.getTextSubtitle(context),
                                    fontFamily: 'Rabar',
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (selectedImage == null) return;
                              setModalState(() => isSubmitting = true);
                              final prefs = await SharedPreferences.getInstance();
                              final token = prefs.getString('auth_token');
                              var request = http.MultipartRequest(
                                'POST',
                                Uri.parse('${ApiClient.baseUrl}/admin/banners'),
                              );
                              request.headers['Authorization'] = 'Bearer $token';
                              request.headers['Accept'] = 'application/json';
                              request.fields['title'] = titleController.text;
                              request.files.add(
                                await http.MultipartFile.fromPath('image', selectedImage!.path),
                              );
                              var res = await request.send();
                              
                              if (ctx.mounted) {
                                setModalState(() => isSubmitting = false);
                              }
                              
                              if (res.statusCode == 201) {
                                if (!ctx.mounted) return;
                                Navigator.pop(ctx);
                                _fetchBanners();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'بڵاوکردنەوەی ڕیکلام',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Rabar', 
                                  fontSize: 16, 
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      margin: const EdgeInsets.only(left: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.getSurface(context),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.getTextTitle(context),
                        size: 20,
                      ),
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Iconsax.picture_frame, color: Color(0xFF3B82F6), size: 22),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ڕیکلامەکان',
                        style: TextStyle(
                          color: AppColors.getTextTitle(context),
                          fontFamily: 'Rabar',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_banners.length} active',
                        style: TextStyle(
                          color: AppColors.getTextSubtitle(context),
                          fontFamily: 'Rabar',
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showAddBannerModal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add, color: AppColors.primary, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            'نوێ',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontFamily: 'Rabar',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn().slideY(begin: -0.1, end: 0),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _banners.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.getTextSubtitle(context).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Iconsax.picture_frame,
                                  color: AppColors.getTextSubtitle(context),
                                  size: 48,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'هیچ ڕیکلامێک نییە',
                                style: TextStyle(
                                  color: AppColors.getTextTitle(context),
                                  fontFamily: 'Rabar',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'تائێستا هیچ بانەرێک بڵاونەکراوەتەوە',
                                style: TextStyle(
                                  color: AppColors.getTextSubtitle(context),
                                  fontFamily: 'Rabar',
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                        )
                      : RefreshIndicator(
                          onRefresh: _fetchBanners,
                          color: AppColors.primary,
                          backgroundColor: AppColors.getSurface(context),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 110),
                            itemCount: _banners.length,
                            itemBuilder: (context, index) {
                              final banner = _banners[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.getSurface(context),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    if (banner['image_path'] != null)
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                        child: Image.network(
                                          '${ApiClient.storageUrl}/${banner['image_path']}',
                                          height: 160,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) => Container(
                                            height: 160,
                                            color: AppColors.getBackground(context),
                                            child: Center(
                                              child: Icon(
                                                Icons.image_not_supported,
                                                color: AppColors.getBorder(context),
                                                size: 40,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              banner['title'] ?? 'بێ ناونیشان',
                                              style: TextStyle(
                                                color: AppColors.getTextTitle(context),
                                                fontFamily: 'Rabar',
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => _deleteBanner(banner['id']),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: AppColors.error.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Icon(
                                                Iconsax.trash,
                                                color: AppColors.error,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate(delay: Duration(milliseconds: index * 60)).fadeIn().slideY(begin: 0.1, end: 0);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
