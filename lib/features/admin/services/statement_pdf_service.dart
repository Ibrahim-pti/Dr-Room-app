import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart' as intl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Professional Medical & Financial Statement / Invoice PDF Generator for Dr. Room
class StatementPdfService {
  static const PdfColor primaryColor = PdfColor.fromInt(0xFF4F46E5); // Indigo
  static const PdfColor primaryLight = PdfColor.fromInt(0xFFEEF2FF);
  static const PdfColor successColor = PdfColor.fromInt(0xFF059669); // Emerald
  static const PdfColor successLight = PdfColor.fromInt(0xFFECFDF5);
  static const PdfColor warningColor = PdfColor.fromInt(0xFFD97706); // Amber
  static const PdfColor textColor = PdfColor.fromInt(0xFF0F172A); // Slate 900
  static const PdfColor textMuted = PdfColor.fromInt(0xFF64748B); // Slate 500
  static const PdfColor borderColor = PdfColor.fromInt(0xFFE2E8F0); // Slate 200
  static const PdfColor bgMuted = PdfColor.fromInt(0xFFF8FAFC); // Slate 50

  static String _formatIqd(dynamic val) {
    final d = double.tryParse(val?.toString() ?? '0') ?? 0;
    return '${intl.NumberFormat('#,###').format(d)} د.ع';
  }

  /// Build the complete printable PDF document
  static Future<pw.Document> generateDocument(Map<String, dynamic> data) async {
    final pdf = pw.Document();

    // Load Kurdish fonts
    final fontData = await rootBundle.load('fonts/Rabar-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    final boldFontData = await rootBundle.load('fonts/Rabar-Bold.ttf');
    final ttfBold = pw.Font.ttf(boldFontData);

    // Load authentic Dr. Room logo
    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/images/app_icon.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {}

    final provider = (data['provider'] as Map?) ?? {};
    final period = (data['period'] as Map?) ?? {};
    final summary = (data['summary'] as Map?) ?? {};
    final transactions = (data['transactions'] as List?) ?? [];
    final statementNo = data['statement_number']?.toString() ?? 'DR-STMT-2026';
    final generatedAt = data['generated_at']?.toString() ?? '';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(base: ttf, bold: ttfBold),
        build: (pw.Context context) {
          return [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // 1. OFFICIAL HEADER BAR
                  _buildHeader(logoImage, statementNo, generatedAt, ttfBold),
                  pw.SizedBox(height: 14),

                  // 2. PROVIDER & PERIOD CARDS
                  _buildProviderAndPeriod(provider, period),
                  pw.SizedBox(height: 14),

                  // 3. FINANCIAL SUMMARY KPIS
                  _buildSummaryGrid(summary),
                  pw.SizedBox(height: 16),

                  // 4. TRANSACTIONS SECTION TITLE
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'وردەکاری پسوڵە و داواکارییە تۆمارکراوەکان (Transactions Ledger)',
                        style: pw.TextStyle(
                          font: ttfBold,
                          fontSize: 12,
                          color: textColor,
                        ),
                      ),
                      pw.Text(
                        'کۆی داواکاری: ${transactions.length}',
                        style: const pw.TextStyle(fontSize: 10, color: textMuted),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),

                  // 5. TRANSACTIONS TABLE
                  _buildTransactionsTable(transactions, ttfBold),
                  pw.SizedBox(height: 20),

                  // 6. OFFICIAL FOOTER / STAMP & SIGNATURE BLOCK
                  _buildFooterSignatures(ttfBold),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  /// Official Header with Logo and Title
  static pw.Widget _buildHeader(
    pw.MemoryImage? logoImage,
    String statementNo,
    String generatedAt,
    pw.Font ttfBold,
  ) {
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
          // Left Side: Statement Ref & Meta (LTR)
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
                    'OFFICIAL STATEMENT',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  statementNo,
                  style: pw.TextStyle(font: ttfBold, fontSize: 10, color: textColor),
                ),
                pw.Text(
                  'Date: $generatedAt',
                  style: const pw.TextStyle(fontSize: 8.5, color: textMuted),
                ),
              ],
            ),
          ),
          pw.Spacer(),

