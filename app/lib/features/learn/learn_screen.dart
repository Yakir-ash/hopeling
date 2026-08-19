// Learn - journeys through the living world. A shelf, not a syllabus.
// Progress reads as exploration ("3 journeys walked"), never as XP.

import 'package:flutter/material.dart';

import '../../core/atmosphere.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/sky.dart';
import '../../data/almanac.dart';
import '../../data/lab.dart';
import '../../data/mysteries.dart';
import '../atlas/atlas_screen.dart';
import '../fieldguide/fieldguide_screen.dart';
import '../mystery/mystery_screen.dart';
import '../paths/paths_screen.dart';
import '../school/errand_card.dart';
import '../school/lab_screen.dart';
import '../school/listening_post.dart';
import '../../core/widgets.dart';
import '../../data/content.dart';
import '../../data/save.dart';
import 'reader_screen.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  AppContent? content;
  Map<String, dynamic> lessonsDone = {};

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
    Store.load().then((s) {
      if (mounted) {
        setState(() => lessonsDone =
            (s.extra['lessons'] as Map<String, dynamic>?) ?? {});
      }
    });
  }

  int _read(Journey j) {
    var n = 0;
    for (var i = 0; i < j.lessons.length; i++) {
      if (lessonsDone[j.lessonKey(i)] == true) n++;
    }
    return n;
  }

  Atmosphere _atmosFor(Journey j) {
    final s = j.slug;
    if (s.contains('ocean') || s.contains('marine')) return atmosphereOf('oceans');
    if (s.contains('wildlife') || s.contains('species') ||
        s.contains('biodiversity')) {
      return atmosphereOf('forests');
    }
    if (s.contains('urban') || s.contains('consumer') || s.contains('travel')) {
      return atmosphereOf('bees');
    }
    return atmosphereOf('forests');
  }

  @override
  Widget build(BuildContext context) {
    final c = content;
    final journeys = c?.journeys ?? [];
    final walked =
        journeys.where((j) => _read(j) == j.lessons.length && j.lessons.isNotEmpty).length;
    final chapters = journeys.fold<int>(0, (n, j) => n + _read(j));
    return Scaffold(
      body: SafeArea(
        child: c == null
            ? const LoadingSeed(line: 'Opening the library...')
            : ListView(
                padding: EdgeInsets.fromLTRB(
                    24, 18, 24, 32 + MediaQuery.of(context).padding.bottom),
                children: [
                  Text('The Schoolhouse', style: serif(28)),
                  const SizedBox(height: 4),
                  const Text(
                      'a place, not a list - the doors change '
                      'with the sky',
                      style: TextStyle(fontSize: 12.5, color: tx2)),
                  // THE NOTICE BOARD - the almanac pins up what
                  // is happening over the valley right now
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _NoticeBoard(),
                  ),
                  // the School's first law, at the head of the
                  // hall: today's one un-phoneable task
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: ErrandCard(),
                  ),
                  // the Lab: pull one thread, watch the web
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Semantics(
                      button: true,
                      label: 'The Lab. Pull one thread of an '
                          'ecosystem and watch the web answer.',
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () {
                            Haptics.tick();
                            Navigator.of(context)
                                .push(risePush(const LabScreen()));
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: ExcludeSemantics(
                              child: Row(children: [
                                Text('🧪',
                                    style: TextStyle(fontSize: 24)),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('The Lab',
                                          style: TextStyle(
                                              fontSize: 15,
                                              fontWeight:
                                                  FontWeight.w700,
                                              color: ink)),
                                      SizedBox(height: 2),
                                      Text(
                                          'what would happen if? '
                                          'Remove the bees, bring '
                                          'the wolves home, warm '
                                          'the sea - and watch',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: tx2)),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right,
                                    color: tx2, size: 20),
                              ]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // the Listening Post: a new sense joins school
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Semantics(
                      button: true,
                      label: 'The Listening Post. Learn the five '
                          'voices of the morning by ear.',
                      child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () {
                            Haptics.tick();
                            Navigator.of(context).push(risePush(
                                const ListeningPostScreen()));
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: ExcludeSemantics(
                              child: Row(children: [
                                Text('🎧',
                                    style: TextStyle(fontSize: 24)),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('The Listening Post',
                                          style: TextStyle(
                                              fontSize: 15,
                                              fontWeight:
                                                  FontWeight.w700,
                                              color: ink)),
                                      SizedBox(height: 2),
                                      Text(
                                          'five voices to know by '
                                          'ear - and the morning '
                                          'becomes a room full of '
                                          'neighbors',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: tx2)),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right,
                                    color: tx2, size: 20),
                              ]),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // three more doors off the hall
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(children: [
                      Expanded(
                          child: _hallDoor('🕵️', 'Mystery',
                              'clue ${cluesOpen(DateTime.now())} of 5',
                              () => Navigator.of(context).push(
                                  risePush(const MysteryScreen())))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _hallDoor('🦉', 'Atlas',
                              'who is awake now',
                              () => Navigator.of(context).push(
                                  risePush(const AtlasScreen())))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: _hallDoor('📖', 'My Guide',
                              'it only grows',
                              () => Navigator.of(context).push(
                                  risePush(
                                      const FieldGuideScreen())))),
                    ]),
                  ),
                  // V2: paths - learning as walking, notes earned
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            mint.withValues(alpha: 0.4),
                            Colors.white
                          ]),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(22),
                          onTap: () {
                            Haptics.tick();
                            Navigator.of(context)
                                .push(risePush(const PathsScreen()));
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(16),
                            child: Row(children: [
                              Text('🥾',
                                  style: TextStyle(fontSize: 24)),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text('Paths',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight:
                                                FontWeight.w700,
                                            color: ink)),
                                    SizedBox(height: 2),
                                    Text(
                                        'not courses - walks. One '
                                        'idea, one thing to notice '
                                        'outside, one field note '
                                        'earned.',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: tx2)),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right,
                                  color: tx2, size: 20),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Text(
                    chapters == 0
                        ? 'journeys through the living world'
                        : '$chapters chapters read · $walked of ${journeys.length} journeys walked',
                    style: const TextStyle(fontSize: 13, color: tx2),
                  ),
                  const SizedBox(height: 20),
                  if (journeys.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(children: [
                        const Text('🍃', style: TextStyle(fontSize: 34)),
                        const SizedBox(height: 10),
                        const Text(
                            'The library arrives with your first connection.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 13.5, height: 1.5, color: tx2)),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () async {
                            await refreshContent();
                            _reload();
                          },
                          child: const Text('Reach for the sky again'),
                        ),
                      ]),
                    ),
                  for (final j in journeys) ...[
                    _JourneyCard(
                      journey: j,
                      read: _read(j),
                      atmos: _atmosFor(j),
                      onOpen: () {
                        Haptics.tick();
                        Navigator.of(context)
                            .push(risePush(ReaderScreen(
                                journey: j, content: c)))
                            .then((_) => _reload());
                      },
                    ),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _hallDoor(String emoji, String title, String sub,
      VoidCallback onTap) {
    return Semantics(
      button: true,
      label: '$title. $sub.',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Haptics.tick();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 14),
            child: ExcludeSemantics(
              child: Column(children: [
                Text(emoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 6),
                Text(title,
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: ink)),
                const SizedBox(height: 2),
                Text(sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 10, color: tx2)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// The almanac pins up what is true over the valley today.
class _NoticeBoard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final w = wonderOfDay(now);
    final sp = speciesOfDay(now, dark: skyIsDark(now));
    final m = mysteryOfWeek(now);
    final clue = cluesOpen(now);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EAD8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFFE0D2B8), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('THE NOTICE BOARD',
              style: TextStyle(
                  fontSize: 10.5, letterSpacing: 2, color: tx2)),
          const SizedBox(height: 10),
          Text('📌 ${w.q}',
              style: const TextStyle(
                  fontSize: 13, height: 1.5, color: ink)),
          const SizedBox(height: 8),
          Text('📌 ${sp.emoji} The ${sp.name.toLowerCase()}: '
              '${sp.nowLine(now)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13, height: 1.5, color: ink)),
          const SizedBox(height: 8),
          Text('📌 ${m.emoji} This week\'s mystery: clue $clue '
              'of 5 is pinned up',
              style: const TextStyle(
                  fontSize: 13, height: 1.5, color: ink)),
          const SizedBox(height: 8),
          // the Lab's heartbeat: a featured experiment each
          // fortnight, chosen by the calendar like everything
          Semantics(
            button: true,
            label: 'This fortnight\'s experiment: '
                '${_fortnight(now).title}. Opens the Lab.',
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                Haptics.tick();
                Navigator.of(context).push(risePush(
                    LabPage(scenario: _fortnight(now))));
              },
              child: ExcludeSemantics(
                child: Text(
                    '📌 ${_fortnight(now).emoji} This '
                    'fortnight\'s experiment: '
                    '${_fortnight(now).question}',
                    style: const TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                        color: ink)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static LabScenario _fortnight(DateTime t) => labScenarios[
      (weekOfYear(t) ~/ 2 + t.year) % labScenarios.length];
}

class _JourneyCard extends StatelessWidget {
  final Journey journey;
  final int read;
  final Atmosphere atmos;
  final VoidCallback onOpen;
  const _JourneyCard(
      {required this.journey,
      required this.read,
      required this.atmos,
      required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final total = journey.lessons.length;
    final complete = total > 0 && read == total;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [atmos.deep, atmos.accent],
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(journey.badge, style: const TextStyle(fontSize: 34)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(journey.t,
                          style: serif(18,
                              color: Colors.white, height: 1.25)),
                      const SizedBox(height: 4),
                      Text(journey.d,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 12.5,
                              height: 1.4,
                              color: Colors.white.withValues(alpha: 0.85))),
                      const SizedBox(height: 8),
                      Text(
                        complete
                            ? 'journey walked ${journey.badge}'
                            : read == 0
                                ? '$total chapters · begin anywhere'
                                : '$read of $total chapters read',
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Colors.white.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
