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
import 'admin_app_bar.dart';

class AdminArticlesScreen extends StatefulWidget {
  const AdminArticlesScreen({super.key});

  @override
  State<AdminArticlesScreen> createState() => _AdminArticlesScreenState();
}

class _AdminArticlesScreenState extends State<AdminArticlesScreen> {
  List<dynamic> _articles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchArticles();
  }

  Future<void> _fetchArticles() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.get('/admin/articles');
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _articles = jsonDecode(response.body);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteArticle(int id) async {
    try {
      final response = await ApiClient.delete('/admin/articles/$id');
      if (response.statusCode == 204) _fetchArticles();
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _showAddArticleModal() async {
    File? selectedImage;
    final titleController = TextEditingController();
    final contentController = TextEditingController();
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
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
                      'نووسینی وتاری نوێ',
                      style: TextStyle(
                        color: AppColors.getTextTitle(context),
                        fontFamily: 'Rabar',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDarkInput(
                      controller: titleController,
                      hint: 'ناونیشانی وتار',
                      context: context,
                    ),
                    const SizedBox(height: 12),
                    _buildDarkInput(
                      controller: contentController,
                      hint: 'ناوەڕۆکی وتار',
                      maxLines: 5,
                      context: context,
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
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.getBackground(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: selectedImage != null
                                ? const Color(0xFF10B981)
                                : AppColors.getBorder(context),
                            width: 1.5,
                          ),
                        ),
                        child: selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Iconsax.add_circle,
                                    color: Color(0xFF10B981),
                                    size: 30,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'وێنەی بەرگ زیاد بکە (ئارەزوومەندانە)',
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
                                if (titleController.text.isEmpty ||
                                    contentController.text.isEmpty) return;
                                
                                setModalState(() => isSubmitting = true);
                                
                                final prefs = await SharedPreferences.getInstance();
                                final token = prefs.getString('auth_token');
                                var request = http.MultipartRequest(
                                  'POST',
                                  Uri.parse('${ApiClient.baseUrl}/admin/articles'),
                                );
                                request.headers['Authorization'] = 'Bearer $token';
                                request.headers['Accept'] = 'application/json';
                                request.fields['title'] = titleController.text;
                                request.fields['content'] = contentController.text;
                                if (selectedImage != null) {
                                  request.files.add(
                                    await http.MultipartFile.fromPath(
                                      'image',
                                      selectedImage!.path,
                                    ),
                                  );
                                }
                                var res = await request.send();
                                
                                if (ctx.mounted) {
                                  setModalState(() => isSubmitting = false);
                                }
                                
                                if (res.statusCode == 201) {
                                  if (!ctx.mounted) return;
                                  Navigator.pop(ctx);
                                  _fetchArticles();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                          disabledBackgroundColor: const Color(0xFF10B981).withValues(alpha: 0.6),
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
                                  'بڵاوکردنەوەی وتار',
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

  Future<void> _showEditArticleModal(Map<String, dynamic> article) async {
    File? selectedImage;
    final titleController = TextEditingController(text: article['title']);
    final contentController = TextEditingController(text: article['content']);
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
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
                      'دەستکاریکردنی وتار',
                      style: TextStyle(
                        color: AppColors.getTextTitle(context),
                        fontFamily: 'Rabar',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDarkInput(
                      controller: titleController,
                      hint: 'ناونیشانی وتار',
                      context: context,
                    ),
                    const SizedBox(height: 12),
                    _buildDarkInput(
                      controller: contentController,
                      hint: 'ناوەڕۆکی وتار',
                      maxLines: 5,
                      context: context,
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
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.getBackground(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                selectedImage != null ||
                                    article['image_path'] != null
                                ? const Color(0xFF10B981)
                                : AppColors.getBorder(context),
                            width: 1.5,
                          ),
                        ),
                        child: selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(
                                  selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : article['image_path'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.network(
                                  '${ApiClient.storageUrl}/${article['image_path']}',
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Iconsax.add_circle,
                                    color: Color(0xFF10B981),
                                    size: 30,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'گۆڕینی وێنەی بەرگ (ئارەزوومەندانە)',
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
                                if (titleController.text.isEmpty ||
                                    contentController.text.isEmpty) return;
                                
                                setModalState(() => isSubmitting = true);
                                
                                final prefs = await SharedPreferences.getInstance();
                                final token = prefs.getString('auth_token');
                                var request = http.MultipartRequest(
                                  'POST',
                                  Uri.parse(
                                      '${ApiClient.baseUrl}/admin/articles/${article['id']}'),
                                );
                                request.headers['Authorization'] = 'Bearer $token';
                                request.headers['Accept'] = 'application/json';
                                request.fields['_method'] = 'PUT';
                                request.fields['title'] = titleController.text;
                                request.fields['content'] = contentController.text;
                                if (selectedImage != null) {
                                  request.files.add(
                                    await http.MultipartFile.fromPath(
                                      'image',
                                      selectedImage!.path,
                                    ),
                                  );
                                }
                                var res = await request.send();
                                
                                if (ctx.mounted) {
                                  setModalState(() => isSubmitting = false);
                                }
                                
                                if (res.statusCode == 200 || res.statusCode == 201) {
                                  if (!ctx.mounted) return;
                                  Navigator.pop(ctx);
                                  _fetchArticles();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                          disabledBackgroundColor: const Color(0xFF10B981).withValues(alpha: 0.6),
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
                                  'نوێکردنەوەی وتار',
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AdminAppBar(
        title: 'وتارەکان',
        subtitle: '${_articles.length} published',
        icon: Iconsax.book_1,
        iconColor: const Color(0xFF10B981),
        iconBackgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
        actions: [
          GestureDetector(
            onTap: _showAddArticleModal,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add, color: Color(0xFF10B981), size: 18),
                  const SizedBox(width: 4),
                  Text(
                    'نوێ',
                    style: TextStyle(
                      color: const Color(0xFF10B981),
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
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF10B981)),
                  )
                : _articles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.getTextSubtitle(
                              context,
                            ).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Iconsax.book,
                            color: AppColors.getTextSubtitle(context),
                            size: 48,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'هیچ وتارێک نییە',
                          style: TextStyle(
                            color: AppColors.getTextTitle(context),
                            fontFamily: 'Rabar',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'تائێستا هیچ بابەتێک بڵاونەکراوەتەوە',
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
                    onRefresh: _fetchArticles,
                    color: const Color(0xFF10B981),
                    backgroundColor: AppColors.getSurface(context),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 110),
                      itemCount: _articles.length,
                      itemBuilder: (context, index) {
                        final article = _articles[index];
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (article['image_path'] != null)
                                    ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(20),
                                      ),
                                      child: Image.network(
                                        '${ApiClient.storageUrl}/${article['image_path']}',
                                        height: 130,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Container(
                                          height: 130,
                                          color: AppColors.getBackground(
                                            context,
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.image_not_supported,
                                              color: AppColors.getBorder(
                                                context,
                                              ),
                                              size: 32,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                article['title'] ??
                                                    'بێ ناونیشان',
                                                style: TextStyle(
                                                  color: AppColors.getTextTitle(
                                                    context,
                                                  ),
                                                  fontFamily: 'Rabar',
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                article['content'] ?? '',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color:
                                                      AppColors.getTextSubtitle(
                                                        context,
                                                      ),
                                                  fontFamily: 'Rabar',
                                                  fontSize: 12,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            GestureDetector(
                                              onTap: () =>
                                                  _showEditArticleModal(
                                                    article,
                                                  ),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFF3B82F6,
                                                  ).withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: const Icon(
                                                  Iconsax.edit,
                                                  color: Color(0xFF3B82F6),
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap: () =>
                                                  _deleteArticle(article['id']),
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.error
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
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
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .animate(delay: Duration(milliseconds: index * 70))
                            .fadeIn()
                            .slideY(begin: 0.08, end: 0);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
