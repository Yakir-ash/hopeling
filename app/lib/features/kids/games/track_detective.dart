// Track Detective - real footprints, drawn true to life, stamp across
// a dusk forest one print at a time. The child taps the glowing next
// print to follow the trail; at its end, whoever walked there steps
// out to say hello. Deer leave twin moons, foxes leave four toes and a
// pad, herons leave arrows, rabbits leave their famous Y - the shapes
// are the lesson, and a child who follows enough trails starts seeing
// them in real mud. Three trails a visit; no timer, no wrong taps -
// a missed tap is just the forest being quiet.

import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/haptics.dart';
import '../../../core/kid_theme.dart';
import '../comic.dart' show ScenePainter, ComicScene;

// ---------- pure logic (tested) ----------

class TrackAnimal {
  final String emo, name, trackName, hello;
  const TrackAnimal(this.emo, this.name, this.trackName, this.hello);
}

const trackAnimals = [
  TrackAnimal('🦌', 'Deer', 'twin moons',
      'A deer walked here - hooves like two little moons.'),
  TrackAnimal('🦊', 'Fox', 'four toes and a heart',
      'A fox trotted through - four toes around a heart-shaped pad.'),
  TrackAnimal('🪶', 'Heron', 'arrows',
      'A heron waded past - three long toes like arrows.'),
  TrackAnimal('🐇', 'Rabbit', 'the famous Y',
      'A rabbit hopped by - big back feet landing in front!'),
];

/// The trail: [count] steps across the box, deterministic per seed,
/// gently curving, never touching the edges.
List<Offset> trailPoints(int count, int seed) {
  final r = Random(seed);
  final out = <Offset>[];
  var x = 0.15, y = 0.82;
  var heading = -0.5 - r.nextDouble() * 0.4;
  for (var i = 0; i < count; i++) {
    out.add(Offset(x, y));
    heading += (r.nextDouble() - 0.5) * 0.7;
    x += cos(heading) * 0.115 + 0.06;
    y += sin(heading) * 0.1;
    x = x.clamp(0.08, 0.92);
    y = y.clamp(0.14, 0.88);
  }
  return out;
}

class TrackCopy {
  static const intro =
      'Someone walked here! Tap the glowing footprint to follow.';
  static const done =
      'Three trails followed. Real mud keeps tracks too - '
      'look down on your next walk.';
}

// ---------- the game ----------

class TrackDetective extends StatefulWidget {
  final void Function(String) speak;
  const TrackDetective({super.key, required this.speak});

  @override
  State<TrackDetective> createState() => _TrackDetectiveState();
}

class _TrackDetectiveState extends State<TrackDetective> {
  static const steps = 7;
  int round = 0; // 0..2
  int found = 0; // prints found this round
  bool revealed = false;
  late List<Offset> trail = trailPoints(steps, 100 + round);

  TrackAnimal get animal =>
      trackAnimals[(round + DateTime.now().day) % trackAnimals.length];

  @override
  void initState() {
    super.initState();
    widget.speak(TrackCopy.intro);
  }

  void _tapAt(Offset p, Size s) {
    if (revealed || found >= steps) return;
    final next =
        Offset(trail[found].dx * s.width, trail[found].dy * s.height);
    if ((next - p).distance < 52) {
      Haptics.tick();
      setState(() => found++);
      if (found >= steps) {
        Haptics.settle();
        setState(() => revealed = true);
        widget.speak(animal.hello);
      }
    }
  }

