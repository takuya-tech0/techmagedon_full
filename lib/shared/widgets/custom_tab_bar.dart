// lib/shared/widgets/custom_tab_bar.dart
import 'package:flutter/material.dart';
import '../../core/themes/app_theme.dart';

class CustomTabBar extends StatelessWidget {
  final TabController controller;

  const CustomTabBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8), // タブ下に8ピクセルの隙間
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0), // 内側の余白を調整
      decoration: BoxDecoration(
        color: const Color(0x80D9D9D9), // 背景色D9D9D9（透過50%）
        borderRadius: BorderRadius.circular(30), // 丸い背景
      ),
      child: TabBar(
        controller: controller, // TabControllerを渡す
        indicator: BoxDecoration(
          color: const Color(0xFFEADDFF), // 選択されたタブの背景色
          borderRadius: BorderRadius.circular(30), // タブの丸い背景
        ),
        indicatorSize: TabBarIndicatorSize.tab, // インジケーターのサイズをタブ全体に適用
        indicatorColor: Colors.transparent, // デフォルトのインジケーター色を透明に設定（念のため）
        overlayColor: MaterialStateProperty.all(Colors.transparent), // タップ時のハイライトも無効化
        labelColor: const Color(0xFF49454F), // 選択されたタブの文字とアイコンの色
        unselectedLabelColor: const Color(0xFF49454F), // 未選択タブの文字とアイコンの色
        dividerColor: Colors.transparent, // Dividerを完全非表示
        tabs: [
          Tab(
            child: SizedBox(
              height: 20, // ボタンの高さを最小限に設定
              child: Row(
                mainAxisSize: MainAxisSize.min, // コンテンツを最小限に抑える
                children: [
                  Icon(Icons.menu_book_outlined, size: 20, color: Color(0xFF49454F)), // アイコンサイズと色
                  const SizedBox(width: 2), // アイコンとテキストの間のスペースを縮小
                  const Text(
                    "テキスト",
                    style: TextStyle(fontSize: 10, color: Color(0xFF49454F)), // テキストのフォントサイズ10
                  ),
                ],
              ),
            ),
          ),
          Tab(
            child: SizedBox(
              height: 20, // ボタンの高さを最小限に設定
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.smart_toy_outlined, size: 20, color: Color(0xFF49454F)), // アイコンサイズと色
                  const SizedBox(width: 2),
                  const Text(
                    "AI相談",
                    style: TextStyle(fontSize: 10, color: Color(0xFF49454F)), // テキストのフォントサイズ10
                  ),
                ],
              ),
            ),
          ),
          Tab(
            child: SizedBox(
              height: 20, // ボタンの高さを最小限に設定
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.diversity_3_outlined, size: 20, color: Color(0xFF49454F)), // アイコンサイズと色
                  const SizedBox(width: 2),
                  const Text(
                    "みんなの叡智",
                    style: TextStyle(fontSize: 10, color: Color(0xFF49454F)), // テキストのフォントサイズ10
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(24); // 全体の高さを調整
}