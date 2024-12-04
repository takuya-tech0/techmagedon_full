// lib/shared/widgets/custom_tab_bar.dart
import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';

class CustomTabBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFEEEEEE),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        labelColor: Colors.purple,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.purple,
        indicatorWeight: 3,
        labelPadding: const EdgeInsets.symmetric(vertical: 8.0),
        tabs: const [
          _TabItem(
            icon: Icons.menu_book_outlined,
            label: 'テキスト',
          ),
          _TabItem(
            icon: Icons.chat_bubble_outline,
            label: 'AIチャット',
          ),
          _TabItem(
            icon: Icons.group_outlined,
            label: 'みんなの叡智',
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(48.0);
}

class _TabItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TabItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 48.0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}