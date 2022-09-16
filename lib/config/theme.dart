import 'package:flutter/material.dart';

class AppThemes {
  static const miscColors = _MiscColors();
  static const fonts = _Fonts();
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFFF8ECE1),
    colorScheme: const ColorScheme.dark(
      //background: Color(0xff001219),
      primary: Color(0xFFF8ECE1),
      onPrimary: Color(0xFF1F2546),
    ),
    fontFamily: "Gilroy",
  );

}

class _Fonts{
  final String gilroy = "Gilroy";
  final String gilroyBold = "GilroyBold";
  final String procrastinating = "ProcrastinatingPixie";

  const _Fonts();
}

class _MiscColors{
  final Color welcomeBackground = const Color.fromRGBO(216, 153, 247, 1);

  const _MiscColors();
}