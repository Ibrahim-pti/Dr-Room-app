import 'package:flutter/material.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';

class VideoCallScreen extends StatefulWidget {
  final String doctorName;
  final String doctorImage;

  const VideoCallScreen({
    super.key,
    required this.doctorName,
    required this.doctorImage,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  bool _isMuted = false;
  bool _isVideoOff = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Doctor Video Placeholder (Full Screen) ──
          if (!_isVideoOff)
            Image.asset(
              widget.doctorImage,
              fit: BoxFit.cover,
            ).animate().fadeIn(duration: 1.seconds),
          if (_isVideoOff)
            Container(color: const Color(0xFF1E293B)),

          // Dark Gradient overlay for UI readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.6),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.8),
                ],
                stops: const [0.0, 0.2, 0.7, 1.0],
              ),
            ),
          ),

          // ── Top Bar ──
          PositionedDirectional(
            top: MediaQuery.of(context).padding.top + 16,
            start: 24,
            end: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 20, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      widget.doctorName,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '12:45', // Mock timer
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Iconsax.user_add, color: Colors.white),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ).animate().slideY(begin: -0.5, end: 0).fadeIn(),

          // ── My Video Thumbnail ──
          PositionedDirectional(
            top: MediaQuery.of(context).padding.top + 90,
            end: 24,
            child: Container(
              width: 100,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                // Since we don't have the user's camera, we show an icon
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: const Center(
                    child: Icon(Iconsax.camera, color: Colors.white, size: 32),
                  ),
                ),
              ),
            ),
          ).animate(delay: 500.ms).slideX(begin: 0.5, end: 0).fadeIn(),

          // ── Bottom Controls ──
          PositionedDirectional(
            bottom: 40,
            start: 0,
            end: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: _isMuted ? Iconsax.microphone_slash : Iconsax.microphone,
                  color: _isMuted ? Colors.white : Colors.white.withValues(alpha: 0.2),
                  iconColor: _isMuted ? Colors.black : Colors.white,
                  onTap: () => setState(() => _isMuted = !_isMuted),
                ),
                _buildControlButton(
                  icon: _isVideoOff ? Icons.videocam_off_outlined : Iconsax.video,
                  color: _isVideoOff ? Colors.white : Colors.white.withValues(alpha: 0.2),
                  iconColor: _isVideoOff ? Colors.black : Colors.white,
                  onTap: () => setState(() => _isVideoOff = !_isVideoOff),
                ),
                _buildControlButton(
                  icon: Iconsax.call_remove,
                  color: const Color(0xFFEF4444),
                  iconColor: Colors.white,
                  size: 64,
                  iconSize: 32,
                  onTap: () => Navigator.pop(context),
                ),
                _buildControlButton(
                  icon: Iconsax.message,
                  color: Colors.white.withValues(alpha: 0.2),
                  iconColor: Colors.white,
                  onTap: () {
                    // Open chat over video overlay
                    Navigator.pop(context); // just pop back to chat
                  },
                ),
                _buildControlButton(
                  icon: Iconsax.setting_2,
                  color: Colors.white.withValues(alpha: 0.2),
                  iconColor: Colors.white,
                  onTap: () {},
                ),
              ],
            ).animate().slideY(begin: 0.5, end: 0).fadeIn(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
    double size = 52,
    double iconSize = 24,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: iconSize),
      ),
    );
  }
}
