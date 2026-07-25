// Pond Hopper - a real game of aiming and timing. Tap the water and
// the frog leaps there in a true ballistic arc, squash and stretch
// and all. Lily pads drift and bob, so every jump is a decision:
// which pad, and when. Miss the pad? She splashes, bobs up, and
// swims to the nearest one - frogs are great swimmers, and nothing
// here is ever a failure. Butterflies hover over the water; leap
// through one and it joins her, fluttering alongside for the rest of
// the crossing. The far bank is the goal: reeds, morning light, and
// a song. Actors are emoji glyphs - drawn by professionals, not me.

import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../core/haptics.dart';
import '../../../core/kid_theme.dart';

// ---------- pure logic (tested) ----------

/// Lily pads from the near bank to the far one:
/// (x 0.18..0.82, distance from start, radius, drift phase).
/// Consecutive pads never step more than 0.45 sideways and sit
/// 95..150 apart, so the next pad is always within a frog's leap.
List<(double, double, double, double)> padSpots(int count, int seed) {
  final r = Random(seed);
  final out = <(double, double, double, double)>[];
  var x = 0.5;
  var d = 0.0;
  for (var i = 0; i < count; i++) {
    out.add((x, d, 28.0 + r.nextDouble() * 10.0,
        r.nextDouble() * pi * 2.0));
    x = (x + (r.nextDouble() * 0.9 - 0.45)).clamp(0.18, 0.82);
    d += 95.0 + r.nextDouble() * 55.0;
  }
  return out;
}

/// Butterflies hovering over the water: (x 0.15..0.85, distance).
List<(double, double)> bfSpots(int count, int seed) {
  final r = Random(seed);
  return [
    for (var i = 0; i < count; i++)
      (0.15 + r.nextDouble() * 0.7,
          180.0 + i * 220.0 + r.nextDouble() * 60.0)
  ];
}

/// A leap reaches toward the tap but never beyond the frog's power.
Offset clampLeap(Offset from, Offset to, double maxLeap) {
  final d = to - from;
  final len = d.distance;
  if (len <= maxLeap) return to;
  return from + d * (maxLeap / len);
}

class PondCopy {
  static const intro =
      'Tap the water where she should leap. The lily pads drift - '
      'pick your moment.';
  static const done =
      'She crossed the whole pond! Some frogs can leap twenty times '
      'their own body length.';
}

// ---------- the game ----------

enum _FrogState { sitting, jumping, swimming, finished }

class PondHopperGame extends FlameGame {
  PondHopperGame({required this.onDone, required this.slow});
  final VoidCallback onDone;
  final bool slow;

  static const maxLeap = 290.0;

  late final List<(double, double, double, double)> pads =
      padSpots(13, 8);
  late final List<(double, double)> flies = bfSpots(5, 9);
  late final double pondLen = 140.0 + pads.last.$2 + 260.0;

  double time = 0;
  double camY = 0;
  bool camReady = false;

  _FrogState state = _FrogState.sitting;
  int padIdx = 0;
  Offset frogPos = Offset.zero;
  Offset jumpFrom = Offset.zero;
  Offset jumpTo = Offset.zero;
  double jumpT = 0;
  double landT = 0; // squash after landing
  double swimTick = 0;
  double doneT = 0;

  final joined = <int>{}; // butterflies flying with her
  final bloomedPads = <int>{};
  final ripples = <_Ripple>[];
  final drops = <_Drop>[];

  double get jumpDur => slow ? 0.75 : 0.55;
  double get driftAmp => slow ? 6.0 : 14.0;

  @override
  Color backgroundColor() => const Color(0xFF2E6B77);

  @override
  Future<void> onLoad() async {
    add(_Pond());
  }

  double padWorldY(int i) => pondLen - 140.0 - pads[i].$2;

