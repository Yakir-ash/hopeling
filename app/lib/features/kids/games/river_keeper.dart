// River Keeper - litter falls out of the sky ANYWHERE on the water
// (blown from banks, dropped from bridges), splashes down where it
// lands, and drifts from there toward the sea; every piece the child
// taps flies into the basket, and the water visibly clears. The
// fish notice: tap them and they jump. Nothing is ever lost - a piece
// that slips past just comes around again, because rivers are patient
// and so are we. When the last piece is caught, the river breathes.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/haptics.dart';
import '../../../core/sfx.dart';
import '../../../core/kid_lottie.dart';
import '../../../core/kid_theme.dart';
import '../comic.dart' show ScenePainter, ComicScene;

// ---------- pure logic (tested) ----------

/// How clear the water looks, 0..1, from pieces caught.
double clarity(int caught, int total) =>
    total == 0 ? 1 : (caught / total).clamp(0.0, 1.0);

/// May a new piece land at (x, y)? Only if it keeps honest distance
/// from every piece already on the water - litter never stacks.
bool landingClear(
        Iterable<(double, double)> taken, double x, double y) =>
    taken.every((p) =>
        (p.$1 - x).abs() > 0.16 || (p.$2 - y).abs() > 0.14);

class RiverCopy {
  static const intro = 'The river is carrying litter. Tap each piece '
      'to catch it before the sea!';
  static const patience =
      'A piece that slips past just comes around again - rivers are '
      'patient, and so are we.';
  static const done =
      'Every piece caught before the sea. The river breathes '
      'easier - hear the fish?';
  static const fact =
      '🌿 Most litter in the sea started its journey on a street, '
      'far from any beach.';
}

const litterEmo = ['🥤', '🛍', '🥫', '👟', '🧃', '📦'];

// ---------- the game ----------

class _Litter {
  double x; // 0..1 across the screen - anywhere on the water
  double y; // 0..1 down the screen once afloat
  double targetY; // where its fall will land
  final int kind;
  final double sway;
  final double speed; // each piece drifts at its own pace
  double dropIn = 0; // 0 = still falling toward the water, 1 = afloat
  double splash = -1; // ring animation after it lands
  bool caught = false;
  double catchAnim = 0; // flies to basket
  Offset catchFrom = Offset.zero;
  _Litter(this.x, this.targetY, this.kind, this.sway, this.speed)
      : y = targetY;
}

class RiverKeeper extends StatefulWidget {
  final void Function(String) speak;
  const RiverKeeper({super.key, required this.speak});

  @override
  State<RiverKeeper> createState() => _RiverKeeperState();
}