  void _nextTrail() {
    if (round >= 2) {
      widget.speak(TrackCopy.done);
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      round++;
      found = 0;
      revealed = false;
      trail = trailPoints(steps, 100 + round);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kidCream,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 8, 4),
            child: Row(children: [
              Expanded(
                  child:
                      Text('🐾 Track detective', style: kidTitle(20))),
              IconButton(
                  tooltip: 'Leave the forest',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close,
                      color: kidInkLight, size: 20)),
            ]),
          ),
          Text('trail ${round + 1} of 3 · $found of $steps prints',
              style: kidBody(13, color: kidInkLight)),
          const SizedBox(height: 8),
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
                    child: Stack(fit: StackFit.expand, children: [
                      CustomPaint(
                        painter: _TrailPainter(
                            trail, found, animal, revealed),
                      ),
                      if (revealed)
                        Align(
                          alignment: const Alignment(0, -0.55),
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                KidDrift(
                                    child: Text(animal.emo,
                                        style: const TextStyle(
                                            fontSize: 72))),
                                Container(
                                  margin: const EdgeInsets.all(12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      color: Colors.white
                                          .withValues(alpha: 0.92),
                                      borderRadius:
                                          BorderRadius.circular(18)),
                                  child: Text(animal.hello,
                                      textAlign: TextAlign.center,
                                      style: kidBody(13.5)),
                                ),
                                KidSquish(
                                  onTap: _nextTrail,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 22, vertical: 12),
                                    decoration: BoxDecoration(
                                        color: kidSun,
                                        borderRadius:
                                            BorderRadius.circular(22)),
                                    child: Text(
                                        round >= 2
                                            ? '🌟 Done detecting!'
                                            : '🐾 Find the next trail',
                                        style: kidTitle(14)),
                                  ),
                                ),
                              ]),
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

class _TrailPainter extends CustomPainter {
  final List<Offset> trail;
  final int found;
  final TrackAnimal animal;
  final bool revealed;
  _TrailPainter(this.trail, this.found, this.animal, this.revealed);

  @override
  void paint(Canvas canvas, Size s) {
    ScenePainter(37, ComicScene.forest, false).paint(canvas, s);
    // dusk falls over the forest - tracks are a dawn-and-dusk craft
    canvas.drawRect(
        Offset.zero & s,
        Paint()
          ..color = const Color(0xFF2B2440).withValues(alpha: 0.32));

    for (var i = 0; i <= found && i < trail.length; i++) {
      final o = Offset(trail[i].dx * s.width, trail[i].dy * s.height);
      final isNext = i == found && !revealed;
      final ink = Paint()
        ..color = isNext
            ? const Color(0xFFFFE08A)
            : const Color(0xFF2E2233).withValues(alpha: 0.85);
      if (isNext) {
        canvas.drawCircle(
            o,
            30,
            Paint()
              ..color =
                  const Color(0xFFFFE08A).withValues(alpha: 0.25));
      }
      _print(canvas, o, i.isEven, ink);
    }
  }

  /// The real shapes, simplified but honest.
  void _print(Canvas c, Offset o, bool leftFoot, Paint p) {
    final flip = leftFoot ? -1.0 : 1.0;
    switch (animal.name) {
      case 'Deer': // two teardrop halves - the twin moons
        c.drawOval(
            Rect.fromCenter(
                center: o + Offset(-4 * flip, 0), width: 7, height: 16),
            p);
        c.drawOval(
            Rect.fromCenter(
                center: o + Offset(4 * flip, 0), width: 7, height: 16),
            p);
      case 'Fox': // heart pad + four toes
        c.drawOval(
            Rect.fromCenter(
                center: o + const Offset(0, 5), width: 11, height: 9),
            p);
        for (final dx in [-7.0, -2.5, 2.5, 7.0]) {
          c.drawCircle(o + Offset(dx, -4 - (dx.abs() < 4 ? 3 : 0)), 3, p);
        }
      case 'Heron': // three long toes like arrows
        for (final a in [-0.5, 0.0, 0.5]) {
          c.drawLine(
              o + const Offset(0, 8),
              o + Offset(sin(a) * 16, -12 * cos(a)),
              Paint()
                ..color = p.color
                ..strokeWidth = 3
                ..strokeCap = StrokeCap.round);
        }
      default: // Rabbit: two long back feet ahead of two round front
        c.drawOval(
            Rect.fromCenter(
                center: o + const Offset(-6, -6), width: 6, height: 15),
            p);
        c.drawOval(
            Rect.fromCenter(
                center: o + const Offset(6, -6), width: 6, height: 15),
            p);
        c.drawCircle(o + Offset(-3 * flip, 9), 3.5, p);
        c.drawCircle(o + Offset(4 * flip, 11), 3.5, p);
    }
  }

  @override
  bool shouldRepaint(_TrailPainter old) =>
      old.found != found || old.revealed != revealed;
}
