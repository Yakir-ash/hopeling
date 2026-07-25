// Salmon Run - the first true Flame game: tap (or hold) to leap a
// young salmon upstream against the current, over rocks and up small
// waterfalls, all the way to the calm spawning pool where she was
// born. Real game feel - gravity, momentum, splash particles - with
// the Hopeling constitution intact: bumping a rock never ends the run,
// it just costs momentum; the current never wins, only slows; and the
// ending is the true story, because real salmon remember the smell of
// their home stream. No score. The pool is the point.

import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../core/haptics.dart';
import '../../../core/kid_theme.dart';

// ---------- pure logic (tested) ----------

/// Rocks along the run: (x, height) - deterministic per seed, spaced
/// so a leap between any two is always possible, and no two neighbors
/// share a height, so every rock asks a different jump.
List<(double, double)> rockSpots(
  int count,
  int seed, {
  double spaceMin = 260.0,
  double spaceVar = 200.0,
  double hMin = 0.6,
  double hVar = 0.9,
}) {
  final r = Random(seed);
  final out = <(double, double)>[];
  final mid = hMin + hVar / 2.0;
  var x = 500.0;
  var lastH = 0.0;
  for (var i = 0; i < count; i++) {
    var h = hMin + r.nextDouble() * hVar;
    if ((h - lastH).abs() < 0.25) {
      // push away from the neighbor, downhill if it stood tall
      h = lastH > mid ? lastH - 0.45 : lastH + 0.45;
    }
    out.add((x, h));
    lastH = h;
    x += spaceMin + r.nextDouble() * spaceVar; // never closer than a leap
  }
  return out;
}

/// The three rivers home. The current pushes her back the moment her
/// momentum fades - upstream must be earned, leap by leap.
class SalmonLevel {
  final String name;
  final String emoji;
  final double run;
  final int rocks;
  final int seed;
  final double current; // px/s pushing her downstream
  final double spaceMin, spaceVar, hMin, hVar;
  const SalmonLevel({
    required this.name,
    required this.emoji,
    required this.run,
    required this.rocks,
    required this.seed,
    required this.current,
    required this.spaceMin,
    required this.spaceVar,
    required this.hMin,
    required this.hVar,
  });

  static const levels = [
    SalmonLevel(
        name: 'Spring stream',
        emoji: '🐟',
        run: 3600.0,
        rocks: 9,
        seed: 5,
        current: 25.0,
        spaceMin: 260.0,
        spaceVar: 200.0,
        hMin: 0.6,
        hVar: 0.9),
    SalmonLevel(
        name: 'Strong river',
        emoji: '🐠',
        run: 4600.0,
        rocks: 14,
        seed: 11,
        current: 50.0,
        spaceMin: 250.0,
        spaceVar: 180.0,
        hMin: 0.6,
        hVar: 1.0),
    SalmonLevel(
        name: 'Great falls',
        emoji: '🌊',
        run: 5600.0,
        rocks: 19,
        seed: 17,
        current: 70.0,
        spaceMin: 240.0,
        spaceVar: 170.0,
        hMin: 0.7,
        hVar: 1.0),
  ];
}

class SalmonCopy {
  static const intro = 'Tap to leap! She can only push off from the '
      'water - time each jump.';
  static const bump = 'Rocks slow a salmon - they never stop one.';
  static const done =
      'She made it - the calm pool where she hatched. Real salmon '
      'remember the smell of their home stream and swim hundreds of '
      'kilometers back to it.';
}

// ---------- the game ----------

class SalmonRunGame extends FlameGame with TapCallbacks {
  SalmonRunGame(
      {required this.level, required this.onDone, required this.slow});
  final SalmonLevel level;
  final VoidCallback onDone;
  final bool slow; // reduced-motion players get a calmer river

  double scroll = 0;
  bool finished = false;
  late final _Salmon salmon;
  late final List<(double, double)> rocks = rockSpots(
      level.rocks, level.seed,
      spaceMin: level.spaceMin,
      spaceVar: level.spaceVar,
      hMin: level.hMin,
      hVar: level.hVar);
  final splashes = <_Splash>[];

  @override
  Color backgroundColor() => const Color(0xFF7CC7F2);

