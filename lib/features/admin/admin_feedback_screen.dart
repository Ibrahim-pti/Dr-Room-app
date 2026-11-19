import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart' as intl;

import '../../core/theme/app_colors.dart';
import '../../core/utils/api_client.dart';
import '../../core/utils/translation_helper.dart';
import 'admin_app_bar.dart';
import 'admin_ui.dart';

/// Admin panel screen to create, translate, toggle (active/inactive), and review
/// user feedback & rating surveys.
class AdminFeedbackScreen extends StatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen> {
  static const _indigo = Color(0xFF4F46E5);
  static const _emerald = Color(0xFF059669);
  static const _amber = Color(0xFFF59E0B);
  static const _rose = Color(0xFFE11D48);

  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _surveys = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await ApiClient.get('/admin/feedback-surveys');
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final rawList = (body['data'] as List?) ?? [];
        setState(() {
          _stats = Map<String, dynamic>.from((body['stats'] as Map?) ?? {});
          _surveys = rawList
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = AdminUi.readError(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleStatus(Map<String, dynamic> survey) async {
    try {
      final res = await ApiClient.patch(
        '/admin/feedback-surveys/${survey['id']}/toggle',
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        AdminUi.toast(
          context,
          (body['message'] ?? 'دۆخەکە گۆڕدرا').toString(),
        );
        _load();
      } else {
        AdminUi.toast(context, AdminUi.readError(res), isError: true);
      }
    } catch (e) {
      if (mounted) AdminUi.toast(context, '$e', isError: true);
    }
  }

  Future<void> _deleteSurvey(Map<String, dynamic> survey) async {
    final ok = await AdminUi.confirm(
      context,
      title: 'سڕینەوەی فیدباک',
      message: 'ئایا دڵنیایت لە سڕینەوەی «${survey['title'] ?? ''}» و هەموو وەڵامەکانی؟',
    );
    if (!ok) return;

    try {
      final res =
          await ApiClient.delete('/admin/feedback-surveys/${survey['id']}');
      if (!mounted) return;
      if (res.statusCode == 200) {
        AdminUi.toast(context, 'فیدباک سڕایەوە');
        _load();
      } else {
        AdminUi.toast(context, AdminUi.readError(res), isError: true);
      }
    } catch (e) {
      if (mounted) AdminUi.toast(context, '$e', isError: true);
    }
  }

  Future<void> _openSurveyForm({Map<String, dynamic>? existing}) async {
    final isEdit = existing != null;

    final titleCtrl = TextEditingController(
      text: existing?['title']?.toString() ?? 'بۆچوونت بۆ ئێمە زۆر گرنگە',
    );
    final titleKmrCtrl = TextEditingController(
      text: existing?['title_kmr']?.toString() ?? 'بۆچوونا تە بۆ مە گەلەک گرنگە',
    );
    final titleArCtrl = TextEditingController(
      text: existing?['title_ar']?.toString() ?? 'رأيك يهمنا كثيراً',
    );
    final titleEnCtrl = TextEditingController(
      text: existing?['title_en']?.toString() ?? 'Your Opinion Matters to Us',
    );

    final ratingQCtrl = TextEditingController(
      text: existing?['rating_question']?.toString() ??
          'ئایا لە خزمەتگوزارییەکانمان ڕازیت؟',
    );
    final ratingQKmrCtrl = TextEditingController(
      text: existing?['rating_question_kmr']?.toString() ??
          'ئایا تو ژ خزمەتگوزاریێن مە ڕازی یی؟',
    );
    final ratingQArCtrl = TextEditingController(
      text: existing?['rating_question_ar']?.toString() ??
          'هل أنت راضٍ عن خدماتنا؟',
    );
    final ratingQEnCtrl = TextEditingController(
      text: existing?['rating_question_en']?.toString() ??
          'Are you satisfied with our services?',
    );

    final sugQCtrl = TextEditingController(
      text: existing?['suggestion_question']?.toString() ??
          'چ شتێکی ترت دەوێت زیادی بکەین یان باشتر بکەین؟',
    );
    final sugQKmrCtrl = TextEditingController(
      text: existing?['suggestion_question_kmr']?.toString() ??
          'تە چ تشتێ دی دڤێت زێدە بکەین یان باشتر بکەین؟',
    );
    final sugQArCtrl = TextEditingController(
      text: existing?['suggestion_question_ar']?.toString() ??
          'ما الذي تود إضافته أو تحسينه في تطبيقنا؟',
    );
    final sugQEnCtrl = TextEditingController(
      text: existing?['suggestion_question_en']?.toString() ??
          'What else would you like us to add or improve?',
    );

    if (isEdit) {
      titleKmrCtrl.text = existing['title_kmr']?.toString() ?? '';
      titleArCtrl.text = existing['title_ar']?.toString() ?? '';
      titleEnCtrl.text = existing['title_en']?.toString() ?? '';
      ratingQKmrCtrl.text = existing['rating_question_kmr']?.toString() ?? '';
      ratingQArCtrl.text = existing['rating_question_ar']?.toString() ?? '';
      ratingQEnCtrl.text = existing['rating_question_en']?.toString() ?? '';
      sugQKmrCtrl.text = existing['suggestion_question_kmr']?.toString() ?? '';
      sugQArCtrl.text = existing['suggestion_question_ar']?.toString() ?? '';
      sugQEnCtrl.text = existing['suggestion_question_en']?.toString() ?? '';
    }

    bool isActive = existing == null
        ? true
        : (existing['is_active'] == true || existing['is_active'] == 1);
    bool isTranslating = false;
    bool showTranslations = false;

    try {
      await AdminUi.formSheet(
        context: context,
        title: isEdit ? 'دەستکاری فیدباک' : 'دروستکردنی فیدباکی نوێ',
        subtitle:
            'ئامادەکردنی پرسیارەکان بۆ بەکارهێنەران (لە کردنەوەی ئەپ دەردەکەوێت)',
        submitLabel: isEdit ? 'نوێکردنەوە' : 'بڵاوکردنەوە',
        builder: (setSheetState, setError) => [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'چالاک بێت بۆ بەکارهێنەران',
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              isActive
                  ? 'هەر یوزەرێک ئەپەکە بکاتەوە بۆ یەک جار پیشانی دەدرێت'
                  : 'ناچالاکە و بۆ هیچ یوزەرێک ناچێت',
              style: const TextStyle(
                fontFamily: 'Rabar',
                fontSize: 11,
                color: Color(0xFF64748B),
              ),
            ),
            activeTrackColor: _emerald,
            value: isActive,
            onChanged: (v) => setSheetState(() => isActive = v),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: titleCtrl,
            style: const TextStyle(fontFamily: 'Rabar', fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'سەرناوی فیدباک (سۆرانی)',
              prefixIcon: Icon(Iconsax.message_favorite),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: ratingQCtrl,
            maxLines: 2,
            style: const TextStyle(fontFamily: 'Rabar', fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'پرسیاری ڕازیبوون / هەڵسەنگاندن (سۆرانی)',
              prefixIcon: Icon(Iconsax.star_1),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: sugQCtrl,
            maxLines: 2,
            style: const TextStyle(fontFamily: 'Rabar', fontSize: 13),
            decoration: const InputDecoration(
              labelText: 'پرسیاری پێشنیار و زیادکردن (سۆرانی)',
              prefixIcon: Icon(Iconsax.edit_2),
            ),
          ),
          const SizedBox(height: 12),

          // Auto-translate + toggle manual translations
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isTranslating
                      ? null
                      : () async {
                          final t = titleCtrl.text.trim();
                          final rq = ratingQCtrl.text.trim();
                          final sq = sugQCtrl.text.trim();
                          if (t.isEmpty || rq.isEmpty || sq.isEmpty) {
                            setError('تکایە سەرەتا هەر ٣ دەقە سۆرانییەکە بنووسە');
                            return;
                          }
                          setSheetState(() {
                            isTranslating = true;
                            setError(null);
                          });
                          try {
                            final tr = await TranslationHelper.translateFields({
                              'title': t,
                              'rating_question': rq,
                              'suggestion_question': sq,
                            });
                            if (tr['title'] != null) {
                              titleKmrCtrl.text = tr['title']!['kmr'] ?? '';
                              titleArCtrl.text = tr['title']!['ar'] ?? '';
                              titleEnCtrl.text = tr['title']!['en'] ?? '';
                            }
                            if (tr['rating_question'] != null) {
                              ratingQKmrCtrl.text =
                                  tr['rating_question']!['kmr'] ?? '';
                              ratingQArCtrl.text =
                                  tr['rating_question']!['ar'] ?? '';
                              ratingQEnCtrl.text =
                                  tr['rating_question']!['en'] ?? '';
                            }
                            if (tr['suggestion_question'] != null) {
                              sugQKmrCtrl.text =
                                  tr['suggestion_question']!['kmr'] ?? '';
                              sugQArCtrl.text =
                                  tr['suggestion_question']!['ar'] ?? '';
                              sugQEnCtrl.text =
                                  tr['suggestion_question']!['en'] ?? '';
                            }
                            setSheetState(() {
                              showTranslations = true;
                            });
                          } finally {
                            setSheetState(() => isTranslating = false);
                          }
                        },
                  icon: isTranslating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Iconsax.translate, size: 17),
                  label: const Text(
                    'وەرگێڕانی خۆکار (بادینی/عەرەبی/EN)',
                    style: TextStyle(fontFamily: 'Rabar', fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'پیشاندانی زمانەکان',
                onPressed: () =>
                    setSheetState(() => showTranslations = !showTranslations),
                icon: Icon(
                  showTranslations
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                ),
              ),
            ],
          ),

          if (showTranslations) ...[
            const SizedBox(height: 12),
            AdminUi.label('بادینی (Kurmanji)'),
            const SizedBox(height: 6),
            TextField(
              controller: titleKmrCtrl,
              decoration: const InputDecoration(labelText: 'سەرناو (بادینی)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ratingQKmrCtrl,
              decoration:
                  const InputDecoration(labelText: 'پرسیاری ڕازیبوون (بادینی)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: sugQKmrCtrl,
              decoration:
                  const InputDecoration(labelText: 'پرسیاری پێشنیار (بادینی)'),
            ),
            const SizedBox(height: 12),
            AdminUi.label('عەرەبی (العربية)'),
            const SizedBox(height: 6),
            TextField(
              controller: titleArCtrl,
              decoration: const InputDecoration(labelText: 'العنوان (عربي)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ratingQArCtrl,
              decoration:
                  const InputDecoration(labelText: 'سؤال الرضا (عربي)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: sugQArCtrl,
              decoration:
                  const InputDecoration(labelText: 'سؤال الاقتراحات (عربي)'),
            ),
            const SizedBox(height: 12),
            AdminUi.label('English'),
            const SizedBox(height: 6),
            TextField(
              controller: titleEnCtrl,
              decoration: const InputDecoration(labelText: 'Title (English)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ratingQEnCtrl,
              decoration: const InputDecoration(
                labelText: 'Satisfaction Question (English)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: sugQEnCtrl,
              decoration: const InputDecoration(
                labelText: 'Suggestion Question (English)',
              ),
            ),
          ],
        ],
        onSubmit: (setError) async {
          final title = titleCtrl.text.trim();
          final rq = ratingQCtrl.text.trim();
          final sq = sugQCtrl.text.trim();
          if (title.isEmpty || rq.isEmpty || sq.isEmpty) {
            setError('تکایە سەرناو و هەردوو پرسیارەکە بنووسە');
            return false;
          }

          final payload = {
            'title': title,
            'title_kmr': titleKmrCtrl.text.trim(),
            'title_ar': titleArCtrl.text.trim(),
            'title_en': titleEnCtrl.text.trim(),
            'rating_question': rq,
            'rating_question_kmr': ratingQKmrCtrl.text.trim(),
            'rating_question_ar': ratingQArCtrl.text.trim(),
            'rating_question_en': ratingQEnCtrl.text.trim(),
            'suggestion_question': sq,
            'suggestion_question_kmr': sugQKmrCtrl.text.trim(),
            'suggestion_question_ar': sugQArCtrl.text.trim(),
            'suggestion_question_en': sugQEnCtrl.text.trim(),
            'is_active': isActive,
          };

          final res = isEdit
              ? await ApiClient.put(
                  '/admin/feedback-surveys/${existing['id']}',
                  body: payload,
                )
              : await ApiClient.post('/admin/feedback-surveys', body: payload);

          if (res.statusCode == 200 || res.statusCode == 201) {
            _load();
            return true;
          }
          setError(AdminUi.readError(res));
          return false;
        },
      );
    } finally {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        titleCtrl.dispose();
        titleKmrCtrl.dispose();
        titleArCtrl.dispose();
        titleEnCtrl.dispose();
        ratingQCtrl.dispose();
        ratingQKmrCtrl.dispose();
        ratingQArCtrl.dispose();
        ratingQEnCtrl.dispose();
        sugQCtrl.dispose();
        sugQKmrCtrl.dispose();
        sugQArCtrl.dispose();
        sugQEnCtrl.dispose();
      });
    }
  }

  Future<void> _openResponsesSheet(Map<String, dynamic> survey) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SurveyResponsesSheet(
        surveyId: int.tryParse('${survey['id']}') ?? 0,
        surveyTitle: (survey['title'] ?? '').toString(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AdminAppBar(
        title: 'فیدباک و هەڵسەنگاندن',
        subtitle: 'پرسیارەکانی بەکارهێنەران و وەڵامەکانیان',
        icon: Iconsax.message_favorite,
        iconColor: _indigo,
        iconBackgroundColor: _indigo.withValues(alpha: 0.12),
        showBackButton: true,
        actions: [
          AdminUi.primaryAction(
            label: 'زیادکردن',
            icon: Iconsax.add,
            onTap: () => _openSurveyForm(),
            color: _indigo,
          ),
        ],
      ),
      body: AdminUi.body(
        isLoading: _isLoading,
        error: _error,
        isEmpty: false,
        emptyIcon: Iconsax.message_favorite,
        emptyText: '',
        onRetry: _load,
        child: RefreshIndicator(
          onRefresh: _load,
          color: _indigo,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
            children: [
              _buildStatsGrid(),
              const SizedBox(height: 16),
              if (_surveys.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 42,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.getSurface(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.getBorder(context)),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Iconsax.message_favorite,
                        size: 50,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'هێشتا هیچ فیدباکێک ئامادە نەکراوە',
                        style: AdminUi.title,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'لێرە پرسیارەکان دروست بکە و چالاکی بکە تا بۆ یوزەرەکان دەربکەوێت',
                        textAlign: TextAlign.center,
                        style: AdminUi.subtitle,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _openSurveyForm(),
                        icon: const Icon(Iconsax.add, size: 18),
                        label: const Text(
                          'دروستکردنی یەکەم فیدباک',
                          style: TextStyle(fontFamily: 'Rabar'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...List.generate(
                  _surveys.length,
                  (i) => _buildSurveyCard(_surveys[i], i),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final totalSurveys = _stats['total_surveys'] ?? _surveys.length;
    final activeSurveys = _stats['active_surveys'] ??
        _surveys
            .where((s) => s['is_active'] == true || s['is_active'] == 1)
            .length;
    final totalResponses = _stats['total_responses'] ?? 0;
    final avgRating =
        double.tryParse('${_stats['overall_avg_rating'] ?? 0}') ?? 0.0;

    return Row(
      children: [
        Expanded(
          child: _statTile(
            label: 'فیدباکەکان',
            value: '$totalSurveys',
            sub: '$activeSurveys چالاک',
            icon: Iconsax.message_favorite,
            color: _indigo,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(
            label: 'وەڵامی یوزەرەکان',
            value: '$totalResponses',
            sub: 'کۆی گشتی',
            icon: Iconsax.people,
            color: _emerald,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statTile(
            label: 'تێکڕای ئەستێرە',
            value: avgRating > 0 ? avgRating.toStringAsFixed(1) : '0.0',
            sub: 'لە ٥ ئەستێرە',
            icon: Icons.star_rounded,
            color: _amber,
          ),
        ),
      ],
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextTitle(context),
            ),
          ),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 9.5,
              color: AppColors.getTextSubtitle(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyCard(Map<String, dynamic> survey, int index) {
    final isActive = survey['is_active'] == true || survey['is_active'] == 1;
    final responsesCount =
        int.tryParse('${survey['responses_count'] ?? 0}') ?? 0;
    final avgRating =
        double.tryParse('${survey['responses_avg_rating'] ?? 0}') ?? 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive
              ? _emerald.withValues(alpha: 0.45)
              : AppColors.getBorder(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: (isActive ? _emerald : const Color(0xFF64748B))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? 'چالاکە' : 'ناچالاکە',
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: isActive ? _emerald : const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (avgRating > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 13, color: _amber),
                      const SizedBox(width: 3),
                      Text(
                        avgRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: _amber,
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              Switch.adaptive(
                value: isActive,
                activeTrackColor: _emerald,
                onChanged: (_) => _toggleStatus(survey),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            (survey['title'] ?? '').toString(),
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextTitle(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '• ${(survey['rating_question'] ?? '').toString()}',
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 12,
              color: AppColors.getTextSubtitle(context),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '• ${(survey['suggestion_question'] ?? '').toString()}',
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 12,
              color: AppColors.getTextSubtitle(context),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openResponsesSheet(survey),
                  icon: const Icon(Iconsax.chart_2, size: 16),
                  label: Text(
                    'وەڵامەکان ($responsesCount)',
                    style: const TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _indigo.withValues(alpha: 0.1),
                    foregroundColor: _indigo,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'دەستکاری',
                onPressed: () => _openSurveyForm(existing: survey),
                icon: const Icon(Iconsax.edit_2, color: _indigo, size: 20),
              ),
              IconButton(
                tooltip: 'سڕینەوە',
                onPressed: () => _deleteSurvey(survey),
                icon: const Icon(Iconsax.trash, color: _rose, size: 20),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 40).ms);
  }
}

class _SurveyResponsesSheet extends StatefulWidget {
  final int surveyId;
  final String surveyTitle;

  const _SurveyResponsesSheet({
    required this.surveyId,
    required this.surveyTitle,
  });

  @override
  State<_SurveyResponsesSheet> createState() => _SurveyResponsesSheetState();
}

class _SurveyResponsesSheetState extends State<_SurveyResponsesSheet> {
  bool _isLoading = true;
  String? _error;
  double _avgRating = 0;
  Map<String, dynamic> _distribution = {};
  List<Map<String, dynamic>> _responses = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient.get(
        '/admin/feedback-surveys/${widget.surveyId}/responses',
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          _avgRating = double.tryParse('${body['avg_rating'] ?? 0}') ?? 0;
          _distribution =
              Map<String, dynamic>.from((body['distribution'] as Map?) ?? {});
          _responses = ((body['data'] as List?) ?? [])
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = AdminUi.readError(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _isLoading = false;
        });
      }
    }
  }

  String _satisfactionLabel(String? val) {
    return switch (val) {
      'satisfied' => 'زۆر ڕازیم',
      'neutral' => 'باشە',
      'unsatisfied' => 'پێویستی بە باشترکردنە',
      _ => '',
    };
  }

  Color _satisfactionColor(String? val) {
    return switch (val) {
      'satisfied' => const Color(0xFF059669),
      'neutral' => const Color(0xFFD97706),
      'unsatisfied' => const Color(0xFFE11D48),
      _ => const Color(0xFF64748B),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.surveyTitle,
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextTitle(context),
                      ),
                    ),
                    Text(
                      '${_responses.length} وەڵام • تێکڕا: ${_avgRating.toStringAsFixed(1)} ★',
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 11.5,
                        color: AppColors.getTextSubtitle(context),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const Divider(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: AdminUi.subtitle))
                    : _responses.isEmpty
                        ? Center(
                            child: Text(
                              'هێشتا هیچ بەکارهێنەرێک وەڵامی نەداوەتەوە',
                              style: AdminUi.subtitle,
                            ),
                          )
                        : ListView(
                            children: [
                              // Star breakdown
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.getBackground(context),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.getBorder(context),
                                  ),
                                ),
                                child: Column(
                                  children: List.generate(5, (idx) {
                                    final star = 5 - idx;
                                    final count = int.tryParse(
                                          '${_distribution['$star'] ?? 0}',
                                        ) ??
                                        0;
                                    final ratio = _responses.isEmpty
                                        ? 0.0
                                        : count / _responses.length;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 3,
                                      ),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 34,
                                            child: Text(
                                              '$star ★',
                                              style: const TextStyle(
                                                fontFamily: 'Rabar',
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFF59E0B),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              child: LinearProgressIndicator(
                                                value: ratio,
                                                minHeight: 7,
                                                backgroundColor:
                                                    Colors.grey.withValues(
                                                  alpha: 0.15,
                                                ),
                                                valueColor:
                                                    const AlwaysStoppedAnimation(
                                                  Color(0xFFF59E0B),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          SizedBox(
                                            width: 24,
                                            child: Text(
                                              '$count',
                                              textAlign: TextAlign.end,
                                              style: TextStyle(
                                                fontFamily: 'Rabar',
                                                fontSize: 11,
                                                color:
                                                    AppColors.getTextSubtitle(
                                                  context,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                              ),
                              const SizedBox(height: 14),
                              ..._responses.map((r) {
                                final user = r['user'] is Map
                                    ? (r['user'] as Map)
                                    : const {};
                                final name =
                                    (user['name'] ?? 'بەکارهێنەر').toString();
                                final phone = (user['phone'] ?? '').toString();
                                final rating =
                                    int.tryParse('${r['rating'] ?? 0}') ?? 0;
                                final sat = r['is_satisfied']?.toString();
                                final satLabel = _satisfactionLabel(sat);
                                final satColor = _satisfactionColor(sat);
                                final suggestion =
                                    (r['suggestion'] ?? '').toString().trim();
                                final dt = DateTime.tryParse(
                                  '${r['created_at'] ?? ''}',
                                );
                                final dateStr = dt != null
                                    ? intl.DateFormat('yyyy-MM-dd HH:mm')
                                        .format(dt.toUtc().add(
                                              const Duration(hours: 3),
                                            ))
                                    : '';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.getBackground(context),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppColors.getBorder(context),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              phone.isNotEmpty
                                                  ? '$name ($phone)'
                                                  : name,
                                              style: TextStyle(
                                                fontFamily: 'Rabar',
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.getTextTitle(
                                                  context,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: List.generate(
                                              5,
                                              (i) => Icon(
                                                i < rating
                                                    ? Icons.star_rounded
                                                    : Icons.star_outline_rounded,
                                                size: 15,
                                                color: const Color(0xFFF59E0B),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          if (satLabel.isNotEmpty)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: satColor.withValues(
                                                  alpha: 0.12,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                satLabel,
                                                style: TextStyle(
                                                  fontFamily: 'Rabar',
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: satColor,
                                                ),
                                              ),
                                            ),
                                          if (dateStr.isNotEmpty)
                                            Text(
                                              dateStr,
                                              style: TextStyle(
                                                fontFamily: 'Rabar',
                                                fontSize: 10,
                                                color:
                                                    AppColors.getTextSubtitle(
                                                  context,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (suggestion.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          suggestion,
                                          style: TextStyle(
                                            fontFamily: 'Rabar',
                                            fontSize: 12,
                                            color: AppColors.getTextTitle(
                                              context,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
          ),
        ],
      ),
    );
  }
}
