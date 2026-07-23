// Kids Mode - the parent area, the gate, and the child's world.
// The child's home is big, warm, and few: an adventure, a friend,
// one small thing to do. Exit and settings live behind the gate.

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/clock.dart';
import '../../core/kid_theme.dart';
import '../../core/narration.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/actions.dart' as engine;
import '../../data/api.dart';
import '../../data/content.dart';
import '../../data/kids.dart';
import '../../data/pulse.dart';
import '../../data/save.dart';
import '../../data/wiki.dart';
import '../../data/bedtime.dart';
import '../../data/explorer.dart';
import '../../data/journal.dart';
import '../grove/grove_screen.dart' show HoldToCommit, RainBurst;
import 'explorer_screen.dart';
import 'journal_screen.dart';
import '../me/me_screen.dart' show openNewsLink;
import 'bedtime_screen.dart';
import 'cinema_screen.dart';
import 'comic.dart';

// ---------- the parent gate ----------
Future<bool> parentGate(BuildContext context) async {
  // While testing, debug builds walk straight through the gate.
  // Release builds always keep it - no flag to forget before launch.
  if (kDebugMode) return true;
  final gate = ParentGate.roll();
  final c = TextEditingController();
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: paper,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            28, 26, 28, 24 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('For grown-ups', style: serif(19)),
            const SizedBox(height: 8),
            Text(gate.question,
                style: const TextStyle(fontSize: 15, color: ink)),
            const SizedBox(height: 12),
            TextField(
              controller: c,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: fern, foregroundColor: paper),
              onPressed: () =>
                  Navigator.of(ctx).pop(gate.check(c.text)),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    ),
  );
  return ok == true;
}

// ---------- the parent area ----------
class KidsParentScreen extends StatefulWidget {
  const KidsParentScreen({super.key});

  @override
  State<KidsParentScreen> createState() => _KidsParentScreenState();
}

