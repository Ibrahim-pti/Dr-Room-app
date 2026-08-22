import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/api_client.dart';
import '../../core/utils/translation_helper.dart';
import '../../core/theme/app_colors.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  File? _selectedImage;
  String _selectedType = 'general';
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _types = [
    {'key': 'general', 'label': 'گشتی 📢', 'color': Color(0xFF3B82F6)},
    {'key': 'promo', 'label': 'داشکاندن 🎁', 'color': Color(0xFFEC4899)},
    {'key': 'alert', 'label': 'ئاگاداری ⚠️', 'color': Color(0xFFF59E0B)},
    {'key': 'system', 'label': 'سیستەم ⚙️', 'color': Color(0xFF10B981)},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _sendNotification() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تکایە ناونیشانی ئاگادارکردنەوە بنووسە',
            style: TextStyle(fontFamily: 'Rabar'),
          ),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تکایە دەقی پەیامەکە بنووسە',
            style: TextStyle(fontFamily: 'Rabar'),
          ),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiClient.baseUrl}/admin/notifications'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.fields['title'] = title;
      request.fields['message'] = message;
      request.fields['type'] = _selectedType;

      // Optional background translation
      try {
        final trFields = await TranslationHelper.translateFields({
          'title': title,
          'message': message,
        }).timeout(const Duration(seconds: 3));

        if (trFields.isNotEmpty) {
          request.fields['title_en'] = trFields['title']?['en'] ?? '';
          request.fields['title_ar'] = trFields['title']?['ar'] ?? '';
          request.fields['message_en'] = trFields['message']?['en'] ?? '';
          request.fields['message_ar'] = trFields['message']?['ar'] ?? '';
        }
      } catch (e) {
        debugPrint('Translation skipped: $e');
      }

      if (_selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', _selectedImage!.path),
        );
      }

      final streamedRes = await request.send().timeout(const Duration(seconds: 15));
      final res = await http.Response.fromStream(streamedRes);

      if (mounted) {
        setState(() => _isSubmitting = false);

        if (res.statusCode >= 200 && res.statusCode < 300) {
          _titleController.clear();
          _messageController.clear();
          setState(() {
            _selectedImage = null;
            _selectedType = 'general';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'ئاگادارکردنەوەکە بە سەرکەوتوویی بۆ هەمووان نێردرا 🎉',
                    style: TextStyle(fontFamily: 'Rabar', fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              backgroundColor: Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ناردن سەرکەوتوو نەبوو (${res.statusCode})',
                style: const TextStyle(fontFamily: 'Rabar'),
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'هەڵە ڕوویدا لە پەیوەندی: $e',
              style: const TextStyle(fontFamily: 'Rabar'),
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(context),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            size: 20,
            color: AppColors.getTextTitle(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ناردنی ئاگادارکردنەوە',
          style: TextStyle(
            color: AppColors.getTextTitle(context),
            fontFamily: 'Rabar',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF3B82F6),
                    const Color(0xFF1D4ED8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Iconsax.notification_bing,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ناردنی نۆتیفیکەیشنی ڕاستەوخۆ',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Rabar',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'پەیامەکەت ڕاستەوخۆ دەگاتە مۆبایلی هەموو بەکارهێنەران',
                          style: TextStyle(
                            color: Colors.white70,
                            fontFamily: 'Rabar',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.1, end: 0),

            const SizedBox(height: 24),

            // Type Selector
            const Text(
              'جۆری ئاگادارکردنەوە',
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _types.map((type) {
                  final isSelected = _selectedType == type['key'];
                  final Color typeColor = type['color'];
                  return Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        setState(() => _selectedType = type['key']);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? typeColor
                              : AppColors.getSurface(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? typeColor
                                : AppColors.getBorder(context),
                            width: 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: typeColor.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : [],
                        ),
                        child: Text(
                          type['label'],
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppColors.getTextTitle(context),
                            fontFamily: 'Rabar',
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 22),

            // Title Field
            const Text(
              'ناونیشانی ئاگادارکردنەوە',
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.getBorder(context)),
              ),
              child: TextField(
                controller: _titleController,
                style: TextStyle(
                  color: AppColors.getTextTitle(context),
                  fontFamily: 'Rabar',
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'نموونە: داشکاندنی نوێ لە پشکنینەکان',
                  hintStyle: TextStyle(
                    color: AppColors.getTextSubtitle(context),
                    fontFamily: 'Rabar',
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(Iconsax.edit_2, color: Color(0xFF3B82F6), size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),

            const SizedBox(height: 20),

            // Message Field
            const Text(
              'دەقی پەیامەکە',
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.getBorder(context)),
              ),
              child: TextField(
                controller: _messageController,
                maxLines: 4,
                style: TextStyle(
                  color: AppColors.getTextTitle(context),
                  fontFamily: 'Rabar',
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'دەقی پەیام و زانیارییەکان لێرە بنووسە...',
                  hintStyle: TextStyle(
                    color: AppColors.getTextSubtitle(context),
                    fontFamily: 'Rabar',
                    fontSize: 13,
                  ),
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 54),
                    child: Icon(Iconsax.message_text, color: Color(0xFF3B82F6), size: 20),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),

            const SizedBox(height: 20),

            // Image Upload Section
            const Text(
              'وێنەی ئاگادارکردنەوە (ئارەزوومەندانە)',
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: _selectedImage != null ? 180 : 100,
                decoration: BoxDecoration(
                  color: AppColors.getSurface(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    style: BorderStyle.solid,
                    width: 1.5,
                  ),
                ),
                child: _selectedImage != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.file(
                              _selectedImage!,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedImage = null),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Iconsax.image, color: Color(0xFF3B82F6), size: 32),
                          const SizedBox(height: 8),
                          Text(
                            'کلیک بکە بۆ دیاریکردنی وێنە',
                            style: TextStyle(
                              color: AppColors.getTextSubtitle(context),
                              fontFamily: 'Rabar',
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Live Preview Card
            if (_titleController.text.isNotEmpty || _messageController.text.isNotEmpty) ...[
              const Text(
                'پێشبینینی نۆتیفیکەیشن (Preview)',
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A)),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => const Icon(
                            Icons.notifications_active_rounded,
                            color: Color(0xFF3B82F6),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _titleController.text.isEmpty
                                      ? 'ناونیشانی ئاگادارکردنەوە'
                                      : _titleController.text,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Rabar',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Text(
                                'Dr-Room',
                                style: TextStyle(
                                  color: Color(0xFF60A5FA),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (_messageController.text.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              _messageController.text,
                              style: const TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontFamily: 'Rabar',
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.1, end: 0),
              const SizedBox(height: 24),
            ],

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _sendNotification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                  disabledBackgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.6),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'ناردنی ئاگادارکردنەوە بۆ هەمووان',
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Rabar',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}