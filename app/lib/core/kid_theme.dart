// Hopeling Kids is not a section - it is its own app that happens to
// share a backend and a mission. This file is its design system: a
// candy-soft palette a picture book would wear, chunky rounded cards,
// touch targets a four-year-old thumb cannot miss, a bouncy route
// transition, and the squish - every pressable thing compresses like
// something alive. An adult who wanders in should think: this is a
// completely different product.

import 'package:flutter/material.dart';

import 'haptics.dart';
import 'theme.dart' show Motion;

// ---------- the Hopeling Kids palette ----------
const kidCream = Color(0xFFFFF9EC); // the paper of the whole app
const kidSky = Color(0xFFBDE3FF);
const kidSkyDeep = Color(0xFF7CBAEB);
const kidSun = Color(0xFFFFE08A);
const kidCoral = Color(0xFFFFB89E);
const kidLeaf = Color(0xFFB5E39B);
const kidLeafDeep = Color(0xFF6FAE54);
const kidBerry = Color(0xFFD9C2F0);
const kidInk = Color(0xFF463A45); // softer than adult ink, never harsh
const kidInkLight = Color(0xFF8B7E8A);

/// Room colors: each of the four rooms has its own weather.
const kidRoomColors = [kidSky, kidLeaf, kidSun, kidBerry];

/// The guide's one daily thought - pure wonder, never a summons.
/// The guide is a companion, not a mascot with an agenda: it never
/// waits for you, never misses you, never asks you to come back.
const guideTips = [
  'Did you know butterflies taste with their feet?',
  'Somewhere right now, an owl is fast asleep.',
  'Every big tree started smaller than your hand.',
  'Listen... how many sounds can you hear right now?',
  'Snails can sleep for months. Champions of napping.',
  'The clouds today have never existed before. Brand new clouds!',
  'A bee visits hundreds of flowers in one trip.',
];

// ---------- type: big, round-feeling, friendly ----------
TextStyle kidTitle(double size, {Color color = kidInk}) => TextStyle(
    fontSize: size,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: 0.2,
    color: color);

TextStyle kidBody(double size, {Color color = kidInk}) => TextStyle(
    fontSize: size, height: 1.5, fontWeight: FontWeight.w500, color: color);

// ---------- motion: everything arrives with a small bounce ----------
Route<T> kidPush<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (context, anim, _, child) {
        if (Motion.still(context)) return child;
        final curved =
            CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
              scale: Tween(begin: 0.92, end: 1.0).animate(curved),
              child: child),
        );
      },
    );

/// The squish: press it and it compresses like something alive,
/// release and it springs back. Wraps any child; guarantees a
/// 56px minimum touch target.
class KidSquish extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  const KidSquish(
      {super.key, required this.child, this.onTap, this.semanticLabel});

  @override
  State<KidSquish> createState() => _KidSquishState();
}

class _KidSquishState extends State<KidSquish> {
  bool down = false;

  @override
  Widget build(BuildContext context) {
    final still = Motion.still(context);
    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: (_) => setState(() => down = true),
        onTapCancel: () => setState(() => down = false),
        onTapUp: (_) => setState(() => down = false),
        onTap: widget.onTap == null
            ? null
            : () {
                Haptics.tick();
                widget.onTap!();
              },
        child: AnimatedScale(
          scale: still ? 1 : (down ? 0.95 : 1),
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(minHeight: 56, minWidth: 56),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// The chunky card every kid surface is built from: thick soft border,
/// big radius, a bottom shadow like a sticker not a floating sheet.
class KidCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final VoidCallback? onTap;
  final String? semanticLabel;
  const KidCard(
      {super.key,
      required this.child,
      this.color = Colors.white,
      this.onTap,
      this.semanticLabel});

  @override
  Widget build(BuildContext context) {
    return KidSquish(
      onTap: onTap,
      semanticLabel: semanticLabel,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
              color: kidInk.withValues(alpha: 0.10), width: 2),
          boxShadow: [
            BoxShadow(
                color: kidInk.withValues(alpha: 0.10),
                offset: const Offset(0, 5),
                blurRadius: 0),
          ],
        ),
        child: child,
      ),
    );
  }
}

/// A gentle forever-drift for decorative emoji - clouds, leaves, the
/// guide's bob. Still under reduced motion.
class KidDrift extends StatefulWidget {
  final Widget child;
  final double amount;
  final int seed;
  const KidDrift(
      {super.key, required this.child, this.amount = 5, this.seed = 0});

  @override
  State<KidDrift> createState() => _KidDriftState();
}

class _KidDriftState extends State<KidDrift>
    with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2600 + widget.seed % 5 * 350));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !Motion.still(context)) c.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Motion.still(context)) return widget.child;
    return AnimatedBuilder(
      animation: c,
      builder: (_, child) => Transform.translate(
          offset: Offset(
              0, -widget.amount * Curves.easeInOut.transform(c.value)),
          child: child),
      child: widget.child,
    );
  }
}

/// The guide's speech bubble - the same comic language the stories
/// speak, so the whole app feels like one picture book.
class GuideBubble extends StatelessWidget {
  final String text;
  const GuideBubble({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: kidInk.withValues(alpha: 0.15), width: 2),
      ),
      child: Text(text, style: kidBody(14.5)),
    );
  }
}
