// The Wind Garden - the child IS the wind. Drag anywhere and a breeze
// crosses the meadow; the bee rides it. Steer her gently toward the
// sleeping buds and each visit blooms a flower open, petal by petal,
// until the whole meadow stands in blossom. There is no way to lose:
// wind that misses is just wind, and the bee never tires. The lesson
// hides inside the play - flowers need their visitors, and even the
// wind is part of the garden.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/haptics.dart';
import '../../../core/kid_theme.dart';
import '../../../core/theme.dart' show Motion;
import '../comic.dart' show ScenePainter, ComicScene;

// ---------- pure logic (tested) ----------

/// Flower spots for a garden: deterministic, spread, never at the edge.
List<Offset> gardenSpots(int count, int seed) {
  final r = Random(seed);
  final out = <Offset>[];
  for (var i = 0; i < count; i++) {
    out.add(Offset(
      0.12 + (i / (count - 1)) * 0.76 + (r.nextDouble() - 0.5) * 0.08,
      0.55 + r.nextDouble() * 0.32,
    ));
  }
  return out;
}

class GardenCopy {
  static const intro = 'Drag to make wind. Help the bee visit every bud.';
  static const done =
      'You were the wind. The bee did the rest. That is how meadows '
      'happen - one visit at a time.';
  static const fact =
      '🌿 One bee can visit hundreds of flowers in a single trip.';
}

// ---------- the game ----------

class WindGarden extends StatefulWidget {
  final void Function(String) speak;
  const WindGarden({super.key, required this.speak});

  @override
  State<WindGarden> createState() => _WindGardenState();
}

class _WindGardenState extends State<WindGarden>
    with SingleTickerProviderStateMixin {
  static const flowerCount = 6;
  late final List<Offset> spots = gardenSpots(flowerCount, 11);
  final bloom = List<double>.filled(flowerCount, 0); // 0 bud -> 1 open
  Offset bee = const Offset(0.5, 0.3);
  Offset beeVel = Offset.zero;
  Offset wind = Offset.zero;
  double wingPhase = 0;
  final petals = <List<double>>[]; // x,y,vx,vy,life
  bool celebrated = false;
  Ticker? ticker;
  Duration last = Duration.zero;

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

  void _tick(Duration now) {
    final dt =
        ((now - last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    last = now;
    if (dt == 0) return;
    final still = Motion.still(context);
    wingPhase += dt * 24;

    // the bee: wind pushes, a tiny will of her own, walls are soft
    final drift = Offset(sin(wingPhase * 0.13), cos(wingPhase * 0.11)) *
        (still ? 0.0 : 0.012);
    beeVel = (beeVel + wind * dt * 2.2 + drift * dt) * 0.985;
    // gentle pull toward the nearest sleeping bud when close
    final target = _nearestBud();
    if (target != null) {
      final d = target - bee;
      if (d.distance < 0.22) {
        beeVel += d / d.distance * 0.02 * dt * 60;
      }
      if (d.distance < 0.055) {
        final i = spots.indexOf(target);
        final before = bloom[i];
        bloom[i] = (bloom[i] + dt * 0.9).clamp(0.0, 1.0);
        if (before < 1 && bloom[i] >= 1) {
          Haptics.tick();
          _burst(target);
        }
      }
    }
    bee += beeVel * dt;
    bee = Offset(bee.dx.clamp(0.04, 0.96), bee.dy.clamp(0.06, 0.94));
    if (bee.dx <= 0.04 || bee.dx >= 0.96) beeVel = Offset(-beeVel.dx * 0.5, beeVel.dy);
    if (bee.dy <= 0.06 || bee.dy >= 0.94) beeVel = Offset(beeVel.dx, -beeVel.dy * 0.5);
    wind *= 0.94; // breezes fade

    // petals drift on the same wind
    for (final p in petals) {
      p[0] += (p[2] + wind.dx * 0.3) * dt;
      p[1] += (p[3] + wind.dy * 0.3) * dt;
      p[4] -= dt;
    }
    petals.removeWhere((p) => p[4] <= 0);

    if (!celebrated && bloom.every((b) => b >= 1)) {
      celebrated = true;
      Haptics.settle();
      widget.speak(GardenCopy.done);
      for (final s in spots) {
        _burst(s);
      }
    }
    setState(() {});
  }

  Offset? _nearestBud() {
    Offset? best;
    var bestD = double.infinity;
    for (var i = 0; i < spots.length; i++) {
      if (bloom[i] >= 1) continue;
      final d = (spots[i] - bee).distance;
      if (d < bestD) {
        bestD = d;
        best = spots[i];
      }
    }
    return best;
  }

  void _burst(Offset at) {
    final r = Random();
    for (var i = 0; i < 8; i++) {
      petals.add([
        at.dx,
        at.dy,
        (r.nextDouble() - 0.5) * 0.12,
        -r.nextDouble() * 0.1 - 0.02,
        1.2 + r.nextDouble()
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = bloom.every((b) => b >= 1);
    return Scaffold(
      backgroundColor: kidCream,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 8, 4),
            child: Row(children: [
              Expanded(
                  child: Text('🌬 The wind garden', style: kidTitle(20))),
              IconButton(
                  tooltip: 'Leave the garden',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close,
                      color: kidInkLight, size: 20)),
            ]),
          ),
          Text(
              done
                  ? 'every flower open 🌼'
                  : bloom.every((b) => b == 0)
                      ? GardenCopy.intro
                      : '${bloom.where((b) => b >= 1).length} of $flowerCount '
                          'flowers awake',
              style: kidBody(13, color: kidInkLight)),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: LayoutBuilder(builder: (context, box) {
                return GestureDetector(
                  onPanUpdate: (d) {
                    wind += Offset(d.delta.dx / box.maxWidth,
                            d.delta.dy / box.maxHeight) *
                        3.5;
                  },
                  onTapDown: Motion.still(context)
                      ? (d) {
                          // reduced motion: the bee steps to your tap
                          bee = Offset(
                              d.localPosition.dx / box.maxWidth,
                              d.localPosition.dy / box.maxHeight);
                        }
                      : null,
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
                      painter: _GardenPainter(
                          spots, bloom, bee, wingPhase, petals),
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
                Text(GardenCopy.done,
                    textAlign: TextAlign.center,
                    style: kidBody(13.5)),
                const SizedBox(height: 6),
                Text(GardenCopy.fact,
                    textAlign: TextAlign.center, style: kidBody(12.5)),
                const SizedBox(height: 10),
                KidSquish(
                  onTap: () => setState(() {
                    for (var i = 0; i < bloom.length; i++) {
                      bloom[i] = 0;
                    }
                    celebrated = false;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                        color: kidLeaf,
                        borderRadius: BorderRadius.circular(22)),
                    child: Text('🌱 Plant a new garden',
                        style: kidTitle(14)),
                  ),
                ),
              ]),
            ),
        ]),
      ),
    );
  }
}

