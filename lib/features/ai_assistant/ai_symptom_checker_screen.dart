import 'dart:io';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../prescriptions/pill_reminder_screen.dart';
import '../pharmacy/screens/pharmacies_screen.dart';

class AiSymptomCheckerScreen extends StatefulWidget {
  const AiSymptomCheckerScreen({super.key});

  @override
  State<AiSymptomCheckerScreen> createState() => _AiSymptomCheckerScreenState();
}

class _AiSymptomCheckerScreenState extends State<AiSymptomCheckerScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

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

  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text':
          'سڵاو! من یاریدەدەری زیرەکی دەستکردی Dr-Room م 🤖.\nدەتوانیت نیشانەکانی نەخۆشییەکەت بنووسیت یان وێنەی ڕەچەتە و پشکنینەکانت بنێریت تاوەکو بە شێوەیەکی ورد شیکاریت بۆ بکەم.',
      'time': '١٠:٠٠ بەیانی',
      'image': null,
      'isPrescription': false,
    },
  ];

  final List<String> _suggestions = [
    'سەرئێشەی بەهێزم هەیە',
    'تای بەرز و ئازاری جەستە',
    'ئازاری گەدە و هەرسنەکردن',
    'کۆکە و هەوکردنی قوڕگ',
  ];

  bool _isTyping = false;

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'isUser': true,
        'text': text,
        'time': 'ئێستا',
        'image': null,
        'isPrescription': false,
      });
      _isTyping = true;
    });

    _controller.clear();
    _scrollToBottom();

    // Simulate AI clinical response
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add({
            'isUser': false,
            'text':
                'بەپێی ئەو نیشانانەی باستان کرد، ئەگەری زۆرە پەتا یان سەرمابوونی ئاسایی بێت. پێشنیاز دەکەین پشوو بدەیت، شلەمەنی زۆر بخۆیتەوە، و ئەگەر تای بەرز زیاتر لە ٣ ڕۆژ بەردەوام بوو نۆبە لای پزیشکی پسپۆڕ وەربگریت. ئایا دەتەوێت پزیشکی گونجاو لە ئەپەکەدا بدۆزمەوە؟',
            'time': 'ئێستا',
            'image': null,
            'isPrescription': false,
          });
        });
        _scrollToBottom();
      }
    });
  }

  Future<void> _pickAndScanImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );

      if (picked != null) {
        final File file = File(picked.path);

        setState(() {
          _messages.add({
            'isUser': true,
            'text': 'وێنەی ڕەچەتە / بەڵگەنامەی پزیشکی 📄',
            'time': 'ئێستا',
            'image': file,
            'isPrescription': false,
          });
          _isTyping = true;
        });

        _scrollToBottom();

        // Simulate multimodal AI prescription & lab analysis
        await Future.delayed(const Duration(milliseconds: 2600));

        if (mounted) {
          setState(() {
            _isTyping = false;
            _messages.add({
              'isUser': false,
              'text':
                  'شیکاریی ڕەچەتەکە تەواو بوو! ئەم دەرمانانە دەستنیشان کران:\n\n'
                  '١. Amoxicillin (ئامۆکسیسیلین 500mg) - کەپسول\n'
                  '• کاتی خواردن: ڕۆژی ٣ جار (دوای نان بۆ ٧ ڕۆژ)\n'
                  '• مەبەست: چارەسەری هەوکردن و بەکتریا\n\n'
                  '٢. Panadol Extra (پانادۆڵ 500mg) - حەب\n'
                  '• کاتی خواردن: لە کاتی ئازار و تا، ڕۆژی ٢ جار\n\n'
                  '٣. Omeprazole (ئۆمیپرازۆڵ 20mg) - کەپسول\n'
                  '• کاتی خواردن: ڕۆژی ١ جار پێش نانی بەیانی',
              'time': 'ئێستا',
              'image': null,
              'isPrescription': true,
            });
          });
          _scrollToBottom();
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isTyping = false);
    }
  }

  void _showImageSourceModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'شیکاریی وێنەی پزیشکی بە زیرەکی دەستکرد',
                style: _kStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'وێنەی ڕەچەتەی دەستنووس، پاکەتی دەرمان، یان ئەنجامی پشکنین بگرە:',
                style: _kStyle(fontSize: 12.5, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _pickAndScanImage(ImageSource.camera);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(
                              0xFF8B5CF6,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.camera_alt_rounded,
                              color: Color(0xFF8B5CF6),
                              size: 28,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'کامێرا 📸',
                              style: _kStyle(
                                color: const Color(0xFF8B5CF6),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _pickAndScanImage(ImageSource.gallery);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: const Color(
                              0xFF3B82F6,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Iconsax.gallery,
                              color: Color(0xFF3B82F6),
                              size: 28,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'گەلەری 🖼️',
                              style: _kStyle(
                                color: const Color(0xFF3B82F6),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF8B5CF6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Iconsax.message_programming,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'ڕاوێژکاری تەندروستی AI',
                  style: _kStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
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
                  'بەردەستە • دەق و وێنە (Multimodal)',
                  style: _kStyle(
                    color: const Color(0xFF10B981),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Top Quick Banner for Image Scanning
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
            child: GestureDetector(
              onTap: _showImageSourceModal,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.document_scanner_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'سکانکردنی وێنەی ڕەچەتە بە کامێرا 📸',
                            style: _kStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'بۆ خوێندنەوەی دەستوخەتی دکتۆر و دەرهێنانی دەرمانەکان',
                            style: _kStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'سکان بکە',
                        style: _kStyle(
                          color: const Color(0xFF6D28D9),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn().slideY(begin: -0.05, end: 0),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator(isDark);
                }

                final msg = _messages[index];
                return _buildMessageBubble(msg, isDark);
              },
            ),
          ),

          if (_messages.length == 1) _buildSuggestions(isDark),

          _buildInputArea(isDark),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isDark) {
    final bool isUser = msg['isUser'] as bool;
    final String text = msg['text'] as String;
    final String time = msg['time'] as String;
    final File? image = msg['image'] as File?;
    final bool isPrescription = msg['isPrescription'] == true;

    return Align(
      alignment: isUser
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.84,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF8B5CF6)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(22),
            topRight: const Radius.circular(22),
            bottomLeft: Radius.circular(isUser ? 22 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 22),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isUser ? 0.1 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Embedded Image if attached
            if (image != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  image,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 10),
            ],

            Text(
              text,
              style: _kStyle(
                color: isUser
                    ? Colors.white
                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
                fontSize: 13.5,
                height: 1.5,
              ),
            ),

            // Interactive Action Buttons if Prescription was analyzed
            if (isPrescription) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PillReminderScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Iconsax.clock,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'دانانی زەنگ',
                              style: _kStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PharmaciesScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Iconsax.shopping_cart,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'داواکردن',
                              style: _kStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 4),
            Align(
              alignment: AlignmentDirectional.bottomEnd,
              child: Text(
                time,
                style: _kStyle(
                  color: isUser ? Colors.white70 : const Color(0xFF94A3B8),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF8B5CF6),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'زیرەکی دەستکرد لە وەڵامدانەوەدایە...',
              style: _kStyle(color: const Color(0xFF94A3B8), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions(bool isDark) {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ActionChip(
              onPressed: () => _sendMessage(_suggestions[index]),
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              label: Text(
                _suggestions[index],
                style: _kStyle(
                  color: const Color(0xFF8B5CF6),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          // Camera Attachment Button
          GestureDetector(
            onTap: _showImageSourceModal,
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.camera,
                color: Color(0xFF8B5CF6),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Text Field
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                style: _kStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 13.5,
                ),
                decoration: InputDecoration(
                  hintText: 'نیشانەکان بنووسە یان وێنە بنێرە...',
                  hintStyle: _kStyle(
                    color: const Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send Button
          GestureDetector(
            onTap: () => _sendMessage(_controller.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}