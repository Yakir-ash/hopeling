// Learn - journeys through the living world. A shelf, not a syllabus.
// Progress reads as exploration ("3 journeys walked"), never as XP.

import 'package:flutter/material.dart';

import '../../core/atmosphere.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
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
                  Text('Learn', style: serif(28)),
                  const SizedBox(height: 4),
                  Text(
                    chapters == 0
                        ? 'journeys through the living world'
                        : '$chapters chapters read · $walked of ${journeys.length} journeys walked',
                    style: const TextStyle(fontSize: 13, color: tx2),
                  ),
                  const SizedBox(height: 20),
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
