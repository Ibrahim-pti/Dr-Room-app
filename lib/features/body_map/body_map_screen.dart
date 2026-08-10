import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'organ_details_screen.dart';

class BodyMapScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const BodyMapScreen({super.key, this.onBack});

  @override
  State<BodyMapScreen> createState() => _BodyMapScreenState();
}

class AnatomicalCallout {
  final String key;
  final String title;
  final IconData icon;
  final double dotX;
  final double dotY;
  final bool isRightSide;

  const AnatomicalCallout({
    required this.key,
    required this.title,
    required this.icon,
    required this.dotX,
    required this.dotY,
    required this.isRightSide,
  });
}

class _BodyMapScreenState extends State<BodyMapScreen> {
  String selectedSystem = 'All';
  String? selectedOrgan;
  double _rotationY = 0.0;
  bool isLoadingApi = false;

  final TransformationController _transformationController =
      TransformationController();

  final Color primaryColor = const Color(0xFF6C4DFF);

  final List<Map<String, dynamic>> systems = [
    {'name': 'All', 'icon': Icons.apps, 'color': const Color(0xFF6C4DFF)},
    {
      'name': 'Nervous',
      'icon': Icons.psychology,
      'color': const Color(0xFFF59E0B),
    },
    {
      'name': 'Circulatory',
      'icon': Icons.favorite,
      'color': const Color(0xFFEF4444),
    },
    {
      'name': 'Respiratory',
      'icon': Icons.air,
      'color': const Color(0xFFEC4899),
    },
    {
      'name': 'Digestive',
      'icon': Icons.restaurant,
      'color': const Color(0xFFF97316),
    },
    {
      'name': 'Hepatic',
      'icon': Icons.opacity,
      'color': const Color(0xFFD97706),
    },
    {
      'name': 'Renal/Urinary',
      'icon': Icons.water_drop,
      'color': const Color(0xFF3B82F6),
    },
    {'name': 'Endocrine', 'icon': Icons.hub, 'color': const Color(0xFFA855F7)},
    {
      'name': 'Muscular',
      'icon': Icons.fitness_center,
      'color': const Color(0xFF6366F1),
    },
    {
      'name': 'Skeletal',
      'icon': Icons.accessibility_new,
      'color': const Color(0xFF64748B),
    },
  ];