  @override
  Future<void> onLoad() async {
    salmon = _Salmon();
    add(_River());
    add(salmon);
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (finished) return;
    // a salmon pushes off water, never air: taps mid-flight do
    // nothing. Climb in the water, then time the leap.
    if (!salmon.inWater) return;
    salmon.leap();
    Haptics.tick();
    for (var i = 0; i < 5; i++) {
      splashes.add(_Splash(salmon.position.clone()));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (finished) return;
    // upstream is earned: momentum carries her forward, the current
    // pushes her back the moment it fades. Never below the start.
    final current = slow ? level.current * 0.5 : level.current;
    final speed = salmon.momentum * (slow ? 150.0 : 180.0) - current;
    scroll = (scroll + speed * dt).clamp(0.0, double.infinity);
    for (final s in splashes) {
      s.age += dt;
    }
    splashes.removeWhere((s) => s.age > 0.7);
    // rocks: a bump costs momentum, never the run - and taller rocks
    // ask for higher leaps
    for (final (rx, rh) in rocks) {
      final sx = rx - scroll;
      final rockTop = size.y * 0.86 - 70 * rh;
      if ((sx - salmon.position.x).abs() < 34 &&
          salmon.position.y > rockTop &&
          !salmon.bumped) {
        salmon.bump();
        Haptics.settle();
      }
    }
    if (scroll >= level.run && !finished) {
      finished = true;
      onDone();
    }
  }
}

class _Salmon extends PositionComponent
    with HasGameReference<SalmonRunGame> {
  double vy = 0;

  /// She can only push off from the water, never from the air.
  bool get inWater => position.y > game.size.y * 0.55;
  double momentum = 0; // builds with leaps, fades with bumps
  bool bumped = false;
  double bumpTimer = 0;
  double tailPhase = 0;

  @override
  Future<void> onLoad() async {
    position = Vector2(90, 200);
    size = Vector2(64, 36);
    anchor = Anchor.center;
  }

  void leap() {
    vy = game.slow ? -240.0 : -320.0;
    momentum = (momentum + 0.25).clamp(0.0, 1.0);
  }

  void bump() {
    bumped = true;
    bumpTimer = 0.9;
    momentum = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    tailPhase += dt * (8 + momentum * 8);
    vy += (game.slow ? 480 : 640) * dt; // gravity
    position.y += vy * dt;
    final waterline = game.size.y * 0.55;
    final riverbed = game.size.y * 0.86;
    if (position.y > riverbed) {
      position.y = riverbed;
      vy = 0;
    }
    if (position.y < 40) {
      position.y = 40;
      vy = 0;
    }
    // drag is stronger underwater, gentler in air
    if (position.y > waterline) vy *= 0.985;
    momentum = (momentum - dt * 0.08).clamp(0.0, 1.0);
    if (bumpTimer > 0) {
      bumpTimer -= dt;
      if (bumpTimer <= 0) bumped = false;
    }
  }

  @override
  void render(Canvas canvas) {
    final wob = bumped ? sin(bumpTimer * 30) * 0.15 : 0.0;
    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.rotate((vy / 900).clamp(-0.5, 0.5) + wob);
    // body
    canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 56, height: 26),
        Paint()..color = const Color(0xFFE0762E));
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(4, 5), width: 44, height: 14),
        Paint()..color = const Color(0xFFF3C9A0));
    // tail, beating
    final t = sin(tailPhase) * 8;
    final tail = Path()
      ..moveTo(-24, 0)
      ..lineTo(-42, -12 + t)
      ..lineTo(-42, 12 + t)
      ..close();
    canvas.drawPath(tail, Paint()..color = const Color(0xFFC96524));
    // eye
    canvas.drawCircle(const Offset(18, -4), 3.4,
        Paint()..color = const Color(0xFF463A45));
    canvas.restore();
  }
}

