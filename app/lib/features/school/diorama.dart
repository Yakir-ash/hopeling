// The Diorama - LAB.md section 2, first wing. The chart stops
// being the first thing you see: this is the meadow itself,
// drawn from the simulation state. Flowers thin when the model
// says they thin; the fox stops appearing when her curve gives
// out; seasons tint the sky as time passes. Emoji are the actors
// (house rule since the owl incident); the paint is only sky and
// hill. Deterministic: sprite positions are fixed tables, and
// time flows CONTINUOUSLY - values and sky colors interpolate
// between seasons, so the three years play as one smooth breath
// rather than twelve slides.

import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../data/almanac.dart' show season;
import '../../data/lab.dart';

/// Seeded by your sky: the diorama's first season is the user's
/// real current season (LAB.md section 8) - your meadow begins
/// in your August.
int seasonOffset(DateTime now) => const {
      'spring': 0,
      'summer': 1,
      'autumn': 2,
      'winter': 3,
    }[season(now)]!;

// fixed sprite slots (x fraction, y fraction within scene)
const _flowerSlots = [
  (0.06, 0.72), (0.14, 0.80), (0.22, 0.70), (0.30, 0.84),
  (0.38, 0.74), (0.46, 0.81), (0.54, 0.71), (0.62, 0.83),
  (0.70, 0.73), (0.78, 0.80), (0.86, 0.70), (0.93, 0.78),
  (0.10, 0.90), (0.50, 0.90),
];
const _beeSlots = [
  (0.18, 0.58), (0.42, 0.52), (0.66, 0.57), (0.82, 0.50),
  (0.30, 0.46),
];
const _rabbitSlots = [
  (0.20, 0.86), (0.58, 0.88), (0.80, 0.85), (0.38, 0.92),
];

const _seasonNames = ['spring', 'summer', 'autumn', 'winter'];
const _skyTints = [
  Color(0xFFDDEBF5), // spring
  Color(0xFFF5E9C8), // summer
  Color(0xFFF2DFC8), // autumn
  Color(0xFFE4E7EC), // winter
];
const _hillTints = [
  Color(0xFF8FB08B), // spring
  Color(0xFF7FA477), // summer
  Color(0xFFA3A375), // autumn
  Color(0xFF9BA893), // winter
];

double _lerpAt(List<double> series, double t) {
  final i = t.floor().clamp(0, series.length - 1);
  final j = (i + 1).clamp(0, series.length - 1);
  final f = t - i;
  return series[i] * (1 - f) + series[j] * f;
}

Color _seasonColor(List<Color> tints, double t) {
  final a = tints[t.floor() % 4];
  final b = tints[(t.floor() + 1) % 4];
  return Color.lerp(a, b, t - t.floor())!;
}

class MeadowDiorama extends StatefulWidget {
  final LabRun run;
  final double beeLevel; // 0..1 from the lever
  const MeadowDiorama(
      {super.key, required this.run, required this.beeLevel});

  @override
  State<MeadowDiorama> createState() => _MeadowDioramaState();
}

class _MeadowDioramaState extends State<MeadowDiorama>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  int get _steps => widget.run.mid[0].length;

  @override
  void initState() {
    super.initState();
    // ~0.8s per season, one continuous flow
    _ctrl = AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 800 * (_steps - 1)))
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _togglePlay() {
    Haptics.tick();
    if (_ctrl.isAnimating) {
      _ctrl.stop();
    } else {
      if (_ctrl.value >= 0.999) _ctrl.value = 0;
      _ctrl.forward();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = _ctrl.value * (_steps - 1);
    final off = seasonOffset(DateTime.now());
    final seasonName = _seasonNames[(t.round() + off) % 4];
    final year = t.round() ~/ 4 + 1;
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MeadowScene(
              run: widget.run,
              beeLevel: widget.beeLevel,
              t: t,
              seasonOff: off),
          const SizedBox(height: 6),
          Row(children: [
            Semantics(
              button: true,
              label: _ctrl.isAnimating
                  ? 'Pause'
                  : 'Play the seasons',
              child: IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                    _ctrl.isAnimating
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: fern),
                onPressed: _togglePlay,
              ),
            ),
            Expanded(
              child: Slider(
                value: _ctrl.value,
                activeColor: fern,
                onChanged: (v) {
                  _ctrl.stop();
                  setState(() => _ctrl.value = v);
                },
              ),
            ),
            Text('$seasonName, year $year',
                style:
                    const TextStyle(fontSize: 11, color: tx2)),
          ]),
          const Text(
            'this IS the data - the curves below are its x-ray',
            style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: tx2),
          ),
        ],
      ),
    );
  }
}

