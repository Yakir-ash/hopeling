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
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/bench.dart';
import '../../data/lab.dart';
import 'classroom_bench.dart';
import 'diorama.dart';
import 'lab_chart.dart';
import 'two_bench.dart';

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
  double lever = 0.2; // the threshold hunt's slider, quantized
  // one guess per lever setting, remembered: predicting is a
  // greeting, not a toll booth - you never re-guess a lever you
  // have already answered. Slider scenarios guess once (-1).
  final Map<int, String> guesses = {};
  bool showData = false;
  bool repairing = false;

  int get _guessKey => widget.scenario.slider ? -1 : option;
  String? get guess => guesses[_guessKey];

  @override
  void initState() {
    super.initState();
    _loadGuesses();
  }

  Future<void> _loadGuesses() async {
    final p = await SharedPreferences.getInstance();
    final loaded = <int, String>{};
    for (var i = 0; i < widget.scenario.options.length; i++) {
      final g = p.getString('labGuess_${widget.scenario.id}_$i');
      if (g != null) loaded[i] = g;
    }
    final gs =
        p.getString('labGuess_${widget.scenario.id}_slider');
    if (gs != null) loaded[-1] = gs;
    if (mounted && loaded.isNotEmpty) {
      setState(() => guesses.addAll(loaded));
    }
  }

  String _direction(List<double> series) {
    final first = series.first, last = series.last;
    if (last > first + 0.05) return 'rises';
    if (last < first - 0.05) return 'falls';
    return 'holds';
  }

  void _chooseGuess(String g, LabRun run) {
    Haptics.tick();
    Sfx.play('drop', volume: 0.35);
    setState(() => guesses[_guessKey] = g);
    final suffix =
        widget.scenario.slider ? 'slider' : '$option';
    SharedPreferences.getInstance().then((p) => p.setString(
        'labGuess_${widget.scenario.id}_$suffix', g));
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scenario;
    final opt =
        s.slider ? leverAt(s, lever) : s.options[option];
    final run = runBandsWith(s, opt);
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
            if (s.slider) ...[
              // THE THRESHOLD HUNT: find the cliff yourself
              Semantics(
                slider: true,
                label: 'Fishing pressure, '
                    '${(lever * 100).round()} percent',
                child: Slider(
                  value: lever,
                  divisions: 20, // quantized: a book, not a
                  // slot machine - the same stop always yields
                  // the same sea
                  activeColor:
                      run.collapsed.isEmpty ? fern : const Color(0xFFB05B5B),
                  label: '${(lever * 100).round()}%',
                  onChanged: (v) {
                    if ((v - lever).abs() >= 0.049) {
                      Haptics.tick();
                    }
                    setState(() {
                      lever = (v * 20).round() / 20;
                      repairing = false;
                    });
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('gentle',
                      style: TextStyle(fontSize: 10.5, color: tx2)),
                  Text('find the cliff edge',
                      style: TextStyle(
                          fontSize: 10.5,
                          fontStyle: FontStyle.italic,
                          color: tx2)),
                  Text('relentless',
                      style: TextStyle(fontSize: 10.5, color: tx2)),
                ],
              ),
            ] else
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
                          repairing = false;
                          // a remembered lever keeps its guess
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
              if (hasScene(s.id)) ...[
                LabDiorama(
                    scenario: s, run: run, option: option),
                const SizedBox(height: 12),
              ],
              BandChart(
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
              // THE CLASSROOM BENCH - the same experiment, run
              // for a room instead of a person
              if (benchLessonFor(s.id) != null) ...[
                const SizedBox(height: 12),
                Semantics(
                  button: true,
                  label: 'Teach this one: the lesson plan and the '
                      'whole-room version.',
                  child: Material(
                    color: const Color(0xFFF3EAD8),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Haptics.tick();
                        Sfx.play('tick', volume: 0.3);
                        Navigator.of(context).push(risePush(
                            BenchSession(scenario: s)));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(13),
                        child: ExcludeSemantics(
                          child: Row(children: [
                            const Text('🧑‍🏫',
                                style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                  'Teach this one - the room '
                                  'predicts together, then every '
                                  'group\'s lever runs at once '
                                  '(${benchLessonFor(s.id)!.minutes} min)',
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: ink)),
                            ),
                            const Icon(Icons.chevron_right,
                                color: tx2, size: 18),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              // THE TWO BENCHES - the controlled experiment door
              if (!s.slider && s.options.length >= 2) ...[
                const SizedBox(height: 12),
                Semantics(
                  button: true,
                  label: 'Two benches: run two settings side by '
                      'side.',
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Haptics.tick();
                        Sfx.play('tick', volume: 0.3);
                        Navigator.of(context).push(risePush(
                            TwoBenchScreen(scenario: s)));
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(13),
                        child: ExcludeSemantics(
                          child: Row(children: [
                            Text('⚖️',
                                style: TextStyle(fontSize: 18)),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                  'Two benches - same world, one '
                                  'difference, side by side',
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: ink)),
                            ),
                            Icon(Icons.chevron_right,
                                color: tx2, size: 18),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
                  BandChart(
                      run: runRepairWith(s, opt),
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
