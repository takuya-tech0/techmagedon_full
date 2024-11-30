/*
# lib/features/bulletin_board/widgets/post_list.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/themes/app_theme.dart';
import '../models/post.dart';

class PostList extends StatelessWidget {
  final CollectionReference posts = FirebaseFirestore.instance.collection('posts');

  PostList({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: posts.orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'エラーが発生しました: ${snapshot.error}',
              style: AppTextStyles.body1.copyWith(color: AppColors.error),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              '投稿がありません',
              style: AppTextStyles.body1.copyWith(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.builder(
          padding: AppSpacing.paddingMD,
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final post = Post.fromFirestore(snapshot.data!.docs[index]);
            return PostCard(post: post);
          },
        );
      },
    );
  }
}

class PostCard extends StatelessWidget {
  final Post post;

  const PostCard({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: AppSpacing.paddingMD,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.surface,
                  child: Icon(
                    Icons.person,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.author,
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('yyyy/MM/dd HH:mm').format(post.timestamp),
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              post.content,
              style: AppTextStyles.body1,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.thumb_up_outlined),
                  onPressed: () {
                    // いいね機能の実装
                  },
                ),
                Text(
                  post.likes.toString(),
                  style: AppTextStyles.body2,
                ),
                const SizedBox(width: AppSpacing.md),
                IconButton(
                  icon: const Icon(Icons.thumb_down_outlined),
                  onPressed: () {
                    // よくないね機能の実装
                  },
                ),
                Text(
                  post.dislikes.toString(),
                  style: AppTextStyles.body2,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}*/
