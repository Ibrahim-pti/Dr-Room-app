import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/api_client.dart';

class PatientEmrScreen extends StatefulWidget {
  final int?
  patientId; // null for current patient, or specific ID for nurse/doctor viewing
  final bool isReadOnly;

  const PatientEmrScreen({super.key, this.patientId, this.isReadOnly = false});

  @override
  State<PatientEmrScreen> createState() => _PatientEmrScreenState();
}

class _PatientEmrScreenState extends State<PatientEmrScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  String? _bloodType;
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _emergencyNotesCtrl = TextEditingController();

  List<String> _chronicDiseases = [];
  List<String> _allergies = [];
  List<String> _currentMedications = [];
  List<String> _pastSurgeries = [];

  final _newChronicCtrl = TextEditingController();
  final _newAllergyCtrl = TextEditingController();
  final _newMedCtrl = TextEditingController();
  final _newSurgeryCtrl = TextEditingController();

  static const _commonDiseases = [
    'شەکرە (Diabetes)',
    'فشاری خوێن (Hypertension)',
    'ڕەبۆ (Asthma)',
    'نەخۆشی دڵ (Heart Disease)',
    'غودە (Thyroid)',
  ];
  static const _commonAllergies = [
    'پەنسیلین (Penicillin)',
    'ئەسپیرین (Aspirin)',
    'سولفا (Sulfa)',
    'هەستیاری خۆراک (Food)',
    'تۆز و پۆلین (Pollen)',
  ];

  @override
  void initState() {
    super.initState();
    _loadEmr();
  }

  Future<void> _loadEmr() async {
    setState(() => _isLoading = true);
    try {
      final endpoint = widget.patientId != null
          ? '/patients/${widget.patientId}/emr'
          : '/patient/emr';
      final res = await ApiClient.get(endpoint);

      if (res.statusCode == 200) {
        final body = jsonDecode(res.body)['data'];
        final emr = (widget.patientId != null ? body['emr'] : body) ?? {};

        setState(() {
          _bloodType = emr['blood_type'];
          _heightCtrl.text = emr['height_cm']?.toString() ?? '';
          _weightCtrl.text = emr['weight_kg']?.toString() ?? '';
          _emergencyNotesCtrl.text = emr['emergency_notes'] ?? '';

          _chronicDiseases = List<String>.from(emr['chronic_diseases'] ?? []);
          _allergies = List<String>.from(emr['allergies'] ?? []);
          _currentMedications = List<String>.from(
            emr['current_medications'] ?? [],
          );
          _pastSurgeries = List<String>.from(emr['past_surgeries'] ?? []);

          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveEmr() async {
    setState(() => _isSaving = true);
    try {
      final payload = {
        'blood_type': _bloodType,
        'height_cm': double.tryParse(_heightCtrl.text.trim()),
        'weight_kg': double.tryParse(_weightCtrl.text.trim()),
        'emergency_notes': _emergencyNotesCtrl.text.trim(),
        'chronic_diseases': _chronicDiseases,
        'allergies': _allergies,
        'current_medications': _currentMedications,
        'past_surgeries': _pastSurgeries,
      };

      final res = await ApiClient.post('/patient/emr', body: payload);
      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF10B981),
              content: Text(
                'دۆسیەی پزیشکی بە سەرکەوتوویی پاشەکەوتکرا',
                style: TextStyle(fontFamily: 'Rabar'),
              ),
            ),
          );
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'comprehensive_emr'.tr(),
          style: const TextStyle(
            fontFamily: 'Rabar',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF0F172A),
      ),
      bottomNavigationBar: widget.isReadOnly
          ? null
          : Container(
              padding: const EdgeInsets.all(16),
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
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveEmr,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'save_emr'.tr(),
                        style: const TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Info banner
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                      ),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(
                          Iconsax.info_circle,
                          color: Color(0xFF0284C7),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'زانیارییە پزیشکییەکانت بە پارێزراوی لە سیستمدا دەمێننەوە بۆ ئەوەی پەرستار یان پزیشک پێش سەردانیکردن بەرچاوڕوونییان هەبێت لەسەر دۆخی تەندروستیت.',
                            style: TextStyle(
                              fontFamily: 'Rabar',
                              fontSize: 12,
                              color: Color(0xFF0F172A),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Vitals / Basic info
                  _buildSectionCard(
                    title: 'زانیارییە سەرەکییەکان',
                    icon: Iconsax.heart,
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _bloodType,
                          decoration: InputDecoration(
                            labelText: 'گروپی خوێن',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items:
                              const [
                                    'A+',
                                    'A-',
                                    'B+',
                                    'B-',
                                    'AB+',
                                    'AB-',
                                    'O+',
                                    'O-',
                                  ]
                                  .map(
                                    (b) => DropdownMenuItem(
                                      value: b,
                                      child: Text(b),
                                    ),
                                  )
                                  .toList(),
                          onChanged: widget.isReadOnly
                              ? null
                              : (v) => setState(() => _bloodType = v),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _heightCtrl,
                                enabled: !widget.isReadOnly,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'height'.tr(),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _weightCtrl,
                                enabled: !widget.isReadOnly,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'weight'.tr(),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Chronic Diseases
                  _buildTagsCard(
                    title: 'chronic_diseases'.tr(),
                    icon: Iconsax.activity,
                    items: _chronicDiseases,
                    suggestions: _commonDiseases,
                    inputCtrl: _newChronicCtrl,
                    onAdd: (val) => setState(() => _chronicDiseases.add(val)),
                    onRemove: (val) =>
                        setState(() => _chronicDiseases.remove(val)),
                  ),
                  const SizedBox(height: 16),

                  // Allergies
                  _buildTagsCard(
                    title: 'allergies'.tr(),
                    icon: Iconsax.danger,
                    items: _allergies,
                    suggestions: _commonAllergies,
                    inputCtrl: _newAllergyCtrl,
                    onAdd: (val) => setState(() => _allergies.add(val)),
                    onRemove: (val) => setState(() => _allergies.remove(val)),
                  ),
                  const SizedBox(height: 16),

                  // Current Medications
                  _buildTagsCard(
                    title: 'current_medications'.tr(),
                    icon: Iconsax.hospital,
                    items: _currentMedications,
                    suggestions: const [],
                    inputCtrl: _newMedCtrl,
                    onAdd: (val) =>
                        setState(() => _currentMedications.add(val)),
                    onRemove: (val) =>
                        setState(() => _currentMedications.remove(val)),
                  ),
                  const SizedBox(height: 16),

                  // Past Surgeries
                  _buildTagsCard(
                    title: 'past_surgeries'.tr(),
                    icon: Iconsax.firstline,
                    items: _pastSurgeries,
                    suggestions: const [],
                    inputCtrl: _newSurgeryCtrl,
                    onAdd: (val) => setState(() => _pastSurgeries.add(val)),
                    onRemove: (val) =>
                        setState(() => _pastSurgeries.remove(val)),
                  ),
                  const SizedBox(height: 16),

                  // Emergency Notes
                  _buildSectionCard(
                    title: 'emergency_notes'.tr(),
                    icon: Iconsax.warning_2,
                    child: TextField(
                      controller: _emergencyNotesCtrl,
                      enabled: !widget.isReadOnly,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText:
                            'تێبینییەکی گرنگ بنووسە کە پەرستار دەبێت پێش سەردان بزانێت...',
                        hintStyle: const TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
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

  Widget _buildTagsCard({
    required String title,
    required IconData icon,
    required List<String> items,
    required List<String> suggestions,
    required TextEditingController inputCtrl,
    required Function(String) onAdd,
    required Function(String) onRemove,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Items Chips
          if (items.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((it) {
                return Chip(
                  label: Text(
                    it,
                    style: const TextStyle(fontFamily: 'Rabar', fontSize: 12),
                  ),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  deleteIcon: widget.isReadOnly
                      ? null
                      : const Icon(Icons.close, size: 14),
                  onDeleted: widget.isReadOnly ? null : () => onRemove(it),
                );
              }).toList(),
            )
          else
            const Text(
              'هیچ تۆمارنەکراوە',
              style: TextStyle(
                fontFamily: 'Rabar',
                fontSize: 12,
                color: Colors.grey,
              ),
            ),

          if (!widget.isReadOnly) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: inputCtrl,
                    decoration: InputDecoration(
                      hintText: 'زیادکردنی دانەیەکی تر...',
                      hintStyle: const TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 12,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add, size: 18),
                  onPressed: () {
                    final txt = inputCtrl.text.trim();
                    if (txt.isNotEmpty && !items.contains(txt)) {
                      onAdd(txt);
                      inputCtrl.clear();
                    }
                  },
                ),
              ],
            ),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: suggestions.where((s) => !items.contains(s)).map((s) {
                  return ActionChip(
                    label: Text(
                      '+ $s',
                      style: const TextStyle(fontFamily: 'Rabar', fontSize: 10),
                    ),
                    onPressed: () => onAdd(s),
                  );
                }).toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
