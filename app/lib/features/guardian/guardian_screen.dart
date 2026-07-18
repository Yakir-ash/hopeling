// The Guardian relationship: ceremony, home, letter, reflection, archive.
// A relationship space, not a species profile - and never a pet.

import 'package:flutter/material.dart';

import '../../core/atmosphere.dart';
import '../../core/clock.dart';
import '../../core/haptics.dart';
import '../../core/notify.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/api.dart';
import '../../data/content.dart';
import '../../data/guardian.dart';
import '../../data/pulse.dart';
import '../../data/rules.dart' as rules;
import '../../data/save.dart';
import '../../data/wiki.dart';
import '../grove/grove_screen.dart' show HoldToCommit;
import 'package:shared_preferences/shared_preferences.dart';

/// The commitment journey: explanation first, then the hold.
Future<bool> offerGuardianship(
    BuildContext context, GuardianDef g, AppContent content) async {
  final began = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: paper,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => _CeremonySheet(g: g),
  );
  if (began == true && context.mounted) {
    Navigator.of(context)
        .push(risePush(GuardianHome(g: g, content: content)));
    return true;
  }
  return false;
}

class _CeremonySheet extends StatelessWidget {
  final GuardianDef g;
  const _CeremonySheet({required this.g});

  Future<void> _commit(BuildContext context) async {
    final s = await Store.load();
    final began = Guardianship.begin(s, g.id, todayStr());
    if (began) {
      await Store.persist(s);
      final p = await SharedPreferences.getInstance();
      await p.setString('guardianEmo', g.emo);
      await addTimeline(g.id, 'began');
      saveTick.value++;
      if (Api.signedIn) Api.pushSave(s.toJson());
      Haptics.bloom(); // sacred: a relationship began
    }
    if (context.mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            28, 26, 28, 24 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(g.emo, style: const TextStyle(fontSize: 36)),
            const SizedBox(height: 10),
            Text('Become a Guardian of the ${g.name.toLowerCase()}',
                style: serif(21, height: 1.3)),
            const SizedBox(height: 10),
            const Text(GCopy.explanation,
                style: TextStyle(fontSize: 14, height: 1.65, color: tx2)),
            const SizedBox(height: 20),
            HoldToCommit(
              done: false,
              label: GCopy.holdLabel,
              onCommit: () => _commit(context),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Not yet', style: TextStyle(color: tx2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GuardianHome extends StatefulWidget {
  final GuardianDef g;
  final AppContent content;
  const GuardianHome({super.key, required this.g, required this.content});

  @override
  State<GuardianHome> createState() => _GuardianHomeState();
}

class _GuardianHomeState extends State<GuardianHome> {
  Save save = Save();
  List<Map<String, String>> timeline = [];
  final reflectC = TextEditingController();
  bool lettersOn = true;

  GuardianDef get g => widget.g;
  bool get isActive => Guardianship.activeId(save) == g.id;
  World? get world =>
      g.cats.isEmpty ? null : widget.content.worlds
          .where((w) => w.slug == g.cats.first)
          .firstOrNull;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final s = await Store.load();
    final tl = await timelineFor(g.id);
    final note = await guardianReflection(g.id);
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      save = s;
      timeline = tl;
      lettersOn = p.getBool('robin_letters') ?? true;
      if (note.isNotEmpty && reflectC.text.isEmpty) reflectC.text = note;
    });
  }

