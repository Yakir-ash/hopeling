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

class _HillsideHomeState extends State<HillsideHome> {
  Set<String> earned = {};

  @override
  void initState() {
    super.initState();
    FieldGuide.earnedChapterIds().then((e) {
      if (mounted) setState(() => earned = e);
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dark = skyIsDark(now);
    final onSky = dark ? Colors.white : ink;
    final sp = speciesOfDay(now, dark: dark);
    final m = mysteryOfWeek(now);
    final p = walk.continuePath(earned);
    final next = p == null ? null : walk.nextChapter(p, earned);

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
            top: 252,
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
          top: 252,
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
                Text(emoji, style: TextStyle(fontSize: emojiSize)),
                const SizedBox(height: 3),
                Container(
                  constraints:
                      const BoxConstraints(maxWidth: 128),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
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
