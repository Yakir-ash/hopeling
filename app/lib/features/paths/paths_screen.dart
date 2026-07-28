// Paths - learning as walking. The list, the path, the chapter.
// A chapter is read in a minute and walked in the world; the tap
// that earns its Field Note says "I looked", and we believe
// people. Question Engine law: every chapter ends with a door.

import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/sfx.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/almanac.dart';
import '../../data/fieldguide.dart';
import '../../data/paths.dart';
import '../atlas/atlas_screen.dart';

class PathsScreen extends StatefulWidget {
  const PathsScreen({super.key});

  @override
  State<PathsScreen> createState() => _PathsScreenState();
}

class _PathsScreenState extends State<PathsScreen> {
  Set<String> earned = {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final e = await FieldGuide.earnedChapterIds();
    if (mounted) setState(() => earned = e);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: ink,
          title: Text('Paths', style: serif(19))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            const Text(
              'Not courses - walks. Every chapter is one true idea '
              'and one thing to notice outside today. Walking a '
              'chapter writes a Field Note into your guide, and '
              'notes can never be lost.',
              style: TextStyle(fontSize: 13, height: 1.6, color: tx2),
            ),
            const SizedBox(height: 14),
            for (final p in paths)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () {
                      Haptics.tick();
                      Navigator.of(context)
                          .push(risePush(PathPage(path: p)))
                          .then((_) => _reload());
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(p.emoji,
                                style: const TextStyle(fontSize: 26)),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(p.name, style: serif(17))),
                          ]),
                          const SizedBox(height: 6),
                          Text(p.promise,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  height: 1.55,
                                  color: tx2)),
                          const SizedBox(height: 10),
                          _ProgressLeaves(
                              done: pathProgress(p, earned),
                              total: p.chapters.length),
                        ],
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

/// Progress told as leaves on a stem - never a percentage.
class _ProgressLeaves extends StatelessWidget {
  final int done, total;
  const _ProgressLeaves({required this.done, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: Wrap(spacing: 3, children: [
          for (var i = 0; i < total; i++)
            Text(i < done ? '🍃' : '·',
                style: TextStyle(
                    fontSize: 12,
                    color: i < done ? fern : tx2)),
        ]),
      ),
      Text(
          done == 0
              ? 'not yet walked'
              : done == total
                  ? 'walked, all $total'
                  : '$done of $total walked',
          style: const TextStyle(fontSize: 11.5, color: tx2)),
    ]);
  }
}

class PathPage extends StatefulWidget {
  final Path path;
  const PathPage({super.key, required this.path});

  @override
  State<PathPage> createState() => _PathPageState();
}

class _PathPageState extends State<PathPage> {
  Set<String> earned = {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final e = await FieldGuide.earnedChapterIds();
    if (mounted) setState(() => earned = e);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.path;
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: ink,
          title: Text('${p.emoji} ${p.name}', style: serif(18))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            Text(p.promise,
                style: const TextStyle(
                    fontSize: 13, height: 1.6, color: tx2)),
            const SizedBox(height: 14),
            for (var i = 0; i < p.chapters.length; i++)
              _chapterTile(context, p, i),
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(22)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🖐️ The capstone', style: serif(15)),
                  const SizedBox(height: 6),
                  Text(p.capstone,
                      style: const TextStyle(
                          fontSize: 13, height: 1.6, color: ink)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chapterTile(BuildContext context, Path p, int i) {
    final c = p.chapters[i];
    final done = earned.contains(c.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: done ? mint.withValues(alpha: 0.3) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Haptics.tick();
            Navigator.of(context)
                .push(risePush(ChapterPage(path: p, chapter: c)))
                .then((_) => _reload());
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16),
            child: Row(children: [
              Text(c.emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 12),
              Expanded(
                child: Text('${i + 1}. ${c.title}',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: done ? fernDeep : ink)),
              ),
              Semantics(
                  label: done ? 'walked' : 'not walked yet',
                  child: ExcludeSemantics(
                      child: Text(done ? '🍃' : '›',
                          style: const TextStyle(
                              fontSize: 16, color: tx2)))),
            ]),
          ),
        ),
      ),
    );
  }
}

