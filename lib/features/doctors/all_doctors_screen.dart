import 'package:flutter/material.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'doctor_details_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:convert';
import '../../core/utils/api_client.dart';
import '../../core/utils/localization_extensions.dart';

class AllDoctorsScreen extends StatefulWidget {

  const AllDoctorsScreen({super.key});

  @override
  State<AllDoctorsScreen> createState() => _AllDoctorsScreenState();
}

class _AllDoctorsScreenState extends State<AllDoctorsScreen> {
  static List<dynamic>? _cachedDoctors;

  bool _isLoading = true;
  List<dynamic> _doctors = [];

  @override
  void initState() {
    super.initState();
    if (_cachedDoctors != null) {
      _doctors = _cachedDoctors!;
      _isLoading = false;
      _fetchDoctors(background: true);
    } else {
      _fetchDoctors();
    }
  }

  Future<void> _fetchDoctors({bool background = false}) async {
    if (!background) {
      setState(() => _isLoading = true);
    }
    try {
      final response = await ApiClient.get('/doctors');
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _doctors = jsonDecode(response.body);
            _cachedDoctors = _doctors;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching doctors: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'top_doctors'.tr(),
          style: GoogleFonts.poppins(
            color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A)),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _doctors.isEmpty
              ? Center(child: Text('no_results_found'.tr(), style: const TextStyle(fontFamily: 'Rabar')))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  itemCount: _doctors.length,
                  itemBuilder: (context, index) {
                    final doc = _doctors[index];
                    final userObj = doc['user'] is Map ? doc['user'] : doc;
                    final name = context.localizedField(userObj, 'name', fallback: 'cat_doctor'.tr());
                    final specialty = context.localizedField(doc, 'specialty', fallback: context.localizedField(doc, 'bio', fallback: 'medical_specialist'.tr()));
                    final rating = doc['rating']?.toString() ?? '5.0';

                    final fallbackImages = [
                      'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=500&auto=format&fit=crop&q=80',
                      'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=500&auto=format&fit=crop&q=80',
                      'https://images.unsplash.com/photo-1594824813511-236b283d0cfa?w=500&auto=format&fit=crop&q=80',
                      'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=500&auto=format&fit=crop&q=80',
                      'https://images.unsplash.com/photo-1537368910025-700350fe46c7?w=500&auto=format&fit=crop&q=80',
                    ];
                    final rawPath = doc['image_path']?.toString();
                    final isCustomUpload = rawPath != null &&
                        rawPath.isNotEmpty &&
                        !rawPath.contains('assets/images/doctor') &&
                        !rawPath.contains('default');
                    final image = isCustomUpload
                        ? (rawPath.startsWith('http')
                            ? rawPath
                            : ApiClient.getImageUrl(rawPath))
                        : fallbackImages[index % fallbackImages.length];
                    final doctorId = doc['id'];

                    return Padding(
                      padding: const EdgeInsetsDirectional.only(bottom: 16),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DoctorDetailsScreen(
                                doctorId: doctorId,
                                name: name,
                                specialty: specialty,
                                image: image,
                                // The list endpoint returns the full record;
                                // passing it opens the details instantly.
                                initialDoctor: Map<String, dynamic>.from(doc),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            border: Border.all(
                              color: const Color(0xFFF1F5F9),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Image Container
                              Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: const Color(0xFFF8FAFC),
                                  image: DecorationImage(
                                    image: doc['image_path'] != null 
                                      ? NetworkImage(image) as ImageProvider
                                      : AssetImage(image),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Info Column
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      name,
                                      style: GoogleFonts.poppins(
                                        color: (Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF0F172A)),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      specialty,
                                      style: GoogleFonts.poppins(
                                        color: (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.star_rounded,
                                                color: Color(0xFFF59E0B),
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                rating,
                                                style: GoogleFonts.poppins(
                                                  color: const Color(0xFFB45309),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '(${doc['total_reviews'] ?? 45})',
                                            style: GoogleFonts.poppins(
                                              color: const Color(0xFF94A3B8),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Action (Heart)
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F4FD),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.favorite_border_rounded,
                                  color: Color(0xFF3B82F6),
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: (100 * index).ms)
                    .slideY(begin: 0.1, end: 0);
                  },
                ),
    );
  }
}