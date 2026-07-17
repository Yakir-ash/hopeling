// Dawnlight - the shared design language (DESIGN.md), native edition.
// Tokens live HERE. Screens never invent raw values.

import 'package:flutter/material.dart';

import 'settings.dart';

// ---------- color tokens ----------
const ink = Color(0xFF16241C);
const fern = Color(0xFF2E6B4F);
const fernDeep = Color(0xFF1E4533);
const mint = Color(0xFFB2F1CC);
const gold = Color(0xFFE8B04B); // sacred: holds, pledges, growth. Nothing else.
const paper = Color(0xFFFAF8F2);
const deep = Color(0xFF0B3D4C);
const tx2 = Color(0xFF55645B);
const bark = Color(0xFF6B4E3A);
// dark groundwork (full dark pass arrives with the settings screen)
const nightsoil = Color(0xFF0E1512);
const nightCard = Color(0xFF16211A);

// ---------- spacing tokens (4pt grid) ----------
class Space {
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const gutter = 24.0;
}

// ---------- shape tokens ----------
class Corners {
  static const chip = 12.0;
  static const button = 16.0;
  static const card = 20.0;
  static const sheet = 24.0;
  static const pill = 99.0;
}

// ---------- elevation: exactly three levels ----------
List<BoxShadow> shadowRest(Color base) => [
      BoxShadow(
          color: base.withValues(alpha: 0.08),
          blurRadius: 16,
          offset: const Offset(0, 6)),
    ];
List<BoxShadow> shadowFloat(Color base) => [
      BoxShadow(
          color: base.withValues(alpha: 0.16),
          blurRadius: 28,
          offset: const Offset(0, 10)),
    ];
// Third level is none: flat.

// ---------- motion (RISE / SWAY / FALL / BLOOM) ----------
class Motion {
  static const rise = Duration(milliseconds: 300);
  static const sway = Duration(seconds: 3);
  static const fall = Duration(milliseconds: 1400); // ceremonies stay under 1.5s
  static const hold = Duration(milliseconds: 1100); // the Thumb Promise
  static const riseCurve = Curves.easeOutCubic;

  /// Reduced motion: system setting OR the user's own choice.
  static bool reduced(BuildContext context) =>
      MediaQuery.of(context).disableAnimations || Settings.instance.reduceMotion;

  /// Low power: still beauty, zero animation, full function.
  static bool still(BuildContext context) =>
      reduced(context) || Settings.instance.lowPower;
}

// ---------- type ----------
TextStyle serif(double size,
        {Color color = ink,
        FontStyle style = FontStyle.normal,
        FontWeight weight = FontWeight.w600,
        double height = 1.3}) =>
    TextStyle(
        fontFamily: 'serif',
        fontSize: size,
        fontStyle: style,
        fontWeight: weight,
        height: height,
        color: color);

TextStyle kicker([Color color = fern]) => TextStyle(
    fontSize: 11, letterSpacing: 2.5, fontWeight: FontWeight.w800, color: color);

TextStyle body([Color color = ink]) =>
    TextStyle(fontSize: 15, height: 1.6, color: color);

TextStyle caption([Color color = tx2]) =>
    TextStyle(fontSize: 12, height: 1.4, color: color);

// ---------- themes ----------
ThemeData dawnlight() => ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: paper,
      colorScheme: ColorScheme.fromSeed(seedColor: fern),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
      ),
      splashFactory: InkSparkle.splashFactory,
    );

/// Groundwork only: activated when the settings screen ships.
ThemeData nightlight() => ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: nightsoil,
      colorScheme: ColorScheme.fromSeed(
          seedColor: fern, brightness: Brightness.dark, surface: nightCard),
    );

/// The sky at the visitor's real hour - shared logic with website and PWA.
List<Color> skyColors(int hour) {
  if (hour >= 5 && hour < 9) return [const Color(0xFFFFF3DD), paper];
  if (hour >= 9 && hour < 17) return [const Color(0xFFE9F6EF), paper];
  if (hour >= 17 && hour < 20) return [const Color(0xFFFFE9D4), paper];
  return [const Color(0xFFE3E9F3), paper];
}
