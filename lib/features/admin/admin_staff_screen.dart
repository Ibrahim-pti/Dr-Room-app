import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/utils/api_client.dart';
import 'admin_app_bar.dart';
import 'admin_ui.dart';

/// Staff accounts, their role, and the individual permissions each one holds.
class AdminStaffScreen extends StatefulWidget {
  const AdminStaffScreen({super.key});

  @override
  State<AdminStaffScreen> createState() => _AdminStaffScreenState();
}

class _AdminStaffScreenState extends State<AdminStaffScreen> {
  List<dynamic> _staff = [];
  List<dynamic> _roles = [];
  List<dynamic> _permissions = [];
  bool _isLoading = true;
  String? _error;

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
      final results = await Future.wait([
        ApiClient.get('/admin/staff'),
        ApiClient.get('/admin/staff/meta'),
      ]);

      if (!mounted) return;

      if (results[0].statusCode == 200 && results[1].statusCode == 200) {
        final meta = jsonDecode(results[1].body);
        setState(() {
          _staff = jsonDecode(results[0].body);
          _roles = meta['roles'] ?? [];
          _permissions = meta['permissions'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = AdminUi.readError(results[0]);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _isLoading = false; });
    }
  }

  Future<void> _delete(dynamic staff) async {
    final ok = await AdminUi.confirm(
      context,
      title: 'سڕینەوەی ستاف',
      message: 'ئایا دڵنیایت لە سڕینەوەی «${staff['name']}»؟',
    );
    if (!ok) return;

    final res = await ApiClient.delete('/admin/staff/${staff['id']}');
    if (!mounted) return;

    if (res.statusCode == 204 || res.statusCode == 200) {
      AdminUi.toast(context, 'ستافەکە سڕایەوە.');
      _load();
    } else {
      AdminUi.toast(context, AdminUi.readError(res), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AdminAppBar(
        title: 'ستاف و دەسەڵاتەکان',
        subtitle: '${_staff.length} هەژماری ستاف',
        icon: Iconsax.security_user,
        iconColor: const Color(0xFF4F46E5),
        iconBackgroundColor: const Color(0xFFEEF2FF),
        actions: [
          AdminUi.primaryAction(
            label: 'ستافی نوێ',
            icon: Iconsax.user_add,
            onTap: () => _openForm(),
          ),
        ],
      ),
      body: AdminUi.body(
        isLoading: _isLoading,
        error: _error,
        isEmpty: _staff.isEmpty,
        emptyIcon: Iconsax.security_user,
        emptyText: 'هێشتا هیچ ستافێک زیاد نەکراوە',
        onRetry: _load,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _staff.length,
            itemBuilder: (context, i) => _buildCard(_staff[i], i),
          ),
        ),
      ),
    );
  }

  Widget _buildCard(dynamic staff, int index) {
    final isBlocked = staff['status'] == 'blocked';
    final perms = (staff['permissions'] as List?) ?? [];
    final roleColor = _roleColor(staff['role']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AdminUi.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Iconsax.user, color: roleColor, size: 22),
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
                            staff['name'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AdminUi.title,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AdminUi.chip(staff['role_label'] ?? staff['role'] ?? '', roleColor),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      staff['email'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AdminUi.subtitle,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isBlocked) ...[
            const SizedBox(height: 10),
            AdminUi.chip('ڕاگیراوە', const Color(0xFFEF4444)),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: perms.map<Widget>((p) {
              final label = _permissions.firstWhere(
                (x) => x['value'] == p,
                orElse: () => {'label': p},
              )['label'];
              return AdminUi.chip(label, const Color(0xFF64748B), small: true);
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AdminUi.smallButton(
                  label: 'دەستکاری',
                  icon: Iconsax.edit_2,
                  color: const Color(0xFF2563EB),
                  onTap: () => _openForm(existing: staff),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AdminUi.smallButton(
                  label: 'سڕینەوە',
                  icon: Iconsax.trash,
                  color: const Color(0xFFEF4444),
                  onTap: () => _delete(staff),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideY(begin: 0.05, end: 0);
  }

  Color _roleColor(String? role) => switch (role) {
        'admin' => const Color(0xFF4F46E5),
        'moderator' => const Color(0xFF0D9488),
        _ => const Color(0xFFD97706),
      };

  Future<void> _openForm({dynamic existing}) async {
    final isEditing = existing != null;
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final emailCtrl = TextEditingController(text: existing?['email'] ?? '');
    final phoneCtrl = TextEditingController(text: existing?['phone'] ?? '');
    final passCtrl = TextEditingController();

    String role = existing?['role'] ?? 'staff';
    bool blocked = existing?['status'] == 'blocked';
    // Null while the user has not touched the checkboxes: keep role defaults.
    List<String>? customPerms = (existing?['is_custom'] == true)
        ? List<String>.from(existing['permissions'] ?? [])
        : null;

    List<String> defaultsFor(String r) => List<String>.from(
          _roles.firstWhere((x) => x['value'] == r,
              orElse: () => {'default_permissions': []})['default_permissions'] ?? [],
        );

    await AdminUi.formSheet(
      context: context,
      title: isEditing ? 'دەستکاریکردنی ستاف' : 'ستافی نوێ',
      subtitle: 'ڕۆڵ و دەسەڵاتەکانی هەژمار دیاری بکە',
      submitLabel: isEditing ? 'نوێکردنەوە' : 'دروستکردنی هەژمار',
      builder: (setSheetState, setError) => [
        AdminUi.label('ناوی تەواو *'),
        AdminUi.input(controller: nameCtrl, hint: 'ناوی ستاف'),
        const SizedBox(height: 14),

        AdminUi.label('ئیمەیل *'),
        AdminUi.input(controller: emailCtrl, hint: 'staff@drroom.com', keyboard: TextInputType.emailAddress),
        const SizedBox(height: 14),

        AdminUi.label('ژمارەی مۆبایل'),
        AdminUi.input(controller: phoneCtrl, hint: '07xx xxx xxxx', keyboard: TextInputType.phone),
        const SizedBox(height: 14),

        AdminUi.label(isEditing ? 'وشەی نهێنی نوێ (بەتاڵی بهێڵەرەوە بۆ نەگۆڕین)' : 'وشەی نهێنی *'),
        AdminUi.input(controller: passCtrl, hint: 'بەلایەنی کەم ٦ پیت', obscure: true),
        const SizedBox(height: 16),

        AdminUi.label('ڕۆڵ'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _roles.map<Widget>((r) {
            final selected = role == r['value'];
            return GestureDetector(
              onTap: () => setSheetState(() {
                role = r['value'];
                customPerms = null; // fall back to the new role's defaults
              }),
              child: AdminUi.selectChip(r['label'], selected),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        if (role != 'admin') ...[
          Row(
            children: [
              Expanded(child: AdminUi.label('دەسەڵاتەکان')),
              if (customPerms != null)
                GestureDetector(
                  onTap: () => setSheetState(() => customPerms = null),
                  child: const Text(
                    'گەڕانەوە بۆ بنەڕەت',
                    style: TextStyle(fontFamily: 'Rabar', fontSize: 11.5, color: Color(0xFF2563EB)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ..._permissions.map<Widget>((p) {
            final effective = customPerms ?? defaultsFor(role);
            final checked = effective.contains(p['value']);
            return AdminUi.checkboxRow(
              label: p['label'],
              value: checked,
              onChanged: (v) => setSheetState(() {
                final next = List<String>.from(customPerms ?? defaultsFor(role));
                v == true ? next.add(p['value']) : next.remove(p['value']);
                customPerms = next;
              }),
            );
          }),
        ] else
          AdminUi.notice('ئەدمینی سەرەکی هەموو دەسەڵاتەکانی هەیە و ناتوانرێت سنووردار بکرێت.'),

        if (isEditing) ...[
          const SizedBox(height: 8),
          AdminUi.checkboxRow(
            label: 'ڕاگرتنی هەژمار (بلۆک)',
            value: blocked,
            onChanged: (v) => setSheetState(() => blocked = v ?? false),
          ),
        ],
      ],
      onSubmit: (setError) async {
        if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) {
          setError('تکایە ناو و ئیمەیل پڕبکەرەوە.');
          return false;
        }
        if (!isEditing && passCtrl.text.trim().length < 6) {
          setError('وشەی نهێنی دەبێت بەلایەنی کەم ٦ پیت بێت.');
          return false;
        }

        final body = <String, dynamic>{
          'name': nameCtrl.text.trim(),
          'email': emailCtrl.text.trim(),
          'phone': phoneCtrl.text.trim(),
          'role': role,
        };

        if (passCtrl.text.trim().isNotEmpty) body['password'] = passCtrl.text.trim();
        if (isEditing) body['status'] = blocked ? 'blocked' : 'approved';
        if (role != 'admin' && customPerms != null) body['permissions'] = customPerms;

        final res = isEditing
            ? await ApiClient.put('/admin/staff/${existing['id']}', body: body)
            : await ApiClient.post('/admin/staff', body: body);

        if (res.statusCode == 200 || res.statusCode == 201) {
          _load();
          return true;
        }

        setError(AdminUi.readError(res));
        return false;
      },
    );
  }
}
