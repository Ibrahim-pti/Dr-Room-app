import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/api_client.dart';
import '../../core/utils/translation_helper.dart';
import 'admin_app_bar.dart';
import 'admin_ui.dart';

/// Admin screen for dynamically managing Step 2 options of the field-team
/// recruitment form: Education Levels (`education`) and Clinical Skills (`skill`).
/// Changes reflect immediately on the public /delivery registration form in all
/// four supported languages (ckb, kmr, ar, en).
class AdminRecruitmentOptionsScreen extends StatefulWidget {
  const AdminRecruitmentOptionsScreen({super.key});

  @override
  State<AdminRecruitmentOptionsScreen> createState() =>
      _AdminRecruitmentOptionsScreenState();
}

class _AdminRecruitmentOptionsScreenState
    extends State<AdminRecruitmentOptionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  bool _isLoading = true;
  String? _error;
  List<dynamic> _options = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging && mounted) {
        setState(() {});
      }
    });
    _loadOptions();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  String get _activeType => _tabCtrl.index == 0 ? 'education' : 'skill';

  List<dynamic> _filtered(String type) =>
      _options.where((o) => o['type'] == type).toList();

  Future<void> _loadOptions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await ApiClient.get('/admin/recruitment-options');
      if (!mounted) return;

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        setState(() {
          _options = decoded is List ? decoded : [];
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

  Future<void> _toggleActive(dynamic option) async {
    final nextVal = option['is_active'] == true ? '0' : '1';
    try {
      final res = await ApiClient.put(
        '/admin/recruitment-options/${option['id']}',
        body: {'is_active': nextVal},
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        await _loadOptions();
      } else {
        AdminUi.toast(context, AdminUi.readError(res), isError: true);
      }
    } catch (e) {
      if (mounted) AdminUi.toast(context, '$e', isError: true);
    }
  }

  Future<void> _deleteOption(dynamic option) async {
    final ok = await AdminUi.confirm(
      context,
      title: 'سڕینەوەی بژاردە',
      message: 'ئایا دڵنیایت لە سڕینەوەی «${option['label_ckb']}»؟',
    );
    if (!ok) return;

    try {
      final res = await ApiClient.delete(
        '/admin/recruitment-options/${option['id']}',
      );
      if (!mounted) return;
      if (res.statusCode == 204 || res.statusCode == 200) {
        AdminUi.toast(context, 'بژاردەکە سڕایەوە.');
        await _loadOptions();
      } else {
        AdminUi.toast(context, AdminUi.readError(res), isError: true);
      }
    } catch (e) {
      if (mounted) AdminUi.toast(context, '$e', isError: true);
    }
  }

  Future<void> _openForm({dynamic existing}) async {
    final isEditing = existing != null;
    final type = isEditing ? (existing['type'] ?? _activeType) : _activeType;
    final typeLabel = type == 'education'
        ? 'بڕوانامە / ئاستی خوێندن'
        : 'شارەزایی و توانای کرداری';

    final ckbCtrl = TextEditingController(
      text: isEditing ? (existing['label_ckb'] ?? '') : '',
    );
    final kmrCtrl = TextEditingController(
      text: isEditing ? (existing['label_kmr'] ?? '') : '',
    );
    final arCtrl = TextEditingController(
      text: isEditing ? (existing['label_ar'] ?? '') : '',
    );
    final enCtrl = TextEditingController(
      text: isEditing ? (existing['label_en'] ?? '') : '',
    );
    final orderCtrl = TextEditingController(
      text: isEditing
          ? '${existing['sort_order'] ?? 0}'
          : '${_filtered(type).length + 1}',
    );

    bool isActive = isEditing ? (existing['is_active'] ?? true) : true;
    bool isTranslating = false;

    try {
      await AdminUi.formSheet(
        context: context,
        title: isEditing ? 'دەستکاریکردنی $typeLabel' : 'زیادکردنی $typeLabel',
        subtitle:
            'ئەم بژاردەیە ڕاستەوخۆ لە هەنگاوی ٢ی فۆڕمی تۆمارکردنی تیمی گەڕۆک دەردەکەوێت.',
        submitLabel: isEditing ? 'پاشەکەوتکردن' : 'زیادکردن',
        builder: (setSheetState, setError) => [
          AdminUi.notice(
            'ناو بە سۆرانی بنووسە و دوگمەی وەرگێڕان دابگرە بۆ وەرگێڕانی خۆکار بۆ بادینی و عەرەبی و ئینگلیزی، یان بە دەست گۆڕانکارییان تێدا بکە.',
          ),
          const SizedBox(height: 14),

          // Auto-translate action bar
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
                  child: const Icon(
                    Iconsax.translate,
                    color: Color(0xFF16A34A),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'وەرگێڕانی خۆکار بۆ هەموو زمانەکان',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF166534),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: isTranslating
                      ? null
                      : () async {
                          final source = ckbCtrl.text.trim();
                          if (source.isEmpty) {
                            setError('تکایە سەرەتا دەقی کوردی سۆرانی بنووسە.');
                            return;
                          }
                          setError(null);
                          setSheetState(() => isTranslating = true);
                          try {
                            final tr = await TranslationHelper.translate(source);
                            kmrCtrl.text = tr['kmr'] ?? '';
                            arCtrl.text = tr['ar'] ?? '';
                            enCtrl.text = tr['en'] ?? '';
                          } finally {
                            setSheetState(() => isTranslating = false);
                          }
                        },
                  icon: isTranslating
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Iconsax.magicpen,
                          size: 13,
                          color: Colors.white,
                        ),
                  label: Text(
                    isTranslating ? 'وەرگێڕان...' : 'وەرگێڕان',
                    style: const TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          AdminUi.label('ناو بە کوردی سۆرانی *'),
          const SizedBox(height: 6),
          AdminUi.input(
            controller: ckbCtrl,
            hint: type == 'education'
                ? 'وەک: دبلۆم لە شیکاری نەخۆشییەکان'
                : 'وەک: کێشانی خوێن و دەرهێنانی نموونە',
          ),
          const SizedBox(height: 14),

          AdminUi.label('ناو بە کوردی بادینی'),
          const SizedBox(height: 6),
          AdminUi.input(
            controller: kmrCtrl,
            hint: 'وەک: دبلۆم د شیکاریا نەخۆشیان دا',
          ),
          const SizedBox(height: 14),

          AdminUi.label('ناو بە عەرەبی'),
          const SizedBox(height: 6),
          AdminUi.input(
            controller: arCtrl,
            hint: 'مثال: دبلوم تحليلات مرضية',
          ),
          const SizedBox(height: 14),

          AdminUi.label('ناو بە ئینگلیزی'),
          const SizedBox(height: 6),
          AdminUi.input(
            controller: enCtrl,
            hint: 'Example: Diploma in Medical Lab Science',
          ),
          const SizedBox(height: 14),

          AdminUi.label('ڕیزبەندی (بچووکتر = پێشتر)'),
          const SizedBox(height: 6),
          AdminUi.input(
            controller: orderCtrl,
            hint: '1',
            keyboard: TextInputType.number,
          ),
          const SizedBox(height: 8),

          AdminUi.checkboxRow(
            label: 'چالاکە (لە وێبسایت و فۆڕمی تۆمارکردندا پیشان بدرێت)',
            value: isActive,
            onChanged: (v) => setSheetState(() => isActive = v ?? true),
          ),
        ],
        onSubmit: (setError) async {
          final ckb = ckbCtrl.text.trim();
          if (ckb.isEmpty) {
            setError('تکایە ناو بە کوردی سۆرانی پڕبکەرەوە.');
            return false;
          }

          if (kmrCtrl.text.trim().isEmpty ||
              arCtrl.text.trim().isEmpty ||
              enCtrl.text.trim().isEmpty) {
            final tr = await TranslationHelper.translate(ckb);
            if (kmrCtrl.text.trim().isEmpty) kmrCtrl.text = tr['kmr'] ?? ckb;
            if (arCtrl.text.trim().isEmpty) arCtrl.text = tr['ar'] ?? ckb;
            if (enCtrl.text.trim().isEmpty) enCtrl.text = tr['en'] ?? ckb;
          }

          final body = {
            if (!isEditing) 'type': type,
            'label_ckb': ckb,
            'label_kmr': kmrCtrl.text.trim(),
            'label_ar': arCtrl.text.trim(),
            'label_en': enCtrl.text.trim(),
            'sort_order':
                orderCtrl.text.trim().isEmpty ? '0' : orderCtrl.text.trim(),
            'is_active': isActive ? '1' : '0',
          };

          final res = isEditing
              ? await ApiClient.put(
                  '/admin/recruitment-options/${existing['id']}',
                  body: body,
                )
              : await ApiClient.post('/admin/recruitment-options', body: body);

          if (res.statusCode == 200 || res.statusCode == 201) {
            await _loadOptions();
            return true;
          }

          setError(AdminUi.readError(res));
          return false;
        },
      );
    } finally {
      ckbCtrl.dispose();
      kmrCtrl.dispose();
      arCtrl.dispose();
      enCtrl.dispose();
      orderCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final eduCount = _filtered('education').length;
    final skillCount = _filtered('skill').length;
    final items = _filtered(_activeType);

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AdminAppBar(
        title: 'بڕوانامە و شارەزایی تیمی گەڕۆک',
        subtitle: 'بەڕێوەبردنی بژاردەکانی هەنگاوی ٢ لە وێبسایت',
        icon: Iconsax.book_1,
        iconColor: const Color(0xFFEA580C),
        iconBackgroundColor: const Color(0xFFEA580C).withValues(alpha: 0.12),
        showBackButton: true,
        actions: [
          IconButton(
            onPressed: _loadOptions,
            icon: const Icon(Iconsax.refresh, color: Color(0xFF64748B)),
            tooltip: 'نوێکردنەوە',
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: AdminUi.primaryAction(
              label: 'زیادکردن',
              icon: Iconsax.add,
              onTap: () => _openForm(),
              color: const Color(0xFFEA580C),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.getSurface(context),
            child: TabBar(
              controller: _tabCtrl,
              labelColor: const Color(0xFFEA580C),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFFEA580C),
              labelStyle: const TextStyle(
                fontFamily: 'Rabar',
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              tabs: [
                Tab(text: 'بڕوانامە و خوێندن ($eduCount)'),
                Tab(text: 'شارەزایی کرداری ($skillCount)'),
              ],
            ),
          ),
          Expanded(
            child: AdminUi.body(
              isLoading: _isLoading,
              error: _error,
              isEmpty: items.isEmpty,
              emptyIcon: Iconsax.book_1,
              emptyText: 'هیچ بژاردەیەک تۆمارنەکراوە',
              onRetry: _loadOptions,
              child: RefreshIndicator(
                onRefresh: _loadOptions,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 90),
                  itemCount: items.length,
                  itemBuilder: (_, idx) => _buildOptionCard(items[idx]),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: const Color(0xFFEA580C),
        icon: const Icon(Iconsax.add, color: Colors.white),
        label: Text(
          _activeType == 'education' ? 'زیادکردنی بڕوانامە' : 'زیادکردنی شارەزایی',
          style: const TextStyle(
            fontFamily: 'Rabar',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(dynamic item) {
    final active = item['is_active'] == true;
    final kmr = (item['label_kmr'] ?? '').toString().trim();
    final ar = (item['label_ar'] ?? '').toString().trim();
    final en = (item['label_en'] ?? '').toString().trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: AdminUi.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Text(
                  '#${item['sort_order'] ?? 0}',
                  style: const TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC2410C),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  (item['label_ckb'] ?? '').toString(),
                  style: AdminUi.title.copyWith(
                    color: active ? null : const Color(0xFF94A3B8),
                  ),
                ),
              ),
              Switch(
                value: active,
                activeThumbColor: const Color(0xFF16A34A),
                onChanged: (_) => _toggleActive(item),
              ),
            ],
          ),
          if (kmr.isNotEmpty || ar.isNotEmpty || en.isNotEmpty) ...[
            const SizedBox(height: 8),
            if (kmr.isNotEmpty) _langRow('بادینی', kmr),
            if (ar.isNotEmpty) _langRow('عەرەبی', ar),
            if (en.isNotEmpty) _langRow('English', en, ltr: true),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AdminUi.smallButton(
                  label: 'دەستکاری و وەرگێڕان',
                  icon: Iconsax.edit_2,
                  color: const Color(0xFF2563EB),
                  onTap: () => _openForm(existing: item),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AdminUi.smallButton(
                  label: 'سڕینەوە',
                  icon: Iconsax.trash,
                  color: const Color(0xFFEF4444),
                  onTap: () => _deleteOption(item),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _langRow(String lang, String text, {bool ltr = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              lang,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Rabar',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
              style: AdminUi.subtitle,
            ),
          ),
        ],
      ),
    );
  }
}
