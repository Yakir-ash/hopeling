// The band chart, shared by the Lab page and the Two Benches:
// lo..hi filled softly (the honest band), mid drawn solid, real
// observations as ink dots when history is available.

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/lab.dart';

const seriesColors = [fern, gold, Color(0xFF8A6FA8)];

class BandChart extends StatelessWidget {
  final LabRun run;
  final List<(String, String)> names;
  final RealData? realData;
  final String? title;
  final double height;
  const BandChart(
      {super.key,
      required this.run,
      required this.names,
      this.realData,
      this.title,
      this.height = 150});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            label: _summary(),
            child: ExcludeSemantics(
              child: SizedBox(
                height: height,
                width: double.infinity,
                child: CustomPaint(
                    painter: BandPainter(run, realData)),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              for (var i = 0; i < names.length; i++)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                      width: 10,
                      height: 3,
                      color: seriesColors[i % seriesColors.length]),
                  const SizedBox(width: 4),
                  Text('${names[i].$2} ${names[i].$1}',
                      style:
                          const TextStyle(fontSize: 11, color: tx2)),
                ]),
              if (title != null)
                Text('· $title',
                    style: const TextStyle(
                        fontSize: 10.5,
                        fontStyle: FontStyle.italic,
                        color: tx2)),
            ],
          ),
        ],
      ),
    );
  }

  String _summary() {
    final parts = <String>[];
    for (var i = 0; i < names.length && i < run.mid.length; i++) {
      final first = run.mid[i].first, last = run.mid[i].last;
      final dir = last > first + 0.05
          ? 'grows'
          : (last < first - 0.05 ? 'declines' : 'holds steady');
      parts.add('${names[i].$1} $dir');
    }
    return 'The band of honest runs: ${parts.join('; ')}.';
  }
}

class BandPainter extends CustomPainter {
  final LabRun run;
  final RealData? realData;
  BandPainter(this.run, this.realData);

  double _y(Size s, double v) => s.height * (1 - v * 0.92) - 2;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0x12000000)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (var s = 0; s < run.mid.length; s++) {
      final color = seriesColors[s % seriesColors.length];
      final n = run.mid[s].length;
      if (n < 2) continue;
      double x(int i) => size.width * i / (n - 1);
      final band = Path()
        ..moveTo(x(0), _y(size, run.lo[s][0]));
      for (var i = 1; i < n; i++) {
        band.lineTo(x(i), _y(size, run.lo[s][i]));
      }
      for (var i = n - 1; i >= 0; i--) {
        band.lineTo(x(i), _y(size, run.hi[s][i]));
      }
      band.close();
      canvas.drawPath(
          band, Paint()..color = color.withValues(alpha: 0.13));
      final line = Path()..moveTo(x(0), _y(size, run.mid[s][0]));
      for (var i = 1; i < n; i++) {
        line.lineTo(x(i), _y(size, run.mid[s][i]));
      }
      canvas.drawPath(
          line,
          Paint()
            ..color = color
            ..strokeWidth = 2.4
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round);
      canvas.drawCircle(
          Offset(x(n - 1) - 2, _y(size, run.mid[s].last)),
          3.2,
          Paint()..color = color);
    }
    final rd = realData;
    if (rd != null && run.mid.isNotEmpty) {
      final n = run.mid[0].length;
      final dot = Paint()..color = ink;
      final ring = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      rd.points.forEach((step, v) {
        if (step < n) {
          final o =
              Offset(size.width * step / (n - 1), _y(size, v));
          canvas.drawCircle(o, 3.4, dot);
          canvas.drawCircle(o, 3.4, ring);
        }
      });
    }
  }

  @override
  bool shouldRepaint(BandPainter old) =>
      old.run != run || old.realData != realData;
}