  Offset padCenter(int i) {
    final (px, _, _, phase) = pads[i];
    return Offset(
      px * size.x + sin(time * 0.5 + phase) * driftAmp,
      padWorldY(i) + sin(time * 0.9 + phase) * 5.0,
    );
  }

  Offset flyCenter(int i) {
    final (fx, fd) = flies[i];
    return Offset(
      fx * size.x + sin(time * 1.3 + i * 2.0) * 12.0,
      pondLen - 140.0 - fd + cos(time * 1.7 + i) * 8.0,
    );
  }

  void leap(Offset screenPoint) {
    if (state != _FrogState.sitting && state != _FrogState.swimming) {
      return;
    }
    final world = Offset(
      screenPoint.dx.clamp(20.0, size.x - 20.0),
      (screenPoint.dy + camY).clamp(40.0, pondLen - 20.0),
    );
    jumpFrom = frogPos;
    jumpTo = clampLeap(frogPos, world, maxLeap);
    jumpT = 0;
    state = _FrogState.jumping;
    Haptics.tick();
  }

  double _arcHeight() =>
      55.0 + (jumpTo - jumpFrom).distance * 0.28;

  /// Where the frog appears on screen right now (world coords),
  /// including the height of her arc.
  Offset frogDrawPos() {
    if (state == _FrogState.jumping) {
      final h = sin(pi * jumpT.clamp(0.0, 1.0)) * _arcHeight();
      return Offset(frogPos.dx, frogPos.dy - h);
    }
    return frogPos;
  }

  @override
  void update(double dt) {
    super.update(dt);
    time += dt;
    if (!camReady && size.y > 0) {
      camReady = true;
      frogPos = padCenter(0) + const Offset(0, -6);
      camY = (pondLen - size.y).clamp(0.0, double.infinity);
    }
    if (!camReady) return;

    for (final r in ripples) {
      r.age += dt;
    }
    ripples.removeWhere((r) => r.age > 1.2);
    for (final d in drops) {
      d.age += dt;
    }
    drops.removeWhere((d) => d.age > 0.7);

    switch (state) {
      case _FrogState.sitting:
        frogPos = padCenter(padIdx) + const Offset(0, -6);
        if (landT > 0) landT -= dt;
      case _FrogState.jumping:
        jumpT += dt / jumpDur;
        frogPos = Offset.lerp(jumpFrom, jumpTo, jumpT.clamp(0.0, 1.0))!;
        _tryButterflies();
        if (jumpT >= 1.0) _land();
      case _FrogState.swimming:
        final target = padCenter(_nearestPad(frogPos));
        final d = target - frogPos;
        if (d.distance < 8.0) {
          padIdx = _nearestPad(frogPos);
          state = _FrogState.sitting;
          landT = 0.2;
          Haptics.tick();
        } else {
          frogPos = frogPos + d * ((90.0 * dt) / d.distance);
          swimTick += dt;
          if (swimTick > 0.45) {
            swimTick = 0;
            ripples.add(_Ripple(frogPos.dx, frogPos.dy));
          }
        }
      case _FrogState.finished:
        doneT += dt;
    }

    // the camera follows her up the pond
    final want =
        (frogPos.dy - size.y * 0.6).clamp(0.0, max(0.0, pondLen - size.y));
    camY = camY + (want - camY) * (dt * 3.0).clamp(0.0, 1.0);
  }

  void _tryButterflies() {
    final p = frogDrawPos();
    for (var i = 0; i < flies.length; i++) {
      if (joined.contains(i)) continue;
      if ((flyCenter(i) - p).distance < 44.0) {
        joined.add(i);
        Haptics.tick();
        for (var k = 0; k < 8; k++) {
          drops.add(_Drop(p.dx, p.dy, sparkle: true));
        }
      }
    }
  }

