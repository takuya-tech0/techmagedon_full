/*
# lib/features/bulletin_board/models/post.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String content;
  final String author;
  final DateTime timestamp;
  final int likes;
  final int dislikes;

  const Post({
    required this.id,
    required this.content,
    required this.author,
    required this.timestamp,
    required this.likes,
    required this.dislikes,
  });

  factory Post.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      id: doc.id,
      content: data['content'] ?? '',
      author: data['author'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      likes: data['likes'] ?? 0,
      dislikes: data['dislikes'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'author': author,
      'timestamp': Timestamp.fromDate(timestamp),
      'likes': likes,
      'dislikes': dislikes,
    };
  }

  Post copyWith({
    String? id,
    String? content,
    String? author,
    DateTime? timestamp,
    int? likes,
    int? dislikes,
  }) {
    return Post(
      id: id ?? this.id,
      content: content ?? this.content,
      author: author ?? this.author,
      timestamp: timestamp ?? this.timestamp,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
    );
  }
}*/
