// Owl Glide - dusk flight on silent wings. The child's finger is the
// air: drag up and down and the owl rides to that height, gathering
// drifting moth-lights that become a sparkling tail behind her (never
// a number - the tail IS the treasure). The sky itself is the journey:
// night fades to dawn as she flies, stars dim one by one, and the run
// ends at the nest in first light. Moths that drift past just drift
// past; nothing is missed, because a night sky always has more. The
// true thing: owl feathers have soft fringed edges - her flight makes
// almost no sound at all.

import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../core/haptics.dart';
import '../../../core/kid_theme.dart';

// ---------- pure logic (tested) ----------

/// Moths along the run: (x, height 0.15..0.72) - deterministic,
/// spaced so the owl can always reach the next one.
List<(double, double)> mothSpots(int count, int seed) {
  final r = Random(seed);
  final out = <(double, double)>[];
  var x = 420.0;
  for (var i = 0; i < count; i++) {
    out.add((x, 0.15 + r.nextDouble() * 0.57));
    x += 200.0 + r.nextDouble() * 160.0;
  }
  return out;
}

/// The sky at journey progress p (0 night .. 1 dawn).
Color skyAt(double p) => Color.lerp(
      const Color(0xFF141C36),
      const Color(0xFFFFE9D6),
      Curves.easeIn.transform(p.clamp(0.0, 1.0)),
    )!;

class OwlCopy {
  static const intro = 'Your finger is the air - glide her through the '
      'night and gather the moth-lights.';
  static const done =
      'Dawn, and the nest. Owl feathers have soft, fringed edges - '
      'her whole flight made almost no sound at all.';
}

// ---------- the game ----------

class OwlGlideGame extends FlameGame {
  OwlGlideGame({required this.onDone, required this.slow});
  final VoidCallback onDone;
  final bool slow;

  static const runLength = 3200.0;
  double scroll = 0;
  double aimY = 0.4; // where the finger asks her to be (0..1)
  bool finished = false;
  final caughtIdx = <int>{};
  late final List<(double, double)> moths = mothSpots(11, 12);
  final sparks = <_Spark>[];
  double time = 0;

  double get progress => (scroll / runLength).clamp(0.0, 1.0);

  @override
  Color backgroundColor() => const Color(0xFF141C36);

  @override
  Future<void> onLoad() async {
    add(_NightSky());
    add(_Owl());
  }

  void aim(double normalizedY) {
    aimY = normalizedY.clamp(0.08, 0.85);
  }

  @override
  void update(double dt) {
    super.update(dt);
    time += dt;
    if (finished) return;
    scroll += (slow ? 60.0 : 100.0) * dt;
    for (final s in sparks) {
      s.age += dt;
    }
    sparks.removeWhere((s) => s.age > 0.8);
    if (scroll >= runLength) {
      finished = true;
      onDone();
    }
  }
}

class _Owl extends PositionComponent with HasGameReference<OwlGlideGame> {
  double wing = 0;

  @override
  Future<void> onLoad() async {
    anchor = Anchor.center;
    size = Vector2(70.0, 50.0);
  }

