import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/api_client.dart';
import 'admin_app_bar.dart';
import 'admin_ui.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic> _data = {};

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
      final res = await ApiClient.get('/admin/analytics/overview');
      if (!mounted) return;

      if (res.statusCode == 200) {
        setState(() {
          _data = jsonDecode(res.body)['data'] ?? {};
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'کێشە لە بارکردنی ئامارەکان ڕوویدا';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _isLoading = false; });
    }
  }

  String _formatIqd(dynamic val) {
    final d = double.tryParse(val?.toString() ?? '0') ?? 0;
    return '${NumberFormat('#,###').format(d)} د.ع';
  }

  @override
  Widget build(BuildContext context) {
    final monthly = _data['monthly'] ?? {};
    final topTests = (_data['top_tests'] as List?) ?? [];
    final topNurses = (_data['top_nurses'] as List?) ?? [];
    final categories = (_data['categories_distribution'] as List?) ?? [];

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AdminAppBar(
        title: 'ئامار و ڕاپۆرتەکان',
        subtitle: 'شیکاری مانگانەی پشکنینەکان و بەکارهێنەران',
        icon: Iconsax.chart_2,
        iconColor: const Color(0xFF8B5CF6),
        iconBackgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: AdminUi.subtitle))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Monthly performance summary
                        Text('ئاستی گەشەکردنی ئەم مانگە', style: AdminUi.title),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetric(
                                'داواکاری مانگ',
                                '${monthly['orders_count'] ?? 0}',
                                Iconsax.bag_2,
                                const Color(0xFF3B82F6),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMetric(
                                'داواکاری تەواوکراو',
                                '${monthly['completed_count'] ?? 0}',
                                Iconsax.tick_circle,
                                const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetric(
                                'داهاتی مانگانە',
                                _formatIqd(monthly['revenue']),
                                Iconsax.wallet_3,
                                const Color(0xFF8B5CF6),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMetric(
                                'نەخۆشی نوێ',
                                '+${monthly['new_users'] ?? 0}',
                                Iconsax.user_add,
                                const Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Most requested lab tests
                        Text('زۆرترین پشکنینی داواکراو', style: AdminUi.title),
                        const SizedBox(height: 12),
                        if (topTests.isEmpty)
                          Container(
                            decoration: AdminUi.cardDecoration,
                            padding: const EdgeInsets.all(20),
                            child: Center(child: Text('هێشتا داواکاری پشکنین تۆمارنەکراوە', style: AdminUi.subtitle)),
                          )
                        else
                          Container(
                            decoration: AdminUi.cardDecoration,
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              children: topTests.asMap().entries.map((entry) {
                                final i = entry.key;
                                final t = entry.value;
                                return Column(
                                  children: [
                                    if (i > 0) const Divider(height: 16),
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                                          child: Text('${i + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(t['title'] ?? 'پشکنین', style: AdminUi.subtitle.copyWith(color: Colors.black87, fontWeight: FontWeight.w600)),
                                        ),
                                        Text('${t['total_requests'] ?? 1} داواکاری', style: const TextStyle(fontFamily: 'Rabar', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
                                      ],
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Test Categories Analytics
                        Text('پۆلێنکردنی پشکنینەکان (بەپێی جۆر)', style: AdminUi.title),
                        const SizedBox(height: 12),
                        if (categories.isEmpty)
                          Container(
                            decoration: AdminUi.cardDecoration,
                            padding: const EdgeInsets.all(20),
                            child: Center(child: Text('زانیاری پۆلەکان لەم مانگەدا بەردەست نییە', style: AdminUi.subtitle)),
                          )
                        else
                          Container(
                            decoration: AdminUi.cardDecoration,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: categories.map<Widget>((cat) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      const Icon(Iconsax.category, size: 18, color: Color(0xFF8B5CF6)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(cat['category'] ?? 'گشتی', style: AdminUi.subtitle.copyWith(color: Colors.black87, fontWeight: FontWeight.w600)),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text('${cat['count'] ?? 0} پشکنین', style: const TextStyle(fontFamily: 'Rabar', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6))),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Top performing nurses
                        Text('باشترین پەرستارەکان', style: AdminUi.title),
                        const SizedBox(height: 12),
                        if (topNurses.isEmpty)
                          Container(
                            decoration: AdminUi.cardDecoration,
                            padding: const EdgeInsets.all(20),
                            child: Center(child: Text('پەرستار بەردەست نییە', style: AdminUi.subtitle)),
                          )
                        else
                          ...topNurses.map((n) {
                            final user = n['user'] ?? {};
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: AdminUi.cardDecoration,
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: ApiClient.getImageProvider(user['profile_image'] ?? n['image_path']),
                                    child: const Icon(Icons.person),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(user['name'] ?? 'پەرستار', style: AdminUi.title),
                                        Text('خزمەتگوزاری ناوماڵ', style: AdminUi.subtitle.copyWith(fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 18),
                                      const SizedBox(width: 4),
                                      Text('${n['rating'] ?? 5.0}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                    ],
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

  Widget _buildMetric(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: AdminUi.cardDecoration,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AdminUi.subtitle.copyWith(fontSize: 11)),
                const SizedBox(height: 2),
                Text(value, style: AdminUi.title.copyWith(fontSize: 14, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
