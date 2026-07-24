// Memory Meadow - a matching game with a twist that carries the whole
// lesson: you never match two identical cards, you match an animal to
// its HOME. Fox to den, bird to nest, bee to hive - the pairs ARE the
// ecology. Cards flip in real 3D with a leaf-pattern back, a mismatch
// simply turns quietly back over (no buzzer, no scold - the meadow is
// patient), and the finished board says what habitat means. Lovely for
// taking turns; nothing counts who found more.

import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/haptics.dart';
import '../../../core/kid_theme.dart';

// ---------- pure logic (tested) ----------

class MeadowCard {
  final int pair; // cards match when pair is equal and kind differs
  final bool isHome;
  final String emo, label;
  const MeadowCard(this.pair, this.isHome, this.emo, this.label);
}

const meadowPairs = [
  (('🦊', 'Fox'), ('🕳️', 'Den')),
  (('🐦', 'Bird'), ('🪺', 'Nest')),
  (('🐝', 'Bee'), ('🍯', 'Hive')),
  (('🐸', 'Frog'), ('🪷', 'Pond')),
  (('🐿️', 'Squirrel'), ('🌳', 'Tree')),
  (('🐻', 'Bear'), ('⛰️', 'Cave')),
];

/// A shuffled deck of twelve cards, deterministic per seed - the same
/// round replays identically, a new round deals fresh.
List<MeadowCard> meadowDeck(int seed) {
  final cards = <MeadowCard>[];
  for (var i = 0; i < meadowPairs.length; i++) {
    final (a, h) = meadowPairs[i];
    cards.add(MeadowCard(i, false, a.$1, a.$2));
    cards.add(MeadowCard(i, true, h.$1, h.$2));
  }
  final r = Random(seed);
  for (var i = cards.length - 1; i > 0; i--) {
    final j = r.nextInt(i + 1);
    final t = cards[i];
    cards[i] = cards[j];
    cards[j] = t;
  }
  return cards;
}

/// The rule of the meadow: an animal matches its home, never its twin.
bool meadowMatch(MeadowCard a, MeadowCard b) =>
    a.pair == b.pair && a.isHome != b.isHome;

class MeadowCopy {
  static const intro = 'Every animal has a home. Flip two cards - '
      'can you bring them together?';
  static const done =
      'Every animal found its home. That is what a habitat is - '
      'the place that fits you exactly.';
  static const fact =
      '🌿 Protecting an animal always means protecting its home too.';
}

// ---------- the game ----------

class MemoryMeadow extends StatefulWidget {
  final void Function(String) speak;
  const MemoryMeadow({super.key, required this.speak});

  @override
  State<MemoryMeadow> createState() => _MemoryMeadowState();
}

class _MemoryMeadowState extends State<MemoryMeadow> {
  int round = DateTime.now().day;
  late List<MeadowCard> deck = meadowDeck(round);
  final faceUp = <int>{};
  final matched = <int>{};
  bool busy = false;

  Future<void> _flip(int i) async {
    if (busy || faceUp.contains(i) || matched.contains(i)) return;
    Haptics.tick();
    setState(() => faceUp.add(i));
    if (faceUp.length < 2) return;
    busy = true;
    final pair = faceUp.toList();
    await Future.delayed(const Duration(milliseconds: 750));
    if (!mounted) return;
    if (meadowMatch(deck[pair[0]], deck[pair[1]])) {
      Haptics.settle();
      setState(() {
        matched.addAll(pair);
        faceUp.clear();
      });
      final animal = deck[pair[0]].isHome ? deck[pair[1]] : deck[pair[0]];
      final home = deck[pair[0]].isHome ? deck[pair[0]] : deck[pair[1]];
      widget.speak('${animal.label} found the ${home.label.toLowerCase()}!');
      if (matched.length == deck.length) {
        widget.speak(MeadowCopy.done);
      }
    } else {
      // the meadow is patient: cards simply turn back over
      setState(() => faceUp.clear());
    }
    busy = false;
  }

  @override
  Widget build(BuildContext context) {
    final done = matched.length == deck.length;
    return Scaffold(
      backgroundColor: kidCream,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 8, 4),
            child: Row(children: [
              Expanded(
                  child: Text('🏡 Memory meadow', style: kidTitle(20))),
              IconButton(
                  tooltip: 'Leave the meadow',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close,
                      color: kidInkLight, size: 20)),
            ]),
          ),
          Text(
              done
                  ? 'every home is full 🌟'
                  : matched.isEmpty && faceUp.isEmpty
                      ? MeadowCopy.intro
                      : '${matched.length ~/ 2} of ${deck.length ~/ 2} '
                          'homes found',
              textAlign: TextAlign.center,
              style: kidBody(13, color: kidInkLight)),
          const SizedBox(height: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.78),
                itemCount: deck.length,
                itemBuilder: (_, i) => _FlipCard(
                  card: deck[i],
                  up: faceUp.contains(i) || matched.contains(i),
                  matched: matched.contains(i),
                  onTap: () => _flip(i),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: done
                ? Column(children: [
                    Text(MeadowCopy.done,
                        textAlign: TextAlign.center,
                        style: kidBody(13.5)),
                    const SizedBox(height: 6),
                    Text(MeadowCopy.fact,
                        textAlign: TextAlign.center,
                        style: kidBody(12.5)),
                    const SizedBox(height: 10),
                    KidSquish(
                      onTap: () => setState(() {
                        round++;
                        deck = meadowDeck(round);
                        matched.clear();
                        faceUp.clear();
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                            color: kidLeaf,
                            borderRadius: BorderRadius.circular(22)),
                        child: Text('🏡 Deal a new meadow',
                            style: kidTitle(14)),
                      ),
                    ),
                  ])
                : Text('take turns with someone - the meadow loves company',
                    style: kidBody(11.5, color: kidInkLight)),
          ),
        ]),
      ),
    );
  }
}

/// A real 3D flip: the card turns around its vertical axis with
/// perspective, leaf-pattern back to painted face.
class _FlipCard extends StatelessWidget {
  final MeadowCard card;
  final bool up, matched;
  final VoidCallback onTap;
  const _FlipCard(
      {required this.card,
      required this.up,
      required this.matched,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return KidSquish(
      semanticLabel: up ? '${card.label}' : 'A face-down card',
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: up ? 0 : 1, end: up ? 1 : 0),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
        builder: (_, t, __) {
          final angle = t * pi;
          final showingFace = angle > pi / 2;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012) // perspective
              ..rotateY(angle),
            child: showingFace
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(pi),
                    child: _face(),
                  )
                : _back(),
          );
        },
      ),
    );
  }

  Widget _face() => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: matched
              ? kidLeaf.withValues(alpha: 0.45)
              : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: matched
                  ? kidLeafDeep
                  : kidInk.withValues(alpha: 0.15),
              width: 2.5),
        ),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(card.emo, style: const TextStyle(fontSize: 38)),
              const SizedBox(height: 4),
              Text(card.label, style: kidTitle(12.5)),
            ]),
      );

  Widget _back() => Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8FBF6E), Color(0xFF6FAE54)]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: kidInk.withValues(alpha: 0.15), width: 2.5),
        ),
        child: const Center(
            child: Text('🍃',
                style: TextStyle(fontSize: 30, color: Colors.white))),
      );
}
