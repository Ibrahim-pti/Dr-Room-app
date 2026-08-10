import 'dart:async';

import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/models/appointment_model.dart' show Doctor;
import '../../core/providers/appointment_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'booking_slot_screen.dart' show DoctorAvatar;
import 'doctor_profile_screen.dart';

/// Browse and filter doctors.
///
/// `GET /doctors` only supports a `specialty` query parameter, so the search
/// box and rating chips are applied client-side inside AppointmentService.
class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({super.key});

  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  String? _specialty;
  double? _minRating;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _load() {
    context.read<AppointmentProvider>().fetchDoctors(
          search: _searchController.text,
          specialty: _specialty,
          minRating: _minRating,
        );
  }

  /// Typing refires the query, so wait for a pause rather than hitting the
  /// endpoint on every keystroke.
  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _load);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppointmentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Find a doctor', style: AppTypography.headingSm),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchField(),
          _buildSpecialtyChips(provider.doctors),
          _buildRatingChips(),
          const SizedBox(height: 8),
          Expanded(child: _buildBody(provider)),
        ],
      ),
    );
  }

  Widget _buildBody(AppointmentProvider provider) {
    if (provider.isLoading && provider.doctors.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.doctors.isEmpty) {
      return _Message(
        icon: Iconsax.warning_2,
        title: 'Could not load doctors',
        body: provider.error!,
        action: FilledButton(onPressed: _load, child: const Text('Try again')),
      );
    }

    if (provider.doctors.isEmpty) {
      return const _Message(
        icon: Iconsax.user_search,
        title: 'No doctors match',
        body: 'Try a different specialty or clear the filters.',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _load(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: provider.doctors.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _DoctorCard(doctor: provider.doctors[i]),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search by name or specialty',
          hintStyle: AppTypography.bodySm.copyWith(color: AppColors.textMedium),
          prefixIcon: Icon(Iconsax.search_normal,
              size: 18, color: AppColors.textMedium),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Iconsax.close_circle,
                      size: 18, color: AppColors.textMedium),
                  onPressed: () {
                    _searchController.clear();
                    _load();
                  },
                ),
          filled: true,
          fillColor: AppColors.surfaceLightSecondary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.cardBorderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.cardBorderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  /// Specialties come from whatever the API returned rather than a hardcoded
  /// list, so the chips can never offer a specialty with no doctors behind it.
  Widget _buildSpecialtyChips(List<Doctor> doctors) {
    final specialties = {
      ...doctors.map((d) => d.specialty).where((s) => s.isNotEmpty),
      if (_specialty != null) _specialty!,
    }.toList()
      ..sort();

    if (specialties.isEmpty) return const SizedBox.shrink();

    return _ChipRow(
      children: [
        _FilterChip(
          label: 'All',
          selected: _specialty == null,
          onTap: () {
            setState(() => _specialty = null);
            _load();
          },
        ),
        for (final s in specialties)
          _FilterChip(
            label: s,
            selected: _specialty == s,
            onTap: () {
              setState(() => _specialty = _specialty == s ? null : s);
              _load();
            },
          ),
      ],
    );
  }

  Widget _buildRatingChips() {
    const options = <double?>[null, 3, 4, 4.5];
     
    return _ChipRow(
      children: [
        for (final rating in options)
          _FilterChip(
            label: rating == null ? 'Any rating' : '$rating+',
            icon: rating == null ? null : Iconsax.star,
            selected: _minRating == rating,
            onTap: () {
              setState(() => _minRating = _minRating == rating ? null : rating);
              _load();
            },
          ),
      ],
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final Doctor doctor;
  const _DoctorCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DoctorProfileScreen(doctor: doctor),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardBorderLight),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            DoctorAvatar(imageUrl: doctor.imageUrl, size: 72),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctor.name,
                    style:
                        AppTypography.labelMd.copyWith(color: AppColors.textDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    doctor.specialty,
                    style: AppTypography.bodySm.copyWith(color: AppColors.primary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (doctor.totalReviews > 0) ...[
                        Icon(Iconsax.star, size: 13, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text(
                          '${doctor.rating} (${doctor.totalReviews})',
                          style: AppTypography.bodySm
                              .copyWith(color: AppColors.textMedium),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (doctor.experienceYears > 0)
                        Text(
                          '${doctor.experienceYears} yrs',
                          style: AppTypography.bodySm
                              .copyWith(color: AppColors.textMedium),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              doctor.formattedFee,
              style: AppTypography.labelMd.copyWith(color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  final List<Widget> children;
  const _ChipRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => children[i],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surfaceLightSecondary,
            border: selected
                ? null
                : Border.all(color: AppColors.cardBorderLight),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 13,
                    color: selected ? Colors.white : AppColors.warning),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: AppTypography.labelSm.copyWith(
                  color: selected ? Colors.white : AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textLight),
            const SizedBox(height: 16),
            Text(
              title,
              style: AppTypography.labelLg.copyWith(color: AppColors.textDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: AppTypography.bodySm.copyWith(color: AppColors.textMedium),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
