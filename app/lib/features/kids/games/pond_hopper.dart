// Pond Hopper - a real game of aiming and timing, in three ponds.
//
//   🌅 Morning pond    - learn the leap; pads drift and bob
//   🌬️ Windy lake      - the wind leans on her mid-air; aim into it
//   🌙 Moonlight marsh - long crossing at night; pads dip under on a
//                        rhythm you must read, fireflies join her and
//                        light the way
//
// Tap the water and the frog leaps there in a true ballistic arc,
// squash and stretch and all. A miss is never a failure: she
// splashes, swims with just her eyes above the waterline, and climbs
// the nearest pad. Actors are emoji glyphs and light - not my
// drawings.

import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../core/haptics.dart';
import '../../../core/kid_theme.dart';

// ---------- pure logic (tested) ----------

/// Lily pads from the near bank to the far one:
/// (x 0.18..0.82, distance from start, radius, drift phase).
/// Consecutive pads never step more than 0.45 sideways, so with sane
/// spacing the next pad is always within a frog's leap.
List<(double, double, double, double)> padSpots(
  int count,
  int seed, {
  double spaceMin = 95.0,
  double spaceMax = 150.0,
  double rMin = 28.0,
  double rMax = 38.0,
}) {
  final r = Random(seed);
  final out = <(double, double, double, double)>[];
  var x = 0.5;
  var d = 0.0;
  for (var i = 0; i < count; i++) {
    out.add((x, d, rMin + r.nextDouble() * (rMax - rMin),
        r.nextDouble() * pi * 2.0));
    x = (x + (r.nextDouble() * 0.9 - 0.45)).clamp(0.18, 0.82);
    d += spaceMin + r.nextDouble() * (spaceMax - spaceMin);
  }
  return out;
}

/// Butterflies (or fireflies) over the water: (x 0.15..0.85,
/// distance), spread evenly along the pond, always between banks.
List<(double, double)> bfSpots(int count, int seed, double span) {
  final r = Random(seed);
  final step = (span - 320.0) / max(1, count - 1);
  return [
    for (var i = 0; i < count; i++)
      (0.15 + r.nextDouble() * 0.7,
          180.0 + i * step + r.nextDouble() * 40.0)
  ];
}

/// A leap reaches toward the tap but never beyond the frog's power.
Offset clampLeap(Offset from, Offset to, double maxLeap) {
  final d = to - from;
  final len = d.distance;
  if (len <= maxLeap) return to;
  return from + d * (maxLeap / len);
}

/// The wind at time t: two overlapping breaths, bounded by
/// 1.4 * strength. Zero strength means still air.
double windX(double t, double strength) =>
    sin(t * 0.5) * strength + sin(t * 1.3) * strength * 0.4;

/// How far pad `phase` is dipped underwater at time t: 0 dry .. 1
/// fully under. A slow rhythm a child can read and wait out.
double dipAmount(double t, double phase) =>
    ((sin(t * 0.5 + phase * 2.0) - 0.2).clamp(0.0, 0.8)) / 0.8;

class PondLevel {
  final String name;
  final String emoji;
  final int padCount;
  final int flyCount;
  final int seed;
  final double spaceMin, spaceMax, rMin, rMax;
  final double driftAmp, driftSpeed;
  final double wind;
  final bool dip;
  final bool night;
  final List<Color> water;
  final Color bank, bankEdge;
  const PondLevel({
    required this.name,
    required this.emoji,
    required this.padCount,
    required this.flyCount,
    required this.seed,
    required this.spaceMin,
    required this.spaceMax,
    required this.rMin,
    required this.rMax,
    required this.driftAmp,
    required this.driftSpeed,
    required this.wind,
    required this.dip,
    required this.night,
    required this.water,
    required this.bank,
    required this.bankEdge,
  });

