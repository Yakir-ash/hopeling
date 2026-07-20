// Comic books for story time. Every story on the shelf becomes a little
// comic: a host animal walks the child through it, one panel at a time,
// with the story's own words in speech bubbles. Everything is drawn on
// the device - each story casts a whole scene family (an ocean book, a
// forest book, a night book...) painted with depth: waves and light
// rays, layered trees, star fields, auroras, a winding river. All of it
// deterministic - the same page of the same story always looks the
// same. A book, not a slot machine. No downloads, no strangers' art,
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

/// Every book lives in one world. The scene family is cast from the
/// story just like the host, so an ocean story is an ocean book from
/// cover to end - waves on every page, not a different backdrop each
/// time the child looks.
enum ComicScene { ocean, meadow, forest, night, ice, river }

const _sceneWords = [
  ['ocean', 'ocean'], ['sea', 'ocean'], ['coral', 'ocean'],
  ['whale', 'ocean'], ['plastic', 'ocean'], ['fish', 'ocean'],
  ['bee', 'meadow'], ['pollinat', 'meadow'], ['butterfl', 'meadow'],
  ['flower', 'meadow'], ['garden', 'meadow'], ['farm', 'meadow'],
  ['forest', 'forest'], ['tree', 'forest'], ['wolf', 'forest'],
  ['panda', 'forest'], ['soil', 'forest'],
  ['night', 'night'], ['bat', 'night'], ['star', 'night'],
  ['moon', 'night'], ['dark', 'night'],
  ['ice', 'ice'], ['arctic', 'ice'], ['polar', 'ice'], ['snow', 'ice'],
  ['river', 'river'], ['frog', 'river'], ['rain', 'river'],
  ['water', 'river'], ['wetland', 'river'],
];

ComicScene sceneOf(String title, String text) {
  final low = '$title $text'.toLowerCase();
  for (final sw in _sceneWords) {
    if (low.contains(sw[0])) {
      return ComicScene.values.firstWhere((s) => s.name == sw[1]);
    }
  }
  return const [ComicScene.meadow, ComicScene.forest, ComicScene.river][
      _hash(title) % 3];
}

/// Scene-true props, placed low in the world where things live -
/// shells on the seabed, mushrooms under the trees.
const _sceneProps = {
  ComicScene.ocean: ['🐚', '🫧', '🐠', '🪸', '⭐'],
  ComicScene.meadow: ['🌼', '🦋', '🌷', '🍀', '🐞'],
  ComicScene.forest: ['🍄', '🍂', '🌱', '🦋', '🐿️'],
  ComicScene.night: ['✨', '🌾', '🍃', '🦉', '🌙'],
  ComicScene.ice: ['❄️', '✨', '🐟', '🌨️', '💎'],
  ComicScene.river: ['🌾', '🪷', '🐟', '💧', '🍃'],
};

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
  late final ComicScene scene =
      sceneOf(widget.lesson.t, KidPolicy.lessonText(widget.lesson));
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
      backgroundColor: const Color(0xFFFBF6EA), // old paper
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
                  key: ValueKey('panel$i'),
                  panel: panels[i],
                  scene: scene,
                  host: host,
                  big: big,
                  index: i,
                  count: panels.length,
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
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
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

class _PanelPage extends StatefulWidget {
  final ComicPanel panel;
  final ComicScene scene;
  final String host;
  final bool big;
  final int index, count;
  final VoidCallback onHear;
  final VoidCallback? onFinish;
  const _PanelPage(
      {super.key,
      required this.panel,
      required this.scene,
      required this.host,
      required this.big,
      required this.index,
      required this.count,
      required this.onHear,
      this.onFinish});

  @override
  State<_PanelPage> createState() => _PanelPageState();
}

