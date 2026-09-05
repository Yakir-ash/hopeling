// THE CLASSROOM BENCH - the Lab with thirty people in front of
// it (LAB.md section 8, SCHOOL.md's teacher door).
//
// Everything else we built assumes one person and one phone. A
// classroom inverts that: one screen, thirty guesses, and a
// teacher who has eleven minutes and cannot afford to be
// surprised by her own material. So the Bench runs the lesson,
// not the learner:
//
//   BRIEF    the sentence for the board, the honest running
//            time, and what the room usually says first
//   HANDS    the whole room predicts, out loud, counted in
//            public. Never a mark. A prediction is how a
//            scientist says hello, and thirty at once is just a
//            louder hello.
//   RUN      every group's lever runs at once, side by side, on
//            ONE clock - the controlled experiment as furniture
//   COMPARE  where the room stood, where the model stands, and
//            the disagreement named as the best possible result
//   DISCUSS  three prompts revealed one at a time, so nobody
//            reads ahead, with every thread of the web listed
//            underneath in case a child asks something sharp
//   CLOSE    the repair act, the hysteresis, and one sentence
//            left standing in the room
//
// The physics are not softened for the classroom, exactly as
// they are not softened for the children (little_meadow.dart).
// Same engine, same three honest runs, same thresholds. We only
// changed who is holding the question.

import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/sfx.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/bench.dart';
import '../../data/lab.dart';
import 'diorama.dart';
import 'lab_chart.dart';

