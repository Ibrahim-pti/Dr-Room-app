import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart' as intl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../core/services/medical_report_pdf_service.dart';

/// Official Executive Monthly Analytics & Accounting PDF Generator for Dr. Room Admin.
class AnalyticsPdfService {
  static const PdfColor primaryColor = PdfColor.fromInt(0xFF7C3AED); // Violet
  static const PdfColor primaryLight = PdfColor.fromInt(0xFFF5F3FF);
  static const PdfColor indigoColor = PdfColor.fromInt(0xFF2563EB);
  static const PdfColor indigoLight = PdfColor.fromInt(0xFFEFF6FF);
  static const PdfColor successColor = PdfColor.fromInt(0xFF059669);
  static const PdfColor successLight = PdfColor.fromInt(0xFFECFDF5);
  static const PdfColor warningColor = PdfColor.fromInt(0xFFD97706);
  static const PdfColor warningLight = PdfColor.fromInt(0xFFFFFBEB);
  static const PdfColor dangerColor = PdfColor.fromInt(0xFFDC2626);
  static const PdfColor dangerLight = PdfColor.fromInt(0xFFFEF2F2);
  static const PdfColor textColor = PdfColor.fromInt(0xFF0F172A);
  static const PdfColor textMuted = PdfColor.fromInt(0xFF64748B);
  static const PdfColor borderColor = PdfColor.fromInt(0xFFE2E8F0);
  static const PdfColor bgMuted = PdfColor.fromInt(0xFFF8FAFC);

  static String _formatIqd(dynamic val) {
    final d = double.tryParse(val?.toString() ?? '0') ?? 0;
    return '${intl.NumberFormat('#,###').format(d)} د.ع';
  }

  static String _formatNum(dynamic val) {
    final d = num.tryParse(val?.toString() ?? '0') ?? 0;
    return intl.NumberFormat('#,###').format(d);
  }

  static String _serviceFilterLabel(String key) {
    return switch (key) {
      'lab' => 'پشکنینی تاقیگە',
      'nursing' => 'پەرستاری ماڵەوە',
      'pharmacy' => 'دەرمانخانە',
      _ => 'هەموو خزمەتگوزارییەکان',
    };
  }

  static String _periodLabel(String month) {
    if (month == 'all') return 'هەموو کاتەکان';
    return month;
  }

  static String _statusLabel(String status) {
    return switch (status.toLowerCase()) {
      'completed' => 'تەواوکراو',
      'pending' => 'چاوەڕوان',
      'accepted' => 'قبوڵکراو',
      'confirmed' => 'پەسەندکراو',
      'processing' || 'in_progress' => 'لە کاردایە',
      'on_the_way' => 'لە ڕێگادایە',
      'cancelled' || 'rejected' => 'هەڵوەشاوە',
      _ => status,
    };
  }

