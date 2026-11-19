import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/api_client.dart';
import 'admin_app_bar.dart';
import 'admin_ui.dart';

class AdminReportSettingsScreen extends StatefulWidget {
  const AdminReportSettingsScreen({super.key});

  @override
  State<AdminReportSettingsScreen> createState() =>
      _AdminReportSettingsScreenState();
}

class _AdminReportSettingsScreenState extends State<AdminReportSettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  final _footerCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _signatureNameCtrl = TextEditingController();
  final _signatureTitleCtrl = TextEditingController();

  bool _showWatermark = true;
  bool _showStamp = true;
  bool _showSignature = true;

  String? _logoUrl;
  String? _signatureUrl;
  String? _localLogoPath;
  String? _localSignaturePath;
  bool _clearLogo = false;
  bool _clearSignature = false;

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _footerCtrl.dispose();
    _phoneCtrl.dispose();
    _signatureNameCtrl.dispose();
    _signatureTitleCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await ApiClient.get('/admin/report-settings');
      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body)['data'] ?? {};
        setState(() {
          _applyLoadedData(data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = AdminUi.readError(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _isLoading = false;
        });
      }
    }
  }

  void _applyLoadedData(dynamic data) {
    _titleCtrl.text =
        (data['header_title'] ?? 'دکتۆر ڕۆم - دۆسیەی پزیشکی و ئەنجامی پشکنین')
            .toString();
    _subtitleCtrl.text =
        (data['header_subtitle'] ?? 'Dr. Room Healthcare System & Lab Diagnostics')
            .toString();
    _footerCtrl.text =
        (data['footer_text'] ??
                'ئەم ڕاپۆرتە بە فەرمی لەلایەن تاقیگەی باوەڕپێکراو پەسەندکراوە و پارێزراوە بە مۆری ئەلیکترۆنی.')
            .toString();
    final rawPhone = (data['emergency_phone'] ?? '+964 750 000 0000').toString();
    _phoneCtrl.text = _cleanPhone(rawPhone);
    _signatureNameCtrl.text =
        (data['signature_name'] ?? 'بەڕێوەبەری پزیشکی و تاقیگە').toString();
    _signatureTitleCtrl.text =
        (data['signature_title'] ?? 'واژووی فەرمی پەسەندکردن').toString();
    _showWatermark = _parseBool(data['show_watermark'], fallback: true);
    _showStamp = _parseBool(data['show_stamp'], fallback: true);
    _showSignature = _parseBool(data['show_signature'], fallback: true);
    _logoUrl = data['logo_url']?.toString();
    _signatureUrl = data['signature_url']?.toString();
    _localLogoPath = null;
    _localSignaturePath = null;
    _clearLogo = false;
    _clearSignature = false;
  }

  bool _parseBool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final s = value.toString().trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return fallback;
  }

  String _cleanPhone(String raw) {
    return raw
        .replaceAll('\u200E', '')
        .replaceAll('\u200F', '')
        .replaceAll('\u202A', '')
        .replaceAll('\u202B', '')
        .replaceAll('\u202C', '')
        .trim();
  }

  Future<void> _pickImage({required bool isSignature}) async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
      );
      if (picked == null || !mounted) return;
      setState(() {
        if (isSignature) {
          _localSignaturePath = picked.path;
          _clearSignature = false;
        } else {
          _localLogoPath = picked.path;
          _clearLogo = false;
        }
      });
    } catch (e) {
      if (mounted) AdminUi.toast(context, 'نەتوانرا وێنە هەڵبژێردرێت: $e', isError: true);
    }
  }

  Future<void> _openSignaturePad() async {
    final strokes = <List<Offset>>[];
    List<Offset>? currentStroke;
    Size canvasSize = const Size(320, 170);

    final pngPath = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) {
        return StatefulBuilder(
          builder: (dCtx, setDlgState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'واژووکردن بە دەست (تەوقیح)',
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // AlertDialog measures content via IntrinsicWidth, which
              // LayoutBuilder doesn't support — a fixed width avoids that.
              content: SizedBox(
                width: 300,
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'لە ناو چوارچێوە سپییەکەدا واژوو بکە، دواتر ڕاستەوخۆ دەچێتە سەر ڕاپۆرت و فایلەکان.',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 170,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                        width: 1.4,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: LayoutBuilder(
                      builder: (_, constraints) {
                        canvasSize = Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );
                        return GestureDetector(
                          onPanStart: (details) {
                            setDlgState(() {
                              currentStroke = [details.localPosition];
                              strokes.add(currentStroke!);
                            });
                          },
                          onPanUpdate: (details) {
                            final pos = Offset(
                              details.localPosition.dx.clamp(0.0, canvasSize.width),
                              details.localPosition.dy.clamp(0.0, canvasSize.height),
                            );
                            setDlgState(() {
                              currentStroke?.add(pos);
                            });
                          },
                          onPanEnd: (_) {
                            currentStroke = null;
                          },
                          child: CustomPaint(
                            painter: _SignaturePadPainter(strokes),
                            size: Size.infinite,
                          ),
                        );
                      },
                    ),
                  ),
                ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dCtx),
                  child: const Text(
                    'داخستن',
                    style: TextStyle(fontFamily: 'Rabar'),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setDlgState(() => strokes.clear());
                  },
                  icon: const Icon(Iconsax.eraser, size: 16),
                  label: const Text(
                    'سڕینەوە',
                    style: TextStyle(fontFamily: 'Rabar'),
                  ),
                ),
                ElevatedButton(
                  onPressed: strokes.isEmpty
                      ? null
                      : () async {
                          final path = await _renderStrokesToPng(
                            strokes,
                            canvasSize,
                          );
                          if (dCtx.mounted) Navigator.pop(dCtx, path);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'جێبەجێکردن',
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (pngPath != null && mounted) {
      setState(() {
        _localSignaturePath = pngPath;
        _clearSignature = false;
        _showSignature = true;
      });
    }
  }

  Future<String> _renderStrokesToPng(
    List<List<Offset>> strokes,
    Size size,
  ) async {
    const scale = 3.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(scale, scale);

    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length == 1) {
        canvas.drawCircle(stroke.first, 1.6, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(
      (size.width * scale).round().clamp(1, 2000),
      (size.height * scale).round().clamp(1, 2000),
    );
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(
      '${Directory.systemTemp.path}/drroom_sig_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await file.writeAsBytes(byteData!.buffer.asUint8List());
    return file.path;
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final files = <String, String>{};
      if (_localLogoPath != null && _localLogoPath!.isNotEmpty) {
        files['logo'] = _localLogoPath!;
      }
      if (_localSignaturePath != null && _localSignaturePath!.isNotEmpty) {
        files['signature'] = _localSignaturePath!;
      }

      final res = await ApiClient.uploadMultipart(
        '/admin/report-settings',
        fields: {
          'header_title': _titleCtrl.text.trim().isNotEmpty
              ? _titleCtrl.text.trim()
              : 'دکتۆر ڕۆم - دۆسیەی پزیشکی و ئەنجامی پشکنین',
          'header_subtitle': _subtitleCtrl.text.trim(),
          'footer_text': _footerCtrl.text.trim(),
          'emergency_phone': _cleanPhone(_phoneCtrl.text),
          'show_watermark': _showWatermark ? '1' : '0',
          'show_stamp': _showStamp ? '1' : '0',
          'show_signature': _showSignature ? '1' : '0',
          'signature_name': _signatureNameCtrl.text.trim(),
          'signature_title': _signatureTitleCtrl.text.trim(),
          if (_clearLogo) 'clear_logo': '1',
          if (_clearSignature) 'clear_signature': '1',
        },
        files: files.isNotEmpty ? files : null,
      );

      if (!mounted) return;

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map && body['data'] is Map) {
          setState(() {
            _applyLoadedData(body['data']);
          });
        }
        AdminUi.toast(
          context,
          'دیزاین، تەوقیح و ڕێکخستنی ڕاپۆرت بە سەرکەوتوویی نوێکرایەوە',
        );
      } else {
        AdminUi.toast(context, AdminUi.readError(res), isError: true);
      }
    } catch (e) {
      if (mounted) AdminUi.toast(context, '$e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AdminAppBar(
        title: 'دیزاین و قالبی ڕاپۆرتەکان',
        subtitle: 'ڕێکخستنی سەرپەڕە، لۆگۆ، مۆر و تەوقیحی فەرمی ئەنجامەکان',
        icon: Iconsax.document_filter,
        iconColor: const Color(0xFF6366F1),
        iconBackgroundColor: const Color(0xFF6366F1).withValues(alpha: 0.1),
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
                        const Icon(
                          Iconsax.info_circle,
                          size: 48,
                          color: Colors.amber,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: AdminUi.subtitle,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text(
                            'دووبارە هەوڵبدەرەوە',
                            style: TextStyle(fontFamily: 'Rabar'),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section Header: Live Preview
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Iconsax.eye,
                              size: 16,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'پێشبینینی ڕاستەوخۆی قالبی فەرمی (Live Preview)',
                              style: AdminUi.title,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      _buildDocumentPreview(isDark)
                          .animate()
                          .fadeIn(duration: 250.ms),

                      const SizedBox(height: 24),

                      // Section Header: Header Details
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Iconsax.edit_2,
                              size: 16,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('سەرپەڕە و دەقە فەرمییەکان', style: AdminUi.title),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Container(
                        decoration: AdminUi.cardDecoration,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputField(
                              label: 'سەرناوی فەرمی سەرپەڕەی ڕاپۆرت',
                              hint:
                                  'دکتۆر ڕۆم - دۆسیەی پزیشکی و ئەنجامی پشکنین',
                              icon: Iconsax.document_text,
                              controller: _titleCtrl,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 14),
                            _buildInputField(
                              label: 'سەردێڕی دووەم (ئینگلیزی / پۆلێن)',
                              hint:
                                  'Dr. Room Healthcare System & Lab Diagnostics',
                              icon: Iconsax.text_block,
                              controller: _subtitleCtrl,
                              isDark: isDark,
                              textDirection: TextDirection.ltr,
                            ),
                            const SizedBox(height: 14),
                            _buildInputField(
                              label: 'ژمارەی پەیوەندی و فریاکەوتن',
                              hint: '+964 750 000 0000',
                              icon: Iconsax.call,
                              controller: _phoneCtrl,
                              isDark: isDark,
                              keyboardType: TextInputType.phone,
                              textDirection: TextDirection.ltr,
                            ),
                            const SizedBox(height: 14),
                            _buildInputField(
                              label: 'دەقی خوارەوەی ڕاپۆرت (تێبینی و گەرەنتی)',
                              hint:
                                  'ئەم ڕاپۆرتە بە فەرمی لەلایەن تاقیگەی باوەڕپێکراو پەسەندکراوە...',
                              icon: Iconsax.note_text,
                              controller: _footerCtrl,
                              isDark: isDark,
                              maxLines: 2,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 300.ms),

                      const SizedBox(height: 24),

                      // Section Header: Signature & Logo
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Iconsax.pen_add,
                              size: 16,
                              color: Color(0xFF8B5CF6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('تەوقیح (واژوو) و لۆگۆی فەرمی', style: AdminUi.title),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Container(
                        decoration: AdminUi.cardDecoration,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Logo Picker Row
                            Row(
                              children: [
                                _buildLogoPreviewBox(isDark, size: 54),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'لۆگۆی سەرپەڕەی ڕاپۆرت',
                                        style: TextStyle(
                                          fontFamily: 'Rabar',
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'لە گۆشەی سەرەوەی ڕاپۆرتە پزیشکییەکان دەردەکەوێت',
                                        style: TextStyle(
                                          fontFamily: 'Rabar',
                                          fontSize: 11,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _pickImage(isSignature: false),
                                    icon: const Icon(Iconsax.gallery, size: 17),
                                    label: const Text(
                                      'گۆڕینی لۆگۆ',
                                      style: TextStyle(
                                        fontFamily: 'Rabar',
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF6366F1),
                                      side: const BorderSide(
                                        color: Color(0xFF6366F1),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                if (_localLogoPath != null ||
                                    (_logoUrl != null &&
                                        _logoUrl!.isNotEmpty &&
                                        !_clearLogo)) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: 'گەڕانەوە بۆ لۆگۆی بنەڕەتی',
                                    onPressed: () {
                                      setState(() {
                                        _localLogoPath = null;
                                        _clearLogo = true;
                                      });
                                    },
                                    icon: const Icon(
                                      Iconsax.trash,
                                      color: Color(0xFFEF4444),
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            Divider(
                              height: 28,
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFF1F5F9),
                            ),

                            // Signature Toggle & Inputs
                            _buildCustomSwitchTile(
                              title: 'پیشاندانی تەوقیح (واژوو) لەسەر فایلەکان',
                              subtitle:
                                  'واژوو و ناوی بەرپرس دەچێتە خوارەوەی هەر ئەنجامێکی پشکنین کە بۆ نەخۆش دەنێردرێت',
                              icon: Iconsax.pen_tool,
                              iconColor: const Color(0xFF8B5CF6),
                              value: _showSignature,
                              onChanged: (v) =>
                                  setState(() => _showSignature = v),
                              isDark: isDark,
                            ),
                            const SizedBox(height: 10),
                            _buildInputField(
                              label: 'ناوی واژووکار (دکتۆر / بەڕێوەبەر)',
                              hint: 'بەڕێوەبەری پزیشکی و تاقیگە',
                              icon: Iconsax.user_edit,
                              controller: _signatureNameCtrl,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 12),
                            _buildInputField(
                              label: 'ناونیشانی واژوو / پۆست',
                              hint: 'واژووی فەرمی پەسەندکردن',
                              icon: Iconsax.award,
                              controller: _signatureTitleCtrl,
                              isDark: isDark,
                            ),
                            const SizedBox(height: 14),

                            // Signature Image Preview Box
                            Container(
                              height: 92,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Center(
                                child: _buildSignatureImageWidget(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _openSignaturePad,
                                    icon: const Icon(Iconsax.edit, size: 17),
                                    label: const Text(
                                      'واژووکردن بە دەست',
                                      style: TextStyle(
                                        fontFamily: 'Rabar',
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF8B5CF6),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 11,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () =>
                                        _pickImage(isSignature: true),
                                    icon: const Icon(
                                      Iconsax.gallery_add,
                                      size: 17,
                                    ),
                                    label: const Text(
                                      'هەڵبژاردنی وێنە',
                                      style: TextStyle(
                                        fontFamily: 'Rabar',
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF8B5CF6),
                                      side: const BorderSide(
                                        color: Color(0xFF8B5CF6),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 11,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                                if (_hasAnySignature) ...[
                                  const SizedBox(width: 4),
                                  IconButton(
                                    tooltip: 'سڕینەوەی واژوو',
                                    onPressed: () {
                                      setState(() {
                                        _localSignaturePath = null;
                                        _clearSignature = true;
                                      });
                                    },
                                    icon: const Icon(
                                      Iconsax.trash,
                                      color: Color(0xFFEF4444),
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 325.ms),

                      const SizedBox(height: 24),

                      // Section Header: Stamps & Security
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Iconsax.shield_tick,
                              size: 16,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('مۆر و ئاسایشی بەڵگەنامەکان', style: AdminUi.title),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Container(
                        decoration: AdminUi.cardDecoration,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Column(
                          children: [
                            _buildCustomSwitchTile(
                              title:
                                  'پیشاندانی مۆری ئەلیکترۆنی لەسەر فایلی ڕاپۆرت',
                              subtitle:
                                  'مۆری فەرمی پەسەندکراو بە سەوزی لە گۆشەی سەرەوە چاپ دەکرێت',
                              icon: Iconsax.verify,
                              iconColor: const Color(0xFF10B981),
                              value: _showStamp,
                              onChanged: (v) => setState(() => _showStamp = v),
                              isDark: isDark,
                            ),
                            Divider(
                              height: 20,
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFF1F5F9),
                            ),
                            _buildCustomSwitchTile(
                              title:
                                  'پیشاندانی Watermark لە پاشبنەمای پەڕە',
                              subtitle:
                                  'بۆ پاراستنی ڕاپۆرت لە ساختەکاری و کۆپیکردنی دەستکاری کراو',
                              icon: Iconsax.security_safe,
                              iconColor: const Color(0xFF6366F1),
                              value: _showWatermark,
                              onChanged: (v) =>
                                  setState(() => _showWatermark = v),
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 350.ms),

                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shadowColor: const Color(0xFF6366F1).withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Iconsax.tick_circle, size: 20),
                                    SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'پاشەکەوتکردنی ڕێکخستنەکان',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Rabar',
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  bool get _hasAnySignature =>
      (_localSignaturePath != null && _localSignaturePath!.isNotEmpty) ||
      (!_clearSignature && _signatureUrl != null && _signatureUrl!.isNotEmpty);

  Widget _buildSignatureImageWidget({double height = 66}) {
    if (_localSignaturePath != null && _localSignaturePath!.isNotEmpty) {
      return Image.file(
        File(_localSignaturePath!),
        height: height,
        fit: BoxFit.contain,
      );
    }
    if (!_clearSignature &&
        _signatureUrl != null &&
        _signatureUrl!.isNotEmpty) {
      final remote = ApiClient.getImageProvider(_signatureUrl);
      if (remote != null) {
        return Image(
          image: remote,
          height: height,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Text(
            'هێشتا واژوو زیادنەکراوە',
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 11,
              color: Color(0xFF94A3B8),
            ),
          ),
        );
      }
    }
    return const Text(
      'هێشتا واژوو (تەوقیح) زیادنەکراوە',
      style: TextStyle(
        fontFamily: 'Rabar',
        fontSize: 11.5,
        color: Color(0xFF94A3B8),
      ),
    );
  }

  Widget _buildLogoPreviewBox(bool isDark, {double size = 54}) {
    Widget child;
    if (_localLogoPath != null && _localLogoPath!.isNotEmpty) {
      child = Image.file(File(_localLogoPath!), fit: BoxFit.cover);
    } else if (!_clearLogo && _logoUrl != null && _logoUrl!.isNotEmpty) {
      final remoteLogo = ApiClient.getImageProvider(_logoUrl);
      child = remoteLogo != null
          ? Image(
              image: remoteLogo,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  Image.asset('assets/images/app_icon.png', fit: BoxFit.cover),
            )
          : Image.asset('assets/images/app_icon.png', fit: BoxFit.cover);
    } else {
      child = Image.asset(
        'assets/images/app_icon.png',
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(
          Icons.local_hospital_rounded,
          color: Color(0xFF6366F1),
          size: 28,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.16),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: child,
      ),
    );
  }

  /// Modern Interactive Medical Document Preview Card
  Widget _buildDocumentPreview(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (_showWatermark)
            Positioned.fill(
              child: Center(
                child: Opacity(
                  opacity: isDark ? 0.05 : 0.04,
                  child: Transform.rotate(
                    angle: -0.25,
                    child: const Text(
                      'DR. ROOM VERIFIED OFFICIAL',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 6,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF6366F1),
                      Color(0xFF8B5CF6),
                      Color(0xFF3B82F6),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLogoPreviewBox(isDark, size: 54),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _titleCtrl.text.isNotEmpty
                                    ? _titleCtrl.text
                                    : 'دکتۆر ڕۆم - دۆسیەی پزیشکی و ئەنجامی پشکنین',
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _subtitleCtrl.text.isNotEmpty
                                    ? _subtitleCtrl.text
                                    : 'Dr. Room Healthcare System & Lab Diagnostics',
                                textDirection: TextDirection.ltr,
                                textAlign: Directionality.of(context) ==
                                        TextDirection.rtl
                                    ? TextAlign.right
                                    : TextAlign.left,
                                style: const TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_showStamp)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF10B981),
                                width: 1.2,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Iconsax.verify,
                                  color: Color(0xFF10B981),
                                  size: 13,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'پەسەندکراوە',
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    Divider(
                      height: 1,
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFF1F5F9),
                    ),
                    const SizedBox(height: 12),

                    // Phone & Signature Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF0F172A)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Iconsax.call,
                                  size: 13,
                                  color: Color(0xFF6366F1),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '\u200E${_cleanPhone(_phoneCtrl.text).isNotEmpty ? _cleanPhone(_phoneCtrl.text) : '+964 750 000 0000'}',
                                  textDirection: TextDirection.ltr,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                    color: isDark
                                        ? Colors.white70
                                        : const Color(0xFF334155),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (_showSignature)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_hasAnySignature)
                                  _buildSignatureImageWidget(height: 34)
                                else
                                  const Text(
                                    'شوێنی تەوقیح',
                                    style: TextStyle(
                                      fontFamily: 'Rabar',
                                      fontSize: 10,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                const SizedBox(height: 2),
                                Text(
                                  _signatureNameCtrl.text.trim().isNotEmpty
                                      ? _signatureNameCtrl.text.trim()
                                      : 'بەڕێوەبەری پزیشکی',
                                  style: const TextStyle(
                                    fontFamily: 'Rabar',
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                if (_signatureTitleCtrl.text.trim().isNotEmpty)
                                  Text(
                                    _signatureTitleCtrl.text.trim(),
                                    style: const TextStyle(
                                      fontFamily: 'Rabar',
                                      fontSize: 8.5,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    Text(
                      _footerCtrl.text.isNotEmpty
                          ? _footerCtrl.text
                          : 'ئەم ڕاپۆرتە بە فەرمی لەلایەن تاقیگەی باوەڕپێکراو پەسەندکراوە و پارێزراوە بە مۆری ئەلیکترۆنی.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 10.5,
                        height: 1.4,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Modern Form Input Field with Icon Badge
  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required bool isDark,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    TextDirection? textDirection,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Rabar',
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Directionality(
            textDirection: textDirection ?? Directionality.of(context),
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              keyboardType: keyboardType,
              textDirection: textDirection,
              textAlign: textDirection == TextDirection.ltr
                  ? TextAlign.left
                  : TextAlign.right,
              onChanged: (_) => setState(() {}),
              style: textDirection == TextDirection.ltr
                  ? GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    )
                  : TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
              decoration: InputDecoration(
                hintText: hint,
                hintTextDirection: textDirection,
                hintStyle: const TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 12,
                  color: Color(0xFF94A3B8),
                ),
                prefixIcon: Icon(icon, size: 20, color: const Color(0xFF6366F1)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Custom Switch Tile without ListTile to prevent any DecoratedBox assertions
  Widget _buildCustomSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: value,
            activeTrackColor: iconColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SignaturePadPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  _SignaturePadPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length == 1) {
        canvas.drawCircle(stroke.first, 1.6, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
        continue;
      }
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePadPainter oldDelegate) => true;
}
