// The Lab v2 - the scientist's loop made screen (LAB.md).
// Choose a lever, PREDICT before anything runs, then the three
// honest runs draw as a band, the moments tell the seasons, the
// web behind it is tappable edge by edge, Under the Hood admits
// what the model cannot do, real history overlays as dots where
// we have it, and the repair act continues from the wreckage -
// slower, as reality is.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/haptics.dart';
import '../../core/sfx.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/fieldguide.dart';
import '../../data/lab.dart';
import 'diorama.dart';

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
              'experiment is a small honest model, run three '
              'ways - cautious, best estimate, severe - and '
              'nothing here rolls dice: same lever, same band, '
              'every time.',
              style: TextStyle(fontSize: 13, height: 1.6, color: tx2),
            ),
            const SizedBox(height: 6),
            for (final (wing, scenarios) in labWings()) ...[
              const SizedBox(height: 12),
              Text(wing.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 10.5, letterSpacing: 2, color: tx2)),
              const SizedBox(height: 8),
              for (final s in scenarios)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
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
                          padding: const EdgeInsets.all(15),
                          child: ExcludeSemantics(
                            child: Row(children: [
                              Text(s.emoji,
                                  style:
                                      const TextStyle(fontSize: 22)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(s.title, style: serif(14.5)),
                                    const SizedBox(height: 2),
                                    Text(s.question,
                                        style: const TextStyle(
                                            fontSize: 11.5,
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
  String? guess; // rises | falls | holds - per lever setting
  bool showData = false;
  bool repairing = false;

  String _direction(List<double> series) {
    final first = series.first, last = series.last;
    if (last > first + 0.05) return 'rises';
    if (last < first - 0.05) return 'falls';
    return 'holds';
  }

  void _chooseGuess(String g, LabRun run) {
    final s = widget.scenario;
    setState(() => guess = g);
    Haptics.tick();
    Sfx.play('drop', volume: 0.35);
    // the lab page: the scientist's notebook grows
    final modelDir = _direction(run.mid[s.predictIndex]);
    final day = DateTime.now()
        .difference(DateTime.utc(2020, 1, 1))
        .inDays;
    FieldGuide.earn(
        'lab', 'lab:${s.id}:$option:$g:$modelDir:$day');
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scenario;
    final run = runBands(s, option);
    final opt = s.options[option];
    final names = s.seriesNames;
    final focusName = names[s.predictIndex].$1;
    final modelDir = _direction(run.mid[s.predictIndex]);
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
            const SizedBox(height: 12),
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
                      setState(() {
                        option = i;
                        guess = null; // a new lever, a new guess
                        repairing = false;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (guess == null)
              // THE SCIENTIST'S LOOP: nothing runs until you guess
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                    color: const Color(0xFFF3EAD8),
                    borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Before it runs - your guess',
                        style: serif(15)),
                    const SizedBox(height: 6),
                    Text(
                        'With this lever set, what happens to '
                        '$focusName over the '
                        '${s.steps == 12 ? "three years" : "years"}?',
                        style: const TextStyle(
                            fontSize: 13, height: 1.5, color: ink)),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, children: [
                      for (final g in ['rises', 'falls', 'holds'])
                        Semantics(
                          button: true,
                          label: '$focusName $g',
                          child: ActionChip(
                            label: Text(g,
                                style: const TextStyle(fontSize: 13)),
                            onPressed: () => _chooseGuess(g, run),
                          ),
                        ),
                    ]),
                    const SizedBox(height: 8),
                    const Text(
                        'No grades - a guess is how a scientist '
                        'says hello to a question.',
                        style: TextStyle(fontSize: 10.5, color: tx2)),
                  ],
                ),
              )
            else ...[
              // guess made - the world may now answer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: Text(
                    guess == modelDir
                        ? 'You guessed $focusName $guess - so does '
                            'the model. Now the interesting '
                            'question: why?'
                        : 'You guessed $focusName $guess - the '
                            'model says $modelDir. This is where '
                            'it gets interesting: somewhere below '
                            'is the thread you and the model '
                            'read differently.',
                    style: const TextStyle(
                        fontSize: 12.5, height: 1.55, color: ink)),
              ),
              const SizedBox(height: 12),
              // the diorama: the world first, the x-ray after
              if (s.id == 'meadow') ...[
                MeadowDiorama(
                    run: run,
                    beeLevel: const [1.0, 0.5, 0.0][option]),
                const SizedBox(height: 12),
              ],
              _BandChart(
                run: run,
                names: names,
                realData: showData ? s.realData : null,
                title: repairing ? null : 'the three honest runs',
              ),
              if (s.realData != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Semantics(
                    button: true,
                    label: showData
                        ? 'Hide the real counts'
                        : 'Show what actually happened',
                    child: ActionChip(
                      avatar: Text(showData ? '📈' : '📍',
                          style: const TextStyle(fontSize: 13)),
                      label: Text(
                          showData
                              ? 'hide the real counts'
                              : 'what actually happened?',
                          style: const TextStyle(fontSize: 12)),
                      onPressed: () {
                        Haptics.tick();
                        setState(() => showData = !showData);
                      },
                    ),
                  ),
                ),
              if (showData && s.realData != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                      '${s.realData!.label}.\nSource: '
                      '${s.realData!.cite}',
                      style: const TextStyle(
                          fontSize: 10.5, height: 1.5, color: tx2)),
                ),
              if (run.collapsed.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF6E9E4),
                        borderRadius: BorderRadius.circular(14)),
                    child: Text(
                        'A threshold was crossed: '
                        '${run.collapsed.map((id) => s.nodes.firstWhere((n) => n.id == id).name.toLowerCase()).join(", ")} '
                        'fell below the line where the old '
                        'recovery physics stop applying.',
                        style: const TextStyle(
                            fontSize: 12, height: 1.5, color: ink)),
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
                      SizedBox(
                        width: 62,
                        child: Text(
                            s.steps > 12
                                ? 'year ${m.step + 1}'
                                : 'season ${m.step + 1}',
                            style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: fern)),
                      ),
                      Expanded(
                        child: Text(m.text,
                            style: const TextStyle(
                                fontSize: 13,
                                height: 1.55,
                                color: ink)),
                      ),
                    ],
                  ),
                ),
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
              // THE WEB BEHIND IT - every edge tappable, cited
              if (s.edges.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('The web behind it', style: serif(15)),
                const SizedBox(height: 4),
                const Text('tap a thread to see why it exists',
                    style: TextStyle(fontSize: 11, color: tx2)),
                const SizedBox(height: 8),
                for (final e in s.edges) _EdgeTile(s: s, e: e),
              ],
              // THE REPAIR ACT
              if (s.repair != null) ...[
                const SizedBox(height: 16),
                if (!repairing)
                  Semantics(
                    button: true,
                    label: s.repair!.label,
                    child: Material(
                      color: fern.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Haptics.tick();
                          Sfx.play('chime', volume: 0.4);
                          setState(() => repairing = true);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: ExcludeSemantics(
                            child: Row(children: [
                              const Text('🌱',
                                  style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(s.repair!.label,
                                    style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: ink)),
                              ),
                              const Icon(Icons.chevron_right,
                                  color: tx2, size: 18),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  )
                else ...[
                  Text('The ${s.repair!.label.toLowerCase()}',
                      style: serif(15)),
                  const SizedBox(height: 4),
                  Text(s.repair!.description,
                      style: const TextStyle(
                          fontSize: 12.5, height: 1.5, color: tx2)),
                  const SizedBox(height: 10),
                  _BandChart(
                      run: runRepair(s, option),
                      names: names,
                      title: 'continued from where it ended'),
                  const SizedBox(height: 10),
                  for (final m in s.repair!.moments)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('•  ${m.text}',
                          style: const TextStyle(
                              fontSize: 13,
                              height: 1.55,
                              color: ink)),
                    ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFFE3C2)
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(18)),
                    child: Text(s.repair!.epilogue,
                        style: const TextStyle(
                            fontSize: 13,
                            height: 1.6,
                            fontStyle: FontStyle.italic,
                            color: ink)),
                  ),
                ],
              ],
              // UNDER THE HOOD - what the model cannot do
              const SizedBox(height: 16),
              _HoodPanel(hood: s.hood),
              if (s.citation != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      color:
                          const Color(0xFFFFE3C2).withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.citation!,
                          style: const TextStyle(
                              fontSize: 12,
                              height: 1.55,
                              color: ink)),
                      if (s.citationUrl != null)
                        Semantics(
                          button: true,
                          label: 'Read the real story',
                          child: TextButton(
                            onPressed: () {
                              Haptics.tick();
                              launchUrl(Uri.parse(s.citationUrl!),
                                  mode:
                                      LaunchMode.externalApplication);
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
                'A model, honestly small: it shows directions, '
                'not destinies. The real web has a thousand '
                'threads we did not draw.',
                style: TextStyle(
                    fontSize: 10.5,
                    fontStyle: FontStyle.italic,
                    color: tx2),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EdgeTile extends StatefulWidget {
  final LabScenario s;
  final EcoEdge e;
  const _EdgeTile({required this.s, required this.e});

  @override
  State<_EdgeTile> createState() => _EdgeTileState();
}

class _EdgeTileState extends State<_EdgeTile> {
  bool open = false;

  @override
  Widget build(BuildContext context) {
    final from =
        widget.s.nodes.firstWhere((n) => n.id == widget.e.from);
    final to =
        widget.s.nodes.firstWhere((n) => n.id == widget.e.to);
    final sign = widget.e.w >= 0 ? 'feeds' : 'checks';
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Semantics(
        button: true,
        expanded: open,
        label: '${from.name} $sign ${to.name}. Tap for why.',
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Haptics.tick();
              setState(() => open = !open);
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(from.emoji,
                          style: const TextStyle(fontSize: 15)),
                      Text(
                          widget.e.w >= 0
                              ? '  ─▸  '
                              : '  ─┤  ',
                          style: TextStyle(
                              fontSize: 13,
                              color: widget.e.w >= 0
                                  ? fern
                                  : const Color(0xFFB07070))),
                      Text(to.emoji,
                          style: const TextStyle(fontSize: 15)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                            '${from.name} $sign ${to.name}',
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ink)),
                      ),
                      Icon(
                          open
                              ? Icons.expand_less
                              : Icons.expand_more,
                          size: 16,
                          color: tx2),
                    ]),
                    if (open) ...[
                      const SizedBox(height: 8),
                      Text(widget.e.why,
                          style: const TextStyle(
                              fontSize: 12.5,
                              height: 1.55,
                              color: ink)),
                      if (widget.e.cite != null) ...[
                        const SizedBox(height: 4),
                        Text(widget.e.cite!,
                            style: const TextStyle(
                                fontSize: 10.5,
                                fontStyle: FontStyle.italic,
                                color: tx2)),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HoodPanel extends StatefulWidget {
  final UnderHood hood;
  const _HoodPanel({required this.hood});

  @override
  State<_HoodPanel> createState() => _HoodPanelState();
}

class _HoodPanelState extends State<_HoodPanel> {
  bool open = false;

  @override
  Widget build(BuildContext context) {
    final h = widget.hood;
    return Semantics(
      button: true,
      expanded: open,
      label: 'Under the hood: what this model can and cannot do.',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Haptics.tick();
            setState(() => open = !open);
          },
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text('🔧', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text('Under the hood',
                            style: serif(14))),
                    Icon(open ? Icons.expand_less : Icons.expand_more,
                        size: 18, color: tx2),
                  ]),
                  if (open) ...[
                    const SizedBox(height: 10),
                    _hoodRow('What we know', h.know),
                    _hoodRow('What scientists estimate', h.estimate),
                    _hoodRow('What this model simplifies',
                        h.simplified),
                    _hoodRow('Where the uncertainty lives',
                        h.uncertain),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _hoodRow(String title, String body) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title.toUpperCase(),
                style: const TextStyle(
                    fontSize: 9.5, letterSpacing: 1.5, color: fern)),
            const SizedBox(height: 3),
            Text(body,
                style: const TextStyle(
                    fontSize: 12, height: 1.55, color: ink)),
          ],
        ),
      );
}

