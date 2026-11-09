import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import '../../core/theme/app_colors.dart';
import 'patient_support_tickets_screen.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Map<String, String>> _getFaqList(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    final isEnglish = context.locale.languageCode == 'en';

    if (isArabic) {
      return [
        {
          'question': 'كيفية الاستفادة من عروض المختبرات؟',
          'answer': 'يمكنك بسهولة الاستفادة من أفضل العروض المختبرية عبر تطبيقنا. قم بزيارة قسم "العروض" أو "المختبرات" للاطلاع على قائمة الباقات المخفضة (مثل الفحص الشامل، فحص الفيتامينات، أو الفحوصات الموسمية). اختر الباقة المطلوبة وحدد الوقت المناسب، وسيقوم فريقنا بزيارتك في المنزل لسحب العينات دون عناء.',
        },
        {
          'question': 'چۆن داوای پشکنینی تاقیگە یان پەرستاری بکەم؟',
          'answer': 'دەتوانیت لە ڕێگەی بەشی تاقیگە پشکنین دیاری بکەیت یان وێنەی ڕەچەتە ئەپلۆد بکەیت، بۆ پەرستاریش لە بەشی خزمەتگوزاری پەرستاری داواکارییەکەت بنێریت.',
        },
        {
          'question': 'كيفية الاستفادة من عروض التمريض؟',
          'answer': 'للحصول على خدمات التمريض بأسعار مخفضة، قم بزيارة قسم "التمريض" في التطبيق. هناك يمكنك الاطلاع على العروض الخاصة للرعاية المنزلية (مثل الحقن، تركيب المغذي، تضميد الجروح، ورعاية المرضى). اختر العرض وأرسل الطلب؛ وسيصلك ممرض مؤهل في الوقت المحدد.',
        },
        {
          'question': 'زانیارییە پزیشکییەکانم چۆن پارێزراون؟',
          'answer': 'تەواوی داتاکان بە شێوازی پێشکەوتووی پاراستنی داتا و ئینکریپشن لە سێرڤەری پارێزراودا دەپارێزرێن و تەنها تۆ و پزیشکی پەیوەندیدار دەستتان پێی دەگات.',
        },
      ];
    } else if (isEnglish) {
      return [
        {
          'question': 'How to benefit from lab offers?',
          'answer': 'You can easily benefit from the best laboratory offers through our app. Simply visit the "Offers" or "Labs" section to see a list of discounted packages (such as comprehensive health checkup, vitamins check, or seasonal tests). Select the package, choose a suitable time, and our team will visit your home for sample collection without any hassle.',
        },
        {
          'question': 'How do I request a lab test or nursing service?',
          'answer': 'You can select tests in the lab section or upload a prescription, and for nursing, submit your request from the nursing services section.',
        },
        {
          'question': 'How to benefit from nursing offers?',
          'answer': 'To get nursing services at discounted prices, visit the "Nursing" section in the app. There you can find special offers for home care (like injections, IV therapy, wound dressing, and patient care). Select the offer and send your request; an expert and trusted nurse will arrive at your scheduled time.',
        },
        {
          'question': 'How is my medical data protected?',
          'answer': 'All data is secured using advanced encryption on protected servers, accessible only by you and your designated medical professional.',
        },
      ];
    }

    // Default Kurdish (Sorani / Kurmanji)
    return [
      {
        'question': '١. چۆنیەتی سوودمەندبوون لە ئۆفەرەکانی تاقیگە؟',
        'answer': 'دەتوانیت زۆر بە ئاسانی لە ڕێگەی ئەپڵیکەیشنەکەمانەوە سوود لە باشترین ئۆفەرە تاقیگەییەکان ببینیت. تەنها سەردانی بەشی \'ئۆفەرەکان\' یان \'تاقیگە\' بکە، لەوێدا لیستێک لە پاکێجە داشکێنراوەکان (وەک پشکنینی گشتی جەستە، پشکنینی ڤیتامینات، یان پشکنینە وەرزییەکان) دەبینیت. پاکێجە مەبەستدارەکە هەڵبژێرە، کاتی گونجاو دیاری بکە، و تیمەکانمان دێنە ماڵەکەی خۆت بۆ وەرگرتنی نموونەکان بەبێ ئەوەی پێویست بە ماندووبوون و سەردانیکردنی تاقیگە بکات.',
      },
      {
        'question': 'چۆن داوای پشکنینی تاقیگە یان پەرستاری بکەم؟',
        'answer': 'دەتوانیت لە ڕێگەی بەشی تاقیگە پشکنین دیاری بکەیت یان وێنەی ڕەچەتە ئەپلۆد بکەیت، بۆ پەرستاریش لە بەشی خزمەتگوزاری پەرستاری داواکارییەکەت بنێریت.',
      },
      {
        'question': '٢. چۆنیەتی سوودمەندبوون لە ئۆفەرەکانی پەرستاری؟',
        'answer': 'بۆ بەدەستهێنانی خزمەتگوزارییە پەرستارییەکان بە نرخی داشکێنراو، سەردانی بەشی \'پەرستاری\' بکە لە ئەپەکەدا. لەوێدا دەتوانیت ئۆفەرە تایبەتەکان بۆ خزمەتگوزارییەکانی ماڵەوە (وەک دەرزی لێدان، دانانی مەغزی، برینپێچی، و چاودێری نەخۆش) ببینیت. ئۆفەرەکە هەڵبژێرە و داواکارییەکە بنێرە؛ پەرستارێکی شارەزا و متمانەپێکراو لە کاتی دیاریکراودا دەگاتە لات بۆ پێشکەشکردنی باشترین چاودێری تەندروستی.',
      },
      {
        'question': 'زانیارییە پزیشکییەکانم چۆن پارێزراون؟',
        'answer': 'تەواوی داتاکان بە شێوازی پێشکەوتووی پاراستنی داتا و ئینکریپشن لە سێرڤەری پارێزراودا دەپارێزرێن و تەنها تۆ و پزیشکی پەیوەندیدار دەستتان پێی دەگات.',
      },
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url);
      }
    } catch (e) {
      debugPrint('Error launching phone call: $e');
    }
  }

  Future<void> _launchWhatsApp(String phone) async {
    final String cleanNumber = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final String fullNumber = cleanNumber.startsWith('0')
        ? '964${cleanNumber.substring(1)}'
        : (cleanNumber.startsWith('964') ? cleanNumber : '964$cleanNumber');

    final Uri appUri = Uri.parse('whatsapp://send?phone=$fullNumber');
    final Uri webUri = Uri.parse('https://wa.me/$fullNumber');

    try {
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUri);
      }
    } catch (e) {
      try {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } catch (e2) {
        debugPrint('Error launching WhatsApp: $e2');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final faqList = _getFaqList(context);
    final filteredFaqs = _searchQuery.isEmpty
        ? faqList
        : faqList.where((faq) {
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
            const SizedBox(height: 20),

            // Live Support & Tickets Card
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PatientSupportTicketsScreen()),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.85)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white24,
                      child: Icon(Iconsax.message_question, color: Colors.white),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'support_and_tickets'.tr(),
                            style: const TextStyle(fontFamily: 'Rabar', fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'my_tickets'.tr(),
                            style: TextStyle(fontFamily: 'Rabar', fontSize: 12, color: Colors.white.withValues(alpha: 0.85)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

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

            // Contact Options (Phone Call & WhatsApp)
            Row(
              children: [
                _buildContactCard(
                  context,
                  icon: Iconsax.call,
                  title: 'phone_call'.tr(),
                  subtitle: '0750 614 8003',
                  color: const Color(0xFF3B82F6),
                  onTap: () => _makePhoneCall('07506148003'),
                ),
                const SizedBox(width: 14),
                _buildContactCard(
                  context,
                  icon: Icons.chat_rounded,
                  title: 'channel_whatsapp'.tr(),
                  subtitle: '0750 614 8003',
                  color: const Color(0xFF25D366),
                  onTap: () => _launchWhatsApp('07506148003'),
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
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
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
            mainAxisSize: MainAxisSize.min,
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    color: AppColors.getTextSubtitle(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textDirection: TextDirection.ltr,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(BuildContext context, {required String question, required String answer}) {
    return Material(
      color: AppColors.getSurface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.getBorder(context)),
      ),
      clipBehavior: Clip.antiAlias,
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