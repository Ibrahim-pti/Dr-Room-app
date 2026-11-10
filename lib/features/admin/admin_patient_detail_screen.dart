import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart' as intl;
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/api_client.dart';
import 'admin_app_bar.dart';
import 'admin_ui.dart';

class AdminPatientDetailScreen extends StatefulWidget {
  final int patientId;
  final String? initialName;

  const AdminPatientDetailScreen({
    super.key,
    required this.patientId,
    this.initialName,
  });

  @override
  State<AdminPatientDetailScreen> createState() => _AdminPatientDetailScreenState();
}

class _AdminPatientDetailScreenState extends State<AdminPatientDetailScreen> {
  Map<String, dynamic>? _patient;
  bool _isLoading = true;
  String? _error;
  bool _isActionLoading = false;

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
      final res = await ApiClient.get('/admin/patients/${widget.patientId}');
      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          _patient = Map<String, dynamic>.from(body['data'] ?? {});
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

  Future<void> _makePhoneCall(String? phone) async {
    if (phone == null || phone.isEmpty) {
      AdminUi.toast(context, 'ژمارەی مۆبایل بەردەست نییە', isError: true);
      return;
    }
    final clean = phone.replaceAll(' ', '').replaceAll('-', '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) AdminUi.toast(context, 'نەتوانرا پەیوەندی پێوەبکرێت', isError: true);
    }
  }

  Future<void> _openWhatsApp(String? phone) async {
    if (phone == null || phone.isEmpty) {
      AdminUi.toast(context, 'ژمارەی مۆبایل بەردەست نییە', isError: true);
      return;
    }
    var clean = phone.replaceAll(' ', '').replaceAll('-', '').replaceAll('+', '');
    if (clean.startsWith('07')) {
      clean = '964${clean.substring(1)}';
    }
    final uri = Uri.parse('https://wa.me/$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) AdminUi.toast(context, 'نەتوانرا واتسئاپ بکرێتەوە', isError: true);
    }
  }

