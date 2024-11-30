// lib/core/themes/theme_extensions.dart
import 'package:flutter/material.dart';

extension ThemeExtension on BuildContext {
ThemeData get theme => Theme.of(this);
ColorScheme get colors => theme.colorScheme;
TextTheme get textTheme => theme.textTheme;
}