  static const levels = [
    PondLevel(
      name: 'Morning pond',
      emoji: '🌅',
      padCount: 13,
      flyCount: 5,
      seed: 8,
      spaceMin: 95.0,
      spaceMax: 150.0,
      rMin: 28.0,
      rMax: 38.0,
      driftAmp: 14.0,
      driftSpeed: 0.5,
      wind: 0.0,
      dip: false,
      night: false,
      water: [Color(0xFF6FB7BE), Color(0xFF3A7D89), Color(0xFF25525F)],
      bank: Color(0xFF7FB069),
      bankEdge: Color(0xFF5E8C4A),
    ),
    PondLevel(
      name: 'Windy lake',
      emoji: '🌬️',
      padCount: 16,
      flyCount: 6,
      seed: 15,
      spaceMin: 100.0,
      spaceMax: 150.0,
      rMin: 26.0,
      rMax: 34.0,
      driftAmp: 18.0,
      driftSpeed: 0.8,
      wind: 26.0,
      dip: false,
      night: false,
      water: [Color(0xFF8CCBD1), Color(0xFF4A93A3), Color(0xFF2E6273)],
      bank: Color(0xFF8FBF6E),
      bankEdge: Color(0xFF6A9653),
    ),
    PondLevel(
      name: 'Moonlight marsh',
      emoji: '🌙',
      padCount: 20,
      flyCount: 7,
      seed: 23,
      spaceMin: 95.0,
      spaceMax: 140.0,
      rMin: 26.0,
      rMax: 34.0,
      driftAmp: 10.0,
      driftSpeed: 0.4,
      wind: 0.0,
      dip: true,
      night: true,
      water: [Color(0xFF2A3B66), Color(0xFF1B2949), Color(0xFF101A33)],
      bank: Color(0xFF31513A),
      bankEdge: Color(0xFF23402C),
    ),
  ];
}

class PondCopy {
  static const intros = [
    'Tap the water where she should leap. The lily pads drift - '
        'pick your moment.',
    'The wind leans on her while she flies - aim a little into it.',
    'Some pads dip under the moonlit water - watch their rhythm, '
        'then leap.',
  ];
  static const dones = [
    'She crossed the whole pond! Some frogs can leap twenty times '
        'their own body length.',
    'She crossed the windy lake! Strong legs and a good aim can '
        'carry a frog through any weather.',
    'She crossed the marsh by moonlight! Fireflies flash their '
        'little lights to talk to each other in the dark.',
  ];
}

// ---------- the game ----------

enum _FrogState { sitting, jumping, swimming, finished }

class PondHopperGame extends FlameGame {
  PondHopperGame(
      {required this.level, required this.onDone, required this.slow});
  final PondLevel level;
  final VoidCallback onDone;
  final bool slow;

  static const maxLeap = 290.0;

  late final List<(double, double, double, double)> pads = padSpots(
    level.padCount,
    level.seed,
    spaceMin: level.spaceMin,
    spaceMax: level.spaceMax,
    rMin: level.rMin,
    rMax: level.rMax,
  );
  late final List<(double, double)> flies =
      bfSpots(level.flyCount, level.seed + 1, pads.last.$2);
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
  double windOff = 0;
  double landT = 0; // squash after landing
  double swimTick = 0;
  double doneT = 0;

  final joined = <int>{}; // butterflies or fireflies flying with her
  final bloomedPads = <int>{};
  final ripples = <_Ripple>[];
  final drops = <_Drop>[];

  double get jumpDur => slow ? 0.75 : 0.55;
  double get driftAmp => slow ? level.driftAmp * 0.4 : level.driftAmp;
  double get windNow =>
      windX(time, slow ? level.wind * 0.5 : level.wind);

  @override
  Color backgroundColor() => level.water.last;

  @override
  Future<void> onLoad() async {
    add(_Pond());
  }

  double padWorldY(int i) => pondLen - 140.0 - pads[i].$2;

  double padDip(int i) =>
      level.dip ? dipAmount(time, pads[i].$4) : 0.0;

