// Hopeling - small actions, real hope.
// Vertical slice 1: the grove, the living sky, today's fact and action,
// the streak that forgives. Reads the same content.json as the website
// and the PWA, picks the same "today" with the same hash (FLUTTER-CONTRACTS.md).

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------- Dawnlight palette ----------
const ink = Color(0xFF16241C);
const fern = Color(0xFF2E6B4F);
const mint = Color(0xFFB2F1CC);
const gold = Color(0xFFE8B04B);
const paper = Color(0xFFFAF8F2);
const deep = Color(0xFF0B3D4C);
const tx2 = Color(0xFF55645B);

void main() => runApp(const HopelingApp());

class HopelingApp extends StatelessWidget {
  const HopelingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hopeling',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: paper,
        colorScheme: ColorScheme.fromSeed(seedColor: fern),
      ),
      home: const GroveScreen(),
    );
  }
}

// ---------- shared clock (identical to the PWA's core.js) ----------
String todayStr() {
  final n = DateTime.now();
  return '${n.year.toString().padLeft(4, '0')}-'
      '${n.month.toString().padLeft(2, '0')}-'
      '${n.day.toString().padLeft(2, '0')}';
}

int dailyIndex(int len, String salt) {
  final d = todayStr() + salt;
  var h = 0;
  for (var i = 0; i < d.length; i++) {
    h = ((h * 31) + d.codeUnitAt(i)) & 0xFFFFFFFF;
  }
  return h % len;
}

// ---------- content ----------
class DayContent {
  final String factText;
  final String factSrc;
  final String actTitle;
  final String actWhy;
  final int actMin;
  DayContent(this.factText, this.factSrc, this.actTitle, this.actWhy, this.actMin);
}

DayContent fallbackContent() => DayContent(
      'Sharks were swimming in the sea before trees existed.',
      'National Geographic',
      'Refuse one single-use plastic today',
      'Most ocean plastic starts as one convenient moment on land.',
      2,
    );

Future<DayContent> loadContent() async {
  try {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 8);
    final req = await client
        .getUrl(Uri.parse('https://hopeling.app/hopeling-web/content.json'));
    final res = await req.close();
    if (res.statusCode != 200) return fallbackContent();
    final body = await res.transform(utf8.decoder).join();
    final doc = jsonDecode(body) as Map<String, dynamic>;

    final facts = (doc['facts'] as List?) ?? [];
    var factText = '';
    var factSrc = '';
    if (facts.isNotEmpty) {
      final f = facts[dailyIndex(facts.length, 'f')] as List;
      factText = f[0].toString();
      factSrc = f[1].toString();
    }

    final actions = (doc['actions'] as Map<String, dynamic>?) ?? {};
    var actTitle = '';
    var actWhy = '';
    var actMin = 2;
    if (actions.isNotEmpty) {
      final keys = actions.keys.toList();
      final a = actions[keys[dailyIndex(keys.length, 'a')]] as Map<String, dynamic>;
      actTitle = (a['t'] ?? '').toString();
      actWhy = (a['why'] ?? '').toString();
      actMin = (a['min'] is int) ? a['min'] as int : 2;
    }

    if (factText.isEmpty || actTitle.isEmpty) return fallbackContent();
    return DayContent(factText, factSrc, actTitle, actWhy, actMin);
  } catch (_) {
    return fallbackContent();
  }
}

// ---------- the grove ----------
class GroveScreen extends StatefulWidget {
  const GroveScreen({super.key});

  @override
  State<GroveScreen> createState() => _GroveScreenState();
}

