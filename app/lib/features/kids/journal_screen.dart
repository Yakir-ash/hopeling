// The Nature Journal's rooms: today's page (a finger-painting canvas
// with a nature palette) and the museum (every page, dated, newest
// first). Drawing is strokes on a RepaintBoundary saved as PNG to the
// device only. Undo eats one stroke at a time - mistakes are part of
// every good drawing, so the eraser never scolds.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/clock.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../data/journal.dart';

const _palette = [
  Color(0xFF2E6B4F), // fern
  Color(0xFF7FC763), // leaf
  Color(0xFF4A8FC0), // sky
  Color(0xFF8FD0EA), // water
  Color(0xFFF2B01E), // sun
  Color(0xFFE0762E), // fox
  Color(0xFF8A6A4C), // bark
  Color(0xFF16241C), // ink
  Color(0xFFE85D75), // flower
  Color(0xFFFFFFFF), // cloud (and gentle eraser)
];

class _Stroke {
  final Color color;
  final double width;
  final List<Offset> points;
  _Stroke(this.color, this.width, this.points);
}

class JournalPage extends StatefulWidget {
  final String kidId;
  final void Function(String) speak;
  const JournalPage(
      {super.key, required this.kidId, required this.speak});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  final strokes = <_Stroke>[];
  Color color = _palette.first;
  double width = 6;
  final canvasKey = GlobalKey();
  bool saving = false;

  @override
  void initState() {
    super.initState();
    widget.speak(journalPrompt());
  }

  Future<void> _save() async {
    if (strokes.isEmpty || saving) return;
    setState(() => saving = true);
    try {
      final boundary = canvasKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final img = await boundary.toImage(pixelRatio: 2);
      final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
      await Journal.save(widget.kidId, bytes!.buffer.asUint8List());
      Haptics.settle();
      widget.speak(JournalCopy.saved.replaceAll('🌟', ''));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(JournalCopy.saved)));
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F8EF),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
            child: Row(children: [
              Expanded(
                  child: Text(journalPrompt(),
                      style: serif(17, height: 1.35))),
              IconButton(
                  tooltip: 'Close the journal',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: tx2, size: 20)),
            ]),
          ),
          Text(todayStr(),
              style: const TextStyle(
                  fontSize: 11, letterSpacing: 2, color: tx2)),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: ink, width: 2.5),
                  borderRadius: BorderRadius.circular(18),
                ),
                clipBehavior: Clip.antiAlias,
                child: RepaintBoundary(
                  key: canvasKey,
                  child: GestureDetector(
                    onPanStart: (d) => setState(() => strokes.add(
                        _Stroke(color, width, [d.localPosition]))),
                    onPanUpdate: (d) => setState(
                        () => strokes.last.points.add(d.localPosition)),
                    // white paper UNDER the strokes - a background as a
                    // CustomPaint child would paint over them instead
                    child: Container(
                      color: Colors.white,
                      child: CustomPaint(
                        painter: _JournalPainter(strokes),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final c in _palette)
                  GestureDetector(
                    onTap: () {
                      Haptics.tick();
                      setState(() => color = c);
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: color == c ? gold : ink.withValues(alpha: 0.25),
                            width: color == c ? 3 : 1.5),
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                for (final (w, label) in [(4.0, '·'), (8.0, '•'), (16.0, '⬤')])
                  GestureDetector(
                    onTap: () => setState(() => width = w),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: width == w ? mint : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: ink.withValues(alpha: 0.2)),
                      ),
                      child: Text(label,
                          style: const TextStyle(fontSize: 14)),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(children: [
              TextButton(
                onPressed: strokes.isEmpty
                    ? null
                    : () => setState(() => strokes.removeLast()),
                child: const Text('↩ Undo', style: TextStyle(fontSize: 13)),
              ),
              TextButton(
                onPressed: strokes.isEmpty
                    ? null
                    : () => setState(() => strokes.clear()),
                child: const Text('Fresh page',
                    style: TextStyle(fontSize: 13, color: tx2)),
              ),
              const Spacer(),
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: fern, foregroundColor: paper),
                onPressed: strokes.isEmpty || saving ? null : _save,
                child: const Text('Into my museum 🌟'),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// One page, whole screen: pinch to look closer, and the little bin
/// asks twice before anything leaves the museum forever.
class _PageViewer extends StatelessWidget {
  final String day;
  final dynamic file;
  const _PageViewer({required this.day, required this.file});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F8EF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        title: Text(day, style: serif(16)),
        actions: [
          IconButton(
            tooltip: 'Remove this page',
            icon: const Icon(Icons.delete_outline, size: 22),
            onPressed: () async {
              final sure = await showDialog<bool>(
                context: context,
                builder: (dctx) => AlertDialog(
                  backgroundColor: paper,
                  title: Text('Remove this page?', style: serif(17)),
                  content: const Text(
                      'It leaves the museum forever - there is no bin '
                      'to bring it back from.',
                      style: TextStyle(fontSize: 13.5, height: 1.5)),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(dctx, false),
                        child: const Text('Keep it')),
                    FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFB4552D),
                            foregroundColor: paper),
                        onPressed: () => Navigator.pop(dctx, true),
                        child: const Text('Remove')),
                  ],
                ),
              );
              if (sure == true) {
                try {
                  await file.delete();
                } catch (_) {}
                if (context.mounted) Navigator.of(context).pop(true);
              }
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          maxScale: 5,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: ink, width: 2.5),
                borderRadius: BorderRadius.circular(16),
                color: Colors.white,
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.file(file, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}

class _JournalPainter extends CustomPainter {
  final List<_Stroke> strokes;
  _JournalPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      final paint = Paint()
        ..color = s.color
        ..strokeWidth = s.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      if (s.points.length == 1) {
        canvas.drawCircle(s.points.first, s.width / 2,
            Paint()..color = s.color);
      } else {
        final path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
        for (final p in s.points.skip(1)) {
          path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_JournalPainter old) => true;
}

/// The museum: every page, dated, newest first. The child visits
/// anytime from their journal; parents come through the gate.
class MuseumScreen extends StatefulWidget {
  final String kidId;
  final String kidName;
  const MuseumScreen(
      {super.key, required this.kidId, required this.kidName});

  @override
  State<MuseumScreen> createState() => _MuseumScreenState();
}

class _MuseumScreenState extends State<MuseumScreen> {
  List<(String, dynamic)> pages = [];
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    Journal.entries(widget.kidId).then((e) {
      if (mounted) {
        setState(() {
          pages = e;
          loaded = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F8EF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        title: Text('🖼 ${widget.kidName}\'s museum', style: serif(18)),
      ),
      body: !loaded
          ? const SizedBox.shrink()
          : pages.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text(JournalCopy.emptyMuseum,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 13.5, height: 1.6, color: tx2)),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.85),
                  itemCount: pages.length,
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () async {
                      final deleted = await Navigator.of(context)
                          .push<bool>(MaterialPageRoute(
                              builder: (_) => _PageViewer(
                                  day: pages[i].$1,
                                  file: pages[i].$2)));
                      if (deleted == true && mounted) {
                        setState(() => pages.removeAt(i));
                      }
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: ink, width: 2),
                              borderRadius: BorderRadius.circular(14),
                              color: Colors.white,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.file(pages[i].$2,
                                fit: BoxFit.cover,
                                width: double.infinity),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(pages[i].$1,
                              style: const TextStyle(
                                  fontSize: 11, color: tx2)),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
