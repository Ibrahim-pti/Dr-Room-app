import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:provider/provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/providers/favorite_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/dr_room_fonts.dart';
import '../../core/utils/api_client.dart';
import 'doctor_details_models.dart';

/// Full-bleed hero carousel with the doctor's photos, collapsible app bar,
/// favourite / back buttons, name, specialty, and rating.
class DoctorDetailsHero extends StatelessWidget {
  final bool isDark;
  final double carouselHeight;
  final double heroHeight;
  final int doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String doctorImage;
  final double rating;
  final List<String> heroImages;
  final int heroPage;
  final PageController heroPageController;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onBack;
  final ImageProvider Function(String path) imageProvider;

  const DoctorDetailsHero({
    super.key,
    required this.isDark,
    required this.carouselHeight,
    required this.heroHeight,
    required this.doctorId,
    required this.doctorName,
    required this.doctorSpecialty,
    required this.doctorImage,
    required this.rating,
    required this.heroImages,
    required this.heroPage,
    required this.heroPageController,
    required this.onPageChanged,
    required this.onBack,
    required this.imageProvider,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final background = AppColors.getBackground(context);

    return SliverAppBar(
      pinned: true,
      stretch: true,
      elevation: 0,
      expandedHeight: heroHeight,
      backgroundColor: background,
      automaticallyImplyLeading: false,
      systemOverlayStyle: null,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final maxHeight = heroHeight + topPadding;
          final minHeight = kToolbarHeight + topPadding;
          final t =
              ((maxHeight - constraints.maxHeight) / (maxHeight - minHeight))
                  .clamp(0.0, 1.0);

          final overStatusBar = t < 0.5;

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: overStatusBar || isDark
                ? SystemUiOverlayStyle.light
                : SystemUiOverlayStyle.dark,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: background),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Opacity(
                    opacity: (1 - t * 1.6).clamp(0.0, 1.0),
                    child: _buildHeroContent(context, topPadding),
                  ),
                ),
                Positioned(
                  left: 56,
                  right: 56,
                  top: topPadding,
                  height: kToolbarHeight,
                  child: Opacity(
                    opacity: ((t - 0.6) / 0.4).clamp(0.0, 1.0),
                    child: Center(
                      child: Text(
                        doctorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: AppColors.getTextTitle(context),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: topPadding + 4,
                  left: 12,
                  right: 12,
                  child: _buildHeroActions(context, t),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroContent(BuildContext context, double topPadding) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeroCarousel(context, topPadding),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            doctorName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: AppColors.getTextTitle(context),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _heroPill(context, Iconsax.health, doctorSpecialty),
            if (rating > 0) ...[
              const SizedBox(width: 8),
              _heroPill(
                context,
                Icons.star_rounded,
                rating.toStringAsFixed(1),
                iconColor: const Color(0xFFFBBF24),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildHeroCarousel(BuildContext context, double topPadding) {
    final images = heroImages;

    return ClipPath(
      clipper: const HeroCurveClipper(),
      child: SizedBox(
        height: topPadding + carouselHeight,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: heroPageController,
              itemCount: images.length,
              onPageChanged: onPageChanged,
              itemBuilder: (context, index) => Image(
                image: imageProvider(images[index]),
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: AppColors.getSurfaceSecondary(context),
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  );
                },
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.primary,
                  child: const Icon(
                    Iconsax.user,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.45),
                      Colors.black.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.18, 0.4],
                  ),
                ),
              ),
            ),
            if (images.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 70,
                child: Center(
                  child: AnimatedSmoothIndicator(
                    activeIndex: heroPage,
                    count: images.length,
                    effect: ExpandingDotsEffect(
                      dotHeight: 6,
                      dotWidth: 6,
                      expansionFactor: 3.5,
                      spacing: 5,
                      dotColor: Colors.white.withValues(alpha: 0.5),
                      activeDotColor: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _heroPill(
    BuildContext context,
    IconData icon,
    String label, {
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.getSurface(context),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.getBorder(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: iconColor ?? AppColors.primary),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: AppColors.getTextTitle(context),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroActions(BuildContext context, double t) {
    final fade = ((t - 0.5) / 0.5).clamp(0.0, 1.0);
    final iconColor = Color.lerp(
      Colors.white,
      AppColors.getTextTitle(context),
      fade,
    )!;
    final chipColor = Color.lerp(
      Colors.black.withValues(alpha: 0.3),
      AppColors.getSurface(context),
      fade,
    )!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _heroIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          color: iconColor,
          background: chipColor,
          onTap: onBack,
        ),
        Consumer<FavoriteProvider>(
          builder: (context, favorites, _) {
            final isFavorite = favorites.isFavorite(doctorId);
            return _heroIconButton(
              icon: isFavorite ? Icons.favorite_rounded : Iconsax.heart,
              color: isFavorite ? AppColors.error : iconColor,
              background: chipColor,
              onTap: () => favorites.toggleFavorite({
                'id': doctorId,
                'doctor': doctorName,
                'specialty': doctorSpecialty,
                'image': doctorImage,
              }),
            );
          },
        ),
      ],
    );
  }

  Widget _heroIconButton({
    required IconData icon,
    required Color color,
    required Color background,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: Icon(icon, size: 19, color: color),
        ),
      ),
    );
  }
}
