import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart' as intl;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Monthly & Lifetime Earnings + Cash Collection PDF Report for Delivery Drivers
class DriverEarningsPdfService {
  static const PdfColor primaryColor = PdfColor.fromInt(0xFF2563EB);
  static const PdfColor primaryLight = PdfColor.fromInt(0xFFEFF6FF);
  static const PdfColor successColor = PdfColor.fromInt(0xFF059669);
  static const PdfColor successLight = PdfColor.fromInt(0xFFECFDF5);
  static const PdfColor warningColor = PdfColor.fromInt(0xFFD97706);
  static const PdfColor warningLight = PdfColor.fromInt(0xFFFEF3C7);
  static const PdfColor textColor = PdfColor.fromInt(0xFF0F172A);
  static const PdfColor textMuted = PdfColor.fromInt(0xFF64748B);
  static const PdfColor borderColor = PdfColor.fromInt(0xFFE2E8F0);
  static const PdfColor bgMuted = PdfColor.fromInt(0xFFF8FAFC);

  static String _formatIqd(dynamic val) {
    final d = double.tryParse(val?.toString() ?? '0') ?? 0;
    return '${intl.NumberFormat('#,###').format(d)} د.ع';
  }

  static bool _isCashOrder(dynamic o) {
    if (o is Map && o['is_cash'] != null) {
      return o['is_cash'] == true;
    }
    final m = (o?['payment_method'] ?? '').toString().trim().toLowerCase();
    return m.isEmpty || m.contains('cash') || m.contains('کاش');
  }

  static String _patientName(dynamic o) {
    if (o is! Map) return 'نەخۆش';
    if ((o['patient_name'] ?? '').toString().trim().isNotEmpty) {
      return o['patient_name'].toString().trim();
    }
    final p = o['patient'];
    if (p is Map && (p['name'] ?? '').toString().trim().isNotEmpty) {
      return p['name'].toString().trim();
    }
    return 'نەخۆش';
  }

