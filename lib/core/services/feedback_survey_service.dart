import 'dart:convert';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_colors.dart';
import '../utils/api_client.dart';
import '../utils/localization_extensions.dart';

/// Fetches the latest active feedback survey for the logged-in user and shows
/// a modern modal dialog once per survey until a new survey is created/activated.
class FeedbackSurveyService {
  FeedbackSurveyService._();

  static const String _submittedStorageKey = 'submitted_feedback_survey_ids_v1';
  static final Set<int> _dismissedInSession = <int>{};
  static bool _isDialogOpen = false;

  static Future<void> checkAndShow(BuildContext context) async {
    if (_isDialogOpen) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) return;

      final res = await ApiClient.get('/feedback-surveys/active');
      if (res.statusCode != 200) return;

      final decoded = jsonDecode(res.body);
      final rawSurvey = decoded is Map ? decoded['data'] : null;
      if (rawSurvey is! Map) return;

      final survey = Map<String, dynamic>.from(rawSurvey);
      final int? surveyId = int.tryParse('${survey['id']}');
      if (surveyId == null) return;

      final submittedList =
          prefs.getStringList(_submittedStorageKey) ?? const <String>[];
      if (submittedList.contains('$surveyId') ||
          _dismissedInSession.contains(surveyId)) {
        return;
      }

      // Let the home screen settle briefly before presenting the modal.
      await Future.delayed(const Duration(milliseconds: 650));
      if (!context.mounted || _isDialogOpen) return;

      _isDialogOpen = true;
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (dialogCtx) => _FeedbackSurveyDialog(
          survey: survey,
          surveyId: surveyId,
          onSubmitted: () async {
            final updated = List<String>.from(
              prefs.getStringList(_submittedStorageKey) ?? const <String>[],
            );
            if (!updated.contains('$surveyId')) {
              updated.add('$surveyId');
              await prefs.setStringList(_submittedStorageKey, updated);
            }
          },
          onDismissedForSession: () {
            _dismissedInSession.add(surveyId);
          },
        ),
      );
    } catch (e) {
      debugPrint('Feedback survey check skipped: $e');
    } finally {
      _isDialogOpen = false;
    }
  }
}

class _FeedbackSurveyDialog extends StatefulWidget {
  final Map<String, dynamic> survey;
  final int surveyId;
  final Future<void> Function() onSubmitted;
  final VoidCallback onDismissedForSession;

  const _FeedbackSurveyDialog({
    required this.survey,
    required this.surveyId,
    required this.onSubmitted,
    required this.onDismissedForSession,
  });

  @override
  State<_FeedbackSurveyDialog> createState() => _FeedbackSurveyDialogState();
}

class _FeedbackSurveyDialogState extends State<_FeedbackSurveyDialog> {
  final TextEditingController _suggestionCtrl = TextEditingController();
  int _rating = 0;
  String? _satisfaction; // satisfied | neutral | unsatisfied
  bool _isSubmitting = false;
  String? _inlineError;

  @override
  void dispose() {
    _suggestionCtrl.dispose();
    super.dispose();
  }

  String _ratingLabel(int stars) {
    return switch (stars) {
      1 => 'feedback_rating_1'.tr(),
      2 => 'feedback_rating_2'.tr(),
      3 => 'feedback_rating_3'.tr(),
      4 => 'feedback_rating_4'.tr(),
      5 => 'feedback_rating_5'.tr(),
      _ => '',
    };
  }

