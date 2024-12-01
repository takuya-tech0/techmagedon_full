// lib/shared/widgets/contents_list_modal.dart
import 'package:flutter/material.dart';

class FullScreenContentList extends StatefulWidget {
  final List<bool> isCheckedList;
  final List<bool> isBookmarkedList;
  final Function(List<bool>, List<bool>) onStateChanged;

  const FullScreenContentList({
    super.key,
    required this.isCheckedList,
    required this.isBookmarkedList,
    required this.onStateChanged,
  });

  @override
  _FullScreenContentListState createState() => _FullScreenContentListState();
}

class _FullScreenContentListState extends State<FullScreenContentList> {
  late List<bool> _isCheckedList;
  late List<bool> _isBookmarkedList;

  @override
  void initState() {
    super.initState();
    _isCheckedList = List.from(widget.isCheckedList); // 状態をコピー
    _isBookmarkedList = List.from(widget.isBookmarkedList); // 状態をコピー
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        "title": "1. 変位、速度、加速度、等加速度",
        "subtitle": "20:44",
      },
      {
        "title": "2. 自由落下、鉛直投射",
        "subtitle": "14:47",
      },
      {
        "title": "確認テスト",
        "subtitle": "全1問",
      }
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('講義一覧'),
        backgroundColor: const Color(0xFFFFFFFF),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            widget.onStateChanged(_isCheckedList, _isBookmarkedList); // 状態を更新
            Navigator.pop(context); // モーダルを閉じる
          },
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: SizedBox(
              width: 32, // チェックボックスの幅
              height: 32, // チェックボックスの高さ
              child: Transform.scale(
                scale: 1.5, // チェックボックスをスケールアップ
                child: Checkbox(
                  shape: const CircleBorder(), // 丸いチェックボックス
                  value: _isCheckedList[index],
                  onChanged: (bool? value) {
                    setState(() {
                      _isCheckedList[index] = value ?? false;
                    });
                  },
                  checkColor: Colors.white,
                  activeColor: const Color(0xFF635690),
                ),
              ),
            ),
            title: Text(
              items[index]["title"]!,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              items[index]["subtitle"]!,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: SizedBox(
              width: 32, // ブックマークボタン全体の幅
              height: 32, // ブックマークボタン全体の高さ
              child: IconButton(
                padding: EdgeInsets.zero, // アイコンの余白をゼロに設定
                icon: Icon(
                  _isBookmarkedList[index] ? Icons.bookmark : Icons.bookmark_border,
                  color: const Color(0xFFBA1A1A), // ブックマークアイコンの色
                  size: 32, // アイコン自体のサイズを32に設定
                ),
                onPressed: () {
                  setState(() {
                    _isBookmarkedList[index] = !_isBookmarkedList[index];
                  });
                },
              ),
            ),
          );
        },
        separatorBuilder: (context, index) => const Divider(
          color: Color(0xFFD9D9D9),
          thickness: 1,
          height: 1,
        ),
      ),
    );
  }
}