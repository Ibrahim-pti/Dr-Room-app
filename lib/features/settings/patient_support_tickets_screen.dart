import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/api_client.dart';

class PatientSupportTicketsScreen extends StatefulWidget {
  const PatientSupportTicketsScreen({super.key});

  @override
  State<PatientSupportTicketsScreen> createState() => _PatientSupportTicketsScreenState();
}

class _PatientSupportTicketsScreenState extends State<PatientSupportTicketsScreen> {
  List<dynamic> _tickets = [];
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
      final res = await ApiClient.get('/support-tickets');
      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        setState(() {
          _tickets = body['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'کێشە لە بارکردنی تیکێتەکان ڕوویدا';
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
      'open' => 'ticket_status_open'.tr(),
      'in_progress' => 'ticket_status_in_progress'.tr(),
      'resolved' => 'ticket_status_resolved'.tr(),
      'closed' => 'ticket_status_closed'.tr(),
      _ => status,
    };
  }

  Future<void> _openCreateTicketSheet() async {
    final subjectCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String category = 'general';
    bool isSubmitting = false;

    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('create_ticket'.tr(), style: const TextStyle(fontFamily: 'Rabar', fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: InputDecoration(
                        labelText: 'ticket_category'.tr(),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'general', child: Text('پرسیار و پێشنیاری گشتی')),
                        DropdownMenuItem(value: 'order', child: Text('کێشە لە داواکاری')),
                        DropdownMenuItem(value: 'nurse', child: Text('تێبینی لەسەر پەرستار')),
                        DropdownMenuItem(value: 'lab', child: Text('کێشەی ئەنجامی تاقیگە')),
                        DropdownMenuItem(value: 'payment', child: Text('کێشەی پارەدان')),
                        DropdownMenuItem(value: 'complaint', child: Text('سکاڵای فەرمی')),
                      ],
                      onChanged: (v) {
                        if (v != null) setSheetState(() => category = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: subjectCtrl,
                      decoration: InputDecoration(
                        labelText: 'ticket_subject'.tr(),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'ticket_description'.tr(),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              final sub = subjectCtrl.text.trim();
                              final desc = descCtrl.text.trim();
                              if (sub.isEmpty || desc.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تکایە بابەت و کێشەکە بنووسە', style: TextStyle(fontFamily: 'Rabar'))),
                                );
                                return;
                              }

                              setSheetState(() => isSubmitting = true);
                              try {
                                final res = await ApiClient.post('/support-tickets', body: {
                                  'category': category,
                                  'subject': sub,
                                  'description': desc,
                                });

                                if (res.statusCode == 200 || res.statusCode == 201) {
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  _load();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('تیکێتەکەت بە سەرکەوتوویی نێردرا', style: TextStyle(fontFamily: 'Rabar'))),
                                    );
                                  }
                                } else if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('ناردنی تیکێت سەرکەوتوو نەبوو', style: TextStyle(fontFamily: 'Rabar'))),
                                  );
                                }
                              } catch (_) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('کێشەی پەیوەندی ڕوویدا', style: TextStyle(fontFamily: 'Rabar'))),
                                  );
                                }
                              } finally {
                                if (ctx.mounted) setSheetState(() => isSubmitting = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('create_ticket'.tr(), style: const TextStyle(fontFamily: 'Rabar', fontSize: 14)),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } finally {
      subjectCtrl.dispose();
      descCtrl.dispose();
    }
  }

  void _openTicketChat(dynamic ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PatientTicketChatSheet(ticketId: ticket['id'], onUpdated: _load),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('my_tickets'.tr(), style: const TextStyle(fontFamily: 'Rabar', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateTicketSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('create_ticket'.tr(), style: const TextStyle(fontFamily: 'Rabar', color: Colors.white)),
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
                        Text(_error!, style: const TextStyle(fontFamily: 'Rabar', color: Colors.grey), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('دووبارە هەوڵبدەرەوە', style: TextStyle(fontFamily: 'Rabar')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _tickets.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Iconsax.message_tick, size: 64, color: Color(0xFF94A3B8)),
                          const SizedBox(height: 12),
                          const Text('هیچ تیکێتێکت تۆمارنەکردووە', style: TextStyle(fontFamily: 'Rabar', fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          const Text('ئەگەر کێشەیەک یان پرسیارێکت هەیە دەتوانیت تیکێت بکەیتەوە', style: TextStyle(fontFamily: 'Rabar', fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _tickets.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final t = _tickets[i];
                          final status = t['status'] ?? 'open';
                          final unread = (t['unread_messages_count'] ?? 0) > 0;

                          return InkWell(
                            onTap: () => _openTicketChat(t),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: unread ? AppColors.primary : const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
                                ],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        t['ticket_number'] ?? '#TKT',
                                        style: TextStyle(
                                          fontFamily: 'Rabar',
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (unread)
                                            Container(
                                              margin: const EdgeInsets.only(left: 6),
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: const Color(0xFFEF4444), width: 1),
                                              ),
                                              child: const Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Iconsax.notification_status, size: 12, color: Color(0xFFEF4444)),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    'وەڵامی نوێ',
                                                    style: TextStyle(fontFamily: 'Rabar', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                                                  ),
                                                ],
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
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    t['subject'] ?? '',
                                    style: const TextStyle(fontFamily: 'Rabar', fontSize: 15, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    t['description'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontFamily: 'Rabar', fontSize: 13, color: Color(0xFF64748B)),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Iconsax.clock, size: 14, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Builder(
                                        builder: (_) {
                                          final dt = DateTime.tryParse('${t['created_at'] ?? ''}');
                                          return Text(
                                            dt != null ? DateFormat('yyyy/MM/dd HH:mm').format(dt) : '',
                                            style: const TextStyle(fontFamily: 'Rabar', fontSize: 11, color: Colors.grey),
                                          );
                                        },
                                      ),
                                      const Spacer(),
                                      const Text('بینینی گفتوگۆ', style: TextStyle(fontFamily: 'Rabar', fontSize: 12, color: Colors.blue)),
                                      const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.blue),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ).animate().fadeIn(duration: 150.ms);
                        },
                      ),
                    ),
    );
  }
}

