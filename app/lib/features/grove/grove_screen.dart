// The Grove - home. The living sky, the swaying tree, today's fact and
// action, and the Thumb Promise: in Hopeling, promises are held, not tapped.

import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/clock.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../data/content.dart';
import '../../data/save.dart';
import 'tree.dart';

class GroveScreen extends StatefulWidget {
  const GroveScreen({super.key});

  @override
  State<GroveScreen> createState() => _GroveScreenState();
}

class _GroveScreenState extends State<GroveScreen> {
  Save save = Save();
  DayContent? day;
  bool booted = false;
  final TreePulse pulse = TreePulse();

  @override
  void initState() {
    super.initState();
    _boot();
    contentTick.addListener(_freshDay);
  }

  @override
  void dispose() {
    contentTick.removeListener(_freshDay);
    super.dispose();
  }

  void _freshDay() {
    loadDay().then((c) {
      if (mounted) setState(() => day = c);
    });
  }

  Future<void> _boot() async {
    final s = await Store.load();
    if (mounted) setState(() { save = s; booted = true; });
    _freshDay();
  }

  String get greeting {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'Good morning 🌅';
    if (h >= 12 && h < 17) return 'Good afternoon ☀️';
    if (h >= 17 && h < 21) return 'Good evening 🌇';
    return 'Good night 🌙';
  }

  void _onCommit() {
    // Persist FIRST. The ceremony is decoration; the promise is data.
    setState(() => save.complete());
    Store.persist(save);
    // The ceremony (under 1.5s): the tree breathes, a few drops fall.
    pulse.breathe();
    Haptics.yourDrop();
    if (!Motion.still(context)) RainBurst.show(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🌧 One more drop in the world\'s rain.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = day;
    final sky = skyColors(DateTime.now().hour);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: const Alignment(0, -0.2),
            colors: sky,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 40),
            children: [
              Text(greeting, style: serif(26)),
              const SizedBox(height: 4),
              Text(todayStr(),
                  style: const TextStyle(
                      fontSize: 12, letterSpacing: 2, color: tx2)),
              const SizedBox(height: 26),
              Center(
                child: Column(
                  children: [
                    if (save.xp >= 15)
                      const Text('🐦 🐝 🦋',
                          style: TextStyle(fontSize: 18, letterSpacing: 6)),
                    const SizedBox(height: 6),
                    Semantics(
                      label:
                          'Your tree: ${stageName(stageForXp(save.xp))}, swaying gently',
                      child: TreeView(
                        stage: stageForXp(save.xp),
                        still: Motion.still(context),
                        pulse: pulse,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(stageName(stageForXp(save.xp)),
                        style: serif(17, weight: FontWeight.w500)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [
                          BoxShadow(
                              color: ink.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Text(
                          '🔥 ${save.streak} day streak   ·   ${save.xp} drops',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: ink)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 34),
              Text("TODAY'S FACT", style: kicker()),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [fern, deep]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d == null ? 'Listening to the world...' : d.factText,
                      style: serif(20,
                          color: Colors.white,
                          style: FontStyle.italic,
                          weight: FontWeight.w500,
                          height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      d == null ? '' : '- ${d.factSrc.toUpperCase()}',
                      style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.5,
                          color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text("TODAY'S ACTION", style: kicker()),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: ink.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d == null ? '...' : d.actTitle,
                        style: serif(19, height: 1.35)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsetsDirectional.only(start: 12),
                      decoration: const BoxDecoration(
                        border: BorderDirectional(
                            start: BorderSide(color: mint, width: 3)),
                      ),
                      child: Text(d == null ? '' : d.actWhy,
                          style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 14,
                              height: 1.55,
                              color: tx2)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                        d == null
                            ? ''
                            : '~${d.actMin} minutes${d.fromCache ? '   ·   offline' : ''}',
                        style: const TextStyle(fontSize: 12, color: tx2)),
                    const SizedBox(height: 16),
                    HoldToCommit(
                      done: save.doneOn(todayStr()),
                      onCommit: _onCommit,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Center(
                child: Text('small actions, real hope',
                    style:
                        TextStyle(fontSize: 12, letterSpacing: 3, color: tx2)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- the Thumb Promise ----------
// Press and hold. A gold ring draws itself around the button under your
// finger, with a haptic tick at each quarter. Release early and it undoes
// itself - no promise was made. Reduced motion: a plain, honest button.
class HoldToCommit extends StatefulWidget {
  final bool done;
  final VoidCallback onCommit;
  const HoldToCommit({super.key, required this.done, required this.onCommit});

  @override
  State<HoldToCommit> createState() => _HoldToCommitState();
}

class _HoldToCommitState extends State<HoldToCommit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  final Set<int> _ticked = {};

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: Motion.hold);
    _c.addListener(_onTickCheck);
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        Haptics.commit();
        widget.onCommit();
        _ticked.clear();
        _c.animateBack(0, duration: const Duration(milliseconds: 400));
      }
    });
  }

  void _onTickCheck() {
    for (final q in [1, 2, 3]) {
      if (_c.value >= q / 4 && !_ticked.contains(q)) {
        _ticked.add(q);
        Haptics.tick();
      }
    }
    setState(() {});
  }

  void _cancel() {
    if (_c.status == AnimationStatus.forward) {
      _ticked.clear();
      _c.animateBack(0, duration: const Duration(milliseconds: 250));
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.done ? 'Done today 🌱 hold for one more' : 'Hold to do it';
    if (Motion.reduced(context)) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: widget.done ? mint : fern,
            foregroundColor: widget.done ? ink : paper,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: widget.onCommit,
          child: Text(widget.done ? 'Done today 🌱 (one more)' : 'I did it',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      );
    }
    return Semantics(
      button: true,
      label: label,
      onTap: widget.onCommit,
      child: GestureDetector(
        onTapDown: (_) {
          _ticked.clear();
          _c.forward(from: _c.value);
        },
        onTapUp: (_) => _cancel(),
        onTapCancel: _cancel,
        child: CustomPaint(
          foregroundPainter: _RingPainter(_c.value),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: widget.done ? mint : fern,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: widget.done ? ink : paper),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double t;
  _RingPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1.5, 1.5, size.width - 3, size.height - 3),
      const Radius.circular(16),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final m = metrics.first;
    final drawn = m.extractPath(0, m.length * t.clamp(0.0, 1.0));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = gold;
    canvas.drawPath(drawn, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.t != t;
}

// ---------- it rains when you act ----------
class RainBurst {
  static void show(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _RainLayer(onDone: () => entry.remove()),
    );
    overlay.insert(entry);
  }
}

class _RainLayer extends StatefulWidget {
  final VoidCallback onDone;
  const _RainLayer({required this.onDone});

  @override
  State<_RainLayer> createState() => _RainLayerState();
}

class _RainLayerState extends State<_RainLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  final List<List<double>> drops = List.generate(
      16, (_) => [Random().nextDouble(), 0.5 + Random().nextDouble() * 0.5]);

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: Motion.fall)
      ..forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) => CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _RainPainter(_c.value, drops),
        ),
      ),
    );
  }
}

class _RainPainter extends CustomPainter {
  final double t;
  final List<List<double>> drops;
  _RainPainter(this.t, this.drops);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = fern.withValues(alpha: 0.55)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final d in drops) {
      final progress = (t / d[1]).clamp(0.0, 1.0);
      if (progress >= 1) continue;
      final x = d[0] * size.width;
      final y = progress * size.height;
      canvas.drawLine(Offset(x, y), Offset(x, y + 18), paint);
    }
  }

  @override
  bool shouldRepaint(_RainPainter old) => old.t != t;
}
