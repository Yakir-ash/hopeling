// The Tree - Hopeling's face (slice 13, EXPERIENCE.md's one big bet).
// A real branching organism drawn by code: structure is DETERMINISTIC
// per stage (seeded, golden-test ready); only the wind, the seasons and
// the light are alive. Eight stages from the oracle's grove table, wind
// that strengthens toward evening, foliage that follows the real
// calendar, growth that happens ON SCREEN with a haptic crescendo,
// leaves that dip under a fingertip, friends perched on true branch
// tips, and the guardian keeping company at the roots. Reduced motion:
// a still, beautiful tree. The Rive character can one day step in
// behind this exact interface.

import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/theme.dart';

// ---------- seasons, from the real calendar ----------
String seasonOf(int month) {
  if (month >= 3 && month <= 5) return 'spring';
  if (month >= 6 && month <= 8) return 'summer';
  if (month >= 9 && month <= 11) return 'autumn';
  return 'winter';
}

List<Color> seasonPalette(String season) => switch (season) {
      'spring' => const [
          Color(0xFF2E6B4F), Color(0xFF4E8F6C), Color(0xFF7FC29B),
          Color(0xFFB2F1CC)
        ],
      'autumn' => const [
          Color(0xFFB07A2E), Color(0xFFD79A4B), Color(0xFF8F5A2B),
          Color(0xFF2E6B4F)
        ],
      'winter' => const [
          Color(0xFF7FA08C), Color(0xFFA9BDAE), Color(0xFF1E4533)
        ],
      _ => const [
          Color(0xFF1E4533), Color(0xFF2E6B4F), Color(0xFF4E8F6C),
          Color(0xFFB2F1CC)
        ],
    };

/// Winter trees hold fewer leaves; spring scatters blossoms.
double seasonLeafKeep(String season) => season == 'winter' ? 0.55 : 1.0;
bool seasonBlossoms(String season) => season == 'spring';

/// Wind strengthens toward evening, rests deep at night.
double windStrength(int hour) {
  if (hour >= 17 && hour < 21) return 1.0;
  if (hour >= 21 || hour < 6) return 0.35;
  return 0.6;
}

// ---------- the deterministic organism ----------
class BranchNode {
  final Offset a; // start (unit space, base at ~(0.5, 0.94))
  final Offset c; // control
  final Offset b; // end
  final double w; // width factor at start
  final int depth; // 0 = trunk
  BranchNode(this.a, this.c, this.b, this.w, this.depth);
}

class LeafCluster {
  final Offset at;
  final double r; // unit radius
  final int seed;
  LeafCluster(this.at, this.r, this.seed);
}

class TreeSpec {
  final int stage; // 0..7 (the oracle's grove stages)
  final List<BranchNode> branches;
  final List<LeafCluster> clusters;
  final List<Offset> perches; // where friends may sit
  TreeSpec._(this.stage, this.branches, this.clusters, this.perches);