/// The painted meadow at a moment in time - shared by the solo
/// diorama and the Two Benches (which drives two of these from
/// one clock).
class MeadowScene extends StatelessWidget {
  final LabRun run;
  final double beeLevel;
  final double t;
  final int seasonOff;
  final double height;
  const MeadowScene(
      {super.key,
      required this.run,
      required this.beeLevel,
      required this.t,
      this.seasonOff = 0,
      this.height = 170});

  @override
  Widget build(BuildContext context) {
    final f = _lerpAt(run.mid[0], t);
    final r = _lerpAt(run.mid[1], t);
    final x = _lerpAt(run.mid[2], t);
    final seasonName = _seasonNames[(t.round() + seasonOff) % 4];
    final year = t.round() ~/ 4 + 1;
    final flowers = (f * _flowerSlots.length).round();
    final bees = (beeLevel * f * _beeSlots.length).round();
    final rabbits = (r * _rabbitSlots.length).round();
    final foxThere = x >= 0.28;
    return Semantics(
      label: 'The meadow in $seasonName of year $year: '
          '$flowers of ${_flowerSlots.length} flower patches '
          'blooming, '
          '${bees == 0 ? "no bees" : "$bees bees"} at work, '
          '${rabbits == 0 ? "no rabbits" : "$rabbits rabbits"} '
          'grazing, and the fox '
          '${foxThere ? "is hunting the hedgeline" : "has not come today"}.',
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: CustomPaint(
              painter: _MeadowPainter(
                t: t + seasonOff,
                flowers: flowers,
                bees: bees,
                rabbits: rabbits,
                fox: foxThere,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MeadowPainter extends CustomPainter {
  final double t;
  final int flowers, bees, rabbits;
  final bool fox;
  _MeadowPainter(
      {required this.t,
      required this.flowers,
      required this.bees,
      required this.rabbits,
      required this.fox});

  void _emoji(Canvas canvas, Size size, String e, double fx,
      double fy, double fs) {
    final tp = TextPainter(
        text: TextSpan(text: e, style: TextStyle(fontSize: fs)),
        textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(
        canvas,
        Offset(size.width * fx - tp.width / 2,
            size.height * fy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    // sky and hill, blended continuously between seasons
    canvas.drawRect(Offset.zero & size,
        Paint()..color = _seasonColor(_skyTints, t));
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.2),
        14, Paint()..color = gold.withValues(alpha: 0.75));
    final hill = Path()
      ..moveTo(0, size.height * 0.62)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.45,
          size.width, size.height * 0.65)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
        hill, Paint()..color = _seasonColor(_hillTints, t));
    final winterish = (t.round() % 4) == 3;
    for (var i = 0; i < flowers && i < _flowerSlots.length; i++) {
      final (fx, fy) = _flowerSlots[i];
      _emoji(canvas, size, winterish ? '🥀' : '🌼', fx, fy, 15);
    }
    for (var i = 0; i < bees && i < _beeSlots.length; i++) {
      final (fx, fy) = _beeSlots[i];
      // bees drift a little as time flows - alive, not pinned
      final wob = 0.012 * (i.isEven ? 1 : -1);
      _emoji(canvas, size, '🐝', fx + wob * (t % 2), fy, 12);
    }
    for (var i = 0; i < rabbits && i < _rabbitSlots.length; i++) {
      final (fx, fy) = _rabbitSlots[i];
      _emoji(canvas, size, '🐰', fx, fy, 15);
    }
    if (fox) _emoji(canvas, size, '🦊', 0.92, 0.88, 17);
  }

  @override
  bool shouldRepaint(_MeadowPainter old) =>
      old.t != t ||
      old.flowers != flowers ||
      old.bees != bees ||
      old.rabbits != rabbits ||
      old.fox != fox;
}