class _GardenPainter extends CustomPainter {
  final List<Offset> spots;
  final List<double> bloom;
  final Offset bee;
  final double wingPhase;
  final List<List<double>> petals;
  _GardenPainter(
      this.spots, this.bloom, this.bee, this.wingPhase, this.petals);

  @override
  void paint(Canvas canvas, Size s) {
    ScenePainter(11, ComicScene.meadow, false).paint(canvas, s);

    // flowers: stem, then bud closed or petals opening by progress
    for (var i = 0; i < spots.length; i++) {
      final o = Offset(spots[i].dx * s.width, spots[i].dy * s.height);
      final b = bloom[i];
      canvas.drawLine(
          o,
          o + const Offset(0, 26),
          Paint()
            ..color = const Color(0xFF4F8B3B)
            ..strokeWidth = 3.5
            ..strokeCap = StrokeCap.round);
      if (b <= 0) {
        canvas.drawCircle(o, 7,
            Paint()..color = const Color(0xFF8FBF6E));
      } else {
        final petalsN = 6;
        final open = Curves.easeOutBack.transform(b);
        for (var p = 0; p < petalsN; p++) {
          final a = p * 2 * pi / petalsN + wingPhase * 0.005;
          canvas.drawCircle(
              o + Offset(cos(a), sin(a)) * 9 * open,
              6.5 * open,
              Paint()
                ..color = [
                  const Color(0xFFFFB3C7),
                  const Color(0xFFFFE08A),
                  const Color(0xFFC7A9F2)
                ][i % 3]);
        }
        canvas.drawCircle(
            o, 5, Paint()..color = const Color(0xFFF2B01E));
      }
    }

    // drifting petals
    for (final p in petals) {
      canvas.drawCircle(
          Offset(p[0] * s.width, p[1] * s.height),
          3.5,
          Paint()
            ..color = const Color(0xFFFFB3C7)
                .withValues(alpha: p[4].clamp(0, 1) * 0.9));
    }

    // the bee: body, stripes, blurring wings
    final bo = Offset(bee.dx * s.width, bee.dy * s.height);
    final wing = sin(wingPhase) * 5;
    canvas.drawOval(
        Rect.fromCenter(
            center: bo + Offset(-3, -7 + wing * 0.4),
            width: 10,
            height: 6),
        Paint()..color = Colors.white.withValues(alpha: 0.8));
    canvas.drawOval(
        Rect.fromCenter(
            center: bo + Offset(4, -7 - wing * 0.4),
            width: 10,
            height: 6),
        Paint()..color = Colors.white.withValues(alpha: 0.8));
    canvas.drawOval(
        Rect.fromCenter(center: bo, width: 16, height: 12),
        Paint()..color = const Color(0xFFF2B01E));
    canvas.drawLine(bo + const Offset(-3, -6), bo + const Offset(-3, 6),
        Paint()..color = const Color(0xFF463A45)..strokeWidth = 3);
    canvas.drawLine(bo + const Offset(3, -6), bo + const Offset(3, 6),
        Paint()..color = const Color(0xFF463A45)..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(_GardenPainter old) => true;
}
