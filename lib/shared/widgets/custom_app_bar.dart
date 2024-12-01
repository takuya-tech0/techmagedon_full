// lib/shared/widgets/custom_app_bar.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/themes/app_theme.dart';
import 'contents_list_modal.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  _CustomAppBarState createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  bool _isBookmarked = false; // ヘッダーのブックマーク状態を管理
  final List<bool> _isCheckedList = [false, false, false]; // コンテンツのチェックボックス状態を管理
  final List<bool> _isBookmarkedList = [false, false, false]; // コンテンツのブックマーク状態を管理

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFFFFFFF),
      elevation: 1,
      leading: Padding(
        padding: AppSpacing.paddingXS,
        child: IconButton(
          icon: const Icon(
            Icons.list,
            color: AppColors.textPrimary,
            size: 28,
          ),
          onPressed: () {
            _showFullScreenModal(context);
          },
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
      actions: [
        Padding(
          padding: AppSpacing.paddingXS,
          child: IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: const Color(0xFFBA1A1A),
              size: 28,
            ),
            onPressed: () {
              setState(() {
                _isBookmarked = !_isBookmarked;
              });
            },
          ),
        ),
      ],
    );
  }

  void _showFullScreenModal(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => FullScreenContentList(
          isCheckedList: _isCheckedList,
          isBookmarkedList: _isBookmarkedList,
          onStateChanged: (checkedList, bookmarkedList) {
            setState(() {
              _isCheckedList.setAll(0, checkedList);
              _isBookmarkedList.setAll(0, bookmarkedList);
            });
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(-1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
  }
}