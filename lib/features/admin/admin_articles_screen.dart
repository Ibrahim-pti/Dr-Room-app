import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../core/utils/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'admin_app_bar.dart';

class AdminArticlesScreen extends StatefulWidget {
  const AdminArticlesScreen({super.key});

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
    String selectedCategory = existingArticle?['category'] ?? 'گشتی';
    final shortDescController = TextEditingController(text: existingArticle?['short_desc'] ?? '');
    final contentController = TextEditingController(text: existingArticle?['content'] ?? '');
    final ambulanceController = TextEditingController(
      text: existingArticle?['when_to_call_ambulance'] ?? '',
    );

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
    // Shown inside the sheet: a SnackBar here lands behind the modal barrier.
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
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title
                          const Text('ناونیشانی فریاگوزاری *', style: TextStyle(fontFamily: 'Rabar', fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                          const SizedBox(height: 6),
                          _buildInput(
                            controller: titleController,
                            hint: 'وەک: خنکان و گیرانی قوڕگ، سووتان، شکان...',
                          ),
                          const SizedBox(height: 14),

                          // Category Selector
                          const Text('کەتەگۆری فریاگوزاری *', style: TextStyle(fontFamily: 'Rabar', fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _categories.where((c) => c != 'هەمووی').map((cat) {
                              final isSelected = selectedCategory == cat;
                              return GestureDetector(
                                onTap: () => setModalState(() => selectedCategory = cat),
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
                                  child: Text(
                                    cat,
                                    style: TextStyle(
                                      fontFamily: 'Rabar',
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: isSelected ? Colors.white : const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),

                          // Short Desc
                          const Text('پوختەی ڕێنمایی (کورتە)', style: TextStyle(fontFamily: 'Rabar', fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                          const SizedBox(height: 6),
                          _buildInput(
                            controller: shortDescController,
                            hint: 'کورتەیەک دەربارەی مەترسی و شێوازی چارەسەر...',
                            maxLines: 2,
                          ),
                          const SizedBox(height: 14),

                          // Content / Steps
                          const Text('هەنگاوەکانی فریاگوزاری و چارەسەر *', style: TextStyle(fontFamily: 'Rabar', fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                          const SizedBox(height: 6),
                          _buildInput(
                            controller: contentController,
                            hint: '١. هەنگاوی یەکەم...\n٢. هەنگاوی دووەم...\n٣. ئاگادارییەکان...',
                            maxLines: 5,
                          ),
                          const SizedBox(height: 18),

                          // Symptoms
                          _buildListSection(
                            title: 'نیشانە سەرەکییەکان',
                            subtitle: 'ئەو نیشانانەی لە ئەپەکەدا بە ✓ دەردەکەون',
                            addLabel: 'زیادکردنی نیشانە',
                            accent: const Color(0xFF3B82F6),
                            controllers: symptomControllers,
                            hint: 'وەک: دەستبردن بۆ قوڕگ و نەتوانینی قسەکردن',
                            onAdd: () => setModalState(() => symptomControllers.add(TextEditingController())),
                            onRemove: (i) => setModalState(() {
                              symptomControllers.removeAt(i).dispose();
                            }),
                          ),
                          const SizedBox(height: 18),

                          // Steps
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

                          // DOs
                          _buildListSection(
                            title: 'پێویستە بکەیت ✅',
                            subtitle: 'ئەو کارانەی دەبێت ئەنجام بدرێن',
                            addLabel: 'زیادکردنی کار',
                            accent: const Color(0xFF10B981),
                            controllers: dosControllers,
                            hint: 'وەک: ئارام بە و دڵنیای بکەرەوە',
                            onAdd: () => setModalState(() => dosControllers.add(TextEditingController())),
                            onRemove: (i) => setModalState(() {
                              dosControllers.removeAt(i).dispose();
                            }),
                          ),
                          const SizedBox(height: 18),

                          // DON'Ts
                          _buildListSection(
                            title: 'قەدەغەیە بکەیت ❌',
                            subtitle: 'ئەو کارانەی مەترسیدارن و نابێت بکرێن',
                            addLabel: 'زیادکردنی قەدەغە',
                            accent: const Color(0xFFEF4444),
                            controllers: dontsControllers,
                            hint: 'وەک: پەنجەت مەکەرە ناو دەمی ئەگەر تەنەکە نەبینیت',
                            onAdd: () => setModalState(() => dontsControllers.add(TextEditingController())),
                            onRemove: (i) => setModalState(() {
                              dontsControllers.removeAt(i).dispose();
                            }),
                          ),
                          const SizedBox(height: 18),

                          // When to call an ambulance
                          const Text('کەی دەستبەجێ پەیوەندی بە ١٢٢ بکەیت؟', style: TextStyle(fontFamily: 'Rabar', fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                          const SizedBox(height: 6),
                          _buildInput(
                            controller: ambulanceController,
                            hint: 'وەک: ئەگەر دوای چەند چرکەیەک تەنەکە دەرنەهات یان بێهۆش بوو...',
                            maxLines: 2,
                          ),
                          const SizedBox(height: 16),

                          // Image Picker
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
                                border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
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
                                      : Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.error_outline, size: 18, color: Color(0xFFEF4444)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      errorMessage!,
                                      style: const TextStyle(
                                        fontFamily: 'Rabar',
                                        fontSize: 12,
                                        height: 1.4,
                                        color: Color(0xFFB91C1C),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Submit Button
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
                                            'تکایە ناونیشان و ناوەڕۆکی فریاگوزاری پڕبکەرەوە (لە سەرەوەی فۆرمەکە).');
                                        return;
                                      }

                                      setModalState(() {
                                        errorMessage = null;
                                        isSubmitting = true;
                                      });

                                      try {
                                        final prefs = await SharedPreferences.getInstance();
                                        final token = prefs.getString('auth_token');

                                        final uri = isEditing
                                            ? Uri.parse('${ApiClient.baseUrl}/admin/articles/${existingArticle['id']}')
                                            : Uri.parse('${ApiClient.baseUrl}/admin/articles');

                                        final request = http.MultipartRequest('POST', uri);
                                        if (isEditing) {
                                          request.fields['_method'] = 'PUT';
                                        }

                                        request.headers['Authorization'] = 'Bearer $token';
                                        request.headers['Accept'] = 'application/json';

                                        request.fields['title'] = titleController.text.trim();
                                        request.fields['category'] = selectedCategory;
                                        request.fields['short_desc'] = shortDescController.text.trim();
                                        request.fields['content'] = contentController.text.trim();
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
                                        request.fields['when_to_call_ambulance'] = ambulanceController.text.trim();

                                        if (selectedImage != null) {
                                          // The server rejects anything over PHP's 2MB upload limit.
                                          final sizeInMb = await selectedImage!.length() / (1024 * 1024);
                                          if (sizeInMb > 8) {
                                            setModalState(() {
                                              errorMessage =
                                                  'وێنەکە زۆر گەورەیە (${sizeInMb.toStringAsFixed(1)}MB). زۆرترین قەبارە ٨MBـە.';
                                              isSubmitting = false;
                                            });
                                            return;
                                          }

                                          request.files.add(
                                            await http.MultipartFile.fromPath('image', selectedImage!.path),
                                          );
                                        }
                                        final streamedResponse = await request.send();
                                        final resp = await http.Response.fromStream(streamedResponse);

                                        if (resp.statusCode == 200 || resp.statusCode == 201) {
                                          if (ctx.mounted) Navigator.of(ctx).pop();
                                          _fetchArticles();
                                        } else {
                                          setModalState(() => errorMessage = _readableError(resp.statusCode, resp.body));
                                        }
                                      } catch (e) {
                                        setModalState(() => errorMessage = 'کێشەیەک لە پەیوەندی هەیە: $e');
                                      } finally {
                                        setModalState(() => isSubmitting = false);
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
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        height: 1.5,
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

  /// Turns a Laravel validation/error payload into one Kurdish sentence.
  String _readableError(int statusCode, String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        if (decoded['errors'] is Map) {
          final first = (decoded['errors'] as Map).values.first;
          final text = first is List ? first.first.toString() : first.toString();
          if (text.contains('image failed to upload') || text.contains('greater than')) {
            return 'وێنەکە زۆر گەورەیە بۆ سێرڤەرەکە. تکایە وێنەیەکی بچووکتر هەڵبژێرە.';
          }
          return text;
        }
        if (decoded['message'] != null) return decoded['message'].toString();
      }
    } catch (_) {}

    if (statusCode == 401 || statusCode == 403) {
      return 'دەسەڵاتت نییە. تکایە دووبارە بچۆ ژوورەوە.';
    }
    if (statusCode == 413) {
      return 'وێنەکە زۆر گەورەیە بۆ سێرڤەرەکە.';
    }
    return 'هەڵە ڕوویدا ($statusCode). تکایە دووبارە هەوڵ بدەرەوە.';
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
    final filteredArticles = _selectedFilter == 'هەمووی'
        ? _articles
        : _articles.where((a) => (a['category'] ?? '') == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AdminAppBar(
        title: 'فریاگوزاری سەرەتایی',
        subtitle: 'بڵاوکردنەوە و بەڕێوەبردنی ڕێنماییەکان',
        icon: Iconsax.firstline,
        iconColor: const Color(0xFF2563EB),
        iconBackgroundColor: const Color(0xFFEFF6FF),
        showBackButton: false,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ElevatedButton.icon(
              onPressed: () => _showAddArticleModal(),
              icon: const Icon(Iconsax.add, size: 16, color: Colors.white),
              label: const Text(
                'پۆستی نوێ',
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                elevation: 0,
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
                    backgroundColor: Colors.white,
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
