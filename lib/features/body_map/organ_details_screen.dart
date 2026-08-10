import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class OrganDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> organData;

  const OrganDetailsScreen({super.key, required this.organData});

  @override
  State<OrganDetailsScreen> createState() => _OrganDetailsScreenState();
}

class _OrganDetailsScreenState extends State<OrganDetailsScreen> {
  String selectedTab = 'Overview';
  bool isFavorite = true;

  final Color primaryColor = const Color(0xFF6C4DFF);

  Future<void> _launchWikiUrl(String urlString) async {
    if (urlString.isEmpty) return;
    final Uri uri = Uri.parse(urlString);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $urlString');
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.organData['title'] ?? 'Wikipedia Medical Summary';
    final imageUrl = widget.organData['imageUrl'] ?? '';
    final description = widget.organData['description'] ??
        'Anatomical structure summary fetched from Wikipedia REST API.';
    final latin = widget.organData['latin'] ?? 'Wikipedia Medical REST v1';
    final specialist = widget.organData['specialist'] ?? 'Wikipedia Medical REST API';
    final wikiUrl = widget.organData['wikiUrl'] as String? ?? '';

    final stats = widget.organData['stats'] as List<dynamic>? ??
        [
          {'value': 'Wikipedia', 'label': 'Source', 'icon': Icons.public},
          {'value': 'REST v1', 'label': 'API', 'icon': Icons.api},
          {'value': 'Live', 'label': 'Status', 'icon': Icons.check_circle},
          {'value': 'Verified', 'label': 'Medical', 'icon': Icons.verified},
        ];

    final functions = widget.organData['functions'] as List<dynamic>? ??
        [description];

    final fact = widget.organData['fact'] as String? ?? description;

    final anatomyDetails = widget.organData['anatomy_details'] as Map<String, dynamic>? ??
        {
          'Wikipedia Article': title,
          'Summary Description': description,
          'Wikipedia Page Link': wikiUrl,
        };

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 16,
              color: Colors.black87,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? primaryColor : Colors.grey.shade400,
            ),
            onPressed: () => setState(() => isFavorite = !isFavorite),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sub-navigation Chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: ['Overview', 'Anatomy', 'Extracts', 'Wikipedia']
                          .map((tab) {
                        final isSelected = selectedTab == tab;
                        return GestureDetector(
                          onTap: () => setState(() => selectedTab = tab),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryColor
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tab,
                              style: GoogleFonts.poppins(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey.shade700,
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Wikipedia Organ Illustration Header
                    Center(
                      child: Container(
                        height: 220,
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (imageUrl.isNotEmpty)
                              Image.network(
                                imageUrl,
                                height: 140,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(Icons.public, size: 80, color: primaryColor),
                              )
                            else
                              Icon(Icons.public, size: 80, color: primaryColor),
                            const SizedBox(height: 10),
                            Text(
                              latin,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Tab Content Switcher
                    if (selectedTab == 'Overview') ...[
                      // Wikipedia Summary Card
                      _buildSectionCard(
                        title: 'Wikipedia Summary',
                        icon: Icons.public,
                        child: Text(
                          description,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey.shade800,
                            height: 1.5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // API Source Tag
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.api, color: primaryColor, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Data Source: ',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                specialist,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Wikipedia REST API Metadata Grid
                      Row(
                        children: stats.map((stat) {
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    stat['icon'] is IconData
                                        ? stat['icon']
                                        : Icons.public,
                                    size: 18,
                                    color: primaryColor,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    stat['value'].toString(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    stat['label'].toString(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 9,
                                      color: Colors.grey.shade600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ] else if (selectedTab == 'Anatomy') ...[
                      // Wikipedia Detailed Anatomy Card
                      _buildSectionCard(
                        title: 'Wikipedia Article Details',
                        icon: Icons.menu_book,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: anatomyDetails.entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: primaryColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        entry.key,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 14),
                                    child: Text(
                                      entry.value.toString(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey.shade800,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ] else if (selectedTab == 'Extracts') ...[
                      // Key Sentences / Extracts Card
                      _buildSectionCard(
                        title: 'Wikipedia Article Extracts',
                        icon: Icons.article_outlined,
                        child: Column(
                          children: functions.map((func) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(top: 2),
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.check,
                                      size: 12,
                                      color: primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      func.toString(),
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey.shade800,
                                        fontWeight: FontWeight.w500,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ] else ...[
                      // Full Extract & Wikipedia Article Link Card
                      _buildSectionCard(
                        title: 'Complete Wikipedia Article',
                        icon: Icons.language,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fact,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey.shade800,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (wikiUrl.isNotEmpty)
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _launchWikiUrl(wikiUrl),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    side: BorderSide(color: primaryColor),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: Icon(Icons.open_in_new, size: 16, color: primaryColor),
                                  label: Text(
                                    'Open Wikipedia Article',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Action Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back,
                      color: Colors.white, size: 20),
                  label: Text(
                    'Back to Body Map',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: primaryColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
