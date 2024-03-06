import 'package:flutter/material.dart';

class AppThemes {
  static const miscColors = _MiscColors();
  static const fonts = _Fonts();
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFFF8ECE1),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFF8ECE1),
      onPrimary: Color(0xFF1F2546),
    ),
    fontFamily: "Gilroy",
    useMaterial3: false
  );

  static Color getContrastColor(Color color){
    if (ThemeData.estimateBrightnessForColor(color) == Brightness.dark) {
      return Colors.white;
    }
    return Colors.black;
  }
}

class _Fonts{
  final String gilroy = "Gilroy";
  final String gilroyBold = "GilroyBold";
  final String procrastinating = "ProcrastinatingPixie";

  const _Fonts();
}

class _MiscColors{
  final List<Color> randomColors = const [
    Color(0xff7b7ff2),
    Color(0xff8aa7db),
    Color(0xffe0699e),
    Color(0xff8e6ec1),
    Color(0xffd88070),
    Color(0xffea8fa1),
    Color(0xff4ed376),
    Color(0xff0aa859),
  ];

  const _MiscColors();
}