  Future<void> _submit() async {
    if (_rating < 1) {
      setState(() => _inlineError = 'feedback_select_rating'.tr());
      return;
    }

    setState(() {
      _isSubmitting = true;
      _inlineError = null;
    });

    try {
      final localeCode = context.locale.languageCode;
      final res = await ApiClient.post(
        '/feedback-surveys/${widget.surveyId}/respond',
        body: {
          'rating': _rating,
          'is_satisfied': _satisfaction,
          'suggestion': _suggestionCtrl.text.trim(),
          'locale': localeCode,
        },
      );

      if (!mounted) return;

      if (res.statusCode == 200 || res.statusCode == 201) {
        await widget.onSubmitted();
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'feedback_thank_you'.tr(),
                    style: const TextStyle(fontFamily: 'Rabar'),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        String msg = 'Error (${res.statusCode})';
        try {
          final body = jsonDecode(res.body);
          if (body is Map && body['message'] != null) {
            msg = body['message'].toString();
          }
        } catch (_) {}
        setState(() {
          _inlineError = msg;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _inlineError = '$e';
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = context.localizedField(
      widget.survey,
      'title',
      fallback: 'feedback_default_title'.tr(),
    );
    final ratingQuestion = context.localizedField(
      widget.survey,
      'rating_question',
      fallback: 'feedback_default_rating_q'.tr(),
    );
    final suggestionQuestion = context.localizedField(
      widget.survey,
      'suggestion_question',
      fallback: 'feedback_default_suggestion_q'.tr(),
    );

    final satisfactionOptions = [
      (
        key: 'satisfied',
        label: 'feedback_satisfied_yes'.tr(),
        icon: Icons.sentiment_very_satisfied_rounded,
        color: const Color(0xFF059669),
      ),
      (
        key: 'neutral',
        label: 'feedback_satisfied_mid'.tr(),
        icon: Icons.sentiment_satisfied_rounded,
        color: const Color(0xFFD97706),
      ),
      (
        key: 'unsatisfied',
        label: 'feedback_satisfied_no'.tr(),
        icon: Icons.sentiment_dissatisfied_rounded,
        color: const Color(0xFFE11D48),
      ),
    ];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          color: AppColors.getSurface(context),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.getBorder(context)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.14),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top badge + close button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Iconsax.message_favorite,
                          size: 14,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'feedback_badge'.tr(),
                          style: const TextStyle(
                            fontFamily: 'Rabar',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            widget.onDismissedForSession();
                            Navigator.pop(context);
                          },
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: AppColors.getTextSubtitle(context),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Decorative icon + title
              Center(
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Iconsax.star_1,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextTitle(context),
                ),
              ),
              const SizedBox(height: 16),

              // Question 1: Satisfaction & Stars
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.getBackground(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.getBorder(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ratingQuestion,
                      style: TextStyle(
                        fontFamily: 'Rabar',
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextTitle(context),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Satisfaction quick pills
                    Row(
                      children: satisfactionOptions.map((opt) {
                        final selected = _satisfaction == opt.key;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _satisfaction = opt.key;
                              if (_rating == 0) {
                                _rating = switch (opt.key) {
                                  'satisfied' => 5,
                                  'neutral' => 3,
                                  _ => 2,
                                };
                              }
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 4,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? opt.color.withValues(alpha: 0.14)
                                    : AppColors.getSurface(context),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selected
                                      ? opt.color
                                      : AppColors.getBorder(context),
                                  width: selected ? 1.4 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    opt.icon,
                                    size: 20,
                                    color: selected
                                        ? opt.color
                                        : AppColors.getTextSubtitle(context),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    opt.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Rabar',
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: selected
                                          ? opt.color
                                          : AppColors.getTextSubtitle(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Interactive 5-star row
                    Center(
                      child: Text(
                        _rating > 0
                            ? _ratingLabel(_rating)
                            : 'feedback_rate_experience'.tr(),
                        style: TextStyle(
                          fontFamily: 'Rabar',
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: _rating > 0
                              ? const Color(0xFFF59E0B)
                              : AppColors.getTextSubtitle(context),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final starVal = i + 1;
                        final active = starVal <= _rating;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _rating = starVal;
                            _inlineError = null;
                          }),
                          child: AnimatedScale(
                            scale: active ? 1.12 : 1.0,
                            duration: const Duration(milliseconds: 160),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              child: Icon(
                                active
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 34,
                                color: active
                                    ? const Color(0xFFF59E0B)
                                    : (isDark
                                        ? const Color(0xFF475569)
                                        : const Color(0xFFCBD5E1)),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Question 2: Suggestions / What to add
              Text(
                suggestionQuestion,
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextTitle(context),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _suggestionCtrl,
                maxLines: 3,
                style: TextStyle(
                  fontFamily: 'Rabar',
                  fontSize: 13,
                  color: AppColors.getTextTitle(context),
                ),
                decoration: InputDecoration(
                  hintText: 'feedback_suggestion_hint'.tr(),
                  hintStyle: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 12,
                    color: AppColors.getTextSubtitle(context),
                  ),
                  filled: true,
                  fillColor: AppColors.getBackground(context),
                  contentPadding: const EdgeInsets.all(12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.getBorder(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: AppColors.getBorder(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Color(0xFF2563EB),
                      width: 1.4,
                    ),
                  ),
                ),
              ),

              if (_inlineError != null) ...[
                const SizedBox(height: 10),
                Text(
                  _inlineError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFE11D48),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Submit button (with explicit padding so text never clips)
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Iconsax.send_2, size: 18),
                  label: Text(
                    'feedback_submit'.tr(),
                    style: const TextStyle(
                      fontFamily: 'Rabar',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () {
                        widget.onDismissedForSession();
                        Navigator.pop(context);
                      },
                child: Text(
                  'feedback_later'.tr(),
                  style: TextStyle(
                    fontFamily: 'Rabar',
                    fontSize: 12.5,
                    color: AppColors.getTextSubtitle(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 240.ms).scale(
            begin: const Offset(0.95, 0.95),
            end: const Offset(1, 1),
            curve: Curves.easeOutBack,
          ),
    );
  }
}