class _RiverKeeperState extends State<RiverKeeper>
    with SingleTickerProviderStateMixin {
  // 🐣 gentle / 🦊 classic / 🦉 quick: pieces and current speed
  int level = 1;
  static const levels = [(8, 0.055), (12, 0.075), (16, 0.1), (24, 0.13)];
  static const caps = [3, 4, 5, 6]; // pieces on the water at once
  int get total => levels[level].$1;
  double get drift => levels[level].$2;
  int get cap => caps[level];
  final litter = <_Litter>[];
  int caught = 0;
  int spawned = 0;
  double phase = 0;
  double fishJump = 0;
  bool celebrated = false;
  Ticker? ticker;
  Duration last = Duration.zero;
  final rand = Random(7);

  @override
  void initState() {
    super.initState();
    ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    ticker?.dispose();
    super.dispose();
  }

  /// The river's course across the box, top to bottom with a bend.
  Offset riverPoint(double t, Size s) {
    final x = 0.5 +
        0.28 * sin(t * pi * 1.3 + 0.4) -
        0.1 * (1 - t);
    return Offset(x * s.width, (0.08 + t * 0.84) * s.height);
  }

  /// Where a piece actually is: falling from the sky toward its own
  /// landing spot, or afloat and swaying wherever it landed.
  Offset litterPos(_Litter l, Size s) {
    final yF = l.dropIn < 1
        ? -0.08 +
            (l.targetY + 0.08) * Curves.easeIn.transform(l.dropIn)
        : l.y;
    return Offset(
        l.x * s.width + sin(phase * 2 + l.sway) * 6, yF * s.height);
  }

  void _tick(Duration now) {
    final dt = ((now - last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    last = now;
    if (dt == 0) return;
    phase += dt;
    if (fishJump > 0) fishJump = (fishJump - dt * 1.6).clamp(0, 1);

    // spawn up to the total: litter falls out of the sky anywhere
    // on the water - never on top of a piece already there
    if (spawned < total &&
        (litter.isEmpty ||
            litter.where((l) => !l.caught).length < cap) &&
        rand.nextDouble() < dt * 1.6) {
      final x0 = 0.08 + rand.nextDouble() * 0.84;
      final y0 = 0.08 + rand.nextDouble() * 0.72;
      final taken = litter
          .where((l) => !l.caught)
          .map((l) => (l.x, l.dropIn < 1 ? l.targetY : l.y));
      if (landingClear(taken, x0, y0)) {
        litter.add(_Litter(
            x0,
            y0,
            spawned % litterEmo.length,
            rand.nextDouble() * 2 * pi,
            0.85 + rand.nextDouble() * 0.3));
        spawned++;
      }
    }
    for (final l in litter) {
      if (l.caught) {
        l.catchAnim = (l.catchAnim + dt * 2.4).clamp(0, 1);
        continue;
      }
      // falling in: it hangs in the air, then splashes down
      if (l.dropIn < 1) {
        l.dropIn = (l.dropIn + dt / 0.5).clamp(0.0, 1.0);
        if (l.dropIn >= 1) {
          l.y = l.targetY;
          l.splash = 0;
          Sfx.play('splash', volume: 0.3);
        }
        continue; // it only starts drifting once it's afloat
      }
      if (l.splash >= 0 && l.splash < 0.7) l.splash += dt;
      // afloat: the current carries it down toward the sea
      l.y += dt * drift * l.speed;
      if (l.y >= 1.05) {
        // the wind lifts it back in somewhere new - the river is
        // patient, and litter never lands on litter
        final nx = 0.08 + rand.nextDouble() * 0.84;
        final ny = 0.08 + rand.nextDouble() * 0.3;
        l.x = nx;
        l.targetY = ny;
        l.y = ny;
        l.dropIn = 0;
        l.splash = -1;
      }
    }
    if (!celebrated && caught >= total) {
      celebrated = true;
      Haptics.settle();
      Sfx.play('chime', volume: 0.7);
      fishJump = 1;
      widget.speak(RiverCopy.done);
    }
    setState(() {});
  }

  void _tapAt(Offset p, Size s) {
    for (final l in litter) {
      if (l.caught || l.dropIn < 1) continue;
      final lp = litterPos(l, s);
      if ((lp - p).distance < 44) {
        l.caught = true;
        l.catchFrom = lp;
        caught++;
        Haptics.tick();
        Sfx.play('pop', volume: 0.55);
        return;
      }
    }
    // maybe they greeted a fish
    for (var f = 0; f < 3; f++) {
      final fp = _fishPos(f, s);
      if ((fp - p).distance < 40) {
        fishJump = 1;
        Haptics.tick();
        Sfx.play('drop', volume: 0.5);
        return;
      }
    }
  }

  Offset _fishPos(int i, Size s) {
    final t = (phase * 0.05 + i * 0.33) % 1;
    return riverPoint(t, s) + Offset(0, 14 + i * 4.0);
  }

  @override
  Widget build(BuildContext context) {
    final done = caught >= total;
    return Scaffold(
      backgroundColor: kidCream,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 8, 4),
            child: Row(children: [
              Expanded(
                  child: Text('🏞 River keeper', style: kidTitle(20))),
              KidLottie(
                  slot: 'fish_bowl',
                  size: 40,
                  fallback: const SizedBox.shrink()),
              IconButton(
                  tooltip: 'Leave the river',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close,
                      color: kidInkLight, size: 20)),
            ]),
          ),
          Text(
              done
                  ? 'the river is clear! 🐟'
                  : caught == 0
                      ? RiverCopy.intro
                      : '🧺 $caught of $total caught',
              textAlign: TextAlign.center,
              style: kidBody(13, color: kidInkLight)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, children: [
            for (var i = 0; i < 4; i++)
              ChoiceChip(
                label: Text(
                    const [
                      '🐣 Gentle',
                      '🦊 Classic',
                      '🦉 Quick',
                      '🌊 Rapids'
                    ][i],
                    style: kidBody(12)),
                selected: level == i,
                selectedColor: kidSky,
                onSelected: (_) => setState(() {
                  level = i;
                  litter.clear();
                  caught = 0;
                  spawned = 0;
                  celebrated = false;
                }),
              ),
          ]),
          const SizedBox(height: 6),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: LayoutBuilder(builder: (context, box) {
                final s = Size(box.maxWidth, box.maxHeight);
                return GestureDetector(
                  onTapDown: (d) => _tapAt(d.localPosition, s),
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                          color: kidInk.withValues(alpha: 0.12),
                          width: 2),
                    ),
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _RiverPainter(this, s),
                    ),
                  ),
                );
              }),
            ),
          ),
          if (done)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(children: [
                KidLottie(
                    slot: 'rain_gentle',
                    size: 54,
                    fallback: const SizedBox.shrink()),
                Text(RiverCopy.done,
                    textAlign: TextAlign.center, style: kidBody(13.5)),
                const SizedBox(height: 6),
                Text(RiverCopy.fact,
                    textAlign: TextAlign.center, style: kidBody(12.5)),
                const SizedBox(height: 10),
                KidSquish(
                  onTap: () => setState(() {
                    litter.clear();
                    caught = 0;
                    spawned = 0;
                    celebrated = false;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                        color: kidSky,
                        borderRadius: BorderRadius.circular(22)),
                    child:
                        Text('🏞 Keep another river', style: kidTitle(14)),
                  ),
                ),
              ]),
            ),
        ]),
      ),
    );
  }
}

