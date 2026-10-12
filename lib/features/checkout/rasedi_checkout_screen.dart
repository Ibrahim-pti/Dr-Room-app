import 'dart:async';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:rasedi_flutter_sdk/rasedi_flutter_sdk.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/services/rasedi_payment_service.dart';

class RasediCheckoutScreen extends StatefulWidget {
  final double amount;
  final String title;
  final String description;
  final Gateway gateway;
  final String? customerPhone;
  final String? customerEmail;

  const RasediCheckoutScreen({
    super.key,
    required this.amount,
    required this.title,
    required this.description,
    required this.gateway,
    this.customerPhone,
    this.customerEmail,
  });

  /// Helper route method to easily push the screen
  static Future<RasediPaymentResult?> startPayment(
    BuildContext context, {
    required double amount,
    required String title,
    required String description,
    required Gateway gateway,
    String? customerPhone,
    String? customerEmail,
  }) {
    return Navigator.push<RasediPaymentResult>(
      context,
      MaterialPageRoute(
        builder: (context) => RasediCheckoutScreen(
          amount: amount,
          title: title,
          description: description,
          gateway: gateway,
          customerPhone: customerPhone,
          customerEmail: customerEmail,
        ),
      ),
    );
  }

  @override
  State<RasediCheckoutScreen> createState() => _RasediCheckoutScreenState();
}

class _RasediCheckoutScreenState extends State<RasediCheckoutScreen> {
  final RasediPaymentService _service = RasediPaymentService.instance;

  late final WebViewController _controller;
  late final NavigationDelegate _navigationDelegate;
  String? _referenceCode;
  String? _redirectUrl;
  bool _isInitializing = true;
  bool _isLoadingPage = true;
  String? _errorMessage;
  Timer? _statusPollingTimer;
  bool _hasCompleted = false;

  @override
  void initState() {
    super.initState();
    _navigationDelegate = NavigationDelegate(
      onPageStarted: (String url) {
        if (mounted) setState(() => _isLoadingPage = true);
        _handleUrlInterception(url);
      },
      onPageFinished: (String url) {
        if (mounted) setState(() => _isLoadingPage = false);
        _handleUrlInterception(url);

        // Clean up requested UI elements: theme/lang icons, yellow warning, promo code, amount row
        _controller.runJavaScript('''
          (function() {
            function applyCleanStyles() {
              // 1. Hide theme (moon) and language (globe) icons
              document.querySelectorAll('button[aria-label="Toggle theme"], button[aria-label="Change language"], button[title="Toggle theme"], button[title="Change language"]').forEach(el => el.style.display = 'none');

              // 2. Hide yellow warning box ("No payment gateway has been selected...")
              document.querySelectorAll('.bg-warning-bg-light').forEach(el => el.style.display = 'none');

              // 3. Hide promo code buttons & containers (Kurdish: زیادکردنی پرۆمۆ کۆد, Arabic: إضافة رمز ترويجي, English: Promo code)
              const promoTerms = [
                'پرۆمۆ',
                'پڕۆمۆ',
                'پرۆمۆ کۆد',
                'پڕۆمۆ کۆد',
                'زیادکردنی پرۆمۆ',
                'زیادکردنی پرۆمۆ کۆد',
                'داشکاندن',
                'کوپۆن',
                'کۆپۆن',
                'promo',
                'promotion',
                'coupon',
                'discount',
                'ترويجي',
                'كود الخصم',
                'كوبون'
              ];

              document.querySelectorAll('button, a, div, span').forEach(el => {
                const t = (el.innerText || '').trim();
                if (!t || t.length > 70) return;
                const lower = t.toLowerCase();
                for (const term of promoTerms) {
                  if (t.includes(term) || lower.includes(term.toLowerCase())) {
                    if (!t.includes('DrRoom') && !t.includes('nursing')) {
                      const target = el.closest('button') || el.closest('.relative') || el;
                      target.style.display = 'none';
                      break;
                    }
                  }
                }
              });

              // 4. Hide "Amount :" row
              document.querySelectorAll('div').forEach(el => {
                const t = el.innerText || '';
                if ((t.startsWith('Amount :') || t.startsWith('بڕی پارە :') || t.startsWith('المبلغ :')) && el.children.length <= 3) {
                  el.style.display = 'none';
                }
              });
            }

            applyCleanStyles();
            const observer = new MutationObserver(applyCleanStyles);
            observer.observe(document.body, { childList: true, subtree: true });
          })();
        ''');
      },
      onNavigationRequest: (NavigationRequest request) {
        final url = request.url;

        // Don't treat internal webview URLs or about:blank as external apps!
        if (url.startsWith('about:') || url.startsWith('javascript:')) {
          return NavigationDecision.navigate;
        }

        // Handle external banking apps (e.g. fib://, fastpay://, intent://)
        if (!url.startsWith('http://') && !url.startsWith('https://')) {
          _launchExternalUrl(url);
          return NavigationDecision.prevent;
        }

        if (_handleUrlInterception(url)) {
          return NavigationDecision.prevent;
        }

        return NavigationDecision.navigate;
      },
      onWebResourceError: (WebResourceError error) {
        debugPrint('WebView Error: ${error.description}');
      },
      onHttpAuthRequest: (HttpAuthRequest request) {
        request.onCancel();
      },
    );

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(_navigationDelegate);

    _createSession();
  }

  @override
  void dispose() {
    _statusPollingTimer?.cancel();
    try {
      _controller.loadRequest(Uri.parse('about:blank'));
    } catch (_) {}
    super.dispose();
  }

