// Bedtime home - the forest quietly preparing for sleep. Not a dark
// theme: a moonlit clearing with slow fireflies and drifting clouds,
// one story chosen for tonight, the guardian settling into its real
// nighttime habit, one gentle question that is never required and
// never stored, and a healthy ending. Everything here moves at half
// speed, and under reduced motion it does not move at all.

import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/kid_lottie.dart';
import '../../core/theme.dart';
import '../../data/bedtime.dart';
import '../../data/content.dart';

const _nightInk = Color(0xFFE8E4D2); // warm candle-white text
const _nightDim = Color(0xFF8B93B4); // quiet blue-grey

class BedtimeHome extends StatefulWidget {
  final String kidName;
  final Lesson? story; // tonight's one story
  final bool storyRead;
  final GuardianDef? guardian;
  final VoidCallback onOpenStory;
  final VoidCallback onExitGate; // the parent lock
  final void Function(String) speak;
  const BedtimeHome(
      {super.key,
      required this.kidName,
      required this.story,
      required this.storyRead,
      required this.guardian,
      required this.onOpenStory,
      required this.onExitGate,
      required this.speak});

  @override
  State<BedtimeHome> createState() => _BedtimeHomeState();
}

class _BedtimeHomeState extends State<BedtimeHome>
    with SingleTickerProviderStateMixin {
  late final AnimationController drift = AnimationController(
      vsync: this, duration: const Duration(seconds: 24));
  bool reflected = false; // this session only - never stored

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !Motion.still(context)) drift.repeat();
    });
  }

  @override
  void dispose() {
    drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.guardian;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF141C36), Color(0xFF23304F), Color(0xFF2C3A56)],
        ),
      ),
      child: Stack(children: [
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: drift,
              builder: (_, __) => CustomPaint(
                  painter: _NightForestPainter(
                      Motion.still(context) ? 0.35 : drift.value)),
            ),
          ),
        ),
        SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
            children: [
              Row(children: [
                Expanded(
                    child: Text('Goodnight, ${widget.kidName} 🌙',
                        style: serif(24, color: _nightInk))),
                // slot: sleepy_moon.json - the night's quiet companion
                KidLottie(
                    slot: 'sleepy_moon',
                    size: 34,
                    fallback: const SizedBox.shrink()),
                IconButton(
                    tooltip: 'For grown-ups',
                    onPressed: widget.onExitGate,
                    icon: const Icon(Icons.lock_outline,
                        color: _nightDim, size: 20)),
              ]),
              const Text(BedtimeCopy.arriving,
                  style: TextStyle(fontSize: 13.5, color: _nightDim)),
              const SizedBox(height: 26),
              // one story, chosen - not a shelf
              if (widget.story != null)
                Semantics(
                  button: true,
                  label:
                      '${BedtimeCopy.shelf}. ${widget.story!.t}. Double tap to open.',
                  child: GestureDetector(
                    onTap: () {
                      Haptics.tick();
                      widget.onOpenStory();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: const Color(0xFF31405F),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color:
                                const Color(0xFFF6EFC1).withValues(alpha: 0.35),
                            width: 1),
                      ),
                      child: ExcludeSemantics(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(BedtimeCopy.shelf.toUpperCase(),
                                style: const TextStyle(
                                    fontSize: 11,
                                    letterSpacing: 2,
                                    color: Color(0xFFF6EFC1))),
                            const SizedBox(height: 10),
                            Text(
                                '${widget.storyRead ? '⭐ ' : '📖 '}'
                                '${widget.story!.t}',
                                style:
                                    serif(19, color: _nightInk, height: 1.35)),
                            const SizedBox(height: 6),
                            const Text(BedtimeCopy.shelfSub,
                                style: TextStyle(
                                    fontSize: 12.5,
                                    fontStyle: FontStyle.italic,
                                    color: _nightDim)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              // the guardian settles too - real biology, softly told
              if (g != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A3752).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(children: [
                    _Breathing(
                        still: Motion.still(context),
                        child: Text(g.emo,
                            style: const TextStyle(fontSize: 40))),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                          guardianRest(
                              g.cats.isEmpty ? '' : g.cats.first, g.name),
                          style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.6,
                              color: _nightInk)),
                    ),
                  ]),
                ),
              const SizedBox(height: 18),
              // one gentle question - a moment, not a data point
              if (!reflected)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A3752).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(reflectionQuestion(),
                          style: serif(17, color: _nightInk, height: 1.4)),
                      const SizedBox(height: 6),
                      const Text(
                          'you can say it out loud, or just think it',
                          style: TextStyle(
                              fontSize: 12, color: _nightDim)),
                      const SizedBox(height: 12),
                      Wrap(spacing: 10, runSpacing: 10, children: [
                        for (final e in const ['🌟', '😊', '😮', '🥱'])
                          ActionChip(
                            label: Text(e,
                                style: const TextStyle(fontSize: 20)),
                            backgroundColor: const Color(0xFF31405F),
                            side: BorderSide.none,
                            onPressed: () => _answer(),
                          ),
                        ActionChip(
                          label: const Text(BedtimeCopy.reflectionSkip,
                              style: TextStyle(
                                  fontSize: 12.5, color: _nightDim)),
                          backgroundColor: const Color(0xFF31405F),
                          side: BorderSide.none,
                          onPressed: () => _answer(),
                        ),
                      ]),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.center,
                  child: Column(children: [
                    Text(BedtimeCopy.reflectionThanks,
                        style: serif(18, color: _nightInk)),
                    const SizedBox(height: 10),
                    const Text(BedtimeCopy.ending,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13.5,
                            height: 1.7,
                            color: _nightDim)),
                  ]),
                ),
              const SizedBox(height: 30),
              const Center(
                child: Text('the forest sleeps with you',
                    style: TextStyle(
                        fontSize: 11.5,
                        letterSpacing: 3,
                        color: _nightDim)),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  void _answer() {
    Haptics.tick();
    widget.speak(BedtimeCopy.reflectionThanks.replaceAll('🌙', ''));
    setState(() => reflected = true);
  }
}

