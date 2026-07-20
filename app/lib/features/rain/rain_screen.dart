// The Rain - the shared living world. Constitutionally truthful: drops
// fall ONLY for verified activity (the counter moving while you watch),
// your own contribution, or your pending leaf. A quiet day looks quiet,
// and that is the point.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/pulse.dart';
import '../../data/save.dart';
import '../../data/api.dart';
import '../../core/clock.dart';

class RainScreen extends StatefulWidget {
  const RainScreen({super.key});

  @override
  State<RainScreen> createState() => _RainScreenState();
}

class _RainScreenState extends State<RainScreen>
    with SingleTickerProviderStateMixin {
  PulseSnap? snap;
  int shown = -1; // odometer value on screen
  int watchedGain = 0; // verified new actions seen this session
  List<PendingDrop> pending = [];
  Save save = Save();
  Timer? poll;
  late final AnimationController _rainCtl;
  final List<_Drop> drops = [];

  @override
  void initState() {
    super.initState();
    _rainCtl = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..addListener(_cullDrops)
      ..repeat();
    pulseTick.addListener(_reload);
    _reload();
    _refresh();
    // While this window is open, look for real movement every 45 seconds.
    // When the screen closes, the timer dies: no sockets, no background hum.
    poll = Timer.periodic(const Duration(seconds: 45), (_) => _refresh());
  }

  @override
  void dispose() {
    poll?.cancel();
    _rainCtl.dispose();
    pulseTick.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    Pulse.queue().then((q) {
      if (mounted) setState(() => pending = q);
    });
    Store.load().then((s) {
      if (mounted) setState(() => save = s);
    });
    Pulse.snapshot().then((s) {
      if (mounted && s != null && shown < 0) {
        setState(() {
          snap = s;
          shown = s.n;
        });
      }
    });
  }

  Future<void> _refresh() async {
    await Pulse.flush();
    final s = await Pulse.snapshot(refresh: true);
    if (!mounted || s == null) return;
    final delta = shown >= 0 ? s.n - shown : 0;
    setState(() {
      snap = s;
      if (shown < 0) shown = s.n;
    });
    if (delta > 0) {
      setState(() => watchedGain += delta);
      _rainFor(delta);
      _tickTo(s.n);
    } else {
      setState(() => shown = s.n);
    }
  }

  /// Verified movement becomes visible rain: one drop per action, capped
  /// at 24 on screen; beyond that, honesty aggregates into the copy.
  void _rainFor(int delta) {
    if (Motion.still(context)) return;
    final r = Random();
    final add = min(delta, 24 - drops.length).clamp(0, 24);
    for (var i = 0; i < add; i++) {
      drops.add(_Drop(r.nextDouble(),
          DateTime.now().millisecondsSinceEpoch + i * 350, 2600));
    }
  }

  void _cullDrops() {
    final now = DateTime.now().millisecondsSinceEpoch;
    drops.removeWhere((d) => now > d.bornMs + d.lifeMs);
    if (mounted) setState(() {});
  }

  void _tickTo(int target) {
    // World rain has no haptic voice: present, never interrupting.
    Timer.periodic(const Duration(milliseconds: 120), (t) {
      if (!mounted || shown >= target) {
        t.cancel();
        return;
      }
      setState(() => shown = min(shown + 1, target));
    });
  }

  @override
  Widget build(BuildContext context) {
    final sky = skyColors(DateTime.now().hour);
    final myDays = save.log.keys.toList()..sort((a, b) => b.compareTo(a));
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [sky[0], sky[1]]),
        ),
        child: Stack(
          children: [
            if (!Motion.still(context))
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: _RainPainter(drops)),
                ),
              ),
            SafeArea(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                    24, 18, 24, 32 + MediaQuery.of(context).padding.bottom),
                children: [
                  Row(children: [
                    Expanded(child: Text('The Rain', style: serif(28))),
                    if (Navigator.of(context).canPop())
                      IconButton(
                          tooltip: 'Back',
                          onPressed: () => Navigator.of(context).pop(),
                          icon:
                              const Icon(Icons.close, color: tx2, size: 20)),
                  ]),
                  const SizedBox(height: 4),
                  const Text(
                      'every drop below is a real action by a real person',
                      style: TextStyle(fontSize: 13, color: tx2)),
                  const SizedBox(height: 30),
                  Center(
                    child: Semantics(
                      label: snap == null
                          ? RainCopy.unavailable
                          : '${snap!.n} verified actions counted together, ${snap!.freshness()}',
                      child: Column(
                        children: [
                          Text(
                            shown >= 0 ? _fmt(shown) : '···',
                            style: serif(52, color: fern, height: 1.1),
                          ),
                          const SizedBox(height: 4),
                          const Text('actions counted together, ever',
                              style:
                                  TextStyle(fontSize: 13, color: tx2)),
                          const SizedBox(height: 6),
                          _FreshnessLeaf(snap: snap),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (watchedGain > 0)
                    Center(
                      child: Text(RainCopy.watched(watchedGain),
                          textAlign: TextAlign.center,
                          style: serif(15,
                              style: FontStyle.italic,
                              weight: FontWeight.w500,
                              color: ink)),
                    )
                  else
                    const Center(
                      child: Text(RainCopy.quiet,
                          style: TextStyle(fontSize: 13, color: tx2)),
                    ),
                  const SizedBox(height: 30),
                  // your standing in the rain
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('YOUR DROPS', style: kicker()),
                        const SizedBox(height: 8),
                        Text('${save.xp} of the world\'s drops are yours.',
                            style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: ink)),
                        if (pending.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Text('🍃',
                                  style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                    Api.signedIn
                                        ? '${pending.length} ${pending.length == 1 ? 'drop rests' : 'drops rest'} on a leaf, joining when the cloud is in reach.'
                                        : RainCopy.guest,
                                    style: const TextStyle(
                                        fontSize: 12.5,
                                        height: 1.5,
                                        color: tx2)),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (myDays.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DAYS YOU WERE PRESENT', style: kicker()),
                          const SizedBox(height: 4),
                          const Text('presence, never absence',
                              style:
                                  TextStyle(fontSize: 11.5, color: tx2)),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final d in myDays.take(21))
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: mint.withValues(alpha: 0.4),
                                    borderRadius:
                                        BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                      '${d.substring(5)} · ${save.log[d]}💧',
                                      style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: ink)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int n) => n.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');
}

class _FreshnessLeaf extends StatelessWidget {
  final PulseSnap? snap;
  const _FreshnessLeaf({required this.snap});

  @override
  Widget build(BuildContext context) {
    final label = snap == null ? 'out of reach' : snap!.freshness();
    final live = label == 'live';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: live
            ? mint.withValues(alpha: 0.45)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(live ? '● live' : label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: live ? fernDeep : tx2)),
    );
  }
}

class _Drop {
  final double x; // 0..1
  final int bornMs;
  final int lifeMs;
  _Drop(this.x, this.bornMs, this.lifeMs);
}

class _RainPainter extends CustomPainter {
  final List<_Drop> drops;
  _RainPainter(this.drops);

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final paint = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final d in drops) {
      final t = ((now - d.bornMs) / d.lifeMs).clamp(0.0, 1.0);
      if (t <= 0 || t >= 1) continue;
      final x = d.x * size.width;
      final y = t * size.height * 0.85;
      paint.color = fern.withValues(alpha: 0.5 * (1 - t * 0.5));
      canvas.drawLine(Offset(x, y), Offset(x, y + 16), paint);
      if (t > 0.92) {
        canvas.drawCircle(Offset(x, size.height * 0.85 + 16), 6 * (t - 0.92) * 12,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = fern.withValues(alpha: 0.3 * (1 - t)));
      }
    }
  }

  @override
  bool shouldRepaint(_RainPainter old) => true;
}
