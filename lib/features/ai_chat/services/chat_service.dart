// lib/features/ai_chat/services/chat_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';


class ChatService {
  final String apiKey;
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';


  ChatService({required this.apiKey});


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


  Future<Map<String, dynamic>> sendMessage(String message, bool isFirstMessage) async {
    try {
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
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4-1106-preview',
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];


        final recommendations = isFirstMessage
            ? initialRecommendations
            : followUpRecommendations;


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
}
