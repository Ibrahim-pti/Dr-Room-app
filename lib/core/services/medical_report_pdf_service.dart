import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart' as intl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../utils/api_client.dart';

/// Builds official Dr. Room branded Medical / Lab Result PDFs with Header, Logo,
/// Watermark, Verified Stamp, Signature (تەوقیح), Footer, and wrapped lab files.
class MedicalReportPdfService {
  static const PdfColor primaryColor = PdfColor.fromInt(0xFF4F46E5);
  static const PdfColor primaryLight = PdfColor.fromInt(0xFFEEF2FF);
  static const PdfColor successColor = PdfColor.fromInt(0xFF059669);
  static const PdfColor successLight = PdfColor.fromInt(0xFFECFDF5);
  static const PdfColor textColor = PdfColor.fromInt(0xFF0F172A);
  static const PdfColor textMuted = PdfColor.fromInt(0xFF64748B);
  static const PdfColor borderColor = PdfColor.fromInt(0xFFE2E8F0);
  static const PdfColor bgMuted = PdfColor.fromInt(0xFFF8FAFC);

  static bool _parseBool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final s = value.toString().trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return fallback;
  }

  static Future<Map<String, dynamic>> _resolveBranding(
    Map<String, dynamic>? passed,
  ) async {
    if (passed != null && passed.isNotEmpty) {
      return passed;
    }
    try {
      final res = await ApiClient.get('/report-branding');
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is Map && decoded['data'] is Map) {
          return Map<String, dynamic>.from(decoded['data']);
        }
      }
    } catch (_) {}
    return {};
  }

  static Future<Uint8List?> downloadImageBytes(String? rawUrl) async {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    final resolved = ApiClient.getImageUrl(rawUrl);
    if (resolved.isEmpty || resolved.startsWith('assets/')) return null;
    try {
      final res = await http
          .get(Uri.parse(resolved))
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
        return res.bodyBytes;
      }
    } catch (_) {}
    return null;
  }

  static Future<List<pw.MemoryImage>> _loadAttachedImages(
    String? rawFileUrl,
  ) async {
    if (rawFileUrl == null || rawFileUrl.trim().isEmpty) return const [];
    final lower = rawFileUrl.toLowerCase();
    final bytes = await downloadImageBytes(rawFileUrl);
    if (bytes == null) return const [];

    if (lower.contains('.pdf')) {
      final pages = <pw.MemoryImage>[];
      try {
        await for (final page in Printing.raster(bytes, dpi: 150)) {
          final png = await page.toPng();
          pages.add(pw.MemoryImage(png));
          if (pages.length >= 10) break;
        }
      } catch (_) {}
      return pages;
    }

    if (lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('.png') ||
        lower.contains('.webp')) {
      try {
        return [pw.MemoryImage(bytes)];
      } catch (_) {}
    }

    return const [];
  }

  static Future<pw.Document> generateDocument({
    required Map<String, dynamic> result,
    Map<String, dynamic>? branding,
  }) async {
    final pdf = pw.Document();
    final cfg = await _resolveBranding(branding);

    final fontData = await rootBundle.load('fonts/Rabar-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);
    final boldFontData = await rootBundle.load('fonts/Rabar-Bold.ttf');
    final ttfBold = pw.Font.ttf(boldFontData);

    pw.MemoryImage? logoImage;
    final remoteLogoBytes = await downloadImageBytes(cfg['logo_url']?.toString());
    if (remoteLogoBytes != null) {
      try {
        logoImage = pw.MemoryImage(remoteLogoBytes);
      } catch (_) {}
    }
    if (logoImage == null) {
      try {
        final localLogo = await rootBundle.load('assets/images/app_icon.png');
        logoImage = pw.MemoryImage(localLogo.buffer.asUint8List());
      } catch (_) {}
    }

    pw.MemoryImage? signatureImage;
    final sigBytes = await downloadImageBytes(cfg['signature_url']?.toString());
    if (sigBytes != null) {
      try {
        signatureImage = pw.MemoryImage(sigBytes);
      } catch (_) {}
    }

    final rawFileUrl =
        (result['file_url'] ?? result['file_path'] ?? '').toString().trim();
    final attachedPages = await _loadAttachedImages(rawFileUrl);

    final headerTitle = (cfg['header_title']?.toString().trim().isNotEmpty ?? false)
        ? cfg['header_title'].toString().trim()
        : 'دکتۆر ڕۆم - دۆسیەی پزیشکی و ئەنجامی پشکنین';
    final headerSubtitle =
        (cfg['header_subtitle']?.toString().trim().isNotEmpty ?? false)
            ? cfg['header_subtitle'].toString().trim()
            : 'Dr. Room Healthcare System & Lab Diagnostics';
    final footerText = (cfg['footer_text']?.toString().trim().isNotEmpty ?? false)
        ? cfg['footer_text'].toString().trim()
        : 'ئەم ڕاپۆرتە بە فەرمی لەلایەن تاقیگەی باوەڕپێکراو پەسەندکراوە و پارێزراوە بە مۆری ئەلیکترۆنی.';
    final emergencyPhone =
        (cfg['emergency_phone']?.toString().trim().isNotEmpty ?? false)
            ? cfg['emergency_phone'].toString().trim()
            : '+964 750 000 0000';
    final showWatermark = _parseBool(cfg['show_watermark'], fallback: true);
    final showStamp = _parseBool(cfg['show_stamp'], fallback: true);
    final showSignature = _parseBool(cfg['show_signature'], fallback: true);
    final sigName = (cfg['signature_name']?.toString().trim().isNotEmpty ?? false)
        ? cfg['signature_name'].toString().trim()
        : 'بەڕێوەبەری پزیشکی و تاقیگە';
    final sigTitle =
        (cfg['signature_title']?.toString().trim().isNotEmpty ?? false)
            ? cfg['signature_title'].toString().trim()
            : 'واژووی فەرمی پەسەندکردن';

    final testName =
        (result['test_name'] ?? result['test']?['name'] ?? 'پشکنینی تاقیگە')
            .toString();
    final labName =
        (result['lab_name'] ??
                result['lab']?['user']?['name'] ??
                result['lab']?['name'] ??
                'تاقیگەی باوەڕپێکراو')
            .toString();
    final patientName =
        (result['patient_name'] ?? result['patient']?['name'] ?? 'نەخۆش')
            .toString();
    final patientPhone =
        (result['patient_phone'] ?? result['patient']?['phone'] ?? '').toString();
    final resultValue = (result['result_value'] ?? '').toString().trim();
    final notes = (result['notes'] ?? '').toString().trim();
    final createdAt = (result['created_at'] ??
            intl.DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()))
        .toString();
    final reportRef = 'DR-LAB-${result['id'] ?? '0'}';

    final pageTheme = pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(22),
      theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
      buildBackground: showWatermark
          ? (_) => pw.Center(
                child: pw.Transform.rotate(
                  angle: -0.45,
                  child: pw.Opacity(
                    opacity: 0.06,
                    child: pw.Text(
                      'DR. ROOM VERIFIED OFFICIAL',
                      style: pw.TextStyle(
                        font: ttfBold,
                        fontSize: 34,
                        color: primaryColor,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
              )
          : null,
    );

    // First page: Official Summary + Metadata + Result + Signature (plus first attachment if fits or separate pages)
    pdf.addPage(
      pw.Page(
        pageTheme: pageTheme,
        build: (_) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _buildHeader(
                  logoImage: logoImage,
                  headerTitle: headerTitle,
                  headerSubtitle: headerSubtitle,
                  emergencyPhone: emergencyPhone,
                  showStamp: showStamp,
                  reportRef: reportRef,
                  createdAt: createdAt,
                  ttfBold: ttfBold,
                ),
                pw.SizedBox(height: 12),
                _buildPatientLabStrip(
                  patientName: patientName,
                  patientPhone: patientPhone,
                  labName: labName,
                  testName: testName,
                  ttfBold: ttfBold,
                ),
                pw.SizedBox(height: 12),
                if (resultValue.isNotEmpty) ...[
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: primaryLight,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(8),
                      ),
                      border: pw.Border.all(color: primaryColor, width: 0.8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'ئەنجامی تۆمارکراوی پشکنین',
                          style: pw.TextStyle(
                            font: ttfBold,
                            fontSize: 9,
                            color: primaryColor,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          resultValue,
                          style: pw.TextStyle(
                            font: ttfBold,
                            fontSize: 12,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),
                ],
                if (notes.isNotEmpty) ...[
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: bgMuted,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(8),
                      ),
                      border: pw.Border.all(color: borderColor),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'تێبینی و ڕێنمایی تاقیگە',
                          style: pw.TextStyle(
                            font: ttfBold,
                            fontSize: 9,
                            color: textMuted,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          notes,
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),
                ],
                if (attachedPages.isNotEmpty)
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(8),
                        ),
                        border: pw.Border.all(color: borderColor),
                      ),
                      child: pw.Center(
                        child: pw.Image(
                          attachedPages.first,
                          fit: pw.BoxFit.contain,
                        ),
                      ),
                    ),
                  )
                else
                  pw.Spacer(),
                pw.SizedBox(height: 10),
                _buildFooterWithSignature(
                  footerText: footerText,
                  emergencyPhone: emergencyPhone,
                  showSignature: showSignature,
                  signatureImage: signatureImage,
                  sigName: sigName,
                  sigTitle: sigTitle,
                  showStamp: showStamp,
                  ttfBold: ttfBold,
                ),
              ],
            ),
          );
        },
      ),
    );

    // Additional attached pages (if lab uploaded a multi-page PDF)
    for (int i = 1; i < attachedPages.length; i++) {
      pdf.addPage(
        pw.Page(
          pageTheme: pageTheme,
          build: (_) {
            return pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(
                    logoImage: logoImage,
                    headerTitle: headerTitle,
                    headerSubtitle: headerSubtitle,
                    emergencyPhone: emergencyPhone,
                    showStamp: showStamp,
                    reportRef: '$reportRef (پەڕەی ${i + 1})',
                    createdAt: createdAt,
                    ttfBold: ttfBold,
                  ),
                  pw.SizedBox(height: 10),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(6),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: const pw.BorderRadius.all(
                          pw.Radius.circular(8),
                        ),
                        border: pw.Border.all(color: borderColor),
                      ),
                      child: pw.Center(
                        child: pw.Image(
                          attachedPages[i],
                          fit: pw.BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  _buildFooterWithSignature(
                    footerText: footerText,
                    emergencyPhone: emergencyPhone,
                    showSignature: showSignature,
                    signatureImage: signatureImage,
                    sigName: sigName,
                    sigTitle: sigTitle,
                    showStamp: showStamp,
                    ttfBold: ttfBold,
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return pdf;
  }

  static pw.Widget _buildHeader({
    required pw.MemoryImage? logoImage,
    required String headerTitle,
    required String headerSubtitle,
    required String emergencyPhone,
    required bool showStamp,
    required String reportRef,
    required String createdAt,
    required pw.Font ttfBold,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: bgMuted,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: borderColor),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (showStamp)
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: pw.BoxDecoration(
                    color: successLight,
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(5),
                    ),
                    border: pw.Border.all(color: successColor, width: 0.9),
                  ),
                  child: pw.Text(
                    'پەسەندکراوی فەرمی',
                    style: pw.TextStyle(
                      font: ttfBold,
                      fontSize: 8,
                      color: successColor,
                    ),
                  ),
                ),
              pw.SizedBox(height: 4),
              pw.Directionality(
                textDirection: pw.TextDirection.ltr,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      reportRef,
                      style: pw.TextStyle(
                        font: ttfBold,
                        fontSize: 8.5,
                        color: textColor,
                      ),
                    ),
                    pw.Text(
                      createdAt,
                      style: const pw.TextStyle(fontSize: 7.5, color: textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  headerTitle,
                  style: pw.TextStyle(
                    font: ttfBold,
                    fontSize: 12.5,
                    color: primaryColor,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Directionality(
                  textDirection: pw.TextDirection.ltr,
                  child: pw.Text(
                    headerSubtitle,
                    style: const pw.TextStyle(fontSize: 8.5, color: textMuted),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Directionality(
                  textDirection: pw.TextDirection.ltr,
                  child: pw.Text(
                    emergencyPhone,
                    style: pw.TextStyle(
                      font: ttfBold,
                      fontSize: 8,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          if (logoImage != null)
            pw.Container(
              width: 44,
              height: 44,
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: borderColor),
              ),
              child: pw.ClipRRect(
                horizontalRadius: 8,
                verticalRadius: 8,
                child: pw.Image(logoImage, fit: pw.BoxFit.cover),
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildPatientLabStrip({
    required String patientName,
    required String patientPhone,
    required String labName,
    required String testName,
    required pw.Font ttfBold,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: borderColor),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'نەخۆش',
                  style: const pw.TextStyle(fontSize: 7.5, color: textMuted),
                ),
                pw.Text(
                  patientName,
                  style: pw.TextStyle(
                    font: ttfBold,
                    fontSize: 10,
                    color: textColor,
                  ),
                ),
                if (patientPhone.isNotEmpty)
                  pw.Directionality(
                    textDirection: pw.TextDirection.ltr,
                    child: pw.Text(
                      patientPhone,
                      style: const pw.TextStyle(fontSize: 8, color: textMuted),
                    ),
                  ),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'تاقیگەی ئەنجامدەر',
                  style: const pw.TextStyle(fontSize: 7.5, color: textMuted),
                ),
                pw.Text(
                  labName,
                  style: pw.TextStyle(
                    font: ttfBold,
                    fontSize: 10,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'جۆری پشکنین',
                  style: const pw.TextStyle(fontSize: 7.5, color: textMuted),
                ),
                pw.Text(
                  testName,
                  style: pw.TextStyle(
                    font: ttfBold,
                    fontSize: 10,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooterWithSignature({
    required String footerText,
    required String emergencyPhone,
    required bool showSignature,
    required pw.MemoryImage? signatureImage,
    required String sigName,
    required String sigTitle,
    required bool showStamp,
    required pw.Font ttfBold,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: bgMuted,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: borderColor),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          if (showSignature)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: borderColor),
              ),
              child: pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                children: [
                  if (signatureImage != null)
                    pw.Image(
                      signatureImage,
                      width: 95,
                      height: 36,
                      fit: pw.BoxFit.contain,
                    )
                  else
                    pw.Container(
                      width: 90,
                      height: 22,
                      decoration: const pw.BoxDecoration(
                        border: pw.Border(
                          bottom: pw.BorderSide(color: borderColor),
                        ),
                      ),
                    ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    sigName,
                    style: pw.TextStyle(
                      font: ttfBold,
                      fontSize: 8.5,
                      color: textColor,
                    ),
                  ),
                  if (sigTitle.isNotEmpty)
                    pw.Text(
                      sigTitle,
                      style: const pw.TextStyle(
                        fontSize: 7.5,
                        color: textMuted,
                      ),
                    ),
                ],
              ),
            ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                if (showStamp)
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2.5,
                    ),
                    decoration: pw.BoxDecoration(
                      color: successLight,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(4),
                      ),
                      border: pw.Border.all(color: successColor, width: 0.8),
                    ),
                    child: pw.Text(
                      'مۆر و واژووی دیجیتاڵی فەرمی',
                      style: pw.TextStyle(
                        font: ttfBold,
                        fontSize: 7.5,
                        color: successColor,
                      ),
                    ),
                  ),
                pw.SizedBox(height: 4),
                pw.Text(
                  footerText,
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(fontSize: 7.5, color: textMuted),
                ),
                pw.SizedBox(height: 2),
                pw.Directionality(
                  textDirection: pw.TextDirection.ltr,
                  child: pw.Text(
                    emergencyPhone,
                    style: const pw.TextStyle(fontSize: 7.5, color: textMuted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> previewAndPrint(
    BuildContext context, {
    required Map<String, dynamic> result,
    Map<String, dynamic>? branding,
  }) async {
    final pdf = await generateDocument(result: result, branding: branding);
    final id = result['id'] ?? 'Report';
    await Printing.layoutPdf(
      name: 'DrRoom_LabResult_$id.pdf',
      onLayout: (_) async => pdf.save(),
    );
  }

  static Future<void> shareReport({
    required Map<String, dynamic> result,
    Map<String, dynamic>? branding,
  }) async {
    final pdf = await generateDocument(result: result, branding: branding);
    final bytes = await pdf.save();
    final id = result['id'] ?? 'Report';
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'DrRoom_LabResult_$id.pdf',
    );
  }
}
