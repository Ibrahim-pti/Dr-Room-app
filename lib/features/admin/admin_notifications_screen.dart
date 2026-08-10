import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/api_client.dart';
import '../../core/theme/app_colors.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.get('/admin/notifications');
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _notifications = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteNotification(int id) async {
    try {
      final response = await ApiClient.delete('/admin/notifications/$id');
      if (response.statusCode == 204) _fetchNotifications();
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _showAddNotificationModal() async {
    File? selectedImage;
    final titleController = TextEditingController();
    final messageController = TextEditingController();
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
              child: SingleChildScrollView(
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
                      'ناردنی نۆتیفیکەیشنی نوێ',
                      style: TextStyle(
                        color: AppColors.getTextTitle(context),
                        fontFamily: 'Rabar',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDarkInput(controller: titleController, hint: 'ناونیشانی ئاگادارکەرەوە', context: context),
                    const SizedBox(height: 12),
                    _buildDarkInput(controller: messageController, hint: 'نامەی ئاگادارکەرەوە', maxLines: 3, context: context),
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
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.getBackground(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selectedImage != null
                                ? const Color(0xFFF59E0B)
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
                                  const Icon(Iconsax.image, color: Color(0xFFF59E0B), size: 30),
                                  const SizedBox(height: 8),
                                  Text(
                                    'وێنە زیاد بکە (ئارەزوومەندانە)',
                                    style: TextStyle(
                                      color: AppColors.getTextSubtitle(context),
                                      fontFamily: 'Rabar',
                                      fontSize: 13,
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
                                if (titleController.text.isEmpty || messageController.text.isEmpty) return;
                                
                                setModalState(() => isSubmitting = true);
                                
                                final prefs = await SharedPreferences.getInstance();
                                final token = prefs.getString('auth_token');
                                var request = http.MultipartRequest(
                                  'POST',
                                  Uri.parse('${ApiClient.baseUrl}/admin/notifications'),
                                );
                                request.headers['Authorization'] = 'Bearer $token';
                                request.headers['Accept'] = 'application/json';
                                request.fields['title'] = titleController.text;
                                request.fields['message'] = messageController.text;
                                request.fields['type'] = 'general';
                                
                                if (selectedImage != null) {
                                  request.files.add(
                                    await http.MultipartFile.fromPath('image', selectedImage!.path),
                                  );
                                }
                                
                                var res = await request.send();
                                
                                if (ctx.mounted) {
                                  setModalState(() => isSubmitting = false);
                                }
                                
                                if (res.statusCode == 201) {
                                  if (!ctx.mounted) return;
                                  Navigator.pop(ctx);
                                  _fetchNotifications();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                          disabledBackgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.6),
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
                                  'ناردن',
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
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDarkInput({
    required TextEditingController controller,
    required String hint,
    required BuildContext context,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getBackground(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(
          color: AppColors.getTextTitle(context),
          fontFamily: 'Rabar',
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.getTextSubtitle(context),
            fontFamily: 'Rabar',
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
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
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Iconsax.notification, color: Color(0xFFF59E0B), size: 22),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ئاگادارکەرەوەکان',
                        style: TextStyle(
                          color: AppColors.getTextTitle(context),
                          fontFamily: 'Rabar',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_notifications.length} sent',
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
                    onTap: _showAddNotificationModal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.send_rounded, color: Color(0xFFF59E0B), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'ناردن',
                            style: TextStyle(
                              color: const Color(0xFFF59E0B),
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
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFF59E0B)))
                  : _notifications.isEmpty
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
                                  Iconsax.notification_bing,
                                  color: AppColors.getTextSubtitle(context),
                                  size: 48,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'هیچ ئاگادارکەرەوەیەک نییە',
                                style: TextStyle(
                                  color: AppColors.getTextTitle(context),
                                  fontFamily: 'Rabar',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'تائێستا هیچ نۆتیفیکەیشنێک نەنێردراوە',
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
                          onRefresh: _fetchNotifications,
                          color: const Color(0xFFF59E0B),
                          backgroundColor: AppColors.getSurface(context),
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 0, 24, 110),
                            itemCount: _notifications.length,
                            itemBuilder: (context, index) {
                              final notif = _notifications[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (notif['image_path'] != null)
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                        child: Image.network(
                                          '${ApiClient.storageUrl}/${notif['image_path']}',
                                          height: 130,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) => Container(
                                            height: 130,
                                            color: AppColors.getBackground(context),
                                            child: Center(
                                              child: Icon(
                                                Icons.image_not_supported,
                                                color: AppColors.getBorder(context),
                                                size: 32,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (notif['image_path'] == null)
                                            Container(
                                              width: 48,
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              child: const Icon(Iconsax.notification, color: Color(0xFFF59E0B), size: 24),
                                            ),
                                          if (notif['image_path'] == null) const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  notif['title'] ?? '',
                                                  style: TextStyle(
                                                    color: AppColors.getTextTitle(context),
                                                    fontFamily: 'Rabar',
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  notif['message'] ?? '',
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color: AppColors.getTextSubtitle(context),
                                                    fontFamily: 'Rabar',
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          GestureDetector(
                                            onTap: () => _deleteNotification(notif['id']),
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: AppColors.error.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Icon(Iconsax.trash, color: AppColors.error, size: 18),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate(delay: Duration(milliseconds: index * 60)).fadeIn().slideX(begin: 0.05, end: 0);
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
