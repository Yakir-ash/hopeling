// Hopeling - small actions, real hope.
// The native companion. The PWA is the blueprint; this is the definitive
// version (NATIVE.md). Slice 1: foundation + the Thumb Promise.

import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'features/grove/grove_screen.dart';

void main() => runApp(const HopelingApp());

class HopelingApp extends StatelessWidget {
  const HopelingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hopeling',
      debugShowCheckedModeBanner: false,
      theme: dawnlight(),
      home: const GroveScreen(),
    );
  }
}
