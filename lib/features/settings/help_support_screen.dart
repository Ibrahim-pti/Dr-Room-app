import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, String>> _faqList = [
    {
      'question': 'چۆن نۆرەی پزیشک بگرم؟',
      'answer': 'بچۆ بۆ پەڕەی سەرەکی یان بەشی پزیشکان، پزیشکی دڵخوازت هەڵبژێرە و کاتێکی گونجاو لە خشتەی بەردەست دیاری بکە و نۆرەکەت پشتڕاست بکەرەوە.',
    },
    {
      'question': 'چۆن داوای پشکنینی تاقیگە یان پەرستاری بکەم؟',
      'answer': 'دەتوانیت لە ڕێگەی بەشی تاقیگە پشکنین دیاری بکەیت یان وێنەی ڕەچەتە ئەپلۆد بکەیت، بۆ پەرستاریش لە بەشی خزمەتگوزاری پەرستاری داواکارییەکەت بنێریت.',
    },
    {
      'question': 'ئایا دەتوانم نۆرەکەم هەڵوەشێنمەوە؟',
      'answer': 'بەڵێ، دەتوانیت لە بەشی "داواکارییەکانم" بچیتە سەر نۆرەکەت و دوگمەی هەڵوەشاندنەوە دابگریت پێش کاتی دیاریکراو.',
    },
    {
      'question': 'زانیارییە پزیشکییەکانم چۆن پارێزراون؟',
      'answer': 'تەواوی داتاکان بە شێوازی پێشکەوتووی پاراستنی داتا و ئینکریپشن لە سێرڤەری پارێزراودا دەپارێزرێن و تەنها تۆ و پزیشکی پەیوەندیدار دەستتان پێی دەگات.',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredFaqs = _searchQuery.isEmpty
        ? _faqList
        : _faqList.where((faq) {
            return faq['question']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                faq['answer']!.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getBackground(context),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.chevron_left_rounded,
            color: AppColors.getTextTitle(context),
            size: 32,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'help_and_support'.tr(),
          style: TextStyle(
            fontFamily: 'Rabar',
            color: AppColors.getTextTitle(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.getBorder(context)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                style: TextStyle(
                  fontFamily: 'Rabar',
                  color: AppColors.getTextTitle(context),
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  hintText: 'help_search_hint'.tr(),
                  hintStyle: const TextStyle(
                    fontFamily: 'Rabar',
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  icon: const Icon(Iconsax.search_normal, color: Color(0xFF94A3B8), size: 20),
                ),
              ),
            ),
            const SizedBox(height: 28),

            Text(
              'contact_us'.tr(),
              style: TextStyle(
                fontFamily: 'Rabar',
                color: AppColors.getTextTitle(context),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),

            // Contact Options
            Row(
              children: [
                _buildContactCard(
                  context,
                  icon: Iconsax.call,
                  title: 'phone_call'.tr(),
                  color: const Color(0xFF3B82F6),
                  onTap: () async {
                    final Uri url = Uri.parse('tel:+9647501234567');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                ),
                const SizedBox(width: 14),
                _buildContactCard(
                  context,
                  icon: Iconsax.sms,
                  title: 'send_email'.tr(),
                  color: const Color(0xFFF59E0B),
                  onTap: () async {
                    final Uri url = Uri.parse('mailto:support@drroom.app?subject=Support');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),

            Text(
              'faq_title'.tr(),
              style: TextStyle(
                fontFamily: 'Rabar',
                color: AppColors.getTextTitle(context),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),

            // FAQ Items
            if (filteredFaqs.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'no_faqs_found'.tr(),
                    style: TextStyle(fontFamily: 'Rabar', color: AppColors.getTextSubtitle(context)),
                  ),

                ),
              )
            else
              ...filteredFaqs.map((faq) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildFAQItem(
                      context,
                      question: faq['question']!,
                      answer: faq['answer']!,
                    ),
                  )),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.getSurface(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.getBorder(context)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Rabar',
                  color: AppColors.getTextTitle(context),
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, {required String question, required String answer}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: const Color(0xFF3B82F6),
          collapsedIconColor: const Color(0xFF94A3B8),
          title: Text(
            question,
            style: TextStyle(
              fontFamily: 'Rabar',
              color: AppColors.getTextTitle(context),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          childrenPadding: const EdgeInsetsDirectional.only(start: 16, end: 16, bottom: 16),
          children: [
            Text(
              answer,
              style: TextStyle(
                fontFamily: 'Rabar',
                color: AppColors.getTextSubtitle(context),
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
