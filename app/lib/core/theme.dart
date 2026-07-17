// Dawnlight - the shared design language (DESIGN.md), native edition.

import 'package:flutter/material.dart';

// ---------- palette ----------
const ink = Color(0xFF16241C);
const fern = Color(0xFF2E6B4F);
const mint = Color(0xFFB2F1CC);
const gold = Color(0xFFE8B04B); // sacred: holds, pledges, growth. Nothing else.
const paper = Color(0xFFFAF8F2);
const deep = Color(0xFF0B3D4C);
const tx2 = Color(0xFF55645B);

// ---------- motion (RISE / SWAY / FALL / BLOOM) ----------
class Motion {
  static const rise = Duration(milliseconds: 300);
  static const sway = Duration(seconds: 3);
  static const fall = Duration(milliseconds: 2200);
  static const hold = Duration(milliseconds: 1100); // the Thumb Promise
  static const riseCurve = Curves.easeOutCubic;

  /// Reduced motion: still beauty, opacity only.
  static bool reduced(BuildContext context) =>
      MediaQuery.of(context).disableAnimations;
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

TextStyle kicker() => const TextStyle(
    fontSize: 11, letterSpacing: 2.5, fontWeight: FontWeight.w800, color: fern);

ThemeData dawnlight() => ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: paper,
      colorScheme: ColorScheme.fromSeed(seedColor: fern),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
      ),
    );

/// The sky at the visitor's real hour - shared logic with website and PWA.
List<Color> skyColors(int hour) {
  if (hour >= 5 && hour < 9) return [const Color(0xFFFFF3DD), paper];
  if (hour >= 9 && hour < 17) return [const Color(0xFFE9F6EF), paper];
  if (hour >= 17 && hour < 20) return [const Color(0xFFFFE9D4), paper];
  return [const Color(0xFFE3E9F3), paper];
}