class _PanelPageState extends State<_PanelPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController bob = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2400));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !Motion.still(context)) bob.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.panel;
    final still = Motion.still(context);
    final r = Random(p.seed);
    final props = _sceneProps[widget.scene]!;
    final chosen = List.generate(3, (_) => props[r.nextInt(props.length)]);
    // props live low in the scene, where the ground and water are
    final spots = List.generate(
        3,
        (_) => Offset(
            0.08 + r.nextDouble() * 0.84, 0.55 + r.nextDouble() * 0.3));
    final tilt = p.kind == 'scene' ? (p.seed % 2 == 0 ? 0.006 : -0.006) : 0.0;

    Widget hostFig = Text(p.kind == 'end' ? '🌟' : widget.host,
        style: TextStyle(fontSize: p.kind == 'cover' ? 92 : 68));
    if (!still) {
      hostFig = AnimatedBuilder(
        animation: bob,
        builder: (_, child) => Transform.translate(
            offset: Offset(0, -4 * Curves.easeInOut.transform(bob.value)),
            child: child),
        child: hostFig,
      );
    }

    final panelBody = Transform.rotate(
      angle: tilt,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: ink, width: 3),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: ink.withValues(alpha: 0.18),
                blurRadius: 0,
                offset: const Offset(5, 6)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
                child: CustomPaint(
                    painter: _ScenePainter(
                        p.seed, widget.scene, p.kind == 'cover'))),
            for (var i = 0; i < chosen.length; i++)
              Align(
                alignment:
                    Alignment(spots[i].dx * 2 - 1, spots[i].dy * 2 - 1),
                child: Transform.scale(
                  scaleX: r.nextBool() ? 1 : -1,
                  child: Text(chosen[i],
                      style: TextStyle(fontSize: 20.0 + r.nextInt(12))),
                ),
              ),
            // the host, grounded by a soft shadow
            Align(
              alignment: const Alignment(0, 0.88),
              child: Container(
                width: 90,
                height: 14,
                decoration: BoxDecoration(
                    color: ink.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20)),
              ),
            ),
            Align(alignment: const Alignment(0, 0.72), child: hostFig),
            // comic-style page tag
            if (p.kind == 'scene')
              Positioned(
                left: 10,
                top: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFF3C9),
                      border: Border.all(color: ink, width: 1.5),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text('PAGE ${widget.index} OF ${widget.count - 2}',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: ink)),
                ),
              ),
            if (p.kind == 'cover')
              Positioned(
                left: 0,
                right: 0,
                top: 12,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                        color: fern,
                        borderRadius: BorderRadius.circular(20)),
                    child: const Text('A HOPELING LITTLE COMIC',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            color: paper)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: widget.onHear,
              child: still
                  ? panelBody
                  : TweenAnimationBuilder<double>(
                      key: ValueKey(p.seed),
                      tween: Tween(begin: 0.96, end: 1),
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOutBack,
                      builder: (_, v, child) => Transform.scale(
                          scale: v,
                          child:
                              Opacity(opacity: v.clamp(0, 1), child: child)),
                      child: panelBody,
                    ),
            ),
          ),
          const SizedBox(height: 14),
          // the speech bubble, tail up toward the host
          CustomPaint(
            painter: _BubblePainter(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
              child: Column(children: [
                Text(p.caption,
                    textAlign: TextAlign.center,
                    style: p.kind == 'cover'
                        ? serif(widget.big ? 26 : 22, height: 1.3)
                        : TextStyle(
                            fontFamily: 'serif',
                            fontSize: widget.big ? 20 : 16.5,
                            height: 1.7,
                            color: ink)),
                if (p.kind == 'cover')
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('swipe to turn the page →',
                        style: TextStyle(fontSize: 12.5, color: tx2)),
                  ),
                if (widget.onFinish != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: fern, foregroundColor: paper),
                      onPressed: widget.onFinish,
                      child: const Text('Put the book back 🌟'),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// The white speech bubble with an ink outline and a tail reaching up
/// toward whoever is talking.
class _BubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const tailW = 22.0, tailH = 14.0;
    final body = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, tailH, size.width, size.height - tailH),
        const Radius.circular(22));
    final tail = Path()
      ..moveTo(size.width / 2 - tailW / 2, tailH + 2)
      ..lineTo(size.width / 2 - 2, 0)
      ..lineTo(size.width / 2 + tailW / 2, tailH + 2)
      ..close();
    final fill = Paint()..color = Colors.white;
    final line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRRect(body, fill);
    canvas.drawPath(tail, fill);
    canvas.drawRRect(body, line);
    canvas.drawPath(tail, line);
    // hide the seam where the tail meets the body
    canvas.drawRect(
        Rect.fromLTWH(size.width / 2 - tailW / 2 + 2, tailH - 1.4,
            tailW - 4, 4),
        fill);
  }

  @override
  bool shouldRepaint(_BubblePainter old) => false;
}

