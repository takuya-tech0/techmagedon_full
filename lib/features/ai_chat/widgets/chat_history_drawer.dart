// lib/features/ai_chat/widgets/chat_history_drawer.dart
import 'package:flutter/material.dart';
import '../models/chat_history.dart';
import '../services/chat_service.dart';

class ChatHistoryDrawer extends StatefulWidget {
  final Function(ChatHistory) onSelectConversation;
  final ChatHistory? currentConversation;

  const ChatHistoryDrawer({
    super.key,
    required this.onSelectConversation,
    this.currentConversation,
  });

  @override
  State<ChatHistoryDrawer> createState() => _ChatHistoryDrawerState();
}

class _ChatHistoryDrawerState extends State<ChatHistoryDrawer> {
  final ChatService _chatService = ChatService(apiKey: '');
  List<ChatHistory> _conversations = [];
  bool _isLoading = true;
  String _activeFilter = 'すべての履歴';

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    try {
      final conversations = await _chatService.getChatHistory();
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('履歴の読み込みに失敗しました: $e')),
        );
      }
    }
  }

  List<ChatHistory> get _filteredConversations {
    if (_activeFilter == 'ブックマーク') {
      return _conversations.where((conv) => conv.bookmarkCount > 0).toList();
    }
    return _conversations;
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu),
      onPressed: () {
        showDrawerContent(context);
      },
      tooltip: '履歴一覧',
    );
  }

  void showDrawerContent(BuildContext context) {
    Scaffold.of(context).openDrawer();
  }
}

class ChatHistoryDrawerContent extends StatelessWidget {
  final List<ChatHistory> conversations;
  final Function(ChatHistory) onSelectConversation;
  final ChatHistory? currentConversation;
  final Function(String) onFilterChange;
  final String activeFilter;
  final bool isLoading;

  const ChatHistoryDrawerContent({
    super.key,
    required this.conversations,
    required this.onSelectConversation,
    required this.onFilterChange,
    required this.activeFilter,
    required this.isLoading,
    this.currentConversation,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) return "今日";
    if (difference.inDays == 1) return "昨日";
    if (difference.inDays < 7) return "${difference.inDays}日前";
    if (difference.inDays < 30) return "${(difference.inDays / 7).floor()}週間前";
    return "${(difference.inDays / 30).floor()}ヶ月前";
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '履歴一覧',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final filter in ['すべての履歴', 'ブックマーク'])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(filter),
                            selected: activeFilter == filter,
                            onSelected: (_) => onFilterChange(filter),
                            backgroundColor: Colors.grey[200],
                            selectedColor: Colors.purple[100],
                            labelStyle: TextStyle(
                              color: activeFilter == filter
                                  ? Colors.purple[900]
                                  : Colors.grey[800],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: conversations.length,
                itemBuilder: (context, index) {
                  final conversation = conversations[index];
                  final isSelected = currentConversation?.conversationId ==
                      conversation.conversationId;

                  return ListTile(
                    selected: isSelected,
                    selectedTileColor: Colors.purple[50],
                    leading: CircleAvatar(
                      backgroundColor: isSelected ? Colors.purple : Colors.grey[200],
                      child: Icon(
                        Icons.message,
                        color: isSelected ? Colors.white : Colors.grey[600],
                        size: 20,
                      ),
                    ),
                    title: Text(
                      conversation.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Text(
                          _formatDate(conversation.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (conversation.understandingFlag) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: Colors.green[600],
                          ),
                        ],
                      ],
                    ),
                    trailing: conversation.bookmarkCount > 0
                        ? const Icon(
                      Icons.bookmark,
                      color: Colors.purple,
                      size: 20,
                    )
                        : null,
                    onTap: () {
                      onSelectConversation(conversation);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}