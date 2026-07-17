// The shared vocabulary: how Hopeling rises, waits, reassures, and
// how wind moves through the grove when you ask for fresh air.

import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'haptics.dart';
import 'theme.dart';

/// A Wikipedia photo with an honest fallback chain: try the large render,
/// fall back to the guaranteed small thumbnail, fall back to the world's
/// emoji on warm mint. Never a broken-image glyph, never a gray void.
class WikiImage extends StatelessWidget {
  final String big;
  final String small;
  final String emo;
  final BoxFit fit;
  const WikiImage(
      {super.key,
      required this.big,
      required this.small,
      required this.emo,
      this.fit = BoxFit.cover});

  Widget _emoji() => Container(
        color: mint.withValues(alpha: 0.25),
        alignment: Alignment.center,
        child: Text(emo, style: const TextStyle(fontSize: 40)),
      );

  @override
  Widget build(BuildContext context) {
    if (small.isEmpty && big.isEmpty) return _emoji();
    final smallImage = CachedNetworkImage(
      imageUrl: small.isEmpty ? big : small,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 300),
      placeholder: (_, __) => Container(color: mint.withValues(alpha: 0.15)),
      errorWidget: (_, __, ___) => _emoji(),
    );
    if (big.isEmpty || big == small) return smallImage;
    // Progressive: the small thumbnail (already on disk from the card that
    // led here) shows INSTANTLY; the large render fades in over it when
    // ready. The flow never waits on the network.
    return Stack(
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(child: smallImage),
        CachedNetworkImage(
          imageUrl: big,
          fit: fit,
          fadeInDuration: const Duration(milliseconds: 250),
          placeholder: (_, __) => const SizedBox.expand(),
          errorWidget: (_, __, ___) => const SizedBox.expand(),
        ),
      ],
    );
  }
}

/// DRIFT: large hero imagery breathes very slowly while you read.
/// The fifth verb of the motion language. Subtle or absent, never busy.
class Drift extends StatefulWidget {
  final Widget child;
  const Drift({super.key, required this.child});

  @override
  State<Drift> createState() => _DriftState();
}

class _DriftState extends State<Drift> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 22))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (Motion.still(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.scale(
        scale: 1.0 + 0.05 * Curves.easeInOut.transform(_c.value),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// RISE: every push grows up from the ground, 300ms, settles.
Route<T> risePush<T>(Widget page) => PageRouteBuilder<T>(
      transitionDuration: Motion.rise,
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (context, anim, _, child) {
        if (Motion.reduced(context)) {
          return FadeTransition(opacity: anim, child: child);
        }
        final curved = CurvedAnimation(parent: anim, curve: Motion.riseCurve);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
                    begin: const Offset(0, 0.04), end: Offset.zero)
                .animate(curved),
            child: child,
          ),
        );
      },
    );

/// The breathing seed: Hopeling's only loading state.
class LoadingSeed extends StatefulWidget {
  final String line;
  const LoadingSeed({super.key, this.line = 'Listening to the world...'});

  @override
  State<LoadingSeed> createState() => _LoadingSeedState();
}

class _LoadingSeedState extends State<LoadingSeed>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: 0.35, end: 1).animate(
                CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
            child: const Text('🌰', style: TextStyle(fontSize: 40)),
          ),
          const SizedBox(height: 12),
          Text(widget.line,
              style: const TextStyle(fontSize: 13, color: tx2)),
        ],
      ),
    );
  }
}

/// Offline is not an alarm. It is a reassurance.
class OfflineLeaf extends StatelessWidget {
  final String line;
  const OfflineLeaf({super.key, this.line = 'offline · your saved world is here'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: mint.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text('🍃 $line',
          style: const TextStyle(
              fontSize: 11.5, fontWeight: FontWeight.w600, color: ink)),
    );
  }
}

/// Pull to refresh = wind moves through the grove.
class WindRefresh extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  const WindRefresh({super.key, required this.child, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: fern,
      backgroundColor: paper,
      displacement: 30,
      onRefresh: () async {
        Haptics.settle();
        await onRefresh();
        if (context.mounted && !Motion.reduced(context)) {
          WindSweep.show(context);
        }
      },
      child: child,
    );
  }
}

/// A handful of leaves cross the screen, once, and are gone.
class WindSweep {
  static void show(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(builder: (_) => _WindLayer(onDone: () => entry.remove()));
    overlay.insert(entry);
  }
}

class _WindLayer extends StatefulWidget {
  final VoidCallback onDone;
  const _WindLayer({required this.onDone});

  @override
  State<_WindLayer> createState() => _WindLayerState();
}

class _WindLayerState extends State<_WindLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  final List<List<double>> leaves = List.generate(
      7,
      (_) => [
            Random().nextDouble() * 0.5, // vertical position
            0.4 + Random().nextDouble() * 0.6, // speed factor
            Random().nextDouble() * 0.3, // start delay
          ]);

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) {
          return Stack(
            children: leaves.map((l) {
              final p = ((_c.value - l[2]) / l[1]).clamp(0.0, 1.0);
              if (p <= 0 || p >= 1) return const SizedBox.shrink();
              return Positioned(
                left: -30 + p * (size.width + 60),
                top: size.height * (0.12 + l[0]) + sin(p * pi * 2) * 14,
                child: Opacity(
                  opacity: (1 - p) * 0.9,
                  child: Transform.rotate(
                    angle: p * pi * 1.5,
                    child: const Text('🍃', style: TextStyle(fontSize: 18)),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
