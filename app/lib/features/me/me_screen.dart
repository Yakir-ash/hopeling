// Me - the quiet back room of the grove. Your story told with presence,
// not scores: days here, drops given, rings formed, wins for the wild
// that happened while you were part of it. Every door that used to
// crowd the grove header lives here now. No XP, no levels, no badges -
// the native app measures a life in rings and seasons, not points.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/clock.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/api.dart';
import '../../data/content.dart';
import '../../data/guardian.dart';
import '../../data/save.dart';
import '../account/account_screen.dart';
import '../circles/circles_screen.dart';
import '../guardian/guardian_screen.dart';
import '../kids/kids_screen.dart';
import '../missions/missions_screen.dart';
import '../robin/robin_screen.dart';

// ---------- pure story logic (tested) ----------

/// The year graph earns its place: it appears once there are 14+ active
/// days, so a newcomer is never shown a field of empty squares.
bool graphUnlocked(Save s) => s.log.keys.length >= 14;

/// "While you were here" - your quiet moments and the world's wins,
/// woven into one timeline, newest first. PWA parity (social.js).
List<(String, String)> storyEvents(
    Save s, List<NewsItem> wins, List<NewsItem> news) {
  final ev = <(String, String)>[];
  final days = s.log.keys.toList()..sort();
  if (days.isNotEmpty) ev.add((days.first, '🌱 You planted your seed'));
  for (final r in s.rings) {
    ev.add(('${r['end']}', '🔥 A ${r['n']}-day streak became a ring'));
  }
  final g = Guardianship.active(s);
  if (g != null && '${g['date']}'.isNotEmpty) {
    ev.add(('${g['date']}', '🛡️ You took the pledge'));
  }
  final seen = <String>{};
  for (final w in [...wins, ...news]) {
    if (w.d.isEmpty || w.t.isEmpty || seen.contains(w.t)) continue;
    seen.add(w.t);
    ev.add((w.d, '🌍 ${w.t}${w.src.isEmpty ? '' : ' · ${w.src}'}'));
  }
  ev.sort((a, b) => b.$1.compareTo(a.$1));
  return ev;
}

/// The header line over the timeline. Counts what is real, claims nothing.
String storyHead(Save s, int winCount, String today) {
  final days = s.log.keys.toList()..sort();
  if (days.isEmpty) return 'Your story starts with your first action.';
  final here = daysBetween(days.first, today) + 1;
  final acts = s.log.values.fold<int>(0, (a, b) => a + b);
  return 'You have been here $here days. $acts actions by you. '
      '$winCount wins for the wild. Same season. Same pull.';
}

// ---------- the screen ----------

class MeScreen extends StatefulWidget {
  const MeScreen({super.key});

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  Save save = Save();
  AppContent? content;
  String? guardianEmo;

