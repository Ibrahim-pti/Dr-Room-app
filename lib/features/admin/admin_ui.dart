import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax_flutter/iconsax_flutter.dart';

/// Shared building blocks for the admin screens: one form sheet, one error
/// banner, one empty state — so every module looks and fails the same way.
class AdminUi {
  static const _font = 'Rabar';

  static const title = TextStyle(
    fontFamily: _font,
    fontSize: 14.5,
    fontWeight: FontWeight.bold,
    color: Color(0xFF0F172A),
  );

  static const subtitle = TextStyle(
    fontFamily: _font,
    fontSize: 12,
    height: 1.4,
    color: Color(0xFF64748B),
  );

  static BoxDecoration get cardDecoration => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  /// Turns a Laravel error payload into one Kurdish sentence.
  static String readError(http.Response res) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map) {
        if (decoded['errors'] is Map) {
          final first = (decoded['errors'] as Map).values.first;
          return first is List ? first.first.toString() : first.toString();
        }
        if (decoded['message'] != null) return decoded['message'].toString();
      }
    } catch (_) {}

    return switch (res.statusCode) {
      401 || 403 => 'دەسەڵاتت نییە بۆ ئەم کارە.',
      404 => 'نەدۆزرایەوە.',
      _ => 'هەڵە ڕوویدا (${res.statusCode}).',
    };
  }

  static void toast(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? const Color(0xFFB91C1C) : const Color(0xFF0F172A),
        content: Text(message, style: const TextStyle(fontFamily: _font)),
      ),
    );
  }

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'بەڵێ، بیسڕەوە',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: const TextStyle(fontFamily: _font, fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(message, style: const TextStyle(fontFamily: _font, fontSize: 13, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('پاشگەزبوونەوە', style: TextStyle(fontFamily: _font)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel,
                style: const TextStyle(fontFamily: _font, color: Colors.white)),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  /// Loading / error / empty / content, in the order a screen needs them.
  static Widget body({
    required bool isLoading,
    required String? error,
    required bool isEmpty,
    required IconData emptyIcon,
    required String emptyText,
    required VoidCallback onRetry,
    required Widget child,
  }) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 44, color: Color(0xFFEF4444)),
              const SizedBox(height: 12),
              Text(error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: _font, fontSize: 13, height: 1.5)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('دووبارە هەوڵ بدەرەوە', style: TextStyle(fontFamily: _font)),
              ),
            ],
          ),
        ),
      );
    }

    if (isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(emptyIcon, size: 48, color: const Color(0xFFCBD5E1)),
            const SizedBox(height: 12),
            Text(emptyText,
                style: const TextStyle(fontFamily: _font, fontSize: 13, color: Color(0xFF94A3B8))),
          ],
        ),
      );
    }

    return child;
  }

  static Widget primaryAction({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    Color color = const Color(0xFF2563EB),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontFamily: _font, fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  static Widget smallButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontFamily: _font, fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  static Widget chip(String text, Color color, {bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: small ? 7 : 9, vertical: small ? 3 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: _font,
          fontSize: small ? 10 : 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  static Widget selectChip(String text, bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: selected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: _font,
          fontSize: 12,
          fontWeight: selected ? FontWeight.bold : FontWeight.w600,
          color: selected ? Colors.white : const Color(0xFF475569),
        ),
      ),
    );
  }

  static Widget label(String text) => Text(
        text,
        style: const TextStyle(
            fontFamily: _font, fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
      );

  static Widget notice(String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2563EB).withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2563EB).withValues(alpha: 0.2)),
        ),
        child: Text(text,
            style: const TextStyle(
                fontFamily: _font, fontSize: 11.5, height: 1.5, color: Color(0xFF1E40AF))),
      );

  static Widget input({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    bool obscure = false,
    TextInputType? keyboard,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        maxLines: obscure ? 1 : maxLines,
        obscureText: obscure,
        keyboardType: keyboard,
        style: const TextStyle(fontFamily: _font, fontSize: 13.5, height: 1.6, color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              fontFamily: _font, color: Color(0xFF94A3B8), fontSize: 12.5, height: 1.6),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }

  static Widget checkboxRow({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: Checkbox(
                value: value,
                onChanged: onChanged,
                activeColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
            Expanded(
              child: Text(label,
                  style: const TextStyle(fontFamily: _font, fontSize: 12.5, color: Color(0xFF334155))),
            ),
          ],
        ),
      ),
    );
  }

  /// A bottom sheet with a pinned header, a scrolling body, an inline error
  /// banner (a SnackBar would land behind the sheet), and one submit button.
  ///
  /// [onSubmit] returns true when the sheet should close.
  static Future<void> formSheet({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String submitLabel,
    required List<Widget> Function(void Function(VoidCallback) setSheetState, void Function(String?) setError) builder,
    required Future<bool> Function(void Function(String?) setError) onSubmit,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
      builder: (ctx) {
        String? errorMessage;
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            void setError(String? message) => setSheetState(() => errorMessage = message);

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 20,
                right: 20,
                top: 12,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: Color(0xFF0F172A)),
                          tooltip: 'گەڕانەوە',
                          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style: const TextStyle(
                                    fontFamily: _font,
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A))),
                            const SizedBox(height: 4),
                            Text(subtitle,
                                style: const TextStyle(
                                    fontFamily: _font, fontSize: 11.5, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...builder(setSheetState, setError),
                          const SizedBox(height: 18),
                          if (errorMessage != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.35)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.error_outline, size: 18, color: Color(0xFFEF4444)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(errorMessage!,
                                        style: const TextStyle(
                                            fontFamily: _font,
                                            fontSize: 12,
                                            height: 1.4,
                                            color: Color(0xFFB91C1C))),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      setSheetState(() {
                                        errorMessage = null;
                                        isSubmitting = true;
                                      });

                                      bool shouldClose = false;
                                      try {
                                        shouldClose = await onSubmit(setError);
                                      } catch (e) {
                                        setError('کێشەیەک لە پەیوەندی هەیە: $e');
                                      }

                                      if (!ctx.mounted) return;
                                      setSheetState(() => isSubmitting = false);
                                      if (shouldClose) Navigator.of(ctx).pop();
                                    },
                              child: isSubmitting
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                    )
                                  : Text(submitLabel,
                                      maxLines: 1,
                                      style: const TextStyle(
                                          fontFamily: _font,
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          height: 1.5)),
                            ),
                          ),
                        ],
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

/// Keeps `Iconsax` referenced for screens that only use it via this file.
const IconData kAdminFallbackIcon = Iconsax.category;
