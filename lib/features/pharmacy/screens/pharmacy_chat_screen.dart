import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/pharmacy_model.dart';


class PharmacyChatScreen extends StatefulWidget {
  final Pharmacy pharmacy;

  const PharmacyChatScreen({super.key, required this.pharmacy});

  @override
  State<PharmacyChatScreen> createState() => _PharmacyChatScreenState();
}

class _PharmacyChatScreenState extends State<PharmacyChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  TextStyle _kStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = const Color(0xFF0F172A),
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'Rabar',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  late final List<Map<String, dynamic>> _messages = [
    {
      'text': 'سڵاو لە ئێوەی بەڕێز! چۆن دەتوانین هاوکاریتان بکەین دەربارەی دەرمان یان شێوازی بەکارهێنان؟ 👨‍⚕️',
      'isMe': false,
      'time': '١٠:٠٠ بەیانی'
    },
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'text': _messageController.text.trim(),
        'isMe': true,
        'time': 'ئێستا',
      });
      _messageController.clear();
    });

    _scrollToBottom();

    // Mock pharmacy response
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'text': 'سوپاس بۆ پەیامەکەت. دەرمانسازەکەمان لە ماوەیەکی کەمدا بە وردی وەڵامت دەداتەوە.',
            'isMe': false,
            'time': 'ئێستا',
          });
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _makeCall() async {
    final phone = widget.pharmacy.phone ?? '07501234567';
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                size: 16,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                image: widget.pharmacy.profileImage != null
                    ? DecorationImage(
                        image: NetworkImage(widget.pharmacy.profileImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: widget.pharmacy.profileImage == null
                  ? const Icon(Icons.local_pharmacy, color: Color(0xFF3B82F6), size: 20)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.pharmacy.name,
                    style: _kStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'دەرمانساز بەردەستە (Online)',
                        style: _kStyle(
                          color: const Color(0xFF10B981),
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: GestureDetector(
              onTap: _makeCall,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: const Icon(Icons.phone_in_talk_rounded, color: Color(0xFF10B981), size: 18),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message['isMe'] as bool;

                return Align(
                  alignment: isMe ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMe
                          ? const Color(0xFF3B82F6)
                          : (isDark ? const Color(0xFF1E293B) : Colors.white),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMe ? 18 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isMe ? 0.1 : 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['text'],
                          style: _kStyle(
                            color: isMe ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)),
                            fontSize: 13.5,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: AlignmentDirectional.bottomEnd,
                          child: Text(
                            message['time'],
                            style: _kStyle(
                              color: isMe ? Colors.white70 : const Color(0xFF94A3B8),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.04, end: 0);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: _kStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontSize: 13.5,
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'write_message_hint'.tr(),
                        hintStyle: _kStyle(color: const Color(0xFF94A3B8), fontSize: 13),

                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