          // Center: Title & App Name
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'دکتۆر ڕۆم - Dr. Room',
                style: pw.TextStyle(
                  font: ttfBold,
                  fontSize: 16,
                  color: primaryColor,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'پسوڵە و ڕاپۆرتی حیساباتی فەرمی دابینکاران',
                style: const pw.TextStyle(fontSize: 10, color: textMuted),
              ),
              pw.Text(
                'سیستەمی تەندروستی و پزیشکی ماڵەوە',
                style: const pw.TextStyle(fontSize: 8.5, color: textMuted),
              ),
            ],
          ),
          pw.SizedBox(width: 10),

          // Right Side: App Logo
          if (logoImage != null)
            pw.Container(
              width: 44,
              height: 44,
              decoration: pw.BoxDecoration(
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                border: pw.Border.all(color: borderColor),
              ),
              child: pw.ClipRRect(
                horizontalRadius: 8,
                verticalRadius: 8,
                child: pw.Image(logoImage, fit: pw.BoxFit.contain),
              ),
            ),
        ],
      ),
    );
  }

  /// Provider & Period Details Side-by-Side
  static pw.Widget _buildProviderAndPeriod(Map provider, Map period) {
    return pw.Row(
      children: [
        // Provider Details Card
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: borderColor),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'زانیاری دابینکار (Provider Info)',
                  style: const pw.TextStyle(fontSize: 9, color: textMuted),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  provider['name']?.toString() ?? 'دابینکاری گشتی',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: textColor),
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  children: [
                    pw.Text(
                      'پۆلێن: ${provider['role'] ?? 'هاوبەش'}',
                      style: const pw.TextStyle(fontSize: 9, color: textMuted),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Directionality(
                      textDirection: pw.TextDirection.ltr,
                      child: pw.Text(
                        provider['phone']?.toString() ?? '',
                        style: const pw.TextStyle(fontSize: 8.5, color: textMuted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 10),

        // Period & Status Card
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              border: pw.Border.all(color: borderColor),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'ماوەی دارایی و ژمێریاری (Billing Period)',
                  style: const pw.TextStyle(fontSize: 9, color: textMuted),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  '${period['month_name'] ?? 'مانگ'} ${period['year'] ?? ''}',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: textColor),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'ماوە: ${period['start_date'] ?? ''} تا ${period['end_date'] ?? ''}',
                  style: const pw.TextStyle(fontSize: 9, color: textMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 4 KPI Summary Cards
  static pw.Widget _buildSummaryGrid(Map summary) {
    return pw.Row(
      children: [
        // Total Orders
        _buildMetricBox(
          'کۆی داواکارییەکان',
          '${summary['total_orders'] ?? 0} داواکاری',
          primaryColor,
          primaryLight,
        ),
        pw.SizedBox(width: 8),

        // Gross Revenue
        _buildMetricBox(
          'کۆی گشتی داهات',
          _formatIqd(summary['gross_revenue']),
          primaryColor,
          primaryLight,
        ),
        pw.SizedBox(width: 8),

        // Platform Commission
        _buildMetricBox(
          'پشکی دکتۆر ڕۆم (عمولە)',
          _formatIqd(summary['commission_amount']),
          warningColor,
          const PdfColor.fromInt(0xFFFEF3C7),
        ),
        pw.SizedBox(width: 8),

        // Net Payout
        _buildMetricBox(
          'شایستەی دابینکار (صافی)',
          _formatIqd(summary['net_payout']),
          successColor,
          successLight,
          isBoldHighlight: true,
        ),
      ],
    );
  }

  static pw.Widget _buildMetricBox(
    String label,
    String value,
    PdfColor accentColor,
    PdfColor bgColor, {
    bool isBoldHighlight = false,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: accentColor, width: isBoldHighlight ? 1.2 : 0.8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 7.5, color: textMuted)),
            pw.SizedBox(height: 3),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: isBoldHighlight ? 10.5 : 9.5,
                fontWeight: pw.FontWeight.bold,
                color: isBoldHighlight ? successColor : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Detailed Transactions Table
  static pw.Widget _buildTransactionsTable(List transactions, pw.Font ttfBold) {
    if (transactions.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: bgMuted,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: borderColor),
        ),
        child: pw.Center(
          child: pw.Text(
            'هیچ مامەڵەیەک لەم ماوەیەدا بۆ ئەم دابینکارە تۆمارنەکراوە.',
            style: const pw.TextStyle(fontSize: 10, color: textMuted),
          ),
        ),
      );
    }

    final headers = [
      '#',
      'وەسل',
      'بەروار',
      'نەخۆش',
      'خزمەتگوزاری',
      'شێواز',
      'بڕی پارە',
      'عمولە',
      'صافی دابینکار',
    ];

    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FixedColumnWidth(18), // index
        1: pw.FixedColumnWidth(42), // invoice no
        2: pw.FixedColumnWidth(44), // date
        3: pw.FlexColumnWidth(2.2), // patient
        4: pw.FlexColumnWidth(2.8), // service
        5: pw.FixedColumnWidth(34), // method
        6: pw.FlexColumnWidth(1.8), // amount
        7: pw.FlexColumnWidth(1.4), // commission
        8: pw.FlexColumnWidth(1.9), // net payout
      },
      children: [
        // Table Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: primaryColor),
          children: headers.map((h) {
            return pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
              child: pw.Text(
                h,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  font: ttfBold,
                  fontSize: 7.5,
                  color: PdfColors.white,
                ),
              ),
            );
          }).toList(),
        ),

        // Table Rows
        ...transactions.asMap().entries.map((entry) {
          final i = entry.key;
          final t = entry.value as Map;
          final isEven = i % 2 == 0;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.white : bgMuted,
            ),
            children: [
              _cell('${t['index'] ?? i + 1}', align: pw.TextAlign.center, fontSize: 7),
              _cell(t['invoice_no']?.toString() ?? '', align: pw.TextAlign.center, fontSize: 7),
              _cell(t['date']?.toString() ?? '', align: pw.TextAlign.center, fontSize: 7),
              _cell(t['patient_name']?.toString() ?? 'نەخۆش', fontSize: 7.5),
              _cell(t['service']?.toString() ?? 'خزمەتگوزاری', fontSize: 7.5),
              _cell(t['payment_method']?.toString() ?? 'کاش', align: pw.TextAlign.center, fontSize: 7),
              _cell(_formatIqd(t['amount']), align: pw.TextAlign.right, fontSize: 7.5),
              _cell(_formatIqd(t['commission']), align: pw.TextAlign.right, fontSize: 7),
              _cell(
                _formatIqd(t['net_payout']),
                align: pw.TextAlign.right,
                fontSize: 7.5,
                color: successColor,
                isBold: true,
              ),
            ],
          );
        }),
      ],
    );
  }

  static pw.Widget _cell(
    String text, {
    pw.TextAlign align = pw.TextAlign.start,
    double fontSize = 8,
    PdfColor? color,
    bool isBold = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: fontSize,
          color: color ?? textColor,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Official Seal & Signatures
  static pw.Widget _buildFooterSignatures(pw.Font ttfBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: bgMuted,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: borderColor),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // Provider Acceptance
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'ئیمزا و پەسەندکردنی دابینکار',
                style: pw.TextStyle(font: ttfBold, fontSize: 8.5, color: textColor),
              ),
              pw.SizedBox(height: 22),
              pw.Container(width: 120, height: 1, color: borderColor),
              pw.SizedBox(height: 2),
              pw.Text('بەروار: ____ / ____ / ٢٠٢٦', style: const pw.TextStyle(fontSize: 7.5, color: textMuted)),
            ],
          ),

          // Platform Official Seal
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: pw.BoxDecoration(
                  color: successLight,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                  border: pw.Border.all(color: successColor, width: 0.8),
                ),
                child: pw.Text(
                  'مۆری فەرمی ژمێریاری دکتۆر ڕۆم ✓',
                  style: pw.TextStyle(font: ttfBold, fontSize: 8, color: successColor),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'پەسەندکراوە لەلایەن بەشی دارایی Dr. Room',
                style: const pw.TextStyle(fontSize: 7.5, color: textMuted),
              ),
              pw.Text(
                'پەیوەندی فریاکەوتن و دارایی: +964 750 000 0000',
                style: const pw.TextStyle(fontSize: 7.5, color: textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Open Native Preview, Print and Save dialog
  static Future<void> previewAndPrint(
    BuildContext context,
    Map<String, dynamic> statementData,
  ) async {
    final pdf = await generateDocument(statementData);
    final period = statementData['period']?['month_name'] ?? 'Month';
    final providerName = statementData['provider']?['name'] ?? 'Provider';

    await Printing.layoutPdf(
      name: 'DrRoom_Statement_${providerName}_$period.pdf',
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  /// Direct Share via WhatsApp / System Share Sheet
  static Future<void> shareStatement(Map<String, dynamic> statementData) async {
    final pdf = await generateDocument(statementData);
    final bytes = await pdf.save();
    final period = statementData['period']?['month_name'] ?? 'Month';
    final providerName = statementData['provider']?['name'] ?? 'Provider';

    await Printing.sharePdf(
      bytes: bytes,
      filename: 'DrRoom_Statement_${providerName}_$period.pdf',
    );
  }
}
