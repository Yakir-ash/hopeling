// This Week's Mystery - the week tells a whodunit, one clue per
// weekday. Guess whenever you like; a wrong guess is a shorter
// path to a good story, and the reveal always teaches the skill
// that solves it. Nothing expires. The mystery waits.

import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/sfx.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/almanac.dart';
import '../../data/fieldguide.dart';
import '../../data/mysteries.dart';
import '../atlas/atlas_screen.dart';

class MysteryScreen extends StatefulWidget {
  const MysteryScreen({super.key});

  @override
  State<MysteryScreen> createState() => _MysteryScreenState();
}

class _MysteryScreenState extends State<MysteryScreen> {
  late final Mystery m = mysteryOfWeek(DateTime.now());
  int? guess;
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    FieldGuide.mysteryGuess(m.id).then((g) {
      if (mounted) {
        setState(() {
          guess = g;
          loaded = true;
        });
      }
    });
  }

  Future<void> _choose(int i) async {
    await FieldGuide.setMysteryGuess(m.id, i);
    Haptics.settle();
    Sfx.play(i == m.answer ? 'chime' : 'drop', volume: 0.6);
    if (mounted) setState(() => guess = i);
  }

  @override
  Widget build(BuildContext context) {
    final open = cluesOpen(DateTime.now());
    final guessed = guess != null;
    final sp = m.speciesId == null ? null : atlasById(m.speciesId!);
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: ink,
          title: Text('🔍 This week\'s mystery', style: serif(18))),
      body: SafeArea(
        child: !loaded
            ? const SizedBox.shrink()
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                children: [
                  Text('${m.emoji} ${m.title}', style: serif(20)),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22)),
                    child: Text(m.scene,
                        style: const TextStyle(
                            fontSize: 14, height: 1.65, color: ink)),
                  ),
                  const SizedBox(height: 14),
                  Text('The clues so far', style: serif(15)),
                  const SizedBox(height: 8),
                  for (var i = 0; i < m.clues.length; i++)
                    if (i < open || guessed)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: mint.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text('${i + 1}.',
                                style: serif(13)),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(m.clues[i],
                                    style: const TextStyle(
                                        fontSize: 13,
                                        height: 1.55,
                                        color: ink))),
                          ],
                        ),
                      )
                    else
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color:
                                    tx2.withValues(alpha: 0.2))),
                        child: Text(
                            '${i + 1}. arrives ${_dayName(i + 1)} - '
                            'the mystery is patient',
                            style: const TextStyle(
                                fontSize: 12, color: tx2)),
                      ),
                  const SizedBox(height: 10),
                  Text(guessed ? 'The verdict' : 'Who did it?',
                      style: serif(15)),
                  const SizedBox(height: 8),
                  for (var i = 0; i < m.suspects.length; i++)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: !guessed
                            ? Colors.white
                            : i == m.answer
                                ? mint.withValues(alpha: 0.5)
                                : guess == i
                                    ? gold.withValues(alpha: 0.2)
                                    : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap:
                              guessed ? null : () => _choose(i),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(children: [
                              Expanded(
                                  child: Text(m.suspects[i],
                                      style: const TextStyle(
                                          fontSize: 13.5,
                                          height: 1.5,
                                          color: ink))),
                              if (guessed && i == m.answer)
                                Semantics(
                                    label: 'the true answer',
                                    child: const ExcludeSemantics(
                                        child: Text('🍃'))),
                              if (guessed &&
                                  guess == i &&
                                  i != m.answer)
                                Semantics(
                                    label: 'your guess',
                                    child: const ExcludeSemantics(
                                        child: Text('🤔'))),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  if (guessed) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              guess == m.answer
                                  ? '🔍 Solved.'
                                  : '🔍 The real story:',
                              style: serif(15)),
                          const SizedBox(height: 8),
                          Text(m.reveal,
                              style: const TextStyle(
                                  fontSize: 13.5,
                                  height: 1.65,
                                  color: ink)),
                          const SizedBox(height: 10),
                          Text('What this one taught: ${m.lesson}',
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  height: 1.55,
                                  fontStyle: FontStyle.italic,
                                  color: tx2)),
                        ],
                      ),
                    ),
                    if (sp != null) ...[
                      const SizedBox(height: 10),
                      Material(
                        color: mint.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            Haptics.tick();
                            FieldGuide.meet(sp.id);
                            Navigator.of(context).push(
                                risePush(AtlasPage(species: sp)));
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(children: [
                              Text(sp.emoji,
                                  style: const TextStyle(
                                      fontSize: 22)),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(
                                      'A witness lives in the '
                                      'Living Atlas - visit '
                                      '${sp.name}\'s page',
                                      style: const TextStyle(
                                          fontSize: 12.5,
                                          color: ink))),
                              const Icon(Icons.chevron_right,
                                  size: 18, color: tx2),
                            ]),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    const Text(
                        'A new mystery arrives with Monday. This '
                        'one stays solved in your field guide.',
                        style:
                            TextStyle(fontSize: 12, color: tx2)),
                  ] else if (open < 5)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                          'You can guess now, or wait for more '
                          'clues - the mystery is in no hurry '
                          'either way.',
                          style:
                              TextStyle(fontSize: 12, color: tx2)),
                    ),
                ],
              ),
      ),
    );
  }

  String _dayName(int weekday) => const [
        '',
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday'
      ][weekday.clamp(1, 5)];
}