/// A slow breath for a sleeping friend: scale 1.0 -> 1.04 over ~4s.
class _Breathing extends StatefulWidget {
  final Widget child;
  final bool still;
  const _Breathing({required this.child, required this.still});

  @override
  State<_Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<_Breathing>
    with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 4200));

  @override
  void initState() {
    super.initState();
    if (!widget.still) c.repeat(reverse: true);
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.still
      ? widget.child
      : AnimatedBuilder(
          animation: c,
          builder: (_, child) => Transform.scale(
              scale: 1 + 0.04 * Curves.easeInOut.transform(c.value),
              child: child),
          child: widget.child);
}

/// The moonlit clearing: a cratered moon, slow star field, drifting
/// clouds, layered sleeping treeline, and fireflies that glow and dim
/// on their own slow clocks. Deterministic layout; only the drift
/// phase animates, so the forest is calm, never busy.
class _NightForestPainter extends CustomPainter {
  final double t; // 0..1 drift phase
  _NightForestPainter(this.t);

  @override
  void paint(Canvas canvas, Size s, ) {
    final r = Random(77);
    // stars
    for (var i = 0; i < 40; i++) {
      final o = Offset(s.width * r.nextDouble(),
          s.height * r.nextDouble() * 0.45);
      final tw = 0.35 + 0.65 * (0.5 + 0.5 * sin(t * 2 * pi + i));
      canvas.drawCircle(
          o,
          0.7 + r.nextDouble(),
          Paint()..color = Colors.white.withValues(alpha: 0.5 * tw));
    }
    // moon
    final m = Offset(s.width * 0.78, s.height * 0.13);
    canvas.drawCircle(m, 34,
        Paint()..color = const Color(0xFFF6EFC1).withValues(alpha: 0.18));
    canvas.drawCircle(m, 24, Paint()..color = const Color(0xFFF6EFC1));
    for (final (dx, dy, cr) in [(-7.0, -4.0, 4.0), (6.0, 5.0, 3.0), (2.0, -8.0, 2.4)]) {
      canvas.drawCircle(m + Offset(dx, dy), cr,
          Paint()..color = const Color(0xFFE3D9A4));
    }
    // slow clouds
    final cloud = Paint()..color = Colors.white.withValues(alpha: 0.05);
    for (var i = 0; i < 3; i++) {
      final cx = ((t * 0.3 + i * 0.33) % 1.2 - 0.1) * s.width;
      final cy = s.height * (0.1 + i * 0.08);
      for (final (dx, rad) in [(0.0, 26.0), (20.0, 32.0), (44.0, 24.0)]) {
        canvas.drawCircle(Offset(cx + dx, cy), rad, cloud);
      }
    }
    // sleeping treeline, two depths
    for (final (top, col) in [
      (0.62, const Color(0xFF1B2749)),
      (0.72, const Color(0xFF121C38)),
    ]) {
      final path = Path()..moveTo(0, s.height);
      for (double x = 0; x <= s.width; x += s.width / 30) {
        path.lineTo(
            x,
            s.height * top +
                sin(x / s.width * pi * 3 + top * 9) * s.height * 0.03);
      }
      path
        ..lineTo(s.width, s.height)
        ..close();
      canvas.drawPath(path, Paint()..color = col);
    }
    // fireflies on their own slow clocks
    for (var i = 0; i < 8; i++) {
      final fx = s.width * r.nextDouble();
      final fy = s.height * (0.55 + r.nextDouble() * 0.35);
      final phase = r.nextDouble();
      final glow =
          (0.5 + 0.5 * sin((t + phase) * 2 * pi)).clamp(0.0, 1.0);
      canvas.drawCircle(
          Offset(fx + sin((t + phase) * 2 * pi) * 6, fy),
          1.8,
          Paint()
            ..color =
                const Color(0xFFFFF3A6).withValues(alpha: 0.85 * glow)
            ..maskFilter =
                const MaskFilter.blur(BlurStyle.normal, 3));
    }
  }

  @override
  bool shouldRepaint(_NightForestPainter old) => old.t != t;
}
