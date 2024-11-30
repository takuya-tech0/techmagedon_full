// lib/shared/widgets/custom_app_bar.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/themes/app_theme.dart';


class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});


  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 1,
      leading: Padding(
        padding: AppSpacing.paddingXS,
        child: IconButton(
          icon: const Icon(
            Icons.list,
            color: AppColors.textPrimary,
            size: 28,
          ),
          onPressed: () {},
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            AppConstants.courseTitle,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppConstants.lessonTitle,
            style: AppTextStyles.h3,
          ),
        ],
      ),
    );
  }


  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}