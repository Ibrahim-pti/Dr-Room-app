import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  List<Map<String, dynamic>> _addresses = [
    {
      'title': 'ماڵەوە',
      'address': 'شەقامی ١٠٠ مەتری، گوندی ئینگلیزی، ڤێلا ٤٥، هەولێر',
      'isDefault': true,
      'type': 'home',
    },
    {
      'title': 'دەوام / شوێنی کار',
      'address': 'گوندی ئیتاڵی ١، ئۆفیسی ١٢، هەولێر',
      'isDefault': false,
      'type': 'work',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('saved_user_addresses');
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List;
        setState(() {
          _addresses = decoded.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      } catch (_) {}
    }
  }

  Future<void> _saveAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_user_addresses', jsonEncode(_addresses));
  }

  void _showAddAddressModal([int? editIndex]) {
    final titleController = TextEditingController(
      text: editIndex != null ? _addresses[editIndex]['title'] : '',
    );
    final addressController = TextEditingController(
      text: editIndex != null ? _addresses[editIndex]['address'] : '',
    );
    String selectedType = editIndex != null ? (_addresses[editIndex]['type'] ?? 'home') : 'home';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getSurface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                editIndex != null ? 'دەستکاریکردنی ناونیشان' : 'زیادکردنی ناونیشانی نوێ',
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextTitle(context),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleController,
                style: TextStyle(fontFamily: 'Rabar', color: AppColors.getTextTitle(context)),
                decoration: InputDecoration(
                  labelText: 'ناوی ناونیشان (نموونە: ماڵەوە، دەوام)',
                  labelStyle: TextStyle(fontFamily: 'Rabar', color: AppColors.getTextSubtitle(context)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Iconsax.tag, color: Color(0xFF3B82F6)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                maxLines: 2,
                style: TextStyle(fontFamily: 'Rabar', color: AppColors.getTextTitle(context)),
                decoration: InputDecoration(
                  labelText: 'وردەکاریی ناونیشان و شار',
                  labelStyle: TextStyle(fontFamily: 'Rabar', color: AppColors.getTextSubtitle(context)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Iconsax.location, color: Color(0xFF3B82F6)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty || addressController.text.trim().isEmpty) return;

                    setState(() {
                      if (editIndex != null) {
                        _addresses[editIndex]['title'] = titleController.text.trim();
                        _addresses[editIndex]['address'] = addressController.text.trim();
                        _addresses[editIndex]['type'] = selectedType;
                      } else {
                        _addresses.add({
                          'title': titleController.text.trim(),
                          'address': addressController.text.trim(),
                          'isDefault': _addresses.isEmpty,
                          'type': selectedType,
                        });
                      }
                    });
                    _saveAddresses();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    editIndex != null ? 'پاشەکەوتکردن' : 'زیادکردن',
                    style: const TextStyle(fontFamily: 'Rabar', fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, size: 20, color: AppColors.getTextTitle(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'saved_addresses'.tr(),
          style: TextStyle(
            fontFamily: 'Rabar',
            color: AppColors.getTextTitle(context),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Map Mockup ──
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.1,
                    child: CustomPaint(painter: _GridPainter()),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.getSurface(context),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          _addresses.isNotEmpty ? _addresses.first['title'] : 'هەولێر',
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            color: AppColors.getTextTitle(context),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ).animate().slideY(begin: 0.5, end: 0).fadeIn(delay: 200.ms),
                      const SizedBox(height: 6),
                      const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 40).animate().scale(delay: 400.ms),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Address List ──
          Expanded(
            child: _addresses.isEmpty
                ? Center(
                    child: Text(
                      'هیچ ناونیشانێک تۆمار نەکراوە',
                      style: TextStyle(fontFamily: 'Rabar', color: AppColors.getTextSubtitle(context)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _addresses.length,
                    itemBuilder: (context, index) {
                      final item = _addresses[index];
                      final isDefault = item['isDefault'] == true;
                      final type = item['type'] ?? 'home';
                      final icon = type == 'work' ? Iconsax.building : Iconsax.home_2;
                      final color = type == 'work' ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6);

                      return _buildAddressCard(
                        context: context,
                        index: index,
                        title: item['title'] ?? '',
                        address: item['address'] ?? '',
                        icon: icon,
                        color: color,
                        isDefault: isDefault,
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAddressModal(),
        backgroundColor: const Color(0xFF3B82F6),
        icon: const Icon(Iconsax.location_add, color: Colors.white),
        label: const Text(
          'زیادکردنی ناونیشان',
          style: TextStyle(fontFamily: 'Rabar', color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildAddressCard({
    required BuildContext context,
    required int index,
    required String title,
    required String address,
    required IconData icon,
    required Color color,
    required bool isDefault,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDefault ? color : AppColors.getBorder(context),
          width: isDefault ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                for (var i = 0; i < _addresses.length; i++) {
                  _addresses[i]['isDefault'] = (i == index);
                }
              });
              _saveAddresses();
            },
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        color: AppColors.getTextTitle(context),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isDefault) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'سەرەکی',
                          style: TextStyle(
                            fontFamily: 'Rabar',
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  address,
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    color: AppColors.getTextSubtitle(context),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF64748B), size: 20),
            onSelected: (val) {
              if (val == 'edit') {
                _showAddAddressModal(index);
              } else if (val == 'default') {
                setState(() {
                  for (var i = 0; i < _addresses.length; i++) {
                    _addresses[i]['isDefault'] = (i == index);
                  }
                });
                _saveAddresses();
              } else if (val == 'delete') {
                setState(() {
                  _addresses.removeAt(index);
                });
                _saveAddresses();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'default', child: Text('دانان وەک سەرەکی', style: TextStyle(fontFamily: 'Rabar'))),
              const PopupMenuItem(value: 'edit', child: Text('دەستکاریکردن', style: TextStyle(fontFamily: 'Rabar'))),
              const PopupMenuItem(value: 'delete', child: Text('سڕینەوە', style: TextStyle(fontFamily: 'Rabar', color: Colors.red))),
            ],
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0;

    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