/// The door: every experiment that carries a lesson plan.
class ClassroomBenchScreen extends StatelessWidget {
  const ClassroomBenchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: ink,
          title: Text('🧑‍🏫 The Classroom Bench', style: serif(18))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            const Text(
              'For the grown-up at the front of the room. Put this '
              'on the big screen: the room predicts together, the '
              'groups each pull a different lever, and every world '
              'runs at once on one clock. Nothing is scored and '
              'nobody is named.',
              style: TextStyle(fontSize: 13, height: 1.6, color: tx2),
            ),
            const SizedBox(height: 16),
            for (final (wing, scenarios) in labWings()) ...[
              Text(wing.toUpperCase(),
                  style: const TextStyle(
                      fontSize: 10.5, letterSpacing: 2, color: tx2)),
              const SizedBox(height: 8),
              for (final s in scenarios)
                if (benchLessonFor(s.id) != null)
                  _LessonTile(scenario: s, lesson: benchLessonFor(s.id)!),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 4),
            const Text(
              'Every plan was written by a person, including the '
              'part that admits what a room usually says first.',
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
}

class _LessonTile extends StatelessWidget {
  final LabScenario scenario;
  final BenchLesson lesson;
  const _LessonTile({required this.scenario, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        label: '${scenario.title}. ${lesson.board} '
            'About ${lesson.minutes} minutes.',
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Haptics.tick();
              Sfx.play('tick', volume: 0.3);
              Navigator.of(context).push(
                  risePush(BenchSession(scenario: scenario)));
            },
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: ExcludeSemantics(
                child: Row(children: [
                  Text(scenario.emoji,
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(scenario.title, style: serif(14.5)),
                        const SizedBox(height: 2),
                        Text(lesson.board,
                            style: const TextStyle(
                                fontSize: 11.5,
                                height: 1.4,
                                color: tx2)),
                        const SizedBox(height: 6),
                        Text(
                            '${lesson.minutes} min  ·  '
                            '${scenario.options.length} groups',
                            style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: fern)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: tx2, size: 20),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _Stage { brief, hands, run, compare, discuss, close }

class BenchSession extends StatefulWidget {
  final LabScenario scenario;
  const BenchSession({super.key, required this.scenario});

  @override
  State<BenchSession> createState() => _BenchSessionState();
}

class _BenchSessionState extends State<BenchSession>
    with SingleTickerProviderStateMixin {
  _Stage stage = _Stage.brief;
  final Map<String, int> hands = {
    for (final a in benchAnswers) a: 0
  };
  int card = 0;
  bool repairing = false;
  late final AnimationController _clock;

  LabScenario get s => widget.scenario;
  BenchLesson get lesson => benchLessonFor(s.id)!;
  int get _steps => s.steps;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
        vsync: this,
        duration: Duration(
            milliseconds: (_steps > 12 ? 380 : 850) * (_steps - 1)))
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  String _direction(List<double> series) {
    final first = series.first, last = series.last;
    if (last > first + 0.05) return 'rises';
    if (last < first - 0.05) return 'falls';
    return 'holds';
  }

  void _go(_Stage next) {
    Haptics.tick();
    Sfx.play('tick', volume: 0.3);
    setState(() => stage = next);
    if (next == _Stage.run) {
      _clock
        ..value = 0
        ..forward();
    }
  }

  void _togglePlay() {
    Haptics.tick();
    if (_clock.isAnimating) {
      _clock.stop();
    } else {
      if (_clock.value >= 0.999) _clock.value = 0;
      _clock.forward();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final runs = [
      for (var i = 0; i < s.options.length; i++) runBands(s, i)
    ];
    final names = s.seriesNames;
    final focus = names[s.predictIndex].$1;
    // the room's question is comparative: bench one is the
    // control, and every other bench is measured against it
    final modelWord = benchVerdict(
        runs[0].mid[s.predictIndex].last,
        runs[lesson.ask].mid[s.predictIndex].last);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        title: Text('${s.emoji} ${s.title}', style: serif(16)),
        actions: [
          if (stage != _Stage.brief)
            Semantics(
              button: true,
              label: 'Start this lesson over with a fresh room',
              child: IconButton(
                icon: const Icon(Icons.replay_rounded, size: 20),
                onPressed: () {
                  Haptics.tick();
                  setState(() {
                    stage = _Stage.brief;
                    card = 0;
                    repairing = false;
                    hands.updateAll((k, v) => 0);
                    _clock.value = 0;
                  });
                },
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 36),
          children: [
            _progress(),
            const SizedBox(height: 16),
            ...switch (stage) {
              _Stage.brief => _brief(),
              _Stage.hands => _hands(focus),
              _Stage.run => _run(runs, names),
              _Stage.compare =>
                _compare(runs, names, focus, modelWord),
              _Stage.discuss => _discuss(),
              _Stage.close => _close(names),
            },
          ],
        ),
      ),
    );
  }

  Widget _progress() {
    const labels = ['brief', 'hands', 'run', 'compare', 'discuss', 'close'];
    final at = _Stage.values.indexOf(stage);
    return Row(children: [
      for (var i = 0; i < labels.length; i++) ...[
        Expanded(
          child: Column(children: [
            Container(
              height: 3,
              decoration: BoxDecoration(
                  color: i <= at ? fern : const Color(0xFFE2E6E2),
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 4),
            Text(labels[i],
                style: TextStyle(
                    fontSize: 8.5,
                    letterSpacing: 0.5,
                    fontWeight:
                        i == at ? FontWeight.w800 : FontWeight.w400,
                    color: i == at ? fern : tx2)),
          ]),
        ),
        if (i < labels.length - 1) const SizedBox(width: 4),
      ],
    ]);
  }

  // ---------------- BRIEF ----------------
  List<Widget> _brief() => [
        Text('FOR THE BOARD',
            style: const TextStyle(
                fontSize: 10.5, letterSpacing: 2, color: tx2)),
        const SizedBox(height: 8),
        Text(lesson.board, style: serif(23, height: 1.35)),
        const SizedBox(height: 14),
        Row(children: [
          _stat('${lesson.minutes} min', 'start to last word'),
          const SizedBox(width: 10),
          _stat('${s.options.length} groups', 'one lever each'),
          const SizedBox(width: 10),
          _stat('0 marks', 'nothing is scored'),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: const Color(0xFFF3EAD8),
              borderRadius: BorderRadius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('WHAT THE ROOM USUALLY SAYS FIRST',
                  style: TextStyle(
                      fontSize: 10, letterSpacing: 1.6, color: tx2)),
              const SizedBox(height: 8),
              Text(lesson.misconception,
                  style: const TextStyle(
                      fontSize: 13.5, height: 1.6, color: ink)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('The groups', style: serif(15)),
        const SizedBox(height: 4),
        Text(
            'Same world, same equations, one difference each. That '
            'is the whole shape of a controlled experiment, and '
            'the room can see it without being told.',
            style: const TextStyle(fontSize: 12, height: 1.5, color: tx2)),
        const SizedBox(height: 10),
        for (var i = 0; i < s.options.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: seriesColors[i % seriesColors.length]
                        .withValues(alpha: 0.18),
                    shape: BoxShape.circle),
                child: Text('${i + 1}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: ink)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(s.options[i].label,
                    style: const TextStyle(
                        fontSize: 13.5, height: 1.4, color: ink)),
              ),
            ]),
          ),
        const SizedBox(height: 8),
        _bigButton('Begin: the show of hands', '✋',
            () => _go(_Stage.hands)),
      ];

  Widget _stat(String big, String small) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16)),
          child: Column(children: [
            Text(big,
                style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: ink)),
            const SizedBox(height: 2),
            Text(small,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 9.5, color: tx2)),
          ]),
        ),
      );

  // ---------------- HANDS ----------------
  List<Widget> _hands(String focus) {
    final total = hands.values.fold<int>(0, (a, b) => a + b);
    final span = s.steps > 12 ? 'twenty five years' : 'three years';
    return [
      const Text('THE WHOLE ROOM PREDICTS',
          style: TextStyle(
              fontSize: 10.5, letterSpacing: 2, color: tx2)),
      const SizedBox(height: 8),
      Text(
          'After $span, where does $focus finish under '
          '"${s.options[lesson.ask].label}" compared with bench '
          'one, "${s.options[0].label}"?',
          style: serif(21, height: 1.35)),
      const SizedBox(height: 6),
      const Text(
          'Read it aloud, then count the hands. Tap once per hand.',
          style: TextStyle(fontSize: 12, height: 1.5, color: tx2)),
      const SizedBox(height: 16),
      for (final k in benchAnswers)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Semantics(
            button: true,
            label: '$focus, $k. ${hands[k]} hands counted. '
                'Tap to add one.',
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Haptics.tick();
                  Sfx.play('drop', volume: 0.25);
                  setState(() => hands[k] = hands[k]! + 1);
                },
                onLongPress: () {
                  Haptics.tick();
                  setState(() {
                    final v = hands[k]! - 1;
                    hands[k] = v < 0 ? 0 : v;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 20),
                  child: ExcludeSemantics(
                    child: Row(children: [
                      Expanded(
                        child: Text('$focus: $k', style: serif(18)),
                      ),
                      Text('${hands[k]}',
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: fern)),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        ),
      const Text(
          'Long-press a row to take one back. No names, no marks, '
          'no record kept: a guess is how a scientist says hello '
          'to a question, and thirty at once is a louder hello.',
          style: TextStyle(fontSize: 11, height: 1.5, color: tx2)),
      const SizedBox(height: 16),
      _bigButton(
          total == 0
              ? 'Run it without counting'
              : 'Run all ${s.options.length} benches at once',
          '▶️',
          () => _go(_Stage.run)),
    ];
  }

  // ---------------- RUN ----------------
  List<Widget> _run(List<LabRun> runs, List<(String, String)> names) {
    final t = _clock.value * (_steps - 1);
    final living = hasScene(s.id);
    final n = s.options.length;
    final h = living ? (n >= 3 ? 92.0 : 132.0) : (n >= 3 ? 78.0 : 104.0);
    final label = s.steps > 12
        ? 'year ${t.round() + 1} of $_steps'
        : 'season ${t.round() + 1} of $_steps';
    return [
      const Text('ONE CLOCK, EVERY BENCH',
          style: TextStyle(
              fontSize: 10.5, letterSpacing: 2, color: tx2)),
      const SizedBox(height: 8),
      Text(s.question, style: serif(18, height: 1.35)),
      const SizedBox(height: 14),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < n; i++) ...[
            Expanded(child: _pane(i, runs[i], names, t, living, h)),
            if (i < n - 1) const SizedBox(width: 8),
          ],
        ],
      ),
      const SizedBox(height: 10),
      Row(children: [
        Semantics(
          button: true,
          label: _clock.isAnimating
              ? 'Pause every bench'
              : 'Play every bench together',
          child: IconButton(
            icon: Icon(
                _clock.isAnimating
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: fern),
            onPressed: _togglePlay,
          ),
        ),
        Expanded(
          child: Slider(
            value: _clock.value,
            activeColor: fern,
            onChanged: (v) {
              _clock.stop();
              setState(() => _clock.value = v);
            },
          ),
        ),
        Text(label,
            style: const TextStyle(fontSize: 11, color: tx2)),
      ]),
      const Text(
          'One clock drives every world on this screen. The only '
          'thing that differs between them is the lever, which is '
          'the entire definition of a controlled experiment.',
          style: TextStyle(fontSize: 11, height: 1.5, color: tx2)),
      const SizedBox(height: 16),
      _bigButton('Stop the clock and compare', '⚖️',
          () => _go(_Stage.compare)),
    ];
  }

  Widget _pane(int i, LabRun run, List<(String, String)> names,
      double t, bool living, double h) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: seriesColors[i % seriesColors.length]
                    .withValues(alpha: 0.18),
                shape: BoxShape.circle),
            child: Text('${i + 1}',
                style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: ink)),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(s.options[i].label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 9.5, height: 1.25, color: tx2)),
          ),
        ]),
        const SizedBox(height: 5),
        if (living)
          labScene(s, run, i, t, height: h)
        else
          BandChart(run: run, names: names, height: h),
      ],
    );
  }

  // ---------------- COMPARE ----------------
  List<Widget> _compare(List<LabRun> runs,
      List<(String, String)> names, String focus, String modelWord) {
    final total = hands.values.fold<int>(0, (a, b) => a + b);
    return [
      const Text('WHERE THE ROOM STOOD',
          style: TextStyle(
              fontSize: 10.5, letterSpacing: 2, color: tx2)),
      const SizedBox(height: 4),
      Text(
          '$focus under "${s.options[lesson.ask].label}", against '
          'bench one',
          style: const TextStyle(fontSize: 11.5, color: tx2)),
      const SizedBox(height: 10),
      for (final k in benchAnswers)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            SizedBox(
              width: 96,
              child: Text(k,
                  style: const TextStyle(fontSize: 12.5, color: ink)),
            ),
            Expanded(
              child: Stack(children: [
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                      color: const Color(0xFFECEFEC),
                      borderRadius: BorderRadius.circular(8)),
                ),
                FractionallySizedBox(
                  widthFactor:
                      total == 0 ? 0.0 : hands[k]! / total,
                  child: Container(
                    height: 16,
                    decoration: BoxDecoration(
                        color: k == modelWord
                            ? fern
                            : fern.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 8),
            SizedBox(
                width: 26,
                child: Text('${hands[k]}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: ink))),
          ]),
        ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: mint.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(20)),
        child: Text(roomVerdict(hands, modelWord, focus),
            style: const TextStyle(
                fontSize: 13.5, height: 1.6, color: ink)),
      ),
      const SizedBox(height: 18),
      Text('Every bench, after the years', style: serif(15)),
      const SizedBox(height: 8),
      for (var i = 0; i < s.options.length; i++)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'GROUP ${i + 1}  ·  ${s.options[i].label}'
                  '${i == 0 ? "  ·  THE CONTROL" : ""}'
                  '${i == lesson.ask ? "  ·  THE ROOM ASKED ABOUT THIS ONE" : ""}',
                  style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: fern)),
              const SizedBox(height: 6),
              Text(
                  '$focus: ${_direction(runs[i].mid[s.predictIndex])}, '
                  'ending near '
                  '${(runs[i].mid[s.predictIndex].last * 100).round()} '
                  'on the model\'s 0 to 100 scale.',
                  style: const TextStyle(
                      fontSize: 12.5, height: 1.5, color: ink)),
              if (runs[i].collapsed.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                      'A threshold was crossed here: '
                      '${runs[i].collapsed.map((id) => s.nodes.firstWhere((n) => n.id == id).name.toLowerCase()).join(", ")} '
                      'fell below the line where the old recovery '
                      'physics stop applying.',
                      style: const TextStyle(
                          fontSize: 11.5,
                          height: 1.5,
                          color: Color(0xFF8A4B4B))),
                ),
            ],
          ),
        ),
      const SizedBox(height: 4),
      const Text(
          'Numbers are the model\'s own scale, best-estimate run. '
          'The benches never disagree about the world: only the '
          'levers differ.',
          style: TextStyle(fontSize: 10.5, color: tx2)),
      const SizedBox(height: 16),
      _bigButton('Open the discussion', '💬',
          () => _go(_Stage.discuss)),
    ];
  }

  // ---------------- DISCUSS ----------------
  List<Widget> _discuss() {
    const kinds = ['NOTICE', 'EXPLAIN', 'CARRY IT OUTSIDE'];
    return [
      Text('QUESTION ${card + 1} OF ${lesson.discuss.length}  ·  '
          '${kinds[card % kinds.length]}',
          style: const TextStyle(
              fontSize: 10.5, letterSpacing: 1.6, color: tx2)),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22)),
        child: Text(lesson.discuss[card], style: serif(20, height: 1.4)),
      ),
      const SizedBox(height: 14),
      if (card < lesson.discuss.length - 1)
        _bigButton('Next question', '➡️', () {
          Haptics.tick();
          Sfx.play('flip', volume: 0.3);
          setState(() => card++);
        })
      else
        _bigButton('Close the lesson', '🌱', () => _go(_Stage.close)),
      const SizedBox(height: 20),
      if (s.edges.isNotEmpty) ...[
        Text('If somebody asks', style: serif(15)),
        const SizedBox(height: 4),
        const Text(
            'every thread in this model, in plain words, so a '
            'sharp question never has to wait for a lesson plan',
            style: TextStyle(fontSize: 11, height: 1.5, color: tx2)),
        const SizedBox(height: 8),
        for (final e in s.edges)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    '${s.nodes.firstWhere((n) => n.id == e.from).emoji} '
                    '${e.w >= 0 ? "feeds" : "checks"} '
                    '${s.nodes.firstWhere((n) => n.id == e.to).emoji}  '
                    '${s.nodes.firstWhere((n) => n.id == e.from).name} '
                    '${e.w >= 0 ? "feeds" : "checks"} '
                    '${s.nodes.firstWhere((n) => n.id == e.to).name.toLowerCase()}',
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: ink)),
                const SizedBox(height: 5),
                Text(e.why,
                    style: const TextStyle(
                        fontSize: 12, height: 1.5, color: tx2)),
              ],
            ),
          ),
      ],
      const SizedBox(height: 8),
      _hoodLine('What we know', s.hood.know),
      _hoodLine('What this model simplifies', s.hood.simplified),
      _hoodLine('Where the uncertainty lives', s.hood.uncertain),
    ];
  }

  Widget _hoodLine(String title, String body) => Padding(
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
                    fontSize: 11.5, height: 1.55, color: tx2)),
          ],
        ),
      );

  // ---------------- CLOSE ----------------
  List<Widget> _close(List<(String, String)> names) {
    final askOpt = s.options[lesson.ask];
    return [
      if (s.repair != null) ...[
        Text('The repair, in front of them', style: serif(16)),
        const SizedBox(height: 4),
        Text(s.repair!.description,
            style: const TextStyle(
                fontSize: 12.5, height: 1.5, color: tx2)),
        const SizedBox(height: 10),
        if (!repairing)
          _bigButton(s.repair!.label, '🌱', () {
            Haptics.tick();
            Sfx.play('chime', volume: 0.4);
            setState(() => repairing = true);
          })
        else ...[
          BandChart(
              run: runRepairWith(s, askOpt),
              names: names,
              title: 'continued from where it ended'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: const Color(0xFFFFE3C2).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(18)),
            child: Text(s.repair!.epilogue,
                style: const TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    fontStyle: FontStyle.italic,
                    color: ink)),
          ),
        ],
        const SizedBox(height: 20),
      ],
      const Text('LEAVE THIS ONE STANDING',
          style: TextStyle(
              fontSize: 10.5, letterSpacing: 2, color: tx2)),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
            color: mint.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(22)),
        child: Text(lesson.closing, style: serif(21, height: 1.4)),
      ),
      const SizedBox(height: 16),
      const Text(
          'Nothing was scored, nobody was named, and no hand '
          'counted here was ever saved. What the room keeps is '
          'the argument it had.',
          style: TextStyle(fontSize: 11.5, height: 1.55, color: tx2)),
      const SizedBox(height: 16),
      _bigButton('Run it again with a fresh room', '🔁', () {
        Haptics.tick();
        setState(() {
          stage = _Stage.brief;
          card = 0;
          repairing = false;
          hands.updateAll((k, v) => 0);
          _clock.value = 0;
        });
      }),
    ];
  }

  Widget _bigButton(String label, String emoji, VoidCallback onTap) =>
      Semantics(
        button: true,
        label: label,
        child: Material(
          color: fern,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 17),
              child: ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Text(label,
                        style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
