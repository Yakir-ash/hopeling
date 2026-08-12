// The Lab - pull one thread, watch the web. Adult surface (kid
// reskins come later and must end in repair). Every experiment:
// a question, a lever, twelve drawn seasons of consequence, the
// curated moments, and - where it really happened - the citation.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/haptics.dart';
import '../../core/sfx.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/lab.dart';

const _seriesColors = [fern, gold, Color(0xFF8A6FA8)];

class LabScreen extends StatelessWidget {
  const LabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: ink,
          title: Text('🧪 The Lab', style: serif(19))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            const Text(
              'Pull one thread and watch the web answer. Every '
              'experiment here is a small honest model - same '
              'lever, same result, every time, because science '
              'repeats or it is not science.',
              style: TextStyle(fontSize: 13, height: 1.6, color: tx2),
            ),
            const SizedBox(height: 14),
            for (final s in labScenarios)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: Semantics(
                  button: true,
                  label: '${s.title}. ${s.question}',
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Haptics.tick();
                        Sfx.play('tick', volume: 0.3);
                        Navigator.of(context)
                            .push(risePush(LabPage(scenario: s)));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: ExcludeSemantics(
                          child: Row(children: [
                            Text(s.emoji,
                                style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(s.title, style: serif(15)),
                                  const SizedBox(height: 2),
                                  Text(s.question,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          height: 1.4,
                                          color: tx2)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: tx2, size: 20),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class LabPage extends StatefulWidget {
  final LabScenario scenario;
  const LabPage({super.key, required this.scenario});

  @override
  State<LabPage> createState() => _LabPageState();
}

class _LabPageState extends State<LabPage> {
  int option = 0;

  @override
  Widget build(BuildContext context) {
    final s = widget.scenario;
    final data = simulate(s.id, option);
    final opt = s.options[option];
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: ink,
          title: Text('${s.emoji} ${s.title}', style: serif(17))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            Text(s.question, style: serif(18)),
            const SizedBox(height: 14),
            Text(s.leverName.toUpperCase(),
                style: const TextStyle(
                    fontSize: 10.5, letterSpacing: 2, color: tx2)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < s.options.length; i++)
                  ChoiceChip(
                    label: Text(s.options[i].label,
                        style: const TextStyle(fontSize: 12)),
                    selected: option == i,
                    selectedColor: mint,
                    onSelected: (_) {
                      Haptics.tick();
                      Sfx.play('flip', volume: 0.3);
                      setState(() => option = i);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 14),
            // three years, drawn
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    label: _chartSummary(s, data),
                    child: ExcludeSemantics(
                      child: SizedBox(
                        height: 150,
                        width: double.infinity,
                        child: CustomPaint(
                            painter: _CurvesPainter(data)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    children: [
                      for (var i = 0; i < s.series.length; i++)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                              width: 10,
                              height: 3,
                              color: _seriesColors[
                                  i % _seriesColors.length]),
                          const SizedBox(width: 5),
                          Text(
                              '${s.series[i].emoji} '
                              '${s.series[i].name}',
                              style: const TextStyle(
                                  fontSize: 11.5, color: tx2)),
                        ]),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('three years, season by season',
                      style: TextStyle(fontSize: 10.5, color: tx2)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text('What happened', style: serif(15)),
            const SizedBox(height: 8),
            for (final m in opt.moments)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('season ${m.step + 1}',
                        style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: fern)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(m.text,
                          style: const TextStyle(
                              fontSize: 13, height: 1.55, color: ink)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: mint.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(18)),
              child: Text(opt.epilogue,
                  style: const TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      fontStyle: FontStyle.italic,
                      color: ink)),
            ),
            if (s.citation != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFE3C2).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.citation!,
                        style: const TextStyle(
                            fontSize: 12, height: 1.55, color: ink)),
                    if (s.citationUrl != null)
                      Semantics(
                        button: true,
                        label: 'Read the real story',
                        child: TextButton(
                          onPressed: () {
                            Haptics.tick();
                            launchUrl(Uri.parse(s.citationUrl!),
                                mode: LaunchMode.externalApplication);
                          },
                          child: const Text('read the real story',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: fern)),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            const Text(
              'A model, honestly small: it shows directions, not '
              'destinies. The real web has a thousand threads we '
              'did not draw.',
              style: TextStyle(
                  fontSize: 10.5,
                  fontStyle: FontStyle.italic,
                  color: tx2),
            ),
          ],
        ),
      ),
    );
  }

  String _chartSummary(LabScenario s, List<List<double>> data) {
    final parts = <String>[];
    for (var i = 0; i < s.series.length && i < data.length; i++) {
      final first = data[i].first, last = data[i].last;
      final dir = last > first + 0.05
          ? 'grows'
          : (last < first - 0.05 ? 'declines' : 'holds steady');
      parts.add('${s.series[i].name} $dir');
    }
    return 'Over three years: ${parts.join('; ')}.';
  }
}

class _CurvesPainter extends CustomPainter {
  final List<List<double>> data;
  _CurvesPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    // quiet paper grid
    final grid = Paint()
      ..color = const Color(0x14000000)
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (var s = 0; s < data.length; s++) {
      final pts = data[s];
      if (pts.length < 2) continue;
      final paint = Paint()
        ..color = _seriesColors[s % _seriesColors.length]
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final path = Path();
      for (var i = 0; i < pts.length; i++) {
        final x = size.width * i / (pts.length - 1);
        final y = size.height * (1 - pts[i] * 0.92) - 2;
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
      // the end dot - where three years left them
      final lx = size.width;
      final ly = size.height * (1 - pts.last * 0.92) - 2;
      canvas.drawCircle(Offset(lx - 2, ly),
          3.5, Paint()..color = paint.color);
    }
  }

  @override
  bool shouldRepaint(_CurvesPainter old) => old.data != data;
}
