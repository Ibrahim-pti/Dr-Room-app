import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/api_client.dart';
import '../first_aid/first_aid_screen.dart';

class EmergencySosModal {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _EmergencySosSheet(),
    );
  }
}

class _EmergencySosSheet extends StatefulWidget {
  const _EmergencySosSheet();

  @override
  State<_EmergencySosSheet> createState() => _EmergencySosSheetState();
}

class _EmergencySosSheetState extends State<_EmergencySosSheet> {
  List<dynamic> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchContacts();
  }

  Future<void> _fetchContacts() async {
    try {
      final res = await ApiClient.get('/emergency-contacts');
      if (res.statusCode == 200 && mounted) {
        final decoded = jsonDecode(res.body);
        final list = decoded is Map ? (decoded['data'] ?? []) : decoded;
        if (list is List && list.isNotEmpty) {
          setState(() {
            _contacts = list;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}

    // Graceful offline fallback defaults
    if (mounted) {
      setState(() {
        _contacts = [
          {
            'title': 'call_emergency_122'.tr(),
            'subtitle': 'ambulance_emergency_team'.tr(),
            'phone': '122',
            'icon_type': 'ambulance',
            'is_primary': true,
          },
          {
            'title': 'نەخۆشخانەی فریاکەوتنی ڕۆژئاوا',
            'subtitle': 'بۆ حاڵەتە لەناکاو و نەشتەرگەرییە بەپەلەکان',
            'phone': '0662234567',
            'icon_type': 'hospital',
            'is_primary': false,
          },
          {
            'title': 'بانکی خوێنی ناوەندی بەپەلە',
            'subtitle': 'دابینکردنی هەموو گرووپە باو و دەگمەنەکانی خوێن',
            'phone': '0662245678',
            'icon_type': 'blood_bank',
            'is_primary': false,
          },
        ];
        _isLoading = false;
      });
    }
  }

  TextStyle _kStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = const Color(0xFF0F172A),
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'Rabar',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    dynamic primaryContact;
    final otherContacts = <dynamic>[];

    for (final c in _contacts) {
      if (c['is_primary'] == true && primaryContact == null) {
        primaryContact = c;
      } else {
        otherContacts.add(c);
      }
    }

    // Default primary if none specified
    primaryContact ??= {
      'title': 'call_emergency_122'.tr(),
      'subtitle': 'ambulance_emergency_team'.tr(),
      'phone': '122',
    };

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emergency, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'فریاکەوتنی خێرا و بەپەلە (SOS)',
                      style: _kStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'emergency_modal_sub'.tr(),
                      style: _kStyle(fontSize: 12, color: const Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Main 122 / Primary Ambulance Button
                  GestureDetector(
                    onTap: () => _makeCall(primaryContact['phone'] ?? '122'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.call, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  primaryContact['title'] ?? 'call_emergency_122'.tr(),
                                  style: _kStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  primaryContact['subtitle'] ?? 'ambulance_emergency_team'.tr(),
                                  style: _kStyle(fontSize: 11.5, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              primaryContact['phone'] ?? '122',
                              style: const TextStyle(
                                fontFamily: 'Rabar',
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Dynamic Contacts List
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFEF4444),
                          strokeWidth: 2.5,
                        ),
                      ),
                    )
                  else
                    ...otherContacts.map((contact) {
                      final iconType = contact['icon_type'] ?? 'hospital';
                      final (icon, color) = switch (iconType) {
                        'ambulance' => (Icons.emergency, const Color(0xFFEF4444)),
                        'blood_bank' => (Icons.water_drop, const Color(0xFFE11D48)),
                        'general' => (Icons.call, const Color(0xFF10B981)),
                        _ => (Iconsax.hospital, const Color(0xFF3B82F6)),
                      };

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildEmergencyItem(
                          context,
                          title: contact['title'] ?? '',
                          subtitle: contact['subtitle'] ?? '',
                          phone: contact['phone'] ?? '',
                          icon: icon,
                          color: color,
                          cardBg: cardBg,
                          borderColor: borderColor,
                          isDark: isDark,
                        ),
                      );
                    }),

                  const SizedBox(height: 6),

                  // First-Aid Guide Banner Button
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FirstAidScreen(showBackButton: true),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.medical_services_outlined, color: Color(0xFF3B82F6), size: 22),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ڕێبەری فریاگوزاریی سەرەتایی (First-Aid)',
                                  style: _kStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2563EB),
                                  ),
                                ),
                                Text(
                                  'emergency_guide_sub'.tr(),
                                  style: _kStyle(
                                    fontSize: 11.5,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Color(0xFF3B82F6), size: 14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String phone,
    required IconData icon,
    required Color color,
    required Color cardBg,
    required Color borderColor,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () => _makeCall(phone),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _kStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _kStyle(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.call, color: color, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    phone,
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      color: color,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}