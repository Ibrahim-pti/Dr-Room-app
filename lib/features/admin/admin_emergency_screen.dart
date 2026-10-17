import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/api_client.dart';
import 'admin_app_bar.dart';
import 'admin_ui.dart';

class AdminEmergencyScreen extends StatefulWidget {
  const AdminEmergencyScreen({super.key});

  @override
  State<AdminEmergencyScreen> createState() => _AdminEmergencyScreenState();
}

class _AdminEmergencyScreenState extends State<AdminEmergencyScreen> {
  List<dynamic> _contacts = [];
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
      final res = await ApiClient.get('/admin/emergency-contacts');
      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _contacts = data is List ? data : [];
          _isLoading = false;
        });
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

  Future<void> _makeCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _toggleActive(dynamic contact) async {
    final id = contact['id'];
    try {
      final res = await ApiClient.patch('/admin/emergency-contacts/$id/toggle');
      if (res.statusCode == 200) {
        _load();
      } else if (mounted) {
        AdminUi.toast(context, AdminUi.readError(res), isError: true);
      }
    } catch (e) {
      if (mounted) AdminUi.toast(context, '$e', isError: true);
    }
  }

  Future<void> _delete(dynamic contact) async {
    final ok = await AdminUi.confirm(
      context,
      title: 'سڕینەوەی ژمارەی فریاکەوتن',
      message: 'ئایا دڵنیایت لە سڕینەوەی «${contact['title']}»؟',
    );

    if (!ok) return;

    try {
      final res = await ApiClient.delete('/admin/emergency-contacts/${contact['id']}');
      if (res.statusCode == 200) {
        _load();
        if (mounted) AdminUi.toast(context, 'بە سەرکەوتوویی سڕایەوە');
      } else if (mounted) {
        AdminUi.toast(context, AdminUi.readError(res), isError: true);
      }
    } catch (e) {
      if (mounted) AdminUi.toast(context, '$e', isError: true);
    }
  }

  Future<void> _openForm([dynamic contact]) async {
    final isEdit = contact != null;
    final titleCtrl = TextEditingController(text: contact?['title'] ?? '');
    final subCtrl = TextEditingController(text: contact?['subtitle'] ?? '');
    final phoneCtrl = TextEditingController(text: contact?['phone'] ?? '');
    String selectedIcon = contact?['icon_type'] ?? 'hospital';
    bool isPrimary = contact?['is_primary'] == true;
    bool isActive = contact?['is_active'] != false;

    await AdminUi.formSheet(
      context: context,
      title: isEdit ? 'دەستکاریکردنی ژمارەی فریاکەوتن' : 'زیادکردنی ژمارەی فریاکەوتن',
      subtitle: isEdit ? contact['title'] : 'زیادکردنی ناوەند یان نەخۆشخانەی فریاکەوتن',
      submitLabel: isEdit ? 'نوێکردنەوە' : 'زیادکردن',
      builder: (setSheetState, setError) => [
        AdminUi.label('ناوی ناوەند / نەخۆشخانە *'),
        const SizedBox(height: 6),
        AdminUi.input(controller: titleCtrl, hint: 'نموونە: نەخۆشخانەی فریاکەوتنی ڕۆژئاوا'),
        const SizedBox(height: 14),

        AdminUi.label('کورتە / ڕوونکردنەوە'),
        const SizedBox(height: 6),
        AdminUi.input(controller: subCtrl, hint: 'نموونە: بۆ حاڵەتە لەناکاو و نەشتەرگەرییە بەپەلەکان'),
        const SizedBox(height: 14),

        AdminUi.label('ژمارەی تەلەفۆن *'),
        const SizedBox(height: 6),
        AdminUi.input(controller: phoneCtrl, hint: 'نموونە: 122 یان 0662234567'),
        const SizedBox(height: 14),

        AdminUi.label('جۆری ئایکۆن'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ('ambulance', 'ئەمبوڵانس', Icons.emergency),
            ('hospital', 'نەخۆشخانە', Iconsax.hospital),
            ('blood_bank', 'بانکی خوێن', Icons.water_drop),
            ('general', 'گشتی', Icons.call),
          ].map((type) {
            final isSel = selectedIcon == type.$1;
            return GestureDetector(
              onTap: () => setSheetState(() => selectedIcon = type.$1),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFFEF4444) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSel ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(type.$3, size: 16, color: isSel ? Colors.white : const Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      type.$2,
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSel ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Checkbox(
              value: isActive,
              activeColor: const Color(0xFF10B981),
              onChanged: (val) => setSheetState(() => isActive = val ?? true),
            ),
            const Text('لە ئەپەکەدا چالاک بێت و دەربکەوێت',
                style: TextStyle(fontFamily: 'Rabar', fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
        Row(
          children: [
            Checkbox(
              value: isPrimary,
              activeColor: const Color(0xFFEF4444),
              onChanged: (val) => setSheetState(() => isPrimary = val ?? false),
            ),
            const Text('ژمارەی سەرەکی (Primary SOS Button)',
                style: TextStyle(fontFamily: 'Rabar', fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
      onSubmit: (setError) async {
        if (titleCtrl.text.trim().isEmpty) {
          setError('تکایە ناوی ناوەند بنووسە');
          return false;
        }
        if (phoneCtrl.text.trim().isEmpty) {
          setError('تکایە ژمارەی تەلەفۆن بنووسە');
          return false;
        }

        final payload = {
          'title': titleCtrl.text.trim(),
          'subtitle': subCtrl.text.trim().isEmpty ? null : subCtrl.text.trim(),
          'phone': phoneCtrl.text.trim(),
          'icon_type': selectedIcon,
          'is_primary': isPrimary,
          'is_active': isActive,
        };

        final res = isEdit
            ? await ApiClient.put('/admin/emergency-contacts/${contact['id']}', body: payload)
            : await ApiClient.post('/admin/emergency-contacts', body: payload);

        if (res.statusCode == 200 || res.statusCode == 201) {
          _load();
          return true;
        }

        setError(AdminUi.readError(res));
        return false;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeCount = _contacts.where((c) => c['is_active'] == true).length;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AdminAppBar(
        title: 'فریاکەوتن و حاڵەتی لەناکاو',
        subtitle: 'بەڕێوەبردنی ژمارە و ناوەندەکانی SOS',
        icon: Icons.emergency,
        iconColor: const Color(0xFFEF4444),
        iconBackgroundColor: const Color(0xFFFEE2E2),
        showBackButton: true,
        actions: [
          IconButton(
            onPressed: () => _openForm(),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add, size: 18, color: Colors.white),
            ),
            tooltip: 'زیادکردنی ژمارە',
          ),
        ],
      ),
      body: AdminUi.body(
        isLoading: _isLoading,
        error: _error,
        isEmpty: _contacts.isEmpty,
        emptyIcon: Icons.emergency,
        emptyText: 'هیچ ژمارەیەکی فریاکەوتن تۆمار نەکراوە',
        onRetry: _load,
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.emergency, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'حاڵەتی لەناکاو و فریاکەوتن (SOS)',
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$activeCount لە ${_contacts.length} ژمارە لە ناو ئەپەکەدا چالاکن',
                            style: const TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.05, end: 0),
              const SizedBox(height: 16),

              // Contacts List
              ...List.generate(_contacts.length, (i) => _buildContactCard(_contacts[i], i)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(dynamic contact, int index) {
    final isActive = contact['is_active'] == true;
    final isPrimary = contact['is_primary'] == true;
    final iconType = contact['icon_type'] ?? 'hospital';

    final (icon, color) = switch (iconType) {
      'ambulance' => (Icons.emergency, const Color(0xFFEF4444)),
      'blood_bank' => (Icons.water_drop, const Color(0xFFE11D48)),
      'general' => (Icons.call, const Color(0xFF10B981)),
      _ => (Iconsax.hospital, const Color(0xFF3B82F6)),
    };

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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
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
                            contact['title'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AdminUi.title,
                          ),
                        ),
                        if (isPrimary) ...[
                          const SizedBox(width: 6),
                          AdminUi.chip('سەرەکی', const Color(0xFFEF4444), small: true),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      contact['subtitle'] ?? 'بێ کورتە',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AdminUi.subtitle,
                    ),
                  ],
                ),
              ),
              Switch(
                value: isActive,
                activeThumbColor: const Color(0xFF10B981),
                onChanged: (_) => _toggleActive(contact),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 0.8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => _makeCall(contact['phone'] ?? ''),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.call, size: 14, color: Color(0xFFEF4444)),
                      const SizedBox(width: 6),
                      Text(
                        contact['phone'] ?? '',
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Iconsax.edit, size: 18, color: Color(0xFF3B82F6)),
                    tooltip: 'دەستکاریکردن',
                    onPressed: () => _openForm(contact),
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.trash, size: 18, color: Color(0xFFEF4444)),
                    tooltip: 'سڕینەوە',
                    onPressed: () => _delete(contact),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 30).ms);
  }
}
