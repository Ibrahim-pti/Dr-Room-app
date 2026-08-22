import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
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

  /// Set when opening the camera failed outright, so the screen can explain
  /// itself and point at the gallery instead of looking broken.
  bool _cameraUnavailable = false;

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

  Future<void> _captureImage() => _pickImage(ImageSource.camera);

  Future<void> _pickFromGallery() => _pickImage(ImageSource.gallery);

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _result = null;
      _errorMessage = null;
    });

    XFile? photo;

    try {
      photo = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1024,
      );
    } catch (e) {
      // Devices without a usable camera — the iOS Simulator above all — throw
      // here. Staying on the screen with the gallery button visible beats
      // bouncing the user back with no explanation.
      debugPrint('Image picker failed: $e');
      if (mounted) {
        setState(() => _cameraUnavailable = source == ImageSource.camera);
      }
      return;
    }

    // Cancelling the very first capture means the user never wanted the
    // scanner; close it. Cancelling a retake leaves the previous photo up.
    if (photo == null) {
      if (mounted && _image == null) Navigator.pop(context);
      return;
    }

    setState(() => _image = File(photo!.path));
    await _analyze();
  }

  /// Looks a medicine up by name instead of by photo.
  ///
  /// The camera route needs the paid Gemini key; this one is backed by the
  /// free openFDA label database, so it is also the way in when the scanner
  /// cannot read a box — or when there is no camera at all.
  Future<void> _lookUpByName() async {
    final name = await showDialog<String>(
      context: context,
      builder: (context) => const _MedicineNameDialog(),
    );

    if (name == null || name.trim().isEmpty || !mounted) return;

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _result = null;
    });

    // The backend translates the label into whichever language the app is in,
    // so the lookup follows the user's chosen locale rather than always
    // answering in English.
    final lang = context.locale.languageCode;

    try {
      final response = await ApiClient.get(
        '/medicines/lookup'
        '?query=${Uri.encodeQueryComponent(name.trim())}'
        '&lang=${Uri.encodeQueryComponent(lang)}',
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        setState(() => _result = data);
        if (data['identified'] == true && mounted) {
          _showMedicineDetails(data);
        }
      } else {
        setState(() {
          _errorMessage = (data is Map ? data['error']?.toString() : null) ??
              'Could not look up that medicine.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Could not reach the medicine service. Check your connection and try again.';
      });
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
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
          activeIngredient: result['active_ingredient']?.toString() ?? '',
          sideEffects: result['side_effects']?.toString() ?? '',
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool showSuccess = _result != null && _result!['identified'] == true;
    final bool showProblem =
        _errorMessage != null || _notConfidentlyIdentified || _cameraUnavailable;
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
                      : _cameraUnavailable
                          ? 'Camera not available'
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
                  _cameraUnavailable
                      ? 'This device has no camera available. Pick a photo from the gallery instead.'
                      : showProblem
                          ? (_errorMessage ??
                              _result?['name']?.toString() ??
                              'Try retaking the photo in better light.')
                          : 'Powered by Gemini Vision — always confirm with a pharmacist.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                ),
                if (showProblem) ...[
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_cameraUnavailable) ...[
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
                        const SizedBox(width: 12),
                      ],
                      // Always reachable: it is the only way in on a device
                      // whose camera cannot be opened.
                      ElevatedButton.icon(
                        onPressed: _pickFromGallery,
                        icon: const Icon(Icons.photo_library_outlined, size: 18),
                        label: const Text('Gallery'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _cameraUnavailable
                              ? const Color(0xFF3B82F6)
                              : Colors.white24,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // The name lookup needs no camera and no paid key, so it is
                  // offered whenever the photo route has not worked out.
                  TextButton.icon(
                    onPressed: _isAnalyzing ? null : _lookUpByName,
                    icon: const Icon(Icons.search, size: 18, color: Colors.white70),
                    label: Text(
                      'Search by name instead',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
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

/// Asks for a medicine name to look up. Kept private to the scanner because
/// that is the only place a name-based lookup starts from today.
class _MedicineNameDialog extends StatefulWidget {
  const _MedicineNameDialog();

  @override
  State<_MedicineNameDialog> createState() => _MedicineNameDialogState();
}

class _MedicineNameDialogState extends State<_MedicineNameDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.length < 2) return;
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        'Medicine name',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _submit(),
        style: GoogleFonts.poppins(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'e.g. Paracetamol, Augmentin',
          hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 14),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white24),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF3B82F6)),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            'Look up',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}