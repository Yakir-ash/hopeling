// The Living Atlas - the encyclopedia that knows what time it is.
// Every page says what its species is doing RIGHT NOW: this season,
// and for the night shift, whether she is awake at this hour. Pages
// obey the Question Engine law: nothing ends with a period - every
// page ends with something to notice and somewhere to go.

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/sky.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/almanac.dart';
import '../../data/wiki.dart';

class AtlasScreen extends StatelessWidget {
  const AtlasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dark = skyIsDark(now);
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: ink,
          title: Text('The Living Atlas', style: serif(19))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            Text(
              'Not what these neighbors ARE - what they are doing '
              'right now, ${season(now)} being what it is. Come back '
              'in another season: every page will have turned.',
              style: const TextStyle(
                  fontSize: 13, height: 1.6, color: tx2),
            ),
            const SizedBox(height: 14),
            for (final s in atlas)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Haptics.tick();
                      Navigator.of(context)
                          .push(risePush(AtlasPage(species: s)));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.emoji,
                              style: const TextStyle(fontSize: 30)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Text(s.name, style: serif(16)),
                                  if (s.nocturnal && dark) ...[
                                    const SizedBox(width: 8),
                                    const Text('🌙 awake now',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: tx2)),
                                  ],
                                ]),
                                const SizedBox(height: 4),
                                Text(
                                  s.nowLine(now),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      height: 1.5,
                                      color: tx2),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: tx2, size: 20),
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

class AtlasPage extends StatefulWidget {
  final AtlasSpecies species;
  const AtlasPage({super.key, required this.species});

  @override
  State<AtlasPage> createState() => _AtlasPageState();
}

class _AtlasPageState extends State<AtlasPage> {
  late String shownSeason = season(DateTime.now());
  WikiSummary? wiki;

  @override
  void initState() {
    super.initState();
    wikiSummary(widget.species.wikiTitle).then((w) {
      if (mounted) setState(() => wiki = w);
    });
  }

  Widget _card(String title, String body, {Widget? extra}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: serif(15)),
            const SizedBox(height: 8),
            Text(body,
                style: const TextStyle(
                    fontSize: 13.5, height: 1.65, color: ink)),
            if (extra != null) extra,
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = widget.species;
    final now = DateTime.now();
    final currentSeason = season(now);
    final dark = skyIsDark(now);
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: ink,
          title: Text('${s.emoji} ${s.name}', style: serif(19))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            // the portrait, from the same pipeline as everything
            if (wiki != null && wiki!.imgSmall.isNotEmpty)
              Container(
                height: 180,
                margin: const EdgeInsets.only(bottom: 12),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22)),
                child: CachedNetworkImage(
                  imageUrl: wiki!.imgSmall,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      const SizedBox.shrink(),
                ),
              ),
            // right now: the living part of the page
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  skyWash(now, paper)[0],
                  Colors.white,
                ]),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(
                        shownSeason == currentSeason
                            ? 'Right now'
                            : 'In $shownSeason',
                        style: serif(15)),
                    if (s.nocturnal &&
                        dark &&
                        shownSeason == currentSeason) ...[
                      const SizedBox(width: 8),
                      const Text('🌙 she is awake right now',
                          style:
                              TextStyle(fontSize: 11.5, color: tx2)),
                    ],
                  ]),
                  const SizedBox(height: 8),
                  Text(s.now[shownSeason] ?? '',
                      style: const TextStyle(
                          fontSize: 13.5, height: 1.65, color: ink)),
                  const SizedBox(height: 12),
                  // the same animal, four lives
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final se in const [
                        ('spring', '🌸'),
                        ('summer', '☀️'),
                        ('autumn', '🍂'),
                        ('winter', '❄️')
                      ])
                        ChoiceChip(
                          label: Text('${se.$2} ${se.$1}',
                              style: const TextStyle(fontSize: 11.5)),
                          selected: shownSeason == se.$1,
                          selectedColor: mint,
                          onSelected: (_) => setState(() {
                            shownSeason = se.$1;
                            Haptics.tick();
                          }),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            _card('Where to look, how to look', s.look),
            _card('One wonder', s.wonder),
            if (wiki != null && wiki!.extract.isNotEmpty)
              _card('From the encyclopedia', wiki!.extract),
            // the Question Engine: no page ends with a period
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: mint.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Before you go', style: serif(15)),
                  const SizedBox(height: 6),
                  Text(
                      dark && s.nocturnal
                          ? 'She is out there this very hour. One '
                              'quiet minute at a window is a real '
                              'chance of meeting her.'
                          : 'This page will say something different '
                              'in ${_nextSeason(currentSeason)}. The '
                              'year turns the pages by itself - come '
                              'back and catch it.',
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

  String _nextSeason(String s) => switch (s) {
        'spring' => 'summer',
        'summer' => 'autumn',
        'autumn' => 'winter',
        _ => 'spring',
      };
}