  int _nearestPad(Offset from) {
    var best = 0;
    var bestD = double.infinity;
    for (var i = 0; i < pads.length; i++) {
      final d = (padCenter(i) - from).distance;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  void _land() {
    // the far bank
    if (jumpTo.dy < 130.0) {
      state = _FrogState.finished;
      frogPos = Offset(jumpTo.dx, 90.0);
      doneT = 0;
      Haptics.settle();
      onDone();
      return;
    }
    // a pad under her?
    for (var i = 0; i < pads.length; i++) {
      final c = padCenter(i);
      if ((c - frogPos).distance <= pads[i].$3 + 16.0) {
        padIdx = i;
        state = _FrogState.sitting;
        landT = 0.2;
        ripples.add(_Ripple(c.dx, c.dy));
        if (i % 3 == 1) bloomedPads.add(i);
        Haptics.tick();
        return;
      }
    }
    // splash - she just swims, because frogs are great swimmers
    ripples.add(_Ripple(frogPos.dx, frogPos.dy));
    for (var k = 0; k < 10; k++) {
      drops.add(_Drop(frogPos.dx, frogPos.dy));
    }
    state = _FrogState.swimming;
    swimTick = 0;
  }
}

// ---------- rendering ----------

class _Glyph {
  final TextPainter tp;
  _Glyph(String s, double size)
      : tp = TextPainter(
          text: TextSpan(text: s, style: TextStyle(fontSize: size)),
          textDirection: TextDirection.ltr,
        )..layout();

  void draw(Canvas c, Offset center,
      {double angle = 0, double sx = 1, double sy = 1}) {
    c.save();
    c.translate(center.dx, center.dy);
    if (angle != 0) c.rotate(angle);
    c.scale(sx, sy);
    tp.paint(c, Offset(-tp.width / 2.0, -tp.height / 2.0));
    c.restore();
  }
}

class _Pond extends Component with HasGameReference<PondHopperGame> {
  final frog = _Glyph('🐸', 44.0);
  final butterfly = _Glyph('🦋', 26.0);
  final flower = _Glyph('🌸', 22.0);
  final bud = _Glyph('🌿', 16.0);
  final reed = _Glyph('🌾', 30.0);
  final tulip = _Glyph('🌷', 26.0);
  final note = _Glyph('🎶', 22.0);

  @override
  void render(Canvas canvas) {
    if (!game.camReady) return;
    final s = game.size;
    final cam = game.camY;

    canvas.save();
    canvas.translate(0, -cam);

    // water: deeper and darker toward the near bank
    canvas.drawRect(
      Rect.fromLTWH(0, 0, s.x, game.pondLen),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6FB7BE), Color(0xFF3A7D89), Color(0xFF25525F)],
        ).createShader(Rect.fromLTWH(0, 0, s.x, game.pondLen)),
    );

