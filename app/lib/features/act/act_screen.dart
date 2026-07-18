// Act - the full shelf, like the PWA's Act tab. Every approved action,
// filtered by difficulty and place, completable right here. Extra acts
// are extra drops: the engine and the rain treat them all as equals.

import 'package:flutter/material.dart';

import '../../core/clock.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/actions.dart' as engine;
import '../../data/api.dart';
import '../../data/content.dart';
import '../../data/pulse.dart';
import '../../data/rules.dart' as rules;
import '../../data/save.dart';
import '../grove/grove_screen.dart' show RainBurst;
import 'act_sheet.dart' show showActionDetail;

class ActScreen extends StatefulWidget {
  const ActScreen({super.key});

  @override
  State<ActScreen> createState() => _ActScreenState();
}

class _ActScreenState extends State<ActScreen> {
  AppContent? content;
  Save save = Save();
  int dif = 0; // 0 = all
  String mode = '';

  @override
  void initState() {
    super.initState();
    contentTick.addListener(_reload);
    saveTick.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    contentTick.removeListener(_reload);
    saveTick.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
    loadContent().then((c) {
      if (mounted) setState(() => content = c);
    });
    Store.load().then((s) {
      if (mounted) setState(() => save = s);
    });
  }

  Future<void> _complete(ActionItem a) async {
    final s = await Store.load();
    final out = engine.recordCompletion(s, a, todayStr());
    await Store.persist(s);
    await engine.recordDoneLocally(a.slug);
    Pulse.add();
    if (Api.signedIn) Api.pushSave(s.toJson());
    saveTick.value++;
    Haptics.yourDrop();
    if (mounted && !Motion.still(context)) RainBurst.show(context);
    if (!mounted) return;
    final msg = out.ringAdded != null
        ? '🪵 ${rules.Lines.ringFormed(out.ringAdded!)}'
        : out.newFriend != null
            ? rules.Lines.friendArrived(out.newFriend!)
            : '🌧 ${Api.signedIn ? RainCopy.joined : RainCopy.guest}';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final c = content;
    final acts = c == null
        ? <ActionItem>[]
        : [
            for (final a in c.actions.values)
              if (a.status == 'approved' &&
                  (dif == 0 || a.diff == dif) &&
                  (mode.isEmpty || a.mod == mode))
                a
          ];
    return Scaffold(
      body: SafeArea(
        child: c == null
            ? const LoadingSeed(line: 'Gathering the small things...')
            : ListView(
                padding: EdgeInsets.fromLTRB(24, 18, 24,
                    32 + MediaQuery.of(context).padding.bottom),
                children: [
                  Text('⚡ Act', style: serif(28)),
                  const SizedBox(height: 4),
                  const Text(
                      'every small thing, and the honest reason it matters',
                      style: TextStyle(fontSize: 13, color: tx2)),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final d in const [
                        [0, 'All'],
                        [1, 'Easy'],
                        [2, 'Medium'],
                        [3, 'High impact'],
                      ])
                        ChoiceChip(
                          label: Text(d[1] as String,
                              style: const TextStyle(fontSize: 12.5)),
                          selected: dif == d[0],
                          selectedColor: mint,
                          onSelected: (_) =>
                              setState(() => dif = d[0] as int),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final m in const [
                        ['', 'Any'],
                        ['home', '🏠 Home'],
                        ['outdoor', '🌳 Outdoor'],
                        ['online', '💻 Online'],
                        ['financial', '💚 Give'],
                      ])
                        ChoiceChip(
                          label: Text(m[1],
                              style: const TextStyle(fontSize: 12.5)),
                          selected: mode == m[0],
                          selectedColor: mint,
                          onSelected: (_) =>
                              setState(() => mode = m[0]),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (acts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(
                        child: Text('Nothing fits those filters today.',
                            style:
                                TextStyle(fontSize: 13.5, color: tx2)),
                      ),
                    ),
                  for (final a in acts) _card(a),
                ],
              ),
      ),
    );
  }

  Widget _card(ActionItem a) {
    final doneEver =
        (save.extra['done'] as Map?)?.containsKey(a.slug) ?? false;
    final impact = engine.impactLine(a);
    return GestureDetector(
      onTap: () {
        Haptics.tick();
        showActionDetail(context, a, onDone: () => _complete(a));
      },
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Corners.card),
        boxShadow: [
          BoxShadow(
              color: ink.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${doneEver ? '✅ ' : ''}${a.t}',
              style: serif(16, height: 1.3)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsetsDirectional.only(start: 10),
            decoration: const BoxDecoration(
              border:
                  BorderDirectional(start: BorderSide(color: mint, width: 3)),
            ),
            child: Text(a.why,
                style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                    color: tx2)),
          ),
          const SizedBox(height: 8),
          Text(
              '~${a.min} min · ${'●' * a.diff}${'○' * (3 - a.diff)}'
              '${impact.isEmpty ? '' : ' · $impact'}',
              style: const TextStyle(fontSize: 11.5, color: tx2)),
          const SizedBox(height: 12),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: fern,
                foregroundColor: paper,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 11)),
            onPressed: () => _complete(a),
            child: const Text('I did it', style: TextStyle(fontSize: 13.5)),
          ),
        ],
      ),
      ),
    );
  }
}
