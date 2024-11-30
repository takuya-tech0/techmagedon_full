/*
# lib/features/bulletin_board/screens/bulletin_board_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/themes/app_theme.dart';
import '../widgets/post_list.dart';

class BulletinBoardScreen extends StatefulWidget {
  const BulletinBoardScreen({super.key});

  @override
  _BulletinBoardScreenState createState() => _BulletinBoardScreenState();
}

class _BulletinBoardScreenState extends State<BulletinBoardScreen> {
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addComment(String content) async {
    if (content.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('posts').add({
          'content': content,
          'timestamp': FieldValue.serverTimestamp(),
          'author': '@匿名さん',
          'likes': 0,
          'dislikes': 0,
        });
        _commentController.clear();
        FocusScope.of(context).unfocus();
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('投稿が完了しました'),
            backgroundColor: AppColors.primary,
          ),
        );
      } catch (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('投稿に失敗しました。ネットワークを確認してください。'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: PostList()),
        Container(
          padding: AppSpacing.paddingMD,
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border(
              top: BorderSide(
                color: AppColors.divider,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.surface,
                radius: 16,
                child: Icon(
                  Icons.person,
                  size: 20,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'コメントする...',
                    border: OutlineInputBorder(),
                    hintStyle: AppTextStyles.body2,
                  ),
                  style: AppTextStyles.body2,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                icon: const Icon(Icons.send),
                color: AppColors.primary,
                onPressed: () => _addComment(_commentController.text),
              ),
            ],
          ),
        ),
      ],
    );
  }
}*/