  // 27 Complete Anatomical Callout Coordinates matching Anatomy Arts USA Diagram
  final Map<String, AnatomicalCallout> calloutCoordinates = {
    'head': const AnatomicalCallout(
      key: 'head',
      title: 'Head & Cranium',
      icon: Icons.psychology,
      dotX: 0.50,
      dotY: 0.01,
      isRightSide: false,
    ),
    'face': const AnatomicalCallout(
      key: 'face',
      title: 'Facial Muscles',
      icon: Icons.face,
      dotX: 0.50,
      dotY: 0.04,
      isRightSide: true,
    ),
    'jaw': const AnatomicalCallout(
      key: 'jaw',
      title: 'Jaw & Mandible',
      icon: Icons.sentiment_satisfied,
      dotX: 0.50,
      dotY: 0.07,
      isRightSide: false,
    ),
    'neck': const AnatomicalCallout(
      key: 'neck',
      title: 'Neck & Spine',
      icon: Icons.view_headline,
      dotX: 0.50,
      dotY: 0.09,
      isRightSide: true,
    ),
    'thyroid': const AnatomicalCallout(
      key: 'thyroid',
      title: 'Thyroid Gland',
      icon: Icons.hub,
      dotX: 0.50,
      dotY: 0.12,
      isRightSide: false,
    ),
    'shoulder': const AnatomicalCallout(
      key: 'shoulder',
      title: 'Deltoid Shoulder',
      icon: Icons.accessibility,
      dotX: 0.72,
      dotY: 0.14,
      isRightSide: true,
    ),
    'chest_muscle': const AnatomicalCallout(
      key: 'chest_muscle',
      title: 'Pectoralis Muscle',
      icon: Icons.fitness_center,
      dotX: 0.44,
      dotY: 0.17,
      isRightSide: false,
    ),
    'heart': const AnatomicalCallout(
      key: 'heart',
      title: 'Heart & Circulation',
      icon: Icons.favorite,
      dotX: 0.54,
      dotY: 0.19,
      isRightSide: true,
    ),
    'lungs': const AnatomicalCallout(
      key: 'lungs',
      title: 'Lungs & Airways',
      icon: Icons.air,
      dotX: 0.42,
      dotY: 0.21,
      isRightSide: false,
    ),
    'ribs': const AnatomicalCallout(
      key: 'ribs',
      title: 'Thoracic Ribcage',
      icon: Icons.grid_view,
      dotX: 0.56,
      dotY: 0.23,
      isRightSide: true,
    ),
    'biceps': const AnatomicalCallout(
      key: 'biceps',
      title: 'Biceps Brachii',
      icon: Icons.fitness_center,
      dotX: 0.32,
      dotY: 0.24,
      isRightSide: false,
    ),
    'forearm': const AnatomicalCallout(
      key: 'forearm',
      title: 'Brachioradialis',
      icon: Icons.pan_tool,
      dotX: 0.24,
      dotY: 0.32,
      isRightSide: false,
    ),
    'liver': const AnatomicalCallout(
      key: 'liver',
      title: 'Liver & Biliary',
      icon: Icons.opacity,
      dotX: 0.44,
      dotY: 0.26,
      isRightSide: false,
    ),
    'stomach': const AnatomicalCallout(
      key: 'stomach',
      title: 'Stomach & Gastric',
      icon: Icons.restaurant,
      dotX: 0.52,
      dotY: 0.28,
      isRightSide: true,
    ),
    'gallbladder': const AnatomicalCallout(
      key: 'gallbladder',
      title: 'Gallbladder',
      icon: Icons.water_drop,
      dotX: 0.45,
      dotY: 0.30,
      isRightSide: false,
    ),
    'pancreas': const AnatomicalCallout(
      key: 'pancreas',
      title: 'Pancreas Gland',
      icon: Icons.science,
      dotX: 0.52,
      dotY: 0.32,
      isRightSide: true,
    ),
    'spleen': const AnatomicalCallout(
      key: 'spleen',
      title: 'Spleen & Lymph',
      icon: Icons.shield,
      dotX: 0.56,
      dotY: 0.34,
      isRightSide: true,
    ),
    'kidneys': const AnatomicalCallout(
      key: 'kidneys',
      title: 'Kidneys & Renal',
      icon: Icons.filter_alt,
      dotX: 0.46,
      dotY: 0.35,
      isRightSide: false,
    ),
    'abs': const AnatomicalCallout(
      key: 'abs',
      title: 'Rectus Abdominis',
      icon: Icons.grid_on,
      dotX: 0.50,
      dotY: 0.37,
      isRightSide: true,
    ),
    'small_intestine': const AnatomicalCallout(
      key: 'small_intestine',
      title: 'Small Intestine',
      icon: Icons.grain,
      dotX: 0.50,
      dotY: 0.39,
      isRightSide: false,
    ),
    'large_intestine': const AnatomicalCallout(
      key: 'large_intestine',
      title: 'Colon Intestine',
      icon: Icons.alt_route,
      dotX: 0.50,
      dotY: 0.41,
      isRightSide: true,
    ),
    'pelvis': const AnatomicalCallout(
      key: 'pelvis',
      title: 'Pelvic Girdle',
      icon: Icons.crop_free,
      dotX: 0.50,
      dotY: 0.43,
      isRightSide: false,
    ),
    'quadriceps': const AnatomicalCallout(
      key: 'quadriceps',
      title: 'Quadriceps Thigh',
      icon: Icons.directions_run,
      dotX: 0.42,
      dotY: 0.47,
      isRightSide: false,
    ),
    'knee': const AnatomicalCallout(
      key: 'knee',
      title: 'Patella & Knee Joint',
      icon: Icons.shield,
      dotX: 0.42,
      dotY: 0.52,
      isRightSide: true,
    ),
    'shin': const AnatomicalCallout(
      key: 'shin',
      title: 'Tibialis Shin',
      icon: Icons.linear_scale,
      dotX: 0.42,
      dotY: 0.57,
      isRightSide: false,
    ),
    'calf': const AnatomicalCallout(
      key: 'calf',
      title: 'Gastrocnemius Calf',
      icon: Icons.directions_walk,
      dotX: 0.58,
      dotY: 0.59,
      isRightSide: true,
    ),
    'feet': const AnatomicalCallout(
      key: 'feet',
      title: 'Ankle & Foot Skeleton',
      icon: Icons.accessibility_new,
      dotX: 0.58,
      dotY: 0.63,
      isRightSide: false,
    ),
  };

