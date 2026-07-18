// "Something else today?" - reasoned alternatives and the full browser.
// Never a feed: three thoughtful options, each explaining itself, and a
// browsable shelf with honest filters. Choosing holds for today only;
// tomorrow the shared clock returns.

import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../data/actions.dart' as engine;
import '../../data/content.dart';
import '../../data/save.dart';
import '../../core/clock.dart';

/// The action, in full: steps, the science, the evidence - the depth the
/// PWA offered on tap. Completing from here runs the caller's ceremony.
Future<void> showActionDetail(BuildContext context, ActionItem a,
    {Future<void> Function()? onDone}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: paper,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (sheetCtx) => SafeArea(
      child: SizedBox(
        height: MediaQuery.of(sheetCtx).size.height * 0.82,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ListView(
                  children: [
                    Text(
                        '~${a.min} MIN · ${'●' * a.diff}${'○' * (3 - a.diff)} · ${switch (a.mod) {
                          'home' => '🏠 AT HOME',
                          'outdoor' => '🌳 OUTDOORS',
                          'online' => '💻 ONLINE',
                          'financial' => '💚 GIVING',
                          _ => a.mod.toUpperCase()
                        }}',
                        style: kicker()),
                    const SizedBox(height: 10),
                    Text(a.t, style: serif(23, height: 1.25)),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsetsDirectional.only(start: 12),
                      decoration: const BoxDecoration(
                        border: BorderDirectional(
                            start: BorderSide(color: mint, width: 3)),
                      ),
                      child: SimplyText(
                        text: a.why,
                        simpleText: a.whySimple,
                        style: serif(15,
                            style: FontStyle.italic,
                            weight: FontWeight.w500,
                            height: 1.6,
                            color: tx2),
                      ),
                    ),
                    if (a.imp.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text('WHY IT WORKS', style: kicker()),
                      const SizedBox(height: 6),
                      Text(a.imp,
                          style: const TextStyle(
                              fontSize: 14, height: 1.6, color: ink)),
                    ],
                    if (a.steps.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text('HOW TO', style: kicker()),
                      const SizedBox(height: 6),
                      for (var i = 0; i < a.steps.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('${i + 1}.  ${a.steps[i]}',
                              style: const TextStyle(
                                  fontSize: 14, height: 1.55, color: ink)),
                        ),
                    ],
                    if (engine.impactLine(a).isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text('WHAT IT ADDS UP TO', style: kicker()),
                      const SizedBox(height: 6),
                      Text(engine.impactLine(a),
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontStyle: FontStyle.italic,
                              color: tx2)),
                    ],
                    if (a.ev.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Text('EVIDENCE', style: kicker(tx2)),
                      const SizedBox(height: 6),
                      for (final e in a.ev)
                        Text('· $e',
                            style: const TextStyle(
                                fontSize: 11.5, height: 1.6, color: tx2)),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              if (onDone != null)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: fern,
                        foregroundColor: paper,
                        padding:
                            const EdgeInsets.symmetric(vertical: 15)),
                    onPressed: () async {
                      Navigator.of(sheetCtx).pop();
                      await onDone();
                    },
                    child: const Text('I did it',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<String?> showAlternates(BuildContext context) async {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: paper,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => const _AlternatesSheet(),
  );
}

class _AlternatesSheet extends StatefulWidget {
  const _AlternatesSheet();

  @override
  State<_AlternatesSheet> createState() => _AlternatesSheetState();
}

class _AlternatesSheetState extends State<_AlternatesSheet> {
  List<engine.Pick> picks = [];
  bool browsing = false;
  String mode = 'any';
  AppContent? content;
  Save? save;
  engine.EngineLocal? st;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await loadContent();
    final s = await Store.load();
    final local = await engine.loadEngineLocal();
    if (!mounted) return;
    setState(() {
      content = c;
      save = s;
      st = local;
      mode = local.mode;
      picks = engine.alternates(c, s, local, todayStr());
    });
  }

  Future<void> _choose(String slug) async {
    await engine.saveOverride(slug);
    Haptics.settle();
    if (mounted) Navigator.of(context).pop(slug);
  }

  Future<void> _dismiss(String slug) async {
    await engine.saveDismiss(slug);
    Haptics.tick();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = content;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.82,
        child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
        child: c == null
            ? const Center(child: Text('...', style: TextStyle(color: tx2)))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(browsing ? 'Every open door' : 'Something else today?',
                      style: serif(20)),
                  const SizedBox(height: 4),
                  Text(
                      browsing
                          ? 'everything you are ready for, honestly filtered'
                          : 'three doors, each with its reason - today only',
                      style: const TextStyle(fontSize: 12.5, color: tx2)),
                  const SizedBox(height: 14),
                  if (browsing) ...[
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final m in const [
                          ['any', 'All'],
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
                            onSelected: (_) async {
                              await engine.savePrefsMode(
                                  m[0], st?.minutes ?? 0);
                              setState(() => mode = m[0]);
                              await _load();
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView(
                        children: [
                          for (final a in c.actions.values)
                            if (engine.eligible(a, save!, st!, todayStr(),
                                    ignorePrefs: mode == 'any') &&
                                (mode == 'any' || a.mod == mode))
                              _row(engine.Pick(a, ''), compact: true),
                        ],
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: ListView(
                        children: [
                          if (picks.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                  'Today\'s door is the right one - nothing else fits better right now.',
                                  style: TextStyle(
                                      fontSize: 13.5,
                                      height: 1.5,
                                      color: tx2)),
                            ),
                          for (final p in picks) _row(p),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: () =>
                                setState(() => browsing = true),
                            child: const Text('Browse every action →',
                                style: TextStyle(
                                    fontSize: 13, color: fern)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
        ),
      ),
    );
  }

  Widget _row(engine.Pick p, {bool compact = false}) {
    final a = p.a;
    final impact = engine.impactLine(a);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(a.t, style: serif(15, height: 1.3)),
          if (p.reason.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(p.reason,
                style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: fern)),
          ],
          const SizedBox(height: 6),
          Text(
              '~${a.min} min · ${'●' * a.diff}${'○' * (3 - a.diff)}'
              '${impact.isEmpty ? '' : ' · $impact'}',
              style: const TextStyle(fontSize: 11.5, color: tx2)),
          const SizedBox(height: 10),
          Row(
            children: [
              FilledButton(
                style: FilledButton.styleFrom(
                    backgroundColor: fern,
                    foregroundColor: paper,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10)),
                onPressed: () => _choose(a.slug),
                child: const Text('Make it today\'s',
                    style: TextStyle(fontSize: 13)),
              ),
              if (!compact)
                TextButton(
                  onPressed: () => _dismiss(a.slug),
                  child: const Text('not for me',
                      style: TextStyle(fontSize: 12, color: tx2)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
