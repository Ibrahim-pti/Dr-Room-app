import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui';
import '../../core/utils/api_client.dart';
import 'widgets/holographic_medicine_card.dart';

class PillScannerScreen extends StatefulWidget {
  const PillScannerScreen({super.key});

  @override
  State<PillScannerScreen> createState() => _PillScannerScreenState();
}

class _PillScannerScreenState extends State<PillScannerScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _laserController;
  final ImagePicker _picker = ImagePicker();

  File? _image;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _result;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _captureImage();
  }

  @override
  void dispose() {
    _laserController.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    setState(() {
      _result = null;
      _errorMessage = null;
    });

    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1024,
    );

    if (photo == null) {
      if (mounted && _image == null) Navigator.pop(context);
      return;
    }

    setState(() => _image = File(photo.path));
    await _analyze();
  }

  Future<void> _analyze() async {
    if (_image == null) return;
    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final bytes = await _image!.readAsBytes();
      final base64Image = base64Encode(bytes);
      final response = await ApiClient.post(
        '/pills/identify',
        body: {'image_base64': base64Image},
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        setState(() => _result = data);
        if (data['identified'] == true) {
          _showMedicineDetails(data);
        }
      } else {
        setState(() {
          _errorMessage = (data is Map ? data['error']?.toString() : null) ??
              'Something went wrong while analyzing the photo.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not reach the AI service. Check your connection and try again.';
      });
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  void _showMedicineDetails(Map<String, dynamic> result) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return HolographicMedicineCard(
          name: result['name']?.toString() ?? 'Unknown medicine',
          category: result['category']?.toString() ?? '',
          commonUses: result['common_uses']?.toString() ?? '',
          dosage: result['typical_dosage']?.toString() ?? '',
          warnings: result['warnings']?.toString() ?? '',
          confidence: result['confidence']?.toString() ?? 'low',
          onAddPressed: () {
            Navigator.pop(context); // Close sheet
            Navigator.pop(context, true); // Return to previous screen with success
          },
        );
      },
    );
  }

  bool get _notConfidentlyIdentified =>
      _result != null && _result!['identified'] != true;

  @override
  Widget build(BuildContext context) {
    final bool showSuccess = _result != null && _result!['identified'] == true;
    final bool showProblem = _errorMessage != null || _notConfidentlyIdentified;
    final Color frameColor = showSuccess
        ? const Color(0xFF10B981)
        : showProblem
            ? const Color(0xFFEF4444)
            : const Color(0xFF3B82F6);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Captured photo as the background, or a dark gradient while the
          // camera sheet is opening.
          Positioned.fill(
            child: _image != null
                ? Image.file(_image!, fit: BoxFit.cover)
                : Container(
                    decoration: const BoxDecoration(
                      gradient: RadialGradient(
                        colors: [Color(0xFF1E293B), Colors.black],
                        radius: 1.5,
                      ),
                    ),
                  ),
          ),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),
          ),

          // The clear cutout in the middle for the "scanner"
          Center(
            child: Container(
              width: 250,
              height: 350,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: frameColor, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: frameColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  _buildCorner(AlignmentDirectional.topStart, frameColor),
                  _buildCorner(AlignmentDirectional.topEnd, frameColor),
                  _buildCorner(AlignmentDirectional.bottomStart, frameColor),
                  _buildCorner(AlignmentDirectional.bottomEnd, frameColor),

                  // Laser Animation while the AI call is in flight
                  if (_isAnalyzing)
                    AnimatedBuilder(
                      animation: _laserController,
                      builder: (context, child) {
                        return PositionedDirectional(
                          top: _laserController.value * 330,
                          start: 0,
                          end: 0,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.8),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                  if (showSuccess)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Color(0xFF10B981), size: 60),
                      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                    ),

                  if (showProblem)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.priority_high_rounded, color: Color(0xFFEF4444), size: 60),
                      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                    ),
                ],
              ),
            ),
          ),

          // Top App Bar Elements (Overlay)
          PositionedDirectional(
            top: 50,
            start: 24,
            end: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ),
                Text(
                  'AI Pill Scanner',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: _isAnalyzing ? null : _captureImage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Iconsax.refresh, color: Colors.white, size: 22),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Instruction Text
          PositionedDirectional(
            bottom: 60,
            start: 24,
            end: 24,
            child: Column(
              children: [
                Text(
                  showSuccess
                      ? 'Medicine Identified!'
                      : showProblem
                          ? "Couldn't confidently identify"
                          : _isAnalyzing
                              ? 'Analyzing with AI...'
                              : 'Align the pill or box within the frame',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: frameColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  showProblem
                      ? (_errorMessage ??
                          _result?['name']?.toString() ??
                          'Try retaking the photo in better light.')
                      : 'Powered by Gemini Vision — always confirm with a pharmacist.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                ),
                if (showProblem) ...[
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _captureImage,
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('Retake Photo'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner(AlignmentDirectional alignment, Color color) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: _getCornerBorder(alignment, color),
        ),
      ),
    );
  }

  BorderDirectional _getCornerBorder(AlignmentDirectional alignment, Color color) {
    const width = 4.0;
    if (alignment == AlignmentDirectional.topStart) {
      return BorderDirectional(top: BorderSide(color: color, width: width), start: BorderSide(color: color, width: width));
    } else if (alignment == AlignmentDirectional.topEnd) {
      return BorderDirectional(top: BorderSide(color: color, width: width), end: BorderSide(color: color, width: width));
    } else if (alignment == AlignmentDirectional.bottomStart) {
      return BorderDirectional(bottom: BorderSide(color: color, width: width), start: BorderSide(color: color, width: width));
    } else {
      return BorderDirectional(bottom: BorderSide(color: color, width: width), end: BorderSide(color: color, width: width));
    }
  }
}