  @override
  void initState() {
    super.initState();
    saveTick.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    saveTick.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    Store.load().then((s) async {
      final p = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        save = s;
        guardianEmo = Guardianship.activeId(s) != null
            ? p.getString('guardianEmo')
            : null;
      });
    });
    loadContent().then((c) {
      if (mounted) setState(() => content = c);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = content;
    final gid = Guardianship.activeId(save);
    final g = gid == null ? null : c?.guardianById(gid);
    return Scaffold(
      backgroundColor: paper,
      appBar: AppBar(
        backgroundColor: paper,
        title: Text('🌿 Me', style: serif(20)),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
            24, 8, 24, 32 + MediaQuery.of(context).padding.bottom),
        children: [
          Text(storyHead(save, (c?.wins.length ?? 0) + (c?.news.length ?? 0),
                  todayStr()),
              style: const TextStyle(fontSize: 13, height: 1.55, color: tx2)),
          const SizedBox(height: 18),
          if (graphUnlocked(save)) ...[
            Text('YOUR YEAR OF ACTION', style: kicker()),
            const SizedBox(height: 10),
            _card(SizedBox(
                height: 84,
                child: CustomPaint(
                    size: const Size(double.infinity, 84),
                    painter: YearGraphPainter(save.log, todayStr())))),
          ] else
            const Text(
                '📈 Your year-of-action graph unlocks after two weeks of activity.',
                style: TextStyle(fontSize: 12, color: tx2)),
          const SizedBox(height: 22),
          Text('YOUR JOURNEY', style: kicker()),
          const SizedBox(height: 10),
          _card(Column(children: [
            if (g != null)
              _row('${guardianEmo ?? '🛡️'} Guardian of the ${g.name}',
                  () => Navigator.of(context).push(risePush(
                      GuardianHome(g: g, content: c!)))),
            _row('🕒 While you were here', _openStory),
            _row(
                '🧭 Your field record',
                () => Navigator.of(context)
                    .push(risePush(const MissionsScreen()))),
          ])),
          const SizedBox(height: 22),
          Text('ROOMS', style: kicker()),
          const SizedBox(height: 10),
          _card(Column(children: [
            _row(
                Api.signedIn
                    ? '☁️ Your grove, everywhere - signed in'
                    : '☁️ Keep your grove safe',
                () => Navigator.of(context)
                    .push(risePush(const AccountScreen()))),
            _row(
                '🐦 The Robin - reminders',
                () =>
                    Navigator.of(context).push(risePush(const RobinScreen()))),
            _row(
                '👥 Circles - together',
                () => Navigator.of(context)
                    .push(risePush(const CirclesScreen()))),
            _row(
                '🧒 Little Helpers - kids mode',
                () => Navigator.of(context)
                    .push(risePush(const KidsParentScreen()))),
          ])),
          const SizedBox(height: 22),
          Text('QUIET THINGS', style: kicker()),
          const SizedBox(height: 10),
          _card(Column(children: [
            _row('💬 Tell us anything', _openFeedback),
            _row('🔄 Freshen the world', () async {
              Haptics.tick();
              await refreshContent();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('🌿 The freshest world we can reach.')));
              }
            }),
          ])),
          const SizedBox(height: 26),
          Center(
            child: Text(
                'Hopeling · content v${c?.version ?? '...'}',
                style: const TextStyle(
                    fontSize: 11, letterSpacing: 2, color: tx2)),
          ),
        ],
      ),
    );
  }

  Widget _card(Widget child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Corners.card),
          boxShadow: [
            BoxShadow(
                color: ink.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: child,
      );

  Widget _row(String label, VoidCallback onTap) => InkWell(
        onTap: () {
          Haptics.tick();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(children: [
            Expanded(
                child: Text(label,
                    style: const TextStyle(fontSize: 14, height: 1.3))),
            const Icon(Icons.chevron_right, size: 18, color: tx2),
          ]),
        ),
      );

  void _openStory() {
    final c = content;
    final ev = storyEvents(save, c?.wins ?? [], c?.news ?? []);
    showModalBottomSheet(
      context: context,
      backgroundColor: paper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.82,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Text('🕒', style: serif(34))),
              const SizedBox(height: 6),
              Center(child: Text('While you were here', style: serif(20))),
              const SizedBox(height: 6),
              Text(
                  storyHead(
                      save,
                      ((c?.wins ?? []).length + (c?.news ?? []).length),
                      todayStr()),
                  style: const TextStyle(
                      fontSize: 12.5, height: 1.5, color: tx2)),
              const SizedBox(height: 14),
              Expanded(
                child: ev.isEmpty
                    ? const Center(
                        child: Text('Your story starts with your first action.',
                            style: TextStyle(fontSize: 13, color: tx2)))
                    : ListView(
                        children: [
                          for (final e in ev.take(80))
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 7),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                      width: 84,
                                      child: Text(e.$1,
                                          style: const TextStyle(
                                              fontSize: 11, color: tx2))),
                                  Expanded(
                                      child: Text(e.$2,
                                          style: const TextStyle(
                                              fontSize: 13, height: 1.4))),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFeedback() {
    final msg = TextEditingController();
    final em = TextEditingController(text: Api.session?.email ?? '');
    showModalBottomSheet(
      context: context,
      backgroundColor: paper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 22, 24, 22 + MediaQuery.of(sheetCtx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('💬 Tell us anything', style: serif(19)),
            const SizedBox(height: 6),
            const Text(
                'Bugs, ideas, feelings - it all lands directly with the maker. Every word gets read.',
                style: TextStyle(fontSize: 13, height: 1.5, color: tx2)),
            const SizedBox(height: 14),
            TextField(
              controller: msg,
              maxLines: 5,
              maxLength: 2000,
              decoration: const InputDecoration(
                  hintText: "What's on your mind?",
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: em,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  labelText: "Email (optional, if you'd like a reply)",
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: fern, foregroundColor: paper),
              onPressed: () async {
                final m = msg.text.trim();
                if (m.length < 3) return;
                final (code, _) = await Api.restSend('POST', '/rest/v1/feedback', {
                  'message': m.substring(0, m.length > 2000 ? 2000 : m.length),
                  'email': em.text.trim().isEmpty ? null : em.text.trim(),
                  'user_id': Api.session?.uid,
                  'meta': 'app',
                });
                if (!sheetCtx.mounted) return;
                Navigator.of(sheetCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(code >= 200 && code < 300
                        ? '💚 Thank you - we read every word'
                        : 'Could not send - try again')));
              },
              child: const Text('Send 💚'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- the year of action, painted ----------
// A 53-week field of days, GitHub-garden style but in grove greens.
// Empty days are soil, not failures: the quietest tint, never red.
class YearGraphPainter extends CustomPainter {
  final Map<String, int> log;
  final String today;
  YearGraphPainter(this.log, this.today);

  @override
  void paint(Canvas canvas, Size size) {
    const weeks = 53;
    final cell = size.width / weeks;
    final side = (cell - 2).clamp(2.0, size.height / 7 - 2);
    final end = DateTime.parse('${today}T00:00:00Z');
    // align so the last column ends today
    final dow = end.weekday % 7; // Sun=0, like JS getDay
    var d = end.subtract(Duration(days: weeks * 7 - 1 - (6 - dow)));
    final paintBox = Paint();
    for (var w = 0; w < weeks; w++) {
      for (var r = 0; r < 7; r++) {
        if (!d.isAfter(end)) {
          final key = d.toIso8601String().substring(0, 10);
          final c = log[key] ?? 0;
          paintBox.color = c == 0
              ? ink.withValues(alpha: 0.05)
              : c == 1
                  ? mint
                  : c == 2
                      ? fern.withValues(alpha: 0.7)
                      : fern;
          canvas.drawRRect(
              RRect.fromRectAndRadius(
                  Rect.fromLTWH(w * cell, r * (size.height / 7), side, side),
                  const Radius.circular(2)),
              paintBox);
        }
        d = d.add(const Duration(days: 1));
      }
    }
  }

  @override
  bool shouldRepaint(YearGraphPainter old) =>
      old.log != log || old.today != today;
}

// ---------- linking out, honestly ----------
Future<void> openNewsLink(String url) async {
  if (url.isEmpty) return;
  final u = Uri.tryParse(url);
  if (u == null || (u.scheme != 'https' && u.scheme != 'http')) return;
  await launchUrl(u, mode: LaunchMode.externalApplication);
}
