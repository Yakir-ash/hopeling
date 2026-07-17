// The tree, hand-drawn by code. Not the final Rive character (NATIVE.md
// slice 13) - but no longer an emoji either. Drawn in Hopeling's own
// palette, staged, swaying, and reactive, behind a small interface the
// Rive tree can later step into without the grove noticing.

import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// Bump to make the tree respond (a soft breath) after a completion.
class TreePulse extends ValueNotifier<int> {
  TreePulse() : super(0);
  void breathe() => value++;
}

class TreeView extends StatefulWidget {
  final int stage; // 0 seed, 1 sprout, 2 seedling, 3 young tree, 4 grove
  final bool still;
  final TreePulse? pulse;
  final double size;
  const TreeView(
      {super.key,
      required this.stage,
      this.still = false,
      this.pulse,
      this.size = 170});

  @override
  State<TreeView> createState() => _TreeViewState();
}

class _TreeViewState extends State<TreeView> with TickerProviderStateMixin {
  late final AnimationController _sway;
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    _sway = AnimationController(vsync: this, duration: Motion.sway);
    if (!widget.still) _sway.repeat(reverse: true);
    _breath = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700),
        lowerBound: 0,
        upperBound: 1);
    widget.pulse?.addListener(_onPulse);
  }

  void _onPulse() {
    if (!mounted || widget.still) return;
    _breath.forward(from: 0);
  }

  @override
  void dispose() {
    widget.pulse?.removeListener(_onPulse);
    _sway.dispose();
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_sway, _breath]),
      builder: (context, child) {
        final swayT = widget.still
            ? 0.0
            : (Curves.easeInOut.transform(_sway.value) * 2 - 1); // -1..1
        final breathT = Curves.easeOut.transform(
            _breath.isAnimating ? 1 - (_breath.value - 0.5).abs() * 2 : 0);
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _TreePainter(
              stage: widget.stage, sway: swayT * 0.035, breath: breathT * 0.04),
        );
      },
    );
  }
}

class _TreePainter extends CustomPainter {
  final int stage;
  final double sway; // radians at the crown
  final double breath; // 0..0.04 scale swell

  _TreePainter({required this.stage, required this.sway, required this.breath});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final baseX = w / 2, baseY = h * 0.88;

