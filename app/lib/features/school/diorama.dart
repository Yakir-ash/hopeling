// The Diorama - LAB.md section 2, first wing. The chart stops
// being the first thing you see: this is the meadow itself,
// drawn from the simulation state. Flowers thin when the model
// says they thin; the fox stops appearing when her curve gives
// out; seasons tint the sky as the steps pass. Emoji are the
// actors (house rule since the owl incident); the paint is only
// sky and hill. Deterministic: sprite positions are fixed
// tables, not random - the same season always looks the same.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../data/lab.dart';

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

class MeadowDiorama extends StatefulWidget {
  final LabRun run;
  final double beeLevel; // 0..1 from the lever
  const MeadowDiorama(
      {super.key, required this.run, required this.beeLevel});

  @override
  State<MeadowDiorama> createState() => _MeadowDioramaState();
}

class _MeadowDioramaState extends State<MeadowDiorama> {
  int step = 0;
  Timer? _player;

  @override
  void dispose() {
    _player?.cancel();
    super.dispose();
  }

  void _togglePlay() {
    Haptics.tick();
    if (_player != null) {
      _player!.cancel();
      setState(() => _player = null);
      return;
    }
    if (step >= widget.run.mid[0].length - 1) {
      setState(() => step = 0);
    }
    _player = Timer.periodic(const Duration(milliseconds: 750),
        (t) {
      if (!mounted) return;
      setState(() {
        if (step < widget.run.mid[0].length - 1) {
          step++;
        } else {
          t.cancel();
          _player = null;
        }
      });
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final steps = widget.run.mid[0].length;
    final f = widget.run.mid[0][step];
    final r = widget.run.mid[1][step];
    final x = widget.run.mid[2][step];
    final season = _seasonNames[step % 4];
    final year = step ~/ 4 + 1;
    final flowers = (f * _flowerSlots.length).round();
    final bees = (widget.beeLevel * f * _beeSlots.length).round();
    final rabbits = (r * _rabbitSlots.length).round();
    final foxThere = x >= 0.28;
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: 'The meadow in $season of year $year: '
                '$flowers of ${_flowerSlots.length} flower '
                'patches blooming, '
                '${bees == 0 ? "no bees" : "$bees bees"} at '
                'work, '
                '${rabbits == 0 ? "no rabbits" : "$rabbits rabbits"} '
                'grazing, and the fox '
                '${foxThere ? "is hunting the hedgeline" : "has not come today"}.',
            child: ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 170,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _MeadowPainter(
                      season: step % 4,
                      flowers: flowers,
                      bees: bees,
                      rabbits: rabbits,
                      fox: foxThere,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(children: [
            Semantics(
              button: true,
              label: _player == null
                  ? 'Play the seasons'
                  : 'Pause',
              child: IconButton(
                visualDensity: VisualDensity.compact,
                icon: Icon(
                    _player == null
                        ? Icons.play_arrow_rounded
                        : Icons.pause_rounded,
                    color: fern),
                onPressed: _togglePlay,
              ),
            ),
            Expanded(
              child: Slider(
                value: step.toDouble(),
                min: 0,
                max: (steps - 1).toDouble(),
                divisions: steps - 1,
                activeColor: fern,
                onChanged: (v) {
                  _player?.cancel();
                  _player = null;
                  setState(() => step = v.round());
                },
              ),
            ),
            Text('$season, year $year',
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

class _MeadowPainter extends CustomPainter {
  final int season;
  final int flowers, bees, rabbits;
  final bool fox;
  _MeadowPainter(
      {required this.season,
      required this.flowers,
      required this.bees,
      required this.rabbits,
      required this.fox});

  void _emoji(Canvas canvas, Size size, String e, double fx,
      double fy, double fs) {
    final tp = TextPainter(
        text: TextSpan(
            text: e, style: TextStyle(fontSize: fs)),
        textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(
        canvas,
        Offset(size.width * fx - tp.width / 2,
            size.height * fy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    // sky
    canvas.drawRect(Offset.zero & size,
        Paint()..color = _skyTints[season]);
    // sun, low and mild
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.2),
        14, Paint()..color = gold.withValues(alpha: 0.75));
    // the hill
    final hill = Path()
      ..moveTo(0, size.height * 0.62)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.45,
          size.width, size.height * 0.65)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hill, Paint()..color = _hillTints[season]);
    // flowers - the meadow's own census
    for (var i = 0; i < flowers && i < _flowerSlots.length; i++) {
      final (fx, fy) = _flowerSlots[i];
      _emoji(canvas, size, season == 3 ? '🥀' : '🌼', fx, fy, 15);
    }
    // bees at work
    for (var i = 0; i < bees && i < _beeSlots.length; i++) {
      final (fx, fy) = _beeSlots[i];
      _emoji(canvas, size, '🐝', fx, fy, 12);
    }
    // rabbits grazing
    for (var i = 0; i < rabbits && i < _rabbitSlots.length; i++) {
      final (fx, fy) = _rabbitSlots[i];
      _emoji(canvas, size, '🐰', fx, fy, 15);
    }
    // the fox, when her curve allows her
    if (fox) _emoji(canvas, size, '🦊', 0.92, 0.88, 17);
  }

  @override
  bool shouldRepaint(_MeadowPainter old) =>
      old.season != season ||
      old.flowers != flowers ||
      old.bees != bees ||
      old.rabbits != rabbits ||
      old.fox != fox;
}
