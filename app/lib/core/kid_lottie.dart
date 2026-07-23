// Named animation slots. The app declares WHERE professional animation
// belongs (the guide, a celebration, the bedtime moon); the assets
// arrive separately as Lottie files dropped into assets/lottie/, one
// per slot name. A slot whose file has not arrived yet simply shows
// its fallback - today's emoji and drift - so the app is always whole,
// and every downloaded animation upgrades exactly one moment.
// See ASSETS.md for the curated shopping list.

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'theme.dart' show Motion;

class KidLottie extends StatelessWidget {
  final String slot; // assets/lottie/<slot>.json
  final double size;
  final Widget fallback;
  final bool repeat;
  const KidLottie(
      {super.key,
      required this.slot,
      required this.size,
      required this.fallback,
      this.repeat = true});

  @override
  Widget build(BuildContext context) {
    final still = Motion.still(context);
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        'assets/lottie/$slot.json',
        fit: BoxFit.contain,
        repeat: repeat && !still,
        animate: !still,
        errorBuilder: (_, __, ___) => Center(child: fallback),
      ),
    );
  }
}
