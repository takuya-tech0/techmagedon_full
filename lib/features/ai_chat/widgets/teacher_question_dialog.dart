// lib/features/ai_chat/widgets/teacher_question_dialog.dart
import 'package:flutter/material.dart';

class TeacherQuestionDialog extends StatefulWidget {
  final Function(String, bool) onSubmit;


  const TeacherQuestionDialog({
    super.key,
    required this.onSubmit,
  });


  @override
  _TeacherQuestionDialogState createState() => _TeacherQuestionDialogState();
}


class _TeacherQuestionDialogState extends State<TeacherQuestionDialog> {
  final TextEditingController _questionController = TextEditingController();
  bool _isChat = true;


  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "先生に質問する",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Radio<bool>(
                  value: true,
                  groupValue: _isChat,
                  onChanged: (value) {
                    setState(() {
                      _isChat = value!;
                    });
                  },
                  activeColor: Colors.purple,
                ),
                const Text("チャットで回答"),
                const SizedBox(width: 16),
                Radio<bool>(
                  value: false,
                  groupValue: _isChat,
                  onChanged: (value) {
                    setState(() {
                      _isChat = value!;
                    });
                  },
                  activeColor: Colors.purple,
                ),
                const Text("対面で回答"),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _questionController,
              decoration: InputDecoration(
                hintText: '先生に質問したい内容を記入してね！',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.purple),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.purple.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.purple),
                ),
                filled: true,
                fillColor: const Color(0xFFFFE4E8),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'キャンセル',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_questionController.text.isNotEmpty) {
                      Navigator.of(context).pop();
                      _showConfirmationDialog(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '質問する',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "先生に質問する",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "以下の内容で先生に質問しています。",
                  style: TextStyle(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "回答形式: ${_isChat ? 'チャットで回答' : '対面で回答'}",
                  style: TextStyle(
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "質問: ${_questionController.text}",
                  style: TextStyle(
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "回答をお待ち下さい。続けてAIに相談したい場合は右上の新規ページボタンをクリックしてね！",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.onSubmit(_questionController.text, _isChat);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    side: BorderSide(color: Colors.purple.shade200),
                  ),
                  child: const Text(
                    "理解できました！ありがとう！",
                    style: TextStyle(color: Colors.purple),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
