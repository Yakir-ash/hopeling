// The Hillside - home stops being a feed and becomes a place.
// The whole hero is the living world: the real sky, the hills, the
// window parallax, fireflies after dark. And the day's content is
// not cards ABOUT the world - it is THINGS IN the world:
//
//   🪧 a note pinned to the signpost      (today's wonder)
//   🐾 footprints crossing the ground     (this week's mystery)
//   🥾 the path with your leaf markers    (continue your path)
//   the animal itself, out on the hill    (happening right now)
//
// Law of the hillside: things, not cards. Tap the thing.

import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/kid_theme.dart' show KidDrift;
import '../../core/sfx.dart';
import '../../core/sky.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/almanac.dart';
import '../../data/fieldguide.dart';
import '../../data/mysteries.dart';
import '../../data/paths.dart' as walk;
import '../atlas/atlas_screen.dart';
import '../mystery/mystery_screen.dart';
import '../paths/paths_screen.dart';

class HillsideHome extends StatefulWidget {
  final String greeting;
  final String dateLine;
  const HillsideHome(
      {super.key, required this.greeting, required this.dateLine});

  @override
  State<HillsideHome> createState() => _HillsideHomeState();
}

class _HillsideHomeState extends State<HillsideHome>
    with SingleTickerProviderStateMixin {
  Set<String> earned = {};
  Set<String> met = {};

  // The Stillness: hold quietly and the world gets braver. The
  // controller IS the stillness - it only moves while you hold.
  late final AnimationController _still = AnimationController(
      vsync: this, duration: const Duration(seconds: 6));
  int _stillStage = 0;
  bool _shyMet = false; // this arrival was greeted already

  @override
  void initState() {
    super.initState();
    FieldGuide.earnedChapterIds().then((e) {
      if (mounted) setState(() => earned = e);
    });
    FieldGuide.metSpecies().then((m) {
      if (mounted) setState(() => met = m);
    });
    _still.addListener(_onStillTick);
  }

  @override
  void dispose() {
    _still.dispose();
    super.dispose();
  }

  int _stageOf(double v) => v >= 1.0
      ? 4
      : v >= 0.7
          ? 3
          : v >= 0.4
              ? 2
              : v >= 0.15
                  ? 1
                  : 0;

  void _onStillTick() {
    final stage = _stageOf(_still.value);
    if (stage > _stillStage) {
      // the world answers each new depth of quiet
      Haptics.tick();
      if (stage == 2 || stage == 3) Sfx.play('drop', volume: 0.25);
      if (stage == 4) {
        Haptics.settle();
        Sfx.play('chime', volume: 0.5);
      }
    }
    if (stage != _stillStage && mounted) {
      setState(() => _stillStage = stage);
    }
  }

  void _stillStart() {
    if (_still.value >= 1.0) return; // the shy one already came
    _still.forward();
  }

  void _stillEnd() {
    if (_still.value >= 1.0) return; // arrived: it stays
    // released too soon - the hillside relaxes, nothing scolds
    _still.animateBack(0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut);
  }

  String _stillLine(AtlasSpecies? shy) => switch (_stillStage) {
        0 => '',
        1 => 'stay still...',
        2 => 'the hillside is getting braver...',
        3 => 'something shy is coming...',
        _ => shy == null
            ? 'you have met every neighbor of this hour - the hill '
                'sat with you anyway 🌾'
            : _shyMet
                ? ''
                : 'a ${shy.name.toLowerCase()} came out to see '
                    'you - tap to say hello',
      };

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dark = skyIsDark(now);
    final onSky = dark ? Colors.white : ink;
    final sp = speciesOfDay(now, dark: dark);
    final m = mysteryOfWeek(now);
    final p = walk.continuePath(earned);
    final next = p == null ? null : walk.nextChapter(p, earned);
    // your field guide is the hillside's cast: species this device
    // has met come visiting, day shift by day, night shift by night.
    // Two at a time: the visitors' strip is theirs alone.
    final visitors = visitorsFor(met, now, dark: dark, max: 2);
    // and the shy one, who only steps out for a still hand
    final shy = shyOfDay(met, now, dark: dark);

    return Container(
      height: 380,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        borderRadius:
            BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: Stack(fit: StackFit.expand, children: [
        // the world: real sky, sun or moon, hills, parallax,
        // fireflies after dark
        const LivingSky(seed: 11, window: true),
        // THE STILLNESS: hold anywhere, quietly, and the world gets
        // braver. Beneath everything - the things still win taps.
        Positioned.fill(
          child: Semantics(
            label: 'The hillside. Press and hold quietly, and '
                'something shy may come out.',
            onLongPress: () {
              // assistive tech gets a gentler road to the same place
              _still.animateTo(1.0,
                  duration: const Duration(milliseconds: 1600));
            },
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onLongPressStart: (_) => _stillStart(),
              onLongPressEnd: (_) => _stillEnd(),
              onLongPressCancel: _stillEnd,
            ),
          ),
        ),
        // the hush: edges dim as the quiet deepens
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _still,
            builder: (context, _) => DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.1,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(
                        alpha: 0.16 *
                            _still.value.clamp(0.0, 1.0)),
                  ],
                ),
              ),
            ),
          ),
        ),
        // the world meets the page below
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [paper.withValues(alpha: 0.0), paper],
              ),
            ),
          ),
        ),
        // the greeting lives IN the sky
        Positioned(
          left: 22,
          top: 16,
          right: 90,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.greeting,
                  style: serif(24, color: onSky).copyWith(shadows: [
                    Shadow(
                        color: dark
                            ? Colors.black54
                            : Colors.white.withValues(alpha: 0.6),
                        blurRadius: 8)
                  ])),
              const SizedBox(height: 2),
              Text(widget.dateLine,
                  style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 2,
                      color: dark
                          ? const Color(0xFFDDE2F5)
                          : tx2)),
              if (skyLine(now).isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(skyLine(now),
                    style: TextStyle(
                        fontSize: 12,
                        color: dark
                            ? const Color(0xFFDDE2F5)
                            : tx2)),
              ],
            ],
          ),
        ),
        // birdsong answering the quiet - in the sky band, theirs
        Positioned(
          left: 0,
          right: 0,
          top: 104,
          height: 32,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _still,
              builder: (context, _) {
                final a = ((_still.value - 0.4) / 0.3)
                    .clamp(0.0, 1.0);
                if (a == 0) return const SizedBox.shrink();
                return Stack(children: [
                  Align(
                    alignment: const Alignment(-0.3, 0),
                    child: Opacity(
                        opacity: a * 0.8,
                        child: const KidDrift(
                            amount: 4,
                            seed: 11,
                            child: Text('♪',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white)))),
                  ),
                  Align(
                    alignment: const Alignment(0.5, 0),
                    child: Opacity(
                        opacity: a * 0.6,
                        child: const KidDrift(
                            amount: 5,
                            seed: 13,
                            child: Text('♫',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white)))),
                  ),
                ]);
              },
            ),
          ),
        ),
        // Row A - on the hilltops: signpost left, the animal right
        Positioned(
          left: 20,
          top: 140,
          width: 144,
          child: _WorldThing(
            emoji: '🪧',
            emojiSize: 36,
            label: "today's wonder",
            semantics: "The signpost with today's wonder",
            onTap: () => _openWonder(context),
          ),
        ),
        Positioned(
          right: 20,
          top: 140,
          width: 144,
          child: _WorldThing(
            emoji: sp.emoji,
            emojiSize: 34,
            label: dark ? 'awake right now' : 'out there today',
            semantics: '${sp.name}, '
                '${dark ? "awake" : "out there"} right now. '
                'Opens the Living Atlas.',
            onTap: () {
              FieldGuide.meet(sp.id);
              Navigator.of(context)
                  .push(risePush(AtlasPage(species: sp)));
            },
          ),
        ),
        // Row B - on the lower slope: path left, tracks right
        if (next != null && p != null)
          Positioned(
            left: 20,
            top: 260,
            width: 144,
            child: _WorldThing(
              emoji: '🥾',
              emojiSize: 30,
              label:
                  'your path · ${walk.pathProgress(p, earned)} 🍃',
              semantics:
                  'Your path: next chapter, ${next.title}',
              onTap: () {
                Navigator.of(context)
                    .push(risePush(
                        ChapterPage(path: p, chapter: next)))
                    .then((_) =>
                        FieldGuide.earnedChapterIds().then((e) {
                          if (mounted) {
                            setState(() => earned = e);
                          }
                        }));
              },
            ),
          ),
        Positioned(
          right: 20,
          top: 260,
          width: 144,
          child: _WorldThing(
            emoji: '🐾',
            emojiSize: 28,
            label: 'follow the tracks',
            semantics: "This week's mystery: ${m.title}. "
                'Follow the tracks.',
            onTap: () {
              Navigator.of(context)
                  .push(risePush(const MysteryScreen()));
            },
          ),
        ),
        // the visitors' strip (212-248): exclusively theirs -
        // known friends at the sides, and dead center, the SHY ONE
        // who only rises for a still hand. The vertical band map
        // (greeting, sky notes, Row A, this strip, Row B, whisper,
        // fade) keeps overlap impossible by construction.
        Positioned(
          left: 0,
          right: 0,
          top: 212,
          height: 36,
          child: Stack(children: [
            if (visitors.isNotEmpty)
              Align(
                  alignment: const Alignment(-0.45, 0),
                  child: _Visitor(species: visitors[0], seed: 3)),
            if (visitors.length > 1)
              Align(
                  alignment: const Alignment(0.45, 0),
                  child: _Visitor(species: visitors[1], seed: 5)),
            if (shy != null)
              Align(
                alignment: Alignment.center,
                child: AnimatedBuilder(
                  animation: _still,
                  builder: (context, _) {
                    final rise = ((_still.value - 0.55) / 0.45)
                        .clamp(0.0, 1.0);
                    if (rise == 0) return const SizedBox.shrink();
                    final arrived = _still.value >= 1.0;
                    return Semantics(
                      button: arrived,
                      label: arrived
                          ? '${shy.name} came out to see you. '
                              'Tap to say hello.'
                          : '${shy.name}, peeking out',
                      child: ExcludeSemantics(
                        child: InkResponse(
                          radius: 26,
                          onTap: !arrived
                              ? null
                              : () async {
                                  Haptics.settle();
                                  Sfx.play('pop', volume: 0.5);
                                  setState(() => _shyMet = true);
                                  await FieldGuide.meet(shy.id);
                                  if (!mounted) return;
                                  await Navigator.of(context).push(
                                      risePush(AtlasPage(
                                          species: shy)));
                                  if (!mounted) return;
                                  final m2 = await FieldGuide
                                      .metSpecies();
                                  if (!mounted) return;
                                  setState(() {
                                    met = m2;
                                    _shyMet = false;
                                    _stillStage = 0;
                                    _still.value = 0.0;
                                  });
                                },
                          child: SizedBox(
                            width: 48,
                            height: 36,
                            child: ClipRect(
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Transform.translate(
                                  offset: Offset(
                                      0, (1.0 - rise) * 26.0),
                                  child: Opacity(
                                    opacity:
                                        0.4 + 0.6 * rise,
                                    child: SizedBox(
                                      height: 28,
                                      child: FittedBox(
                                          fit: BoxFit.contain,
                                          child: Text(shy.emoji,
                                              style:
                                                  const TextStyle(
                                                      fontSize:
                                                          24))),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ]),
        ),
        // the whisper line - the stillness speaks from the fade
        Positioned(
          left: 16,
          right: 16,
          bottom: 6,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _still,
              builder: (context, _) {
                final line = _stillLine(shy);
                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: line.isEmpty ? 0.0 : 1.0,
                  child: Text(
                    line,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: tx2),
                  ),
                );
              },
            ),
          ),
        ),
      ]),
    );
  }

  void _openWonder(BuildContext context) {
    final w = wonderOfDay(DateTime.now());
    final y = wonderOfYesterday(DateTime.now());
    Sfx.play('flip', volume: 0.4);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: paper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(26))),
      builder: (ctx) => _WonderSheet(w: w, y: y),
    );
  }
}

