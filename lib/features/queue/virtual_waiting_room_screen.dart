import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';

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
  int _queuePosition = 4;
  int _totalInQueue = 7;
  int _estimatedMinutes = 32;
  late Timer _simulationTimer;
  late AnimationController _pulseController;
  late AnimationController _progressController;
  bool _isAlmostReady = false;

  final List<Map<String, dynamic>> _queuePeople = [
    {'name': 'Patient A', 'status': 'In Session', 'avatar': '👤'},
    {'name': 'Patient B', 'status': 'Waiting', 'avatar': '👤'},
    {'name': 'Patient C', 'status': 'Waiting', 'avatar': '👤'},
    {'name': 'Patient D', 'status': 'Waiting', 'avatar': '👤'},
    {'name': 'You', 'status': 'Waiting', 'avatar': '🧑'},
    {'name': 'Patient F', 'status': 'Waiting', 'avatar': '👤'},
    {'name': 'Patient G', 'status': 'Waiting', 'avatar': '👤'},
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

    // Simulate queue movement every 8 seconds
    _simulationTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (_queuePosition > 1) {
        setState(() {
          _queuePosition--;
          _estimatedMinutes = max(0, _estimatedMinutes - 8);
          // Remove the first person from queue (they finished)
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
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            borderRadius: BorderRadius.circular(32),
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
                  size: 64,
                ),
              ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
              const SizedBox(height: 24),
              Text(
                'It\'s Your Turn!',
                style: GoogleFonts.poppins(
                  color: AppColors.getTextTitle(context),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The doctor is ready to see you now.\nPlease proceed to Room 3.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: AppColors.getTextSubtitle(context),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // dialog
                    Navigator.pop(context); // screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    'I\'m on my way!',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1 - (_queuePosition / _totalInQueue.clamp(1, 100));

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(context),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'virtual_waiting_room'.tr(),
          style: GoogleFonts.poppins(
            color: AppColors.getTextTitle(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.getTextTitle(context)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Iconsax.notification,
              color: AppColors.getTextTitle(context),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ── Doctor Info Card ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
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
                      borderRadius: BorderRadius.circular(20),
                      image: DecorationImage(
                        image: AssetImage(widget.image),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.doctorName,
                          style: GoogleFonts.poppins(
                            color: AppColors.getTextTitle(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.specialty} • Room 3',
                          style: GoogleFonts.poppins(
                            color: AppColors.getTextSubtitle(context),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Active',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF10B981),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.1, end: 0),

            const SizedBox(height: 32),

            // ── Queue Position Hero ──
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isAlmostReady
                          ? [const Color(0xFF10B981), const Color(0xFF059669)]
                          : [const Color(0xFF3B82F6), const Color(0xFF8B5CF6)],
                      begin: AlignmentDirectional.topStart,
                      end: AlignmentDirectional.bottomEnd,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: (_isAlmostReady
                                ? const Color(0xFF10B981)
                                : const Color(0xFF3B82F6))
                            .withValues(alpha: 0.2 + (_pulseController.value * 0.15)),
                        blurRadius: 20 + (_pulseController.value * 10),
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        _isAlmostReady ? 'almost_ready'.tr() : 'your_position'.tr(),
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _queuePosition == 0 ? '🎉' : '#$_queuePosition',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                          if (_queuePosition > 0)
                            Text(
                              ' / $_totalInQueue',
                              style: GoogleFonts.poppins(
                                color: Colors.white.withValues(alpha: 0.6),
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                            icon: Iconsax.clock,
                            label: 'est_wait'.tr(),
                            value: '$_estimatedMinutes min',
                          ),
                          Container(
                            width: 1,
                            height: 40,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                          _buildStatItem(
                            icon: Iconsax.people,
                            label: 'ahead'.tr(),
                            value: '${_queuePosition > 0 ? _queuePosition - 1 : 0} people',
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),

            const SizedBox(height: 32),

            // ── Live Queue Visualization ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'live_queue'.tr(),
                        style: GoogleFonts.poppins(
                          color: AppColors.getTextTitle(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'LIVE',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFFEF4444),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Queue list
                  ...List.generate(_queuePeople.length, (index) {
                    final person = _queuePeople[index];
                    final isYou = person['name'] == 'You';
                    final isFirst = index == 0;

                    return Padding(
                      padding: const EdgeInsetsDirectional.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isYou
                              ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
                              : isFirst
                                  ? const Color(0xFF10B981).withValues(alpha: 0.08)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: isYou
                              ? Border.all(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            // Position number
                            Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isFirst
                                    ? const Color(0xFF10B981)
                                    : isYou
                                        ? const Color(0xFF3B82F6)
                                        : AppColors.getBorder(context),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.poppins(
                                  color: isFirst || isYou ? Colors.white : AppColors.getTextSubtitle(context),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Person name
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isYou ? 'You 👈' : person['name'],
                                    style: GoogleFonts.poppins(
                                      color: isYou
                                          ? const Color(0xFF3B82F6)
                                          : AppColors.getTextTitle(context),
                                      fontSize: 14,
                                      fontWeight: isYou ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Status badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isFirst
                                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                    : AppColors.getBackground(context),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isFirst ? 'In Session' : 'Waiting',
                                style: GoogleFonts.poppins(
                                  color: isFirst
                                      ? const Color(0xFF10B981)
                                      : AppColors.getTextSubtitle(context),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: (100 * index).ms).slideX(begin: 0.05, end: 0);
                  }),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 24),

            // ── Tips while waiting ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Iconsax.lamp_charge, color: Color(0xFFFBBF24), size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'While You Wait...',
                        style: GoogleFonts.poppins(
                          color: AppColors.getTextTitle(context),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTipItem(context, '📋', 'Prepare your questions for the doctor'),
                  const SizedBox(height: 12),
                  _buildTipItem(context, '💊', 'Have your current medications list ready'),
                  const SizedBox(height: 12),
                  _buildTipItem(context, '📱', 'You\'ll get a notification when it\'s your turn'),
                ],
              ),
            ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 32),

            // ── Leave Queue button ──
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.getSurface(context),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      title: Text(
                        'Leave Queue?',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextTitle(context),
                        ),
                      ),
                      content: Text(
                        'You will lose your position in the queue. Are you sure?',
                        style: GoogleFonts.poppins(
                          color: AppColors.getTextSubtitle(context),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'Stay',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF3B82F6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Leave',
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFEF4444),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: Text(
                  'Leave Queue',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFFEF4444),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 800.ms),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildTipItem(BuildContext context, String emoji, String text) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: AppColors.getTextSubtitle(context),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
