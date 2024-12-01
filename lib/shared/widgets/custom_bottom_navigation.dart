// lib/shared/widgets/custom_bottom_navigation.dart
import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';


class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;


  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });


  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined, size: 28),
          label: 'ホーム',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today, size: 28),
          label: '学習プラン',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.menu_book, size: 28),
          label: '講座一覧',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.smart_toy_outlined, size: 28),
          label: 'AI相談',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.diversity_3_outlined, size: 28),
          label: 'みんなの叡智',
        ),
      ],
      currentIndex: currentIndex,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      selectedLabelStyle: AppTextStyles.caption,
      unselectedLabelStyle: AppTextStyles.caption,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.primaryLight,
    );
  }
}
