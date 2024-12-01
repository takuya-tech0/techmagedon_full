import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/constants/app_constants.dart';
import 'core/themes/app_theme.dart';
import 'features/text_viewer/screens/text_screen.dart';
import 'features/ai_chat/screens/chat_screen.dart';
import 'shared/widgets/custom_app_bar.dart';
import 'shared/widgets/custom_bottom_navigation.dart';
import 'shared/widgets/custom_tab_bar.dart';
import 'shared/widgets/video_player_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appTitle,
      theme: AppTheme.lightTheme,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController!.addListener(() {
      setState(() {}); // タブが変更されたときに再描画
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 初期化が完了していない場合はローディング状態を表示
    if (_tabController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          CustomTabBar(controller: _tabController!), // TabControllerを渡す
          if (_tabController!.index == 0) // テキストタブ（インデックス0）のときのみ表示
            const VideoPlayerWidget(),
          Expanded(
            child: TabBarView(
              controller: _tabController, // TabControllerを設定
              children: [
                TextScreen(),
                ChatScreen(),
                const Center(child: Text("みんなの叡智")),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: _tabController!.index,
        onTap: (index) {
          setState(() {
            _tabController!.index = index;
          });
        },
      ),
    );
  }
}