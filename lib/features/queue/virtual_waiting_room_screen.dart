import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/utils/api_client.dart';

class VirtualWaitingRoomScreen extends StatefulWidget {
  final String doctorName;
  final String specialty;
  final String image;

  const VirtualWaitingRoomScreen({
    super.key,
    required this.doctorName,
    required this.specialty,
    required this.image,
  });

  @override
  State<VirtualWaitingRoomScreen> createState() => _VirtualWaitingRoomScreenState();
}

class _VirtualWaitingRoomScreenState extends State<VirtualWaitingRoomScreen>
    with TickerProviderStateMixin {
  int _queuePosition = 3;
  int _totalInQueue = 6;
  int _estimatedMinutes = 20;
  late Timer _simulationTimer;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  bool _isAlmostReady = false;

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

  final List<Map<String, dynamic>> _queuePeople = [
    {'name': 'نەخۆشی ژمارە ١', 'status': 'لای دکتۆرە', 'avatar': '👤', 'isCurrent': true},
    {'name': 'نەخۆشی ژمارە ٢', 'status': 'چاوەڕوانە', 'avatar': '👤', 'isCurrent': false},
    {'name': 'تۆ (نەخۆش)', 'status': 'نۆرەی تۆیە', 'avatar': '🧑', 'isYou': true},
    {'name': 'نەخۆشی ژمارە ٤', 'status': 'چاوەڕوانە', 'avatar': '👤', 'isCurrent': false},
    {'name': 'نەخۆشی ژمارە ٥', 'status': 'چاوەڕوانە', 'avatar': '👤', 'isCurrent': false},
  ];

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();

    // Simulate queue movement every 10 seconds
    _simulationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_queuePosition > 1) {
        setState(() {
          _queuePosition--;
          _estimatedMinutes = max(0, _estimatedMinutes - 7);
          if (_queuePeople.isNotEmpty) {
            _queuePeople.removeAt(0);
            _totalInQueue--;
          }
          if (_queuePosition <= 2) {
            _isAlmostReady = true;
          }
        });
        _progressController.forward(from: 0);
      } else if (_queuePosition == 1) {
        setState(() {
          _queuePosition = 0;
          _estimatedMinutes = 0;
        });
        timer.cancel();
        _showReadyDialog();
      }
    });
  }

  @override
  void dispose() {
    _simulationTimer.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _showReadyDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF10B981),
                    size: 60,
                  ),
                ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                const SizedBox(height: 20),
                Text(
                  'نۆرەی تۆ گەیشت!',
                  style: _kStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'پزیشک ئێستا ئامادەیە بۆ بینینت.\nتکایە بچۆ ژووری ژمارە ٣.',
                  textAlign: TextAlign.center,
                  style: _kStyle(
                    color: const Color(0xFF64748B),
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text('چوونە ژوورەوە', style: _kStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
        centerTitle: true,
        title: Text(
          'ژووری چاوەڕوانیی ڕاستەوخۆ',
          style: _kStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
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
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                      image: widget.image.isNotEmpty
                          ? DecorationImage(
                              image: widget.image.startsWith('http')
                                  ? NetworkImage(widget.image)
                                  : NetworkImage('${ApiClient.storageUrl}/${widget.image}'),
                              fit: BoxFit.cover,
                            )
                          : const DecorationImage(
                              image: AssetImage('assets/images/doctor2.png'),
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.doctorName,
                          style: _kStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.specialty,
                          style: _kStyle(color: const Color(0xFF3B82F6), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text('چالاکە', style: _kStyle(color: const Color(0xFF10B981), fontSize: 11.5, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.05, end: 0),

            const SizedBox(height: 20),

            // Queue Status Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('نۆرەی تۆ لە نۆرەگریدا', style: _kStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                            _isAlmostReady && _queuePosition > 0
                                ? 'نزیک بوویەوە! نۆرەی $_queuePosition'
                                : (_queuePosition > 0 ? 'نەفەری $_queuePosition لە $_totalInQueue' : 'نۆرەی تۆیە ئێستا!'),
                            style: _kStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$_queuePosition',
                          style: _kStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Iconsax.clock, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'کاتی خەمڵێنراوی ماوە: $_estimatedMinutes خولەک',
                          style: _kStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05, end: 0),

            const SizedBox(height: 24),

            Text(
              'ڕیزی نۆرەگریی نەخۆشەکان',
              style: _kStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),

            ...List.generate(_queuePeople.length, (index) {
              final person = _queuePeople[index];
              final isYou = person['isYou'] == true;
              final isCurrent = person['isCurrent'] == true;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isYou
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
                      : cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isYou ? const Color(0xFF3B82F6) : borderColor,
                    width: isYou ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: isYou
                            ? const Color(0xFF3B82F6)
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          person['avatar'] as String,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            person['name'] as String,
                            style: _kStyle(
                              fontSize: 14,
                              fontWeight: isYou ? FontWeight.bold : FontWeight.w600,
                              color: isYou
                                  ? const Color(0xFF2563EB)
                                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
                            ),
                          ),
                          Text(
                            person['status'] as String,
                            style: _kStyle(
                              fontSize: 11.5,
                              color: isCurrent
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF94A3B8),
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isYou)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'نۆرەی تۆیە',
                          style: _kStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ).animate().fadeIn(delay: (index * 60).ms);
            }),
          ],
        ),
      ),
    );
  }
}