    // drifting light on the water
    final caustic = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    for (var i = 0; i < 14; i++) {
      final cy = (i * 190.0 + game.time * 10.0) % game.pondLen;
      final cx =
          s.x * (0.2 + 0.6 * ((sin(i * 3.7) + 1.0) / 2.0)) +
              sin(game.time * 0.4 + i) * 20.0;
      canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, cy), width: 90, height: 26),
          caustic);
    }

    // the far bank: morning grass and reeds
    canvas.drawRect(Rect.fromLTWH(0, 0, s.x, 110),
        Paint()..color = const Color(0xFF7FB069));
    canvas.drawRect(Rect.fromLTWH(0, 100, s.x, 14),
        Paint()..color = const Color(0xFF5E8C4A));
    for (var i = 0; i < 6; i++) {
      final rx = s.x * (0.08 + i * 0.17);
      reed.draw(canvas, Offset(rx, 62.0),
          angle: sin(game.time * 0.8 + i) * 0.08);
      if (i % 2 == 0) tulip.draw(canvas, Offset(rx + 22.0, 84.0));
    }

    // ripples
    for (final r in game.ripples) {
      final a = (1.0 - r.age / 1.2).clamp(0.0, 1.0);
      canvas.drawCircle(
          Offset(r.x, r.y),
          12.0 + r.age * 60.0,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0
            ..color = Colors.white.withValues(alpha: 0.45 * a));
    }

    // lily pads
    for (var i = 0; i < game.pads.length; i++) {
      final c = game.padCenter(i);
      final r = game.pads[i].$3;
      final phase = game.pads[i].$4;
      // soft shadow in the water
      canvas.drawOval(
          Rect.fromCenter(
              center: c + const Offset(3, 5),
              width: r * 2.3,
              height: r * 1.7),
          Paint()..color = Colors.black.withValues(alpha: 0.14));
      // the pad
      canvas.drawOval(
          Rect.fromCenter(center: c, width: r * 2.3, height: r * 1.7),
          Paint()..color = const Color(0xFF3E8E4E));
      canvas.drawOval(
          Rect.fromCenter(
              center: c + const Offset(-2, -2),
              width: r * 1.7,
              height: r * 1.2),
          Paint()..color = const Color(0xFF57A868));
      // the classic notch
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(phase);
      canvas.drawPath(
          Path()
            ..moveTo(0, 0)
            ..lineTo(r * 1.3, -r * 0.42)
            ..lineTo(r * 1.3, r * 0.42)
            ..close(),
          Paint()..color = const Color(0xFF37727F));
      canvas.restore();
      // some pads carry a bud that blooms when she lands
      if (i % 3 == 1) {
        final spot = c + Offset(r * 0.55, -r * 0.35);
        if (game.bloomedPads.contains(i)) {
          flower.draw(canvas, spot);
        } else {
          bud.draw(canvas, spot);
        }
      }
    }

    // butterflies still on the wing
    for (var i = 0; i < game.flies.length; i++) {
      if (game.joined.contains(i)) continue;
      final c = game.flyCenter(i);
      butterfly.draw(canvas, c,
          angle: sin(game.time * 2.0 + i) * 0.2,
          sx: 0.8 + 0.2 * sin(game.time * 8.0 + i).abs());
    }

    // her shadow while she flies
    if (game.state == _FrogState.jumping) {
      final t = game.jumpT.clamp(0.0, 1.0);
      final h = sin(pi * t);
      canvas.drawOval(
          Rect.fromCenter(
              center: game.frogPos + const Offset(0, 8),
              width: 34.0 * (1.0 - h * 0.5),
              height: 12.0 * (1.0 - h * 0.5)),
          Paint()..color = Colors.black.withValues(alpha: 0.18));
    }

    // the frog: squash on landing, stretch mid-leap, low in the
    // water while swimming
    final p = game.frogDrawPos();
    var sx = 1.0;
    var sy = 1.0;
    var tilt = 0.0;
    if (game.state == _FrogState.jumping) {
      final t = game.jumpT.clamp(0.0, 1.0);
      sy = 1.0 + 0.18 * sin(pi * t);
      sx = 1.0 - 0.08 * sin(pi * t);
      tilt = (game.jumpTo.dx - game.jumpFrom.dx).sign *
          0.16 *
          sin(pi * t);
    } else if (game.landT > 0) {
      sy = 0.82;
      sx = 1.12;
    } else if (game.state == _FrogState.swimming) {
      sy = 0.85;
    } else {
      sy = 1.0 + 0.03 * sin(game.time * 2.2); // breathing
    }
    if (game.state == _FrogState.swimming) {
      // just her eyes above the waterline, like a real frog
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(p.dx - 30.0, p.dy - 30.0, 60.0, 22.0));
      frog.draw(canvas, p + const Offset(0, 6), sx: sx, sy: sy);
      canvas.restore();
    } else {
      frog.draw(canvas, p, angle: tilt, sx: sx, sy: sy);
    }

    // her butterfly companions, orbiting
    var slot = 0;
    for (final i in game.joined) {
      final a = game.time * 1.6 + slot * 2.1;
      butterfly.draw(
          canvas,
          p + Offset(cos(a) * 36.0, sin(a) * 18.0 - 22.0),
          angle: sin(game.time * 3.0 + i) * 0.25,
          sx: 0.75,
          sy: 0.75);
      slot++;
    }

    // droplets and sparkles
    for (final d in game.drops) {
      final a = (1.0 - d.age / 0.7).clamp(0.0, 1.0);
      final pos = Offset(
          d.x + d.vx * d.age * 60.0,
          d.y + d.vy * d.age * 60.0 + 120.0 * d.age * d.age);
      canvas.drawCircle(
          pos,
          d.sparkle ? 2.6 * a : 2.2 * a,
          Paint()
            ..color = (d.sparkle
                    ? const Color(0xFFFFE08A)
                    : const Color(0xFFBFE8EC))
                .withValues(alpha: a));
    }

    // her song from the far bank
    if (game.state == _FrogState.finished) {
      for (var i = 0; i < 3; i++) {
        final t = (game.doneT - i * 0.5);
        if (t < 0) continue;
        final rise = (t % 2.0);
        final a = (1.0 - rise / 2.0).clamp(0.0, 1.0);
        canvas.saveLayer(null, Paint()..color = Colors.white.withValues(alpha: a));
        note.draw(
            canvas,
            game.frogPos +
                Offset(sin(t * 2.0 + i) * 14.0, -30.0 - rise * 40.0));
        canvas.restore();
      }
    }

    canvas.restore();
  }
}