// ---------- painted worlds ----------
// One painter, six scene families, all seeded. Depth comes from layers:
// far things pale, near things bold, light on top.
class _ScenePainter extends CustomPainter {
  final int seed;
  final ComicScene scene;
  final bool burst; // the cover gets a sunburst of excitement
  _ScenePainter(this.seed, this.scene, this.burst);

  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(seed);
    switch (scene) {
      case ComicScene.ocean:
        _ocean(canvas, size, r);
      case ComicScene.meadow:
        _meadow(canvas, size, r);
      case ComicScene.forest:
        _forest(canvas, size, r);
      case ComicScene.night:
        _night(canvas, size, r);
      case ComicScene.ice:
        _ice(canvas, size, r);
      case ComicScene.river:
        _river(canvas, size, r);
    }
    if (burst) _sunburst(canvas, size);
    _halftone(canvas, size, r);
  }

  void _sky(Canvas c, Size s, List<Color> colors) {
    c.drawRect(
        Offset.zero & s,
        Paint()
          ..shader = LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: colors)
              .createShader(Offset.zero & s));
  }

  void _sun(Canvas c, Size s, Random r, Color color) {
    final o = Offset(s.width * (0.2 + r.nextDouble() * 0.6), s.height * 0.18);
    c.drawCircle(o, s.width * 0.11,
        Paint()..color = color.withValues(alpha: 0.35));
    c.drawCircle(o, s.width * 0.07, Paint()..color = color);
  }

  void _cloud(Canvas c, Size s, Random r, double y, double alpha) {
    final x = s.width * r.nextDouble();
    final p = Paint()..color = Colors.white.withValues(alpha: alpha);
    for (final (dx, dy, rad) in [
      (0.0, 0.0, 0.045), (0.05, -0.012, 0.055), (0.11, 0.0, 0.042)
    ]) {
      c.drawCircle(Offset(x + s.width * dx, s.height * (y + dy)),
          s.width * rad, p);
    }
  }

  void _wavyBand(Canvas c, Size s, double topFrac, Color color,
      {double amp = 0.025, double waves = 2.5, double phase = 0}) {
    final path = Path()..moveTo(0, s.height);
    for (double x = 0; x <= s.width; x += s.width / 40) {
      path.lineTo(
          x,
          s.height * topFrac +
              sin(x / s.width * pi * waves + phase) * s.height * amp);
    }
    path
      ..lineTo(s.width, s.height)
      ..close();
    c.drawPath(path, Paint()..color = color);
  }

  void _ocean(Canvas c, Size s, Random r) {
    _sky(c, s,
        const [Color(0xFFCDEBFF), Color(0xFFA8DCFF), Color(0xFF7CC7F2)]);
    _sun(c, s, r, const Color(0xFFFFE59A));
    _cloud(c, s, r, 0.12, 0.8);
    // light rays into the water
    final ray = Paint()..color = Colors.white.withValues(alpha: 0.12);
    for (var i = 0; i < 3; i++) {
      final x = s.width * (0.2 + r.nextDouble() * 0.6);
      c.drawPath(
          Path()
            ..moveTo(x - 8, s.height * 0.36)
            ..lineTo(x + 8, s.height * 0.36)
            ..lineTo(x + 30, s.height)
            ..lineTo(x - 30, s.height)
            ..close(),
          ray);
    }
    _wavyBand(c, s, 0.42, const Color(0xFF5FB7EC), phase: seed % 5 * 1.0);
    _wavyBand(c, s, 0.52, const Color(0xFF3E9CD9),
        phase: 1.6, waves: 3, amp: 0.02);
    _wavyBand(c, s, 0.64, const Color(0xFF2C86C4), phase: 3.1);
    // seabed
    _wavyBand(c, s, 0.93, const Color(0xFFEAD9A8), waves: 4, amp: 0.012);
    // bubbles
    final bub = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (var i = 0; i < 7; i++) {
      c.drawCircle(
          Offset(s.width * r.nextDouble(),
              s.height * (0.45 + r.nextDouble() * 0.45)),
          2.0 + r.nextDouble() * 4,
          bub);
    }
  }

  void _meadow(Canvas c, Size s, Random r) {
    _sky(c, s, const [Color(0xFFFFEFD1), Color(0xFFD9EFFF)]);
    _sun(c, s, r, const Color(0xFFFFD98A));
    _cloud(c, s, r, 0.1, 0.9);
    _cloud(c, s, r, 0.2, 0.7);
    _wavyBand(c, s, 0.58, const Color(0xFFC5E8B0), waves: 1.5, amp: 0.04);
    _wavyBand(c, s, 0.7, const Color(0xFFA3D98A),
        waves: 2, amp: 0.03, phase: 2);
    _wavyBand(c, s, 0.82, const Color(0xFF7FC763), waves: 2.5, phase: 4);
    // painted flowers in the near grass
    for (var i = 0; i < 8; i++) {
      final o = Offset(s.width * r.nextDouble(),
          s.height * (0.72 + r.nextDouble() * 0.24));
      final col = [
        const Color(0xFFFFB3C7), const Color(0xFFFFE08A),
        const Color(0xFFC7A9F2), Colors.white
      ][r.nextInt(4)];
      for (var pth = 0; pth < 5; pth++) {
        final a = pth * 2 * pi / 5;
        c.drawCircle(o + Offset(cos(a) * 4, sin(a) * 4), 3,
            Paint()..color = col);
      }
      c.drawCircle(o, 2.6, Paint()..color = const Color(0xFFF2B01E));
    }
  }

  void _forest(Canvas c, Size s, Random r) {
    _sky(c, s, const [Color(0xFFFDF3D8), Color(0xFFDCEFC9)]);
    _sun(c, s, r, const Color(0xFFFFE8A3));
    // three depths of trees
    for (final (top, col) in [
      (0.34, const Color(0xFFB9DCA4)),
      (0.46, const Color(0xFF8FC479)),
      (0.6, const Color(0xFF67A954)),
    ]) {
      for (var i = 0; i < 6; i++) {
        final x = s.width * (i / 5.0) + (r.nextDouble() - 0.5) * 18;
        final h = s.height * (0.16 + r.nextDouble() * 0.08);
        final y = s.height * top;
        c.drawPath(
            Path()
              ..moveTo(x, y - h)
              ..lineTo(x + s.width * 0.09, y)
              ..lineTo(x - s.width * 0.09, y)
              ..close(),
            Paint()..color = col);
        c.drawRect(
            Rect.fromLTWH(x - 2.4, y, 4.8, s.height * 0.035),
            Paint()..color = const Color(0xFF8A6A4C));
      }
    }
    _wavyBand(c, s, 0.78, const Color(0xFF578F46), waves: 2, amp: 0.02);
    // light shafts
    final ray = Paint()..color = Colors.white.withValues(alpha: 0.14);
    for (var i = 0; i < 2; i++) {
      final x = s.width * (0.25 + r.nextDouble() * 0.5);
      c.drawPath(
          Path()
            ..moveTo(x - 6, 0)
            ..lineTo(x + 10, 0)
            ..lineTo(x + 44, s.height * 0.8)
            ..lineTo(x + 10, s.height * 0.8)
            ..close(),
          ray);
    }
  }

  void _night(Canvas c, Size s, Random r) {
    _sky(c, s,
        const [Color(0xFF223058), Color(0xFF3A4A7A), Color(0xFF56659B)]);
    // stars, a few of them twinkly crosses
    for (var i = 0; i < 26; i++) {
      final o =
          Offset(s.width * r.nextDouble(), s.height * r.nextDouble() * 0.55);
      final star = Paint()
        ..color = Colors.white.withValues(alpha: 0.5 + r.nextDouble() * 0.5);
      if (r.nextInt(5) == 0) {
        c.drawLine(o - const Offset(3.5, 0), o + const Offset(3.5, 0), star);
        c.drawLine(o - const Offset(0, 3.5), o + const Offset(0, 3.5), star);
      } else {
        c.drawCircle(o, 0.8 + r.nextDouble() * 1.2, star);
      }
    }
    // the moon, with craters
    final m = Offset(s.width * (0.25 + r.nextDouble() * 0.5), s.height * 0.2);
    c.drawCircle(m, s.width * 0.12,
        Paint()..color = const Color(0xFFF6EFC1).withValues(alpha: 0.25));
    c.drawCircle(m, s.width * 0.085, Paint()..color = const Color(0xFFF6EFC1));
    for (var i = 0; i < 3; i++) {
      c.drawCircle(
          m +
              Offset((r.nextDouble() - 0.5) * s.width * 0.09,
                  (r.nextDouble() - 0.5) * s.width * 0.09),
          s.width * (0.01 + r.nextDouble() * 0.012),
          Paint()..color = const Color(0xFFE3D9A4));
    }
    _wavyBand(c, s, 0.74, const Color(0xFF1B2749), waves: 1.5, amp: 0.05);
    _wavyBand(c, s, 0.86, const Color(0xFF121C38), waves: 2, phase: 2);
    // fireflies
    for (var i = 0; i < 6; i++) {
      c.drawCircle(
          Offset(s.width * r.nextDouble(),
              s.height * (0.6 + r.nextDouble() * 0.3)),
          1.6,
          Paint()
            ..color = const Color(0xFFFFF3A6).withValues(alpha: 0.9)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    }
  }

  void _ice(Canvas c, Size s, Random r) {
    _sky(c, s, const [Color(0xFFDDEBFA), Color(0xFFF3F9FF)]);
    // aurora ribbons
    for (final (col, y0) in [
      (const Color(0xFF9BE8C9), 0.1), (const Color(0xFFB9C9F5), 0.18)
    ]) {
      final path = Path()..moveTo(0, s.height * y0);
      for (double x = 0; x <= s.width; x += s.width / 30) {
        path.lineTo(x,
            s.height * y0 + sin(x / s.width * pi * 2 + seed % 4) * 14);
      }
      for (double x = s.width; x >= 0; x -= s.width / 30) {
        path.lineTo(
            x,
            s.height * (y0 + 0.1) +
                sin(x / s.width * pi * 2 + seed % 4) * 14);
      }
      path.close();
      c.drawPath(path, Paint()..color = col.withValues(alpha: 0.35));
    }
    _wavyBand(c, s, 0.62, const Color(0xFFCBE4F7), waves: 1.5, amp: 0.02);
    // icebergs
    for (var i = 0; i < 3; i++) {
      final x = s.width * (0.15 + i * 0.3) + (r.nextDouble() - 0.5) * 20;
      final y = s.height * 0.72;
      final w = s.width * (0.12 + r.nextDouble() * 0.08);
      c.drawPath(
          Path()
            ..moveTo(x, y - w * 0.9)
            ..lineTo(x + w * 0.55, y - w * 0.25)
            ..lineTo(x + w * 0.4, y)
            ..lineTo(x - w * 0.45, y)
            ..lineTo(x - w * 0.5, y - w * 0.3)
            ..close(),
          Paint()..color = Colors.white);
    }
    _wavyBand(c, s, 0.78, const Color(0xFFAFD3EE), waves: 2.5, amp: 0.015);
    // snowfall
    for (var i = 0; i < 14; i++) {
      c.drawCircle(
          Offset(s.width * r.nextDouble(), s.height * r.nextDouble()),
          1.2 + r.nextDouble(),
          Paint()..color = Colors.white.withValues(alpha: 0.85));
    }
  }

  void _river(Canvas c, Size s, Random r) {
    _sky(c, s, const [Color(0xFFE7F3D8), Color(0xFFFDF7E3)]);
    _sun(c, s, r, const Color(0xFFFFD98A));
    _cloud(c, s, r, 0.12, 0.8);
    _wavyBand(c, s, 0.5, const Color(0xFFB9DCA4), waves: 1.5, amp: 0.03);
    _wavyBand(c, s, 0.62, const Color(0xFF93C77E), waves: 2, phase: 2);
    // the river, winding from the horizon and widening
    final bend = (r.nextDouble() - 0.5) * s.width * 0.3;
    final river = Path()
      ..moveTo(s.width * 0.48 + bend, s.height * 0.52)
      ..quadraticBezierTo(s.width * 0.3, s.height * 0.7, s.width * 0.18,
          s.height)
      ..lineTo(s.width * 0.82, s.height)
      ..quadraticBezierTo(s.width * 0.6, s.height * 0.72,
          s.width * 0.54 + bend, s.height * 0.52)
      ..close();
    c.drawPath(river, Paint()..color = const Color(0xFF8FD0EA));
    // sparkles on the water
    final glint = Paint()..color = Colors.white.withValues(alpha: 0.7);
    for (var i = 0; i < 6; i++) {
      final t = 0.6 + r.nextDouble() * 0.35;
      c.drawLine(
          Offset(s.width * (0.3 + r.nextDouble() * 0.4), s.height * t),
          Offset(s.width * (0.3 + r.nextDouble() * 0.4) + 10, s.height * t),
          glint);
    }
    // reeds on the bank
    final reed = Paint()
      ..color = const Color(0xFF4F8B3B)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final x = (i < 3 ? 0.06 : 0.86) + r.nextDouble() * 0.08;
      final base = s.height * (0.86 + r.nextDouble() * 0.1);
      c.drawLine(Offset(s.width * x, base),
          Offset(s.width * x + 4, base - 26 - r.nextDouble() * 10), reed);
    }
  }

  /// A pale radial burst behind the cover host - the "ta-da" of a comic
  /// front page.
  void _sunburst(Canvas c, Size s) {
    final center = Offset(s.width / 2, s.height * 0.62);
    final p = Paint()..color = const Color(0xFFFFE59A).withValues(alpha: 0.3);
    for (var i = 0; i < 12; i++) {
      final a = i * pi / 6;
      c.drawPath(
          Path()
            ..moveTo(center.dx, center.dy)
            ..lineTo(center.dx + cos(a - 0.09) * s.width,
                center.dy + sin(a - 0.09) * s.width)
            ..lineTo(center.dx + cos(a + 0.09) * s.width,
                center.dy + sin(a + 0.09) * s.width)
            ..close(),
          p);
    }
  }

  /// Faint halftone dots in the top corner - the print-shop wink that
  /// says "comic".
  void _halftone(Canvas c, Size s, Random r) {
    final p = Paint()..color = ink.withValues(alpha: 0.05);
    final left = r.nextBool();
    for (var row = 0; row < 5; row++) {
      for (var col = 0; col < 7 - row; col++) {
        final x = left
            ? 8.0 + col * 9 + (row.isOdd ? 4.5 : 0)
            : s.width - 8 - col * 9 - (row.isOdd ? 4.5 : 0);
        c.drawCircle(Offset(x, 8.0 + row * 9), 2.2, p);
      }
    }
  }

  @override
  bool shouldRepaint(_ScenePainter old) =>
      old.seed != seed || old.scene != scene || old.burst != burst;
}
