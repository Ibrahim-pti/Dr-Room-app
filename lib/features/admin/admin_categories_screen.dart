import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/utils/api_client.dart';
import 'admin_app_bar.dart';
import 'admin_ui.dart';

/// One screen for every category list in the app — nursing specialties, lab
/// test groups, pharmacy sections, doctor specialties, first-aid topics.
/// Adding a category here changes the app without a rebuild.
class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  List<dynamic> _scopes = [];
  List<dynamic> _categories = [];
  String? _selectedScope;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadScopes();
  }

  Future<void> _loadScopes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await ApiClient.get('/admin/service-categories/scopes');
      if (!mounted) return;

      if (res.statusCode == 200) {
        final scopes = jsonDecode(res.body) as List;
        setState(() {
          _scopes = scopes;
          _selectedScope ??= scopes.isNotEmpty ? scopes.first['value'] : null;
        });
        await _loadCategories();
      } else {
        setState(() {
          _error = AdminUi.readError(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _isLoading = false; });
    }
  }

  Future<void> _loadCategories() async {
    if (_selectedScope == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ApiClient.get('/admin/service-categories?scope=$_selectedScope');
      if (!mounted) return;

      setState(() {
        _categories = res.statusCode == 200 ? jsonDecode(res.body) : [];
        _error = res.statusCode == 200 ? null : AdminUi.readError(res);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _isLoading = false; });
    }
  }

  Future<void> _delete(dynamic category) async {
    final ok = await AdminUi.confirm(
      context,
      title: 'سڕینەوەی کەتەگۆری',
      message: 'ئایا دڵنیایت لە سڕینەوەی «${category['name']}»؟',
    );
    if (!ok) return;

    final res = await ApiClient.delete('/admin/service-categories/${category['id']}');
    if (!mounted) return;

    if (res.statusCode == 204 || res.statusCode == 200) {
      AdminUi.toast(context, 'کەتەگۆرییەکە سڕایەوە.');
      _loadScopes();
    } else {
      AdminUi.toast(context, AdminUi.readError(res), isError: true);
    }
  }

  Future<void> _toggleActive(dynamic category) async {
    final res = await ApiClient.put(
      '/admin/service-categories/${category['id']}',
      body: {'is_active': category['is_active'] == true ? '0' : '1'},
    );

    if (!mounted) return;

    if (res.statusCode == 200) {
      _loadCategories();
    } else {
      AdminUi.toast(context, AdminUi.readError(res), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AdminAppBar(
        title: 'کەتەگۆرییەکان',
        subtitle: 'بەڕێوەبردنی هەموو لیستەکانی ئەپ',
        icon: Iconsax.category,
        iconColor: const Color(0xFF0D9488),
        iconBackgroundColor: const Color(0xFFF0FDFA),
        actions: [
          AdminUi.primaryAction(
            label: 'کەتەگۆری نوێ',
            icon: Iconsax.add,
            onTap: () => _openForm(),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_scopes.isNotEmpty)
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _scopes.length,
                separatorBuilder: (context, i) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final scope = _scopes[i];
                  final selected = _selectedScope == scope['value'];
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedScope = scope['value']);
                      _loadCategories();
                    },
                    child: AdminUi.selectChip('${scope['label']} (${scope['count']})', selected),
                  );
                },
              ),
            ),
          Expanded(
            child: AdminUi.body(
              isLoading: _isLoading,
              error: _error,
              isEmpty: _categories.isEmpty,
              emptyIcon: Iconsax.category,
              emptyText: 'هیچ کەتەگۆرییەک لەم بەشەدا نییە',
              onRetry: _loadScopes,
              child: RefreshIndicator(
                onRefresh: _loadCategories,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _categories.length,
                  itemBuilder: (context, i) => _buildCard(_categories[i], i),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(dynamic category, int index) {
    final isActive = category['is_active'] == true;
    final color = _parseColor(category['color']) ?? const Color(0xFF0D9488);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: AdminUi.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isActive ? 0.12 : 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Iconsax.category,
                color: isActive ? color : const Color(0xFFCBD5E1), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category['name'] ?? '',
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: AdminUi.title),
                if ((category['name_en'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(category['name_en'], style: AdminUi.subtitle),
                ],
              ],
            ),
          ),
          if (!isActive) AdminUi.chip('ناچالاک', const Color(0xFF94A3B8), small: true),
          IconButton(
            onPressed: () => _toggleActive(category),
            tooltip: isActive ? 'ناچالاککردن' : 'چالاککردن',
            icon: Icon(isActive ? Iconsax.eye : Iconsax.eye_slash,
                size: 18, color: const Color(0xFF64748B)),
          ),
          IconButton(
            onPressed: () => _openForm(existing: category),
            tooltip: 'دەستکاری',
            icon: const Icon(Iconsax.edit_2, size: 18, color: Color(0xFF2563EB)),
          ),
          IconButton(
            onPressed: () => _delete(category),
            tooltip: 'سڕینەوە',
            icon: const Icon(Iconsax.trash, size: 18, color: Color(0xFFEF4444)),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 40).ms);
  }

  Color? _parseColor(dynamic hex) {
    if (hex is! String || !hex.startsWith('#') || hex.length < 7) return null;
    return Color(int.parse('FF${hex.substring(1, 7)}', radix: 16));
  }

  Future<void> _openForm({dynamic existing}) async {
    final isEditing = existing != null;
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final nameEnCtrl = TextEditingController(text: existing?['name_en'] ?? '');
    final nameArCtrl = TextEditingController(text: existing?['name_ar'] ?? '');
    final orderCtrl = TextEditingController(text: '${existing?['sort_order'] ?? 0}');

    String scope = existing?['scope'] ?? _selectedScope ?? 'nursing';
    bool isActive = existing == null ? true : existing['is_active'] == true;

    await AdminUi.formSheet(
      context: context,
      title: isEditing ? 'دەستکاریکردنی کەتەگۆری' : 'کەتەگۆری نوێ',
      subtitle: 'ئەم ناوە ڕاستەوخۆ لە ئەپەکەدا دەردەکەوێت',
      submitLabel: isEditing ? 'نوێکردنەوە' : 'زیادکردن',
      builder: (setSheetState, setError) => [
        AdminUi.label('بەشەکە *'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _scopes.map<Widget>((s) {
            return GestureDetector(
              onTap: () => setSheetState(() => scope = s['value']),
              child: AdminUi.selectChip(s['label'], scope == s['value']),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        AdminUi.label('ناو بە کوردی *'),
        const SizedBox(height: 6),
        AdminUi.input(controller: nameCtrl, hint: 'وەک: چاودێری ماڵەوە'),
        const SizedBox(height: 14),

        AdminUi.label('ناو بە ئینگلیزی'),
        const SizedBox(height: 6),
        AdminUi.input(controller: nameEnCtrl, hint: 'Home Care'),
        const SizedBox(height: 14),

        AdminUi.label('ناو بە عەرەبی'),
        const SizedBox(height: 6),
        AdminUi.input(controller: nameArCtrl, hint: 'الرعاية المنزلية'),
        const SizedBox(height: 14),

        AdminUi.label('ڕیزبەندی (بچووکتر = پێشتر)'),
        const SizedBox(height: 6),
        AdminUi.input(controller: orderCtrl, hint: '0', keyboard: TextInputType.number),
        const SizedBox(height: 8),

        AdminUi.checkboxRow(
          label: 'چالاکە (لە ئەپەکەدا دەردەکەوێت)',
          value: isActive,
          onChanged: (v) => setSheetState(() => isActive = v ?? true),
        ),
      ],
      onSubmit: (setError) async {
        if (nameCtrl.text.trim().isEmpty) {
          setError('تکایە ناوی کوردی پڕبکەرەوە.');
          return false;
        }

        final body = {
          'scope': scope,
          'name': nameCtrl.text.trim(),
          'name_en': nameEnCtrl.text.trim(),
          'name_ar': nameArCtrl.text.trim(),
          'sort_order': orderCtrl.text.trim().isEmpty ? '0' : orderCtrl.text.trim(),
          'is_active': isActive ? '1' : '0',
        };

        final res = isEditing
            ? await ApiClient.put('/admin/service-categories/${existing['id']}', body: body)
            : await ApiClient.post('/admin/service-categories', body: body);

        if (res.statusCode == 200 || res.statusCode == 201) {
          _loadScopes();
          return true;
        }

        setError(AdminUi.readError(res));
        return false;
      },
    );
  }
}
