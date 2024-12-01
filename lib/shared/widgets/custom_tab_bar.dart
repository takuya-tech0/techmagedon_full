// lib/shared/widgets/custom_tab_bar.dart
import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';


class CustomTabBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomTabBar({super.key});


  @override
  Widget build(BuildContext context) {
    return TabBar(
      indicatorColor: AppColors.primary,
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textSecondary,
      labelStyle: AppTextStyles.body1,
      unselectedLabelStyle: AppTextStyles.body2,
      tabs: const [
        Tab(text: "テキスト"),
        Tab(text: "AIチャット"),
        Tab(text: "みんなの叡智"),
      ],
    );
  }


  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
