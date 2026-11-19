import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart' as intl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/services/medical_report_pdf_service.dart';

/// Monthly commission report (app profit vs provider share) as an A4 PDF.
class CommissionPdfService {
  static const _primary = PdfColor.fromInt(0xFF10B981);
  static const _primaryLight = PdfColor.fromInt(0xFFECFDF5);
  static const _indigo = PdfColor.fromInt(0xFF4F46E5);
  static const _blue = PdfColor.fromInt(0xFF2563EB);
  static const _text = PdfColor.fromInt(0xFF0F172A);
  static const _muted = PdfColor.fromInt(0xFF64748B);
  static const _border = PdfColor.fromInt(0xFFE2E8F0);
  static const _bg = PdfColor.fromInt(0xFFF8FAFC);

  static double _num(dynamic v) => double.tryParse(v?.toString() ?? '') ?? 0.0;
  static String _iqd(dynamic v) => '${intl.NumberFormat('#,##0').format(_num(v).round())} د.ع';
  static String _rate(dynamic v) {
    final d = _num(v);
    return d == d.roundToDouble() ? '${d.toInt()}%' : '$d%';
  }

  static String _period(Map data) {
    final m = (data['month'] ?? DateTime.now().month).toString().padLeft(2, '0');
    final y = (data['year'] ?? DateTime.now().year).toString();
    return '$m / $y';
  }

  static String _fileName(Map data) {
    final m = (data['month'] ?? DateTime.now().month).toString().padLeft(2, '0');
    final y = (data['year'] ?? DateTime.now().year).toString();
    return 'DrRoom_Commission_$y-$m.pdf';
  }