class _KidsParentScreenState extends State<KidsParentScreen> {
  Save save = Save();
  final nameC = TextEditingController();
  String band = 'ranger';
  String intensity = 'gentle';
  bool narration = true;
  BedtimePrefs bt = BedtimePrefs();
  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final s = await Store.load();
    final b = await BedtimePrefs.load();
    if (mounted) {
      setState(() {
        save = s;
        bt = b;
      });
    }
  }

  Future<void> _persist() async {
    await Store.persist(save);
    saveTick.value++;
    if (Api.signedIn) Api.pushSave(save.toJson());
    _reload();
  }

  Future<void> _create() async {
    if (nameC.text.trim().isEmpty) return;
    final p = KidProfile(
        id: Kids.newId(),
        name: nameC.text.trim(),
        band: band,
        narration: narration,
        intensity: intensity);
    Kids.put(save, p);
    await _persist();
    nameC.clear();
    Haptics.settle();
  }

  Future<void> _enter(KidProfile p) async {
    await startKidSession(p.id);
    if (!mounted) return;
    Navigator.of(context)
        .push(risePush(KidsHome(profileId: p.id)))
        .then((_) => _reload());
  }

  /// Bedtime now: the manual override. Holds for one hour, then the
  /// schedule takes over again. Clears any "not tonight".
  Future<void> _enterBedtime(KidProfile p) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('btManualUntil',
        DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch);
    await prefs.remove('btSkipUntil');
    await _enter(p);
  }

  /// Not tonight: bedtime stands down for twelve hours, whatever the
  /// schedule or a stray override says.
  Future<void> _skipBedtime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('btSkipUntil',
        DateTime.now().add(const Duration(hours: 12)).millisecondsSinceEpoch);
    await prefs.remove('btManualUntil');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('☀️ Bedtime is off for the next twelve hours.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final kids = Kids.list(save);
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: ink,
          title: Text('Little Helpers', style: serif(19))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 40),
          children: [
            const Text(
              'A safe, gentle Hopeling for children: simple words, '
              'narration, no strangers, no pressure, nothing to buy. '
              'You hold the gate; they hold the wonder.',
              style: TextStyle(fontSize: 13.5, height: 1.6, color: tx2),
            ),
            const SizedBox(height: 16),
            // bedtime: the forest prepares for sleep on your schedule
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: const Color(0xFF23304F),
                  borderRadius: BorderRadius.circular(Corners.card)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🌙 Bedtime', style: serif(16, color: Colors.white)),
                  const SizedBox(height: 4),
                  const Text(
                      'After this hour their world becomes a moonlit forest: '
                      'one story, softer voice, slower everything. '
                      'No location is used - you set the hour.',
                      style: TextStyle(
                          fontSize: 12.5,
                          height: 1.5,
                          color: Color(0xFF8B93B4))),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final t in const [
                      (1110, '18:30'),
                      (1140, '19:00'),
                      (1170, '19:30'),
                      (1200, '20:00'),
                      (1230, '20:30'),
                    ])
                      ChoiceChip(
                        label: Text(t.$2,
                            style: const TextStyle(fontSize: 12)),
                        selected: bt.startMin == t.$1,
                        selectedColor: const Color(0xFFF6EFC1),
                        backgroundColor: const Color(0xFF31405F),
                        labelStyle: TextStyle(
                            color: bt.startMin == t.$1
                                ? ink
                                : Colors.white),
                        onSelected: (_) async {
                          bt.startMin = t.$1;
                          await bt.save();
                          setState(() {});
                        },
                      ),
                  ]),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Begin automatically at that hour',
                        style: TextStyle(
                            fontSize: 13, color: Colors.white)),
                    activeThumbColor: const Color(0xFFF6EFC1),
                    value: bt.auto,
                    onChanged: (v) async {
                      bt.auto = v;
                      await bt.save();
                      setState(() {});
                    },
                  ),
                  TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: _skipBedtime,
                    child: const Text('☀️ Not tonight - keep the day awake',
                        style: TextStyle(
                            fontSize: 12.5, color: Color(0xFFF6EFC1))),
                  ),
                ],
              ),
            ),
            // printable coloring pages - a parent surface, printed at home
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(Corners.card)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🖍 Coloring pages & nature games', style: serif(16)),
                  const SizedBox(height: 4),
                  const Text(
                      'Real wildlife coloring pages from public wildlife '
                      'agencies, plus printable mazes, word searches and '
                      'criss-cross puzzles where every clue is a true thing '
                      'about a real animal. Free, nothing to buy. Opens in '
                      'your browser - print what they love.',
                      style: TextStyle(
                          fontSize: 12.5, height: 1.5, color: tx2)),
                  const SizedBox(height: 8),
                  TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () =>
                        openNewsLink('https://hopeling.app/coloring/'),
                    child: const Text('Open the shelf →',
                        style: TextStyle(fontSize: 13, color: fern)),
                  ),
                ],
              ),
            ),
            for (final p in kids) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(Corners.card)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🧒 ${p.name}', style: serif(16)),
                    const SizedBox(height: 4),
                    Text(KidCopy.summary(p),
                        style: const TextStyle(
                            fontSize: 12.5, height: 1.5, color: tx2)),
                    const SizedBox(height: 10),
                    Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                      FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: fern,
                            foregroundColor: paper),
                        onPressed: () => _enter(p),
                        child: const Text('Enter their world'),
                      ),
                      TextButton(
                        onPressed: () => _enterBedtime(p),
                        child: const Text('🌙 Bedtime',
                            style: TextStyle(fontSize: 12.5)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                            risePush(MuseumScreen(
                                kidId: p.id, kidName: p.name))),
                        child: const Text('🖼 Museum',
                            style: TextStyle(fontSize: 12.5)),
                      ),
                      TextButton(
                        onPressed: () async {
                          if (!await parentGate(context)) return;
                          Kids.remove(save, p.id);
                          await _persist();
                        },
                        child: const Text('Remove',
                            style:
                                TextStyle(fontSize: 12, color: tx2)),
                      ),
                    ]),
                  ],
                ),
              ),
            ],
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(Corners.card)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🌱 A new little helper', style: serif(15)),
                  const SizedBox(height: 10),
                  TextField(
                      controller: nameC,
                      decoration: InputDecoration(
                        hintText: 'nickname (nothing else is needed)',
                        filled: true,
                        fillColor: paper,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none),
                      )),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final b in const [
                      ['early', '🐣 Early explorer (4-6)'],
                      ['ranger', '🦊 Curious ranger (7-9)'],
                      ['young', '🦉 Young guardian (10-12)'],
                    ])
                      ChoiceChip(
                        label: Text(b[1],
                            style: const TextStyle(fontSize: 12)),
                        selected: band == b[0],
                        selectedColor: mint,
                        onSelected: (_) =>
                            setState(() => band = b[0]),
                      ),
                  ]),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: [
                    for (final i in const [
                      ['gentle', '☁️ Gentle'],
                      ['balanced', '🌤 Balanced'],
                      ['full', '☀️ Full truth'],
                    ])
                      ChoiceChip(
                        label: Text(i[1],
                            style: const TextStyle(fontSize: 12)),
                        selected: intensity == i[0],
                        selectedColor: mint,
                        onSelected: (_) =>
                            setState(() => intensity = i[0]),
                      ),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Expanded(
                        child: Text('Read stories aloud',
                            style: TextStyle(
                                fontSize: 12.5, color: tx2))),
                    Switch(
                        value: narration,
                        activeThumbColor: fern,
                        onChanged: (v) =>
                            setState(() => narration = v)),
                  ]),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: fern,
                          foregroundColor: paper),
                      onPressed: _create,
                      child: const Text('Create their profile'),
                    ),
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