    // Ground: a soft warm mound, always.
    final ground = Paint()..color = bark.withValues(alpha: 0.18);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(baseX, baseY + h * 0.02),
            width: w * 0.5,
            height: h * 0.09),
        ground);

    // Sway + breath transform around the base of the trunk.
    canvas.save();
    canvas.translate(baseX, baseY);
    canvas.rotate(sway);
    canvas.scale(1 + breath);
    canvas.translate(-baseX, -baseY);

    final trunk = Paint()
      ..color = bark
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final leafDark = Paint()..color = fernDeep;
    final leafMid = Paint()..color = fern;
    final leafLight = Paint()..color = mint.withValues(alpha: 0.9);

    switch (stage) {
      case 0: // the sleeping seed
        final seed = Paint()..color = bark;
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(baseX, baseY - h * 0.045),
                width: w * 0.13,
                height: h * 0.16),
            seed);
        // the gleam: gold, sacred, tiny
        canvas.drawCircle(Offset(baseX + w * 0.02, baseY - h * 0.09),
            w * 0.018, Paint()..color = gold);
        break;

      case 1: // the sprout
        trunk.strokeWidth = w * 0.03;
        final stem = Path()
          ..moveTo(baseX, baseY)
          ..quadraticBezierTo(
              baseX + w * 0.02, baseY - h * 0.12, baseX, baseY - h * 0.22);
        canvas.drawPath(stem, trunk..color = fern);
        _leaf(canvas, Offset(baseX - w * 0.005, baseY - h * 0.21), w * 0.11,
            -0.7, leafMid);
        _leaf(canvas, Offset(baseX + w * 0.005, baseY - h * 0.24), w * 0.10,
            0.6, leafLight);
        break;

      case 2: // the seedling
        trunk.strokeWidth = w * 0.045;
        _drawTrunk(canvas, trunk, baseX, baseY, h * 0.30, w);
        _canopy(canvas, Offset(baseX, baseY - h * 0.36), w * 0.30, leafDark,
            leafMid, leafLight);
        break;

      case 3: // the young tree
        trunk.strokeWidth = w * 0.06;
        _drawTrunk(canvas, trunk, baseX, baseY, h * 0.40, w);
        // one visible branch: growth you can point at
        final branch = Path()
          ..moveTo(baseX, baseY - h * 0.26)
          ..quadraticBezierTo(baseX + w * 0.10, baseY - h * 0.32,
              baseX + w * 0.16, baseY - h * 0.36);
        canvas.drawPath(branch, trunk..strokeWidth = w * 0.03);
        _canopy(canvas, Offset(baseX, baseY - h * 0.52), w * 0.42, leafDark,
            leafMid, leafLight);
        _canopy(canvas, Offset(baseX + w * 0.18, baseY - h * 0.40), w * 0.18,
            leafDark, leafMid, leafLight);
        break;

      default: // the grove
        trunk.strokeWidth = w * 0.07;
        _drawTrunk(canvas, trunk, baseX, baseY, h * 0.46, w);
        _canopy(canvas, Offset(baseX, baseY - h * 0.58), w * 0.52, leafDark,
            leafMid, leafLight);
        // a companion sapling: the grove begins
        final small = Paint()
          ..color = bark
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = w * 0.03;
        canvas.drawLine(Offset(baseX + w * 0.30, baseY),
            Offset(baseX + w * 0.30, baseY - h * 0.16), small);
        _canopy(canvas, Offset(baseX + w * 0.30, baseY - h * 0.22), w * 0.15,
            leafDark, leafMid, leafLight);
    }

    canvas.restore();
  }

  /// A single leaf: an ellipse leaning out from its stem tip.
  void _leaf(
      Canvas canvas, Offset tip, double len, double angle, Paint paint) {
    canvas.save();
    canvas.translate(tip.dx, tip.dy);
    canvas.rotate(angle);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(0, -len / 2), width: len * 0.55, height: len),
        paint);
    canvas.restore();
  }

  void _drawTrunk(
      Canvas canvas, Paint trunk, double x, double y, double height, double w) {
    final path = Path()
      ..moveTo(x, y)
      ..quadraticBezierTo(x - w * 0.02, y - height * 0.55, x, y - height);
    canvas.drawPath(path, trunk);
  }

  void _canopy(Canvas canvas, Offset center, double r, Paint dark, Paint mid,
      Paint light) {
    canvas.drawCircle(center.translate(-r * 0.35, r * 0.1), r * 0.72, dark);
    canvas.drawCircle(center.translate(r * 0.35, r * 0.12), r * 0.70, dark);
    canvas.drawCircle(center, r * 0.85, mid);
    canvas.drawCircle(center.translate(-r * 0.25, -r * 0.3), r * 0.42, light);
    canvas.drawCircle(center.translate(r * 0.3, -r * 0.18), r * 0.3,
        Paint()..color = fern.withValues(alpha: 0.85));
  }

  @override
  bool shouldRepaint(_TreePainter old) =>
      old.stage != stage || old.sway != sway || old.breath != breath;
}

/// Stage from drops (xp) - thresholds identical to slice 1 and the PWA arc.
int stageForXp(int xp) {
  if (xp < 5) return 0;
  if (xp < 15) return 1;
  if (xp < 40) return 2;
  if (xp < 100) return 3;
  return 4;
}

String stageName(int stage) => const [
      'A sleeping seed',
      'A sprout',
      'A seedling',
      'A young tree',
      'A mighty grove'
    ][min(stage, 4)];
