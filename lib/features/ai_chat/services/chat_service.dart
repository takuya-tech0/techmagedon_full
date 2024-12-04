// lib/features/ai_chat/services/chat_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../models/chat_history.dart';

class ChatService {
  final String apiKey;
  static const String _baseUrl = 'http://localhost:8000'; // バックエンドのURL

  int? _currentConversationId;

  // パブリックなゲッターとセッターを追加
  int? get currentConversationId => _currentConversationId;

  set currentConversationId(int? value) {
    _currentConversationId = value;
  }

  // 未使用の初期選択肢を保持するためのSet
  final Set<String> _unusedInitialRecommendations = {};

  ChatService({required this.apiKey}) {
    // 初期化時に未使用の選択肢をセットする
    _unusedInitialRecommendations.addAll(initialRecommendations);
  }

  // 初回の選択肢
  final List<String> initialRecommendations = [
    "加速度の意味について",
    "加速度の数式について",
    "等加速度直線運動の意味について",
    "等加速度直線運動の数式について",
  ];

  // 2回目以降の固定選択肢
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

  // 選択された選択肢を記録するメソッド
  void markRecommendationAsUsed(String recommendation) {
    _unusedInitialRecommendations.remove(recommendation);
  }

  // 現在の状況に応じた選択肢を取得するメソッド
  List<String> getCurrentRecommendations(bool isFirstMessage, String? selectedRecommendation) {
    if (isFirstMessage) {
      return initialRecommendations;
    } else {
      // 2回目以降は固定の選択肢と未使用の初期選択肢を組み合わせる
      List<String> currentRecommendations = List.from(followUpRecommendations);

      // 未使用の初期選択肢を追加（選択された選択肢は除外）
      if (selectedRecommendation != null) {
        markRecommendationAsUsed(selectedRecommendation);
      }

      // 未使用の初期選択肢を追加（最大2つまで）
      final unusedRecommendations = _unusedInitialRecommendations.take(2).toList();
      currentRecommendations.insertAll(0, unusedRecommendations);

      return currentRecommendations;
    }
  }

  // 新しい会話を作成するメソッド
  Future<int> createConversation(int userId, int unitId) async {
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
      return _currentConversationId!;
    } else {
      throw Exception('Failed to create conversation');
    }
  }

  // メッセージを追加するメソッド
  Future<void> addMessage(int conversationId, String content, String role) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/messages'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'conversation_id': conversationId,
        'content': content,
        'role': role,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add message');
    }
  }

  // タイトルを生成するメソッド
  Future<String> generateTitle(int conversationId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/conversations/$conversationId/generate_title'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['title'];
    } else {
      throw Exception('Failed to generate title');
    }
  }

  // メッセージを送信するメソッド
  Future<Map<String, dynamic>> sendMessage(String message, bool isFirstMessage) async {
    try {
      // 会話の作成または既存の会話IDを使用
      if (_currentConversationId == null) {
        await createConversation(1, 1); // ユーザーIDとユニットIDは適宜設定
      }

      // ユーザーメッセージをバックエンドに保存
      await addMessage(_currentConversationId!, message, 'user');

      // OpenAI APIへのリクエスト
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

        // アシスタントの応答をバックエンドに保存
        await addMessage(_currentConversationId!, content, 'assistant');

        // タイトルの生成（初回メッセージの場合）
        if (isFirstMessage) {
          await generateTitle(_currentConversationId!);
        }

        // メッセージに応じた選択肢を取得
        final recommendations = getCurrentRecommendations(isFirstMessage, message);

        return {
          'content': content,
          'recommendations': recommendations,
        };
      } else {
        throw Exception('応答の取得に失敗しました: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('メッセージの送信に失敗しました: $e');
    }
  }

  // チャット履歴を取得するメソッド
  Future<List<ChatHistory>> getChatHistory() async {
    try {
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
        return data.map((json) => ChatHistory.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load chat history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching chat history: $e');
    }
  }

  // 会話の詳細を取得するメソッド
  Future<ChatHistoryDetail> getConversationDetail(int conversationId) async {
    try {
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
        return ChatHistoryDetail.fromJson(data);
      } else {
        throw Exception('Failed to load conversation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching conversation: $e');
    }
  }
}