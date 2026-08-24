import 'package:flutter/material.dart';

class NoahColors {
  NoahColors._();

  // Light
  static const bg0 = Color(0xFFF7F4EE);
  static const bg1 = Color(0xFFFFFFFF);
  static const bg2 = Color(0xFFF0ECE4);
  static const bg3 = Color(0xFFE8E3D8);
  static const bg4 = Color(0xFFDDD6C8);
  static const border = Color(0x0F000000);
  static const borderMd = Color(0x1A000000);
  static const borderLg = Color(0x29000000);
  static const t0 = Color(0xFF1C1C1C);
  static const t1 = Color(0xFF5C5C5C);
  static const t2 = Color(0xFF9C9C9C);
  static const t3 = Color(0xFFC8C8C8);
  static const accent = Color(0xFFB08D57);
  static const accentBg = Color(0x1AB08D57);
  static const accentBorder = Color(0x33B08D57);
  static const accentHover = Color(0x2EB08D57);
  static const green = Color(0xFF2E7D5E);
  static const greenBg = Color(0x142E7D5E);
  static const greenBorder = Color(0x2E2E7D5E);
  static const red = Color(0xFFB8453A);
  static const redBg = Color(0x14B8453A);
  static const redBorder = Color(0x2EB8453A);
  static const amber = Color(0xFFA67C2E);
  static const amberBg = Color(0x14A67C2E);
  static const amberBorder = Color(0x2EA67C2E);

  // Dark
  static const dkBg0 = Color(0xFF121212);
  static const dkBg1 = Color(0xFF1E1E1E);
  static const dkBg2 = Color(0xFF282828);
  static const dkBg3 = Color(0xFF323232);
  static const dkBg4 = Color(0xFF3C3C3C);
  static const dkBorder = Color(0x0DFFFFFF);
  static const dkBorderMd = Color(0x17FFFFFF);
  static const dkBorderLg = Color(0x26FFFFFF);
  static const dkT0 = Color(0xFFF0F0F0);
  static const dkT1 = Color(0xFFA0A0A0);
  static const dkT2 = Color(0xFF6C6C6C);
  static const dkT3 = Color(0xFF4A4A4A);
  static const dkAccent = Color(0xFFC2A878);
  static const dkAccentBg = Color(0x1AC2A878);
  static const dkAccentBorder = Color(0x2EC2A878);
  static const dkAccentHover = Color(0x29C2A878);
  static const dkGreen = Color(0xFF4CAF8E);
  static const dkGreenBg = Color(0x144CAF8E);
  static const dkGreenBorder = Color(0x2E4CAF8E);
  static const dkRed = Color(0xFFE07060);
  static const dkRedBg = Color(0x14E07060);
  static const dkRedBorder = Color(0x2EE07060);
  static const dkAmber = Color(0xFFD4A84B);
  static const dkAmberBg = Color(0x14D4A84B);
  static const dkAmberBorder = Color(0x2ED4A84B);
}

class NoahTheme {
  static const radiusSm = 16.0;
  static const radius = 24.0;
  static const radiusLg = 30.0;
  static const radiusXl = 36.0;

  static List<BoxShadow> shadow(bool isDark) => [
        BoxShadow(
          color: Colors.black.withOpacity( isDark ? 0.3 : 0.04),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: Colors.black.withOpacity( isDark ? 0.2 : 0.03),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> shadowMd(bool isDark) => [
        BoxShadow(
          color: Colors.black.withOpacity( isDark ? 0.4 : 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity( isDark ? 0.2 : 0.03),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static C get s => C(); // shorthand for color access

  static ThemeData light({String fontFamily = 'Inter', bool useBold = false}) => _build(false, fontFamily: fontFamily, useBold: useBold);
  static ThemeData dark({String fontFamily = 'Inter', bool useBold = false}) => _build(true, fontFamily: fontFamily, useBold: useBold);

  static ThemeData _build(bool isDark, {String fontFamily = 'Inter', bool useBold = false}) {
    final w = useBold ? FontWeight.w700 : FontWeight.w400;
    return ThemeData(
      useMaterial3: false,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: isDark ? NoahColors.dkBg0 : NoahColors.bg0,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: isDark ? NoahColors.dkAccent : NoahColors.accent,
        onPrimary: Colors.white,
        secondary: isDark ? NoahColors.dkAccent : NoahColors.accent,
        onSecondary: Colors.white,
        error: isDark ? NoahColors.dkRed : NoahColors.red,
        onError: Colors.white,
        surface: isDark ? NoahColors.dkBg1 : NoahColors.bg1,
        onSurface: isDark ? NoahColors.dkT0 : NoahColors.t0,
      ),
      fontFamily: fontFamily,
      textTheme: TextTheme(
        bodySmall: TextStyle(fontFamily: fontFamily, fontWeight: w, color: isDark ? NoahColors.dkT2 : NoahColors.t2, fontSize: 12),
        bodyMedium: TextStyle(fontFamily: fontFamily, fontWeight: w, color: isDark ? NoahColors.dkT0 : NoahColors.t0, fontSize: 14),
        bodyLarge: TextStyle(fontFamily: fontFamily, fontWeight: w, color: isDark ? NoahColors.dkT0 : NoahColors.t0, fontSize: 16),
      ),
    );
  }
}

class C {
  Color get bg0 => _d ? NoahColors.dkBg0 : NoahColors.bg0;
  Color get bg1 => _d ? NoahColors.dkBg1 : NoahColors.bg1;
  Color get bg2 => _d ? NoahColors.dkBg2 : NoahColors.bg2;
  Color get bg3 => _d ? NoahColors.dkBg3 : NoahColors.bg3;
  Color get bg4 => _d ? NoahColors.dkBg4 : NoahColors.bg4;
  Color get border => _d ? NoahColors.dkBorder : NoahColors.border;
  Color get borderMd => _d ? NoahColors.dkBorderMd : NoahColors.borderMd;
  Color get borderLg => _d ? NoahColors.dkBorderLg : NoahColors.borderLg;
  Color get t0 => _d ? NoahColors.dkT0 : NoahColors.t0;
  Color get t1 => _d ? NoahColors.dkT1 : NoahColors.t1;
  Color get t2 => _d ? NoahColors.dkT2 : NoahColors.t2;
  Color get t3 => _d ? NoahColors.dkT3 : NoahColors.t3;
  Color get accent => _d ? NoahColors.dkAccent : NoahColors.accent;
  Color get accentBg => _d ? NoahColors.dkAccentBg : NoahColors.accentBg;
  Color get accentBorder => _d ? NoahColors.dkAccentBorder : NoahColors.accentBorder;
  Color get accentHover => _d ? NoahColors.dkAccentHover : NoahColors.accentHover;
  Color get green => _d ? NoahColors.dkGreen : NoahColors.green;
  Color get greenBg => _d ? NoahColors.dkGreenBg : NoahColors.greenBg;
  Color get greenBorder => _d ? NoahColors.dkGreenBorder : NoahColors.greenBorder;
  Color get red => _d ? NoahColors.dkRed : NoahColors.red;
  Color get redBg => _d ? NoahColors.dkRedBg : NoahColors.redBg;
  Color get redBorder => _d ? NoahColors.dkRedBorder : NoahColors.redBorder;
  Color get amber => _d ? NoahColors.dkAmber : NoahColors.amber;
  Color get amberBg => _d ? NoahColors.dkAmberBg : NoahColors.amberBg;
  Color get amberBorder => _d ? NoahColors.dkAmberBorder : NoahColors.amberBorder;

  static bool _d = false;
  static void setDark(bool v) => _d = v;
}