// ---------- the child's world ----------
class KidsHome extends StatefulWidget {
  final String profileId;
  const KidsHome({super.key, required this.profileId});

  @override
  State<KidsHome> createState() => _KidsHomeState();
}

class _KidsHomeState extends State<KidsHome> {
  Save save = Save();
  AppContent? content;
  KidProfile? kid;
  bool sessionOver = false;
  final tts = StoryVoice(); // recorded narration, device voice fallback

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    tts.stop();
    super.dispose();
  }

  Future<void> _reload() async {
    final s = await Store.load();
    final c = await loadContent();
    final k = Kids.list(s).where((p) => p.id == widget.profileId).firstOrNull;
    final over = k == null ? false : await kidSessionOver(k.band);
    // Bedtime: the parent's schedule, or the one-hour manual override -
    // unless a parent said "not tonight", which wins for twelve hours.
    final bp = await BedtimePrefs.load();
    final prefs = await SharedPreferences.getInstance();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final skipUntil = prefs.getInt('btSkipUntil') ?? 0;
    final manualUntil = prefs.getInt('btManualUntil') ?? 0;
    final night = nowMs >= skipUntil &&
        (nowMs < manualUntil ||
            (bp.auto && inBedtimeWindow(DateTime.now(), bp)));
    if (mounted) {
      setState(() {
        save = s;
        content = c;
        kid = k;
        sessionOver = over;
        bedtime = night;
      });
    }
  }

  Future<void> _persistKid() async {
    if (kid == null) return;
    Kids.put(save, kid!);
    await Store.persist(save);
    saveTick.value++;
    if (Api.signedIn) Api.pushSave(save.toJson());
  }

  bool bedtime = false;

  Future<void> _speak(String text) async {
    if (kid?.narration != true) return;
    // the Storyteller reads like a grown-up reading aloud: sentence by
    // sentence, a breath between, questions lifting, endings landing
    await tts.speak(text, bedtime: bedtime, band: kid?.band ?? 'ranger');
  }

  ActionItem? get _kidAction {
    final c = content;
    if (c == null) return null;
    for (final a in c.actions.values) {
      if (KidPolicy.actionEligible(a)) return a;
    }
    return null;
  }

  /// Every story with a simple telling - the child's whole bookshelf.
  List<Lesson> get _kidStories {
    final c = content;
    if (c == null) return [];
    return [
      for (final j in c.journeys)
        for (final l in j.lessons)
          if (l.bodySimple.isNotEmpty) l
    ];
  }

  Future<void> _exit() async {
    if (await parentGate(context)) {
      await endKidSession();
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = kid;
    final c = content;
    if (k == null || c == null) {
      return const Scaffold(body: LoadingSeed());
    }
    if (sessionOver) return _sessionEnd();
    final g = k.guardianId == null ? null : c.guardianById(k.guardianId!);
    if (bedtime) {
      final stories = _kidStories;
      final story = stories.isEmpty
          ? null
          : stories[tonightIndex(stories.length)];
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _exit();
        },
        child: Scaffold(
          body: BedtimeHome(
            kidName: k.name,
            story: story,
            storyRead:
                story != null && k.lessonsRead.contains(story.t),
            guardian: g,
            onOpenStory: story == null
                ? () {}
                : () => _openComic(story, bedtime: true),
            onExitGate: _exit,
            speak: _speak,
          ),
        ),
      );
    }
    // Hopeling Kids: not a section - its own little app, four rooms.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        backgroundColor: kidCream,
        body: SafeArea(
          bottom: false,
          child: switch (room) {
            0 => _homeRoom(k, g),
            1 => _adventureRoom(k),
            2 => _storiesRoom(k),
            _ => _stuffRoom(k, g),
          },
        ),
        bottomNavigationBar: _kidNav(),
      ),
    );
  }

  int room = 0;

  Widget _kidNav() {
    const rooms = [
      ('🏡', 'Home'),
      ('🥾', 'Adventure'),
      ('📖', 'Stories'),
      ('🎨', 'My stuff'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
            top: BorderSide(
                color: kidInk.withValues(alpha: 0.08), width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Row(
            children: [
              for (var i = 0; i < rooms.length; i++)
                Expanded(
                  child: KidSquish(
                    semanticLabel: rooms[i].$2,
                    onTap: () => setState(() => room = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      margin:
                          const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: room == i
                            ? kidRoomColors[i].withValues(alpha: 0.55)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(rooms[i].$1,
                                style:
                                    const TextStyle(fontSize: 26)),
                            Text(rooms[i].$2,
                                style: kidTitle(11,
                                    color: room == i
                                        ? kidInk
                                        : kidInkLight)),
                          ]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roomCard(String emo, String title, String sub, Color color,
      {VoidCallback? onTap, String? footnote}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: KidCard(
        color: color,
        onTap: onTap,
        semanticLabel: '$title. $sub',
        child: Row(children: [
          Text(emo, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: kidTitle(17)),
                const SizedBox(height: 3),
                Text(sub, style: kidBody(13, color: kidInkLight)),
                if (footnote != null) ...[
                  const SizedBox(height: 4),
                  Text(footnote,
                      style: kidTitle(11.5, color: kidLeafDeep)),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: kidInkLight),
        ]),
      ),
    );
  }

  void _openWalk(KidProfile k) {
    Navigator.of(context).push(kidPush(ExplorerScreen(
        kidId: k.id,
        speak: _speak,
        onMet: (name) {
          if (!k.speciesMet.contains(name)) {
            k.speciesMet.add(name);
            _persistKid();
            setState(() {});
          }
        })));
  }

  int guideTaps = 0;
  bool rainbow = false;
  int sunTaps = 0;

  /// A painted world-strip for a room's header - the same scenery
  /// engine the comics use, so the whole app is one picture book.
  Widget _roomHeader(
      String title, String sub, ComicScene scene, int seed) {
    return Container(
      height: 108,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border:
            Border.all(color: kidInk.withValues(alpha: 0.12), width: 2),
      ),
      child: Stack(fit: StackFit.expand, children: [
        CustomPaint(painter: ScenePainter(seed, scene, false)),
        Positioned(
          left: 16,
          bottom: 12,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: kidTitle(24, color: Colors.white)
                  .copyWith(shadows: const [
                Shadow(color: Color(0x66000000), blurRadius: 6)
              ])),
              Text(sub,
                  style: kidBody(12.5, color: Colors.white)
                      .copyWith(shadows: const [
                    Shadow(color: Color(0x66000000), blurRadius: 5)
                  ])),
            ],
          ),
        ),
      ]),
    );
  }

  /// This month's little garland - the rooms wear the season.
  String get _seasonEmo => switch (DateTime.now().month) {
        12 || 1 || 2 => '❄️',
        3 || 4 || 5 => '🌸',
        6 || 7 || 8 => '☀️',
        _ => '🍂',
      };

  // ----- room 0: home - the sky, the guide, today -----
  Widget _homeRoom(KidProfile k, GuardianDef? g) {
    final tip = guideTips[dailyIndex(guideTips.length, 'tip')];
    final stories = _kidStories;
    final story =
        stories.isEmpty ? null : stories[tonightIndex(stories.length)];
    final act = _kidAction;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      children: [
        // the sky header
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 8, 22),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [kidSky, kidCream]),
            borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(36)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                    child: Text('Hi, ${k.name}!', style: kidTitle(28))),
                // the sun keeps a small secret for the patient
                KidSquish(
                  semanticLabel: 'The sun',
                  onTap: () {
                    setState(() {
                      sunTaps++;
                      if (sunTaps >= 5) rainbow = true;
                    });
                  },
                  child: KidDrift(
                      amount: 3,
                      seed: 2,
                      child: Text(rainbow ? '🌈' : '☀️',
                          style: const TextStyle(fontSize: 26))),
                ),
                KidDrift(
                    amount: 4,
                    seed: 4,
                    child: Text(_seasonEmo,
                        style: const TextStyle(fontSize: 20))),
                KidSquish(
                  semanticLabel: 'For grown-ups',
                  onTap: _exit,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.lock_outline,
                        color: kidInkLight, size: 22),
                  ),
                ),
              ]),
              const SizedBox(height: 10),
              // the guide: their own animal friend, or the fox.
              // tap once for the day's thought; keep tapping and you
              // find its giggle spot.
              Builder(builder: (context) {
                final line = guideTaps == 0
                    ? tip
                    : guideTickles[(guideTaps - 1) % guideTickles.length];
                return KidSquish(
                  semanticLabel: 'Your guide says: $line',
                  onTap: () {
                    setState(() => guideTaps++);
                    _speak(line);
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      KidDrift(
                          amount: 4,
                          child: Text(g?.emo ?? '🦊',
                              style: const TextStyle(fontSize: 52))),
                      const SizedBox(width: 10),
                      Expanded(child: GuideBubble(text: line)),
                      if (guideTaps > 0)
                        const Text('✨',
                            style: TextStyle(fontSize: 18)),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('TODAY', style: kidTitle(13, color: kidInkLight)),
        const SizedBox(height: 10),
        if (story != null)
          _roomCard('📖', 'Tonight\'s story', story.t, Colors.white,
              footnote: k.lessonsRead.contains(story.t)
                  ? '⭐ you know this one - hear it again!'
                  : 'picked just for today',
              onTap: () => _openComic(story)),
        _roomCard('🥾', 'A noticing walk',
            'the world is full of neighbors', Colors.white,
            onTap: () => _openWalk(k)),
        if (act != null)
          _roomCard('🌟', 'One small thing', act.t, Colors.white,
              footnote: KidPolicy.supervision(act),
              onTap: () => _openAction(act)),
      ],
    );
  }

  // ----- room 1: adventure -----
  Widget _adventureRoom(KidProfile k) {
    final act = _kidAction;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _roomHeader('Where to today?', 'the world is waiting, no hurry',
            ComicScene.meadow, 41),
        const SizedBox(height: 16),
        _roomCard('🥾', 'A noticing walk',
            'pause, look, listen - then meet a neighbor', kidLeaf,
            onTap: () => _openWalk(k)),
        _roomCard('🗺', 'Explore the wild',
            'real animals from every corner of Earth', Colors.white,
            onTap: _openExplore),
        if (act != null)
          _roomCard('🌟', 'One small thing', act.t, Colors.white,
              footnote: KidPolicy.supervision(act),
              onTap: () => _openAction(act)),
      ],
    );
  }

  // ----- room 2: stories - the shelf as a bookcase -----
  Widget _storiesRoom(KidProfile k) {
    final stories = _kidStories;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _roomHeader('Story time', 'every one is a little comic book',
            ComicScene.forest, 73),
        const SizedBox(height: 16),
        _roomCard('🎬', 'Nature cinema', 'a little film, just for you',
            const Color(0xFFF3D9DA),
            onTap: () => Navigator.of(context).push(kidPush(
                CinemaScreen(kidId: k.id, speak: _speak)))),
        if (stories.isEmpty)
          _roomCard('🍃', 'Stories are on their way',
              'they arrive with your first connection', Colors.white),
        for (var i = 0; i < stories.length; i++)
          _roomCard(
              k.lessonsRead.contains(stories[i].t) ? '⭐' : '📕',
              stories[i].t,
              k.lessonsRead.contains(stories[i].t)
                  ? 'you know this one - hear it again!'
                  : 'a new book on the shelf',
              kidRoomColors[i % kidRoomColors.length]
                  .withValues(alpha: 0.35),
              onTap: () => _openComic(stories[i])),
        if (stories.isNotEmpty)
          _roomCard('🤝', 'Read together',
              'the plain words, for a grown-up\'s lap', Colors.white,
              onTap: _openShelf),
      ],
    );
  }

  // ----- room 3: my stuff - the child's own things -----
  Widget _stuffRoom(KidProfile k, GuardianDef? g) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _roomHeader('My stuff', 'made by you, kept by you',
            ComicScene.river, 19),
        const SizedBox(height: 16),
        _roomCard('🎨', 'Draw today\'s page', journalPrompt(),
            kidSun.withValues(alpha: 0.45),
            onTap: () => Navigator.of(context).push(
                kidPush(JournalPage(kidId: k.id, speak: _speak)))),
        _roomCard('🖼', 'My museum', 'every page you ever drew',
            Colors.white,
            onTap: () => Navigator.of(context).push(kidPush(
                MuseumScreen(kidId: k.id, kidName: k.name)))),
        _roomCard(
            g == null ? '🐾' : g.emo,
            g == null ? 'Meet an animal friend' : 'My ${g.name}',
            g == null ? KidCopy.guardianAsk : 'see how they are doing',
            Colors.white,
            onTap: () => _openGuardian(g)),
        if (k.speciesMet.isNotEmpty || k.lessonsRead.isNotEmpty)
          _roomCard(
              '⭐',
              'My discoveries',
              '${k.speciesMet.length} animals met · ${k.lessonsRead.length} stories read',
              Colors.white,
              onTap: _openDiscoveries),
      ],
    );
  }

  /// The bookshelf: every simple story, read ones marked with a star.
  void _openShelf() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: paper,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.75,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Pick a story 📖', style: serif(20)),
              const SizedBox(height: 10),
              for (final l in _kidStories)
                ListTile(
                  leading: Text(
                      kid!.lessonsRead.contains(l.t) ? '⭐' : '📖',
                      style: const TextStyle(fontSize: 22)),
                  title: Text(l.t,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _openComic(l);
                  },
                  onLongPress: () {
                    // the plain telling, for reading together
                    Navigator.of(ctx).pop();
                    _openStory(l);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Explore the wild: worlds, then real animals with real photographs.
  /// Gentle by policy: no red lists, no threats, only wonder.
  void _openExplore() {
    final worlds = content!.worlds.where((w) => w.species.isNotEmpty).toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: paper,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.8,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('Where shall we go? 🗺', style: serif(20)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final w in worlds)
                    ActionChip(
                      avatar: Text(w.emo,
                          style: const TextStyle(fontSize: 18)),
                      label: Text(w.name,
                          style: const TextStyle(fontSize: 13)),
                      backgroundColor: Colors.white,
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _openWorldAnimals(w);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openWorldAnimals(World w) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: paper,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.8,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('${w.emo} ${w.name}', style: serif(20)),
              const SizedBox(height: 6),
              Text(w.sciSimple.isNotEmpty ? w.sciSimple : w.sum,
                  style: const TextStyle(
                      fontSize: 14, height: 1.6, color: tx2)),
              const SizedBox(height: 14),
              for (final name in w.species)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        Haptics.tick();
                        if (!kid!.speciesMet.contains(name)) {
                          kid!.speciesMet.add(name);
                          _persistKid();
                        }
                        _openAnimal(name, w);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                width: 56,
                                height: 56,
                                child: FutureBuilder<WikiSummary?>(
                                  future: wikiSummary(name),
                                  builder: (c2, snap) {
                                    final ws = snap.data;
                                    if (ws == null ||
                                        ws.imgSmall.isEmpty) {
                                      return Container(
                                          color: mint.withValues(
                                              alpha: 0.3),
                                          alignment: Alignment.center,
                                          child: Text(w.emo,
                                              style: const TextStyle(
                                                  fontSize: 22)));
                                    }
                                    return WikiImage(
                                        big: ws.imgSmall,
                                        small: ws.imgSmall,
                                        emo: w.emo);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                  '${kid!.speciesMet.contains(name) ? '⭐ ' : ''}$name',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: ink)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAnimal(String name, World w) {
    final text = w.sciSimple.isNotEmpty ? w.sciSimple : w.sum;
    _speak('$name. $text');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: paper,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.75,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              SizedBox(
                height: 240,
                child: FutureBuilder<WikiSummary?>(
                  future: wikiSummary(name),
                  builder: (c2, snap) {
                    final ws = snap.data;
                    if (ws == null || ws.imgSmall.isEmpty) {
                      return Container(
                          color: mint.withValues(alpha: 0.25),
                          alignment: Alignment.center,
                          child: Text(w.emo,
                              style: const TextStyle(fontSize: 64)));
                    }
                    return WikiImage(
                        big: ws.img, small: ws.imgSmall, emo: w.emo);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: serif(24)),
                    const SizedBox(height: 10),
                    Text(text,
                        style: TextStyle(
                            fontFamily: 'serif',
                            fontSize:
                                kid?.band == 'early' ? 19 : 16,
                            height: 1.8,
                            color: ink)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) => tts.stop());
  }

  void _openDiscoveries() {
    final k = kid!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: paper,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.7,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text('⭐ My discoveries', style: serif(20)),
              const SizedBox(height: 12),
              if (k.speciesMet.isNotEmpty) ...[
                const Text('ANIMALS I HAVE MET',
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w800,
                        color: fern)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in k.speciesMet)
                      Chip(
                          label: Text(s,
                              style: const TextStyle(fontSize: 12.5)),
                          backgroundColor: Colors.white),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              if (k.lessonsRead.isNotEmpty) ...[
                const Text('STORIES I HAVE READ',
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w800,
                        color: fern)),
                const SizedBox(height: 8),
                for (final t in k.lessonsRead)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('📖 $t',
                        style: const TextStyle(
                            fontSize: 14, color: ink)),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Story time as a comic book: the story's own words, panel by panel,
  /// told by a host animal. Narration follows the page.
  void _openComic(Lesson l, {bool bedtime = false}) {
    Navigator.of(context).push(risePush(ComicReader(
      lesson: l,
      band: kid?.band ?? 'ranger',
      bedtime: bedtime,
      speak: _speak,
      stopSpeaking: tts.stop,
      onFinished: () {
        final key = l.t;
        if (!(kid!.lessonsRead.contains(key))) {
          kid!.lessonsRead.add(key);
          _persistKid();
        }
        setState(() {});
      },
    )));
  }

  void _openStory(Lesson l) {
    final text = KidPolicy.lessonText(l);
    _speak('${l.t}. $text');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: paper,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.8,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
            child: ListView(
              children: [
                Text(l.t, style: serif(24, height: 1.3)),
                const SizedBox(height: 16),
                Text(text,
                    style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: kid?.band == 'early' ? 20 : 17,
                        height: 1.9,
                        color: ink)),
                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: fern, foregroundColor: paper),
                  onPressed: () {
                    tts.stop();
                    final key = l.t;
                    if (!(kid!.lessonsRead.contains(key))) {
                      kid!.lessonsRead.add(key);
                      _persistKid();
                    }
                    Navigator.of(ctx).pop();
                    setState(() {});
                  },
                  child: const Text('The end 🌟'),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) => tts.stop());
  }

  void _openGuardian(GuardianDef? current) {
    final c = content!;
    if (current != null) {
      _speak(KidPolicy.guardianStory(current));
      showModalBottomSheet(
        context: context,
        backgroundColor: paper,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${current.emo} ${current.name}', style: serif(22)),
                const SizedBox(height: 12),
                Text(KidPolicy.guardianStory(current),
                    style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 16,
                        height: 1.8,
                        color: ink)),
              ],
            ),
          ),
        ),
      ).then((_) => tts.stop());
      return;
    }
    // choose a friend: child-safe stories only, no counts of loss
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: paper,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.7,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(KidCopy.guardianAsk, style: serif(19)),
              const SizedBox(height: 12),
              for (final g in c.guardians.take(8))
                ListTile(
                  leading:
                      Text(g.emo, style: const TextStyle(fontSize: 26)),
                  title: Text(g.name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  onTap: () {
                    kid!.guardianId = g.id;
                    if (!kid!.speciesMet.contains(g.name)) {
                      kid!.speciesMet.add(g.name);
                    }
                    _persistKid();
                    Haptics.bloom();
                    Navigator.of(ctx).pop();
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(KidCopy.guardianYes)));
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAction(ActionItem act) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: paper,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(KidPolicy.supervision(act) ?? '',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: fern)),
              const SizedBox(height: 8),
              Text(act.t, style: serif(20, height: 1.3)),
              const SizedBox(height: 10),
              Text(KidPolicy.actionWhy(act),
                  style: const TextStyle(
                      fontSize: 14.5, height: 1.6, color: tx2)),
              const SizedBox(height: 18),
              HoldToCommit(
                done: false,
                label: 'I did my small thing',
                onCommit: () async {
                  final s = await Store.load();
                  engine.recordCompletion(s, act, todayStr());
                  await Store.persist(s);
                  await Pulse.add(); // one equal family drop
                  kid!.actions += 1;
                  save = s;
                  await _persistKid();
                  Haptics.yourDrop();
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (mounted) {
                    if (!Motion.still(context)) RainBurst.show(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text(KidCopy.done)));
                    setState(() {});
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sessionEnd() {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F8EF),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(36),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🌙', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(KidCopy.sessionEnd,
                    textAlign: TextAlign.center,
                    style: serif(20, height: 1.5)),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () async {
                    if (await parentGate(context)) {
                      await extendKidSession();
                      if (mounted) {
                        setState(() => sessionOver = false);
                      }
                    }
                  },
                  child: const Text('A little longer (grown-ups)',
                      style: TextStyle(color: fern)),
                ),
                TextButton(
                  onPressed: () async {
                    await endKidSession();
                    if (mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Goodbye for now 👋',
                      style: TextStyle(color: tx2)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