class _Ripple {
  final double x, y;
  double age = 0;
  _Ripple(this.x, this.y);
}

class _Drop {
  final double x, y;
  final bool sparkle;
  final double vx = Random().nextDouble() * 2.0 - 1.0;
  final double vy = -Random().nextDouble() * 1.6 - 0.4;
  double age = 0;
  _Drop(this.x, this.y, {this.sparkle = false});
}

// ---------- the screen ----------

class PondHopper extends StatefulWidget {
  final void Function(String) speak;
  const PondHopper({super.key, required this.speak});

  @override
  State<PondHopper> createState() => _PondHopperState();
}

class _PondHopperState extends State<PondHopper> {
  PondHopperGame? game;
  bool done = false;

  @override
  Widget build(BuildContext context) {
    game ??= PondHopperGame(
        slow: MediaQuery.of(context).disableAnimations,
        onDone: () {
          if (mounted) {
            setState(() => done = true);
            widget.speak(PondCopy.done);
          }
        });
    return Scaffold(
      backgroundColor: kidCream,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 8, 4),
            child: Row(children: [
              Expanded(child: Text('🐸 Pond hopper', style: kidTitle(20))),
              IconButton(
                  tooltip: 'Leave the pond',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close,
                      color: kidInkLight, size: 20)),
            ]),
          ),
          Text(done ? 'she made it! 🎶' : PondCopy.intro,
              textAlign: TextAlign.center,
              style: kidBody(13, color: kidInkLight)),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GestureDetector(
                onTapDown: (d) => game!.leap(d.localPosition),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Stack(fit: StackFit.expand, children: [
                    GameWidget(game: game!),
                    if (done)
                      Align(
                        alignment: const Alignment(0, 0.86),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      color: Colors.white
                                          .withValues(alpha: 0.95),
                                      borderRadius:
                                          BorderRadius.circular(16)),
                                  child: Text(PondCopy.done,
                                      textAlign: TextAlign.center,
                                      style: kidBody(13)),
                                ),
                                const SizedBox(height: 10),
                                KidSquish(
                                  onTap: () => setState(() {
                                    game = null;
                                    done = false;
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 22, vertical: 11),
                                    decoration: BoxDecoration(
                                        color: kidSun,
                                        borderRadius:
                                            BorderRadius.circular(20)),
                                    child: Text('🐸 Hop again',
                                        style: kidTitle(13.5)),
                                  ),
                                ),
                              ]),
                        ),
                      ),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
