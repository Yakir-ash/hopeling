// Firefly Night - draw with light. A dark summer meadow full of
// drifting fireflies; wherever the child draws, the fireflies gather
// along the glowing trail before it fades, so for a few seconds their
// finger-line is written in living light. No goal, no end, no score -
// free play in the oldest sense. The one true thing it carries:
// fireflies really do talk to each other in flashes of light.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/haptics.dart';
import '../../../core/kid_theme.dart';
import '../../../core/theme.dart' show Motion;

// ---------- pure logic (tested) ----------

/// Trail points older than this many seconds have fully faded.
const trailLife = 3.0;

/// 0..1 brightness of a trail point of the given age.
double trailGlow(double age) =>
    age >= trailLife ? 0 : (1 - age / trailLife).clamp(0.0, 1.0);

class FireflyCopy {
  static const intro =
      'Fireflies talk in flashes of light. Draw, and they will '
      'follow your glow.';
  static const fact =
      '🌿 Each kind of firefly has its own flash pattern - a language '
      'of light.';
}

// ---------- the game ----------

class _Fly {
  Offset p, v;
  double phase;
  _Fly(this.p, this.v, this.phase);
}

class _TrailPoint {
  final Offset p;
  double age = 0;
  _TrailPoint(this.p);
}

class FireflyNight extends StatefulWidget {
  final void Function(String) speak;
  const FireflyNight({super.key, required this.speak});

  @override
  State<FireflyNight> createState() => _FireflyNightState();
}

class _FireflyNightState extends State<FireflyNight>
    with SingleTickerProviderStateMixin {
  final flies = <_Fly>[];
  final trail = <_TrailPoint>[];
  Ticker? ticker;
  Duration last = Duration.zero;
  double time = 0;
  final rand = Random(3);

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 22; i++) {
      flies.add(_Fly(
          Offset(rand.nextDouble(), rand.nextDouble()),
          Offset.zero,
          rand.nextDouble() * 2 * pi));
    }
    ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    ticker?.dispose();
    super.dispose();
  }

  void _tick(Duration now) {
    final dt = ((now - last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    last = now;
    if (dt == 0) return;
    time += dt;
    final still = Motion.still(context);

    for (final t in trail) {
      t.age += dt;
    }
    trail.removeWhere((t) => t.age >= trailLife);

    if (!still) {
      for (final f in flies) {
        // wander...
        var force = Offset(
                sin(time * 0.6 + f.phase), cos(time * 0.5 + f.phase * 1.3)) *
            0.008;
        // ...unless there is fresh light to gather around
        _TrailPoint? nearest;
        var best = double.infinity;
        for (final t in trail) {
          if (t.age > trailLife * 0.7) continue;
          final d = (t.p - f.p).distance;
          if (d < best) {
            best = d;
            nearest = t;
          }
        }
        if (nearest != null && best > 0.02) {
          force = (nearest.p - f.p) / best * 0.06;
        }
        f.v = (f.v + force * dt * 8) * 0.96;
        f.p += f.v * dt;
        f.p = Offset(f.p.dx.clamp(0.02, 0.98), f.p.dy.clamp(0.02, 0.98));
      }
    }
    setState(() {});
  }

  void _draw(Offset local, Size s) {
    final p = Offset(local.dx / s.width, local.dy / s.height);
    if (trail.isEmpty || (trail.last.p - p).distance > 0.015) {
      trail.add(_TrailPoint(p));
      if (trail.length > 160) trail.removeAt(0);
      if (trail.length % 12 == 0) Haptics.tick();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141C36),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 8, 4),
            child: Row(children: [
              Expanded(
                  child: Text('✨ Firefly night',
                      style: kidTitle(20, color: const Color(0xFFE8E4D2)))),
              IconButton(
                  tooltip: 'Leave the night meadow',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close,
                      color: Color(0xFF8B93B4), size: 20)),
            ]),
          ),
          Text(FireflyCopy.intro,
              textAlign: TextAlign.center,
              style: kidBody(13, color: const Color(0xFF8B93B4))),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: LayoutBuilder(builder: (context, box) {
                final s = Size(box.maxWidth, box.maxHeight);
                return GestureDetector(
                  onPanStart: (d) => _draw(d.localPosition, s),
                  onPanUpdate: (d) => _draw(d.localPosition, s),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                          color: const Color(0xFF2A3752), width: 2),
                    ),
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _NightMeadowPainter(flies, trail, time),
                    ),
                  ),
                );
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Text(FireflyCopy.fact,
                textAlign: TextAlign.center,
                style: kidBody(12, color: const Color(0xFF8B93B4))),
          ),
        ]),
      ),
    );
  }
}

class _NightMeadowPainter extends CustomPainter {
  final List<_Fly> flies;
  final List<_TrailPoint> trail;
  final double time;
  _NightMeadowPainter(this.flies, this.trail, this.time);

  @override
  void paint(Canvas canvas, Size s) {
    // the dark meadow: deep night sky over sleeping grass
    canvas.drawRect(
        Offset.zero & s,
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF10172E), Color(0xFF1C2745)])
              .createShader(Offset.zero & s));
    final r = Random(9);
    for (var i = 0; i < 18; i++) {
      canvas.drawCircle(
          Offset(s.width * r.nextDouble(), s.height * r.nextDouble() * 0.4),
          0.8,
          Paint()..color = Colors.white.withValues(alpha: 0.35));
    }
    final grass = Path()..moveTo(0, s.height);
    for (double x = 0; x <= s.width; x += s.width / 24) {
      grass.lineTo(x, s.height * 0.92 + sin(x / 30) * 5);
    }
    grass
      ..lineTo(s.width, s.height)
      ..close();
    canvas.drawPath(grass, Paint()..color = const Color(0xFF0C1226));

    // the drawn trail: fading light
    for (final t in trail) {
      final g = trailGlow(t.age);
      if (g <= 0) continue;
      canvas.drawCircle(
          Offset(t.p.dx * s.width, t.p.dy * s.height),
          5 * g,
          Paint()
            ..color = const Color(0xFFFFF3A6).withValues(alpha: 0.28 * g)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }

    // the fireflies: bodies with breathing glow
    for (final f in flies) {
      final o = Offset(f.p.dx * s.width, f.p.dy * s.height);
      final pulse = 0.55 + 0.45 * sin(time * 2.2 + f.phase * 3);
      canvas.drawCircle(
          o,
          7 * pulse,
          Paint()
            ..color =
                const Color(0xFFFFF3A6).withValues(alpha: 0.35 * pulse)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      canvas.drawCircle(
          o,
          2.2,
          Paint()
            ..color = const Color(0xFFFFF7C8)
                .withValues(alpha: 0.6 + 0.4 * pulse));
    }
  }

  @override
  bool shouldRepaint(_NightMeadowPainter old) => true;
}