  // Dynamic Organ Data Map (Populated with Wikipedia REST API & Anatomy Arts USA Data)
  final Map<String, Map<String, dynamic>> organQuickData = {};

  @override
  void initState() {
    super.initState();
    _fetchAnatomyApiData();
  }

  void _selectOrgan(String key) async {
    setState(() {
      selectedOrgan = key;
      isLoadingApi = true;
    });

    final wikiMap = {
      'head': 'Human_brain',
      'face': 'Facial_muscles',
      'jaw': 'Human_jaw',
      'neck': 'Neck',
      'thyroid': 'Thyroid',
      'shoulder': 'Deltoid_muscle',
      'chest_muscle': 'Pectoralis_major',
      'heart': 'Heart',
      'lungs': 'Lung',
      'ribs': 'Rib_cage',
      'biceps': 'Biceps',
      'forearm': 'Forearm',
      'liver': 'Liver',
      'stomach': 'Stomach',
      'pancreas': 'Pancreas',
      'spleen': 'Spleen',
      'gallbladder': 'Gallbladder',
      'kidneys': 'Kidney',
      'abs': 'Rectus_abdominis_muscle',
      'small_intestine': 'Small_intestine',
      'large_intestine': 'Large_intestine',
      'pelvis': 'Pelvis',
      'quadriceps': 'Quadriceps_femoris_muscle',
      'knee': 'Knee',
      'shin': 'Tibialis_anterior_muscle',
      'calf': 'Gastrocnemius_muscle',
      'feet': 'Foot',
    };

    final wikiTitle = wikiMap[key] ?? key;

    try {
      final wikiRes = await http
          .get(
            Uri.parse(
              'https://en.wikipedia.org/api/rest_v1/page/summary/$wikiTitle',
            ),
          )
          .timeout(const Duration(seconds: 3));

      if (wikiRes.statusCode == 200) {
        final data = json.decode(wikiRes.body);
        final extract = data['extract'] as String? ?? '';
        final sentences = List<String>.from(
          extract.split('. ').where((s) => s.isNotEmpty),
        );

        if (mounted) {
          setState(() {
            organQuickData[key] = {
              'id': key,
              'title': data['title'] ?? wikiTitle,
              'description':
                  data['description'] ??
                  (sentences.isNotEmpty ? sentences.first : extract),
              'imageUrl':
                  data['thumbnail']?['source'] ??
                  (data['originalimage']?['source'] ?? ''),
              'wikiUrl':
                  data['content_urls']?['desktop']?['page'] ??
                  'https://en.wikipedia.org/wiki/$wikiTitle',
              'latin': data['description'] ?? 'Anatomical Structure',
              'specialist': 'Anatomy Arts USA & Medical REST API',
              'stats': [
                {'value': 'Wikipedia', 'label': 'Source', 'icon': Icons.public},
                {'value': 'REST v1', 'label': 'API', 'icon': Icons.api},
                {
                  'value': 'Live',
                  'label': 'Status',
                  'icon': Icons.check_circle,
                },
                {
                  'value': 'Verified',
                  'label': 'Medical',
                  'icon': Icons.verified,
                },
              ],
              'functions': sentences.isNotEmpty ? sentences : [extract],
              'fact': extract,
              'anatomy_details': {
                'Anatomical Part': data['title'] ?? '',
                'Medical Summary': data['description'] ?? '',
                'Full Article Extract': extract,
                'Wikipedia Page Link':
                    data['content_urls']?['desktop']?['page'] ?? '',
              },
            };
            isLoadingApi = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Live Wikipedia fetch error: $e');
      if (mounted) {
        setState(() => isLoadingApi = false);
      }
    }
  }

  Future<void> _fetchAnatomyApiData() async {
    setState(() => isLoadingApi = true);
    final urls = [
      'http://127.0.0.1:8000/api/anatomy/organs',
      'http://10.0.2.2:8000/api/anatomy/organs',
      'http://localhost:8000/api/anatomy/organs',
    ];

    bool fetchedFromLaravel = false;

    for (final url in urls) {
      try {
        final response = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 2));

        if (response.statusCode == 200) {
          final jsonBody = json.decode(response.body);
          if (jsonBody['status'] == 'success' && jsonBody['data'] != null) {
            final Map<String, dynamic> apiData = Map<String, dynamic>.from(
              jsonBody['data'],
            );
            if (mounted) {
              setState(() {
                apiData.forEach((key, value) {
                  if (value is Map) {
                    organQuickData[key] = Map<String, dynamic>.from(value);
                  }
                });
                isLoadingApi = false;
              });
              fetchedFromLaravel = true;
              break;
            }
          }
        }
      } catch (_) {
        // Try next candidate URL
      }
    }

    if (!fetchedFromLaravel) {
      final wikiMap = {
        'head': 'Human_brain',
        'face': 'Facial_muscles',
        'jaw': 'Human_jaw',
        'neck': 'Neck',
        'thyroid': 'Thyroid',
        'shoulder': 'Deltoid_muscle',
        'chest_muscle': 'Pectoralis_major',
        'heart': 'Heart',
        'lungs': 'Lung',
        'ribs': 'Rib_cage',
        'biceps': 'Biceps',
        'forearm': 'Forearm',
        'liver': 'Liver',
        'stomach': 'Stomach',
        'pancreas': 'Pancreas',
        'spleen': 'Spleen',
        'gallbladder': 'Gallbladder',
        'kidneys': 'Kidney',
        'abs': 'Rectus_abdominis_muscle',
        'small_intestine': 'Small_intestine',
        'large_intestine': 'Large_intestine',
        'pelvis': 'Pelvis',
        'quadriceps': 'Quadriceps_femoris_muscle',
        'knee': 'Knee',
        'shin': 'Tibialis_anterior_muscle',
        'calf': 'Gastrocnemius_muscle',
        'feet': 'Foot',
      };

      for (final entry in wikiMap.entries) {
        try {
          final wikiRes = await http
              .get(
                Uri.parse(
                  'https://en.wikipedia.org/api/rest_v1/page/summary/${entry.value}',
                ),
              )
              .timeout(const Duration(seconds: 2));

          if (wikiRes.statusCode == 200) {
            final data = json.decode(wikiRes.body);
            final extract = data['extract'] ?? '';
            final sentences = List<String>.from(
              (extract as String).split('. ').where((s) => s.isNotEmpty),
            );

            if (mounted) {
              setState(() {
                organQuickData[entry.key] = {
                  'id': entry.key,
                  'title': data['title'] ?? entry.key,
                  'description':
                      data['description'] ??
                      (sentences.isNotEmpty ? sentences.first : ''),
                  'imageUrl':
                      data['thumbnail']?['source'] ??
                      (data['originalimage']?['source'] ?? ''),
                  'wikiUrl': data['content_urls']?['desktop']?['page'] ?? '',
                  'latin': data['description'] ?? 'Anatomical Structure',
                  'specialist': 'Anatomy Arts USA & Medical API',
                  'stats': [
                    {
                      'value': 'Wikipedia',
                      'label': 'Source',
                      'icon': Icons.public,
                    },
                    {'value': 'REST v1', 'label': 'API', 'icon': Icons.api},
                  ],
                  'functions': sentences.isNotEmpty ? sentences : [extract],
                  'fact': extract,
                  'anatomy_details': {
                    'Anatomical Part': data['title'] ?? '',
                    'Summary Description': data['description'] ?? '',
                    'Full Extract': extract,
                    'Wikipedia Link':
                        data['content_urls']?['desktop']?['page'] ?? '',
                  },
                };
              });
            }
          }
        } catch (_) {}
      }
    }

    if (mounted) {
      setState(() => isLoadingApi = false);
    }
  }

  void _openOrganDetails(Map<String, dynamic> organData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrganDetailsScreen(organData: organData),
      ),
    );
  }

