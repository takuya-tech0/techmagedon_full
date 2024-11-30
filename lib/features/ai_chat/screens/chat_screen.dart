// lib/features/ai_chat/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/teacher_question_dialog.dart';


class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});


  @override
  _ChatScreenState createState() => _ChatScreenState();
}


class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  late final ChatService _chatService;
  bool _isLoading = false;
  bool _isFirstMessage = true;
  final ScrollController _scrollController = ScrollController();


  @override
  void initState() {
    super.initState();
    _chatService = ChatService(apiKey: dotenv.env['OPENAI_API_KEY'] ?? '');
    _messages.add(
      ChatMessage(
        content: '物理の学習をサポートします。\n分からないことがあれば、気軽に質問してください！',
        isUser: false,
        isFirstMessage: true,
        recommendations: _chatService.initialRecommendations,
      ),
    );
  }


  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }


  void _handleTeacherQuestion() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return TeacherQuestionDialog(
          onSubmit: (question, isChat) {
            setState(() {
              _messages.add(ChatMessage(
                content: "質問を送信しました。先生からの回答をお待ちください。",
                isUser: false,
                recommendations: const [],
              ));
            });
          },
        );
      },
    );
  }


  void _handleRecommendationTap(String recommendation) async {
    if (recommendation == "先生に質問する") {
      _handleTeacherQuestion();
      return;
    }


    if (recommendation == "理解できました！ありがとう！") {
      setState(() {
        _messages.add(ChatMessage(
          content: _chatService.getUnderstandingConfirmationMessage(),
          isUser: false,
          recommendations: _chatService.understandingConfirmationOptions,
        ));
      });
      return;
    }


    if (recommendation == "「みんなの教習」に追加する！") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('「みんなの教習」に追加しました！'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }


    if (recommendation == "今回はやめとく") {
      return;
    }


    _messageController.text = recommendation;
    _sendMessage();
  }


  void _sendMessage() async {
    if (_messageController.text.isEmpty) return;


    final userMessage = _messageController.text;
    final isFirstMessage = _isFirstMessage;


    setState(() {
      _messages.add(ChatMessage(
        content: userMessage,
        isUser: true,
      ));
      _isLoading = true;
      _messageController.clear();
    });


    await Future.delayed(const Duration(milliseconds: 100));
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );


    try {
      final response = await _chatService.sendMessage(userMessage, isFirstMessage);
      setState(() {
        _messages.add(ChatMessage(
          content: response['content'],
          isUser: false,
          recommendations: List<String>.from(response['recommendations']),
          isFirstMessage: isFirstMessage,
        ));
        _isFirstMessage = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      await Future.delayed(const Duration(milliseconds: 100));
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                return ChatBubble(
                  message: message,
                  onRecommendationTap: _handleRecommendationTap,
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE4E8),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'メッセージ',
                        hintStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      style: const TextStyle(fontSize: 14),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_upward),
                    onPressed: _sendMessage,
                    color: Colors.purple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