/// The band chart: lo..hi filled softly, mid drawn solid, real
/// observations as dots when provided.
class _BandChart extends StatelessWidget {
  final LabRun run;
  final List<(String, String)> names;
  final RealData? realData;
  final String? title;
  const _BandChart(
      {required this.run,
      required this.names,
      this.realData,
      this.title});

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
                height: 150,
                width: double.infinity,
                child: CustomPaint(
                    painter: _BandPainter(run, realData)),
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
                      color: _seriesColors[i % _seriesColors.length]),
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

class _BandPainter extends CustomPainter {
  final LabRun run;
  final RealData? realData;
  _BandPainter(this.run, this.realData);

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
      final color = _seriesColors[s % _seriesColors.length];
      final n = run.mid[s].length;
      if (n < 2) continue;
      double x(int i) => size.width * i / (n - 1);
      // the honest band: cautious..severe
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
      // the best-estimate line
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
    // what actually happened - drawn as ink dots
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
          final o = Offset(
              size.width * step / (n - 1), _y(size, v));
          canvas.drawCircle(o, 3.4, dot);
          canvas.drawCircle(o, 3.4, ring);
        }
      });
    }
  }

  @override
  bool shouldRepaint(_BandPainter old) =>
      old.run != run || old.realData != realData;
}
