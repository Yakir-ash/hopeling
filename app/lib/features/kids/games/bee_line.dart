// Bee Line - steer a bee through a streaming meadow with your finger,
// and every flower she flies through blooms open behind her. When she
// has gathered enough nectar the hive appears and she flies home to
// perform the real ending: the WAGGLE DANCE, a figure-eight traced in
// golden light - because that is truly how bees tell the hive where
// the flowers are. Flowers she misses simply stream past; the meadow
// never runs out. Gentle gusts of wind lean on her now and then, told
// by streaks in the air - part of flying, never a punishment.

import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../core/haptics.dart';
import '../../../core/kid_theme.dart';

// ---------- pure logic (tested) ----------

/// Flowers along the run: (lane 0.12..0.88, distance, palette index) -
/// deterministic, always reachable from any lane.
List<(double, double, int)> flowerField(int count, int seed) {
  final r = Random(seed);
  final out = <(double, double, int)>[];
  var d = 300.0;
  for (var i = 0; i < count; i++) {
    out.add((0.12 + r.nextDouble() * 0.76, d, i % 4));
    d += 150.0 + r.nextDouble() * 130.0;
  }
  return out;
}

/// Blooms needed before the hive calls her home.
const nectarGoal = 8;

class BeeCopy {
  static const intro =
      'Steer with your finger - fly through the flowers and fill up '
      'on nectar.';
  static const dance =
      'The waggle dance! A bee dances a figure-eight to tell her '
      'hive exactly where the flowers are.';
}

// ---------- the game ----------

class BeeLineGame extends FlameGame {
  BeeLineGame({required this.onDance, required this.slow});
  final VoidCallback onDance;
  final bool slow;

  double scroll = 0;
  double aimX = 0.5;
  double time = 0;
  bool dancing = false;
  double danceT = 0;
  final bloomed = <int>{};
  late final List<(double, double, int)> flowers = flowerField(40, 21);
  final sparks = <_Nectar>[];

  @override
  Color backgroundColor() => const Color(0xFFDCEFC9);

  @override
  Future<void> onLoad() async {
    add(_Meadow());
    add(_Bee());
  }

  void aim(double normalizedX) {
    aimX = normalizedX.clamp(0.08, 0.92);
  }

  double gust() => sin(time * 0.35) * 16.0; // the wind leans, gently

  @override
  void update(double dt) {
    super.update(dt);
    time += dt;
    for (final s in sparks) {
      s.age += dt;
    }
    sparks.removeWhere((s) => s.age > 0.8);
    if (dancing) {
      danceT += dt;
      return;
    }
    scroll += (slow ? 70.0 : 120.0) * dt;
    if (bloomed.length >= nectarGoal) {
      dancing = true;
      danceT = 0;
      Haptics.settle();
      onDance();
    }
  }
}

class _Bee extends PositionComponent with HasGameReference<BeeLineGame> {
  double wingPhase = 0;

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    size = Vector2(46.0, 40.0);
  }

  @override
  void update(double dt) {
    super.update(dt);
    wingPhase += dt * 26.0;
    if (game.dancing) {
      // the waggle: a figure-eight in the middle of the meadow
      final t = game.danceT * 1.6;
      position.x = game.size.x * 0.5 + sin(t) * 70.0;
      position.y = game.size.y * 0.45 + sin(t * 2.0) * 42.0;
      return;
    }
    final targetX = game.aimX * game.size.x + game.gust();
    position.x =
        position.x + (targetX - position.x) * (dt * 5.0).clamp(0.0, 1.0);
    position.y = game.size.y * 0.72;
    // bloom every flower she reaches
    for (var i = 0; i < game.flowers.length; i++) {
      if (game.bloomed.contains(i)) continue;
      final (lane, dist, _) = game.flowers[i];
      final fx = lane * game.size.x;
      final fy = game.size.y - (dist - game.scroll);
      if ((Offset(fx, fy) - Offset(position.x, position.y)).distance <
          42.0) {
        game.bloomed.add(i);
        Haptics.tick();
        for (var k = 0; k < 6; k++) {
          game.sparks.add(_Nectar(fx, fy));
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    final flap = sin(wingPhase) * 4.0;
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(-8, -10 + flap * 0.5), width: 20, height: 12),
        Paint()..color = Colors.white.withValues(alpha: 0.85));
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(8, -10 - flap * 0.5), width: 20, height: 12),
        Paint()..color = Colors.white.withValues(alpha: 0.85));
    canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 30, height: 22),
        Paint()..color = const Color(0xFFF2B01E));
    final stripe = Paint()
      ..color = const Color(0xFF463A45)
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-6, -10), const Offset(-6, 10), stripe);
    canvas.drawLine(const Offset(4, -10), const Offset(4, 10), stripe);
    canvas.drawCircle(const Offset(12, -4), 2.6,
        Paint()..color = const Color(0xFF463A45));
    canvas.restore();
  }
}

/// The streaming meadow: grass bands, flowers that bloom behind her,
/// wind streaks when the gust leans, nectar sparkles, and the honey
/// glow that fills as she gathers.
class _Meadow extends Component with HasGameReference<BeeLineGame> {
  static const petals = [
    Color(0xFFFFB3C7),
    Color(0xFFFFE08A),
    Color(0xFFC7A9F2),
    Color(0xFFFF9E80),
  ];

