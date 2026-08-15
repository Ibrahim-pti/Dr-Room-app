import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';

class TermsPrivacyModal extends StatefulWidget {
  final int initialTabIndex; // 0 for Terms, 1 for Privacy
  final VoidCallback? onAccept;

  const TermsPrivacyModal({
    super.key,
    this.initialTabIndex = 0,
    this.onAccept,
  });

  static Future<void> show(
    BuildContext context, {
    int initialTabIndex = 0,
    VoidCallback? onAccept,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TermsPrivacyModal(
        initialTabIndex: initialTabIndex,
        onAccept: onAccept,
      ),
    );
  }

  @override
  State<TermsPrivacyModal> createState() => _TermsPrivacyModalState();
}

class _TermsPrivacyModalState extends State<TermsPrivacyModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isKurdish = context.locale.languageCode == 'ckb';
    final isArabic = context.locale.languageCode == 'ar';

    return Container(
      height: size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Drag Handle ──
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Header ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: Color(0xFF2563EB),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'terms_and_privacy'.tr(),
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'last_updated'.tr(),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── Tab Bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 48,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: const Color(0xFF1D4ED8),
                unselectedLabelColor: const Color(0xFF64748B),
                labelStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: [
                  Tab(
                    iconMargin: EdgeInsets.zero,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.description_outlined, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'terms_of_service'.tr(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tab(
                    iconMargin: EdgeInsets.zero,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.privacy_tip_outlined, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'privacy_policy'.tr(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Tab Content ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTermsContent(isKurdish, isArabic),
                _buildPrivacyContent(isKurdish, isArabic),
              ],
            ),
          ),

          // ── Bottom Action Button ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onAccept?.call();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'i_agree_terms'.tr(),
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsContent(bool isKurdish, bool isArabic) {
    final List<Map<String, dynamic>> sections = isKurdish
        ? [
            {
              'icon': Icons.handshake_outlined,
              'title': '١. قبوڵکردنی مەرجەکان',
              'desc':
                  'بە بەکارهێنان و دروستکردنی هەژمار لە Dr. Room، تۆ ڕازی دەبیت بە سەرجەم مەرج و ڕێساکانی ئەم ڕێککەوتننامەیە. ئەگەر بە هەریەک لەم مەرجانە ڕازی نیت، تکایە ڕابوەستە لە بەکارهێنانی ئەپڵیکەیشنەکە.',
            },
            {
              'icon': Icons.medical_services_outlined,
              'title': '٢. خزمەتگوزارییە پزیشکییەکان',
              'desc':
                  'Dr. Room پلاتفۆرمێکی تەندروستی پێشکەوتووە بۆ ئاسانکاری نۆرەگرتن لای پزیشکان، داواکردنی دەرمان لە دەرمانخانەکان، ئەنجامدانی پشکنینی تاقیگە، و ڕاوێژی پزیشکی بە شێوەیەکی دیجیتاڵی.',
            },
            {
              'icon': Icons.warning_amber_rounded,
              'title': '٣. باری لەناکاو و فریاگوزاری',
              'desc':
                  'ئەم ئەپڵیکەیشنە جێگرەوەی فریاگوزاری خێرا و نەخۆشخانەی فریاکەوتن نییە. لە کاتی باری لەناکاو و مەترسیداردا، دەستبەجێ پەیوەندی بە هێڵی فریاکەوتن (١٢٢) یان نزیکترین فریاکەوتن بکە.',
            },
            {
              'icon': Icons.lock_person_outlined,
              'title': '٤. هەژماری بەکارهێنەر و پاراستن',
              'desc':
                  'بەکارهێنەر تەواو بەرپرسیارە لە پاراستنی زانیارییەکانی چوونەژوورەوە و وشەی نهێنی. هەر چالاکییەک لە ڕێگەی هەژمارەکەتەوە ئەنجام بدرێت، بە بەرپرسیارێتی تۆ لەقەڵەم دەدرێت.',
            },
            {
              'icon': Icons.payment_outlined,
              'title': '٥. پارەدان و هەڵوەشاندنەوەی نۆرە',
              'desc':
                  'تەواوی پرۆسەکانی پارەدان بە شێوازێکی پارێزراو ئەنجام دەدرێن. هەڵوەشاندنەوە یان دواخستنی نۆرە دەبێت بەپێی کات و مەرجی ڕێگەپێدراوی پزیشک و کلینیکەکە ئەنجام بدرێت.',
            },
            {
              'icon': Icons.sync_problem_outlined,
              'title': '٦. نوێکردنەوە و گۆڕانکاری مەرجەکان',
              'desc':
                  'مافی ئەوەمان پارێزراوە لە هەر کاتێکدا پێداچوونەوە و گۆڕانکاری لە مەرجەکانی خزمەتگوزاریدا بکەین بۆ باشترکردنی ئاستی خزمەتگوزارییەکان.',
            },
          ]
        : isArabic
            ? [
                {
                  'icon': Icons.handshake_outlined,
                  'title': '١. قبول الشروط',
                  'desc':
                      'باستخدامك وإنشاء حساب في تطبيق Dr. Room، فإنك توافق على الالتزام بجميع الشروط والأحكام المذكورة هنا.',
                },
                {
                  'icon': Icons.medical_services_outlined,
                  'title': '٢. الخدمات الطبية',
                  'desc':
                      'يوفر تطبيق Dr. Room منصة رقمية متكاملة لحجز المواعيد مع الأطباء، طلب الأدوية، التحاليل المخبرية والاستشارات الطبية.',
                },
                {
                  'icon': Icons.warning_amber_rounded,
                  'title': '٣. حالات الطوارئ الطبية',
                  'desc':
                      'التطبيق ليس بديلاً عن قسم الطوارئ في الحالات الحرجة. في حال الطوارئ، يرجى الاتصال بالإسعاف فوراً أو التوجه لأقرب مستشفى.',
                },
                {
                  'icon': Icons.lock_person_outlined,
                  'title': '٤. أمان الحساب',
                  'desc':
                      'أنت مسؤول عن الحفاظ على سرية معلومات حسابك وكلمة المرور وكافة الأنشطة التي تتم من خلاله.',
                },
                {
                  'icon': Icons.payment_outlined,
                  'title': '٥. الدفع وسياسة الإلغاء',
                  'desc':
                      'تتم المعاملات المالية عبر بوابات دفع آمنة ومشفرة، وتخضع سياسة إلغاء المواعيد للشروط المحددة لكل عيادة.',
                },
                {
                  'icon': Icons.sync_problem_outlined,
                  'title': '٦. تحديث الشروط',
                  'desc':
                      'نحتفظ بالحق في تحديث هذه الشروط في أي وقت لتحسين تجربة المستخدم وجودة الخدمة.',
                },
              ]
            : [
                {
                  'icon': Icons.handshake_outlined,
                  'title': '1. Acceptance of Terms',
                  'desc':
                      'By creating an account or using Dr. Room, you agree to comply with and be bound by these Terms of Service.',
                },
                {
                  'icon': Icons.medical_services_outlined,
                  'title': '2. Medical & Healthcare Services',
                  'desc':
                      'Dr. Room provides a digital health platform facilitating appointment booking, pharmacy delivery, lab requests, and virtual consultations.',
                },
                {
                  'icon': Icons.warning_amber_rounded,
                  'title': '3. Emergency Medical Disclaimer',
                  'desc':
                      'Dr. Room is not designed for life-threatening medical emergencies. In an emergency, immediately dial local emergency services or visit the nearest ER.',
                },
                {
                  'icon': Icons.lock_person_outlined,
                  'title': '4. User Account & Security',
                  'desc':
                      'You are responsible for safeguarding your login credentials and for all activities conducted under your account.',
                },
                {
                  'icon': Icons.payment_outlined,
                  'title': '5. Payments & Cancellations',
                  'desc':
                      'All transactions are processed securely. Cancellations and reschedules are subject to individual clinic policies.',
                },
                {
                  'icon': Icons.sync_problem_outlined,
                  'title': '6. Modifications to Terms',
                  'desc':
                      'We reserve the right to modify these terms at any time to improve app features and service reliability.',
                },
              ];

    return _buildSectionsList(sections);
  }

  Widget _buildPrivacyContent(bool isKurdish, bool isArabic) {
    final List<Map<String, dynamic>> sections = isKurdish
        ? [
            {
              'icon': Icons.person_search_outlined,
              'title': '١. ئەو زانیارییانەی کۆیان دەکەینەوە',
              'desc':
                  'زانیارییە سەرەتاییەکان (ناو، ژمارەی مۆبایل، ناونیشان) و تۆماری نۆرە و مێژووی دەرمان کە بە ویستی خۆت داخل دەکرێن بۆ باشترکردنی چاودێری تەندروستی.',
            },
            {
              'icon': Icons.security_rounded,
              'title': '٢. پاراستن و بەکۆدکردنی داتا',
              'desc':
                  'تەواوی زانیارییە پزیشکی و کەسییەکانت بە شێوازی پێشکەوتووی (AES-256 و SSL/TLS) بەکۆد دەکرێن و بەپێی بەرزترین ستانداردەکانی پاراستنی نهێنی پزیشکی پارێزراون.',
            },
            {
              'icon': Icons.insights_rounded,
              'title': '٣. چۆنیەتی بەکارهێنانی زانیاری',
              'desc':
                  'زانیارییەکانت تەنها بۆ تەواوکردنی خزمەتگوزارییەکانی وەک نۆرەگرتن، ئاگادارکردنەوە، و گەیاندنی دەرمان بەکاردەهێنرێن.',
            },
            {
              'icon': Icons.share_outlined,
              'title': '٤. هاوبەشکردن لەگەڵ لایەنی سێیەم',
              'desc':
                  'زانیارییەکانت بە هیچ شێوەیەک نافرۆشرێن و بازرگانییان پێوە ناکرێت. تەنها ئەو بەشەی پێویستە لەگەڵ پزیشکی دیاریکراو یان دەرمانخانە هاوبەش دەکرێت بۆ پێشکەشکردنی چارەسەر.',
            },
            {
              'icon': Icons.delete_outline_rounded,
              'title': '٥. مافی بەکارهێنەر و سڕینەوەی داتا',
              'desc':
                  'مافی تەواوت هەیە لە هەر ساتێکدا داوای دەستکاریکردن، وەرگرتنەوە، یان سڕینەوەی تەواوەتی هەژمار و مێژووی زانیارییەکانت بکەیت.',
            },
            {
              'icon': Icons.headset_mic_outlined,
              'title': '٦. پەیوەندی و پرسیاری تایبەتمەندی',
              'desc':
                  'بۆ هەر پرسیار یان تێبینییەک لەسەر سیاسەتی تایبەتمەندی و ئاسایشی زانیارییەکانت، دەتوانیت لە ڕێگەی بەشی پشتیوانی ڕاستەوخۆ پەیوەندیمان پێوە بکەیت.',
            },
          ]
        : isArabic
            ? [
                {
                  'icon': Icons.person_search_outlined,
                  'title': '١. المعلومات التي نجمعها',
                  'desc':
                      'نجمع البيانات الأساسية (الاسم، رقم الهاتف، العنوان) وتاريخ الحجوزات الطبية لتقديم الرعاية الصحية المثالية لك.',
                },
                {
                  'icon': Icons.security_rounded,
                  'title': '٢. حماية وتشفير البيانات',
                  'desc':
                      'جميع البيانات مشفرة باستخدام أعلى معايير التشفير (AES-256 و SSL) لضمان الخصوصية والسرية التامة.',
                },
                {
                  'icon': Icons.insights_rounded,
                  'title': '٣. كيفية استخدام البيانات',
                  'desc':
                      'تُستخدم المعلومات لجدولة المواعيد، وإرسال التنبيهات الصحية، وتوصيل الأدوية بدقة.',
                },
                {
                  'icon': Icons.share_outlined,
                  'title': '٤. عدم مشاركة البيانات',
                  'desc':
                      'لا نقوم ببيع بياناتك لأي طرف ثالث مطلقاً. يتم مشاركة المعلومات الضرورية فقط مع الطبيب أو الصيدلية المعنية.',
                },
                {
                  'icon': Icons.delete_outline_rounded,
                  'title': '٥. حقوقك وحذف الحساب',
                  'desc':
                      'يحق لك في أي وقت طلب تعديل أو حذف بياناتك وسجلاتك الشخصية بالكامل من نظامنا.',
                },
                {
                  'icon': Icons.headset_mic_outlined,
                  'title': '٦. التواصل والدعم',
                  'desc':
                      'إذا كان لديك أي استفسار حول خصوصيتك، يسعدنا تواصلك مع فريق الدعم الفني عبر التطبيق.',
                },
              ]
            : [
                {
                  'icon': Icons.person_search_outlined,
                  'title': '1. Information We Collect',
                  'desc':
                      'We collect basic profile info (name, phone, address) and health/appointment records you provide to deliver medical services.',
                },
                {
                  'icon': Icons.security_rounded,
                  'title': '2. Data Security & Encryption',
                  'desc':
                      'All medical data is protected using state-of-the-art AES-256 and SSL/TLS encryption adhering to healthcare compliance standards.',
                },
                {
                  'icon': Icons.insights_rounded,
                  'title': '3. How We Use Information',
                  'desc':
                      'Your data is utilized solely for facilitating doctor appointments, medication delivery, reminders, and patient support.',
                },
                {
                  'icon': Icons.share_outlined,
                  'title': '4. Third-Party Sharing',
                  'desc':
                      'We never sell or monetize your personal data. Relevant details are only shared with your assigned doctor or pharmacy.',
                },
                {
                  'icon': Icons.delete_outline_rounded,
                  'title': '5. Your Rights & Account Deletion',
                  'desc':
                      'You retain full rights to inspect, export, or permanently delete your account and personal records at any time.',
                },
                {
                  'icon': Icons.headset_mic_outlined,
                  'title': '6. Contact & Privacy Support',
                  'desc':
                      'For any inquiries regarding data protection, please reach out directly via our in-app Help & Support center.',
                },
              ];

    return _buildSectionsList(sections);
  }

  Widget _buildSectionsList(List<Map<String, dynamic>> sections) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: sections.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = sections[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item['icon'] as IconData,
                  size: 20,
                  color: const Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['desc'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