  @override
  void update(double dt) {
    super.update(dt);
    wing += dt * 3.0;
    final targetY = game.aimY * game.size.y;
    position.x = game.size.x * 0.3;
    position.y = position.y + (targetY - position.y) * (dt * 4.0).clamp(0.0, 1.0);
    // gather any moth-light she reaches
    for (var i = 0; i < game.moths.length; i++) {
      if (game.caughtIdx.contains(i)) continue;
      final (mx, myf) = game.moths[i];
      final sx = mx - game.scroll;
      final my = myf * game.size.y +
          sin(game.time * 2.0 + i) * 14.0;
      if ((Offset(sx, my) - Offset(position.x, position.y)).distance <
          46.0) {
        game.caughtIdx.add(i);
        Haptics.tick();
        for (var k = 0; k < 6; k++) {
          game.sparks.add(_Spark(position.x, position.y));
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    final flap = sin(wing) * 0.35;
    // wings: two soft arcs, nearly silent
    final wingPaint = Paint()..color = const Color(0xFF8A6A4C);
    canvas.save();
    canvas.rotate(-0.25 - flap);
    canvas.drawOval(
        Rect.fromCenter(
            center: const Offset(-8, -14), width: 52, height: 18),
        wingPaint);
    canvas.restore();
    canvas.save();
    canvas.rotate(0.1 + flap * 0.5);
    canvas.drawOval(
        Rect.fromCenter(
            center: const Offset(-8, 10), width: 46, height: 16),
        wingPaint);
    canvas.restore();
    // body
    canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 44, height: 34),
        Paint()..color = const Color(0xFFA98866));
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(4, 4), width: 28, height: 20),
        Paint()..color = const Color(0xFFE8DCC8));
    // face disc + eyes
    canvas.drawCircle(const Offset(16, -6), 11,
        Paint()..color = const Color(0xFFE8DCC8));
    canvas.drawCircle(const Offset(13, -7), 3.2,
        Paint()..color = const Color(0xFF463A45));
    canvas.drawCircle(const Offset(20, -7), 3.2,
        Paint()..color = const Color(0xFF463A45));
    canvas.restore();
  }
}

/// Everything that isn't the owl: the turning sky, dimming stars,
/// drifting moth-lights, the sparkling tail, treetops, and at last
/// the nest in first light.
class _NightSky extends Component with HasGameReference<OwlGlideGame> {
  final starSeed = Random(4);

  @override
  void render(Canvas canvas) {
    final s = game.size;
    final p = game.progress;
    // the sky is the progress bar
    canvas.drawRect(Rect.fromLTWH(0, 0, s.x, s.y),
        Paint()..color = skyAt(p));
    // stars dim as dawn rises
    final r = Random(4);
    final starAlpha = ((1.0 - p * 1.4).clamp(0.0, 1.0)) * 0.8;
    if (starAlpha > 0) {
      for (var i = 0; i < 34; i++) {
        canvas.drawCircle(
            Offset(s.x * r.nextDouble(), s.y * r.nextDouble() * 0.7),
            0.9 + r.nextDouble(),
            Paint()
              ..color = Colors.white.withValues(alpha: starAlpha));
      }
    }
    // the moon sets as she flies
    canvas.drawCircle(
        Offset(s.x * 0.82, s.y * (0.16 + p * 0.5)),
        26,
        Paint()
          ..color = const Color(0xFFF6EFC1)
              .withValues(alpha: (1.0 - p).clamp(0.0, 1.0)));
    // treetops scrolling below
    final tree = Paint()..color = const Color(0xFF0C1226);
    for (var i = 0; i < 16; i++) {
      final tx = (i * 220.0 - game.scroll * 0.8) % (s.x + 300.0) - 150.0;
      canvas.drawPath(
          Path()
            ..moveTo(tx, s.y)
            ..lineTo(tx + 40, s.y * 0.86)
            ..lineTo(tx + 80, s.y)
            ..close(),
          tree);
    }
    // moth-lights, drifting and breathing
    for (var i = 0; i < game.moths.length; i++) {
      if (game.caughtIdx.contains(i)) continue;
      final (mx, myf) = game.moths[i];
      final sx = mx - game.scroll;
      if (sx < -60 || sx > s.x + 60) continue;
      final my = myf * s.y + sin(game.time * 2.0 + i) * 14.0;
      final pulse = 0.6 + 0.4 * sin(game.time * 3.0 + i * 2.0);
      canvas.drawCircle(
          Offset(sx, my),
          9.0 * pulse,
          Paint()
            ..color =
                const Color(0xFFFFF3A6).withValues(alpha: 0.3 * pulse)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      canvas.drawCircle(Offset(sx, my), 3.0,
          Paint()..color = const Color(0xFFFFF7C8));
    }
    // the gathered lights ride behind her as a tail
    final owlX = s.x * 0.3;
    final owlY = game.aimY * s.y;
    for (var i = 0; i < game.caughtIdx.length; i++) {
      final t = game.time * 2.0 + i * 0.9;
      canvas.drawCircle(
          Offset(owlX - 46.0 - i * 16.0,
              owlY + sin(t) * 10.0),
          3.4,
          Paint()
            ..color = const Color(0xFFFFF3A6).withValues(alpha: 0.85)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    }
    // catch sparks
    for (final sp in game.sparks) {
      final a = (1.0 - sp.age / 0.8).clamp(0.0, 1.0);
      canvas.drawCircle(
          Offset(sp.x + sp.dx * sp.age * 70.0,
              sp.y + sp.dy * sp.age * 70.0),
          2.6 * a,
          Paint()
            ..color = const Color(0xFFFFF3A6).withValues(alpha: a));
    }
    // the nest arrives with the dawn
    final nestX = OwlGlideGame.runLength - game.scroll + s.x * 0.75;
    if (nestX < s.x + 200.0) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(nestX, s.y * 0.4),
              width: 110,
              height: 54),
          Paint()..color = const Color(0xFF8A6A4C));
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(nestX, s.y * 0.37),
              width: 80,
              height: 30),
          Paint()..color = const Color(0xFF5E4632));
    }
  }
}

