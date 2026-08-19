// The Two Benches - the concept of a controlled experiment,
// turned into an interface (LAB.md section 8). Same ecosystem,
// two lever settings, side by side, one shared clock. For the
// meadow the benches are living dioramas breathing in sync; for
// every other scenario, twin band charts. The verdict below
// speaks the difference plainly.

import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../data/lab.dart';
import 'diorama.dart';
import 'lab_chart.dart';

class TwoBenchScreen extends StatefulWidget {
  final LabScenario scenario;
  const TwoBenchScreen({super.key, required this.scenario});

  @override
  State<TwoBenchScreen> createState() => _TwoBenchScreenState();
}

class _TwoBenchScreenState extends State<TwoBenchScreen>
    with SingleTickerProviderStateMixin {
  late int a = 0;
  late int b = widget.scenario.options.length - 1;
  late final AnimationController _clock;

  int get _steps => widget.scenario.steps;

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
        vsync: this,
        duration: Duration(
            milliseconds:
                (widget.scenario.steps > 12 ? 350 : 800) *
                    (_steps - 1)))
      ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
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
    final s = widget.scenario;
    final runA = runBands(s, a);
    final runB = runBands(s, b);
    final t = _clock.value * (_steps - 1);
    final living = hasScene(s.id);
    final names = s.seriesNames;
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: ink,
          title: Text('⚖️ Two benches', style: serif(18))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            Text(s.title, style: serif(16)),
            const SizedBox(height: 4),
            const Text(
              'Same world, one difference - which is the whole '
              'idea of a controlled experiment.',
              style: TextStyle(fontSize: 12, height: 1.5, color: tx2),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: _benchColumn('BENCH A', a, runA,
                        living, t, (i) => setState(() => a = i))),
                const SizedBox(width: 10),
                Expanded(
                    child: _benchColumn('BENCH B', b, runB,
                        living, t, (i) => setState(() => b = i))),
              ],
            ),
            if (living) ...[
              const SizedBox(height: 8),
              Row(children: [
                Semantics(
                  button: true,
                  label: _clock.isAnimating
                      ? 'Pause both benches'
                      : 'Play both benches together',
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
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
              ]),
              const Text(
                'one clock drives both worlds - the only thing '
                'that differs is the lever',
                style: TextStyle(
                    fontSize: 10.5,
                    fontStyle: FontStyle.italic,
                    color: tx2),
              ),
            ],
            const SizedBox(height: 14),
            Text('The verdict, after the years', style: serif(15)),
            const SizedBox(height: 8),
            for (var i = 0; i < names.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                    '${names[i].$2} ${names[i].$1}: '
                    '${(runA.mid[i].last * 100).round()} on bench '
                    'A, ${(runB.mid[i].last * 100).round()} on '
                    'bench B',
                    style: const TextStyle(
                        fontSize: 12.5, height: 1.5, color: ink)),
              ),
            const SizedBox(height: 4),
            const Text(
              'Numbers are the model\'s 0-100 scale, best-estimate '
              'run. The benches never disagree about the world - '
              'only the levers differ.',
              style: TextStyle(fontSize: 10.5, color: tx2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _benchColumn(String label, int opt, LabRun run,
      bool living, double t, void Function(int) onPick) {
    final s = widget.scenario;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10, letterSpacing: 2, color: tx2)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < s.options.length; i++)
              ChoiceChip(
                label: Text(s.options[i].label,
                    style: const TextStyle(fontSize: 10)),
                selected: opt == i,
                selectedColor: mint,
                visualDensity: VisualDensity.compact,
                onSelected: (_) {
                  Haptics.tick();
                  onPick(i);
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (living)
          labScene(s, run, opt, t, height: 130)
        else
          BandChart(
              run: run,
              names: s.seriesNames,
              height: 110),
      ],
    );
  }
}
