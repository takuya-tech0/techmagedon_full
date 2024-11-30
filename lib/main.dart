// lib/main.dart
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


class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }


  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // タブの数を3に変更
      child: Scaffold(
        appBar: const CustomAppBar(),
        body: Column(
          children: const [
            VideoPlayerWidget(),
            CustomTabBar(), // CustomTabBarも3タブに修正する必要があります
            Expanded(
              child: TabBarView(
                children: [
                  TextScreen(),
                  ChatScreen(),
                  Center(child: Text("メモの内容")),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: CustomBottomNavigation(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