  Future<void> _archive() async {
    final sure = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: paper,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(GCopy.archiveTitle, style: serif(20)),
              const SizedBox(height: 8),
              const Text(GCopy.archiveBody,
                  style:
                      TextStyle(fontSize: 14, height: 1.6, color: tx2)),
              const SizedBox(height: 18),
              Row(children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Archive',
                      style: TextStyle(color: ink)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Stay', style: TextStyle(color: fern)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
    if (sure != true) return;
    final s = await Store.load();
    Guardianship.archive(s, todayStr());
    await Store.persist(s);
    final p = await SharedPreferences.getInstance();
    await p.remove('guardianEmo');
    saveTick.value++;
    if (Api.signedIn) Api.pushSave(s.toJson());
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(GCopy.archived)));
      await _reload();
    }
  }

  Future<void> _restore() async {
    final s = await Store.load();
    if (Guardianship.restore(s, g.id, todayStr())) {
      await Store.persist(s);
      final p = await SharedPreferences.getInstance();
      await p.setString('guardianEmo', g.emo);
      saveTick.value++;
      if (Api.signedIn) Api.pushSave(s.toJson());
      await _reload();
    }
  }

  Future<void> _completeRelated(ActionItem act) async {
    final s = await Store.load();
    rules.complete(s, todayStr());
    await Store.persist(s);
    await Pulse.add(); // joins the rain as an equal drop, never a bigger one
    await addTimeline(g.id, 'action');
    saveTick.value++;
    if (Api.signedIn) Api.pushSave(s.toJson());
    Haptics.yourDrop();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('🌧 ${Api.signedIn ? RainCopy.joined : RainCopy.guest}')));
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final atmos =
        atmosphereOf(g.cats.isEmpty ? 'forests' : g.cats.first);
    final letter = welcomeLetter(g, world);
    final act = letter.actionSlug != null
        ? widget.content.actions[letter.actionSlug]
        : null;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 230,
            pinned: true,
            backgroundColor: atmos.deep,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsetsDirectional.only(start: 52, bottom: 14),
              title: Text('${g.emo}  ${g.name}',
                  style: serif(18, color: Colors.white)),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  FutureBuilder<WikiSummary?>(
                    future:
                        wikiSummary(g.wiki.isNotEmpty ? g.wiki : g.name),
                    builder: (context, snap) {
                      final w = snap.data;
                      if (w == null || w.imgSmall.isEmpty) {
                        return Container(color: atmos.deep);
                      }
                      return Drift(
                          child: WikiImage(
                              big: w.img, small: w.imgSmall, emo: g.emo));
                    },
                  ),
                  DecoratedBox(
                      decoration:
                          BoxDecoration(gradient: atmos.heroVeil())),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 20, 24, 40 + MediaQuery.of(context).padding.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isActive) ...[
                    Semantics(
                      label: GCopy.began(g.name.toLowerCase()),
                      child: Text(
                          GCopy.anniversary(g.name.toLowerCase(),
                              Guardianship.since(save)),
                          style: serif(15,
                              style: FontStyle.italic,
                              weight: FontWeight.w500,
                              color: atmos.accent)),
                    ),
                  ] else ...[
                    Text('This relationship rests in your history.',
                        style: serif(15,
                            style: FontStyle.italic,
                            weight: FontWeight.w500,
                            color: tx2)),
                    const SizedBox(height: 10),
                    OutlinedButton(
                        onPressed: _restore,
                        child: const Text('Walk together again',
                            style: TextStyle(color: fern))),
                  ],
                  const SizedBox(height: 22),
                  Text('THE LATEST LETTER', style: kicker(atmos.accent)),
                  const SizedBox(height: 10),
                  _LetterCard(
                      letter: letter,
                      g: g,
                      act: act,
                      onRead: () => addTimeline(g.id, 'letter'),
                      onAct: act == null || !isActive
                          ? null
                          : () => _completeRelated(act)),
                  const SizedBox(height: 24),
                  Text('YOUR REFLECTION', style: kicker(atmos.accent)),
                  const SizedBox(height: 6),
                  Text(GCopy.reflectionPrompt,
                      style: serif(15, weight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reflectC,
                    maxLines: 3,
                    onChanged: (t) {
                      saveGuardianReflection(g.id, t);
                      if (t.trim().isNotEmpty) {
                        addTimeline(g.id, 'reflection');
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Private, on this phone, yours...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none),
                    ),
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  if (timeline.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('YOUR TIME TOGETHER', style: kicker(atmos.accent)),
                    const SizedBox(height: 4),
                    const Text('presence, never absence',
                        style: TextStyle(fontSize: 11.5, color: tx2)),
                    const SizedBox(height: 10),
                    for (final e in timeline.take(12))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                            '${e['d']} · ${GCopy.timelineKinds[e['k']] ?? e['k']}',
                            style: const TextStyle(
                                fontSize: 13, color: ink)),
                      ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Text('🕊 Guardian letters',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: ink)),
                      const Spacer(),
                      Switch(
                        value: lettersOn,
                        activeThumbColor: fern,
                        onChanged: (v) async {
                          final p =
                              await SharedPreferences.getInstance();
                          await p.setBool('robin_letters', v);
                          if (mounted) setState(() => lettersOn = v);
                        },
                      ),
                    ],
                  ),
                  if (isActive) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _archive,
                      child: const Text(GCopy.archiveTitle,
                          style: TextStyle(fontSize: 13, color: tx2)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LetterCard extends StatefulWidget {
  final GuardianLetter letter;
  final GuardianDef g;
  final ActionItem? act;
  final VoidCallback onRead;
  final VoidCallback? onAct;
  const _LetterCard(
      {required this.letter,
      required this.g,
      required this.act,
      required this.onRead,
      this.onAct});

  @override
  State<_LetterCard> createState() => _LetterCardState();
}

class _LetterCardState extends State<_LetterCard> {
  @override
  void initState() {
    super.initState();
    widget.onRead();
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.letter;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Corners.card),
        boxShadow: [
          BoxShadow(
              color: ink.withValues(alpha: 0.07),
              blurRadius: 18,
              offset: const Offset(0, 7)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // The seal. A long press sends a test letter notification.
              GestureDetector(
                onLongPress: () {
                  Robin.guardianTestLetter(widget.g.id, widget.g.name);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content:
                          Text('A test letter is on its way. (test only)')));
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: gold, width: 2)),
                  child: Text(widget.g.emo,
                      style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(l.title, style: serif(16, height: 1.35)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(l.opening,
              style: const TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                  color: tx2)),
          const SizedBox(height: 10),
          Text(l.body,
              style: serif(15,
                  weight: FontWeight.w500, height: 1.7, color: ink)),
          const SizedBox(height: 10),
          Text(l.why,
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: ink)),
          if (widget.act != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: paper,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ONE THING, WHEN TODAY HAS ROOM', style: kicker()),
                  const SizedBox(height: 6),
                  Text(widget.act!.t,
                      style: serif(14.5, height: 1.35)),
                  if (widget.onAct != null) ...[
                    const SizedBox(height: 10),
                    FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: fern, foregroundColor: paper),
                      onPressed: widget.onAct,
                      child: const Text('I did it'),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text('SOURCES', style: kicker(tx2)),
          const SizedBox(height: 6),
          for (final s in l.sources)
            Text('· $s',
                style: const TextStyle(
                    fontSize: 11.5, height: 1.6, color: tx2)),
        ],
      ),
    );
  }
}
