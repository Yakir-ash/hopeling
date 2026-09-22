// The Schoolhouse - V2 (V2-AUDIT.md sections 2-3).
//
// Five jobs and one quiet line. Not a lobby full of doors:
//   1. do one thing outside today      - the Errand, the first law
//   2. continue                        - where you stopped
//   3. five minutes of wonder          - one short thing, by the day
//   4. experiment                      - the Lab, headlined
//   5. go deeper                       - paths and journeys, one shelf
//   ...and "everything in the Schoolhouse", a plain list, at the end.
//
// What is NOT here anymore, on purpose: the Notice Board (it was a
// text copy of the hillside), the Atlas door (the neighbours live in
// Explore), the Field Guide door (it lives in Me), the Mystery door
// (it is footprints on the hill), the Classroom Bench door (it is
// inside the Lab), the Listening Post door (it is a five-minute
// pick and a line in the list), and the list of every journey (it
// is behind "go deeper"). The library is enormous. The door is five
// things.

import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/sfx.dart';
import '../../core/theme.dart';
import '../../core/sky.dart';
import '../../core/widgets.dart';
import '../../data/almanac.dart';
import '../../data/content.dart';
import '../../data/fieldguide.dart';
import '../../data/lab.dart';
import '../../data/mysteries.dart';
import '../../data/paths.dart' as walk;
import '../../data/save.dart';
import '../../data/school.dart';
import '../atlas/atlas_screen.dart';
import '../home/doorkeeper.dart';
import '../mystery/mystery_screen.dart';
import '../paths/paths_screen.dart';
import '../school/errand_card.dart';
import '../school/lab_screen.dart';
import '../school/listening_post.dart';
import '../school/classroom_bench.dart';
import 'reader_screen.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  AppContent? content;
  Map<String, dynamic> lessonsDone = {};
  Set<String> earned = {};
  String? door;
  bool everything = false;

  @override
  void initState() {
    super.initState();
    contentTick.addListener(_reload);
    saveTick.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    contentTick.removeListener(_reload);
    saveTick.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    loadContent().then((c) {
      if (mounted) setState(() => content = c);
    });
    FieldGuide.earnedChapterIds().then((e) {
      if (mounted) setState(() => earned = e);
    });
    Doorkeeper.door().then((d) {
      if (mounted) setState(() => door = d);
    });
    // journeys read: the reader keeps this in the save's extra
    // (PWA parity), so we read it the same way the reader does
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    final s = await Store.load();
    if (mounted) {
      setState(() => lessonsDone =
          (s.extra['lessons'] as Map<String, dynamic>?) ?? {});
    }
  }

  int _read(Journey j) {
    var n = 0;
    for (var i = 0; i < j.lessons.length; i++) {
      if (lessonsDone[j.lessonKey(i)] == true) n++;
    }
    return n;
  }

  /// The journey furthest along but unfinished, if any.
  Journey? _continueJourney() {
    final c = content;
    if (c == null) return null;
    Journey? best;
    var bestRead = 0;
    for (final j in c.journeys) {
      final r = _read(j);
      if (r > 0 && r < j.lessons.length && r >= bestRead) {
        best = j;
        bestRead = r;
      }
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final path = walk.continuePath(earned);
    final pathStarted = path != null && walk.pathProgress(path, earned) > 0;
    final journey = _continueJourney();
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              24, 18, 24, 32 + MediaQuery.of(context).padding.bottom),
          children: [
            Text('The Schoolhouse', style: serif(28)),
            const SizedBox(height: 4),
            const Text(
                'there is a whole world here to learn - and only '
                'one thing to do first',
                style: TextStyle(fontSize: 12.5, color: tx2)),
            // 1. THE FIRST LAW - today's one un-phoneable task
            const Padding(
              padding: EdgeInsets.only(top: 14),
              child: ErrandCard(),
            ),
            // 2. CONTINUE - only when there is something to continue
            if (pathStarted || journey != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _job(
                  kicker: 'CONTINUE',
                  emoji: pathStarted ? path.emoji : journey!.badge,
                  title: pathStarted ? path.name : journey!.t,
                  sub: pathStarted
                      ? '${walk.pathProgress(path, earned)} of '
                          '${path.chapters.length} walked · next: '
                          '${walk.nextChapter(path, earned)?.title ?? ""}'
                      : '${_read(journey!)} of ${journey.lessons.length} '
                          'chapters read',
                  onTap: () {
                    if (pathStarted) {
                      Navigator.of(context)
                          .push(risePush(PathPage(path: path)))
                          .then((_) => _reload());
                    } else {
                      Navigator.of(context)
                          .push(risePush(ReaderScreen(
                              journey: journey!, content: content!)))
                          .then((_) => _reload());
                    }
                  },
                ),
              ),
            // 3. FIVE MINUTES - one short thing, chosen by the day
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _fiveMinutes(now),
            ),
            // 4. EXPERIMENT - the Lab, headlined by the fortnight
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _job(
                kicker: 'EXPERIMENT',
                emoji: fortnightExperiment(now).emoji,
                title: fortnightExperiment(now).question,
                sub: 'this fortnight\'s experiment · guess first, then '
                    'watch the web answer',
                onTap: () => Navigator.of(context).push(
                    risePush(LabPage(scenario: fortnightExperiment(now)))),
                trailing: 'all twelve',
                onTrailing: () =>
                    Navigator.of(context).push(risePush(const LabScreen())),
              ),
            ),
            // 5. GO DEEPER - paths and journeys, one shelf
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _job(
                kicker: 'GO DEEPER',
                emoji: '🥾',
                title: 'Paths and journeys',
                sub: 'walks with a field note at the end of each, and '
                    'the long reads',
                onTap: () => Navigator.of(context)
                    .push(risePush(const PathsScreen()))
                    .then((_) => _reload()),
              ),
            ),
            // THE ONE QUIET LINE - the whole library, plainly
            const SizedBox(height: 18),
            Semantics(
              button: true,
              expanded: everything,
              label: 'Everything in the Schoolhouse',
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Haptics.tick();
                  setState(() => everything = !everything);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    Text(
                        everything
                            ? 'everything in the Schoolhouse'
                            : 'everything in the Schoolhouse →',
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: fern)),
                  ]),
                ),
              ),
            ),
            if (everything)
              for (final (emoji, name, sub) in schoolRooms)
                _room(emoji, name, sub, () => _openRoom(name)),
          ],
        ),
      ),
    );
  }

  void _openRoom(String name) {
    final nav = Navigator.of(context);
    switch (name) {
      case 'The Lab':
        nav.push(risePush(const LabScreen()));
      case 'The Listening Post':
        nav.push(risePush(const ListeningPostScreen()));
      case 'Mysteries':
        nav.push(risePush(const MysteryScreen()));
      case 'Paths':
      case 'Journeys':
        nav.push(risePush(const PathsScreen())).then((_) => _reload());
      case 'The Classroom Bench':
        nav.push(risePush(const ClassroomBenchScreen()));
    }
  }

  /// Job 3, decided by data/school.dart and rendered here.
  Widget _fiveMinutes(DateTime now) {
    final pick = fiveMinutePick(now, door);
    switch (pick.kind) {
      case FiveKind.listening:
        return _job(
          kicker: 'FIVE MINUTES',
          emoji: '🎧',
          title: 'Learn one voice by ear',
          sub: 'the morning becomes a room full of neighbours',
          onTap: () => Navigator.of(context)
              .push(risePush(const ListeningPostScreen())),
        );
      case FiveKind.mystery:
        final m = mysteryOfWeek(now);
        return _job(
          kicker: 'FIVE MINUTES',
          emoji: m.emoji,
          title: m.title,
          sub: 'clue ${cluesOpen(now)} of 5 is pinned up',
          onTap: () =>
              Navigator.of(context).push(risePush(const MysteryScreen())),
        );
      case FiveKind.lab:
        final s = labScenarioById(pick.labId!) ?? labScenarios.first;
        return _job(
          kicker: 'FIVE MINUTES',
          emoji: s.emoji,
          title: s.question,
          sub: 'guess before it runs - no grades, a hello',
          onTap: () =>
              Navigator.of(context).push(risePush(LabPage(scenario: s))),
        );
      case FiveKind.neighbour:
        final dark = skyIsDark(now);
        final sp = speciesOfDay(now, dark: dark);
        return _job(
          kicker: 'FIVE MINUTES',
          emoji: sp.emoji,
          title: 'The ${sp.name.toLowerCase()} is '
              '${dark ? "awake" : "out there"} right now',
          sub: sp.nowLine(now),
          onTap: () =>
              Navigator.of(context).push(risePush(AtlasPage(species: sp))),
        );
    }
  }

  Widget _job({
    required String kicker,
    required String emoji,
    required String title,
    required String sub,
    required VoidCallback onTap,
    String? trailing,
    VoidCallback? onTrailing,
  }) {
    return Semantics(
      button: true,
      label: '$kicker. $title. $sub',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Haptics.tick();
            Sfx.play('tick', volume: 0.3);
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(kicker,
                        style: const TextStyle(
                            fontSize: 10,
                            letterSpacing: 2,
                            fontWeight: FontWeight.w700,
                            color: tx2)),
                    const Spacer(),
                    if (trailing != null)
                      Semantics(
                        button: true,
                        label: trailing,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            Haptics.tick();
                            onTrailing?.call();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            child: Text(trailing,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: fern)),
                          ),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Text(emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: serif(15.5, height: 1.3)),
                          const SizedBox(height: 3),
                          Text(sub,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, height: 1.4, color: tx2)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: tx2, size: 20),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _room(String emoji, String name, String sub, VoidCallback onTap) =>
      Semantics(
        button: true,
        label: '$name. $sub',
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Haptics.tick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: ExcludeSemantics(
              child: Row(children: [
                Text(emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Text(name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ink)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: tx2)),
                ),
              ]),
            ),
          ),
        ),
      );
}