/// A visitor from your field guide, drifting gently on the hill.
/// No label - ambient life does not advertise - but screen readers
/// still know exactly who came by.
class _Visitor extends StatelessWidget {
  final AtlasSpecies species;
  final int seed;
  const _Visitor({required this.species, required this.seed});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${species.name}, visiting your hillside. '
          'Opens the Living Atlas.',
      child: ExcludeSemantics(
        child: InkResponse(
          radius: 26,
          onTap: () {
            Haptics.tick();
            Sfx.play('pop', volume: 0.4);
            Navigator.of(context)
                .push(risePush(AtlasPage(species: species)));
          },
          child: SizedBox(
            width: 48,
            height: 36,
            child: Center(
              child: KidDrift(
                amount: 3,
                seed: seed,
                child: SizedBox(
                  height: 24,
                  child: FittedBox(
                      fit: BoxFit.contain,
                      child: Text(species.emoji,
                          style:
                              const TextStyle(fontSize: 24))),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A thing that lives in the world: an emoji actor with a small
/// paper label, softly tappable, honestly labeled.
class _WorldThing extends StatelessWidget {
  final String emoji;
  final double emojiSize;
  final String label;
  final String semantics;
  final VoidCallback onTap;
  const _WorldThing({
    required this.emoji,
    required this.emojiSize,
    required this.label,
    required this.semantics,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        button: true,
        label: semantics,
        child: ExcludeSemantics(
          child: InkResponse(
            onTap: () {
              Haptics.tick();
              Sfx.play('tick', volume: 0.3);
              onTap();
            },
            radius: 44,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: emojiSize + 4,
                  child: FittedBox(
                      fit: BoxFit.contain,
                      child: Text(emoji,
                          style:
                              const TextStyle(fontSize: 32))),
                ),
                const SizedBox(height: 2),
                Container(
                  height: 22,
                  constraints:
                      const BoxConstraints(maxWidth: 128),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: ink)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The note from the signpost, unfolded.
class _WonderSheet extends StatefulWidget {
  final Wonder w, y;
  const _WonderSheet({required this.w, required this.y});

  @override
  State<_WonderSheet> createState() => _WonderSheetState();
}

class _WonderSheetState extends State<_WonderSheet> {
  bool open = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(26, 24, 26, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('TODAY\'S WONDER',
                style: TextStyle(
                    fontSize: 10.5, letterSpacing: 2, color: tx2)),
            const SizedBox(height: 10),
            Text(widget.w.q, style: serif(19)),
            const SizedBox(height: 10),
            Text('🔎 ${widget.w.notice}',
                style: const TextStyle(
                    fontSize: 13.5, height: 1.6, color: tx2)),
            const SizedBox(height: 14),
            Semantics(
              button: true,
              expanded: open,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  Haptics.tick();
                  setState(() => open = !open);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                      open
                          ? 'Yesterday: ${widget.y.q}'
                          : 'Yesterday\'s answer ▾',
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: fern)),
                ),
              ),
            ),
            if (open) ...[
              const SizedBox(height: 6),
              Text(widget.y.a,
                  style: const TextStyle(
                      fontSize: 13.5, height: 1.65, color: ink)),
            ],
            const SizedBox(height: 8),
            const Text(
                'Today\'s answer arrives tomorrow morning - the '
                'looking comes first.',
                style: TextStyle(fontSize: 11.5, color: tx2)),
          ],
        ),
      ),
    );
  }
}
