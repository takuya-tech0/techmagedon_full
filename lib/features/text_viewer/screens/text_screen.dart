// lib/features/text_viewer/screens/text_screen.dart
import 'package:flutter/material.dart';
import '../../../core/themes/app_theme.dart';


class TextScreen extends StatelessWidget {
  const TextScreen({super.key});


  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: AppSpacing.paddingMD,
        child: const Image(
          image: AssetImage('assets/images/text_sample2.png'),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
