// lib/features/ai_chat/models/chat_history.dart
import 'package:flutter/foundation.dart';
import 'chat_message.dart';

class ChatHistory {
  final int conversationId;
  final int userId;
  final int unitId;
  final String title;
  final String summary;
  final bool understandingFlag;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublic;
  final int viewCount;
  final int likeCount;
  final int bookmarkCount;
  final bool isPinned;
  final bool isToTeacher;
  final String? teacherResponseType;
  final String? teacherResponseStatus;

  ChatHistory({
    required this.conversationId,
    required this.userId,
    required this.unitId,
    required this.title,
    required this.summary,
    required this.understandingFlag,
    required this.createdAt,
    required this.updatedAt,
    required this.isPublic,
    required this.viewCount,
    required this.likeCount,
    required this.bookmarkCount,
    required this.isPinned,
    required this.isToTeacher,
    this.teacherResponseType,
    this.teacherResponseStatus,
  });

  factory ChatHistory.fromJson(Map<String, dynamic> json) {
    return ChatHistory(
      conversationId: json['conversation_id'],
      userId: json['user_id'],
      unitId: json['unit_id'],
      title: json['title'],
      summary: json['summary'],
      understandingFlag: json['understanding_flag'] == 1,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isPublic: json['is_public'] == 1,
      viewCount: json['view_count'],
      likeCount: json['like_count'],
      bookmarkCount: json['bookmark_count'],
      isPinned: json['is_pinned'] == 1,
      isToTeacher: json['is_to_teacher'] == 1,
      teacherResponseType: json['teacher_response_type'],
      teacherResponseStatus: json['teacher_response_status'],
    );
  }
}

class ChatHistoryDetail {
  final ChatHistory conversation;
  final List<ChatMessage> messages;

  ChatHistoryDetail({
    required this.conversation,
    required this.messages,
  });

  factory ChatHistoryDetail.fromJson(Map<String, dynamic> json) {
    return ChatHistoryDetail(
      conversation: ChatHistory.fromJson(json['conversation']),
      messages: (json['messages'] as List)
          .map((msg) => ChatMessage.fromJson(msg))
          .toList(),
    );
  }
}