// The Noticing Walk, staged: choose where you are, then Pause (a dark
// breathing screen, twenty seconds, the phone bows out), Observe (one
// sensory prompt), Wonder (one prediction), Reveal (a quiet cinematic
// meeting - never a confetti explosion), Remember (the hook that works
// without the app, and a door to the journal). No sensors anywhere:
// the child's ears and eyes do all the noticing.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../data/explorer.dart';
import 'journal_screen.dart';

class ExplorerScreen extends StatefulWidget {
  final String kidId;
  final void Function(String) speak;
  final void Function(String) onMet; // adds to the child's discoveries
  const ExplorerScreen(
      {super.key,
      required this.kidId,
      required this.speak,
      required this.onMet});

  @override
  State<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends State<ExplorerScreen>
    with SingleTickerProviderStateMixin {
  int stage = 0; // 0 where, 1 pause, 2 observe, 3 wonder, 4 reveal, 5 remember
  Habitat? habitat;
  int observeChoice = 0;
  int wonderChoice = 0;
  int pauseLeft = 20;
  Timer? pauseTimer;
  late final AnimationController breath = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 4000));

  @override
  void dispose() {
    pauseTimer?.cancel();
    breath.dispose();
    super.dispose();
  }

  void _startPause() {
    setState(() {
      stage = 1;
      pauseLeft = Motion.still(context) ? 8 : 20;
    });
    widget.speak(WalkCopy.pause);
    if (!Motion.still(context)) breath.repeat(reverse: true);
    pauseTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => pauseLeft--);
      if (pauseLeft <= 0) {
        t.cancel();
        breath.stop();
        Haptics.settle();
        _toObserve();
      }
    });
  }

  void _toObserve() {
    final h = habitat!;
    final prompt =
        h.observePrompts[observeChoice % h.observePrompts.length];
    setState(() => stage = 2);
    widget.speak(prompt);
  }

  WalkAnimal get _animal =>
      revealFor(habitat!, observeChoice, wonderChoice);

  @override
  Widget build(BuildContext context) {
    if (stage == 1) return _pauseScreen();
    return Scaffold(
      backgroundColor: const Color(0xFFF2F8EF),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
          children: [
            Row(children: [
              Expanded(child: Text(WalkCopy.door, style: serif(20))),
              IconButton(
                  tooltip: 'Close the walk',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: tx2, size: 20)),
            ]),
            const SizedBox(height: 8),
            ..._stageBody(),
          ],
        ),
      ),
    );
  }

  List<Widget> _stageBody() {
    switch (stage) {
      case 0:
        return [
          Text('Where are you right now?', style: serif(17)),
          const SizedBox(height: 6),
          const Text(
              'You tell me - I never need to know more than that.',
              style: TextStyle(fontSize: 12.5, color: tx2)),
          const SizedBox(height: 14),
          for (final h in habitats)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Haptics.tick();
                    habitat = h;
                    observeChoice =
                        DateTime.now().day % h.observePrompts.length;
                    _startPause();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(children: [
                      Text(h.emo, style: const TextStyle(fontSize: 26)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(h.name,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600))),
                    ]),
                  ),
                ),
              ),
            ),
        ];
      case 2:
        final h = habitat!;
        return [
          Text('👀 Observe', style: serif(17)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20)),
            child: Text(
                h.observePrompts[observeChoice % h.observePrompts.length],
                style: serif(18, height: 1.5)),
          ),
          const SizedBox(height: 14),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: fern, foregroundColor: paper),
            onPressed: () {
              Haptics.tick();
              setState(() => stage = 3);
              widget.speak(wonderFor().$1);
            },
            child: const Text('I noticed something!'),
          ),
          TextButton(
            onPressed: () {
              setState(() => observeChoice++);
              _toObserve();
            },
            child: const Text('Give me a different thing to notice',
                style: TextStyle(fontSize: 12.5, color: tx2)),
          ),
        ];
      case 3:
        final (q, opts) = wonderFor();
        return [
          Text('💭 Wonder', style: serif(17)),
          const SizedBox(height: 10),
          Text(q, style: serif(18, height: 1.4)),
          const SizedBox(height: 14),
          for (var i = 0; i < opts.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Haptics.tick();
                    wonderChoice = i;
                    setState(() => stage = 4);
                    widget.speak(WalkCopy.reveal(_animal, habitat!));
                    widget.onMet(_animal.name);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(opts[i],
                        style: const TextStyle(fontSize: 15)),
                  ),
                ),
              ),
            ),
          const Text('There is no wrong guess - wondering IS the game.',
              style: TextStyle(
                  fontSize: 12, fontStyle: FontStyle.italic, color: tx2)),
        ];
      case 4:
        final a = _animal;
        return [
          // the quiet cinematic reveal - no confetti, a slow arrival
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(
                milliseconds: Motion.still(context) ? 1 : 1600),
            curve: Curves.easeOut,
            builder: (_, v, child) =>
                Opacity(opacity: v, child: child),
            child: Column(children: [
              const SizedBox(height: 18),
              Text(a.emo, style: const TextStyle(fontSize: 84)),
              const SizedBox(height: 14),
              Text(a.name, style: serif(24)),
              const SizedBox(height: 12),
              Text(WalkCopy.reveal(a, habitat!),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14.5, height: 1.6, color: tx2)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18)),
                child: Text('🌿 ${a.detail}',
                    style: const TextStyle(fontSize: 13.5, height: 1.55)),
              ),
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: fern, foregroundColor: paper),
                onPressed: () {
                  Haptics.tick();
                  setState(() => stage = 5);
                  widget.speak(WalkCopy.remember(a));
                },
                child: const Text('Tell me the secret →'),
              ),
            ]),
          ),
        ];
      default:
        final a = _animal;
        return [
          Text('🧠 Remember', style: serif(17)),
          const SizedBox(height: 10),
          Text(WalkCopy.remember(a),
              style: serif(17, height: 1.5)),
          const SizedBox(height: 14),
          const Text(WalkCopy.guest,
              style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                  color: tx2)),
          const SizedBox(height: 18),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: fern, foregroundColor: paper),
            onPressed: () {
              Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (_) => JournalPage(
                      kidId: widget.kidId, speak: widget.speak)));
            },
            child: const Text(WalkCopy.drawIt),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(WalkCopy.end,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: tx2)),
          ),
        ];
    }
  }

  Widget _pauseScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFF141C36),
      body: Semantics(
        label: WalkCopy.pauseA11y,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ExcludeSemantics(
                  child: AnimatedBuilder(
                    animation: breath,
                    builder: (_, __) => Container(
                      width: 90 +
                          30 * Curves.easeInOut.transform(breath.value),
                      height: 90 +
                          30 * Curves.easeInOut.transform(breath.value),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFFF6EFC1)
                                .withValues(alpha: 0.6),
                            width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40),
                  child: Text(WalkCopy.pause,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14,
                          height: 1.7,
                          color: Color(0xFF8B93B4))),
                ),
                const SizedBox(height: 20),
                ExcludeSemantics(
                  child: Text('$pauseLeft',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF56659B))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
