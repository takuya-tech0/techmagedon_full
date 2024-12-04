// lib/shared/widgets/custom_app_bar.dart
import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? materialTitle;
  final String? unitName;

  const CustomAppBar({
    super.key,
    this.materialTitle,
    this.unitName,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(
            Icons.menu,
            color: Colors.black87,
          ),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            unitName ?? "第1章 物体の位置、速度、加速度",
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            materialTitle ?? "1. 変位、速度、加速度、等加速度",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.bookmark_border,
            color: Colors.purple,
          ),
          onPressed: () {
            // ブックマーク機能の実装
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}