  Offset padCenter(int i) {
    final (px, _, _, phase) = pads[i];
    return Offset(
      px * size.x + sin(time * level.driftSpeed + phase) * driftAmp,
      padWorldY(i) +
          sin(time * 0.9 + phase) * 5.0 +
          padDip(i) * 10.0,
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
    windOff = 0;
    state = _FrogState.jumping;
    Haptics.tick();
  }

  double _arcHeight() => 55.0 + (jumpTo - jumpFrom).distance * 0.28;

  /// Where the frog appears right now (world coords), including the
  /// height of her arc.
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
        // the marsh: her pad can yawn under the water - she just swims
        if (padDip(padIdx) > 0.85) {
          ripples.add(_Ripple(frogPos.dx, frogPos.dy));
          state = _FrogState.swimming;
          swimTick = 0;
        }
      case _FrogState.jumping:
        jumpT += dt / jumpDur;
        windOff += windNow * dt; // the wind carries her mid-air
        frogPos =
            Offset.lerp(jumpFrom, jumpTo, jumpT.clamp(0.0, 1.0))! +
                Offset(windOff, 0);
        _tryFlies();
        if (jumpT >= 1.0) _land();
      case _FrogState.swimming:
        final target = padCenter(_nearestDryPad(frogPos));
        final d = target - frogPos;
        if (d.distance < 8.0) {
          padIdx = _nearestDryPad(frogPos);
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
    final want = (frogPos.dy - size.y * 0.6)
        .clamp(0.0, max(0.0, pondLen - size.y));
    camY = camY + (want - camY) * (dt * 3.0).clamp(0.0, 1.0);
  }

  void _tryFlies() {
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

  /// The nearest pad that isn't underwater right now. If the whole
  /// marsh happens to be dipped, the nearest pad of all - it will
  /// surface before she reaches it.
  int _nearestDryPad(Offset from) {
    var best = -1;
    var bestD = double.infinity;
    for (var dry = 1; dry >= 0; dry--) {
      for (var i = 0; i < pads.length; i++) {
        if (dry == 1 && padDip(i) > 0.5) continue;
        final d = (padCenter(i) - from).distance;
        if (d < bestD) {
          bestD = d;
          best = i;
        }
      }
      if (best >= 0) return best;
    }
    return 0;
  }

  void _land() {
    // the far bank
    if (jumpTo.dy < 130.0) {
      state = _FrogState.finished;
      frogPos = Offset(frogPos.dx.clamp(30.0, size.x - 30.0), 90.0);
      doneT = 0;
      Haptics.settle();
      onDone();
      return;
    }
    // a dry pad under her?
    for (var i = 0; i < pads.length; i++) {
      final c = padCenter(i);
      if ((c - frogPos).distance <= pads[i].$3 + 16.0 &&
          padDip(i) < 0.6) {
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
  final moon = _Glyph('🌙', 34.0);
  final note = _Glyph('🎶', 22.0);

  @override
  void render(Canvas canvas) {
    if (!game.camReady) return;
    final s = game.size;
    final lv = game.level;

    canvas.save();
    canvas.translate(0, -game.camY);

    // water
    canvas.drawRect(
      Rect.fromLTWH(0, 0, s.x, game.pondLen),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: lv.water,
        ).createShader(Rect.fromLTWH(0, 0, s.x, game.pondLen)),
    );

    // drifting light on the water (moonlight at night)
    final caustic = Paint()
      ..color = (lv.night ? const Color(0xFFBFD4FF) : Colors.white)
          .withValues(alpha: lv.night ? 0.05 : 0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    for (var i = 0; i < 14; i++) {
      final cy = (i * 190.0 + game.time * 10.0) % game.pondLen;
      final cx = s.x * (0.2 + 0.6 * ((sin(i * 3.7) + 1.0) / 2.0)) +
          sin(game.time * 0.4 + i) * 20.0;
      canvas.drawOval(
          Rect.fromCenter(center: Offset(cx, cy), width: 90, height: 26),
          caustic);
    }

    // night: stars over the whole marsh, and a moon path
    if (lv.night) {
      final r = Random(6);
      for (var i = 0; i < 40; i++) {
        final sy2 = r.nextDouble() * game.pondLen;
        final tw = 0.4 + 0.6 * ((sin(game.time * 1.5 + i) + 1.0) / 2.0);
        canvas.drawCircle(
            Offset(s.x * r.nextDouble(), sy2),
            0.8 + r.nextDouble(),
            Paint()..color = Colors.white.withValues(alpha: 0.35 * tw));
      }
      // the moon's reflection: a shimmering path down the water
      for (var i = 0; i < 12; i++) {
        final my = 160.0 + i * 90.0;
        if (my > game.pondLen) break;
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(
                    s.x * 0.72 + sin(game.time * 0.8 + i) * 8.0, my),
                width: 34.0 - i * 1.5,
                height: 8),
            Paint()
              ..color = const Color(0xFFF6EFC1)
                  .withValues(alpha: 0.10 + 0.04 * sin(game.time + i)));
      }
    }

    // wind: streaks in the air when the gust leans
    final w = game.windNow;
    if (lv.wind > 0 && w.abs() > lv.wind * 0.45) {
      final streak = Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 7; i++) {
        final wy = game.camY + s.y * (0.1 + i * 0.13);
        final wx =
            (game.time * 110.0 + i * 130.0) % (s.x + 80.0) - 40.0;
        canvas.drawLine(Offset(wx, wy),
            Offset(wx + w.sign * 34.0, wy + 3.0), streak);
      }
    }

    // the far bank
    canvas.drawRect(
        Rect.fromLTWH(0, 0, s.x, 110), Paint()..color = lv.bank);
    canvas.drawRect(
        Rect.fromLTWH(0, 100, s.x, 14), Paint()..color = lv.bankEdge);
    for (var i = 0; i < 6; i++) {
      final rx = s.x * (0.08 + i * 0.17);
      reed.draw(canvas, Offset(rx, 62.0),
          angle: sin(game.time * 0.8 + i) * 0.08 + w * 0.004);
      if (!lv.night && i % 2 == 0) {
        tulip.draw(canvas, Offset(rx + 22.0, 84.0));
      }
    }
    if (lv.night) moon.draw(canvas, Offset(s.x * 0.72, 46.0));

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
      final dip = game.padDip(i);
      final fade = (1.0 - dip * 0.75).clamp(0.0, 1.0);
      // soft shadow in the water
      canvas.drawOval(
          Rect.fromCenter(
              center: c + const Offset(3, 5),
              width: r * 2.3,
              height: r * 1.7),
          Paint()..color = Colors.black.withValues(alpha: 0.14 * fade));
      // the pad, sinking into the dark as it dips
      canvas.drawOval(
          Rect.fromCenter(center: c, width: r * 2.3, height: r * 1.7),
          Paint()
            ..color = Color.lerp(const Color(0xFF3E8E4E),
                lv.water.last, dip * 0.8)!);
      canvas.drawOval(
          Rect.fromCenter(
              center: c + const Offset(-2, -2),
              width: r * 1.7,
              height: r * 1.2),
          Paint()
            ..color = Color.lerp(const Color(0xFF57A868),
                lv.water.last, dip * 0.8)!);
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
          Paint()
            ..color = lv.water[1].withValues(alpha: fade));
      canvas.restore();
      // water closing over a dipped pad
      if (dip > 0.6) {
        canvas.drawOval(
            Rect.fromCenter(
                center: c, width: r * 2.5, height: r * 1.9),
            Paint()
              ..color =
                  lv.water[1].withValues(alpha: (dip - 0.6) * 1.8));
      }
      // some pads carry a bud that blooms when she lands
      if (i % 3 == 1 && dip < 0.5) {
        final spot = c + Offset(r * 0.55, -r * 0.35);
        if (game.bloomedPads.contains(i)) {
          flower.draw(canvas, spot);
        } else {
          bud.draw(canvas, spot);
        }
      }
    }

    // butterflies by day, fireflies by night
    for (var i = 0; i < game.flies.length; i++) {
      if (game.joined.contains(i)) continue;
      final c = game.flyCenter(i);
      if (lv.night) {
        _firefly(canvas, c, game.time + i * 2.0);
      } else {
        butterfly.draw(canvas, c,
            angle: sin(game.time * 2.0 + i) * 0.2,
            sx: 0.8 + 0.2 * sin(game.time * 8.0 + i).abs());
      }
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

    // the frog
    final p = game.frogDrawPos();
    var sx = 1.0;
    var sy = 1.0;
    var tilt = 0.0;
    if (game.state == _FrogState.jumping) {
      final t = game.jumpT.clamp(0.0, 1.0);
      sy = 1.0 + 0.18 * sin(pi * t);
      sx = 1.0 - 0.08 * sin(pi * t);
      tilt =
          (game.jumpTo.dx - game.jumpFrom.dx).sign * 0.16 * sin(pi * t);
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
      canvas.clipRect(
          Rect.fromLTWH(p.dx - 30.0, p.dy - 30.0, 60.0, 22.0));
      frog.draw(canvas, p + const Offset(0, 6), sx: sx, sy: sy);
      canvas.restore();
    } else {
      frog.draw(canvas, p, angle: tilt, sx: sx, sy: sy);
    }

    // her companions: butterflies orbit, fireflies orbit and glow
    var slot = 0;
    for (final i in game.joined) {
      final a = game.time * 1.6 + slot * 2.1;
      final c = p + Offset(cos(a) * 36.0, sin(a) * 18.0 - 22.0);
      if (lv.night) {
        _firefly(canvas, c, game.time + i * 2.0, bright: true);
      } else {
        butterfly.draw(canvas, c,
            angle: sin(game.time * 3.0 + i) * 0.25, sx: 0.75, sy: 0.75);
      }
      slot++;
    }
    // at night her gathered fireflies light the water around her
    if (lv.night && game.joined.isNotEmpty) {
      canvas.drawCircle(
          p,
          60.0 + game.joined.length * 10.0,
          Paint()
            ..color = const Color(0xFFFFF3A6)
                .withValues(alpha: 0.03 + game.joined.length * 0.012)
            ..maskFilter =
                const MaskFilter.blur(BlurStyle.normal, 30));
    }

    // droplets and sparkles
    for (final d in game.drops) {
      final a = (1.0 - d.age / 0.7).clamp(0.0, 1.0);
      final pos = Offset(d.x + d.vx * d.age * 60.0,
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
        final t = game.doneT - i * 0.5;
        if (t < 0) continue;
        final rise = t % 2.0;
        final a = (1.0 - rise / 2.0).clamp(0.0, 1.0);
        canvas.saveLayer(
            null, Paint()..color = Colors.white.withValues(alpha: a));
        note.draw(
            canvas,
            game.frogPos +
                Offset(sin(t * 2.0 + i) * 14.0, -30.0 - rise * 40.0));
        canvas.restore();
      }
    }

    canvas.restore();
  }

  void _firefly(Canvas canvas, Offset c, double t,
      {bool bright = false}) {
    final pulse = 0.5 + 0.5 * ((sin(t * 3.0) + 1.0) / 2.0);
    canvas.drawCircle(
        c,
        bright ? 14.0 : 10.0,
        Paint()
          ..color = const Color(0xFFFFF3A6)
              .withValues(alpha: (bright ? 0.4 : 0.3) * pulse)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawCircle(
        c,
        3.2,
        Paint()
          ..color = const Color(0xFFFFF9D6)
              .withValues(alpha: 0.5 + 0.5 * pulse));
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
  int levelIdx = 0;
  bool done = false;

  @override
  Widget build(BuildContext context) {
    final level = PondLevel.levels[levelIdx];
    game ??= PondHopperGame(
        level: level,
        slow: MediaQuery.of(context).disableAnimations,
        onDone: () {
          if (mounted) {
            setState(() => done = true);
            widget.speak(PondCopy.dones[levelIdx]);
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
          // the three ponds
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < PondLevel.levels.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: KidSquish(
                    onTap: () => setState(() {
                      levelIdx = i;
                      game = null;
                      done = false;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: i == levelIdx ? kidSun : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: i == levelIdx
                                ? Colors.transparent
                                : kidInkLight.withValues(alpha: 0.25)),
                      ),
                      child: Text(
                          '${PondLevel.levels[i].emoji} '
                          '${PondLevel.levels[i].name}',
                          style: kidTitle(11.5)),
                    ),
                  ),
                ),
            ],
            ),
          ),
          const SizedBox(height: 6),
          Text(done ? 'she made it! 🎶' : PondCopy.intros[levelIdx],
              textAlign: TextAlign.center,
              style: kidBody(12.5, color: kidInkLight)),
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
                                  child: Text(PondCopy.dones[levelIdx],
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
