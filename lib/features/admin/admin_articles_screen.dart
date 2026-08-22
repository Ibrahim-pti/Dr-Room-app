import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../core/utils/api_client.dart';
import '../../core/utils/translation_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_app_bar.dart';

class AdminArticlesScreen extends StatefulWidget {
  final bool isRoot;
  const AdminArticlesScreen({super.key, this.isRoot = false});

  @override
  State<AdminArticlesScreen> createState() => _AdminArticlesScreenState();
}

class _AdminArticlesScreenState extends State<AdminArticlesScreen> {
  List<dynamic> _articles = [];
  bool _isLoading = true;
  String _selectedFilter = 'هەمووی';

  final List<String> _categories = [
    'هەمووی',
    'هەناسەدان',
    'پێست و برین',
    'دڵ و سووڕی خوێن',
    'ئێسک و شکان',
    'ژەهراویبوون',
    'گشتی',
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _fetchArticles();
  }

  Future<void> _loadCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('admin_custom_article_categories');
      if (saved != null) {
        for (final c in saved) {
          if (!_categories.contains(c) && c.trim().isNotEmpty) {
            _categories.add(c.trim());
          }
        }
        if (mounted) setState(() {});
      }
    } catch (_) {}
  }

  Future<void> _saveCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final toSave = _categories.where((c) => c != 'هەمووی').toList();
      await prefs.setStringList('admin_custom_article_categories', toSave);
    } catch (_) {}
  }

  Future<void> _showAddCategoryDialog(StateSetter setModalState, Function(String) onSelected) async {
    final textController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Iconsax.add_circle, color: Color(0xFF2563EB), size: 22),
            SizedBox(width: 8),
            Text(
              'زیادکردنی کەتەگۆری نوێ',
              style: TextStyle(fontFamily: 'Rabar', fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ناوی کەتەگۆرییە نوێیەکە بنووسە:',
              style: TextStyle(fontFamily: 'Rabar', fontSize: 12.5, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              style: const TextStyle(fontFamily: 'Rabar', fontSize: 14),
              decoration: InputDecoration(
                hintText: 'وەک: چاو و بینین، دەمار، منداڵان...',
                hintStyle: const TextStyle(fontFamily: 'Rabar', fontSize: 13, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('پاشگەزبوونەوە', style: TextStyle(fontFamily: 'Rabar', color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final val = textController.text.trim();
              if (val.isNotEmpty) {
                Navigator.pop(ctx, val);
              }
            },
            child: const Text('زیادکردن', style: TextStyle(fontFamily: 'Rabar', color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty) {
      final newCat = result.trim();
      if (!_categories.contains(newCat)) {
        setState(() {
          _categories.add(newCat);
        });
        await _saveCategories();
      }
      setModalState(() {
        onSelected(newCat);
      });
    }
  }

  Future<void> _showDeleteCategoryDialog(
    String cat,
    StateSetter setModalState,
    Function(String) onSelected,
    String currentSelected,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'سڕینەوەی کەتەگۆری',
          style: TextStyle(fontFamily: 'Rabar', fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Text(
          'ئایا دڵنیایت لە سڕینەوەی کەتەگۆری "$cat" لە لیستەکە؟',
          style: const TextStyle(fontFamily: 'Rabar', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('پاشگەزبوونەوە', style: TextStyle(fontFamily: 'Rabar', color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('سڕینەوە', style: TextStyle(fontFamily: 'Rabar', color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _categories.remove(cat);
      });
      await _saveCategories();
      setModalState(() {
        if (currentSelected == cat) {
          onSelected('گشتی');
        }
      });
    }
  }

  Future<void> _fetchArticles() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.get('/admin/articles');
      if (response.statusCode == 200 && mounted) {
        setState(() {
          _articles = jsonDecode(response.body);
          for (final a in _articles) {
            final cat = (a['category'] ?? '').toString().trim();
            if (cat.isNotEmpty && !_categories.contains(cat)) {
              _categories.add(cat);
            }
          }
          _isLoading = false;
        });
        _saveCategories();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteArticle(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'سڕینەوەی فریاگوزاری',
          style: TextStyle(fontFamily: 'Rabar', fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: const Text(
          'ئایا دڵنیایت لە سڕینەوەی ئەم پۆستەی فریاگوزاری سەرەتایی؟',
          style: TextStyle(fontFamily: 'Rabar', fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('پاشگەزبوونەوە', style: TextStyle(fontFamily: 'Rabar', color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('سڕینەوە', style: TextStyle(fontFamily: 'Rabar', color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final response = await ApiClient.delete('/admin/articles/$id');
        if (response.statusCode == 204 || response.statusCode == 200) {
          _fetchArticles();
        }
      } catch (e) {
        debugPrint('Error: $e');
      }
    }
  }

  Future<void> _showAddArticleModal({dynamic existingArticle}) async {
      File? selectedImage;
      final isEditing = existingArticle != null;
      final titleController = TextEditingController(text: existingArticle?['title'] ?? '');
      final titleEnController = TextEditingController(text: existingArticle?['title_en'] ?? '');
      final titleArController = TextEditingController(text: existingArticle?['title_ar'] ?? '');

      String selectedCategory = existingArticle?['category'] ?? 'گشتی';
      String selectedCategoryEn = existingArticle?['category_en'] ?? '';
      String selectedCategoryAr = existingArticle?['category_ar'] ?? '';

      final shortDescController = TextEditingController(text: existingArticle?['short_desc'] ?? '');
      final shortDescEnController = TextEditingController(text: existingArticle?['short_desc_en'] ?? '');
      final shortDescArController = TextEditingController(text: existingArticle?['short_desc_ar'] ?? '');

      final contentController = TextEditingController(text: existingArticle?['content'] ?? '');
      final contentEnController = TextEditingController(text: existingArticle?['content_en'] ?? '');
      final contentArController = TextEditingController(text: existingArticle?['content_ar'] ?? '');

      final ambulanceController = TextEditingController(
        text: existingArticle?['when_to_call_ambulance'] ?? '',
      );
      final ambulanceEnController = TextEditingController(
        text: existingArticle?['when_to_call_ambulance_en'] ?? '',
      );
      final ambulanceArController = TextEditingController(
        text: existingArticle?['when_to_call_ambulance_ar'] ?? '',
      );

      int activeLangTab = 0; // 0: کوردی, 1: عەرەبی, 2: ئینگلیزی
      bool isTranslating = false;

      final symptomControllers = _decodeStringList(existingArticle?['symptoms'])
          .map((v) => TextEditingController(text: v))
          .toList();
      final dosControllers = _decodeStringList(existingArticle?['dos'])
          .map((v) => TextEditingController(text: v))
          .toList();
      final dontsControllers = _decodeStringList(existingArticle?['donts'])
          .map((v) => TextEditingController(text: v))
          .toList();
      final stepControllers = _decodeStepList(existingArticle?['steps'])
          .map((step) => (
                title: TextEditingController(text: step['title'] ?? ''),
                desc: TextEditingController(text: step['desc'] ?? ''),
              ))
          .toList();

      bool isSubmitting = false;
      String? errorMessage;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        builder: (ctx) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  left: 20,
                  right: 20,
                  top: 12,
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
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: IconButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF0F172A)),
                            tooltip: 'گەڕانەوە',
                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEditing ? 'دەستکاریکردنی فریاگوزاری' : 'بڵاوکردنەوەی فریاگوزاری نوێ',
                                style: const TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'زانیاری و ڕێنمایی ڕزگارکەر بۆ نەخۆش و بەکارهێنەرانی ئەپ',
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 11.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── AI Auto-Translate Bar ──
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Iconsax.translate, color: Color(0xFF16A34A), size: 16),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'وەرگێڕانی هەموو بۆ عەرەبی و ئینگلیزی',
                              style: TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF166534),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: isTranslating
                                ? null
                                : () async {
                                    if (titleController.text.trim().isEmpty && contentController.text.trim().isEmpty) {
                                      setModalState(() => errorMessage = 'تکایە سەرەتا ناونیشان یان ناوەڕۆک بنووسە.');
                                      return;
                                    }
                                    setModalState(() {
                                      isTranslating = true;
                                      errorMessage = null;
                                    });
                                    final toTranslate = {
                                      'title': titleController.text.trim(),
                                      'category': selectedCategory,
                                      'short_desc': shortDescController.text.trim(),
                                      'content': contentController.text.trim(),
                                      'ambulance': ambulanceController.text.trim(),
                                    };
                                    final res = await TranslationHelper.translateFields(toTranslate);
                                    if (res.isNotEmpty) {
                                      titleArController.text = res['title']?['ar'] ?? '';
                                      titleEnController.text = res['title']?['en'] ?? '';
                                      selectedCategoryAr = res['category']?['ar'] ?? '';
                                      selectedCategoryEn = res['category']?['en'] ?? '';
                                      shortDescArController.text = res['short_desc']?['ar'] ?? '';
                                      shortDescEnController.text = res['short_desc']?['en'] ?? '';
                                      contentArController.text = res['content']?['ar'] ?? '';
                                      contentEnController.text = res['content']?['en'] ?? '';
                                      ambulanceArController.text = res['ambulance']?['ar'] ?? '';
                                      ambulanceEnController.text = res['ambulance']?['en'] ?? '';
                                    }
                                    setModalState(() => isTranslating = false);
                                  },
                            icon: isTranslating
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Iconsax.magicpen, size: 13, color: Colors.white),
                            label: Text(
                              isTranslating ? 'وەرگێڕان...' : 'وەرگێڕانی هەموو',
                              style: const TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── Language Tabs (کوردی / عەرەبی / ئینگلیزی) ──
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => activeLangTab = 0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                decoration: BoxDecoration(
                                  color: activeLangTab == 0 ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: activeLangTab == 0
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'کوردی (سەرەکی)',
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 11.5,
                                    fontWeight: activeLangTab == 0 ? FontWeight.bold : FontWeight.w600,
                                    color: activeLangTab == 0 ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => activeLangTab = 1),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                decoration: BoxDecoration(
                                  color: activeLangTab == 1 ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: activeLangTab == 1
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'العربية (Arabic)',
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 11.5,
                                    fontWeight: activeLangTab == 1 ? FontWeight.bold : FontWeight.w600,
                                    color: activeLangTab == 1 ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setModalState(() => activeLangTab = 2),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 7),
                                decoration: BoxDecoration(
                                  color: activeLangTab == 2 ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: activeLangTab == 2
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'English (ئینگلیزی)',
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 11.5,
                                    fontWeight: activeLangTab == 2 ? FontWeight.bold : FontWeight.w600,
                                    color: activeLangTab == 2 ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Title Field (Dynamic according to active tab) ──
                            Text(
                              activeLangTab == 0
                                  ? 'ناونیشانی فریاگوزاری (کوردی) *'
                                  : activeLangTab == 1
                                      ? 'ناونیشانی فریاگوزاری (العربية) *'
                                      : 'ناونیشانی فریاگوزاری (English) *',
                              style: const TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildInput(
                              controller: activeLangTab == 0
                                  ? titleController
                                  : activeLangTab == 1
                                      ? titleArController
                                      : titleEnController,
                              hint: activeLangTab == 0
                                  ? 'وەک: خنکان و گیرانی قوڕگ، سووتان، شکان...'
                                  : activeLangTab == 1
                                      ? 'مثل: الاختناق وانسداد الحلق، الحروق...'
                                      : 'e.g. Choking, Burns, Heart Stroke...',
                            ),
                            const SizedBox(height: 14),

                            // ── Category Selector ──
                            if (activeLangTab == 0) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'کەتەگۆری فریاگوزاری *',
                                    style: TextStyle(
                                      fontFamily: 'Rabar',
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _showAddCategoryDialog(
                                      setModalState,
                                      (newCat) => selectedCategory = newCat,
                                    ),
                                    icon: const Icon(Iconsax.add_circle, size: 16, color: Color(0xFF2563EB)),
                                    label: const Text(
                                      'زیادکردنی کەتەگۆری نوێ',
                                      style: TextStyle(
                                        fontFamily: 'Rabar',
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ..._categories.where((c) => c != 'هەمووی').map((cat) {
                                    final isSelected = selectedCategory == cat;
                                    final isCustom = !['هەناسەدان', 'پێست و برین', 'دڵ و سووڕی خوێن', 'ئێسک و شکان', 'ژەهراویبوون', 'گشتی'].contains(cat);

                                    return GestureDetector(
                                      onTap: () => setModalState(() => selectedCategory = cat),
                                      onLongPress: () => _showDeleteCategoryDialog(
                                        cat,
                                        setModalState,
                                        (fallback) => selectedCategory = fallback,
                                        selectedCategory,
                                      ),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 150),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(
                                            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              cat,
                                              style: TextStyle(
                                                fontFamily: 'Rabar',
                                                fontSize: 12,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                                color: isSelected ? Colors.white : const Color(0xFF475569),
                                              ),
                                            ),
                                            if (isCustom) ...[
                                              const SizedBox(width: 6),
                                              GestureDetector(
                                                onTap: () => _showDeleteCategoryDialog(
                                                  cat,
                                                  setModalState,
                                                  (fallback) => selectedCategory = fallback,
                                                  selectedCategory,
                                                ),
                                                child: Icon(
                                                  Icons.close,
                                                  size: 13,
                                                  color: isSelected ? Colors.white70 : const Color(0xFF94A3B8),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                  GestureDetector(
                                    onTap: () => _showAddCategoryDialog(
                                      setModalState,
                                      (newCat) => selectedCategory = newCat,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: const Color(0xFF93C5FD),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Iconsax.add, size: 14, color: Color(0xFF2563EB)),
                                          SizedBox(width: 4),
                                          Text(
                                            'کەتەگۆری نوێ +',
                                            style: TextStyle(
                                              fontFamily: 'Rabar',
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2563EB),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                            ],

                            // ── Short Desc ──
                            Text(
                              activeLangTab == 0
                                  ? 'پوختەی ڕێنمایی (کورتە بە کوردی)'
                                  : activeLangTab == 1
                                      ? 'پوختەی ڕێنمایی (ملخص بالعربية)'
                                      : 'پوختەی ڕێنمایی (Summary in English)',
                              style: const TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildInput(
                              controller: activeLangTab == 0
                                  ? shortDescController
                                  : activeLangTab == 1
                                      ? shortDescArController
                                      : shortDescEnController,
                              hint: activeLangTab == 0
                                  ? 'کورتەیەک دەربارەی مەترسی و شێوازی چارەسەر...'
                                  : activeLangTab == 1
                                      ? 'ملخص قصير عن الحالة والإسعاف...'
                                      : 'Short summary of the emergency...',
                              maxLines: 2,
                            ),
                            const SizedBox(height: 14),

                            // ── Content / Steps ──
                            Text(
                              activeLangTab == 0
                                  ? 'هەنگاوەکانی فریاگوزاری و چارەسەر (کوردی) *'
                                  : activeLangTab == 1
                                      ? 'هەنگاوەکانی فریاگوزاری (خطوات بالعربية) *'
                                      : 'هەنگاوەکانی فریاگوزاری (Steps in English) *',
                              style: const TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildInput(
                              controller: activeLangTab == 0
                                  ? contentController
                                  : activeLangTab == 1
                                      ? contentArController
                                      : contentEnController,
                              hint: activeLangTab == 0
                                  ? '١. هەنگاوی یەکەم...\n٢. هەنگاوی دووەم...\n٣. ئاگادارییەکان...'
                                  : activeLangTab == 1
                                      ? '١. الخطوة الأولى...\n٢. الخطوة الثانية...'
                                      : '1. First step...\n2. Second step...',
                              maxLines: 5,
                            ),
                            const SizedBox(height: 18),

                            // ── Symptoms / Signs ──
                            _buildListSection(
                              title: 'نیشانە سەرەکییەکان',
                              subtitle: 'ئەو نیشانانەی لە ئەپەکەدا بە ✓ دەردەکەون',
                              addLabel: 'زیادکردنی نیشانە',
                              accent: const Color(0xFF3B82F6),
                              controllers: symptomControllers,
                              hint: 'وەک: تەنگەنەفەسی، شینبوونی لێو...',
                              onAdd: () => setModalState(() => symptomControllers.add(TextEditingController())),
                              onRemove: (i) => setModalState(() => symptomControllers.removeAt(i).dispose()),
                            ),
                            const SizedBox(height: 18),

                            // ── Steps ──
                            _buildStepsSection(
                              steps: stepControllers,
                              onAdd: () => setModalState(() => stepControllers.add((
                                    title: TextEditingController(),
                                    desc: TextEditingController(),
                                  ))),
                              onRemove: (i) => setModalState(() {
                                final removed = stepControllers.removeAt(i);
                                removed.title.dispose();
                                removed.desc.dispose();
                              }),
                            ),
                            const SizedBox(height: 18),

                            // ── Dos ──
                            _buildListSection(
                              title: 'پێویستە بکەیت ✅',
                              subtitle: 'ئەو کارانەی دەبێت ئەنجام بدرێن',
                              addLabel: 'زیادکردنی کار',
                              accent: const Color(0xFF10B981),
                              controllers: dosControllers,
                              hint: 'وەک: ئارام بە و دڵنیای بکەرەوە',
                              onAdd: () => setModalState(() => dosControllers.add(TextEditingController())),
                              onRemove: (i) => setModalState(() => dosControllers.removeAt(i).dispose()),
                            ),
                            const SizedBox(height: 18),

                            // ── DON'Ts ──
                            _buildListSection(
                              title: 'قەدەغەیە بکەیت ❌',
                              subtitle: 'ئەو کارانەی مەترسیدارن و نابێت بکرێن',
                              addLabel: 'زیادکردنی قەدەغە',
                              accent: const Color(0xFFEF4444),
                              controllers: dontsControllers,
                              hint: 'وەک: پەنجەت مەکەرە ناو دەمی ئەگەر تەنەکە نەبینیت',
                              onAdd: () => setModalState(() => dontsControllers.add(TextEditingController())),
                              onRemove: (i) => setModalState(() => dontsControllers.removeAt(i).dispose()),
                            ),
                            const SizedBox(height: 18),

                            // ── Ambulance Call Note ──
                            Text(
                              activeLangTab == 0
                                  ? 'کەی دەستبەجێ پەیوەندی بە ١٢٢ بکەیت؟'
                                  : activeLangTab == 1
                                      ? 'متى تتصل بالإسعاف 122؟'
                                      : 'When to immediately call 122 ambulance?',
                              style: const TextStyle(
                                fontFamily: 'Rabar',
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 6),
                            _buildInput(
                              controller: activeLangTab == 0
                                  ? ambulanceController
                                  : activeLangTab == 1
                                      ? ambulanceArController
                                      : ambulanceEnController,
                              hint: 'وەک: ئەگەر دوای چەند چرکەیەک تەنەکە دەرنەهات یان بێهۆش بوو...',
                              maxLines: 2,
                            ),
                            const SizedBox(height: 16),

                            // ── Image Picker ──
                            GestureDetector(
                              onTap: () async {
                                final picker = ImagePicker();
                                final img = await picker.pickImage(
                                  source: ImageSource.gallery,
                                  imageQuality: 85,
                                  maxWidth: 1920,
                                );
                                if (img != null) {
                                  setModalState(() => selectedImage = File(img.path));
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                height: 110,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: selectedImage != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.file(selectedImage!, fit: BoxFit.cover),
                                      )
                                    : (isEditing && existingArticle['image_path'] != null)
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: Image.network(
                                              '${ApiClient.storageUrl}/${existingArticle['image_path']}',
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Iconsax.image, color: Color(0xFF2563EB), size: 30),
                                              SizedBox(height: 6),
                                              Text(
                                                'دەستنیشانکردنی وێنە (ئارەزوومەندانە)',
                                                style: TextStyle(
                                                  fontFamily: 'Rabar',
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                              ),
                            ),
                            const SizedBox(height: 22),

                            if (errorMessage != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.35)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, size: 18, color: Color(0xFFEF4444)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        errorMessage!,
                                        style: const TextStyle(
                                          fontFamily: 'Rabar',
                                          fontSize: 12,
                                          color: Color(0xFFB91C1C),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // ── Submit Button ──
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                onPressed: isSubmitting
                                    ? null
                                    : () async {
                                        if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) {
                                          setModalState(() => errorMessage =
                                              'تکایە ناونیشان و ناوەڕۆکی فریاگوزاری بە کوردی پڕبکەرەوە.');
                                          return;
                                        }

                                        setModalState(() {
                                          errorMessage = null;
                                          isSubmitting = true;
                                        });

                                        // Auto-translate if English/Arabic fields were left empty
                                        if (titleArController.text.trim().isEmpty || titleEnController.text.trim().isEmpty) {
                                          final toTranslate = {
                                            'title': titleController.text.trim(),
                                            'category': selectedCategory,
                                            'short_desc': shortDescController.text.trim(),
                                            'content': contentController.text.trim(),
                                            'ambulance': ambulanceController.text.trim(),
                                          };
                                          final res = await TranslationHelper.translateFields(toTranslate);
                                          if (res.isNotEmpty) {
                                            if (titleArController.text.trim().isEmpty) titleArController.text = res['title']?['ar'] ?? '';
                                            if (titleEnController.text.trim().isEmpty) titleEnController.text = res['title']?['en'] ?? '';
                                            if (selectedCategoryAr.isEmpty) selectedCategoryAr = res['category']?['ar'] ?? '';
                                            if (selectedCategoryEn.isEmpty) selectedCategoryEn = res['category']?['en'] ?? '';
                                            if (shortDescArController.text.trim().isEmpty) shortDescArController.text = res['short_desc']?['ar'] ?? '';
                                            if (shortDescEnController.text.trim().isEmpty) shortDescEnController.text = res['short_desc']?['en'] ?? '';
                                            if (contentArController.text.trim().isEmpty) contentArController.text = res['content']?['ar'] ?? '';
                                            if (contentEnController.text.trim().isEmpty) contentEnController.text = res['content']?['en'] ?? '';
                                            if (ambulanceArController.text.trim().isEmpty) ambulanceArController.text = res['ambulance']?['ar'] ?? '';
                                            if (ambulanceEnController.text.trim().isEmpty) ambulanceEnController.text = res['ambulance']?['en'] ?? '';
                                          }
                                        }

                                        try {
                                          final prefs = await SharedPreferences.getInstance();
                                          final token = prefs.getString('auth_token');

                                          final uri = isEditing
                                              ? Uri.parse('${ApiClient.baseUrl}/admin/articles/${existingArticle['id']}')
                                              : Uri.parse('${ApiClient.baseUrl}/admin/articles');

                                          final request = http.MultipartRequest('POST', uri);
                                          if (isEditing) request.fields['_method'] = 'PUT';

                                          request.headers['Authorization'] = 'Bearer $token';
                                          request.headers['Accept'] = 'application/json';

                                          // Kurdish (default)
                                          request.fields['title'] = titleController.text.trim();
                                          request.fields['category'] = selectedCategory;
                                          request.fields['short_desc'] = shortDescController.text.trim();
                                          request.fields['content'] = contentController.text.trim();
                                          request.fields['when_to_call_ambulance'] = ambulanceController.text.trim();

                                          // English
                                          request.fields['title_en'] = titleEnController.text.trim();
                                          request.fields['category_en'] = selectedCategoryEn;
                                          request.fields['short_desc_en'] = shortDescEnController.text.trim();
                                          request.fields['content_en'] = contentEnController.text.trim();
                                          request.fields['when_to_call_ambulance_en'] = ambulanceEnController.text.trim();

                                          // Arabic
                                          request.fields['title_ar'] = titleArController.text.trim();
                                          request.fields['category_ar'] = selectedCategoryAr;
                                          request.fields['short_desc_ar'] = shortDescArController.text.trim();
                                          request.fields['content_ar'] = contentArController.text.trim();
                                          request.fields['when_to_call_ambulance_ar'] = ambulanceArController.text.trim();
                                          request.fields['is_published'] = '1';
                                          request.fields['symptoms'] = jsonEncode(_valuesOf(symptomControllers));
                                          request.fields['dos'] = jsonEncode(_valuesOf(dosControllers));
                                          request.fields['donts'] = jsonEncode(_valuesOf(dontsControllers));
                                          request.fields['steps'] = jsonEncode(
                                            stepControllers
                                                .map((c) => {
                                                      'title': c.title.text.trim(),
                                                      'desc': c.desc.text.trim(),
                                                    })
                                                .where((m) => m['title']!.isNotEmpty || m['desc']!.isNotEmpty)
                                                .toList(),
                                          );

                                          if (selectedImage != null) {
                                            request.files.add(
                                              await http.MultipartFile.fromPath(
                                                'image',
                                                selectedImage!.path,
                                              ),
                                            );
                                          }

                                          final streamedResponse = await request.send();
                                          final response = await http.Response.fromStream(streamedResponse);

                                          if (response.statusCode == 200 || response.statusCode == 201) {
                                            if (ctx.mounted) Navigator.pop(ctx);
                                            _fetchArticles();
                                          } else {
                                            String msg = 'هەڵەیەک ڕوویدا (${response.statusCode})';
                                            try {
                                              final body = jsonDecode(response.body);
                                              if (body is Map && body['message'] != null) {
                                                msg = body['message'].toString();
                                              }
                                            } catch (_) {}
                                            setModalState(() {
                                              isSubmitting = false;
                                              errorMessage = msg;
                                            });
                                          }
                                        } catch (e) {
                                          setModalState(() {
                                            isSubmitting = false;
                                            errorMessage = 'کێشەی پەیوەندی بە سێرڤەر: $e';
                                          });
                                        }
                                      },
                                child: isSubmitting
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                      )
                                    : Text(
                                        isEditing ? 'نوێکردنەوەی فریاگوزاری' : 'بڵاوکردنەوەی فریاگوزاری',
                                        maxLines: 1,
                                        style: const TextStyle(
                                          fontFamily: 'Rabar',
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          height: 1.2,
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
          },
        );
      },
    );
  }

  /// The API may hand these back as a real List or as a raw JSON string,
  /// depending on where the record was written from.
  List<String> _decodeStringList(dynamic raw) {
    final decoded = _decodeList(raw);
    return decoded.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
  }

  List<Map<String, String>> _decodeStepList(dynamic raw) {
    return _decodeList(raw).map((e) {
      if (e is Map) {
        return {
          'title': (e['title'] ?? '').toString(),
          'desc': (e['desc'] ?? '').toString(),
        };
      }
      return {'title': 'هەنگاو', 'desc': e.toString()};
    }).toList();
  }

  List<dynamic> _decodeList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) return decoded;
      } catch (_) {}
    }
    return [];
  }

  List<String> _valuesOf(List<TextEditingController> controllers) {
    return controllers
        .map((c) => c.text.trim())
        .where((v) => v.isNotEmpty)
        .toList();
  }

  Widget _buildListSection({
    required String title,
    required String subtitle,
    required String addLabel,
    required Color accent,
    required List<TextEditingController> controllers,
    required String hint,
    required VoidCallback onAdd,
    required void Function(int index) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontFamily: 'Rabar', fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(fontFamily: 'Rabar', fontSize: 11, color: Color(0xFF94A3B8))),
        const SizedBox(height: 8),
        ...List.generate(controllers.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                ),
                Expanded(child: _buildInput(controller: controllers[i], hint: hint)),
                IconButton(
                  onPressed: () => onRemove(i),
                  icon: const Icon(Iconsax.trash, size: 18, color: Color(0xFFEF4444)),
                  tooltip: 'سڕینەوە',
                ),
              ],
            ),
          );
        }),
        _buildAddButton(label: addLabel, accent: accent, onTap: onAdd),
      ],
    );
  }

  Widget _buildStepsSection({
    required List<({TextEditingController title, TextEditingController desc})> steps,
    required VoidCallback onAdd,
    required void Function(int index) onRemove,
  }) {
    const accent = Color(0xFF2563EB);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('هەنگاوەکانی فریاگوزاری بەپەلە', style: TextStyle(fontFamily: 'Rabar', fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
        const SizedBox(height: 2),
        const Text('هەر هەنگاوێک بە ژمارە و ناونیشانەوە لە ئەپەکەدا دەردەکەوێت', style: TextStyle(fontFamily: 'Rabar', fontSize: 11, color: Color(0xFF94A3B8))),
        const SizedBox(height: 8),
        ...List.generate(steps.length, (i) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(fontFamily: 'Rabar', fontSize: 12, fontWeight: FontWeight.bold, color: accent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInput(controller: steps[i].title, hint: 'ناونیشانی هەنگاو، وەک: هاندانی بۆ کۆکین'),
                    ),
                    IconButton(
                      onPressed: () => onRemove(i),
                      icon: const Icon(Iconsax.trash, size: 18, color: Color(0xFFEF4444)),
                      tooltip: 'سڕینەوەی هەنگاو',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildInput(
                  controller: steps[i].desc,
                  hint: 'ڕوونکردنەوەی هەنگاوەکە...',
                  maxLines: 2,
                ),
              ],
            ),
          );
        }),
        _buildAddButton(label: 'زیادکردنی هەنگاو', accent: accent, onTap: onAdd),
      ],
    );
  }

  Widget _buildAddButton({
    required String label,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.add, size: 16, color: accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontFamily: 'Rabar', fontSize: 12, fontWeight: FontWeight.bold, color: accent),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(
          fontFamily: 'Rabar',
          fontSize: 13.5,
          height: 1.6,
          color: Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: 'Rabar',
            color: Color(0xFF94A3B8),
            fontSize: 12.5,
            height: 1.6,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredArticles = _selectedFilter == 'هەمووی'
        ? _articles
        : _articles.where((a) => (a['category'] ?? '') == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AdminAppBar(
        title: 'فریاگوزاری',
        subtitle: '${_articles.length} بابەتی بڵاوکراوە',
        icon: Iconsax.firstline,
        iconColor: const Color(0xFF2563EB),
        iconBackgroundColor: const Color(0xFFEFF6FF),
        showBackButton: !widget.isRoot,
        actions: [
          GestureDetector(
            onTap: () => _showAddArticleModal(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'نوێ',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Filter Bar
          Container(
            height: 48,
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedFilter == cat;
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ChoiceChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: const Color(0xFF2563EB),
                    backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF0F172A) : Colors.white,
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (_) => setState(() => _selectedFilter = cat),
                  ),
                );
              },
            ),
          ),

          // List of First Aid Articles
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchArticles,
              color: const Color(0xFF2563EB),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                  : filteredArticles.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Iconsax.document_text, size: 48, color: Color(0xFFCBD5E1)),
                              SizedBox(height: 12),
                              Text(
                                'هیچ پۆستێکی فریاگوزاری نییە',
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 14,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                          itemCount: filteredArticles.length,
                          itemBuilder: (context, index) {
                            final article = filteredArticles[index];
                            final category = article['category'] ?? 'گشتی';
                            final hasImage = article['image_path'] != null;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Thumbnail
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      width: 65,
                                      height: 65,
                                      color: const Color(0xFFEFF6FF),
                                      child: hasImage
                                          ? Image.network(
                                              '${ApiClient.storageUrl}/${article['image_path']}',
                                              fit: BoxFit.cover,
                                              errorBuilder: (c, e, s) => const Icon(
                                                Iconsax.firstline,
                                                color: Color(0xFF2563EB),
                                                size: 26,
                                              ),
                                            )
                                          : const Icon(
                                              Iconsax.firstline,
                                              color: Color(0xFF2563EB),
                                              size: 26,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                article['title'] ?? '',
                                                style: const TextStyle(
                                                  fontFamily: 'Rabar',
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0F172A),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEFF6FF),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                category,
                                                style: const TextStyle(
                                                  fontFamily: 'Rabar',
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF2563EB),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          article['short_desc'] ?? article['content'] ?? '',
                                          style: const TextStyle(
                                            fontFamily: 'Rabar',
                                            fontSize: 12,
                                            color: Color(0xFF64748B),
                                            height: 1.3,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),

                                        // Actions
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            GestureDetector(
                                              onTap: () => _showAddArticleModal(existingArticle: article),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: const [
                                                    Icon(Iconsax.edit, size: 13, color: Color(0xFF2563EB)),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'دەستکاری',
                                                      style: TextStyle(
                                                        fontFamily: 'Rabar',
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xFF2563EB),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            GestureDetector(
                                              onTap: () => _deleteArticle(article['id']),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFEF2F2),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: const [
                                                    Icon(Iconsax.trash, size: 13, color: Color(0xFFDC2626)),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'سڕینەوە',
                                                      style: TextStyle(
                                                        fontFamily: 'Rabar',
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xFFDC2626),
                                                      ),
                                                    ),
                                                  ],
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
                            ).animate(delay: Duration(milliseconds: index * 40)).fadeIn();
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }
}