  static Future<pw.Document> generateDocument(Map<String, dynamic> report) async {
    final pdf = pw.Document();

    final fontData = await rootBundle.load('fonts/Rabar-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    final boldFontData = await rootBundle.load('fonts/Rabar-Bold.ttf');
    final ttfBold = pw.Font.ttf(boldFontData);

    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/images/app_icon.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {}

    final branding = (report['branding'] as Map?) ?? {};
    final remoteLogoBytes = await MedicalReportPdfService.downloadImageBytes(
      branding['logo_url']?.toString(),
    );
    if (remoteLogoBytes != null) {
      try {
        logoImage = pw.MemoryImage(remoteLogoBytes);
      } catch (_) {}
    }
    pw.MemoryImage? signatureImage;
    final remoteSigBytes = await MedicalReportPdfService.downloadImageBytes(
      branding['signature_url']?.toString(),
    );
    if (remoteSigBytes != null) {
      try {
        signatureImage = pw.MemoryImage(remoteSigBytes);
      } catch (_) {}
    }

    final summary = (report['summary'] as Map?) ?? {};
    final overall = (report['overall'] as Map?) ?? {};
    final ecosystem = (report['ecosystem'] as Map?) ?? {};
    final serviceBreakdown = (report['service_breakdown'] as List?) ?? [];
    final monthlyRows = (report['monthly_rows'] as List?) ?? [];
    final topItems = (report['top_items'] as List?) ?? [];
    final topLabs = (report['top_labs'] as List?) ?? [];
    final topNurses = (report['top_nurses'] as List?) ?? [];
    final ledgerOrders = (report['ledger_orders'] as List?) ?? [];

    final selectedMonth = (report['selected_month'] ?? 'all').toString();
    final serviceType = (report['service_type'] ?? 'all').toString();
    final generatedAt = (report['generated_at'] ?? '').toString();
    final reportCode =
        'DR-RPT-${selectedMonth == 'all' ? 'ALL' : selectedMonth.replaceAll('-', '')}';

    final headerTitle =
        (branding['header_title']?.toString().trim().isNotEmpty ?? false)
            ? branding['header_title'].toString().trim()
            : 'دکتۆر ڕۆم - Dr. Room';
    final headerSubtitle =
        (branding['header_subtitle']?.toString().trim().isNotEmpty ?? false)
            ? branding['header_subtitle'].toString().trim()
            : 'سیستەمی تەندروستی و پزیشکی ماڵەوە';
    final footerText =
        (branding['footer_text']?.toString().trim().isNotEmpty ?? false)
            ? branding['footer_text'].toString().trim()
            : 'پەسەندکراوە لەلایەن بەڕێوەبەرایەتی Dr. Room';
    final emergencyPhone =
        (branding['emergency_phone']?.toString().trim().isNotEmpty ?? false)
            ? branding['emergency_phone'].toString().trim()
            : '+964 750 000 0000';
    final showStamp = branding['show_stamp'] != false;
    final showSignature = branding['show_signature'] != false;
    final signatureName =
        (branding['signature_name']?.toString().trim().isNotEmpty ?? false)
            ? branding['signature_name'].toString().trim()
            : 'بەڕێوەبەری پزیشکی و تاقیگە';
    final signatureTitle =
        (branding['signature_title']?.toString().trim().isNotEmpty ?? false)
            ? branding['signature_title'].toString().trim()
            : 'واژووی فەرمی پەسەندکردن';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(22),
        theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
        build: (pw.Context context) {
          return [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // 1. Official Header
                  _buildHeader(
                    logoImage: logoImage,
                    ttfBold: ttfBold,
                    headerTitle: headerTitle,
                    headerSubtitle: headerSubtitle,
                    reportCode: reportCode,
                    generatedAt: generatedAt,
                    periodText: _periodLabel(selectedMonth),
                    filterText: _serviceFilterLabel(serviceType),
                  ),
                  pw.SizedBox(height: 12),

                  // 2. Primary 4 KPI Cards
                  _buildPrimaryKpis(summary, overall, ecosystem, ttfBold),
                  pw.SizedBox(height: 10),

                  // 3. Financial & Payment Strip
                  _buildFinancialStrip(summary, ttfBold),
                  pw.SizedBox(height: 14),

                  // 4. System Ecosystem & Sector Breakdown
                  if (serviceBreakdown.isNotEmpty) ...[
                    _sectionHeading('دابەشبوونی کەرتەکان و دۆخی سیستەم', ttfBold),
                    pw.SizedBox(height: 6),
                    _buildSectorAndEcosystem(serviceBreakdown, ecosystem, ttfBold),
                    pw.SizedBox(height: 14),
                  ],

                  // 5. Monthly Breakdown Table
                  if (monthlyRows.isNotEmpty) ...[
                    _sectionHeading('خشتەی ڕاپۆرتی مانگانە (بەراوردی مانگەکان)', ttfBold),
                    pw.SizedBox(height: 6),
                    _buildMonthlyTable(monthlyRows.take(12).toList(), ttfBold),
                    pw.SizedBox(height: 14),
                  ],

                  // 6. Top Requested Services & Providers
                  if (topItems.isNotEmpty) ...[
                    _sectionHeading('زۆرترین پشکنین و خزمەتگوزاری داواکراو', ttfBold),
                    pw.SizedBox(height: 6),
                    _buildTopItemsTable(topItems, ttfBold),
                    pw.SizedBox(height: 14),
                  ],

                  if (topLabs.isNotEmpty || topNurses.isNotEmpty) ...[
                    _sectionHeading('باشترین تاقیگە و پەرستارەکانی ماوەکە', ttfBold),
                    pw.SizedBox(height: 6),
                    _buildTopProvidersRow(topLabs, topNurses, ttfBold),
                    pw.SizedBox(height: 14),
                  ],

                  // 7. Period Orders Ledger (up to 30 recent orders for clean A4 length)
                  if (ledgerOrders.isNotEmpty) ...[
                    _sectionHeading(
                      'تۆماری داواکارییەکانی ماوەکە (${ledgerOrders.length > 30 ? '٣٠ نوێترین لە کۆی ${ledgerOrders.length}' : '${ledgerOrders.length} داواکاری'})',
                      ttfBold,
                    ),
                    pw.SizedBox(height: 6),
                    _buildOrdersTable(ledgerOrders.take(30).toList(), ttfBold),
                    pw.SizedBox(height: 16),
                  ],

                  // 8. Official Footer & Stamp
                  _buildFooter(
                    ttfBold: ttfBold,
                    footerText: footerText,
                    emergencyPhone: emergencyPhone,
                    showStamp: showStamp,
                    showSignature: showSignature,
                    signatureImage: signatureImage,
                    signatureName: signatureName,
                    signatureTitle: signatureTitle,
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _sectionHeading(String title, pw.Font ttfBold) {
    return pw.Row(
      children: [
        pw.Container(
          width: 4,
          height: 13,
          decoration: const pw.BoxDecoration(
            color: primaryColor,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
          ),
        ),
        pw.SizedBox(width: 6),
        pw.Text(
          title,
          style: pw.TextStyle(font: ttfBold, fontSize: 11, color: textColor),
        ),
      ],
    );
  }

  static pw.Widget _buildHeader({
    required pw.MemoryImage? logoImage,
    required pw.Font ttfBold,
    required String headerTitle,
    required String headerSubtitle,
    required String reportCode,
    required String generatedAt,
    required String periodText,
    required String filterText,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: bgMuted,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: borderColor, width: 1),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Directionality(
            textDirection: pw.TextDirection.ltr,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: const pw.BoxDecoration(
                    color: primaryColor,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    'MONTHLY SYSTEM REPORT',
                    style: pw.TextStyle(
                      fontSize: 7.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  reportCode,
                  style: pw.TextStyle(font: ttfBold, fontSize: 9.5, color: textColor),
                ),
                pw.Text(
                  'Generated: $generatedAt',
                  style: const pw.TextStyle(fontSize: 8, color: textMuted),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  headerTitle,
                  style: pw.TextStyle(font: ttfBold, fontSize: 13.5, color: primaryColor),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'ڕاپۆرتی گشتی ئامار، داهات و چالاکییەکانی سیستەم',
                  style: pw.TextStyle(font: ttfBold, fontSize: 9.5, color: textColor),
                ),
                pw.Text(
                  '$headerSubtitle  |  ماوە: $periodText  |  فلتەر: $filterText',
                  style: const pw.TextStyle(fontSize: 8, color: textMuted),
                ),
              ],
            ),
          ),
          if (logoImage != null) ...[
            pw.SizedBox(width: 10),
            pw.Container(
              width: 42,
              height: 42,
              decoration: pw.BoxDecoration(
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
        ],
      ),
    );
  }

  static pw.Widget _buildPrimaryKpis(
    Map summary,
    Map overall,
    Map ecosystem,
    pw.Font ttfBold,
  ) {
    return pw.Row(
      children: [
        _kpiCard(
          'کۆی گشتی داهات',
          _formatIqd(summary['gross_revenue']),
          'کۆمیشن: ${_formatIqd(summary['commission_total'])}',
          primaryColor,
          primaryLight,
          ttfBold,
        ),
        pw.SizedBox(width: 8),
        _kpiCard(
          'داواکارییەکان',
          '${_formatNum(summary['completed_orders'])} / ${_formatNum(summary['total_orders'])}',
          'تەواوبوون: ${summary['completion_rate'] ?? 0}%',
          indigoColor,
          indigoLight,
          ttfBold,
        ),
        pw.SizedBox(width: 8),
        _kpiCard(
          'پشکنین و خزمەتگوزاری',
          _formatNum(summary['items_performed']),
          'هەموو کات: ${_formatNum(overall['items_performed'])}',
          successColor,
          successLight,
          ttfBold,
        ),
        pw.SizedBox(width: 8),
        _kpiCard(
          'نەخۆشە چالاکەکان',
          _formatNum(summary['unique_patients']),
          'تۆمارکراو: ${_formatNum(ecosystem['total_patients'])} | نوێ: ${_formatNum(summary['new_users'])}',
          warningColor,
          warningLight,
          ttfBold,
        ),
      ],
    );
  }

  static pw.Widget _kpiCard(
    String label,
    String value,
    String sub,
    PdfColor color,
    PdfColor bg,
    pw.Font ttfBold,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(9),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: color, width: 0.6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: textMuted)),
            pw.SizedBox(height: 3),
            pw.Text(
              value,
              style: pw.TextStyle(font: ttfBold, fontSize: 11, color: color),
            ),
            pw.SizedBox(height: 2),
            pw.Text(sub, style: const pw.TextStyle(fontSize: 7, color: textMuted)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildFinancialStrip(Map summary, pw.Font ttfBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: borderColor),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _miniStat('داهاتی کاش', _formatIqd(summary['cash_revenue']), successColor, ttfBold),
          _miniStat('داهاتی ئۆنلاین', _formatIqd(summary['online_revenue']), indigoColor, ttfBold),
          _miniStat('خەرجییەکان', _formatIqd(summary['expenses_total']), dangerColor, ttfBold),
          _miniStat('داشکاندنەکان', _formatIqd(summary['discount_total']), warningColor, ttfBold),
          _miniStat('قازانجی پوختی سەکۆ', _formatIqd(summary['net_profit']), primaryColor, ttfBold),
        ],
      ),
    );
  }

