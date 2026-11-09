import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/api_client.dart';

class PatientLoyaltyScreen extends StatefulWidget {
  const PatientLoyaltyScreen({super.key});

  @override
  State<PatientLoyaltyScreen> createState() => _PatientLoyaltyScreenState();
}

class _PatientLoyaltyScreenState extends State<PatientLoyaltyScreen> {
  bool _isLoading = true;
  String? _error;

  int _points = 0;
  double _monetaryValue = 0;
  String _tier = 'Silver';
  List<dynamic> _history = [];
  bool _isRedeeming = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ApiClient.get('/loyalty/balance'),
        ApiClient.get('/loyalty/history'),
      ]);

      if (!mounted) return;

      if (results[0].statusCode == 200 && results[1].statusCode == 200) {
        final balData = jsonDecode(results[0].body)['data'];
        final histData = jsonDecode(results[1].body)['data'];

        setState(() {
          _points = balData['points'] ?? 0;
          _monetaryValue = (balData['monetary_value_iqd'] ?? 0).toDouble();
          _tier = balData['tier'] ?? 'Silver';
          _history = histData is Map
              ? (histData['data'] ?? [])
              : (histData ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'کێشە لە بارکردنی خاڵەکان ڕوویدا';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted)
        if (mounted) {
          setState(() {
            _error = '$e';
            _isLoading = false;
          });
        }
    }
  }

  Future<void> _redeemPoints() async {
    if (_points < 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'کەمترین بڕی پێویست بۆ گۆڕینەوە ٢٠٠ خاڵە',
            style: TextStyle(fontFamily: 'Rabar'),
          ),
        ),
      );
      return;
    }

    final pointsToRedeem = (_points ~/ 100) * 100;
    final iqdValue = pointsToRedeem * 10;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'گۆڕینەوەی خاڵەکان',
          style: TextStyle(fontFamily: 'Rabar', fontWeight: FontWeight.bold),
        ),
        content: Text(
          'ئایا دڵنیایت لە گۆڕینەوەی $pointsToRedeem خاڵ بۆ کۆدی داشکاندن بە بەهای ${NumberFormat('#,###').format(iqdValue)} د.ع؟',
          style: const TextStyle(fontFamily: 'Rabar'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'پاشگەزبوونەوە',
              style: TextStyle(fontFamily: 'Rabar'),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'گۆڕینەوە',
              style: TextStyle(fontFamily: 'Rabar'),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isRedeeming = true);
    try {
      final res = await ApiClient.post(
        '/loyalty/redeem',
        body: {'points': pointsToRedeem},
      );

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body)['data'];
        final couponCode = body['coupon_code'];

        if (!mounted) return;
        _showSuccessCouponDialog(couponCode, iqdValue);
        _load();
      } else {
        final msg = jsonDecode(res.body)['message'] ?? 'هەڵە ڕوویدا';
        if (mounted)
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg, style: const TextStyle(fontFamily: 'Rabar')),
              ),
            );
          }
      }
    } catch (_) {}
    if (mounted) setState(() => _isRedeeming = false);
    if (mounted) {
      setState(() => _isRedeeming = false);
    }
  }

  void _showSuccessCouponDialog(String code, int value) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Iconsax.ticket_discount, color: Color(0xFF10B981), size: 28),
            SizedBox(width: 8),
            Text(
              'پیرۆزە! کۆدەکەت ئامادەیە',
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'کۆدێکی داشکاندن بە بەهای ${NumberFormat('#,###').format(value)} د.ع بۆت دروستکرا:',
              style: const TextStyle(fontFamily: 'Rabar', fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFCBD5E1),
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    code,
                    style: const TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.copy, color: Colors.blue),
                    tooltip: 'کۆپیکردنی کۆد',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'کۆدەکە کۆپیکرا!',
                            style: TextStyle(fontFamily: 'Rabar'),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('تەواو', style: TextStyle(fontFamily: 'Rabar')),
          ),
        ],
      ),
    );
  }

  Color _tierColor() {
    return switch (_tier) {
      'Platinum' => const Color(0xFFE2E8F0),
      'Gold' => const Color(0xFFF59E0B),
      _ => const Color(0xFF94A3B8),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'loyalty_program'.tr(),
          style: const TextStyle(
            fontFamily: 'Rabar',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(
                _error!,
                style: const TextStyle(fontFamily: 'Rabar', color: Colors.grey),
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Loyalty Card
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Iconsax.medal_star,
                                    color: Colors.amber,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'loyalty_program'.tr(),
                                    style: const TextStyle(
                                      fontFamily: 'Rabar',
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _tierColor().withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _tierColor().withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Text(
                                  _tier,
                                  style: TextStyle(
                                    fontFamily: 'Rabar',
                                    color: _tierColor(),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'pts_balance'.tr(),
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                NumberFormat('#,###').format(_points),
                                style: const TextStyle(
                                  fontFamily: 'Rabar',
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'خاڵ',
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white24, height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'pts_value'.tr(),
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${NumberFormat('#,###').format(_monetaryValue)} د.ع',
                                style: const TextStyle(
                                  fontFamily: 'Rabar',
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 250.ms),

                    const SizedBox(height: 16),

                    // Redeem Button
                    ElevatedButton.icon(
                      onPressed: (_points >= 200 && !_isRedeeming)
                          ? _redeemPoints
                          : null,
                      icon: _isRedeeming
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Iconsax.ticket_discount),
                      label: Text(
                        _points >= 200
                            ? 'redeem_points'.tr()
                            : 'کەمترین بڕ بۆ گۆڕینەوە ٢٠٠ خاڵە',
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Points History
                    Text(
                      'points_history'.tr(),
                      style: const TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_history.isEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        padding: const EdgeInsets.all(24),
                        child: const Center(
                          child: Text(
                            'هێشتا هیچ خاڵێک تۆمارنەکراوە',
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    else
                      ..._history.map((h) {
                        final pts = h['points'] ?? 0;
                        final isPositive = pts > 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor:
                                    (isPositive
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFEF4444))
                                        .withValues(alpha: 0.12),
                                child: Icon(
                                  isPositive ? Icons.add : Icons.remove,
                                  color: isPositive
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      h['description'] ?? 'چالاکی خاڵەکان',
                                      style: const TextStyle(
                                        fontFamily: 'Rabar',
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      h['created_at'] != null
                                          ? DateFormat(
                                              'yyyy-MM-dd HH:mm',
                                            ).format(
                                              DateTime.parse(h['created_at']),
                                            )
                                          : '',
                                      style: const TextStyle(
                                        fontFamily: 'Rabar',
                                        fontSize: 11,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${isPositive ? '+' : ''}$pts',
                                style: TextStyle(
                                  fontFamily: 'Rabar',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isPositive
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
    );
  }
}
