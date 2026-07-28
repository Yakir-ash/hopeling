// The Field Guide of Mine - what all the seeing has added up to.
// Pages, not points: field notes walked, neighbors met, mysteries
// solved. It only ever grows, and its emptiness is an invitation,
// never a reproach.

import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/almanac.dart';
import '../../data/fieldguide.dart';
import '../../data/mysteries.dart';
import '../../data/paths.dart';
import '../atlas/atlas_screen.dart';
import '../paths/paths_screen.dart';

class FieldGuideScreen extends StatefulWidget {
  const FieldGuideScreen({super.key});

  @override
  State<FieldGuideScreen> createState() => _FieldGuideScreenState();
}

class _FieldGuideScreenState extends State<FieldGuideScreen> {
  List<FieldNote> notes = [];
  Set<String> met = {};
  Set<String> solved = {};
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final n = await FieldGuide.notes();
    final m = await FieldGuide.metSpecies();
    final s = await FieldGuide.solvedMysteries();
    if (mounted) {
      setState(() {
        notes = n;
        met = m;
        solved = s;
        loaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: ink,
          title: Text('📖 My Field Guide', style: serif(19))),
      body: SafeArea(
        child: !loaded
            ? const SizedBox.shrink()
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                        color: gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(22)),
                    child: Text(
                        guideLine(
                            notes.length, met.length, solved.length),
                        style: const TextStyle(
                            fontSize: 13.5, height: 1.6, color: ink)),
                  ),
                  const SizedBox(height: 16),
                  // neighbors met
                  Text('Neighbors met', style: serif(16)),
                  const SizedBox(height: 8),
                  if (met.isEmpty)
                    const Text(
                        'None yet - every page of the Living Atlas '
                        'you open, every game creature you follow '
                        'home, lands here.',
                        style: TextStyle(
                            fontSize: 12.5, height: 1.55, color: tx2))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final id in met)
                          if (atlasById(id) != null)
                            _speciesChip(atlasById(id)!),
                      ],
                    ),
                  const SizedBox(height: 18),
                  // field notes, the walked knowledge
                  Text('Field notes', style: serif(16)),
                  const SizedBox(height: 8),
                  if (notes.isEmpty)
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Haptics.tick();
                          Navigator.of(context)
                              .push(risePush(const PathsScreen()))
                              .then((_) => _reload());
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                              'Empty, and honestly inviting: walk '
                              'the first chapter of any Path and '
                              'the first note writes itself. →',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.55,
                                  color: tx2)),
                        ),
                      ),
                    )
                  else
                    for (final n in notes.reversed) _noteCard(n),
                  const SizedBox(height: 18),
                  // mysteries
                  if (solved.isNotEmpty) ...[
                    Text('Mysteries solved', style: serif(16)),
                    const SizedBox(height: 8),
                    for (final m in mysteries)
                      if (solved.contains(m.id))
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(18)),
                          child: Row(children: [
                            Text(m.emoji,
                                style:
                                    const TextStyle(fontSize: 20)),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(m.title,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: ink))),
                          ]),
                        ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _speciesChip(AtlasSpecies s) => Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Haptics.tick();
            Navigator.of(context)
                .push(risePush(AtlasPage(species: s)));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            child: Text('${s.emoji} ${s.name}',
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600)),
          ),
        ),
      );

  Widget _noteCard(FieldNote n) {
    Chapter? ch;
    for (final p in paths) {
      for (final c in p.chapters) {
        if (c.id == n.chapterId) ch = c;
      }
    }
    if (ch == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(ch.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
                child: Text(ch.title,
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: tx2))),
          ]),
          const SizedBox(height: 4),
          Text('"${ch.note}"',
              style: const TextStyle(
                  fontSize: 13,
                  height: 1.55,
                  fontStyle: FontStyle.italic,
                  color: ink)),
        ],
      ),
    );
  }
}