  static pw.Widget _miniStat(
    String label,
    String value,
    PdfColor color,
    pw.Font ttfBold,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 7.5, color: textMuted)),
        pw.SizedBox(height: 2),
        pw.Text(value, style: pw.TextStyle(font: ttfBold, fontSize: 9, color: color)),
      ],
    );
  }

  static pw.Widget _buildSectorAndEcosystem(
    List serviceBreakdown,
    Map ecosystem,
    pw.Font ttfBold,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 3,
          child: pw.Table(
            border: pw.TableBorder.all(color: borderColor, width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: bgMuted),
                children: [
                  _cell('کەرت', ttfBold, bold: true),
                  _cell('داواکاری', ttfBold, bold: true),
                  _cell('تەواوکراو', ttfBold, bold: true),
                  _cell('داهات', ttfBold, bold: true),
                ],
              ),
              ...serviceBreakdown.map((s) {
                return pw.TableRow(
                  children: [
                    _cell((s['label'] ?? '').toString(), ttfBold),
                    _cell(_formatNum(s['orders_count']), ttfBold),
                    _cell(_formatNum(s['completed_count']), ttfBold, color: successColor),
                    _cell(_formatIqd(s['revenue']), ttfBold, bold: true),
                  ],
                );
              }),
            ],
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          flex: 2,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: bgMuted,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: borderColor, width: 0.6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('پێکهاتەی سیستەم', style: pw.TextStyle(font: ttfBold, fontSize: 9, color: textColor)),
                pw.SizedBox(height: 4),
                _ecoLine('تاقیگە پەسەندکراوەکان', '${ecosystem['total_labs'] ?? 0}'),
                _ecoLine('پەرستارەکان', '${ecosystem['total_nurses'] ?? 0}'),
                _ecoLine('کارمەندانی گەیاندن', '${ecosystem['total_drivers'] ?? 0} (${ecosystem['online_drivers'] ?? 0} لە هێڵ)'),
                _ecoLine('نەخۆشە تۆمارکراوەکان', '${ecosystem['total_patients'] ?? 0}'),
                _ecoLine('ئەنجامی تاقیگەیی', '${ecosystem['total_lab_results'] ?? 0}'),
                _ecoLine('تیکێتی کراوە', '${ecosystem['open_tickets'] ?? 0}'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _ecoLine(String label, String val) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: textMuted)),
          pw.Text(val, style: const pw.TextStyle(fontSize: 8, color: textColor)),
        ],
      ),
    );
  }

  static pw.Widget _buildMonthlyTable(List rows, pw.Font ttfBold) {
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: bgMuted),
          children: [
            _cell('مانگ', ttfBold, bold: true),
            _cell('کۆی داواکاری', ttfBold, bold: true),
            _cell('تەواوکراو', ttfBold, bold: true),
            _cell('خزمەتگوزاری', ttfBold, bold: true),
            _cell('نەخۆش', ttfBold, bold: true),
            _cell('کۆی داهات', ttfBold, bold: true),
            _cell('کۆمیشن', ttfBold, bold: true),
            _cell('خەرجی', ttfBold, bold: true),
          ],
        ),
        ...rows.map((r) {
          return pw.TableRow(
            children: [
              _cell((r['month'] ?? '').toString(), ttfBold, bold: true),
              _cell(_formatNum(r['total_orders']), ttfBold),
              _cell(_formatNum(r['completed_orders']), ttfBold, color: successColor),
              _cell(_formatNum(r['items_performed']), ttfBold),
              _cell(_formatNum(r['unique_patients']), ttfBold),
              _cell(_formatIqd(r['gross_revenue']), ttfBold, bold: true),
              _cell(_formatIqd(r['commission_total']), ttfBold, color: primaryColor),
              _cell(_formatIqd(r['expenses_total']), ttfBold, color: dangerColor),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTopItemsTable(List items, pw.Font ttfBold) {
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: bgMuted),
          children: [
            _cell('#', ttfBold, bold: true),
            _cell('ناوی پشکنین / خزمەتگوزاری', ttfBold, bold: true),
            _cell('کەرت', ttfBold, bold: true),
            _cell('ژمارەی داواکاری', ttfBold, bold: true),
            _cell('کۆی داهات', ttfBold, bold: true),
          ],
        ),
        ...items.asMap().entries.map((entry) {
          final i = entry.key;
          final it = entry.value;
          return pw.TableRow(
            children: [
              _cell('${i + 1}', ttfBold),
              _cell((it['name'] ?? '').toString(), ttfBold, bold: true),
              _cell(_serviceFilterLabel((it['service_type'] ?? 'all').toString()), ttfBold),
              _cell('${_formatNum(it['count'])}×', ttfBold, color: primaryColor),
              _cell(_formatIqd(it['revenue']), ttfBold, bold: true),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _buildTopProvidersRow(
    List topLabs,
    List topNurses,
    pw.Font ttfBold,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: borderColor, width: 0.6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('باشترین تاقیگەکان', style: pw.TextStyle(font: ttfBold, fontSize: 9, color: indigoColor)),
                pw.SizedBox(height: 4),
                if (topLabs.isEmpty)
                  pw.Text('هیچ داتایەک نییە', style: const pw.TextStyle(fontSize: 8, color: textMuted))
                else
                  ...topLabs.map((l) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Expanded(
                              child: pw.Text(
                                '${l['name']} (${l['orders_count']} داواکاری)',
                                style: const pw.TextStyle(fontSize: 8, color: textColor),
                              ),
                            ),
                            pw.Text(_formatIqd(l['revenue']), style: pw.TextStyle(font: ttfBold, fontSize: 8, color: indigoColor)),
                          ],
                        ),
                      )),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
              border: pw.Border.all(color: borderColor, width: 0.6),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('باشترین پەرستارەکان', style: pw.TextStyle(font: ttfBold, fontSize: 9, color: successColor)),
                pw.SizedBox(height: 4),
                if (topNurses.isEmpty)
                  pw.Text('هیچ داتایەک نییە', style: const pw.TextStyle(fontSize: 8, color: textMuted))
                else
                  ...topNurses.map((n) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Expanded(
                              child: pw.Text(
                                '${n['name']} (${n['orders_count']} داواکاری)',
                                style: const pw.TextStyle(fontSize: 8, color: textColor),
                              ),
                            ),
                            pw.Text(_formatIqd(n['revenue']), style: pw.TextStyle(font: ttfBold, fontSize: 8, color: successColor)),
                          ],
                        ),
                      )),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildOrdersTable(List orders, pw.Font ttfBold) {
    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: bgMuted),
          children: [
            _cell('#', ttfBold, bold: true),
            _cell('نەخۆش', ttfBold, bold: true),
            _cell('دابینکار', ttfBold, bold: true),
            _cell('خزمەتگوزاری', ttfBold, bold: true),
            _cell('بەروار', ttfBold, bold: true),
            _cell('دۆخ', ttfBold, bold: true),
            _cell('بڕی پارە', ttfBold, bold: true),
          ],
        ),
        ...orders.map((o) {
          final status = (o['status'] ?? '').toString();
          final sColor = status == 'completed'
              ? successColor
              : (status == 'cancelled' || status == 'rejected'
                  ? dangerColor
                  : warningColor);
          return pw.TableRow(
            children: [
              _cell((o['order_number'] ?? '#${o['id']}').toString(), ttfBold),
              _cell((o['patient_name'] ?? 'نەخۆش').toString(), ttfBold),
              _cell((o['provider_name'] ?? '-').toString(), ttfBold),
              _cell((o['items_summary'] ?? '').toString(), ttfBold),
              _cell((o['date'] ?? '').toString(), ttfBold),
              _cell(_statusLabel(status), ttfBold, color: sColor),
              _cell(_formatIqd(o['total_price']), ttfBold, bold: true),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _cell(
    String text,
    pw.Font ttfBold, {
    bool bold = false,
    PdfColor color = textColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: bold ? ttfBold : null,
          fontSize: 7.5,
          color: color,
        ),
      ),
    );
  }

  static pw.Widget _buildFooter({
    required pw.Font ttfBold,
    required String footerText,
    required String emergencyPhone,
    required bool showStamp,
    required bool showSignature,
    required pw.MemoryImage? signatureImage,
    required String signatureName,
    required String signatureTitle,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: bgMuted,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: borderColor),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(footerText, style: pw.TextStyle(font: ttfBold, fontSize: 8.5, color: textColor)),
                pw.SizedBox(height: 2),
                pw.Text('پەیوەندی بەڕێوەبەرایەتی: $emergencyPhone', style: const pw.TextStyle(fontSize: 7.5, color: textMuted)),
              ],
            ),
          ),
          if (showSignature) ...[
            pw.SizedBox(width: 10),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: borderColor),
              ),
              child: pw.Column(
                children: [
                  if (signatureImage != null)
                    pw.Image(signatureImage, width: 80, height: 30, fit: pw.BoxFit.contain),
                  pw.Text(signatureName, style: pw.TextStyle(font: ttfBold, fontSize: 7.5, color: textColor)),
                  if (signatureTitle.isNotEmpty)
                    pw.Text(signatureTitle, style: const pw.TextStyle(fontSize: 6.8, color: textMuted)),
                ],
              ),
            ),
          ],
          if (showStamp) ...[
            pw.SizedBox(width: 8),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: pw.BoxDecoration(
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: primaryColor, width: 1.2),
              ),
              child: pw.Text(
                'پەسەندکراو • Dr. Room',
                style: pw.TextStyle(font: ttfBold, fontSize: 8, color: primaryColor),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Future<void> previewAndPrint(
    BuildContext context,
    Map<String, dynamic> report,
  ) async {
    final pdf = await generateDocument(report);
    final period = (report['selected_month'] ?? 'All').toString();
    await Printing.layoutPdf(
      name: 'DrRoom_Analytics_$period.pdf',
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static Future<void> sharePdf(Map<String, dynamic> report) async {
    final pdf = await generateDocument(report);
    final bytes = await pdf.save();
    final period = (report['selected_month'] ?? 'All').toString();
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'DrRoom_Analytics_$period.pdf',
    );
  }
}
