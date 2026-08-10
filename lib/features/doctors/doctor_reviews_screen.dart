import 'dart:convert';

import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/api_client.dart';
import '../../main.dart';

const _starColor = Color(0xFFF59E0B);

class DoctorReviewsScreen extends StatefulWidget {
  final int doctorId;
  final String doctorName;
  final String rating;

  const DoctorReviewsScreen({
    super.key,
    required this.doctorId,
    required this.doctorName,
    required this.rating,
  });

  @override
  State<DoctorReviewsScreen> createState() => _DoctorReviewsScreenState();
}

class _DoctorReviewsScreenState extends State<DoctorReviewsScreen> {
  List<dynamic> _reviews = [];
  Map<String, int> _breakdown = {};
  double _average = 0;
  int _total = 0;

  bool _loading = true;
  bool _failed = false;

  // Owned by the screen, not the sheet: the sheet's closing animation keeps
  // rebuilding its TextField for a few frames after the route is popped.
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _average = double.tryParse(widget.rating) ?? 0;
    _fetchReviews();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _fetchReviews() async {
    try {
      final response =
          await ApiClient.get('/doctors/${widget.doctorId}/reviews');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (!mounted) return;
        setState(() {
          _reviews = (data['reviews'] as List?) ?? const [];
          _average = double.tryParse(data['rating'].toString()) ?? 0;
          _total = int.tryParse(data['total_reviews'].toString()) ?? 0;
          _breakdown = ((data['breakdown'] as Map?) ?? {}).map(
            (key, value) => MapEntry(
              key.toString(),
              int.tryParse(value.toString()) ?? 0,
            ),
          );
          _loading = false;
          _failed = false;
        });
        return;
      }
    } catch (_) {
      // Handled by the failure state below.
    }
    if (mounted) {
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _submitReview(int rating, String comment) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (!mounted) return;

    if (token == null || token.isEmpty) {
      Navigator.pop(context); // close the sheet before routing away
      _promptLogin();
      return;
    }

    try {
      final response = await ApiClient.post(
        '/doctors/${widget.doctorId}/reviews',
        body: {
          'rating': rating,
          if (comment.trim().isNotEmpty) 'comment': comment.trim(),
        },
      );
      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context);
        _toast('rv_thanks'.tr(), AppColors.success);
        _fetchReviews();
        return;
      }
    } catch (_) {
      // Falls through to the error toast.
    }
    if (mounted) _toast('rv_failed'.tr(), AppColors.error);
  }

  void _toast(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _promptLogin() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.getSurface(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'dd_login_title'.tr(),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: AppColors.getTextTitle(context),
          ),
        ),
        content: Text(
          'dd_login_desc'.tr(),
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            height: 1.7,
            color: AppColors.getTextSubtitle(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'dd_later'.tr(),
              style: GoogleFonts.poppins(
                color: AppColors.getTextSubtitle(context),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const AppFlow(startAtLogin: true),
                ),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'dd_login'.tr(),
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  /// intl has no Kurdish date symbols, so month names come from the
  /// translation files (shared with the doctor details screen).
  String _formatDate(String? iso) {
    if (iso == null) return '';
    final date = DateTime.tryParse(iso)?.toLocal();
    if (date == null) return '';
    return '${date.day} ${'mo_${date.month}'.tr()} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(context),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'reviews_ratings'.tr(),
          style: GoogleFonts.poppins(
            color: AppColors.getTextTitle(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: AppColors.getTextTitle(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchReviews,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    _buildRatingSummary(),
                    const SizedBox(height: 8),
                    if (_failed)
                      _buildMessage('rv_load_failed'.tr())
                    else if (_reviews.isEmpty)
                      _buildMessage('rv_empty'.tr(), 'rv_empty_sub'.tr())
                    else
                      _buildReviewList(),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildWriteBar(),
    );
  }

  Widget _buildWriteBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 14),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        border: Border(top: BorderSide(color: AppColors.getDivider(context))),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _showWriteReviewSheet,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: Text(
              'write_review'.tr(),
              style: GoogleFonts.poppins(
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSummary() {
    return Container(
      color: AppColors.getSurface(context),
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                _average > 0 ? _average.toStringAsFixed(1) : '—',
                style: GoogleFonts.poppins(
                  color: AppColors.getTextTitle(context),
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return Icon(
                    Iconsax.star_1,
                    color: index < _average.round()
                        ? _starColor
                        : _starColor.withValues(alpha: 0.25),
                    size: 15,
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                'based_on_reviews'.tr(args: ['$_total']),
                style: GoogleFonts.poppins(
                  color: AppColors.getTextSubtitle(context),
                  fontSize: 11,
                ),
              ),
            ],
          ).animate().fadeIn().slideX(begin: -0.2, end: 0),
          const SizedBox(width: 28),
          Expanded(
            child: Column(
              children: [
                for (final star in [5, 4, 3, 2, 1])
                  _buildRatingBar(star, _breakdown['$star'] ?? 0),
              ],
            ).animate().fadeIn().slideX(begin: 0.2, end: 0),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(int stars, int count) {
    final fraction = _total > 0 ? count / _total : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$stars',
            style: GoogleFonts.poppins(
              color: AppColors.getTextTitle(context),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                backgroundColor: AppColors.getBorder(context),
                valueColor: const AlwaysStoppedAnimation<Color>(_starColor),
                minHeight: 7,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 22,
            child: Text(
              '$count',
              textAlign: TextAlign.end,
              style: GoogleFonts.poppins(
                color: AppColors.getTextSubtitle(context),
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(String title, [String? subtitle]) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 60, 40, 40),
      child: Column(
        children: [
          Icon(Iconsax.message_text, size: 44, color: AppColors.textLight),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: AppColors.getTextTitle(context),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.getTextSubtitle(context),
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: _reviews.length,
      separatorBuilder: (context, index) => const Divider(height: 32),
      itemBuilder: (context, index) {
        final review = _reviews[index] as Map<String, dynamic>;
        final name = review['patient_name']?.toString() ?? 'rv_patient'.tr();
        final rating = int.tryParse(review['rating'].toString()) ?? 0;
        final comment = review['comment']?.toString() ?? '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Text(
                    name.isNotEmpty ? name.characters.first : '?',
                    style: GoogleFonts.poppins(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: AppColors.getTextTitle(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _formatDate(review['created_at']?.toString()),
                        style: GoogleFonts.poppins(
                          color: AppColors.getTextSubtitle(context),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (starIndex) {
                    return Icon(
                      Iconsax.star_1,
                      color: starIndex < rating
                          ? _starColor
                          : AppColors.getBorder(context),
                      size: 13,
                    );
                  }),
                ),
              ],
            ),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                comment,
                style: GoogleFonts.poppins(
                  color: AppColors.getTextTitle(context),
                  fontSize: 13.5,
                  height: 1.6,
                ),
              ),
            ],
          ],
        ).animate(delay: (60 * index).ms).fadeIn().slideY(begin: 0.1, end: 0);
      },
    );
  }

  void _showWriteReviewSheet() {
    var selectedRating = 5;
    var sending = false;
    _commentController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.fromLTRB(
                24,
                12,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.getDivider(context),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'rv_how_was'.tr(),
                    style: GoogleFonts.poppins(
                      color: AppColors.getTextTitle(context),
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'rv_rate'.tr(args: [widget.doctorName]),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: AppColors.getTextSubtitle(context),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < selectedRating ? Iconsax.star_1 : Iconsax.star,
                          color: _starColor,
                          size: 34,
                        ),
                        onPressed: () =>
                            setSheetState(() => selectedRating = index + 1),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.getBorder(context)),
                    ),
                    child: TextField(
                      controller: _commentController,
                      maxLines: 4,
                      maxLength: 1000,
                      style: GoogleFonts.poppins(
                        color: AppColors.getTextTitle(context),
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'rv_hint'.tr(),
                        counterText: '',
                        hintStyle: GoogleFonts.poppins(
                          color: AppColors.getTextSubtitle(context),
                          fontSize: 13.5,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'rv_edit_note'.tr(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: AppColors.textLight,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: sending
                          ? null
                          : () async {
                              setSheetState(() => sending = true);
                              await _submitReview(
                                selectedRating,
                                _commentController.text,
                              );
                              if (sheetContext.mounted) {
                                setSheetState(() => sending = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: sending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              'submit_review'.tr(),
                              style: GoogleFonts.poppins(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
