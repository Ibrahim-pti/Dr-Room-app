import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/utils/api_client.dart';
import 'first_aid_detail_screen.dart';

class FirstAidScreen extends StatefulWidget {
  const FirstAidScreen({super.key});

  @override
  State<FirstAidScreen> createState() => _FirstAidScreenState();
}

class _FirstAidScreenState extends State<FirstAidScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'هەمووی';
  bool _isLoading = false;
  List<FirstAidTopic> _apiTopics = [];

  @override
  void initState() {
    super.initState();
    _fetchTopicsFromApi();
  }

  Future<void> _fetchTopicsFromApi() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiClient.get('/articles');
      if (res.statusCode == 200 && mounted) {
        final List list = jsonDecode(res.body);
        final parsed = list.map((item) {
          final cat = item['category'] ?? 'گشتی';
          Color col = const Color(0xFF2563EB);
          IconData ico = Icons.medical_services_rounded;
          if (cat.contains('هەناسە') || cat.contains('خوێن')) {
            col = const Color(0xFFEF4444);
            ico = Icons.air;
          } else if (cat.contains('پێست') || cat.contains('برین') || cat.contains('سووتان')) {
            col = const Color(0xFFF97316);
            ico = Icons.local_fire_department;
          } else if (cat.contains('دڵ')) {
            col = const Color(0xFFDC2626);
            ico = Icons.favorite_rounded;
          } else if (cat.contains('ئێسک') || cat.contains('شکان')) {
            col = const Color(0xFF8B5CF6);
            ico = Icons.accessibility_new_rounded;
          }

          final symptoms = _stringList(item['symptoms']);
          final dos = _stringList(item['dos']);
          final donts = _stringList(item['donts']);

          var steps = _rawList(item['steps']).map((st) {
            if (st is Map) {
              final title = (st['title'] ?? '').toString().trim();
              final desc = (st['desc'] ?? '').toString().trim();
              return {'title': title.isNotEmpty ? title : 'هەنگاو', 'desc': desc};
            }
            return {'title': 'هەنگاو', 'desc': st.toString()};
          }).where((st) => (st['desc'] as String).isNotEmpty || st['title'] != 'هەنگاو').toList();

          // Fall back to the free-text content when no structured steps were entered.
          if (steps.isEmpty && item['content'] != null && item['content'].toString().trim().isNotEmpty) {
            steps = [{'title': 'ڕێنمایی چارەسەر', 'desc': item['content'].toString()}];
          }

          return FirstAidTopic(
            id: item['id'].toString(),
            title: item['title'] ?? '',
            category: cat,
            shortDesc: _shortDesc(item),
            icon: ico,
            color: col,
            symptoms: symptoms,
            steps: steps,
            dos: dos,
            donts: donts,
            whenToCallAmbulance: (item['when_to_call_ambulance']?.toString().trim().isNotEmpty ?? false)
                ? item['when_to_call_ambulance'].toString()
                : 'لە کاتی باری لەناکاودا دەستبەجێ پەیوەندی بە ١٢٢ بکە.',
          );
        }).toList();

        if (parsed.isNotEmpty) {
          setState(() {
            _apiTopics = parsed;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching first aid topics: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  /// Laravel casts these to arrays, but a record written before the cast
  /// existed can still come back as a raw JSON string.
  List<dynamic> _rawList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) return decoded;
      } catch (_) {}
    }
    return [];
  }

  List<String> _stringList(dynamic raw) {
    return _rawList(raw)
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  String _shortDesc(dynamic item) {
    final short = (item['short_desc'] ?? '').toString().trim();
    if (short.isNotEmpty) return short;

    final content = (item['content'] ?? '').toString().trim();
    if (content.length <= 120) return content;
    return '${content.substring(0, 120).trimRight()}…';
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

  final List<FirstAidTopic> _allTopics = [
    const FirstAidTopic(
      id: 'choking',
      title: 'خنکان و گیرانی قوڕگ',
      category: 'هەناسەدان',
      shortDesc: 'فێربوونی شێوازی هێملیک (Heimlich) بۆ دەرهێنانی تەن لە قوڕگی گەورە و مناڵ',
      icon: Icons.air,
      color: Color(0xFFEF4444),
      symptoms: [
        'دەستبردن بۆ قوڕگ و نەتوانینی قسەکردن',
        'شینبوونی لێو و دەموچاو',
        'دەنگی بەرزی فیکە لە کاتی هەناسەدان',
      ],
      steps: [
        {
          'title': 'هاندانی بۆ کۆکین',
          'desc': 'ئەگەر دەتوانێت بکۆکێت، هانی بدە با بەهێز بکۆکێت تا شتەکە دێتە دەرەوە.',
        },
        {
          'title': '٥ لێدانی بەهێز لە نێوان دوو شانی پشت',
          'desc': 'لە پشتی کەسەکە بوەستە، کەمێک بە لاری دایبنێ و ٥ جار بە کفی دەستت لە نێوان شانەکانی بدە.',
        },
        {
          'title': 'ڕێگای هێملیک (Heimlich Maneuver)',
          'desc': 'دەستت بکە بە مست و لە سەرووی ناوکی دابنێ، بە دەستەکەی ترت بیگرە و بە خێرایی بەرەو ژوورەوە و سەرەوە ڕابکێشە.',
        },
      ],
      dos: [
        'ئارام بە و دڵنیای بکەرەوە',
        'بۆ مناڵی ساوا، لەسەر باڵت دایبنێ و بە پەنجە لە پشتی بدە',
        'ئەگەر بێهۆش بوو، ڕاستەوخۆ دەست بە بوژانەوەی دڵ (CPR) بکە',
      ],
      donts: [
        'پەنجەت مەکەرە ناو دەمی کەسەکە ئەگەر تەنەکە نەبینیت (زیاتر دەیباتە خوارەوە)',
        'ئاو یان شلە مەدە بە کەسێک کە دەخنکێت',
      ],
      whenToCallAmbulance: 'ئەگەر دوای چەند چرکەیەک تەنەکە دەرنەهات یان کەسەکە بێهۆش بوو، دەستبەجێ پەیوەندی بە ١٢٢ بکە.',
    ),
    const FirstAidTopic(
      id: 'burns',
      title: 'سووتان و کڕانەوە',
      category: 'پێست و برین',
      shortDesc: 'چارەسەری سووتانی پلە ١، ٢ و ٣ و هەنگاوە دروستەکانی ساردکردنەوەی برین',
      icon: Icons.local_fire_department,
      color: Color(0xFFF97316),
      symptoms: [
        'سووربوونەوەی زۆری پێست و ئازاری توند',
        'دروستبوونی بڵقی ئاو لەسەر پێست (پلە ٢)',
        'ڕەشبوونەوە یان سپیبوونی بێئازاری پێست (پلە ٣ی سەخت)',
      ],
      steps: [
        {
          'title': 'ساردکردنەوە بە ئاوی شیرەتین',
          'desc': 'دەستبەجێ ئاوی ساردی شیرەتین (نەک سەهۆڵ) بۆ ماوەی ١٥ تا ٢٠ خولەک بەسەر برینەکەدا بڕێژە.',
        },
        {
          'title': 'داپۆشینی بە نایلۆن یان شاشی پاک',
          'desc': 'برینەکە بە نایلۆنی خاوێنی خواردن یان قوماشێکی تەڕی پاک داپۆشە تا هەوا و بەکتریا لێی نەدات.',
        },
        {
          'title': 'لێکردنەوەی خشڵ و کاتژمێر',
          'desc': 'پێش ئەوەی شوێنەکە بئاوسێت، بە وریایی دەستبەند و ئەڵقە لە دەستی لێبکەرەوە.',
        },
      ],
      dos: [
        'برینەکە بە ئاوی خاوێن و سارد بشۆ',
        'ئازارشکێنی سادە (وەک پاراسیتامۆڵ)ی پێبدە',
      ],
      donts: [
        'مەعجوونی ددان، ڕۆن، یان تەماتە بە هیچ شێوەیەک لە برین مەدە',
        'بڵقەکانی ئاوی پێست مەپەقێنە (ڕێگری لە هەوکردن دەکەن)',
        'جلوبەرگی بە پێستەوە چەسپاو بە زۆر لێمەکەرەوە',
      ],
      whenToCallAmbulance: 'ئەگەر سووتانەکە ڕووبەری لە دەستی زیاتر بوو، یان لە دەموچاو و ئەندامە هەستیارەکان بوو، یان سووتانی کارەبا و کیمیایی بوو.',
    ),
    const FirstAidTopic(
      id: 'heart_stroke',
      title: 'جەڵتەی دڵ و مێشک (FAST)',
      category: 'دڵ و دەمار',
      shortDesc: 'ناسینەوەی خێرای نیشانەکانی جەڵتەی مێشک بە یاسای FAST و فریاکەوتنی جەڵتەی دڵ',
      icon: Icons.favorite,
      color: Color(0xFFDC2626),
      symptoms: [
        'ئازاری توندی سنگ کە دەچێتە شانی چەپ و چەناگە',
        'خواربوونی دەم و لاری دەموچاو (Face drooping)',
        'نەتوانینی بەرزکردنەوەی هەردوو دەست (Arm weakness)',
        'تێکچوونی قسەکردن و زمانگرتن (Speech difficulty)',
      ],
      steps: [
        {
          'title': 'داوای یارمەتی لە ١٢٢ دەستبەجێ',
          'desc': 'هەموو چرکەیەک گرنگە! ڕاستەوخۆ پەیوەندی بە فریاکەوتنی ١٢٢ بکە.',
        },
        {
          'title': 'دانانی نەخۆش لە شوێنێکی ئارام',
          'desc': 'نەخۆش بە دانیشتنەوە دابنێ و پشتی ڕابگرە، با بە هیچ شێوەیەک نەجوڵێت و هەناسەی قووڵ بدات.',
        },
        {
          'title': 'حەبی ئەسپرین (بۆ جەڵتەی دڵ)',
          'desc': 'ئەگەر نەخۆش حەساسیەتی بە ئەسپرین نییە، ٣٠٠ ملگم حەبی ئەسپرین بجوێت (ئەگەر هۆشی هەبێت).',
        },
      ],
      dos: [
        'کاتی دەرکەوتنی نیشانەکان بە وردی تۆمار بکە',
        'جلوبەرگی تەنگی سەرسنگ و ملی شل بکەرەوە',
      ],
      donts: [
        'مەهێڵە بە پێ بڕوات یان شۆفێری بکات',
        'ئاو یان خۆراکی پێمەدە لە کاتی گومانی جەڵتەی مێشکدا',
      ],
      whenToCallAmbulance: 'دەستبەجێ لە یەکەم چرکەی دەرکەوتنی نیشانەکاندا.',
    ),
    const FirstAidTopic(
      id: 'bites',
      title: 'پێوەدانی دووپشک و مار',
      category: 'ژەهراویبوون',
      shortDesc: 'ڕێوشوێنی پاراستنی ژیان لە کاتی پێوەدانی دووپشک و ماری ژەهراوی لە ماڵ و دەرەوە',
      icon: Icons.bug_report,
      color: Color(0xFF8B5CF6),
      symptoms: [
        'ئازاری زۆر توند و ئاوسانی شوێنی پێوەدانەکە',
        'ئارەقەکردنەوە، دڵتێکەڵهاتن، و لێدانی خێرای دڵ',
        'سڕبوونی دەم و لێوەکان و تەنگەنەفەسی',
      ],
      steps: [
        {
          'title': 'هێمنکردنەوەی بریندارەکە',
          'desc': 'با بریندار نەجوڵێت و ڕانەکات، چونکە لێدانی دڵ خێرا دەبێت و ژەهرەکە زووتر بڵاودەبێتەوە.',
        },
        {
          'title': 'شوێنی پێوەدان لە ئاستی دڵ نزمتر دابنێ',
          'desc': 'ئەندامە بریندارەکە بە نەجوڵاوی بهێڵەرەوە و کاتژمێر و ئەڵقەی لێبکەرەوە.',
        },
        {
          'title': 'شۆردنی بە ئاو و سابوون',
          'desc': 'شوێنی برینەکە بە هێواشی بە ئاو و سابوون بشۆ و بە قوماشێکی پاک دایپۆشە.',
        },
      ],
      dos: [
        'وێنەی دووپشکەکە یان مارەکە بگرە ئەگەر مەترسیدار نەبوو (بۆ ئەوەی دژەژەهری گونجاو بدەن)',
        'دەستبەجێ بیگەینە نزیکترین نەخۆشخانەی فریاکەوتن',
      ],
      donts: [
        'برینەکە مەبڕە و بە دەم ژەهرەکە مەمژە!',
        'بە توندی پەستێنەر (Tourniquet) مەبەستە کە خوێن بوەستێنێت',
        'سەهۆڵ یان ئاگری لێمەدە',
      ],
      whenToCallAmbulance: 'لە هەموو حاڵەتەکانی پێوەدانی دووپشک و مار دەبێت دەستبەجێ بچیتە فریاکەوتن بۆ لێدانی شرومی دژەژەهر.',
    ),
    const FirstAidTopic(
      id: 'fainting',
      title: 'بێهۆشبوون و لەهۆشچوون',
      category: 'هۆشیاری',
      shortDesc: 'چۆنیەتی هەڵسوکەوت لەگەڵ کەسێک کە لەپڕ لەهۆش خۆی دەچێت یان سەری دەسوڕێت',
      icon: Icons.airline_seat_flat,
      color: Color(0xFF06B6D4),
      symptoms: [
        'سپیبوونی لەپڕی دەموچاو و ئارەقەی سارد',
        'کەوتنە سەر زەوی و وەڵامنەدانەوە',
        'لێدانی کزی پەستانی خوێن',
      ],
      steps: [
        {
          'title': 'پاڵخستن و بەرزکردنەوەی قاچەکان',
          'desc': 'کەسەکە لەسەر پشت پاڵبخە و قاچەکانی نزیکەی ٣٠ سم بەرز بکەرەوە تا خوێن بۆ مێشک بگەڕێتەوە.',
        },
        {
          'title': 'پشکنینی هەناسەدان',
          'desc': 'سەیری سنگی بکە و گوێت لە دەمی بێت بۆ دڵنیابوونەوە لە هەبوونی هەناسەدان.',
        },
        {
          'title': 'دۆخی چاکبوونەوە (Recovery Position)',
          'desc': 'ئەگەر هۆشی نەبوو بەڵام هەناسەی هەبوو، لەسەر تەنیشت ڕایبکێشە بۆ ئەوەی زمان و لیکی دەمی ڕێگەی هەناسە نەگرێت.',
        },
      ],
      dos: [
        'هەوای پاکی بۆ دابین بکە و خەڵکی لێ دووربخەرەوە',
        'دوای هۆش هاتنەوە، کەمێک ئاو و شەربەتی پێبدە',
      ],
      donts: [
        'ئاو بە دەموچاویدا مەکە و ڕامەوەشێنە',
        'ڕاستەوخۆ بەپێوەی مەهێڵەرەوە با دووبارە نەکەوێت',
      ],
      whenToCallAmbulance: 'ئەگەر بێهۆشبوونەکە زیاتر لە ٢ خولەکی خایاند یان لە کاتی کەوتندا سەری بەر شتێکی ڕەق کەوت.',
    ),
    const FirstAidTopic(
      id: 'bleeding',
      title: 'خوێنبەربوونی سەخت و برینداری',
      category: 'پێست و برین',
      shortDesc: 'ڕاگرتنی خوێنبەربوونی خوێنبەر و خوێنهێنەرەکان بە پەستانی بەهێز',
      icon: Icons.water_drop,
      color: Color(0xFFE11D48),
      symptoms: [
        'فڕێدانی خوێن بە شێوازی فیشقی یان خوێنبەربوونی بەردەوام',
        'گێژبوون و ساردیی دەست و پێیەکان',
      ],
      steps: [
        {
          'title': 'پەستانی ڕاستەوخۆ لەسەر برینەکە',
          'desc': 'بە قوماشێکی پاک یان شاش بە توندی دەست بنێ بە سەر برینەکە بۆ ماوەی ٥ بۆ ١٠ خولەک.',
        },
        {
          'title': 'بەرزکردنەوەی ئەندامە بریندارەکە',
          'desc': 'دەست یان قاچی بریندار لە ئاستی دڵ بەرزتر ڕابگرە بۆ کەمکردنەوەی لێشاوی خوێن.',
        },
        {
          'title': 'بەستنی بە باندیج',
          'desc': 'قوماشێکی تر لەسەر قوماشی یەکەم بئاڵێنە (قوماشی یەکەم لێمەکەرەوە تا خوێنەکە مەیینەکەی تێکنەچێت).',
        },
      ],
      dos: [
        'دەستکێشی پاک لەدەست بکە ئەگەر بەردەست بوو',
        'بریندارەکە دابپۆشە تا جەستەی سارد نەبێتەوە',
      ],
      donts: [
        'تەنی ناو برین (وەک شوشە یان چەقۆ) بە هیچ جۆرێک لە برین دەرمەهێنە!',
        'قوماشی خوێناوی لێمەکەرەوە، قوماشی تر بخەرە سەری',
      ],
      whenToCallAmbulance: 'ئەگەر خوێنبەربوونەکە دوای ١٠ خولەک لە پەستان ڕانەوەستا یان کەسەکە ڕەنگی سپی بوو.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final activeTopics = _apiTopics.isNotEmpty ? _apiTopics : _allTopics;
    final filteredTopics = activeTopics.where((topic) {
      final matchesSearch = topic.title.contains(_searchController.text.trim()) ||
          topic.shortDesc.contains(_searchController.text.trim());
      final matchesCategory = _selectedCategory == 'هەمووی' || topic.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'ڕێبەری فریاگوزاریی سەرەتایی',
          style: _kStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTopicsFromApi,
        color: const Color(0xFF2563EB),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(
                    color: Color(0xFF2563EB),
                    backgroundColor: Color(0xFFEFF6FF),
                  ),
                ),
              // Search Bar
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.search_normal_1, color: Color(0xFF94A3B8), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() {}),
                      style: _kStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'گەڕان بۆ حاڵەت (وەک: خنکان، سووتان، مار)...',
                        hintStyle: _kStyle(color: const Color(0xFF94A3B8), fontSize: 13),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.05, end: 0),

            const SizedBox(height: 16),

            // Category Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: ['هەمووی', 'هەناسەدان', 'پێست و برین', 'دڵ و دەمار', 'ژەهراویبوون', 'هۆشیاری'].map((cat) {
                  final isSel = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: ChoiceChip(
                      label: Text(
                        cat,
                        style: _kStyle(
                          color: isSel ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      selected: isSel,
                      selectedColor: const Color(0xFF3B82F6),
                      backgroundColor: cardBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: isSel ? const Color(0xFF3B82F6) : borderColor),
                      ),
                      onSelected: (val) => setState(() => _selectedCategory = cat),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'حاڵەتە لەناکاو و فریاگوزارییەکان',
              style: _kStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),

            ...List.generate(filteredTopics.length, (index) {
              final topic = filteredTopics[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FirstAidDetailScreen(topic: topic),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: topic.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(topic.icon, color: topic.color, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    topic.title,
                                    style: _kStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 90),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: topic.color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      topic.category,
                                      style: _kStyle(
                                        color: topic.color,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              topic.shortDesc,
                              style: _kStyle(
                                fontSize: 12,
                                color: const Color(0xFF94A3B8),
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Iconsax.arrow_left_2,
                        color: Color(0xFF94A3B8),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: (index * 60).ms).slideY(begin: 0.05, end: 0);
            }),
          ],
        ),
      ),
    ),
  );
}
}