  /// Same stage, same tree, forever. Only the weather is alive.
  factory TreeSpec.grow(int stage) {
    final rnd = Random(7919 * (stage + 3));
    final branches = <BranchNode>[];
    final clusters = <LeafCluster>[];
    const base = Offset(0.5, 0.94);

    // per-stage silhouette: trunk height, recursion depth, spread
    final params = const [
      // trunkLen, depth, spread(rad), childCount
      [0.0, 0, 0.0, 0], // 0 sleeping seed
      [0.16, 0, 0.0, 0], // 1 sprout
      [0.22, 1, 0.5, 2], // 2 seedling
      [0.30, 2, 0.55, 2], // 3 young tree
      [0.36, 3, 0.6, 2], // 4 strong tree
      [0.40, 3, 0.7, 3], // 5 flourishing
      [0.44, 3, 0.78, 3], // 6 mighty grove
      [0.46, 3, 0.86, 4], // 7 ancient grove
    ][stage];
    final trunkLen = params[0] as double;
    final maxDepth = params[1] as int;
    final spread = params[2] as double;
    final kids = params[3] as int;

    void branch(Offset from, double angle, double len, int depth) {
      final end = from + Offset(sin(angle), -cos(angle)) * len;
      final mid = Offset.lerp(from, end, 0.5)!;
      final perp = Offset(cos(angle), sin(angle)) *
          (rnd.nextDouble() - 0.5) *
          len *
          0.5;
      final node = BranchNode(
          from, mid + perp, end, pow(0.62, depth).toDouble(), depth);
      branches.add(node);
      if (depth >= maxDepth) {
        clusters.add(LeafCluster(
            end, 0.05 + 0.02 * (maxDepth - depth + 1), rnd.nextInt(1 << 20)));
        return;
      }
      // Bounded fullness: rich near the trunk, restrained at the tips,
      // so an ancient grove stays smooth on an inexpensive phone.
      final n = depth == 0
          ? kids + (rnd.nextDouble() < 0.4 ? 1 : 0)
          : depth == 1
              ? min(kids, 3)
              : 2;
      for (var i = 0; i < n; i++) {
        final t = n == 1 ? 0.0 : (i / (n - 1)) * 2 - 1; // -1..1
        final childAngle = angle +
            t * spread +
            (rnd.nextDouble() - 0.5) * 0.25;
        branch(end, childAngle, len * (0.68 + rnd.nextDouble() * 0.1),
            depth + 1);
      }
      // occasional mid-branch tuft for fullness
      if (depth >= 1 && rnd.nextDouble() < 0.35) {
        clusters.add(LeafCluster(
            Offset.lerp(from, end, 0.6)!, 0.035, rnd.nextInt(1 << 20)));
      }
    }

    if (stage == 1) {
      // the sprout: one stem, two hand-placed leaves
      final tip = base + const Offset(0.008, -0.16);
      branches.add(BranchNode(
          base, base + const Offset(0.02, -0.08), tip, 0.5, 0));
      clusters.add(LeafCluster(tip + const Offset(-0.02, -0.005), 0.035, 11));
      clusters.add(LeafCluster(tip + const Offset(0.022, -0.02), 0.03, 12));
    } else if (stage >= 2) {
      branch(base, (rnd.nextDouble() - 0.5) * 0.06, trunkLen, 0);
      if (stage >= 6) {
        // a companion sapling: the grove begins
        branch(base + const Offset(0.18, 0.0), 0.15, trunkLen * 0.35, maxDepth);
      }
    }

    // Normalize: no stage may escape its canvas. Measure the extents and,
    // if needed, scale the whole organism toward its base - so the ancient
    // grove is majestic AND fully visible on every phone.
    if (branches.isNotEmpty) {
      var minX = 1.0, maxX = 0.0, minY = 1.0;
      void see(Offset p) {
        minX = min(minX, p.dx);
        maxX = max(maxX, p.dx);
        minY = min(minY, p.dy);
      }

      for (final b in branches) {
        see(b.a);
        see(b.c);
        see(b.b);
      }
      for (final cl in clusters) {
        see(cl.at.translate(-cl.r, -cl.r));
        see(cl.at.translate(cl.r, 0));
      }
      final heightScale =
          minY < 0.05 ? (base.dy - 0.05) / (base.dy - minY) : 1.0;
      final halfWidth = max(maxX - base.dx, base.dx - minX);
      final widthScale = halfWidth > 0.46 ? 0.46 / halfWidth : 1.0;
      final s = min(1.0, min(heightScale, widthScale));
      if (s < 1.0) {
        Offset fit(Offset p) => base + (p - base) * s;
        final nb = [
          for (final b in branches)
            BranchNode(fit(b.a), fit(b.c), fit(b.b), b.w, b.depth)
        ];
        branches
          ..clear()
          ..addAll(nb);
        final nc = [
          for (final cl in clusters)
            LeafCluster(fit(cl.at), cl.r * s, cl.seed)
        ];
        clusters
          ..clear()
          ..addAll(nc);
      }
    }

    // perches: the highest, most separated cluster points
    final sorted = [...clusters]..sort((x, y) => x.at.dy.compareTo(y.at.dy));
    final perches = <Offset>[];
    for (final cl in sorted) {
      if (perches.every((p) => (p - cl.at).distance > 0.12)) {
        perches.add(cl.at);
      }
      if (perches.length >= 6) break;
    }
    return TreeSpec._(stage, branches, clusters, perches);
  }
}

// ---------- the living view ----------
class TreePulse extends ValueNotifier<int> {
  TreePulse() : super(0);
  void breathe() => value++;
}

class TreeView extends StatefulWidget {
  final int stage; // 0..7
  final bool still;
  final TreePulse? pulse;
  final double size;
  final List<String> friends;
  final String? guardianEmo;
  const TreeView(
      {super.key,
      required this.stage,
      this.still = false,
      this.pulse,
      this.size = 170,
      this.friends = const [],
      this.guardianEmo});

  @override
  State<TreeView> createState() => _TreeViewState();
}

class _TreeViewState extends State<TreeView> with TickerProviderStateMixin {
  late TreeSpec spec;
  late final AnimationController _wind; // endless time source
  late final AnimationController _breath; // completion response
  late final AnimationController _growth; // stage-up ceremony
  int _dipCluster = -1;
  late final AnimationController _dip;
  final Set<int> _growthTicks = {};