class _GroveScreenState extends State<GroveScreen> {
  int xp = 0;
  int streak = 0;
  String last = '';
  DayContent? day;
  SharedPreferences? prefs;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      xp = prefs?.getInt('xp') ?? 0;
      streak = prefs?.getInt('streak') ?? 0;
      last = prefs?.getString('last') ?? '';
    });
    final c = await loadContent();
    if (mounted) setState(() => day = c);
  }

  bool get doneToday => last == todayStr();

  String get stage {
    if (xp < 5) return '🌰';
    if (xp < 15) return '🌱';
    if (xp < 40) return '🌿';
    if (xp < 100) return '🌳';
    return '🌲';
  }

  String get stageName {
    if (xp < 5) return 'A sleeping seed';
    if (xp < 15) return 'A sprout';
    if (xp < 40) return 'A seedling';
    if (xp < 100) return 'A young tree';
    return 'A mighty grove';
  }

  String get greeting {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'Good morning 🌅';
    if (h >= 12 && h < 17) return 'Good afternoon ☀️';
    if (h >= 17 && h < 21) return 'Good evening 🌇';
    return 'Good night 🌙';
  }

  List<Color> get sky {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 9) return [const Color(0xFFFFF3DD), paper];
    if (h >= 9 && h < 17) return [const Color(0xFFE9F6EF), paper];
    if (h >= 17 && h < 20) return [const Color(0xFFFFE9D4), paper];
    return [const Color(0xFFE3E9F3), paper];
  }

  void _complete() {
    final t = todayStr();
    setState(() {
      if (last != t) {
        // The streak that forgives: it rests, it never dies.
        streak += 1;
        last = t;
      }
      xp += 1;
    });
    prefs?.setInt('xp', xp);
    prefs?.setInt('streak', streak);
    prefs?.setString('last', last);
    RainBurst.show(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        content: Text('🌧 One more drop in the world\'s rain.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = day;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: const Alignment(0, -0.2),
            colors: [sky[0], sky[1]],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 40),
            children: [
              Text(greeting,
                  style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: ink)),
              const SizedBox(height: 4),
              Text(todayStr(),
                  style: const TextStyle(
                      fontSize: 12, letterSpacing: 2, color: tx2)),
              const SizedBox(height: 26),

              // The grove
              Center(
                child: Column(
                  children: [
                    if (xp >= 15)
                      const Text('🐦 🐝 🦋',
                          style: TextStyle(fontSize: 18, letterSpacing: 6)),
                    const SizedBox(height: 6),
                    SwayingTree(emoji: stage),
                    const SizedBox(height: 8),
                    Text(stageName,
                        style: const TextStyle(
                            fontFamily: 'serif', fontSize: 17, color: ink)),
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
                      child: Text('🔥 $streak day streak   ·   $xp drops',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: ink)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 34),

              // Today's fact
              const Text("TODAY'S FACT",
                  style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w800,
                      color: fern)),
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
                      style: const TextStyle(
                          fontFamily: 'serif',
                          fontStyle: FontStyle.italic,
                          fontSize: 20,
                          height: 1.5,
                          color: Colors.white),
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

              // Today's action
              const Text("TODAY'S ACTION",
                  style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w800,
                      color: fern)),
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
                        style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color: ink)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.only(left: 12),
                      decoration: const BoxDecoration(
                        border: Border(left: BorderSide(color: mint, width: 3)),
                      ),
                      child: Text(d == null ? '' : d.actWhy,
                          style: const TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 14,
                              height: 1.55,
                              color: tx2)),
                    ),
                    const SizedBox(height: 8),
                    Text(d == null ? '' : '~${d.actMin} minutes',
                        style: const TextStyle(fontSize: 12, color: tx2)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: doneToday ? mint : fern,
                          foregroundColor: doneToday ? ink : paper,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _complete,
                        child: Text(
                          doneToday ? 'Done today 🌱 (do more)' : 'I did it',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Center(
                child: Text('small actions, real hope',
                    style: TextStyle(
                        fontSize: 12, letterSpacing: 3, color: tx2)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- the tree sways ----------
class SwayingTree extends StatefulWidget {
  final String emoji;
  const SwayingTree({super.key, required this.emoji});

  @override
  State<SwayingTree> createState() => _SwayingTreeState();
}

class _SwayingTreeState extends State<SwayingTree>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: Tween<double>(begin: -0.006, end: 0.006)
          .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: Text(widget.emoji, style: const TextStyle(fontSize: 84)),
    );
  }
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
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
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
