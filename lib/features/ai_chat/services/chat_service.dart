// lib/features/ai_chat/services/chat_service.dart

import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../models/chat_message.dart';
import '../models/chat_history.dart';

class ChatService {
  final String apiKey;
  static const String _baseUrl = 'http://localhost:8000';

  int? _currentConversationId;

  int? get currentConversationId => _currentConversationId;

  set currentConversationId(int? value) {
    _currentConversationId = value;
  }

  final Set<String> _unusedInitialRecommendations = {};

  ChatService({required this.apiKey}) {
    if (apiKey.isEmpty) {
      throw ArgumentError('API key cannot be empty');
    }
    _unusedInitialRecommendations.addAll(initialRecommendations);
  }

  final List<String> initialRecommendations = [
    "加速度の意味について",
    "加速度の数式について",
    "等加速度直線運動の意味について",
    "等加速度直線運動の数式について",
  ];

  final List<String> followUpRecommendations = [
    "もっと詳しく教えて",
    "先生に質問する",
    "理解できました！ありがとう！",
    "「みんなの教習」に追加する！",
    "今回はやめとく",
  ];

  final List<String> understandingConfirmationOptions = [
    "「みんなの教習」に追加する！",
    "今回はやめとく",
  ];

  String getUnderstandingConfirmationMessage() {
    return "お役に立てて光栄です！\n今回の学びを「みんなの教習」に追加しますか？";
  }

  void markRecommendationAsUsed(String recommendation) {
    _unusedInitialRecommendations.remove(recommendation);
  }

  List<String> getCurrentRecommendations(bool isFirstMessage, String? selectedRecommendation) {
    if (isFirstMessage) {
      return initialRecommendations;
    } else {
      List<String> currentRecommendations = List.from(followUpRecommendations);

      if (selectedRecommendation != null) {
        markRecommendationAsUsed(selectedRecommendation);
      }

      final unusedRecommendations = _unusedInitialRecommendations.take(2).toList();
      currentRecommendations.insertAll(0, unusedRecommendations);

      return currentRecommendations;
    }
  }

  Future<int> createConversation(int userId, int unitId) async {
    try {
      developer.log('Creating new conversation for user $userId in unit $unitId');

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/conversations'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'user_id': userId,
          'unit_id': unitId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentConversationId = data['conversation_id'];
        developer.log('Created conversation with ID: $_currentConversationId');
        return _currentConversationId!;
      } else {
        throw Exception(
            'Failed to create conversation. Status code: ${response.statusCode}, '
                'Response: ${response.body}'
        );
      }
    } catch (e) {
      developer.log('Error creating conversation', error: e);
      rethrow;
    }
  }

  Future<void> addMessage(
      int conversationId,
      String content,
      String role, {
        bool isFirstMessage = false
      }) async {
    try {
      developer.log('Adding message to conversation $conversationId');

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/messages'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'conversation_id': conversationId,
          'content': content,
          'role': role,
          'is_first_message': isFirstMessage
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to add message. Status code: ${response.statusCode}, '
                'Response: ${response.body}'
        );
      }
      developer.log('Successfully added message to conversation $conversationId');
    } catch (e) {
      developer.log('Error adding message', error: e);
      rethrow;
    }
  }

  Future<String> generateTitle(int conversationId) async {
    try {
      developer.log('Generating title for conversation $conversationId');

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/conversations/$conversationId/title'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final title = data['title'] as String;
        developer.log('Generated title: $title');
        return title;
      } else {
        throw Exception(
            'Failed to generate title. Status code: ${response.statusCode}, '
                'Response: ${response.body}'
        );
      }
    } catch (e) {
      developer.log('Error generating title', error: e);
      rethrow;
    }
  }

  /// 旧フロー(一括処理用)メソッド: sendMessage
  /// 新フローでは使用しないが、既存機能維持のため残す
  Future<Map<String, dynamic>> sendMessage(String message, bool isFirstMessage) async {
    try {
      developer.log('Sending message. isFirstMessage: $isFirstMessage');

      if (_currentConversationId == null) {
        await createConversation(1, 1);
      }

      await addMessage(
          _currentConversationId!,
          message,
          'user',
          isFirstMessage: isFirstMessage
      );

      final List<Map<String, String>> messages = [
        {
          'role': 'system',
          'content': '高校1年生の物理を教える教師アシスタントです。わかりやすく、丁寧に説明してください。'
        },
        {
          'role': 'user',
          'content': message
        }
      ];

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'];

        await addMessage(
            _currentConversationId!,
            content,
            'assistant',
            isFirstMessage: isFirstMessage
        );

        if (isFirstMessage) {
          await generateTitle(_currentConversationId!);
        }

        final recommendations = getCurrentRecommendations(isFirstMessage, message);

        return {
          'content': content,
          'recommendations': recommendations,
        };
      } else {
        throw Exception(
            'Failed to get AI response. Status code: ${response.statusCode}, '
                'Response: ${response.body}'
        );
      }
    } catch (e) {
      developer.log('Error sending message', error: e);
      rethrow;
    }
  }

  Future<List<ChatHistory>> getChatHistory() async {
    try {
      developer.log('Fetching chat history');

      final response = await http.get(
        Uri.parse('$_baseUrl/chat/history'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        final List<dynamic> data = json.decode(decodedBody);
        final history = data.map((json) => ChatHistory.fromJson(json)).toList();
        developer.log('Successfully fetched ${history.length} chat histories');
        return history;
      } else {
        throw Exception(
            'Failed to load chat history. Status code: ${response.statusCode}, '
                'Response: ${response.body}'
        );
      }
    } catch (e) {
      developer.log('Error fetching chat history', error: e);
      rethrow;
    }
  }

  Future<ChatHistoryDetail> getConversationDetail(int conversationId) async {
    try {
      developer.log('Fetching conversation detail for ID: $conversationId');

      final response = await http.get(
        Uri.parse('$_baseUrl/chat/$conversationId'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);
        final detail = ChatHistoryDetail.fromJson(data);
        developer.log('Successfully fetched conversation detail');
        return detail;
      } else {
        throw Exception(
            'Failed to load conversation. Status code: ${response.statusCode}, '
                'Response: ${response.body}'
        );
      }
    } catch (e) {
      developer.log('Error fetching conversation detail', error: e);
      rethrow;
    }
  }

  // --- 新フロー用メソッド ---
  /// 新フロー: ユーザーメッセージのみ送信して会話IDを取得
  Future<Map<String, dynamic>> sendUserMessage({int? conversationId, required String content}) async {
    final body = {
      'conversation_id': conversationId ?? 0,
      'content': content,
      'role': 'user',
      'is_first_message': false,
    };
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/messages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _currentConversationId = data['conversation_id'];
      return data;
    } else {
      throw Exception('Failed to store user message');
    }
  }

  /// 新フロー: アシスタントメッセージ取得
  Future<String> fetchAssistantResponse(int conversationId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/conversations/$conversationId/assistant_response'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['assistant_message'];
    } else {
      throw Exception('Failed to fetch assistant response');
    }
  }

  /// 新フロー: タイトル生成取得
  Future<String> fetchGeneratedTitle(int conversationId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/conversations/$conversationId/title'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['title'];
    } else {
      throw Exception('Failed to fetch title');
    }
  }
}