  static Future<pw.Document> generate(Map<String, dynamic> data) async {
    final ttf = pw.Font.ttf(await rootBundle.load('fonts/Rabar-Regular.ttf'));
    final ttfBold = pw.Font.ttf(await rootBundle.load('fonts/Rabar-Bold.ttf'));

    final branding = (data['branding'] as Map?) ?? {};
    pw.MemoryImage? logo;
    try {
      final bytes = await rootBundle.load('assets/images/app_icon.png');
      logo = pw.MemoryImage(bytes.buffer.asUint8List());
    } catch (_) {}
    final remoteLogo = await MedicalReportPdfService.downloadImageBytes(branding['logo_url']?.toString());
    if (remoteLogo != null) {
      try {
        logo = pw.MemoryImage(remoteLogo);
      } catch (_) {}
    }

    String brand(String key, String fallback) {
      final v = branding[key]?.toString().trim() ?? '';
      return v.isEmpty ? fallback : v;
    }

    final title = brand('header_title', 'دکتۆر ڕۆم - Dr. Room');
    final footer = brand('footer_text', 'پەسەندکراوە لەلایەن بەشی دارایی Dr. Room');
    final breakdown = (data['breakdown'] as List?) ?? [];
    final revenue = _num(data['total_revenue']);
    final commission = _num(data['total_commission']);
    final payout = _num(data['total_provider_payout']);
    final share = revenue > 0 ? commission / revenue * 100 : 0.0;
    final generatedAt = data['generated_at']?.toString() ??
        intl.DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
        textDirection: pw.TextDirection.rtl,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: _bg,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                border: pw.Border.all(color: _border),
              ),
              child: pw.Row(
                children: [
                  if (logo != null)
                    pw.ClipRRect(
                      horizontalRadius: 8,
                      verticalRadius: 8,
                      child: pw.Image(logo, width: 46, height: 46, fit: pw.BoxFit.cover),
                    ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(title, style: pw.TextStyle(font: ttfBold, fontSize: 15, color: _primary)),
                        pw.SizedBox(height: 2),
                        pw.Text('ڕاپۆرتی کۆمیشنی مانگانە', style: const pw.TextStyle(fontSize: 11, color: _text)),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: const pw.BoxDecoration(
                          color: _primary,
                          borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                        ),
                        child: pw.Text('مانگ: ${_period(data)}',
                            style: pw.TextStyle(font: ttfBold, fontSize: 10, color: PdfColors.white)),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(generatedAt, style: const pw.TextStyle(fontSize: 8.5, color: _muted)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 18),

            // KPIs
            pw.Row(
              children: [
                _kpi('کۆی داهات', _iqd(revenue), '${data['total_orders'] ?? 0} داواکاری', _indigo, ttfBold),
                pw.SizedBox(width: 10),
                _kpi('قازانجی ئەپ (کۆمیشن)', _iqd(commission), '${share.toStringAsFixed(1)}%', _primary, ttfBold),
                pw.SizedBox(width: 10),
                _kpi('پشکی پێشکەشکاران', _iqd(payout), '${(revenue > 0 ? 100 - share : 0).toStringAsFixed(1)}%',
                    _blue, ttfBold),
              ],
            ),
            pw.SizedBox(height: 22),

            pw.Text('پوختە بەپێی بەشەکان', style: pw.TextStyle(font: ttfBold, fontSize: 12, color: _text)),
            pw.SizedBox(height: 8),

            // Table
            pw.Table(
              border: pw.TableBorder.all(color: _border, width: 0.8),
              columnWidths: const {
                0: pw.FlexColumnWidth(2.2),
                1: pw.FlexColumnWidth(1),
                2: pw.FlexColumnWidth(1.2),
                3: pw.FlexColumnWidth(2),
                4: pw.FlexColumnWidth(2),
                5: pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: _primaryLight),
                  children: ['بەش', 'ڕێژە', 'داواکاری', 'کۆی داهات', 'کۆمیشن', 'پشکی پێشکەشکار']
                      .map((h) => _cell(h, bold: ttfBold))
                      .toList(),
                ),
                ...breakdown.map((b) => pw.TableRow(children: [
                      _cell(b['label']?.toString() ?? ''),
                      _cell(_rate(b['rate'])),
                      _cell('${b['total_orders'] ?? 0}'),
                      _cell(_iqd(b['total_amount'])),
                      _cell(_iqd(b['total_commission']), color: _primary),
                      _cell(_iqd(b['provider_net']), color: _blue),
                    ])),
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: _bg),
                  children: [
                    _cell('کۆی گشتی', bold: ttfBold),
                    _cell('-'),
                    _cell('${data['total_orders'] ?? 0}', bold: ttfBold),
                    _cell(_iqd(revenue), bold: ttfBold),
                    _cell(_iqd(commission), bold: ttfBold, color: _primary),
                    _cell(_iqd(payout), bold: ttfBold, color: _blue),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              'تێبینی: تەنها داواکارییە تەواوکراوەکانی پەرستاری ماڵەوە و تاقیگەکان لەم ڕاپۆرتەدا حیساب کراون.',
              style: const pw.TextStyle(fontSize: 9, color: _muted),
            ),
            pw.Spacer(),
            pw.Divider(color: _border),
            pw.Text(footer, style: const pw.TextStyle(fontSize: 8.5, color: _muted)),
          ],
        ),
      ),
    );
    return pdf;
  }

  static pw.Widget _kpi(String label, String value, String caption, PdfColor color, pw.Font bold) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
          border: pw.Border.all(color: _border),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 9, color: _muted)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(font: bold, fontSize: 13, color: color)),
            pw.SizedBox(height: 2),
            pw.Text(caption, style: const pw.TextStyle(fontSize: 8.5, color: _muted)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _cell(String text, {pw.Font? bold, PdfColor color = _text}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(font: bold, fontSize: 9.5, color: color),
      ),
    );
  }

  /// Native preview with print / save-to-files.
  static Future<void> preview(Map<String, dynamic> data) async {
    final pdf = await generate(data);
    await Printing.layoutPdf(name: _fileName(data), onLayout: (_) async => pdf.save());
  }

  /// System share sheet (Save to Files, WhatsApp, …).
  static Future<void> share(Map<String, dynamic> data) async {
    final pdf = await generate(data);
    await Printing.sharePdf(bytes: await pdf.save(), filename: _fileName(data));
  }
}
