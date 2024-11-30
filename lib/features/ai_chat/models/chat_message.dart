// lib/features/ai_chat/models/chat_message.dart
import 'package:flutter/foundation.dart';

@immutable
class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<String> recommendations;
  final bool isFirstMessage;


  ChatMessage({
    required this.content,
    required this.isUser,
    DateTime? timestamp,
    this.recommendations = const [],
    this.isFirstMessage = false,
  }) : timestamp = timestamp ?? DateTime.now();


  ChatMessage copyWith({
    String? content,
    bool? isUser,
    DateTime? timestamp,
    List<String>? recommendations,
    bool? isFirstMessage,
  }) {
    return ChatMessage(
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      recommendations: recommendations ?? this.recommendations,
      isFirstMessage: isFirstMessage ?? this.isFirstMessage,
    );
  }
}
