// The Little Meadow - the kids' first Lab, running on the SAME
// engine as the adults' Meadow Web (LAB.md: one engine, four
// rooms). The constitution's hardest law governs the whole
// design: A CHILD CAN NEVER END IN THE RUINS. Whatever the
// child chooses, the final act is repair - tap the soft ground,
// plant the wild patch, watch the meadow answer - and the fable
// voice closes on recovery.
//
// No charts, no percentages, no timers, no scores, no scolds.
// Deterministic: the same choice tells the same story, because
// this is a book, not a slot machine.
//
// NARRATION: the lines below must exist BYTE-IDENTICAL in
// scripts/narrate.js (meadowLines) - the fable voice matches
// recordings by exact sentence. Until regenerated, they simply
// stay silent (fable or silence).

import 'package:flutter/material.dart';

import '../../../core/haptics.dart';
import '../../../core/kid_theme.dart';
import '../../../core/sfx.dart';
import '../../../data/lab.dart';
import '../../school/diorama.dart' show MeadowScene;

// the fable lines - keep in sync with scripts/narrate.js
const lmIntro =
    'This is the little meadow. The flowers feed the bees, the bees help the flowers, and everyone needs everyone.';
const lmAwayEarly =
    'The bees flew away, and the flowers made fewer seeds. Spring came up quieter.';
const lmAwayLate =
    'The rabbits found less to eat. Even the fox felt it, all the way at the end of the line.';
const lmStay =
    'The bees stayed, and the meadow hummed like a little engine of flowers.';
const lmInviteRepair =
    'Can you help the meadow come back? Tap the soft ground and plant a wild patch.';
const lmInviteRicher =
    'Want to make it even richer? Tap the soft ground and plant a wild patch.';
const lmGrowing =
    'Look - the flowers found the sun, and the bees found the flowers.';
const lmClosing =
    'The meadow came back because someone helped. Helpers change everything.';
const lmClosingStay =
    'The meadow grew even brighter because someone helped. Helpers change everything.';

const littleMeadowLines = [
  lmIntro,
  lmAwayEarly,
  lmAwayLate,
  lmStay,
  lmInviteRepair,
  lmInviteRicher,
  lmGrowing,
  lmClosing,
  lmClosingStay,
];

// where the soft ground waits for small gardeners
const _plantSpots = [
  (0.12, 0.75), (0.30, 0.87), (0.50, 0.78),
  (0.68, 0.86), (0.84, 0.74), (0.42, 0.93),
];

enum _Stage { meet, watching, planting, growing, done }

class LittleMeadow extends StatefulWidget {
  final void Function(String) speak;
  const LittleMeadow({super.key, required this.speak});

  @override
  State<LittleMeadow> createState() => _LittleMeadowState();
}

