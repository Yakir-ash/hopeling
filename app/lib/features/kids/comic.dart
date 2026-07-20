// Comic books for story time. Every story on the shelf becomes a little
// comic: a host animal walks the child through it, one panel at a time,
// with the story's own words in speech bubbles. Everything is drawn on
// the device - deterministic scenes, no downloads, no strangers' art,
// nothing to buy. The words are the lesson's words, never invented.

import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../data/content.dart';
import '../../data/kids.dart';

// ---------- pure panel logic (tested) ----------

class ComicPanel {
  final String kind; // cover | scene | end
  final String caption;
  final int seed; // deterministic scenery
  ComicPanel(this.kind, this.caption, this.seed);
}

int _hash(String s) {
  var h = 0;
  for (final c in s.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return h;
}

/// The host: a friendly animal cast from the story itself. Keywords in
/// the title and text pick a fitting host; otherwise the title chooses
/// one deterministically, so a story always keeps its narrator.
const _cast = ['🦊', '🐢', '🐿️', '🦔', '🐇'];
const _keywordHosts = [
  ['ocean', '🐋'], ['sea', '🐬'], ['coral', '🐠'], ['fish', '🐟'],
  ['whale', '🐋'], ['bee', '🐝'], ['pollinat', '🐝'],
  ['butterfl', '🦋'], ['bird', '🐦'], ['forest', '🦉'], ['tree', '🦉'],
  ['river', '🐸'], ['frog', '🐸'], ['water', '💧'],
  ['ice', '🐧'], ['arctic', '🐧'], ['polar', '🐻‍❄️'],
  ['elephant', '🐘'], ['soil', '🐛'], ['garden', '🐛'],
  ['plastic', '🐢'], ['climate', '🌍'], ['energy', '☀️'],
  ['food', '🐿️'], ['farm', '🐄'], ['wolf', '🐺'], ['panda', '🐼'],
];

String comicHost(String title, String text) {
  final low = '$title $text'.toLowerCase();
  for (final kh in _keywordHosts) {
    if (low.contains(kh[0])) return kh[1];
  }
  return _cast[_hash(title) % _cast.length];
}

/// Split the simple telling into panels: one or two short sentences
/// each, never more than ten scene panels, and not one word dropped -
/// if the story runs long, the last panels simply carry more.
List<String> comicCaptions(String text) {
  final sentences = text
      .split(RegExp(r'(?<=[.!?])\s+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();
  if (sentences.isEmpty) return [];
  final captions = <String>[];
  var i = 0;
  while (i < sentences.length) {
    final remainingPanels = 10 - captions.length;
    final remainingSentences = sentences.length - i;
    if (remainingPanels <= 1) {
      captions.add(sentences.sublist(i).join(' '));
      break;
    }
    // pair short sentences; let a long one stand alone
    final take = (sentences[i].length < 60 &&
            i + 1 < sentences.length &&
            remainingSentences > remainingPanels)
        ? 2
        : 1;
    captions.add(sentences.sublist(i, i + take).join(' '));
    i += take;
  }
  return captions;
}

List<ComicPanel> comicPanels(Lesson l) {
  final text = KidPolicy.lessonText(l);
  final caps = comicCaptions(text);
  if (caps.isEmpty) return [];
  final base = _hash(l.t);
  return [
    ComicPanel('cover', l.t, base),
    for (var i = 0; i < caps.length; i++)
      ComicPanel('scene', caps[i], base + 7 * (i + 1)),
    ComicPanel('end', 'The end 🌟', base + 997),
  ];
}

// ---------- the reader ----------

class ComicReader extends StatefulWidget {
  final Lesson lesson;
  final String band; // early | ranger | young
  final void Function(String) speak;
  final VoidCallback stopSpeaking;
  final VoidCallback onFinished; // marks the star, once
  const ComicReader(
      {super.key,
      required this.lesson,
      required this.band,
      required this.speak,
      required this.stopSpeaking,
      required this.onFinished});

  @override
  State<ComicReader> createState() => _ComicReaderState();
}

class _ComicReaderState extends State<ComicReader> {
  late final List<ComicPanel> panels = comicPanels(widget.lesson);
  late final String host =
      comicHost(widget.lesson.t, KidPolicy.lessonText(widget.lesson));
  final controller = PageController();
  int page = 0;

  @override
  void initState() {
    super.initState();
    if (panels.isNotEmpty) widget.speak(panels.first.caption);
  }

  @override
  void dispose() {
    widget.stopSpeaking();
    controller.dispose();
    super.dispose();
  }

  void _turned(int i) {
    setState(() => page = i);
    Haptics.tick();
    widget.speak(panels[i].caption);
  }

  @override
  Widget build(BuildContext context) {
    final big = widget.band == 'early';
    return Scaffold(
      backgroundColor: const Color(0xFFF2F8EF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 8, 0),
              child: Row(children: [
                Expanded(
                    child: Text(widget.lesson.t,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: serif(16))),
                IconButton(
                    tooltip: 'Close the book',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: tx2, size: 20)),
              ]),
            ),
            Expanded(
              child: PageView.builder(
                controller: controller,
                onPageChanged: _turned,
                itemCount: panels.length,
                itemBuilder: (_, i) => _PanelPage(
                  panel: panels[i],
                  host: host,
                  big: big,
                  pageOf: '${i + 1} / ${panels.length}',
                  onHear: () => widget.speak(panels[i].caption),
                  onFinish: panels[i].kind == 'end'
                      ? () {
                          widget.onFinished();
                          Navigator.of(context).pop();
                        }
                      : null,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 14, top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < panels.length; i++)
                    Container(
                      width: i == page ? 18 : 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                          color: i == page ? fern : mint,
                          borderRadius: BorderRadius.circular(4)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelPage extends StatelessWidget {
  final ComicPanel panel;
  final String host;
  final bool big;
  final String pageOf;
  final VoidCallback onHear;
  final VoidCallback? onFinish;
  const _PanelPage(
      {required this.panel,
      required this.host,
      required this.big,
      required this.pageOf,
      required this.onHear,
      this.onFinish});

  @override
  Widget build(BuildContext context) {
    final r = Random(panel.seed);
    const props = ['🌸', '🍃', '☁️', '⭐', '🌿', '🍄', '🌼', '🦋'];
    final chosen = List.generate(3, (_) => props[r.nextInt(props.length)]);
    final spots = List.generate(
        3, (_) => Offset(0.1 + r.nextDouble() * 0.8, 0.08 + r.nextDouble() * 0.4));
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        children: [
          // the panel: a drawn scene behind the host
          Expanded(
            child: GestureDetector(
              onTap: onHear,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: ink, width: 3),
                  borderRadius: BorderRadius.circular(18),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned.fill(
                        child: CustomPaint(
                            painter: _ScenePainter(panel.seed))),
                    for (var i = 0; i < chosen.length; i++)
                      Align(
                        alignment: Alignment(
                            spots[i].dx * 2 - 1, spots[i].dy * 2 - 1),
                        child: Text(chosen[i],
                            style: const TextStyle(fontSize: 26)),
                      ),
                    Align(
                      alignment: const Alignment(0, 0.72),
                      child: Text(panel.kind == 'end' ? '🌟' : host,
                          style: TextStyle(
                              fontSize: panel.kind == 'cover' ? 84 : 64)),
                    ),
                    Positioned(
                      right: 10,
                      bottom: 8,
                      child: Text(pageOf,
                          style: const TextStyle(
                              fontSize: 11, color: tx2)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // the speech bubble
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: ink, width: 2),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(children: [
              Text(panel.caption,
                  textAlign: TextAlign.center,
                  style: panel.kind == 'cover'
                      ? serif(big ? 26 : 22, height: 1.3)
                      : TextStyle(
                          fontFamily: 'serif',
                          fontSize: big ? 20 : 16.5,
                          height: 1.7,
                          color: ink)),
              if (panel.kind == 'cover')
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('swipe to turn the page →',
                      style: TextStyle(fontSize: 12.5, color: tx2)),
                ),
              if (onFinish != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: fern, foregroundColor: paper),
                    onPressed: onFinish,
                    child: const Text('Put the book back 🌟'),
                  ),
                ),
            ]),
          ),
        ],
      ),
    );
  }
}

/// Deterministic scenery: a time of day, soft hills, a sun or moon.
/// The same page of the same story always looks the same - a book,
/// not a slot machine.
class _ScenePainter extends CustomPainter {
  final int seed;
  _ScenePainter(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(seed);
    final variant = r.nextInt(4); // dawn, day, dusk, meadow
    const skies = [
      [Color(0xFFFFE9D6), Color(0xFFFFF7EC)],
      [Color(0xFFD9EFFF), Color(0xFFF0FAFF)],
      [Color(0xFFE8DDF7), Color(0xFFFDF1E3)],
      [Color(0xFFE4F6DC), Color(0xFFF7FDF0)],
    ];
    final sky = Paint()
      ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: skies[variant])
          .createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    // sun or moon
    final sunX = size.width * (0.2 + r.nextDouble() * 0.6);
    canvas.drawCircle(
        Offset(sunX, size.height * 0.2),
        size.width * 0.07,
        Paint()
          ..color = (variant == 2 ? const Color(0xFFF6EFC1) : const Color(0xFFFFD98A))
              .withValues(alpha: 0.9));

    // two soft hills
    for (final (dy, alpha) in [(0.78, 0.5), (0.88, 0.8)]) {
      final path = Path()..moveTo(0, size.height);
      for (double x = 0; x <= size.width; x += size.width / 24) {
        path.lineTo(
            x,
            size.height * dy +
                sin(x / size.width * pi * 2 + seed % 7) * size.height * 0.03);
      }
      path
        ..lineTo(size.width, size.height)
        ..close();
      canvas.drawPath(
          path, Paint()..color = mint.withValues(alpha: alpha));
    }
  }

  @override
  bool shouldRepaint(_ScenePainter old) => old.seed != seed;
}