  @override
  void render(Canvas canvas) {
    final s = game.size;
    // grass bands drifting down
    for (var i = 0; i < 7; i++) {
      final by = (i * 160.0 + game.scroll) % (s.y + 160.0) - 80.0;
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(s.x * 0.5, by),
              width: s.x * 1.4,
              height: 60),
          Paint()
            ..color = const Color(0xFFB9DCA4).withValues(alpha: 0.35));
    }
    // wind streaks when the gust leans hard
    final g = game.gust();
    if (g.abs() > 10.0) {
      final streak = Paint()
        ..color = Colors.white.withValues(alpha: 0.4)
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 5; i++) {
        final wy = s.y * (0.15 + i * 0.16);
        final wx = (game.time * 90.0 + i * 120.0) % (s.x + 60.0) - 30.0;
        canvas.drawLine(Offset(wx, wy),
            Offset(wx + g.sign * 30.0, wy + 4.0), streak);
      }
    }
    // flowers: buds ahead, blooms behind
    for (var i = 0; i < game.flowers.length; i++) {
      final (lane, dist, c) = game.flowers[i];
      final fy = s.y - (dist - game.scroll);
      if (fy < -60.0 || fy > s.y + 60.0) continue;
      final fx = lane * s.x;
      final isBloomed = game.bloomed.contains(i);
      canvas.drawLine(
          Offset(fx, fy),
          Offset(fx, fy + 22.0),
          Paint()
            ..color = const Color(0xFF4F8B3B)
            ..strokeWidth = 3.5
            ..strokeCap = StrokeCap.round);
      if (isBloomed) {
        for (var p = 0; p < 6; p++) {
          final a = p * pi / 3.0 + game.time * 0.4;
          canvas.drawCircle(Offset(fx + cos(a) * 9.0, fy + sin(a) * 9.0),
              6.0, Paint()..color = petals[c]);
        }
        canvas.drawCircle(
            Offset(fx, fy), 5.0, Paint()..color = const Color(0xFFF2B01E));
      } else {
        canvas.drawCircle(Offset(fx, fy), 7.0,
            Paint()..color = const Color(0xFF8FBF6E));
      }
    }
    // nectar sparkles
    for (final sp in game.sparks) {
      final a = (1.0 - sp.age / 0.8).clamp(0.0, 1.0);
      canvas.drawCircle(
          Offset(sp.x + sp.dx * sp.age * 60.0,
              sp.y - 30.0 * sp.age),
          2.6 * a,
          Paint()..color = const Color(0xFFF2B01E).withValues(alpha: a));
    }
    // the honey glow: her gathering, told as light - never a number
    final fill = (game.bloomed.length / nectarGoal).clamp(0.0, 1.0);
    canvas.drawCircle(
        Offset(s.x - 34.0, 34.0),
        16.0 + 6.0 * fill,
        Paint()
          ..color =
              const Color(0xFFF2B01E).withValues(alpha: 0.25 + 0.5 * fill)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawCircle(Offset(s.x - 34.0, 34.0), 10.0,
        Paint()..color = const Color(0xFFF2B01E).withValues(alpha: 0.9));
    // the waggle dance: her path written in golden light
    if (game.dancing) {
      final trail = Paint()
        ..color = const Color(0xFFF2B01E).withValues(alpha: 0.7)
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      final path = Path();
      var first = true;
      for (var t = 0.0; t < game.danceT * 1.6; t += 0.05) {
        final px = s.x * 0.5 + sin(t) * 70.0;
        final py = s.y * 0.45 + sin(t * 2.0) * 42.0;
        if (first) {
          path.moveTo(px, py);
          first = false;
        } else {
          path.lineTo(px, py);
        }
      }
      canvas.drawPath(path, trail);
    }
  }
}

class _Nectar {
  final double x, y;
  final double dx = Random().nextDouble() * 2.0 - 1.0;
  double age = 0;
  _Nectar(this.x, this.y);
}

// ---------- the screen ----------

class BeeLine extends StatefulWidget {
  final void Function(String) speak;
  const BeeLine({super.key, required this.speak});

  @override
  State<BeeLine> createState() => _BeeLineState();
}

class _BeeLineState extends State<BeeLine> {
  BeeLineGame? game;
  bool dancing = false;

  @override
  Widget build(BuildContext context) {
    game ??= BeeLineGame(
        slow: MediaQuery.of(context).disableAnimations,
        onDance: () {
          if (mounted) {
            setState(() => dancing = true);
            widget.speak(BeeCopy.dance);
          }
        });
    return Scaffold(
      backgroundColor: kidCream,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 8, 4),
            child: Row(children: [
              Expanded(child: Text('🐝 Bee line', style: kidTitle(20))),
              IconButton(
                  tooltip: 'Leave the meadow',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close,
                      color: kidInkLight, size: 20)),
            ]),
          ),
          Text(dancing ? 'the waggle dance! 💛' : BeeCopy.intro,
              textAlign: TextAlign.center,
              style: kidBody(13, color: kidInkLight)),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: LayoutBuilder(builder: (context, box) {
                return GestureDetector(
                  onPanStart: (d) =>
                      game!.aim(d.localPosition.dx / box.maxWidth),
                  onPanUpdate: (d) =>
                      game!.aim(d.localPosition.dx / box.maxWidth),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Stack(fit: StackFit.expand, children: [
                      GameWidget(game: game!),
                      if (dancing)
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
                                    child: Text(BeeCopy.dance,
                                        textAlign: TextAlign.center,
                                        style: kidBody(13)),
                                  ),
                                  const SizedBox(height: 10),
                                  KidSquish(
                                    onTap: () => setState(() {
                                      game = null;
                                      dancing = false;
                                    }),
                                    child: Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 22,
                                              vertical: 11),
                                      decoration: BoxDecoration(
                                          color: kidSun,
                                          borderRadius:
                                              BorderRadius.circular(
                                                  20)),
                                      child: Text('🌼 Fly again',
                                          style: kidTitle(13.5)),
                                    ),
                                  ),
                                ]),
                          ),
                        ),
                    ]),
                  ),
                );
              }),
            ),
          ),
        ]),
      ),
    );
  }
}