  @override
  void initState() {
    super.initState();
    spec = TreeSpec.grow(widget.stage);
    _wind = AnimationController(
        vsync: this, duration: const Duration(seconds: 6));
    if (!widget.still) _wind.repeat();
    _breath = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _growth = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2600), value: 1);
    _dip = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _growth.addListener(_growthCrescendo);
    widget.pulse?.addListener(_onPulse);
  }

  void _onPulse() {
    if (mounted && !widget.still) _breath.forward(from: 0);
  }

  /// Growth is felt, not just seen: ticks as branches extend, a settle
  /// as leaves unfold, and one bloom when the new crown completes.
  void _growthCrescendo() {
    for (final m in [1, 2, 3]) {
      if (_growth.value >= m / 4 && !_growthTicks.contains(m)) {
        _growthTicks.add(m);
        m < 3 ? Haptics.tick() : Haptics.settle();
      }
    }
    if (_growth.isCompleted && !_growthTicks.contains(4)) {
      _growthTicks.add(4);
      Haptics.bloom();
    }
  }

  @override
  void didUpdateWidget(TreeView old) {
    super.didUpdateWidget(old);
    if (widget.stage != old.stage) {
      spec = TreeSpec.grow(widget.stage);
      if (widget.stage > old.stage && !widget.still) {
        _growthTicks.clear();
        _growth.forward(from: 0); // the tree grows before your eyes
      } else {
        _growth.value = 1;
      }
    }
    if (widget.still && _wind.isAnimating) _wind.stop();
    if (!widget.still && !_wind.isAnimating) _wind.repeat();
  }

  @override
  void dispose() {
    widget.pulse?.removeListener(_onPulse);
    _wind.dispose();
    _breath.dispose();
    _growth.dispose();
    _dip.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails d) {
    if (widget.still) return;
    final local = d.localPosition;
    final u = Offset(local.dx / widget.size, local.dy / widget.size);
    var best = -1;
    var bestDist = 0.14;
    for (var i = 0; i < spec.clusters.length; i++) {
      final dist = (spec.clusters[i].at - u).distance;
      if (dist < bestDist) {
        bestDist = dist;
        best = i;
      }
    }
    if (best >= 0) {
      Haptics.tick();
      setState(() => _dipCluster = best);
      _dip.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final season = seasonOf(now.month);
    final wind = widget.still ? 0.0 : windStrength(now.hour);
    return GestureDetector(
      onTapDown: _onTapDown,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: Listenable.merge([_wind, _breath, _growth, _dip]),
          builder: (context, _) {
            final t = _wind.value * 2 * pi;
            final breath = _breath.isAnimating
                ? sin(_breath.value * pi) * 0.035
                : 0.0;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _TreePainter(
                    spec: spec,
                    time: t,
                    wind: wind,
                    breath: breath,
                    growth: Curves.easeOutCubic.transform(_growth.value),
                    season: season,
                    dipCluster: _dipCluster,
                    dip: _dip.isAnimating
                        ? sin(_dip.value * pi) * (1 - _dip.value * 0.4)
                        : 0.0,
                  ),
                ),
                // friends perch on true branch tips, sway with the crown
                for (var i = 0;
                    i < widget.friends.length && i < spec.perches.length;
                    i++)
                  Positioned(
                    left: spec.perches[i].dx * widget.size - 9 +
                        sin(t + i * 1.7) * 2.2 * wind,
                    top: spec.perches[i].dy * widget.size - 18,
                    child: Text(widget.friends[i],
                        style: const TextStyle(fontSize: 14)),
                  ),
                if (widget.guardianEmo != null)
                  Positioned(
                    left: widget.size * 0.68,
                    top: widget.size * 0.86,
                    child: Text(widget.guardianEmo!,
                        style: const TextStyle(fontSize: 14)),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TreePainter extends CustomPainter {
  final TreeSpec spec;
  final double time; // radians
  final double wind; // 0..1
  final double breath; // extra scale
  final double growth; // 0..1
  final String season;
  final int dipCluster;
  final double dip;

  _TreePainter(
      {required this.spec,
      required this.time,
      required this.wind,
      required this.breath,
      required this.growth,
      required this.season,
      required this.dipCluster,
      required this.dip});

  Offset _u(Offset u, Size s) => Offset(u.dx * s.width, u.dy * s.height);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final base = Offset(0.5 * w, 0.94 * h);

    // ground: mound and a hint of roots
    final ground = Paint()..color = bark.withValues(alpha: 0.16);
    canvas.drawOval(
        Rect.fromCenter(center: base.translate(0, h * 0.015),
            width: w * 0.52, height: h * 0.075),
        ground);
    final rootPaint = Paint()
      ..color = bark.withValues(alpha: 0.35)
      ..strokeWidth = w * 0.012
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(base, base.translate(-w * 0.07, h * 0.02), rootPaint);
    canvas.drawLine(base, base.translate(w * 0.06, h * 0.025), rootPaint);

    // whole-tree sway and completion breath, hinged at the roots
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(sin(time) * 0.02 * wind);
    canvas.scale(1 + breath);
    canvas.translate(-base.dx, -base.dy);

    if (spec.stage == 0) {
      // the sleeping seed and its sacred gleam
      canvas.drawOval(
          Rect.fromCenter(center: _u(const Offset(0.5, 0.90), size),
              width: w * 0.12, height: h * 0.15),
          Paint()..color = bark);
      canvas.drawCircle(
          _u(const Offset(0.52, 0.855), size), w * 0.017,
          Paint()..color = gold);
      canvas.restore();
      return;
    }

    // branches: drawn oldest-first, each depth arriving as growth allows
    final trunkPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..color = bark;
    final maxDepth =
        spec.branches.fold<int>(0, (m, b) => max(m, b.depth));
    for (final b in spec.branches) {
      final depthStart = maxDepth == 0 ? 0.0 : b.depth / (maxDepth + 1);
      final local =
          ((growth - depthStart) / (1 - depthStart)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final sway = sin(time + b.depth * 0.9) * 0.006 * wind * b.depth;
      final a = _u(b.a, size);
      final c = _u(b.c, size).translate(sway * w, 0);
      final end = _u(b.b, size).translate(sway * w * 1.6, 0);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(c.dx, c.dy, end.dx, end.dy);
      trunkPaint.strokeWidth = max(1.2, w * 0.055 * b.w);
      if (local >= 1) {
        canvas.drawPath(path, trunkPaint);
      } else {
        for (final m in path.computeMetrics()) {
          canvas.drawPath(m.extractPath(0, m.length * local), trunkPaint);
        }
      }
    }

    // foliage: fanned leaves per cluster, seasonal, unfolding with growth
    final palette = seasonPalette(season);
    final keep = seasonLeafKeep(season);
    final leavesAt = growth >= 0.55
        ? ((growth - 0.55) / 0.45).clamp(0.0, 1.0)
        : 0.0;
    if (leavesAt > 0) {
      for (var ci = 0; ci < spec.clusters.length; ci++) {
        final cl = spec.clusters[ci];
        final rnd = Random(cl.seed);
        final extraDip = ci == dipCluster ? dip * h * 0.02 : 0.0;
        final center = _u(cl.at, size)
            .translate(sin(time + ci) * 1.5 * wind, extraDip);
        final r = cl.r * w * leavesAt;
        final leaves = 5 + rnd.nextInt(4);
        for (var i = 0; i < leaves; i++) {
          if (rnd.nextDouble() > keep) continue;
          final ang = (i / leaves) * 2 * pi + rnd.nextDouble() * 0.8;
          final flutter =
              sin(time * 2 + i * 2.1 + ci) * 0.10 * wind;
          final at = center +
              Offset(cos(ang), sin(ang)) * r * (0.4 + rnd.nextDouble() * 0.6);
          canvas.save();
          canvas.translate(at.dx, at.dy);
          canvas.rotate(ang + flutter);
          canvas.drawOval(
              Rect.fromCenter(
                  center: Offset.zero, width: r * 0.85, height: r * 1.5),
              Paint()
                ..color =
                    palette[rnd.nextInt(palette.length)].withValues(
                        alpha: 0.85 + rnd.nextDouble() * 0.15));
          canvas.restore();
        }
        if (seasonBlossoms(season) && rnd.nextDouble() < 0.5) {
          canvas.drawCircle(
              center.translate(r * 0.4, -r * 0.3), max(1.5, r * 0.14),
              Paint()..color = const Color(0xFFF6D5E0));
        }
      }
    }

    // autumn: one quiet leaf falls, again and again, never the same one
    if (season == 'autumn' && wind > 0 && spec.clusters.isNotEmpty) {
      final ft = (time / (2 * pi)) % 1.0;
      final from = _u(spec.clusters.first.at, size);
      final fx = from.dx + sin(ft * 5) * w * 0.06;
      final fy = from.dy + ft * (h * 0.88 - from.dy);
      canvas.save();
      canvas.translate(fx, fy);
      canvas.rotate(ft * 5);
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset.zero, width: w * 0.016, height: w * 0.03),
          Paint()
            ..color = const Color(0xFFD79A4B)
                .withValues(alpha: (1 - ft) * 0.9));
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_TreePainter old) => true;
}