/// The whole river world: sky, banks, water with waves, rocks, the
/// waiting pool - everything scrolls against the salmon's progress.
class _River extends Component with HasGameReference<SalmonRunGame> {
  @override
  void render(Canvas canvas) {
    final s = game.size;
    final scroll = game.scroll;
    // sky
    canvas.drawRect(
        Rect.fromLTWH(0, 0, s.x, s.y),
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFCDEBFF), Color(0xFFA8DCFF)])
              .createShader(Rect.fromLTWH(0, 0, s.x, s.y)));
    // far bank trees, slow parallax
    final treePaint = Paint()..color = const Color(0xFF8FC479);
    for (var i = 0; i < 14; i++) {
      final tx = (i * 260 - scroll * 0.3) % (s.x + 400) - 200;
      canvas.drawPath(
          Path()
            ..moveTo(tx, s.y * 0.5)
            ..lineTo(tx + 34, s.y * 0.32)
            ..lineTo(tx + 68, s.y * 0.5)
            ..close(),
          treePaint);
    }
    // water
    canvas.drawRect(
        Rect.fromLTWH(0, s.y * 0.5, s.x, s.y * 0.5),
        Paint()
          ..shader = const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF5FB7EC), Color(0xFF2C86C4)])
              .createShader(
                  Rect.fromLTWH(0, s.y * 0.5, s.x, s.y * 0.5)));
    // current lines drifting against her
    final flow = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final fx = (i * 140 - scroll * 1.4) % (s.x + 80) - 40;
      final fy = s.y * (0.58 + (i % 4) * 0.08);
      canvas.drawLine(Offset(fx, fy), Offset(fx + 26, fy), flow);
    }
    // rocks - each with its own height and girth
    for (final (rx, rh) in game.rocks) {
      final sx = rx - scroll;
      if (sx < -100 || sx > s.x + 100) continue;
      final top = s.y * 0.86 - 70 * rh;
      final h = s.y * 0.88 - top;
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(sx, top + h / 2),
              width: 50 + 26 * rh,
              height: h),
          Paint()..color = const Color(0xFF6B6560));
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(sx - 8 * rh, top + h * 0.3),
              width: 22 + 10 * rh,
              height: h * 0.3),
          Paint()..color = const Color(0xFF837C76));
    }
    // the spawning pool, waiting at the end of the world
    final poolX = game.level.run - scroll + s.x * 0.6;
    if (poolX < s.x + 300) {
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(poolX, s.y * 0.72),
              width: 320,
              height: 130),
          Paint()..color = const Color(0xFF8FD0EA));
      canvas.drawCircle(Offset(poolX - 30, s.y * 0.70), 5,
          Paint()..color = const Color(0xFFE0762E));
      canvas.drawCircle(Offset(poolX + 24, s.y * 0.74), 5,
          Paint()..color = const Color(0xFFE0762E));
    }
    // splashes
    for (final sp in game.splashes) {
      final a = (1 - sp.age / 0.7).clamp(0.0, 1.0);
      canvas.drawCircle(
          Offset(sp.at.x + sp.dx * sp.age * 60,
              sp.at.y - 40 * sp.age + 50 * sp.age * sp.age),
          3 * a,
          Paint()..color = Colors.white.withValues(alpha: 0.8 * a));
    }
    // progress: her journey, told as a river line - not a score
    final p = (scroll / game.level.run).clamp(0.0, 1.0);
    canvas.drawLine(
        Offset(20, 20),
        Offset(s.x - 20, 20),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.4)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(Offset(20 + (s.x - 40) * p, 20), 6,
        Paint()..color = const Color(0xFFE0762E));
  }
}

class _Splash {
  final Vector2 at;
  final double dx = Random().nextDouble() * 2 - 1;
  double age = 0;
  _Splash(this.at);
}

// ---------- the screen ----------

class SalmonRun extends StatefulWidget {
  final void Function(String) speak;
  const SalmonRun({super.key, required this.speak});

  @override
  State<SalmonRun> createState() => _SalmonRunState();
}

class _SalmonRunState extends State<SalmonRun> {
  SalmonRunGame? game;
  int levelIdx = 0;
  bool done = false;

  @override
  Widget build(BuildContext context) {
    game ??= SalmonRunGame(
        level: SalmonLevel.levels[levelIdx],
        slow: MediaQuery.of(context).disableAnimations,
        onDone: () {
          if (mounted) {
            setState(() => done = true);
            widget.speak(SalmonCopy.done);
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
              Expanded(child: Text('🐟 Salmon run', style: kidTitle(20))),
              IconButton(
                  tooltip: 'Leave the river',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close,
                      color: kidInkLight, size: 20)),
            ]),
          ),
          Text(done ? 'home at last 🌟' : SalmonCopy.intro,
              textAlign: TextAlign.center,
              style: kidBody(13, color: kidInkLight)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, children: [
            for (var i = 0; i < SalmonLevel.levels.length; i++)
              ChoiceChip(
                label: Text(
                    '${SalmonLevel.levels[i].emoji} '
                    '${SalmonLevel.levels[i].name}',
                    style: kidBody(12)),
                selected: levelIdx == i,
                selectedColor: kidSky,
                onSelected: (_) => setState(() {
                  levelIdx = i;
                  game = null;
                  done = false;
                }),
              ),
          ]),
          const SizedBox(height: 6),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
                                const Text('🐟💛',
                                    style: TextStyle(fontSize: 44)),
                                const SizedBox(height: 10),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                      color: Colors.white
                                          .withValues(alpha: 0.95),
                                      borderRadius:
                                          BorderRadius.circular(18)),
                                  child: Text(SalmonCopy.done,
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                    decoration: BoxDecoration(
                                        color: kidSun,
                                        borderRadius:
                                            BorderRadius.circular(22)),
                                    child: Text('🐟 Swim again',
                                        style: kidTitle(14)),
                                  ),
                                ),
                              ]),
                        ),
                      ),
                    ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
