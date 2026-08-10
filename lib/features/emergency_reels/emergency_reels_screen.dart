import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/api_client.dart';

class EmergencyReelsScreen extends StatefulWidget {
  const EmergencyReelsScreen({super.key});

  @override
  State<EmergencyReelsScreen> createState() => _EmergencyReelsScreenState();
}

class _EmergencyReelsScreenState extends State<EmergencyReelsScreen> {
  List<dynamic> _articles = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'all';
  final Set<String> _bookmarkedIds = {};

  final TextEditingController _searchController = TextEditingController();

  // Presets / Fallback medical guides if admin has not posted articles or server is offline
  final List<Map<String, dynamic>> _fallbackArticles = [
    {
      'id': 'fb-1',
      'title': 'ڕێنماییە سەرەتاییەکانی فریاکەوتنی CPR بۆ وەستانی دڵ',
      'title_en': 'First Aid CPR Guidelines for Cardiac Arrest',
      'title_ar': 'دليل الإسعافات الأولية للإنعاش قلبي رئوي (CPR)',
      'category': 'فریاکەوتن',
      'category_key': 'first_aid',
      'content':
          '''کاتێک کەسێک لەناکاو دەکەوێت و هەناسەدانی دەوەستێت، ئەنجامدانی فریاکەوتنی خێرا (CPR) دەتوانێت ژیانی ڕزگار بکات.

١. بەپەلە پەیوەندی بە ژمارەی فریاکەوتنی پزیشکی (122) بکە.
٢. نەخۆشەکە لەسەر پشتی بە تەختی دابنێ.
٣. دەستت بخەرە سەر ناوەڕاستی سنگ، بەردەوام و بە خێرایی (١٠٠-١٢٠ جار لە خولەکێکدا) پەستاوتنی سنگ ئەنجام بدە.
٤. قووڵی پەستاوتنەکە با نزیکەی ٥ سم بێت.
٥. تا گەیشتنی تیمی پزیشکی یان ژیانەوەی نەخۆشەکە بەردەوام بە.

تێبینی: ئەگەر ڕاهێنراو نیت لە هەناسەی دەستکرد، تەنها پەستاوتنی سنگ بەسە.''',
      'image_url':
          'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=800&q=80',
      'author': 'ئادمینی گشتی - Dr. Room',
      'created_at': '2026-08-01',
      'is_admin_post': true,
    },
    {
      'id': 'fb-2',
      'title': 'نیشانە سەرەتاییەکانی جەڵتەی دڵ و ڕێکارە فریاگوزارییەکان',
      'title_en': 'Early Symptoms of Heart Attack and Emergency Measures',
      'title_ar': 'الأعراض المبكرة للنوبة القلبية والإجراءات الطارئة',
      'category': 'نیشانەکان',
      'category_key': 'symptoms',
      'content':
          '''جەڵتەی دڵ یەکێکە لە حاڵەتە کتوپڕەکان کە پێویستی بە وەڵامدانەوەی خێرا هەیە.

نیشانە سەرەتاییەکان:
• ئازار و پەستانی توند لە ناوەڕاستی سنگ یان لای چەپ.
• ئازارێک کە بەرەو قۆڵی چەپ، مل، پشت یان فەک دەڕوات.
• هەناسەتەنگی و ئارەقکردنەوەی سارد.
• گێژبوون یان دڵتێکچوون.

ڕێکارە فریاگوزارییەکان:
١. بەپەلە داوای ئامبوڵانس بکە.
٢. نەخۆشەکە لە شوێنێکی ئارام دابنیشێنە یان پاڵی بخەرەوە.
٣. جلوبەرگی تەنگ خاو بکەرەوە بۆ ئاسانکاری لە هەناسەدان.
٤. ڕێگەی مەدە نەخۆشەکە جوڵەی زۆر بکات.''',
      'image_url':
          'https://images.unsplash.com/photo-1628348068343-c6a848d2b6dd?w=800&q=80',
      'author': 'ئادمینی گشتی - Dr. Room',
      'created_at': '2026-07-30',
      'is_admin_post': true,
    },
    {
      'id': 'fb-3',
      'title': 'چۆنیەتی مامەڵەکردن لەگەڵ سووتانی پلە یەک و دوو',
      'title_en': 'How to Treat First and Second-Degree Burns',
      'title_ar': 'كيفية التعامل مع الحروق من الدرجة الأولى والثانية',
      'category': 'فریاکەوتن',
      'category_key': 'first_aid',
      'content': '''لە کاتی زیانگەیشتن بە پێست بەهۆی سووتانەوە:

چی بکەیت؟
١. بۆ ماوەی ١٠ تا ١٥ خولەک ئاوی ئاسایی (شیلەتێن یان سارد، بەڵام نە سەهۆڵ) بەسەر شوێنی سووتاوییەکەدا برژێنە.
٢. هەر جۆرە ئەڵقە یان کاتژمێرێک لە شوێنی سووتاوییەکە نزیک بێت لایبە پێش ئەوەی هەڵبئاوسێت.
٣. بە گازێکی خاوێن یان پەڕۆیەکی شێدار و خاوێن شوێنەکە داپۆشە.

چی نەکەیت؟
- سەهۆڵی ڕاستەوخۆ مەخەرە سەر برینەکە.
- خەمیرە، ڕۆن، یان مەعجونی ددان لێمەدە.
- قڵپکردنی پەقپەقەی سووتاوییەکە مەشکێنە.''',
      'image_url':
          'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?w=800&q=80',
      'author': 'ئادمینی گشتی - Dr. Room',
      'created_at': '2026-07-28',
      'is_admin_post': true,
    },
    {
      'id': 'fb-4',
      'title': 'ڕێنمایی کۆنتڕۆڵکردنی خوێنربوونی توند لە کاتی برینداربوون',
      'title_en': 'Severe Bleeding Control & Wound First Aid',
      'title_ar': 'دليل التحكم في النزيف الحاد والإسعافات الأولية',
      'category': 'خۆپارێزی',
      'category_key': 'prevention',
      'content':
          '''خوێنربوونی توند پێویستی بە هەنگاوی بەپەلە هەیە بۆ ڕێگریکردن لە شوکی خوێنربوون.

هەنگاوەکانی فریاکەوتن:
١. پارچە پەڕۆیەکی خاوێن یان گازی پزیشکی بپەستێنە سەر شوێنی برینەکە.
٢. پەستانەکە بە بەردەوامی و بێ پچڕان ڕابگرە بۆ ماوەی ٥-١٠ خولەک.
٣. ئەگەر بەردەست بوو، ئەندامی برینداربوو بەرزتر بکەرەوە لە ئاستی دڵ.
٤. بپێچەرەوە و پەیوەندی بە تیمی فریاکەوتنەوە بکە.''',
      'image_url':
          'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=800&q=80',
      'author': 'ئادمینی گشتی - Dr. Room',
      'created_at': '2026-07-25',
      'is_admin_post': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchArticles();
  }

  Future<void> _fetchArticles() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient.get('/articles');
      if (response.statusCode == 200 && mounted) {
        final List<dynamic> data = jsonDecode(response.body);

        final List<Map<String, dynamic>> apiArticles = data.map((item) {
          String? imgUrl = item['image_path'];
          if (imgUrl != null && imgUrl.isNotEmpty) {
            if (!imgUrl.startsWith('http')) {
              imgUrl = '${ApiClient.storageUrl}/$imgUrl';
            }
          }

          return {
            'id': item['id']?.toString() ?? UniqueKey().toString(),
            'title': item['title'] ?? item['title_en'] ?? 'زانیاری پزیشکی',
            'title_en': item['title_en'] ?? '',
            'title_ar': item['title_ar'] ?? '',
            'content': item['content'] ?? item['content_en'] ?? '',
            'content_en': item['content_en'] ?? '',
            'content_ar': item['content_ar'] ?? '',
            'category': 'ئادمینی گشتی',
            'image_url': imgUrl,
            'author': 'ئادمینی گشتی - Dr. Room',
            'created_at':
                item['created_at']?.toString().split('T').first ?? '2026-08-01',
            'is_admin_post': true,
          };
        }).toList();

        setState(() {
          _articles = [...apiArticles, ..._fallbackArticles];
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _articles = List.from(_fallbackArticles);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching articles from Admin API: $e');
      if (mounted) {
        setState(() {
          _articles = List.from(_fallbackArticles);
          _isLoading = false;
        });
      }
    }
  }

  List<dynamic> get _filteredArticles {
    return _articles.where((article) {
      final title = (article['title'] ?? '').toString().toLowerCase();
      final content = (article['content'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      final matchesQuery =
          query.isEmpty || title.contains(query) || content.contains(query);

      if (_selectedCategory == 'all') return matchesQuery;
      if (_selectedCategory == 'bookmarked')
        return matchesQuery && _bookmarkedIds.contains(article['id']);

      final category = (article['category'] ?? '').toString();
      return matchesQuery &&
          (category.contains(_selectedCategory) ||
              article['category_key'] == _selectedCategory);
    }).toList();
  }

  int _calculateReadingTime(String text) {
    final words = text.trim().split(RegExp(r'\s+')).length;
    final minutes = (words / 150).ceil();
    return minutes < 1 ? 1 : minutes;
  }

  void _toggleBookmark(String id) {
    setState(() {
      if (_bookmarkedIds.contains(id)) {
        _bookmarkedIds.remove(id);
      } else {
        _bookmarkedIds.add(id);
      }
    });
  }

  void _shareArticle(Map<String, dynamic> article) {
    final String shareText =
        "${article['title']}\n\n"
        "${article['content']}\n\n"
        "لە ئەپڵیکەیشنی Dr. Room دەستت دەکەوێت";
    SharePlus.instance.share(ShareParams(text: shareText));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredArticles;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getBackground(context),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'زانیاری و ڕێنمایی پزیشکی',
          style: GoogleFonts.poppins(
            color: AppColors.getTextTitle(context),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchArticles,
          color: AppColors.primary,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Top Header Bar & Search
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Search Box
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.getSurface(context),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.getBorder(context),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.2 : 0.04,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                          style: GoogleFonts.poppins(
                            color: AppColors.getTextTitle(context),
                            fontSize: 14,
                          ),
                          decoration: InputDecoration(
                            hintText: 'گەڕان بۆ بابەت یان نیشانەی پزیشکی...',
                            hintStyle: GoogleFonts.poppins(
                              color: AppColors.getTextSubtitle(context),
                              fontSize: 13,
                            ),
                            prefixIcon: const Icon(
                              Iconsax.search_normal_1,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category Chips Filter
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: Row(
                          children: [
                            _buildCategoryChip('all', 'هەمووی', Iconsax.grid_5),
                            const SizedBox(width: 8),
                            _buildCategoryChip(
                              'first_aid',
                              'فریاکەوتن',
                              Iconsax.hospital,
                            ),
                            const SizedBox(width: 8),
                            _buildCategoryChip(
                              'symptoms',
                              'نیشانەکان',
                              Iconsax.activity,
                            ),
                            const SizedBox(width: 8),
                            _buildCategoryChip(
                              'prevention',
                              'خۆپارێزی',
                              Iconsax.shield_tick,
                            ),
                            const SizedBox(width: 8),
                            _buildCategoryChip(
                              'bookmarked',
                              'نیشانەکراوەکان',
                              Iconsax.archive_book,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Loading State
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                )
              // Empty State
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Iconsax.document_text,
                            size: 48,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'هیچ زانیارییەک نەدۆزرایەوە',
                          style: GoogleFonts.poppins(
                            color: AppColors.getTextTitle(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'تکایە دڵنیابەوە لە گەڕانەکەت یان بەشی تری پۆلەکان دیاری بکە',
                          style: GoogleFonts.poppins(
                            color: AppColors.getTextSubtitle(context),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // Spotlight / Hero Article Banner (First Item)
                if (_searchQuery.isEmpty &&
                    _selectedCategory == 'all' &&
                    filtered.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: _buildHeroArticleCard(filtered.first),
                    ),
                  ),
                ],

                // Grid / List of Medical Articles
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final actualIndex =
                            (_searchQuery.isEmpty && _selectedCategory == 'all')
                            ? index + 1
                            : index;

                        if (actualIndex >= filtered.length)
                          return const SizedBox.shrink();
                        final article = filtered[actualIndex];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildArticleCard(article, index)
                              .animate()
                              .fade(duration: 350.ms, delay: (index * 50).ms)
                              .slideY(begin: 0.1, end: 0, duration: 350.ms),
                        );
                      },
                      childCount:
                          (_searchQuery.isEmpty && _selectedCategory == 'all')
                          ? (filtered.length > 1 ? filtered.length - 1 : 0)
                          : filtered.length,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String id, String label, IconData icon) {
    final isSelected = _selectedCategory == id;

    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.getBorder(context),
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected
                  ? Colors.white
                  : AppColors.getTextSubtitle(context),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected
                    ? Colors.white
                    : AppColors.getTextTitle(context),
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroArticleCard(Map<String, dynamic> article) {
    final String id = article['id'];
    final bool isBookmarked = _bookmarkedIds.contains(id);
    final String? imgUrl = article['image_url'];
    final int readTime = _calculateReadingTime(article['content'] ?? '');

    return GestureDetector(
      onTap: () => _openArticleDetail(article),
      child: Container(
        height: 220,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            if (imgUrl != null && imgUrl.isNotEmpty)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: CachedNetworkImage(
                    imageUrl: imgUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => const SizedBox(),
                  ),
                ),
              ),

            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.85),
                    ],
                  ),
                ),
              ),
            ),

            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Iconsax.star_1,
                                color: Colors.amber,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'پێشنیارکراوی ئادمین',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => _toggleBookmark(id),
                          icon: Icon(
                            isBookmarked
                                ? Iconsax.archive_tick
                                : Iconsax.archive_book,
                            color: isBookmarked ? Colors.amber : Colors.white,
                            size: 22,
                          ),
                        ),
                      ],
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article['title'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Iconsax.clock,
                              color: Colors.white70,
                              size: 13,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$readTime خولەک خوێندنەوە',
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'خوێندنەوە',
                                    style: GoogleFonts.poppins(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: AppColors.primary,
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleCard(Map<String, dynamic> article, int index) {
    final String id = article['id'];
    final bool isBookmarked = _bookmarkedIds.contains(id);
    final String? imgUrl = article['image_url'];
    final int readTime = _calculateReadingTime(article['content'] ?? '');

    return GestureDetector(
      onTap: () => _openArticleDetail(article),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.getBorder(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 90,
                  height: 90,
                  color: AppColors.primary.withValues(alpha: 0.1),
                  child: imgUrl != null && imgUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: imgUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                          errorWidget: (context, url, error) => const Icon(
                            Iconsax.document_text,
                            color: AppColors.primary,
                            size: 32,
                          ),
                        )
                      : const Icon(
                          Iconsax.document_text,
                          color: AppColors.primary,
                          size: 36,
                        ),
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            article['category'] ?? 'زانیاری',
                            style: GoogleFonts.poppins(
                              color: AppColors.primary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _shareArticle(article),
                              child: const Icon(
                                Iconsax.share,
                                size: 17,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => _toggleBookmark(id),
                              child: Icon(
                                isBookmarked
                                    ? Iconsax.archive_tick
                                    : Iconsax.archive_book,
                                size: 18,
                                color: isBookmarked
                                    ? Colors.amber
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    Text(
                      article['title'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: AppColors.getTextTitle(context),
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),

                    Row(
                      children: [
                        Icon(
                          Iconsax.clock,
                          size: 12,
                          color: AppColors.getTextSubtitle(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$readTime خولەک',
                          style: GoogleFonts.poppins(
                            color: AppColors.getTextSubtitle(context),
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Iconsax.verify,
                          size: 12,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'ئادمین',
                          style: GoogleFonts.poppins(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openArticleDetail(Map<String, dynamic> article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ArticleDetailSheet(
          article: article,
          onShare: () => _shareArticle(article),
        );
      },
    );
  }
}

class _ArticleDetailSheet extends StatefulWidget {
  final Map<String, dynamic> article;
  final VoidCallback onShare;

  const _ArticleDetailSheet({required this.article, required this.onShare});

  @override
  State<_ArticleDetailSheet> createState() => _ArticleDetailSheetState();
}

class _ArticleDetailSheetState extends State<_ArticleDetailSheet> {
  String _activeLang = 'ku'; // ku, en, ar

  @override
  Widget build(BuildContext context) {
    final String? imgUrl = widget.article['image_url'];

    String title = widget.article['title'] ?? '';
    String content = widget.article['content'] ?? '';

    if (_activeLang == 'en' &&
        (widget.article['title_en'] ?? '').toString().isNotEmpty) {
      title = widget.article['title_en'];
      content = widget.article['content_en'] ?? widget.article['content'];
    } else if (_activeLang == 'ar' &&
        (widget.article['title_ar'] ?? '').toString().isNotEmpty) {
      title = widget.article['title_ar'];
      content = widget.article['content_ar'] ?? widget.article['content'];
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: AppColors.getBackground(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (imgUrl != null && imgUrl.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: SizedBox(
                              height: 200,
                              width: double.infinity,
                              child: CachedNetworkImage(
                                imageUrl: imgUrl,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) =>
                                    const SizedBox(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.12,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Iconsax.verify,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.article['author'] ??
                                          'ئادمینی گشتی',
                                      style: GoogleFonts.poppins(
                                        color: AppColors.getTextTitle(context),
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'پۆستکراوە لە ${widget.article['created_at'] ?? ''}',
                                      style: GoogleFonts.poppins(
                                        color: AppColors.getTextSubtitle(
                                          context,
                                        ),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            Row(
                              children: [
                                _buildLangChip('ku', 'کوردی'),
                                const SizedBox(width: 4),
                                _buildLangChip('ar', 'عربي'),
                                const SizedBox(width: 4),
                                _buildLangChip('en', 'EN'),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            color: AppColors.getTextTitle(context),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),

                        const Divider(),
                        const SizedBox(height: 12),

                        Text(
                          content,
                          style: GoogleFonts.poppins(
                            color: AppColors.getTextTitle(context),
                            fontSize: 15,
                            height: 1.8,
                          ),
                        ),

                        const SizedBox(height: 28),

                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Iconsax.info_circle,
                                color: AppColors.primary,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'ئەم زانیارییانە بۆ بەرچاوڕوونی و ڕێنمایی گشتییە لەلایەن ئادمینی پزیشکی Dr. Room. لە کاتی باری لەناکاودا بەپەلە پەیوەندی بە تیمەکانی فریاکەوتن بکە.',
                                  style: GoogleFonts.poppins(
                                    color: AppColors.getTextSubtitle(context),
                                    fontSize: 12,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.getSurface(context),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.onShare,
                    icon: const Icon(
                      Iconsax.share,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      'بەشکردنی بابەتەکە',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.getSurfaceSecondary(context),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangChip(String lang, String label) {
    final isSelected = _activeLang == lang;
    return GestureDetector(
      onTap: () => setState(() => _activeLang = lang),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.grey.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected
                ? Colors.white
                : AppColors.getTextSubtitle(context),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