class ChapterPage extends StatefulWidget {
  final Path path;
  final Chapter chapter;
  const ChapterPage(
      {super.key, required this.path, required this.chapter});

  @override
  State<ChapterPage> createState() => _ChapterPageState();
}

class _ChapterPageState extends State<ChapterPage> {
  bool keeperOpen = false;
  bool earnedNow = false;
  bool alreadyEarned = false;

  @override
  void initState() {
    super.initState();
    FieldGuide.earnedChapterIds().then((e) {
      if (mounted) {
        setState(
            () => alreadyEarned = e.contains(widget.chapter.id));
      }
    });
  }

  Future<void> _earn() async {
    await FieldGuide.earn(widget.path.id, widget.chapter.id);
    Haptics.settle();
    Sfx.play('chime', volume: 0.6);
    if (mounted) setState(() => earnedNow = true);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.chapter;
    final sp = c.speciesId == null ? null : atlasById(c.speciesId!);
    final done = earnedNow || alreadyEarned;
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: ink,
          title: Text('${c.emoji} ${c.title}', style: serif(18))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            // the idea
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22)),
              child: Text(c.idea,
                  style: const TextStyle(
                      fontSize: 14.5, height: 1.7, color: ink)),
            ),
            const SizedBox(height: 12),
            // the noticing - the world is the exercise
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: mint.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(22)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🔎 The noticing', style: serif(15)),
                  const SizedBox(height: 6),
                  Text(c.notice,
                      style: const TextStyle(
                          fontSize: 13.5, height: 1.65, color: ink)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // the keeper layer - depth for the hungry
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () {
                  Haptics.tick();
                  setState(() => keeperOpen = !keeperOpen);
                },
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Text('🌳 The keeper\'s layer',
                            style: serif(15)),
                        const Spacer(),
                        Icon(
                            keeperOpen
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 18,
                            color: tx2),
                      ]),
                      if (keeperOpen) ...[
                        const SizedBox(height: 8),
                        Text(c.keeper,
                            style: const TextStyle(
                                fontSize: 13,
                                height: 1.65,
                                color: ink)),
                      ] else
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text('the deeper cut, when you want it',
                              style: TextStyle(
                                  fontSize: 11.5, color: tx2)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // walking the chapter writes the note
            if (!done)
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: fern,
                    foregroundColor: paper,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14)),
                onPressed: _earn,
                child: const Text(
                    '🍃 I looked - write my field note'),
              )
            else
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                    color: gold.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(22)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        earnedNow
                            ? '🍃 Written into your field guide:'
                            : '🍃 In your field guide:',
                        style: serif(14)),
                    const SizedBox(height: 6),
                    Text('"${c.note}"',
                        style: const TextStyle(
                            fontSize: 13.5,
                            height: 1.6,
                            fontStyle: FontStyle.italic,
                            color: ink)),
                  ],
                ),
              ),
            // the Question Engine: a door, never a period
            if (sp != null) ...[
              const SizedBox(height: 10),
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                child: Ink(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        mint.withValues(alpha: 0.35),
                        Colors.white
                      ]),
                      borderRadius: BorderRadius.circular(18)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      Haptics.tick();
                      FieldGuide.meet(sp.id);
                      Navigator.of(context)
                          .push(risePush(AtlasPage(species: sp)));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        Text(sp.emoji,
                            style: const TextStyle(fontSize: 22)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(
                                'Meet ${sp.name} in the Living '
                                'Atlas - what is she doing right '
                                'now?',
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    height: 1.5,
                                    color: ink))),
                        const Icon(Icons.chevron_right,
                            size: 18, color: tx2),
                      ]),
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
