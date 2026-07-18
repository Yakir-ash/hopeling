// Kids Mode - the parent area, the gate, and the child's world.
// The child's home is big, warm, and few: an adventure, a friend,
// one small thing to do. Exit and settings live behind the gate.

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../core/clock.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/actions.dart' as engine;
import '../../data/api.dart';
import '../../data/content.dart';
import '../../data/kids.dart';
import '../../data/pulse.dart';
import '../../data/save.dart';
import '../grove/grove_screen.dart' show HoldToCommit, RainBurst;

// ---------- the parent gate ----------
Future<bool> parentGate(BuildContext context) async {
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

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final s = await Store.load();
    if (mounted) setState(() => save = s);
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
                    Row(children: [
                      FilledButton(
                        style: FilledButton.styleFrom(
                            backgroundColor: fern,
                            foregroundColor: paper),
                        onPressed: () => _enter(p),
                        child: const Text('Enter their world'),
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
  final tts = FlutterTts();

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
    if (mounted) {
      setState(() {
        save = s;
        content = c;
        kid = k;
        sessionOver = over;
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

  Future<void> _speak(String text) async {
    if (kid?.narration != true) return;
    await tts.stop();
    await tts.setSpeechRate(0.45);
    await tts.speak(text);
  }

  ActionItem? get _kidAction {
    final c = content;
    if (c == null) return null;
    for (final a in c.actions.values) {
      if (KidPolicy.actionEligible(a)) return a;
    }
    return null;
  }

  Lesson? get _kidLesson {
    final c = content;
    if (c == null) return null;
    for (final j in c.journeys) {
      for (final l in j.lessons) {
        if (l.bodySimple.isNotEmpty &&
            !(kid?.lessonsRead.contains('${j.slug}:${l.t}') ?? false)) {
          return l;
        }
      }
    }
    return c.journeys.isNotEmpty && c.journeys.first.lessons.isNotEmpty
        ? c.journeys.first.lessons.first
        : null;
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
    final act = _kidAction;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F8EF),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
            children: [
              Row(children: [
                Expanded(
                    child: Text('Hello, ${k.name} 🌱',
                        style: serif(26))),
                IconButton(
                    tooltip: 'For grown-ups',
                    onPressed: _exit,
                    icon: const Icon(Icons.lock_outline,
                        color: tx2, size: 20)),
              ]),
              Text(KidCopy.welcome,
                  style: const TextStyle(fontSize: 14, color: tx2)),
              const SizedBox(height: 20),
              _bigCard(
                '📖 Today\'s adventure',
                _kidLesson?.t ?? 'A story is on its way',
                mint.withValues(alpha: 0.5),
                onTap: _kidLesson == null
                    ? null
                    : () => _openStory(_kidLesson!),
              ),
              _bigCard(
                g == null ? '🐾 Meet an animal friend' : '${g.emo} My ${g.name}',
                g == null
                    ? KidCopy.guardianAsk
                    : 'See how they are doing',
                const Color(0xFFFFF3DD),
                onTap: () => _openGuardian(g),
              ),
              if (act != null)
                _bigCard(
                  '🌟 One small thing',
                  act.t,
                  const Color(0xFFE3F0FA),
                  sub2: KidPolicy.supervision(act),
                  onTap: () => _openAction(act),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bigCard(String title, String sub, Color bg,
      {String? sub2, VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onTap == null
              ? null
              : () {
                  Haptics.tick();
                  onTap();
                },
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: serif(20, height: 1.25)),
                const SizedBox(height: 6),
                Text(sub,
                    style: const TextStyle(
                        fontSize: 14.5, height: 1.45, color: ink)),
                if (sub2 != null) ...[
                  const SizedBox(height: 8),
                  Text(sub2,
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: fern)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
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
