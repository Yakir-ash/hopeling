// The Migration - "my little world came with me."
// Everything is ALREADY saved to disk before this screen appears; this is
// pure celebration, skippable at any moment, losing nothing if killed.

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../data/rules.dart' as rules;
import '../grove/tree.dart';

class MigrationScreen extends StatefulWidget {
  final dynamic save; // Save; dynamic import avoided for test simplicity
  const MigrationScreen({super.key, required this.save});

  @override
  State<MigrationScreen> createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<MigrationScreen> {
  int step = 0;
  int shownStage = 0;
  Timer? timer;
  final TreePulse pulse = TreePulse();

  int get finalStage =>
      rules.painterStage(rules.stageIdx(widget.save.streak as int));
  List<String> get badges {
    final b = widget.save.extra['badges'];
    if (b is Map) return b.keys.map((e) => e.toString()).take(8).toList();
    return [];
  }

  bool get hasGuardian => widget.save.extra['guardian'] != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Motion.reduced(context)) {
        setState(() {
          step = 99;
          shownStage = finalStage;
        });
        return;
      }
      timer = Timer.periodic(const Duration(milliseconds: 850), (_) => _next());
    });
  }

  void _next() {
    if (!mounted) return;
    setState(() {
      step++;
      if (shownStage < finalStage) {
        shownStage++;
        pulse.breathe();
        Haptics.settle();
      }
    });
    if (step > finalStage + 4) {
      timer?.cancel();
    }
  }

  void _skip() {
    timer?.cancel();
    setState(() {
      step = 99;
      shownStage = finalStage;
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.save;
    final done = step > finalStage + 3 || step == 99;
    final rows = <Widget>[];

    // Reveal order: streak, drops, badges, guardian - each after the tree.
    final revealBase = finalStage + 1;
    if (step >= revealBase || step == 99) {
      rows.add(_line('🔥', '${s.streak} days kept. Every one of them counted.'));
    }
    if (step >= revealBase + 1 || step == 99) {
      rows.add(_line('💧', '${s.xp} drops of rain, yours.'));
    }
    if ((step >= revealBase + 2 || step == 99) && badges.isNotEmpty) {
      rows.add(Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Wrap(
          spacing: 10,
          alignment: WrapAlignment.center,
          children: badges
              .map((b) => Text(b, style: const TextStyle(fontSize: 26)))
              .toList(),
        ),
      ));
    }
    if ((step >= revealBase + 3 || step == 99) && hasGuardian) {
      rows.add(_line('🛡', 'Your guardian is still under your watch.'));
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: skyColors(DateTime.now().hour),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  onPressed: _skip,
                  child:
                      const Text('skip', style: TextStyle(color: tx2)),
                ),
              ),
              const Spacer(),
              Text('Welcome home.', style: serif(30)),
              const SizedBox(height: 6),
              const Text('Your little world came with you.',
                  style: TextStyle(fontSize: 14, color: tx2)),
              const SizedBox(height: 26),
              TreeView(
                  stage: shownStage,
                  pulse: pulse,
                  still: Motion.still(context),
                  size: 170),
              const SizedBox(height: 6),
              Text(stageName(shownStage),
                  style: serif(16, weight: FontWeight.w500)),
              const SizedBox(height: 18),
              AnimatedOpacity(
                opacity: rows.isEmpty ? 0 : 1,
                duration: Motion.rise,
                child: Column(children: rows),
              ),
              const Spacer(),
              AnimatedOpacity(
                opacity: done ? 1 : 0,
                duration: Motion.rise,
                child: Padding(
                  padding: EdgeInsets.only(
                      left: 24,
                      right: 24,
                      bottom: 24 + MediaQuery.of(context).padding.bottom),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: fern,
                        foregroundColor: paper,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(Corners.button)),
                      ),
                      onPressed: done
                          ? () => Navigator.of(context)
                              .popUntil((r) => r.isFirst)
                          : null,
                      child: const Text("Today's action is waiting →",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(String emo, String text) => Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emo, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: ink)),
            ),
          ],
        ),
      );
}
