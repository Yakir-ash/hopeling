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

/// Which scenarios have a living scene, and how to draw it at
/// time t. Everything else falls back to charts alone.
bool hasScene(String scenarioId) =>
    const {'meadow', 'wolves', 'sea'}.contains(scenarioId);

Widget labScene(LabScenario s, LabRun run, int option, double t,
    {double height = 170}) {
  switch (s.id) {
    case 'meadow':
      return MeadowScene(
          run: run,
          beeLevel: const [1.0, 0.5, 0.0][option],
          t: t,
          seasonOff: seasonOffset(DateTime.now()),
          height: height);
    case 'wolves':
      return ValleyScene(
          run: run, wolves: option == 1, t: t, height: height);
    case 'sea':
      return ReefScene(run: run, t: t, height: height);
  }
  return const SizedBox.shrink();
}

class LabDiorama extends StatefulWidget {
  final LabScenario scenario;
  final LabRun run;
  final int option;
  const LabDiorama(
      {super.key,
      required this.scenario,
      required this.run,
      required this.option});

  @override
  State<LabDiorama> createState() => _LabDioramaState();
}

class _LabDioramaState extends State<LabDiorama>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  int get _steps => widget.run.mid[0].length;

  @override
  void initState() {
    super.initState();
    // ~0.8s per season; years pass quicker (25 of them)
    _ctrl = AnimationController(
        vsync: this,
        duration: Duration(
            milliseconds:
                (widget.scenario.steps > 12 ? 350 : 800) *
                    (_steps - 1)))
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
    final yearly = widget.scenario.steps > 12;
    final off = seasonOffset(DateTime.now());
    final label = yearly
        ? 'year ${t.round() + 1}'
        : '${_seasonNames[(t.round() + off) % 4]}, '
            'year ${t.round() ~/ 4 + 1}';
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          labScene(widget.scenario, widget.run, widget.option, t),
          const SizedBox(height: 6),
          Row(children: [
            Semantics(
              button: true,
              label: _ctrl.isAnimating
                  ? 'Pause'
                  : 'Play the ${yearly ? "years" : "seasons"}',
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
            Text(label,
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

// ==================== THE VALLEY (wolves) ====================
// Twenty-five years of Yellowstone in one frame: the stream, the
// willows along its banks, the elk who decide their fate, the
// beaver who arrives when the willows do, and the wolf standing
// at the treeline when the lever says she is home.

const _willowSlots = [
  (0.28, 0.66), (0.38, 0.72), (0.48, 0.64), (0.58, 0.71),
  (0.68, 0.65), (0.35, 0.80), (0.55, 0.82), (0.45, 0.88),
];
const _elkSlots = [
  (0.15, 0.85), (0.78, 0.78), (0.24, 0.72), (0.86, 0.88),
  (0.65, 0.90),
];

class ValleyScene extends StatelessWidget {
  final LabRun run;
  final bool wolves;
  final double t;
  final double height;
  const ValleyScene(
      {super.key,
      required this.run,
      required this.wolves,
      required this.t,
      this.height = 170});

  @override
  Widget build(BuildContext context) {
    final elk = _lerpAt(run.mid[0], t);
    final wil = _lerpAt(run.mid[1], t);
    final bv = _lerpAt(run.mid[2], t);
    final year = t.round() + 1;
    final elkCount = (elk * _elkSlots.length).round();
    final willows = (wil * _willowSlots.length).round();
    final beaverThere = bv >= 0.2;
    return Semantics(
      label: 'The valley in year $year: '
          '${elkCount == 0 ? "no elk" : "$elkCount elk"} in the '
          'open, $willows of ${_willowSlots.length} willow '
          'stands along the stream, the beaver '
          '${beaverThere ? "is building" : "has not returned"}, '
          'and the wolves are '
          '${wolves ? "home at the treeline" : "absent"}.',
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: CustomPaint(
              painter: _ValleyPainter(
                willowLevel: wil,
                elkCount: elkCount,
                willows: willows,
                beaver: beaverThere,
                lodge: bv >= 0.3,
                wolf: wolves,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ValleyPainter extends CustomPainter {
  final double willowLevel;
  final int elkCount, willows;
  final bool beaver, lodge, wolf;
  _ValleyPainter(
      {required this.willowLevel,
      required this.elkCount,
      required this.willows,
      required this.beaver,
      required this.lodge,
      required this.wolf});

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
    // mountain sky
    canvas.drawRect(Offset.zero & size,
        Paint()..color = const Color(0xFFE3EAF0));
    // the far ridge with its treeline
    final ridge = Path()
      ..moveTo(0, size.height * 0.42)
      ..lineTo(size.width * 0.3, size.height * 0.22)
      ..lineTo(size.width * 0.55, size.height * 0.38)
      ..lineTo(size.width * 0.8, size.height * 0.20)
      ..lineTo(size.width, size.height * 0.36)
      ..lineTo(size.width, size.height * 0.55)
      ..lineTo(0, size.height * 0.55)
      ..close();
    canvas.drawPath(ridge, Paint()..color = const Color(0xFF9BAA9B));
    // valley floor
    canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.5, size.width,
            size.height * 0.5),
        Paint()..color = const Color(0xFFADBE96));
    // the stream: healthy willows narrow and deepen it; bare
    // banks leave it wide, shallow, pale
    final width = 22 - willowLevel * 12; // px-ish
    final streamColor = Color.lerp(const Color(0xFFC7D6D8),
        const Color(0xFF7FA8C0), willowLevel)!;
    final stream = Path()
      ..moveTo(size.width * 0.05, size.height * 0.55)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.7,
          size.width * 0.5, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.6, size.height * 0.9,
          size.width * 0.95, size.height * 0.95);
    canvas.drawPath(
        stream,
        Paint()
          ..color = streamColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round);
    // willows along the banks
    for (var i = 0; i < willows && i < _willowSlots.length; i++) {
      final (fx, fy) = _willowSlots[i];
      _emoji(canvas, size, '🌿', fx, fy, 15);
    }
    // elk in the open
    for (var i = 0; i < elkCount && i < _elkSlots.length; i++) {
      final (fx, fy) = _elkSlots[i];
      _emoji(canvas, size, '🦌', fx, fy, 16);
    }
    // the beaver and, in time, her lodge
    if (lodge) _emoji(canvas, size, '🪵', 0.52, 0.83, 14);
    if (beaver) _emoji(canvas, size, '🦫', 0.47, 0.79, 15);
    // the wolf at the treeline, when she is home
    if (wolf) _emoji(canvas, size, '🐺', 0.12, 0.48, 16);
  }

  @override
  bool shouldRepaint(_ValleyPainter old) =>
      old.willowLevel != willowLevel ||
      old.elkCount != elkCount ||
      old.willows != willows ||
      old.beaver != beaver ||
      old.lodge != lodge ||
      old.wolf != wolf;
}

// ==================== THE REEF (sea) ====================
// The city and its citizens: corals that pale as the heat
// stays, fish that thin with their streets, and the boat that
// fishes the third curve.

const _coralSlots = [
  (0.10, 0.82), (0.22, 0.88), (0.34, 0.80), (0.46, 0.90),
  (0.58, 0.82), (0.70, 0.88), (0.82, 0.80), (0.92, 0.88),
  (0.28, 0.94), (0.64, 0.94),
];
const _fishSlots = [
  (0.20, 0.55), (0.45, 0.48), (0.70, 0.58), (0.32, 0.66),
  (0.60, 0.68), (0.85, 0.50),
];

class ReefScene extends StatelessWidget {
  final LabRun run;
  final double t;
  final double height;
  const ReefScene(
      {super.key,
      required this.run,
      required this.t,
      this.height = 170});

  @override
  Widget build(BuildContext context) {
    final coral = _lerpAt(run.mid[0], t);
    final fish = _lerpAt(run.mid[1], t);
    final catchLevel = _lerpAt(run.mid[2], t);
    final year = t.round() ~/ 4 + 1;
    final living =
        (coral / 0.85 * _coralSlots.length).round().clamp(0, 10);
    final fishCount = (fish * _fishSlots.length).round();
    return Semantics(
      label: 'The reef in year $year: $living of '
          '${_coralSlots.length} coral heads still in color, '
          'the rest bleached white; '
          '${fishCount == 0 ? "no fish" : "$fishCount fish"} in '
          'the streets; the boat above '
          '${catchLevel > 0.25 ? "is still working" : "has little to work for"}.',
      child: ExcludeSemantics(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: CustomPaint(
              painter: _ReefPainter(
                living: living,
                fishCount: fishCount,
                boat: catchLevel > 0.25,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReefPainter extends CustomPainter {
  final int living, fishCount;
  final bool boat;
  _ReefPainter(
      {required this.living,
      required this.fishCount,
      required this.boat});

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
    // the water column, light to deep
    final water = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFBFE0E8), Color(0xFF6FA3B8)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, water);
    // sun shafts
    final shaft = Paint()..color = const Color(0x22FFF3D6);
    for (final x in [0.2, 0.5, 0.8]) {
      canvas.drawPath(
          Path()
            ..moveTo(size.width * (x - 0.04), 0)
            ..lineTo(size.width * (x + 0.04), 0)
            ..lineTo(size.width * (x + 0.10), size.height)
            ..lineTo(size.width * (x - 0.10), size.height)
            ..close(),
          shaft);
    }
    // sea floor
    canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.86, size.width,
            size.height * 0.14),
        Paint()..color = const Color(0xFFD8CBA8));
    // the city: living coral in color, the rest bleached white
    for (var i = 0; i < _coralSlots.length; i++) {
      final (fx, fy) = _coralSlots[i];
      _emoji(canvas, size, i < living ? '🪸' : '🦴', fx, fy, 15);
    }
    // the citizens
    for (var i = 0; i < fishCount && i < _fishSlots.length; i++) {
      final (fx, fy) = _fishSlots[i];
      _emoji(canvas, size, i.isEven ? '🐠' : '🐟', fx, fy, 14);
    }
    // the third curve, at the surface
    if (boat) _emoji(canvas, size, '⛵', 0.85, 0.06, 16);
  }

  @override
  bool shouldRepaint(_ReefPainter old) =>
      old.living != living ||
      old.fishCount != fishCount ||
      old.boat != boat;
}
