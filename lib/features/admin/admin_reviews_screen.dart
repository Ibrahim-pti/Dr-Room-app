import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../core/utils/api_client.dart';
import 'admin_app_bar.dart';
import 'admin_ui.dart';

/// One merged feed of every review left on a doctor, lab, nurse or pharmacy,
/// so a moderator does not have to check four separate places.
class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  static const _typeFilters = [
    (value: '', label: 'هەمووی'),
    (value: 'doctor', label: 'پزیشک'),
    (value: 'nurse', label: 'پەرستار'),
    (value: 'lab', label: 'تاقیگە'),
    (value: 'pharmacy', label: 'دەرمانخانە'),
  ];

  static const _statusFilters = [
    (value: '', label: 'هەمووی'),
    (value: 'visible', label: 'دیار'),
    (value: 'hidden', label: 'شاردراوە'),
  ];

  List<dynamic> _reviews = [];
  String _type = '';
  String _status = '';
  bool _lowRatingOnly = false;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final params = <String>[
      if (_type.isNotEmpty) 'type=$_type',
      if (_status.isNotEmpty) 'status=$_status',
      if (_lowRatingOnly) 'min_rating=2',
    ];
    final query = params.isEmpty ? '' : '?${params.join('&')}';

    try {
      final res = await ApiClient.get('/admin/reviews$query');
      if (!mounted) return;

      setState(() {
        _reviews = res.statusCode == 200 ? jsonDecode(res.body) : [];
        _error = res.statusCode == 200 ? null : AdminUi.readError(res);
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = '$e'; _isLoading = false; });
    }
  }

  Future<void> _hide(dynamic review) async {
    final reasonCtrl = TextEditingController();

    await AdminUi.formSheet(
      context: context,
      title: 'شاردنەوەی هەڵسەنگاندن',
      subtitle: 'لە ئەپەکەدا نامێنێت و لە ناوەندی هەڵسەنگاندن دەرناچێت',
      submitLabel: 'شاردنەوە',
      builder: (setSheetState, setError) => [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            review['comment'] ?? '(بێ کۆمێنت)',
            style: const TextStyle(fontFamily: 'Rabar', fontSize: 12.5, height: 1.5),
          ),
        ),
        const SizedBox(height: 14),
        AdminUi.label('هۆکار (ئارەزوومەندانە)'),
        const SizedBox(height: 6),
        AdminUi.input(controller: reasonCtrl, hint: 'وەک: زمانی ناشیرین', maxLines: 2),
      ],
      onSubmit: (setError) async {
        final res = await ApiClient.patch(
          '/admin/reviews/${review['type']}/${review['id']}/hide',
          body: {'reason': reasonCtrl.text.trim()},
        );

        if (res.statusCode == 200) {
          _load();
          return true;
        }

        setError(AdminUi.readError(res));
        return false;
      },
    );
  }

  Future<void> _restore(dynamic review) async {
    final res = await ApiClient.patch('/admin/reviews/${review['type']}/${review['id']}/restore');
    if (!mounted) return;

    if (res.statusCode == 200) {
      AdminUi.toast(context, 'گەڕایەوە.');
      _load();
    } else {
      AdminUi.toast(context, AdminUi.readError(res), isError: true);
    }
  }

  Future<void> _delete(dynamic review) async {
    final ok = await AdminUi.confirm(
      context,
      title: 'سڕینەوەی هەڵسەنگاندن',
      message: 'ئەمە بۆ هەمیشە دەسڕدرێتەوە و ناگەڕێتەوە. دڵنیایت؟',
    );
    if (!ok) return;

    final res = await ApiClient.delete('/admin/reviews/${review['type']}/${review['id']}');
    if (!mounted) return;

    if (res.statusCode == 204 || res.statusCode == 200) {
      AdminUi.toast(context, 'سڕایەوە.');
      _load();
    } else {
      AdminUi.toast(context, AdminUi.readError(res), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hiddenCount = _reviews.where((r) => r['is_hidden'] == true).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AdminAppBar(
        title: 'هەڵسەنگاندنەکان',
        subtitle: '${_reviews.length} هەڵسەنگاندن · $hiddenCount شاردراوە',
        icon: Iconsax.star,
        iconColor: const Color(0xFFD97706),
        iconBackgroundColor: const Color(0xFFFFFBEB),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Column(
              children: [
                _filterRow(
                  _typeFilters,
                  _type,
                  (v) { setState(() => _type = v); _load(); },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _filterRow(
                        _statusFilters,
                        _status,
                        (v) { setState(() => _status = v); _load(); },
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() => _lowRatingOnly = !_lowRatingOnly);
                        _load();
                      },
                      child: AdminUi.selectChip('★ ٢ و کەمتر', _lowRatingOnly),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: AdminUi.body(
              isLoading: _isLoading,
              error: _error,
              isEmpty: _reviews.isEmpty,
              emptyIcon: Iconsax.star,
              emptyText: 'هیچ هەڵسەنگاندنێک نییە',
              onRetry: _load,
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reviews.length,
                  itemBuilder: (context, i) => _buildCard(_reviews[i], i),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterRow(
    List<({String value, String label})> options,
    String selected,
    ValueChanged<String> onSelect,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options
            .map((o) => Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: GestureDetector(
                    onTap: () => onSelect(o.value),
                    child: AdminUi.selectChip(o.label, selected == o.value),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildCard(dynamic review, int index) {
    final isHidden = review['is_hidden'] == true;
    final rating = (review['rating'] as num?)?.toDouble() ?? 0;
    final ratingColor = rating <= 2
        ? const Color(0xFFEF4444)
        : rating <= 3.5
            ? const Color(0xFFD97706)
            : const Color(0xFF10B981);

    return Opacity(
      opacity: isHidden ? 0.6 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: AdminUi.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AdminUi.chip(review['type_label'] ?? '', const Color(0xFF2563EB), small: true),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    review['provider_name'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AdminUi.title,
                  ),
                ),
                const SizedBox(width: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded, size: 16, color: ratingColor),
                    const SizedBox(width: 2),
                    Text(
                      rating.toStringAsFixed(1),
                      style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: ratingColor),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              (review['comment'] ?? '').toString().isEmpty ? '(بێ کۆمێنت)' : review['comment'],
              style: const TextStyle(
                  fontFamily: 'Rabar', fontSize: 12.5, height: 1.5, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Iconsax.user, size: 13, color: Color(0xFF94A3B8)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    review['patient_name'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AdminUi.subtitle,
                  ),
                ),
                if (isHidden) AdminUi.chip('شاردراوە', const Color(0xFFEF4444), small: true),
              ],
            ),
            if (isHidden && (review['hidden_reason'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('هۆکار: ${review['hidden_reason']}',
                  style: const TextStyle(
                      fontFamily: 'Rabar', fontSize: 11, color: Color(0xFFB91C1C))),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: isHidden
                      ? AdminUi.smallButton(
                          label: 'گەڕاندنەوە',
                          icon: Iconsax.eye,
                          color: const Color(0xFF10B981),
                          onTap: () => _restore(review),
                        )
                      : AdminUi.smallButton(
                          label: 'شاردنەوە',
                          icon: Iconsax.eye_slash,
                          color: const Color(0xFFD97706),
                          onTap: () => _hide(review),
                        ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AdminUi.smallButton(
                    label: 'سڕینەوە',
                    icon: Iconsax.trash,
                    color: const Color(0xFFEF4444),
                    onTap: () => _delete(review),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 40).ms);
  }
}
