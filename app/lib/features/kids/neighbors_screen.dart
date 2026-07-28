// The Neighbors - the Living Atlas in the kid register. Same
// world, same truth, told in the kid voice: what each neighbor is
// doing RIGHT NOW, this season, tonight. The fable voice reads the
// kid line where recordings exist; otherwise the words stand
// quietly on their own (fable or silence). Meeting a neighbor
// writes them into the child's own field guide.

import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/kid_theme.dart';
import '../../core/sky.dart';
import '../../data/almanac.dart';
import '../../data/fieldguide.dart';

class NeighborsScreen extends StatelessWidget {
  final void Function(String) speak;
  const NeighborsScreen({super.key, required this.speak});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dark = skyIsDark(now);
    return Scaffold(
      backgroundColor: kidCream,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 8, 4),
            child: Row(children: [
              Expanded(
                  child: Text('🏘️ The neighbors', style: kidTitle(20))),
              IconButton(
                  tooltip: 'Back home',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close,
                      color: kidInkLight, size: 20)),
            ]),
          ),
          Text(
              dark
                  ? 'some neighbors are awake RIGHT NOW - look for '
                      'the moon'
                  : 'every neighbor is up to something today',
              textAlign: TextAlign.center,
              style: kidBody(12.5, color: kidInkLight)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                for (final s in atlas)
                  Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: KidSquish(
                      semanticLabel: s.name,
                      onTap: () {
                        Haptics.tick();
                        FieldGuide.meet(s.id);
                        Navigator.of(context).push(kidPush(
                            NeighborPage(species: s, speak: speak)));
                      },
                      child: KidCard(
                        color: s.nocturnal && dark
                            ? const Color(0xFF2A3752)
                                .withValues(alpha: 0.15)
                            : Colors.white,
                        child: Row(children: [
                          Text(s.emoji,
                              style: const TextStyle(fontSize: 34)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(s.name, style: kidTitle(15)),
                                if (s.nocturnal && dark)
                                  Text('🌙 awake right now!',
                                      style: kidBody(11.5,
                                          color: kidInkLight)),
                              ],
                            ),
                          ),
                          const Text('›',
                              style: TextStyle(
                                  fontSize: 20, color: kidInkLight)),
                        ]),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class NeighborPage extends StatefulWidget {
  final AtlasSpecies species;
  final void Function(String) speak;
  const NeighborPage(
      {super.key, required this.species, required this.speak});

  @override
  State<NeighborPage> createState() => _NeighborPageState();
}

class _NeighborPageState extends State<NeighborPage> {
  @override
  void initState() {
    super.initState();
    // the fable voice reads the kid line, or silence stands in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.speak(widget.species.kidLine);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.species;
    final now = DateTime.now();
    final dark = skyIsDark(now);
    return Scaffold(
      backgroundColor: kidCream,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          children: [
            Row(children: [
              Expanded(
                  child: Text('${s.emoji} ${s.name}',
                      style: kidTitle(22))),
              IconButton(
                  tooltip: 'Back to the neighbors',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close,
                      color: kidInkLight, size: 20)),
            ]),
            const SizedBox(height: 8),
            // the kid line - the page's heart
            KidCard(
              color: kidSun.withValues(alpha: 0.3),
              child: Text(s.kidLine, style: kidBody(15)),
            ),
            const SizedBox(height: 10),
            // right now, in the kid frame
            KidCard(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      s.nocturnal && dark
                          ? '🌙 Awake right now'
                          : '📅 What ${s.name.toLowerCase()} is '
                              'doing these days',
                      style: kidTitle(14)),
                  const SizedBox(height: 6),
                  Text(s.nowLine(now), style: kidBody(13)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // where to look - the invitation outside
            KidCard(
              color: kidLeaf.withValues(alpha: 0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🔎 How to find this neighbor',
                      style: kidTitle(14)),
                  const SizedBox(height: 6),
                  Text(s.look, style: kidBody(13)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text('this neighbor is in your field guide now 📖',
                  style: kidBody(11.5, color: kidInkLight)),
            ),
          ],
        ),
      ),
    );
  }
}
