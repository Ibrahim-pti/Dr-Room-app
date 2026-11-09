import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/api_client.dart';
import 'admin_app_bar.dart';
import 'admin_ui.dart';

class AdminTicketsScreen extends StatefulWidget {
  const AdminTicketsScreen({super.key});

  @override
  State<AdminTicketsScreen> createState() => _AdminTicketsScreenState();
}

class _AdminTicketsScreenState extends State<AdminTicketsScreen> {
  List<dynamic> _tickets = [];
  bool _isLoading = true;
  String? _error;
  String _selectedStatus = '';

  static const _statusFilters = [
    (value: '', label: 'هەمووی'),
    (value: 'open', label: 'کراوە'),
    (value: 'in_progress', label: 'بەدواداچوون'),
    (value: 'resolved', label: 'چارەسەرکراو'),
    (value: 'closed', label: 'داخراو'),
  ];

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
      final query = _selectedStatus.isNotEmpty ? '?status=$_selectedStatus' : '';
      final res = await ApiClient.get('/admin/tickets$query');
      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body['data'];
        setState(() {
          _tickets = data is Map ? (data['data'] ?? []) : (data ?? []);
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

  Color _statusColor(String status) {
    return switch (status) {
      'open' => const Color(0xFFEF4444),
      'in_progress' => const Color(0xFFF59E0B),
      'resolved' => const Color(0xFF10B981),
      'closed' => const Color(0xFF64748B),
      _ => const Color(0xFF64748B),
    };
  }

  String _statusLabel(String status) {
    return switch (status) {
      'open' => 'کراوە',
      'in_progress' => 'لە ژێر کاردایە',
      'resolved' => 'چارەسەرکراوە',
      'closed' => 'داخراوە',
      _ => status,
    };
  }

  Future<void> _openTicketDetail(dynamic ticket) async {
    final ticketId = ticket['id'];
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TicketDetailSheet(ticketId: ticketId, onUpdated: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AdminAppBar(
        title: 'سکاڵا و پشتیوانی',
        subtitle: '${_tickets.length} تیکێت',
        icon: Iconsax.message_question,
        iconColor: const Color(0xFFEC4899),
        iconBackgroundColor: const Color(0xFFEC4899).withValues(alpha: 0.1),
        showBackButton: true,
      ),
      body: Column(
        children: [
          // Filter pills
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _statusFilters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final f = _statusFilters[i];
                final isSelected = _selectedStatus == f.value;
                return ChoiceChip(
                  label: Text(f.label, style: const TextStyle(fontFamily: 'Rabar', fontSize: 13)),
                  selected: isSelected,
                  selectedColor: const Color(0xFFEC4899),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (val) {
                    setState(() => _selectedStatus = f.value);
                    _load();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!, style: AdminUi.subtitle))
                    : _tickets.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Iconsax.message_tick, size: 54, color: Color(0xFF94A3B8)),
                                const SizedBox(height: 12),
                                Text('هیچ تیکێتێک لەم بەشەدا نییە', style: AdminUi.title),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _tickets.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final t = _tickets[index];
                                final status = t['status'] ?? 'open';
                                final user = t['user'] ?? {};

                                return InkWell(
                                  onTap: () => _openTicketDetail(t),
                                  borderRadius: BorderRadius.circular(18),
                                  child: Container(
                                    decoration: AdminUi.cardDecoration,
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              t['ticket_number'] ?? '#TKT',
                                              style: const TextStyle(
                                                fontFamily: 'Rabar',
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFEC4899),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: _statusColor(status).withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                _statusLabel(status),
                                                style: TextStyle(
                                                  fontFamily: 'Rabar',
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: _statusColor(status),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          t['subject'] ?? 'بێ ناونیشان',
                                          style: AdminUi.title,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          t['description'] ?? '',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: AdminUi.subtitle,
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            const Icon(Iconsax.user, size: 14, color: Color(0xFF94A3B8)),
                                            const SizedBox(width: 4),
                                            Text(
                                              user['name'] ?? 'نەخۆش',
                                              style: AdminUi.subtitle.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
                                            ),
                                            const Spacer(),
                                            const Icon(Iconsax.clock, size: 14, color: Color(0xFF94A3B8)),
                                            const SizedBox(width: 4),
                                            Text(
                                              t['created_at'] != null
                                                  ? DateFormat('yyyy/MM/dd HH:mm').format(DateTime.parse(t['created_at']))
                                                  : '',
                                              style: AdminUi.subtitle.copyWith(fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ).animate().fadeIn(duration: 200.ms);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

class _TicketDetailSheet extends StatefulWidget {
  final int ticketId;
  final VoidCallback onUpdated;

  const _TicketDetailSheet({required this.ticketId, required this.onUpdated});

  @override
  State<_TicketDetailSheet> createState() => _TicketDetailSheetState();
}

class _TicketDetailSheetState extends State<_TicketDetailSheet> {
  dynamic _ticket;
  bool _isLoading = true;
  final _replyCtrl = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await ApiClient.get('/admin/tickets/${widget.ticketId}');
      if (res.statusCode == 200) {
        setState(() {
          _ticket = jsonDecode(res.body)['data'];
          _isLoading = false;
        });
      }
    } catch (_) {}
  }

  Future<void> _sendReply() async {
    final text = _replyCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      final res = await ApiClient.post('/admin/tickets/${widget.ticketId}/reply', body: {
        'message': text,
        'status': 'in_progress',
      });
      if (res.statusCode == 200) {
        _replyCtrl.clear();
        _fetch();
        widget.onUpdated();
      }
    } catch (_) {}
    setState(() => _isSending = false);
  }

  Future<void> _changeStatus(String status) async {
    try {
      final res = await ApiClient.patch('/admin/tickets/${widget.ticketId}/status', body: {
        'status': status,
      });
      if (res.statusCode == 200) {
        _fetch();
        widget.onUpdated();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _ticket?['subject'] ?? 'تیکێت',
                        style: AdminUi.title.copyWith(fontSize: 16),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: _changeStatus,
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'in_progress', child: Text('دانان لە ژێر بەدواداچوون')),
                        PopupMenuItem(value: 'resolved', child: Text('نیشانکردن وەک چارەسەرکراو')),
                        PopupMenuItem(value: 'closed', child: Text('داخستنی تیکێت')),
                      ],
                    ),
                  ],
                ),
                Text(
                  'نەخۆش: ${_ticket?['user']?['name']} (${_ticket?['user']?['phone'] ?? ''})',
                  style: AdminUi.subtitle,
                ),
                const Divider(height: 24),

                // Message thread
                Expanded(
                  child: ListView.separated(
                    itemCount: (_ticket?['messages'] as List?)?.length ?? 0,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final m = _ticket['messages'][i];
                      final isAdmin = m['is_admin_reply'] == true || m['is_admin_reply'] == 1;

                      return Align(
                        alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isAdmin ? const Color(0xFFEC4899) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAdmin ? 'وەڵامی ئەدمین / ستاف' : (_ticket?['user']?['name'] ?? 'نەخۆش'),
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isAdmin ? Colors.white70 : const Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                m['message'] ?? '',
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 13,
                                  color: isAdmin ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyCtrl,
                        decoration: InputDecoration(
                          hintText: 'وەڵامەکەت بنووسە...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _isSending ? null : _sendReply,
                      icon: _isSending
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send),
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFFEC4899)),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