  void _handleSystemTap(String systemName) {
    selectedSystem = systemName;
    String? targetKey;
    switch (systemName) {
      case 'Nervous':
        targetKey = 'head';
        break;
      case 'Circulatory':
        targetKey = 'heart';
        break;
      case 'Respiratory':
        targetKey = 'lungs';
        break;
      case 'Digestive':
        targetKey = 'stomach';
        break;
      case 'Hepatic':
        targetKey = 'liver';
        break;
      case 'Renal/Urinary':
        targetKey = 'kidneys';
        break;
      case 'Endocrine':
        targetKey = 'thyroid';
        break;
      case 'Muscular':
        targetKey = 'biceps';
        break;
      case 'Skeletal':
        targetKey = 'ribs';
        break;
      case 'All':
      default:
        targetKey = null;
    }

    if (targetKey != null) {
      _selectOrgan(targetKey);
    } else {
      setState(() => selectedOrgan = null);
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeOrganData = selectedOrgan != null
        ? organQuickData[selectedOrgan]
        : null;

    final isAllSelected = selectedSystem == 'All';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            // Top Systems Horizontal Filter Bar
            _buildTopSystemsFilter(),

            // Main Interactive Anatomy Viewport
            Expanded(
              child: Stack(
                children: [
                  // Centered 3D Human Body Model Canvas with Interactive 360 Rotation
                  Positioned.fill(
                    child: InteractiveViewer(
                      transformationController: _transformationController,
                      panEnabled: false,
                      scaleEnabled: false,
                      minScale: 1.0,
                      maxScale: 1.0,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 80, top: 10),
                          child: GestureDetector(
                            onHorizontalDragUpdate: (details) {
                              setState(() {
                                _rotationY += details.primaryDelta! * 0.008;
                              });
                            },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // 3D Perspective Y-Axis Rotation Model
                                Transform(
                                  transform: Matrix4.identity()
                                    ..setEntry(3, 2, 0.001)
                                    ..rotateY(_rotationY),
                                  alignment: Alignment.center,
                                  child: Hero(
                                    tag: 'anatomy_model',
                                    child: Image.asset(
                                      'assets/images/anatomy.png',
                                      fit: BoxFit.contain,
                                      height:
                                          MediaQuery.of(context).size.height *
                                          0.65,
                                    ),
                                  ),
                                ),

                                // 27 Dynamic Callout Pointer Lines Matching Anatomy Arts USA
                                ...calloutCoordinates.entries.map((entry) {
                                  final key = entry.key;
                                  final callout = entry.value;
                                  final organInfo = organQuickData[key];

                                  final showThisCallout =
                                      isAllSelected || selectedOrgan == key;

                                  if (!showThisCallout) {
                                    return const SizedBox();
                                  }

                                  final labelTitle =
                                      organInfo?['title']?.toString() ??
                                      callout.title;

                                  final screenWidth = MediaQuery.of(context).size.width;
                                  
                                  double lineLength;
                                  if (callout.isRightSide) {
                                    lineLength = (0.70 - callout.dotX) * screenWidth;
                                  } else {
                                    lineLength = (callout.dotX - 0.30) * screenWidth;
                                  }
                                  if (lineLength < 15) lineLength = 15;

                                  return Positioned(
                                    top: MediaQuery.of(context).size.height * callout.dotY,
                                    left: MediaQuery.of(context).size.width * callout.dotX,
                                    child: FractionalTranslation(
                                      translation: callout.isRightSide
                                          ? const Offset(0.0, -0.5)
                                          : const Offset(-1.0, -0.5),
                                      child: _buildPointerLineLabel(
                                        organKey: key,
                                        label: labelTitle,
                                        icon: callout.icon,
                                        isRightSide: callout.isRightSide,
                                        lineLength: lineLength,
                                        onTap: () => _selectOrgan(key),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom Organ Quick Card (Appears smoothly when an organ is selected)
                  if (activeOrganData != null)
                    Positioned(
                      left: 14,
                      right: 14,
                      bottom: 115,
                      child: _buildOrganQuickCard(activeOrganData),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      title: Text(
        'Anatomy Arts Medical Map',
        style: GoogleFonts.poppins(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: isLoadingApi
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Iconsax.search_normal_copy, color: Colors.black87),
          onPressed: _fetchAnatomyApiData,
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.black87),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildTopSystemsFilter() {
    return Container(
      height: 42,
      margin: const EdgeInsets.only(top: 4, bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: systems.length,
        itemBuilder: (context, index) {
          final system = systems[index];
          final isSelected = selectedSystem == system['name'];
          final color = system['color'] as Color;

          return GestureDetector(
            onTap: () => _handleSystemTap(system['name']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? primaryColor : Colors.grey.shade200,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    system['icon'],
                    size: 15,
                    color: isSelected ? Colors.white : color,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    system['name'],
                    style: GoogleFonts.poppins(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPointerLineLabel({
    required String organKey,
    required String label,
    required IconData icon,
    required bool isRightSide,
    required double lineLength,
    required VoidCallback onTap,
  }) {
    final isSelected = selectedOrgan == organKey;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isRightSide) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.6),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            Container(
              width: lineLength,
              height: 1.2,
              color: primaryColor.withValues(alpha: 0.5),
            ),
          ],
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected ? primaryColor : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? primaryColor : Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? primaryColor.withValues(alpha: 0.35)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 11,
                  color: isSelected ? Colors.white : primaryColor,
                ),
                const SizedBox(width: 4),
                Container(
                  constraints: const BoxConstraints(maxWidth: 80),
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 9.0,
                      height: 1.1,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isRightSide) ...[
            Container(
              width: lineLength,
              height: 1.2,
              color: primaryColor.withValues(alpha: 0.5),
            ),
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.6),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrganQuickCard(Map<String, dynamic> organData) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: primaryColor.withValues(alpha: 0.12)),
      ),
      child: Stack(
        children: [
          Row(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.1),
                  ),
                ),
                padding: const EdgeInsets.all(6),
                child:
                    (organData['imageUrl'] != null &&
                        (organData['imageUrl'] as String).isNotEmpty)
                    ? Image.network(
                        organData['imageUrl'] as String,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.public, size: 40, color: primaryColor),
                      )
                    : Icon(Icons.public, size: 40, color: primaryColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 24),
                      child: Text(
                        organData['title'] ?? 'Organ Details',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      organData['description'] ??
                          'Detailed summary fetched live from Wikipedia REST API.',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: Colors.grey.shade700,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _openOrganDetails(organData),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Read More Details',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11.5,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 10,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () => setState(() => selectedOrgan = null),
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, size: 14, color: Colors.grey.shade600),
              ),
            ),
          ),
        ],
      ),
    );
  }

}