class _LittleMeadowState extends State<LittleMeadow>
    with SingleTickerProviderStateMixin {
  _Stage stage = _Stage.meet;
  bool beesAway = false; // the one thread a small hand can pull
  late final AnimationController _clock;
  final Set<int> planted = {};
  String caption = '';
  final Set<String> _spoken = {};

  late final LabScenario _meadow = labScenarioById('meadow')!;
  late final LabRun _stayRun = runBands(_meadow, 0);
  late final LabRun _awayRun = runBands(_meadow, 2);
  late final LabRun _repairAway = runRepair(_meadow, 2);
  late final LabRun _repairStay = runRepair(_meadow, 0);

  @override
  void initState() {
    super.initState();
    _clock = AnimationController(
        vsync: this, duration: const Duration(seconds: 13))
      ..addListener(_onTick);
    // the meadow introduces itself
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => _say(lmIntro));
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  void _say(String line) {
    if (_spoken.add(line)) widget.speak(line);
    setState(() => caption = line);
  }

  void _onTick() {
    setState(() {});
    final t = _clock.value;
    if (stage == _Stage.watching) {
      if (beesAway) {
        if (t > 0.25) _say(lmAwayEarly);
        if (t > 0.65) _say(lmAwayLate);
      } else {
        if (t > 0.3) _say(lmStay);
      }
      if (_clock.isCompleted) {
        stage = _Stage.planting;
        _say(beesAway ? lmInviteRepair : lmInviteRicher);
      }
    } else if (stage == _Stage.growing) {
      if (t > 0.35) _say(lmGrowing);
      if (_clock.isCompleted) {
        stage = _Stage.done;
        Sfx.play('chime', volume: 0.5);
        _say(beesAway ? lmClosing : lmClosingStay);
      }
    }
  }

  void _choose(bool away) {
    Haptics.tick();
    Sfx.play(away ? 'whoosh' : 'pop', volume: 0.4);
    setState(() {
      beesAway = away;
      stage = _Stage.watching;
    });
    _clock
      ..value = 0
      ..forward();
  }

  void _plant(int i) {
    if (planted.contains(i)) return;
    Haptics.tick();
    Sfx.play('drop', volume: 0.45);
    setState(() => planted.add(i));
    if (planted.length == _plantSpots.length) {
      Sfx.play('pop', volume: 0.5);
      setState(() => stage = _Stage.growing);
      _clock
        ..duration = const Duration(seconds: 10)
        ..value = 0
        ..forward();
    }
  }

  // which run and time the scene shows right now
  (LabRun, double, double) _scene() {
    final steps = 11.0;
    switch (stage) {
      case _Stage.meet:
        return (_stayRun, 0, 1.0);
      case _Stage.watching:
        return (
          beesAway ? _awayRun : _stayRun,
          _clock.value * steps,
          beesAway ? (1 - _clock.value).clamp(0, 1) * 0.9 : 1.0,
        );
      case _Stage.planting:
        return (beesAway ? _awayRun : _stayRun, steps,
            beesAway ? 0.1 : 1.0);
      case _Stage.growing:
      case _Stage.done:
        final t = stage == _Stage.done ? steps : _clock.value * steps;
        return (
          beesAway ? _repairAway : _repairStay,
          t,
          beesAway
              ? (0.15 + 0.7 * (t / steps)).clamp(0.0, 1.0)
              : 1.0,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (run, t, beeLevel) = _scene();
    return Scaffold(
      backgroundColor: kidCream,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(children: [
                KidSquish(
                  semanticLabel: 'Back to the games room',
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16)),
                    child: const Text('⬅️',
                        style: TextStyle(fontSize: 18)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                    child: Text('The little meadow',
                        style: kidTitle(20))),
              ]),
            ),
            const SizedBox(height: 10),
            // THE MEADOW ITSELF - the same living world the
            // grown-ups study, with soft ground for planting
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22)),
                padding: const EdgeInsets.all(10),
                child: Stack(children: [
                  MeadowScene(
                      run: run,
                      beeLevel: beeLevel,
                      t: t,
                      height: 210),
                  if (stage == _Stage.planting)
                    ...List.generate(_plantSpots.length, (i) {
                      final (fx, fy) = _plantSpots[i];
                      return Positioned.fill(
                        child: Align(
                          alignment: Alignment(
                              fx * 2 - 1, fy * 2 - 1),
                          child: KidSquish(
                            semanticLabel: planted.contains(i)
                                ? 'A seed is planted here'
                                : 'Soft ground - plant a seed',
                            onTap: () => _plant(i),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: planted.contains(i)
                                    ? Colors.transparent
                                    : const Color(0x66FFFFFF),
                                shape: BoxShape.circle,
                                border: planted.contains(i)
                                    ? null
                                    : Border.all(
                                        color: Colors.white,
                                        width: 2),
                              ),
                              child: Center(
                                child: Text(
                                    planted.contains(i)
                                        ? '🌱'
                                        : '🟤',
                                    style: const TextStyle(
                                        fontSize: 18)),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            // the fable's words, big and slow
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  children: [
                    if (caption.isNotEmpty)
                      Text(caption,
                          textAlign: TextAlign.center,
                          style: kidTitle(16,
                              color: kidInk)),
                    const Spacer(),
                    if (stage == _Stage.meet) ...[
                      Text('What should happen?',
                          style:
                              kidTitle(14, color: kidInkLight)),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                            child: _bigChoice('🐝',
                                'The bees stay', () =>
                                    _choose(false))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: _bigChoice('🌬️',
                                'The bees fly away', () =>
                                    _choose(true))),
                      ]),
                    ],
                    if (stage == _Stage.planting)
                      Padding(
                        padding:
                            const EdgeInsets.only(bottom: 6),
                        child: Text(
                            '${planted.length} of '
                            '${_plantSpots.length} seeds in the '
                            'ground',
                            style: kidTitle(13,
                                color: kidInkLight)),
                      ),
                    if (stage == _Stage.done)
                      KidSquish(
                        semanticLabel:
                            'Play the meadow again',
                        onTap: () {
                          Haptics.tick();
                          setState(() {
                            stage = _Stage.meet;
                            planted.clear();
                            _spoken.clear();
                            caption = '';
                            _clock
                              ..duration = const Duration(
                                  seconds: 13)
                              ..value = 0;
                          });
                          _say(lmIntro);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          decoration: BoxDecoration(
                              color: kidLeaf,
                              borderRadius:
                                  BorderRadius.circular(20)),
                          child: Text('🔁 Tell it again',
                              style: kidTitle(15)),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bigChoice(
      String emoji, String label, VoidCallback onTap) {
    return KidSquish(
      semanticLabel: label,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22)),
        child: Column(children: [
          Text(emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(height: 6),
          Text(label,
              textAlign: TextAlign.center,
              style: kidTitle(13)),
        ]),
      ),
    );
  }
}