class _PatientTicketChatSheet extends StatefulWidget {
  final int ticketId;
  final VoidCallback onUpdated;

  const _PatientTicketChatSheet({required this.ticketId, required this.onUpdated});

  @override
  State<_PatientTicketChatSheet> createState() => _PatientTicketChatSheetState();
}

class _PatientTicketChatSheetState extends State<_PatientTicketChatSheet> {
  dynamic _ticket;
  bool _isLoading = true;
  final _msgCtrl = TextEditingController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final res = await ApiClient.get('/support-tickets/${widget.ticketId}');
      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() {
          _ticket = jsonDecode(res.body)['data'];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      final res = await ApiClient.post('/support-tickets/${widget.ticketId}/reply', body: {
        'message': text,
      });
      if (!mounted) return;
      if (res.statusCode == 200) {
        _msgCtrl.clear();
        _fetch();
        widget.onUpdated();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ناردنی پەیام سەرکەوتوو نەبوو', style: TextStyle(fontFamily: 'Rabar'))),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('کێشەی پەیوەندی ڕوویدا', style: TextStyle(fontFamily: 'Rabar'))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = (_ticket?['messages'] as List?) ?? [];

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _ticket?['subject'] ?? 'تیکێت',
                        style: const TextStyle(fontFamily: 'Rabar', fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                Text(
                  'ژمارەی تیکێت: ${_ticket?['ticket_number'] ?? ''}',
                  style: const TextStyle(fontFamily: 'Rabar', fontSize: 12, color: Colors.grey),
                ),
                const Divider(height: 20),

                Expanded(
                  child: ListView.separated(
                    itemCount: messages.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final m = messages[i];
                      final isAdmin = m['is_admin_reply'] == true || m['is_admin_reply'] == 1;

                      return Align(
                        alignment: isAdmin ? Alignment.centerLeft : Alignment.centerRight,
                        child: Container(
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isAdmin ? const Color(0xFFF1F5F9) : AppColors.primary,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isAdmin ? 'تیمی پشتیوانی دکتۆر ڕۆم' : 'تۆ',
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isAdmin ? const Color(0xFF64748B) : Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                m['message'] ?? '',
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 13,
                                  color: isAdmin ? const Color(0xFF0F172A) : Colors.white,
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
                        controller: _msgCtrl,
                        decoration: InputDecoration(
                          hintText: 'reply_hint'.tr(),
                          hintStyle: const TextStyle(fontFamily: 'Rabar', fontSize: 13),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _isSending ? null : _send,
                      icon: _isSending
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send),
                      style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
