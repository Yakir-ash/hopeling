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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
        child: c == null
            ? const SizedBox(
                height: 200,
                child: Center(child: Text('...', style: TextStyle(color: tx2))))
            : Column(
                mainAxisSize: MainAxisSize.min,
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
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
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
                    if (picks.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                            'Today\'s door is the right one - nothing else fits better right now.',
                            style: TextStyle(
                                fontSize: 13.5, height: 1.5, color: tx2)),
                      ),
                    for (final p in picks) _row(p),
                    const SizedBox(height: 6),
                    TextButton(
                      onPressed: () => setState(() => browsing = true),
                      child: const Text('Browse every action →',
                          style: TextStyle(fontSize: 13, color: fern)),
                    ),
                  ],
                ],
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