  String get _gatewayDisplayName {
    switch (widget.gateway) {
      case Gateway.FIB:
        return 'First Iraqi Bank (FIB)';
      case Gateway.FAST_PAY:
        return 'FastPay';
      case Gateway.ZAIN:
        return 'ZainCash';
      case Gateway.CREDIT_CARD:
        return 'Qi Card / Card';
      default:
        return 'Rasedi';
    }
  }

  String get _gatewayKurdishTitle {
    switch (widget.gateway) {
      case Gateway.FIB:
        return 'فایب بانک (FIB)';
      case Gateway.FAST_PAY:
        return 'فاستپەی (FastPay)';
      case Gateway.ZAIN:
        return 'زەین کاش (ZainCash)';
      case Gateway.CREDIT_CARD:
        return 'کی کارد و ماستەرکارت';
      default:
        return 'پارەدانی ئەلیکترۆنی';
    }
  }

  Color get _gatewayColor {
    switch (widget.gateway) {
      case Gateway.FIB:
        return const Color(0xFF2563EB);
      case Gateway.FAST_PAY:
        return const Color(0xFFEC4899);
      case Gateway.ZAIN:
        return const Color(0xFF8B5CF6);
      case Gateway.CREDIT_CARD:
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  Future<void> _createSession() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      final responseBody = await _service.createPayment(
        amount: widget.amount,
        title: widget.title,
        description: widget.description,
        gateway: widget.gateway,
        customerPhone: widget.customerPhone,
        customerEmail: widget.customerEmail,
      );

      _referenceCode = responseBody.referenceCode;
      var targetUrl = responseBody.redirectUrl;

      // Localize Rasedi checkout url according to app language (e.g. /ku/)
      if (mounted) {
        final langCode =
            Localizations.localeOf(context).languageCode.toLowerCase();
        final rasediLang =
            (langCode == 'ar') ? 'ar' : (langCode == 'en' ? 'en' : 'ku');
        if (targetUrl.contains('checkout.rasedi.com/pay/')) {
          targetUrl = targetUrl.replaceFirst(
            'checkout.rasedi.com/pay/',
            'checkout.rasedi.com/$rasediLang/pay/',
          );
        }
      }
      _redirectUrl = targetUrl;

      await _controller.loadRequest(Uri.parse(_redirectUrl!));

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }

      // Start periodic status checking
      _startStatusPolling();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _launchExternalUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Failed to launch external app URL: $e');
    }
  }

  bool _handleUrlInterception(String url) {
    if (_hasCompleted) return true;

    if (url.startsWith(RasediPaymentService.redirectUrl) ||
        url.contains('/callback') ||
        url.contains('status=paid') ||
        url.contains('status=success')) {
      _checkStatusImmediately();
      return true;
    }
    return false;
  }

  void _startStatusPolling() {
    _statusPollingTimer?.cancel();
    _statusPollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_hasCompleted || _referenceCode == null) {
        timer.cancel();
        return;
      }
      _checkStatusImmediately();
    });
  }

  Future<void> _checkStatusImmediately() async {
    if (_hasCompleted || _referenceCode == null) return;

    try {
      final status = await _service.checkPaymentStatus(_referenceCode!);
      if (status == PaymentStatus.PAID) {
        _hasCompleted = true;
        _statusPollingTimer?.cancel();
        if (mounted) {
          Navigator.pop(
            context,
            RasediPaymentResult.success(
              referenceCode: _referenceCode!,
              gatewayName: _gatewayDisplayName,
            ),
          );
        }
      } else if (status == PaymentStatus.FAILED ||
          status == PaymentStatus.TIMED_OUT ||
          status == PaymentStatus.CANCELED) {
        _statusPollingTimer?.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'پارەدانەکە سەرکەوتوو نەبوو، باڵانس بەش ناکات یان پرۆسەکە هەڵوەشایەوە',
                style: TextStyle(fontFamily: 'Rabar'),
              ),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Status check error: $e');
    }
  }

  Future<bool> _onWillPop() async {
    if (_hasCompleted) return true;

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'هەڵوەشاندنەوەی پارەدان',
          textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Rabar', fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: const Text(
          'ئایا دڵنیایت لەوەی دەتەوێت پرۆسەی پارەدانەکە هەڵبوەشێنیتەوە؟',
          textAlign: TextAlign.right,
          style: TextStyle(fontFamily: 'Rabar', fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('نەخێر، بەردەوامبە', style: TextStyle(fontFamily: 'Rabar', color: Color(0xFF3B82F6))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('بەڵێ، هەڵیوەشێنەرەوە', style: TextStyle(fontFamily: 'Rabar', color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldCancel == true) {
      if (_referenceCode != null) {
        _service.cancelPayment(_referenceCode!);
      }
      if (mounted) {
        Navigator.pop(context, RasediPaymentResult.cancelled());
      }
      return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _onWillPop();
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          elevation: 0.5,
          leading: IconButton(
            icon: Icon(
              Icons.close,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            onPressed: _onWillPop,
          ),
          title: Text(
            _gatewayKurdishTitle,
            style: TextStyle(
              fontFamily: 'Rabar',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          actions: const [],
        ),
        body: Column(
          children: [
            if (_isLoadingPage && !_isInitializing)
              const LinearProgressIndicator(
                backgroundColor: Color(0xFFE2E8F0),
                color: Color(0xFF3B82F6),
                minHeight: 3,
              ),
            Expanded(
              child: _buildBody(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isInitializing) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                color: _gatewayColor,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'ئامادەکردنی دەروازەی پارەدان...',
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _gatewayDisplayName,
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Iconsax.warning_2,
                  color: Color(0xFFEF4444),
                  size: 44,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'کێشەیەک لە پەیوەندی بە دەروازەی پارەدان دروست بوو',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _createSession,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('دووبارە هەوڵبدەرەوە', style: TextStyle(fontFamily: 'Rabar', color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return WebViewWidget(controller: _controller);
  }
}