class _Spark {
  final double x, y;
  final double dx = Random().nextDouble() * 2.0 - 1.0;
  final double dy = Random().nextDouble() * 2.0 - 1.0;
  double age = 0;
  _Spark(this.x, this.y);
}

// ---------- the screen ----------

class OwlGlide extends StatefulWidget {
  final void Function(String) speak;
  const OwlGlide({super.key, required this.speak});

  @override
  State<OwlGlide> createState() => _OwlGlideState();
}

class _OwlGlideState extends State<OwlGlide> {
  OwlGlideGame? game;
  bool done = false;

  @override
  Widget build(BuildContext context) {
    game ??= OwlGlideGame(
        slow: MediaQuery.of(context).disableAnimations,
        onDone: () {
          if (mounted) {
            setState(() => done = true);
            widget.speak(OwlCopy.done);
            Haptics.settle();
          }
        });
    return Scaffold(
      backgroundColor: kidCream,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 8, 4),
            child: Row(children: [
              Expanded(child: Text('🦉 Owl glide', style: kidTitle(20))),
              IconButton(
                  tooltip: 'Leave the night',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close,
                      color: kidInkLight, size: 20)),
            ]),
          ),
          Text(done ? 'home at dawn 🌅' : OwlCopy.intro,
              textAlign: TextAlign.center,
              style: kidBody(13, color: kidInkLight)),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: LayoutBuilder(builder: (context, box) {
                return GestureDetector(
                  onPanStart: (d) => game!
                      .aim(d.localPosition.dy / box.maxHeight),
                  onPanUpdate: (d) => game!
                      .aim(d.localPosition.dy / box.maxHeight),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Stack(fit: StackFit.expand, children: [
                      GameWidget(game: game!),
                      if (done)
                        Container(
                          color: const Color(0x66103A55),
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('🦉🪺',
                                        style:
                                            TextStyle(fontSize: 44)),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding:
                                          const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                          color: Colors.white
                                              .withValues(alpha: 0.95),
                                          borderRadius:
                                              BorderRadius.circular(
                                                  18)),
                                      child: Text(OwlCopy.done,
                                          textAlign: TextAlign.center,
                                          style: kidBody(13.5)),
                                    ),
                                    const SizedBox(height: 12),
                                    KidSquish(
                                      onTap: () => setState(() {
                                        game = null;
                                        done = false;
                                      }),
                                      child: Container(
                                        padding: const EdgeInsets
                                            .symmetric(
                                            horizontal: 24,
                                            vertical: 12),
                                        decoration: BoxDecoration(
                                            color: kidSun,
                                            borderRadius:
                                                BorderRadius.circular(
                                                    22)),
                                        child: Text('🌙 Fly again',
                                            style: kidTitle(14)),
                                      ),
                                    ),
                                  ]),
                            ),
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
