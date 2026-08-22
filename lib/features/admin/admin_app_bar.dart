import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color iconColor;
  final Color iconBackgroundColor;
  final List<Widget>? actions;
  final String? imagePath;
  final String? titleFontFamily;
  final TextStyle? titleStyle;
  final Widget? titleWidget;
  final bool showBackButton;

  const AdminAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.iconColor,
    required this.iconBackgroundColor,
    this.actions,
    this.imagePath,
    this.titleFontFamily,
    this.titleStyle,
    this.titleWidget,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool canPop = showBackButton;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 12,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.getBackground(context),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (canPop) ...[
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                margin: const EdgeInsetsDirectional.only(end: 10),
                decoration: BoxDecoration(
                  color: AppColors.getSurface(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.getBorder(context)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.getTextTitle(context),
                  size: 16,
                ),
              ),
            ),
          ],
          if (imagePath != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                imagePath!,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 4),
          ] else if (icon != null) ...[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                titleWidget ?? Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle ?? TextStyle(
                    fontFamily: titleFontFamily ?? 'Rabar',
                    color: AppColors.getTextTitle(context),
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Rabar',
                      color: AppColors.getTextSubtitle(context),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (actions != null) ...[
            const SizedBox(width: 8),
            ...actions!,
          ],
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(92);
}