  Future<void> _toggleBlockStatus() async {
    if (_isActionLoading) return;
    setState(() => _isActionLoading = true);

    try {
      final res = await ApiClient.patch('/admin/patients/${widget.patientId}/toggle-block');
      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final isBlocked = body['is_blocked'] ?? false;
        setState(() {
          if (_patient != null) {
            _patient!['is_blocked'] = isBlocked;
            _patient!['status'] = isBlocked ? 'blocked' : 'approved';
          }
        });
        AdminUi.toast(context, body['message'] ?? 'دۆخی نەخۆشەکە گۆڕدرا');
      } else {
        AdminUi.toast(context, AdminUi.readError(res), isError: true);
      }
    } catch (e) {
      if (mounted) AdminUi.toast(context, '$e', isError: true);
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _showSendNotificationDialog() async {
    final titleCtrl = TextEditingController(text: 'ئاگاداری لە ئەپی دکتۆر ڕۆم');
    final messageCtrl = TextEditingController();
    bool isSending = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dCtx, setDialogState) {
            final isDark = Theme.of(dCtx).brightness == Brightness.dark;

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Iconsax.notification, color: Color(0xFF2563EB), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text('ناردنی ئاگاداری ڕاستەوخۆ', style: TextStyle(fontFamily: 'Rabar', fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('نامەکە ڕاستەوخۆ لەسەر مۆبایلی ${_patient?['name'] ?? 'نەخۆش'} پیشان دەدرێت.', style: const TextStyle(fontFamily: 'Rabar', fontSize: 11.5, color: Color(0xFF64748B))),
                    const SizedBox(height: 14),
                    const Text('سەردێڕی ئاگاداری', style: TextStyle(fontFamily: 'Rabar', fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      style: const TextStyle(fontFamily: 'Rabar', fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    const Text('دەقی پەیام', style: TextStyle(fontFamily: 'Rabar', fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: messageCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'دەقی پەیامەکەت لێرە بنووسە...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      style: const TextStyle(fontFamily: 'Rabar', fontSize: 13),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSending ? null : () => Navigator.pop(dCtx),
                  child: const Text('پاشگەزبوونەوە', style: TextStyle(fontFamily: 'Rabar')),
                ),
                ElevatedButton.icon(
                  onPressed: isSending
                      ? null
                      : () async {
                          final msg = messageCtrl.text.trim();
                          if (msg.isEmpty) {
                            AdminUi.toast(context, 'تکایە دەقی پەیام بنووسە', isError: true);
                            return;
                          }

                          setDialogState(() => isSending = true);
                          try {
                            final res = await ApiClient.post('/admin/patients/${widget.patientId}/notify', body: {
                              'title': titleCtrl.text.trim(),
                              'message': msg,
                            });

                            if (dCtx.mounted) Navigator.pop(dCtx);

                            if (res.statusCode == 200) {
                              if (mounted) AdminUi.toast(context, 'ئاگاداری بە سەرکەوتوویی بۆ نەخۆشەکە نێردرا');
                            } else {
                              if (mounted) AdminUi.toast(context, AdminUi.readError(res), isError: true);
                            }
                          } catch (e) {
                            if (dCtx.mounted) Navigator.pop(dCtx);
                            if (mounted) AdminUi.toast(context, '$e', isError: true);
                          }
                        },
                  icon: isSending
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Iconsax.send_1, size: 16),
                  label: const Text('ناردن', style: TextStyle(fontFamily: 'Rabar')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    titleCtrl.dispose();
    messageCtrl.dispose();
  }

  String _formatIqd(dynamic val) {
    final d = double.tryParse(val?.toString() ?? '0') ?? 0;
    return '${intl.NumberFormat('#,###').format(d)} د.ع';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AdminAppBar(
        title: _patient?['name'] ?? widget.initialName ?? 'پڕۆفایلی نەخۆش',
        subtitle: 'وردەکاری دۆسیە، ناونیشان و مێژووی داواکارییەکان',
        icon: Iconsax.user_square,
        iconColor: const Color(0xFF0D9488),
        iconBackgroundColor: const Color(0xFF0D9488).withValues(alpha: 0.1),
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Iconsax.info_circle, size: 48, color: Colors.amber),
                        const SizedBox(height: 12),
                        Text(_error!, style: AdminUi.subtitle, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(onPressed: _load, child: const Text('دووبارە هەوڵبدەرەوە')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Patient Header Card
                        _buildPatientHeaderCard(isDark),
                        const SizedBox(height: 16),

                        // 2. Action Buttons (Call, WhatsApp, Notify, Block)
                        _buildActionButtons(isDark),
                        const SizedBox(height: 20),

                        // 3. Address & Location Card (Essential for Home Care)
                        _buildAddressCard(isDark),
                        const SizedBox(height: 20),

                        // 4. Statistics Summary Grid
                        _buildStatsGrid(),
                        const SizedBox(height: 20),

                        // 5. EMR Medical Summary (if available)
                        if (_patient?['emr'] != null) ...[
                          _buildEmrCard(isDark),
                          const SizedBox(height: 20),
                        ],

                        // 6. Complete Order History Section
                        _buildOrderHistorySection(isDark),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
    );
  }

  /// Patient Header with Avatar, Name, Phone & Status Badge
  Widget _buildPatientHeaderCard(bool isDark) {
    final name = (_patient?['name'] ?? 'نەخۆش').toString();
    final trimmedName = name.trim();
    final initial = trimmedName.isNotEmpty ? trimmedName.characters.first : 'ن';
    final phone = (_patient?['phone'] ?? '').toString().trim();
    final email = (_patient?['email'] ?? '').toString().trim();
    final isBlocked = _patient?['is_blocked'] == true;
    final loyalty = _patient?['loyalty_points'] ?? 0;
    final createdAt = (_patient?['created_at'] ?? '').toString();
    final avatarProvider = ApiClient.getImageProvider(_patient?['avatar_url']?.toString());

    return Container(
      decoration: AdminUi.cardDecoration,
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar / Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isBlocked
                    ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                    : [const Color(0xFF0D9488), const Color(0xFF14B8A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              image: avatarProvider != null
                  ? DecorationImage(image: avatarProvider, fit: BoxFit.cover)
                  : null,
            ),
            child: avatarProvider == null
                ? Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isBlocked ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isBlocked ? 'بلۆککراوە' : 'چالاکە',
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isBlocked ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (phone.isNotEmpty)
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      children: [
                        const Icon(Iconsax.call, size: 13, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '\u200E$phone',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontFamily: 'Rabar', fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const Row(
                    children: [
                      Icon(Iconsax.call, size: 13, color: Color(0xFF94A3B8)),
                      SizedBox(width: 4),
                      Text('بێ ژمارە', style: TextStyle(fontFamily: 'Rabar', fontSize: 12, color: Color(0xFF94A3B8))),
                    ],
                  ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      children: [
                        const Icon(Iconsax.sms, size: 13, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Iconsax.award, size: 12, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 4),
                          Text('$loyalty خاڵ', style: const TextStyle(fontFamily: 'Rabar', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                        ],
                      ),
                    ),
                    if (createdAt.isNotEmpty)
                      Text(
                        'تۆمارکراوە: $createdAt',
                        style: const TextStyle(fontFamily: 'Rabar', fontSize: 10.5, color: Color(0xFF94A3B8)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.05, end: 0);
  }

  /// 4 Direct Actions: Call, WhatsApp, Notify, Block/Unblock
  Widget _buildActionButtons(bool isDark) {
    final phone = _patient?['phone'];
    final isBlocked = _patient?['is_blocked'] == true;

    return Row(
      children: [
        // Call Phone
        Expanded(
          child: _buildActionPill(
            icon: Iconsax.call,
            label: 'تەلەفۆن',
            color: const Color(0xFF2563EB),
            onTap: () => _makePhoneCall(phone),
          ),
        ),
        const SizedBox(width: 8),

        // WhatsApp
        Expanded(
          child: _buildActionPill(
            icon: Iconsax.message,
            label: 'واتسئاپ',
            color: const Color(0xFF10B981),
            onTap: () => _openWhatsApp(phone),
          ),
        ),
        const SizedBox(width: 8),

        // Push Notification
        Expanded(
          child: _buildActionPill(
            icon: Iconsax.notification,
            label: 'ئاگاداری',
            color: const Color(0xFF8B5CF6),
            onTap: _showSendNotificationDialog,
          ),
        ),
        const SizedBox(width: 8),

        // Block / Suspend Toggle
        Expanded(
          child: _buildActionPill(
            icon: isBlocked ? Iconsax.user_tick : Iconsax.user_remove,
            label: isBlocked ? 'چالاککردن' : 'بلۆککردن',
            color: isBlocked ? const Color(0xFF059669) : const Color(0xFFEF4444),
            onTap: _toggleBlockStatus,
          ),
        ),
      ],
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _isActionLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Address & Location Card
  Widget _buildAddressCard(bool isDark) {
    final rawAddress = (_patient?['address'] ?? '').toString().trim();
    final address = rawAddress.isNotEmpty ? rawAddress : 'ناونیشان لە سیستەمدا تۆمارنەکراوە';
    final location = _patient?['location'] as Map?;
    final lat = location?['lat'];
    final lng = location?['lng'];

    return Container(
      decoration: AdminUi.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Iconsax.location, size: 16, color: Color(0xFF0D9488)),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'ناونیشانی نەخۆش و لۆکەیشن',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontFamily: 'Rabar', fontSize: 13.5, fontWeight: FontWeight.bold),
                ),
              ),
              if (lat != null && lng != null) ...[
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Iconsax.map, size: 14),
                  label: const Text('بینین لە نەخشە', style: TextStyle(fontFamily: 'Rabar', fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0D9488),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            address,
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 12.5,
              height: 1.4,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }

  /// Stats Grid (Orders, Completed, Spent)
  Widget _buildStatsGrid() {
    final stats = (_patient?['stats'] as Map?) ?? {};
    final totalOrders = '${stats['total_orders'] ?? 0}';
    final completed = '${stats['completed_orders'] ?? 0}';
    final totalSpent = _formatIqd(stats['total_spent']);

    return Row(
      children: [
        Expanded(
          child: _buildStatBox('کۆی داواکاری', totalOrders, Iconsax.box, const Color(0xFF2563EB)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatBox('تەواوکراو', completed, Iconsax.tick_circle, const Color(0xFF10B981)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatBox('کۆی خەرجی', totalSpent, Iconsax.wallet_3, const Color(0xFF8B5CF6)),
        ),
      ],
    );
  }

  Widget _buildStatBox(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: AdminUi.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(label, style: const TextStyle(fontFamily: 'Rabar', fontSize: 10.5, color: Color(0xFF64748B)), maxLines: 1),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// EMR Medical Card
  Widget _buildEmrCard(bool isDark) {
    final emr = _patient?['emr'] as Map? ?? {};
    final rawBlood = emr['blood_type']?.toString().trim() ?? '';
    final blood = rawBlood.isNotEmpty ? rawBlood : 'دیاری نەکراوە';

    final chronicList = (emr['chronic_diseases'] as List?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];
    final chronic = chronicList.isNotEmpty ? chronicList.join('، ') : 'نییە';

    final allergiesList = (emr['allergies'] as List?)
            ?.map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList() ??
        [];
    final allergies = allergiesList.isNotEmpty ? allergiesList.join('، ') : '';

    final emergencyNotes = (emr['emergency_notes'] ?? '').toString().trim();

    return Container(
      decoration: AdminUi.cardDecoration,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Iconsax.health, size: 16, color: Color(0xFFEF4444)),
              ),
              const SizedBox(width: 8),
              const Text('دۆسیەی پزیشکی کورت (EMR)', style: TextStyle(fontFamily: 'Rabar', fontSize: 13.5, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildEmrTag('گرووپی خوێن', blood, const Color(0xFFEF4444))),
              const SizedBox(width: 8),
              Expanded(child: _buildEmrTag('نەخۆشی درێژخایەن', chronic, const Color(0xFFF59E0B))),
            ],
          ),
          if (allergies.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: _buildEmrTag('حەساسیەت / هەستیاری', allergies, const Color(0xFF8B5CF6)),
            ),
          ],
          if (emergencyNotes.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: _buildEmrTag('تێبینی فریاکەوتن', emergencyNotes, const Color(0xFF0D9488)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmrTag(String title, String val, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontFamily: 'Rabar', fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(val, style: const TextStyle(fontFamily: 'Rabar', fontSize: 11.5, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  /// Order History Section
  Widget _buildOrderHistorySection(bool isDark) {
    final orders = (_patient?['orders'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'مێژووی داواکارییەکان (Order History)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: 'Rabar', fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            Text('${orders.length} داواکاری', style: const TextStyle(fontFamily: 'Rabar', fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
        const SizedBox(height: 10),

        if (orders.isEmpty)
          Container(
            decoration: AdminUi.cardDecoration,
            padding: const EdgeInsets.all(24),
            child: const Center(
              child: Column(
                children: [
                  Icon(Iconsax.box, size: 36, color: Color(0xFFCBD5E1)),
                  SizedBox(height: 8),
                  Text('ئەم نەخۆشە تا ئێستا هیچ داواکارییەکی نەکردووە', style: TextStyle(fontFamily: 'Rabar', fontSize: 12, color: Color(0xFF94A3B8))),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final ord = orders[i] as Map;
              final status = ord['status'] ?? 'pending';
              final isCompleted = status == 'completed';
              final isCancelled = status == 'cancelled';

              final statusColor = isCompleted
                  ? const Color(0xFF10B981)
                  : isCancelled
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFF59E0B);

              final statusLabel = isCompleted
                  ? 'سەرکەوتوو'
                  : isCancelled
                      ? 'هەڵوەشاوە'
                      : 'چاوەڕوان';

              return Container(
                decoration: AdminUi.cardDecoration,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isCompleted ? Iconsax.tick_circle : (isCancelled ? Iconsax.close_circle : Iconsax.clock),
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  ord['order_number'] ?? '#ORD',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontFamily: 'Rabar', fontSize: 12.5, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(statusLabel, style: TextStyle(fontFamily: 'Rabar', fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            ord['service_title'] ?? 'خزمەتگوزاری',
                            style: const TextStyle(fontFamily: 'Rabar', fontSize: 11.5, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(ord['date'] ?? '', style: const TextStyle(fontFamily: 'Rabar', fontSize: 10, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatIqd(ord['total_price']),
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ord['payment_method'] ?? 'کاش',
                          style: const TextStyle(fontFamily: 'Rabar', fontSize: 10, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