class _RiverPainter extends CustomPainter {
  final _RiverKeeperState g;
  final Size box;
  _RiverPainter(this.g, this.box);

  @override
  void paint(Canvas canvas, Size s) {
    ScenePainter(23, ComicScene.river, false).paint(canvas, s);

    // the clearing water: a haze that lifts as litter is caught
    final murk = 1 - clarity(g.caught, g.total);
    if (murk > 0) {
      canvas.drawRect(
          Offset.zero & s,
          Paint()
            ..color =
                const Color(0xFF6B5B4A).withValues(alpha: 0.22 * murk));
    }

    // flowing water lines along the course
    final flow = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 5; i++) {
      final t = ((g.phase * 0.1) + i * 0.2) % 1;
      final p = g.riverPoint(t, s);
      canvas.drawLine(p + const Offset(-8, 0), p + const Offset(8, 0), flow);
    }

    // fish, swimming the course - one jumps when greeted
    for (var f = 0; f < 3; f++) {
      final fp = g._fishPos(f, s);
      final jump = f == 0 ? sin(g.fishJump * pi) * 26 : 0.0;
      _emoji(canvas, '🐟', fp - Offset(0, jump), 20);
      if (jump > 8) _emoji(canvas, '✨', fp - Offset(14, jump + 8), 12);
    }

    // the basket
    final basket = Offset(s.width - 44, 44);
    _emoji(canvas, '🧺', basket, 30);

    // litter: falling in, drifting, or flying to the basket
    for (final l in g.litter) {
      if (l.caught && l.catchAnim >= 1) continue;
      Offset p;
      if (l.caught) {
        final e = Curves.easeInBack.transform(l.catchAnim);
        p = Offset.lerp(l.catchFrom, basket, e)!;
      } else {
        p = g.litterPos(l, s);
        if (l.dropIn < 1) {
          // its shadow waits on the water where it will land
          final home =
              Offset(l.x * s.width, l.targetY * s.height);
          canvas.drawOval(
              Rect.fromCenter(center: home, width: 20, height: 7),
              Paint()
                ..color = Colors.black
                    .withValues(alpha: 0.12 + 0.1 * l.dropIn));
        }
        if (l.splash >= 0 && l.splash < 0.7) {
          final a = (1.0 - l.splash / 0.7).clamp(0.0, 1.0);
          canvas.drawCircle(
              p,
              8.0 + l.splash * 46.0,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.0
                ..color = Colors.white.withValues(alpha: 0.5 * a));
        }
      }
      _emoji(canvas, litterEmo[l.kind], p, l.caught ? 20 : 26);
    }
  }

  void _emoji(Canvas c, String e, Offset at, double size) {
    if (size <= 0) return;
    final tp = TextPainter(
        text: TextSpan(text: e, style: TextStyle(fontSize: size)),
        textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(c, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_RiverPainter old) => true;
}
