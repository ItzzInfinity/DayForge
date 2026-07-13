import 'package:flutter/material.dart';

const _seedColor = Colors.teal;

ThemeData buildTheme(Brightness brightness) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    ),
    visualDensity: VisualDensity.adaptivePlatformDensity,
  );
}