  static String _deliveredDateStr(dynamic o) {
    if (o is! Map) return '-';
    final disp = (o['delivered_at_display'] ?? o['delivered_at'] ?? '')
        .toString()
        .trim();
    if (disp.isNotEmpty) return disp;
    final raw = (o['driver_delivered_at'] ?? o['created_at'] ?? '')
        .toString()
        .trim();
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt != null) {
      return intl.DateFormat('yyyy-MM-dd HH:mm').format(dt);
    }
    return '-';
  }

  static String _roleLabel(String? role) {
    switch ((role ?? '').trim()) {
      case 'doctor':
        return 'پزیشکی گەڕۆک';
      case 'nurse':
        return 'پەرستار';
      case 'phlebotomist':
        return 'وەرگرتنی خوێن و تاقیگە';
      case 'delivery_courier':
        return 'کارمەندی گەیاندنی دەرمان';
      default:
        return 'کارمەندی گەیاندن (دلیڤەری)';
    }
  }

  static Future<pw.Document> generateDocument({
    required Map<String, dynamic> driver,
    required Map<String, dynamic> finance,
    required List<dynamic> orders,
  }) async {
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

    final period = finance['period_summary'] is Map
        ? Map<String, dynamic>.from(finance['period_summary'])
        : <String, dynamic>{};

    final periodLabel = (period['label'] ??
            finance['selected_month_label'] ??
            'هەموو مانگەکان')
        .toString();
    final periodCode = (period['month'] ?? finance['selected_month'] ?? 'all')
        .toString();

    final deliveries =
        int.tryParse(
          '${period['deliveries'] ?? finance['total_deliveries'] ?? orders.length}',
        ) ??
        orders.length;
    final earnings =
        double.tryParse(
          '${period['earnings'] ?? finance['total_earnings'] ?? 0}',
        ) ??
        0;
    final cashCount =
        int.tryParse(
          '${period['cash_count'] ?? finance['cash_all_time_count'] ?? 0}',
        ) ??
        0;
    final cashCollected =
        double.tryParse(
          '${period['cash_collected'] ?? finance['lifetime_cash_collected'] ?? 0}',
        ) ??
        0;
    final cashFee =
        double.tryParse(
          '${period['cash_delivery_fee'] ?? finance['cash_total_delivery_fee'] ?? 0}',
        ) ??
        0;
    final onlineCount =
        int.tryParse(
          '${period['online_count'] ?? finance['online_total_count'] ?? 0}',
        ) ??
        0;
    final onlineFee =
        double.tryParse(
          '${period['online_delivery_fee'] ?? finance['online_total_delivery_fee'] ?? 0}',
        ) ??
        0;
    final labCount = int.tryParse('${period['lab_count'] ?? 0}') ?? 0;
    final pharmacyCount =
        int.tryParse('${period['pharmacy_count'] ?? 0}') ?? 0;

    final unsettledCash =
        double.tryParse('${finance['cash_total_collected'] ?? 0}') ?? 0;
    final unsettledCount =
        int.tryParse('${finance['cash_total_count'] ?? 0}') ?? 0;

    final resetAtRaw = finance['earnings_reset_at']?.toString();
    final resetAt = resetAtRaw != null
        ? DateTime.tryParse(resetAtRaw)?.toLocal()
        : null;
    final resetText = resetAt != null
        ? intl.DateFormat('yyyy-MM-dd HH:mm').format(resetAt)
        : 'هێشتا سفر نەکراوەتەوە';

    final nowStr = intl.DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final reportNo =
        'DR-DRV-${driver['id'] ?? driver['user_id'] ?? '0'}-${periodCode.toUpperCase()}';

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
                  _buildHeader(logoImage, reportNo, nowStr, ttfBold),
                  pw.SizedBox(height: 12),
                  _buildDriverAndPeriod(driver, periodLabel, resetText, ttfBold),
                  pw.SizedBox(height: 12),
                  _buildKpis(
                    deliveries: deliveries,
                    labCount: labCount,
                    pharmacyCount: pharmacyCount,
                    earnings: earnings,
                    cashCount: cashCount,
                    cashCollected: cashCollected,
                    cashFee: cashFee,
                    unsettledCash: unsettledCash,
                    unsettledCount: unsettledCount,
                    ttfBold: ttfBold,
                  ),
                  pw.SizedBox(height: 8),
                  _buildSubStrip(
                    cashCount: cashCount,
                    cashFee: cashFee,
                    onlineCount: onlineCount,
                    onlineFee: onlineFee,
                  ),
                  pw.SizedBox(height: 14),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'وردەکاری گەیاندن و کرێکان',
                        style: pw.TextStyle(
                          font: ttfBold,
                          fontSize: 11.5,
                          color: textColor,
                        ),
                      ),
                      pw.Text(
                        'ژمارەی تۆمارەکان: ${orders.length}',
                        style: const pw.TextStyle(
                          fontSize: 9.5,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 6),
                  _buildOrdersTable(orders, ttfBold),
                  pw.SizedBox(height: 18),
                  _buildFooter(ttfBold),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  static pw.Widget _buildHeader(
    pw.MemoryImage? logoImage,
    String reportNo,
    String generatedAt,
    pw.Font ttfBold,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: bgMuted,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: borderColor),
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
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: const pw.BoxDecoration(
                    color: primaryColor,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Text(
                    'DRIVER REPORT',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  reportNo,
                  style: pw.TextStyle(
                    font: ttfBold,
                    fontSize: 9.5,
                    color: textColor,
                  ),
                ),
                pw.Text(
                  'Date: $generatedAt',
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
                  'دکتۆر ڕۆم - Dr. Room',
                  style: pw.TextStyle(
                    font: ttfBold,
                    fontSize: 13.5,
                    color: primaryColor,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'ڕاپۆرتی مانگانەی داهات و پارەی کاشی کارمەندی گەیاندن',
                  style: const pw.TextStyle(fontSize: 9.5, color: textColor),
                ),
                pw.Text(
                  'پوختەی گەیاندنەکان، کرێی هەر کارێک و بڕی پارەی کاشی وەرگیراو',
                  style: const pw.TextStyle(fontSize: 8, color: textMuted),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          if (logoImage != null)
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
      ),
    );
  }

  static pw.Widget _buildDriverAndPeriod(
    Map<String, dynamic> driver,
    String periodLabel,
    String resetText,
    pw.Font ttfBold,
  ) {
    return pw.Row(
      children: [
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
                  'زانیاری کارمەندی گەیاندن',
                  style: const pw.TextStyle(fontSize: 8.5, color: textMuted),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  (driver['name'] ?? 'کارمەندی گەیاندن').toString(),
                  style: pw.TextStyle(
                    font: ttfBold,
                    fontSize: 11.5,
                    color: textColor,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '${_roleLabel(driver['applicant_role']?.toString())} · ${driver['city'] ?? 'هەولێر'}',
                  style: const pw.TextStyle(fontSize: 8.5, color: textMuted),
                ),
                if ((driver['phone'] ?? '').toString().trim().isNotEmpty)
                  pw.Directionality(
                    textDirection: pw.TextDirection.ltr,
                    child: pw.Text(
                      driver['phone'].toString(),
                      style: const pw.TextStyle(fontSize: 8.5, color: textMuted),
                    ),
                  ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 10),
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
                  'ماوەی هەڵبژێردراو و دۆخی کاش',
                  style: const pw.TextStyle(fontSize: 8.5, color: textMuted),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  periodLabel,
                  style: pw.TextStyle(
                    font: ttfBold,
                    fontSize: 11.5,
                    color: primaryColor,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  'دواین سفرکردنەوەی کاش: $resetText',
                  style: const pw.TextStyle(fontSize: 8, color: textMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildKpis({
    required int deliveries,
    required int labCount,
    required int pharmacyCount,
    required double earnings,
    required int cashCount,
    required double cashCollected,
    required double cashFee,
    required double unsettledCash,
    required int unsettledCount,
    required pw.Font ttfBold,
  }) {
    return pw.Row(
      children: [
        _metricBox(
          'ژمارەی کارەکان',
          '$deliveries گەیاندن',
          'تاقیگە: $labCount · دەرمان: $pharmacyCount',
          primaryColor,
          primaryLight,
          ttfBold,
        ),
        pw.SizedBox(width: 8),
        _metricBox(
          'کۆی داهاتی کرێ',
          _formatIqd(earnings),
          'داهاتی پارێزراوی گەیاندن',
          primaryColor,
          primaryLight,
          ttfBold,
        ),
        pw.SizedBox(width: 8),
        _metricBox(
          'کاشی وەرگیراوی ماوە',
          _formatIqd(cashCollected),
          '$cashCount داواکاری · کرێ: ${_formatIqd(cashFee)}',
          successColor,
          successLight,
          ttfBold,
        ),
        pw.SizedBox(width: 8),
        _metricBox(
          'کاشی چاوەڕوانی پاکتاو',
          _formatIqd(unsettledCash),
          '$unsettledCount داواکاری سفرنەکراو',
          warningColor,
          warningLight,
          ttfBold,
        ),
      ],
    );
  }

  static pw.Widget _metricBox(
    String label,
    String value,
    String sub,
    PdfColor accent,
    PdfColor bg,
    pw.Font ttfBold,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: accent, width: 0.8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 7.5, color: textMuted)),
            pw.SizedBox(height: 3),
            pw.Text(
              value,
              style: pw.TextStyle(
                font: ttfBold,
                fontSize: 10,
                color: textColor,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(sub, style: const pw.TextStyle(fontSize: 6.8, color: textMuted)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildSubStrip({
    required int cashCount,
    required double cashFee,
    required int onlineCount,
    required double onlineFee,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: pw.BoxDecoration(
        color: bgMuted,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: borderColor),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'کارە کاشەکان: $cashCount کار (کرێ: ${_formatIqd(cashFee)})',
            style: const pw.TextStyle(fontSize: 8.5, color: textColor),
          ),
          pw.Text(
            'کارە ئۆنلاینەکان: $onlineCount کار (کرێ: ${_formatIqd(onlineFee)})',
            style: const pw.TextStyle(fontSize: 8.5, color: textColor),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildOrdersTable(List<dynamic> orders, pw.Font ttfBold) {
    if (orders.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: bgMuted,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          border: pw.Border.all(color: borderColor),
        ),
        child: pw.Center(
          child: pw.Text(
            'هیچ گەیاندنێکی تەواوبوو لەم ماوەیەدا تۆمارنەکراوە.',
            style: const pw.TextStyle(fontSize: 10, color: textMuted),
          ),
        ),
      );
    }

    final headers = [
      '#',
      'داواکاری',
      'بەروار و کات',
      'نەخۆش',
      'جۆر',
      'پارەدان',
      'کاش / پسوڵە',
      'کرێی گەیاندن',
    ];

    double sumOrderAmount = 0;
    double sumDeliveryFee = 0;
    for (final o in orders) {
      sumOrderAmount += double.tryParse('${o['total_price'] ?? 0}') ?? 0;
      sumDeliveryFee += double.tryParse('${o['delivery_fee'] ?? 0}') ?? 0;
    }

    return pw.Table(
      border: pw.TableBorder.all(color: borderColor, width: 0.5),
      columnWidths: const {
        0: pw.FixedColumnWidth(20),
        1: pw.FixedColumnWidth(40),
        2: pw.FixedColumnWidth(72),
        3: pw.FlexColumnWidth(2.1),
        4: pw.FlexColumnWidth(1.5),
        5: pw.FlexColumnWidth(1.4),
        6: pw.FlexColumnWidth(1.6),
        7: pw.FlexColumnWidth(1.5),
      },
      children: [
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
        ...orders.asMap().entries.map((entry) {
          final i = entry.key;
          final o = entry.value;
          final isEven = i % 2 == 0;
          final isCash = _isCashOrder(o);
          final isSettled = isCash && o['is_settled'] == true;
          final isLab = o['is_lab'] == true;
          final payLabel = isSettled
              ? 'کاش (سفرکراوە)'
              : (isCash ? 'کاش' : 'ئۆنلاین');

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.white : bgMuted,
            ),
            children: [
              _cell('${i + 1}', align: pw.TextAlign.center, fontSize: 7),
              _cell(
                (o['order_number'] ?? '#${o['id']}').toString(),
                align: pw.TextAlign.center,
                fontSize: 7.5,
                isBold: true,
              ),
              _cell(
                _deliveredDateStr(o),
                align: pw.TextAlign.center,
                fontSize: 6.8,
              ),
              _cell(_patientName(o), fontSize: 7.5),
              _cell(
                isLab ? 'نموونەی تاقیگە' : 'دەرمانخانە',
                align: pw.TextAlign.center,
                fontSize: 7,
              ),
              _cell(
                payLabel,
                align: pw.TextAlign.center,
                fontSize: 7,
                color: isCash
                    ? (isSettled ? textMuted : successColor)
                    : primaryColor,
              ),
              _cell(
                _formatIqd(o['total_price']),
                align: pw.TextAlign.right,
                fontSize: 7.5,
              ),
              _cell(
                _formatIqd(o['delivery_fee']),
                align: pw.TextAlign.right,
                fontSize: 7.5,
                color: primaryColor,
                isBold: true,
              ),
            ],
          );
        }),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: primaryLight),
          children: [
            _cell('', fontSize: 7.5),
            _cell('کۆی گشتی', align: pw.TextAlign.center, fontSize: 7.5, isBold: true),
            _cell('${orders.length} گەیاندن', align: pw.TextAlign.center, fontSize: 7.5, isBold: true),
            _cell('', fontSize: 7.5),
            _cell('', fontSize: 7.5),
            _cell('', fontSize: 7.5),
            _cell(_formatIqd(sumOrderAmount), align: pw.TextAlign.right, fontSize: 7.5, isBold: true),
            _cell(
              _formatIqd(sumDeliveryFee),
              align: pw.TextAlign.right,
              fontSize: 8,
              color: primaryColor,
              isBold: true,
            ),
          ],
        ),
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

  static pw.Widget _buildFooter(pw.Font ttfBold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: bgMuted,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: borderColor),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'واژۆ و پەسەندکردنی بەشی دارایی',
                style: pw.TextStyle(font: ttfBold, fontSize: 8.5, color: textColor),
              ),
              pw.SizedBox(height: 16),
              pw.Container(width: 120, height: 1, color: borderColor),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'پەسەندکراوە لەلایەن سیستەمی Dr. Room',
                style: pw.TextStyle(font: ttfBold, fontSize: 8, color: successColor),
              ),
              pw.Text(
                'ئەم ڕاپۆرتە بە شێوەی خۆکار لە داتابەیسی سەکۆ ئامادەکراوە',
                style: const pw.TextStyle(fontSize: 7.5, color: textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Future<void> previewAndPrint(
    BuildContext context, {
    required Map<String, dynamic> driver,
    required Map<String, dynamic> finance,
    required List<dynamic> orders,
  }) async {
    final pdf = await generateDocument(
      driver: driver,
      finance: finance,
      orders: orders,
    );
    final driverName = (driver['name'] ?? 'Driver').toString().replaceAll(' ', '_');
    final periodCode =
        (finance['period_summary']?['month'] ?? finance['selected_month'] ?? 'all')
            .toString();

    await Printing.layoutPdf(
      name: 'DrRoom_Driver_${driverName}_$periodCode.pdf',
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  static Future<void> sharePdf({
    required Map<String, dynamic> driver,
    required Map<String, dynamic> finance,
    required List<dynamic> orders,
  }) async {
    final pdf = await generateDocument(
      driver: driver,
      finance: finance,
      orders: orders,
    );
    final bytes = await pdf.save();
    final driverName = (driver['name'] ?? 'Driver').toString().replaceAll(' ', '_');
    final periodCode =
        (finance['period_summary']?['month'] ?? finance['selected_month'] ?? 'all')
            .toString();

    await Printing.sharePdf(
      bytes: bytes,
      filename: 'DrRoom_Driver_${driverName}_$periodCode.pdf',
    );
  }
}
