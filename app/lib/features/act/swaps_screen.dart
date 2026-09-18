// This-not-that - the everyday decision as a card (V2-AUDIT.md
// section 5). Adults only; it lives in Act.
//
// The eight-second surface: one thing to avoid, one thing to
// prefer, one pick, one neighbour, one tap. "Why?" is a door, never
// a paragraph on the card. Behind the door: every ingredient and
// how it hides on a label, the nearby alternative, the chain, the
// neighbour herself (the Atlas), the experiment where her thread
// runs (the Lab), the action this decision feeds, the sources, and
// the date a person last checked all of it.
//
// The decision is the act. "This one, from now on" takes the same
// path as every action: a drop, the rhythm, the rain. We never
// verify a purchase. We witness a decision.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/clock.dart';
import '../../core/haptics.dart';
import '../../core/sfx.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/actions.dart' as engine;
import '../../data/almanac.dart' show atlasById;
import '../../data/api.dart';
import '../../data/content.dart';
import '../../data/lab.dart';
import '../../data/pulse.dart';
import '../../data/rules.dart' as rules;
import '../../data/save.dart';
import '../../data/swaps.dart';
import '../atlas/atlas_screen.dart';
import '../grove/grove_screen.dart' show RainBurst;
import '../school/lab_screen.dart';
import 'act_sheet.dart' show showActionDetail;

/// The shelf inside Act: three cards, each a question.
class SwapShelf extends StatelessWidget {
  const SwapShelf({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SwapBook>(
      future: loadSwaps(),
      builder: (context, snap) {
        final book = snap.data;
        if (book == null) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('THIS, NOT THAT', style: kicker()),
            const SizedBox(height: 4),
            const Text(
              'ingredients first, one pick, and the neighbour it '
              'reaches - decided once, running for years',
              style: TextStyle(fontSize: 12, height: 1.45, color: tx2),
            ),
            const SizedBox(height: 10),
            for (final sw in book.swaps) _SwapTile(sw: sw),
          ],
        );
      },
    );
  }
}

class _SwapTile extends StatelessWidget {
  final Swap sw;
  const _SwapTile({required this.sw});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Semantics(
        button: true,
        label: '${sw.title}. ${sw.question}',
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              Haptics.tick();
              Sfx.play('tick', volume: 0.3);
              Navigator.of(context).push(risePush(SwapPage(sw: sw)));
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: ExcludeSemantics(
                child: Row(children: [
                  Text(sw.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sw.title,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: ink)),
                        const SizedBox(height: 2),
                        Text(sw.question,
                            style: const TextStyle(
                                fontSize: 12.5, height: 1.4, color: tx2)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: tx2, size: 20),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The card. Eight seconds on top; an afternoon behind "why?".
class SwapPage extends StatefulWidget {
  final Swap sw;
  const SwapPage({super.key, required this.sw});

  @override
  State<SwapPage> createState() => _SwapPageState();
}

class _SwapPageState extends State<SwapPage> {
  bool why = false;
  String? decidedOn;

  Swap get sw => widget.sw;

  @override
  void initState() {
    super.initState();
    Swaps.decided().then((m) {
      if (mounted) setState(() => decidedOn = m[sw.id]);
    });
  }

  Future<void> _decide() async {
    final today = todayStr();
    final s = await Store.load();
    final out = recordSwapDecision(s, sw, today);
    await Store.persist(s);
    await Swaps.markDecided(sw.id, today);
    Pulse.add();
    if (Api.signedIn) Api.pushSave(s.toJson());
    saveTick.value++;
    Haptics.yourDrop();
    Sfx.play('chime', volume: 0.4);
    if (!mounted) return;
    setState(() => decidedOn = today);
    if (!Motion.still(context)) RainBurst.show(context);
    final msg = out.ringAdded != null
        ? '🪵 ${rules.Lines.ringFormed(out.ringAdded!)}'
        : '🌧 ${Api.signedIn ? RainCopy.joined : RainCopy.guest}';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  /// The habit behind the decision: the same completion every
  /// action takes on the Act shelf.
  Future<void> _completeAction(ActionItem a) async {
    final s = await Store.load();
    final out = engine.recordCompletion(s, a, todayStr());
    await Store.persist(s);
    await engine.recordDoneLocally(a.slug);
    Pulse.add();
    if (Api.signedIn) Api.pushSave(s.toJson());
    saveTick.value++;
    Haptics.yourDrop();
    if (!mounted) return;
    if (!Motion.still(context)) RainBurst.show(context);
    final msg = out.ringAdded != null
        ? '🪵 ${rules.Lines.ringFormed(out.ringAdded!)}'
        : '🌧 ${Api.signedIn ? RainCopy.joined : RainCopy.guest}';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final species = atlasById(sw.consequence.species);
    final lab = labScenarioById(sw.consequence.lab);
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: ink,
          title: Text('${sw.emoji} ${sw.title}', style: serif(17))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
          children: [
            // ---------------- THE EIGHT SECONDS ----------------
            Text(sw.question, style: serif(22, height: 1.3)),
            const SizedBox(height: 16),
            _line('AVOID', sw.firstAvoid.ingredient,
                const Color(0xFFB05B5B)),
            const SizedBox(height: 10),
            _line('PREFER', sw.firstPrefer.trait, fern),
            const SizedBox(height: 10),
            _line('PICK', sw.pick.label, ink,
                sub: 'checked ${sw.reviewed}'),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: mint.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(species?.emoji ?? '🌿',
                      style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(sw.consequence.line,
                        style: const TextStyle(
                            fontSize: 13.5, height: 1.5, color: ink)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (decidedOn == null)
              Semantics(
                button: true,
                label: 'This one, from now on. Decide, and a drop '
                    'joins the rain.',
                child: Material(
                  color: fern,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _decide,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 17),
                      child: Center(
                        child: Text('This one, from now on',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: Text(
                    '✅ Decided on $decidedOn. It is still running '
                    'every time you shop - that is the whole point '
                    'of a swap.',
                    style: const TextStyle(
                        fontSize: 12.5, height: 1.5, color: ink)),
              ),
            const SizedBox(height: 10),
            Center(
              child: Semantics(
                button: true,
                expanded: why,
                label: why ? 'Close the why' : 'Why? Open the reasons.',
                child: TextButton(
                  onPressed: () {
                    Haptics.tick();
                    setState(() => why = !why);
                  },
                  child: Text(why ? 'enough for now' : 'why?',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: fern)),
                ),
              ),
            ),
            // ---------------- THE AFTERNOON ----------------
            if (why) ...[
              const SizedBox(height: 8),
              Text('What to avoid, and how it hides', style: serif(15)),
              const SizedBox(height: 8),
              for (final a in sw.avoid)
                _panel(
                    title: a.ingredient,
                    body: a.why,
                    foot: a.aka.isEmpty
                        ? null
                        : 'on a label: ${a.aka.join(", ")}'),
              const SizedBox(height: 12),
              Text('What to prefer', style: serif(15)),
              const SizedBox(height: 8),
              for (final p in sw.prefer) _panel(title: p.trait, body: p.why),
              const SizedBox(height: 12),
              Text('The pick, honestly', style: serif(15)),
              const SizedBox(height: 8),
              _panel(
                  title: sw.pick.label,
                  body: sw.pick.note,
                  foot: sw.pick.link == null
                      ? 'No brand is named here yet. When one is, it '
                          'will carry the date a person checked it, '
                          'and it will never move the pick: there is '
                          'no ranking to move.'
                      : 'a named product, checked ${sw.pick.linkChecked}'),
              if (sw.pick.link != null)
                TextButton(
                  onPressed: () {
                    Haptics.tick();
                    launchUrl(Uri.parse(sw.pick.link!),
                        mode: LaunchMode.externalApplication);
                  },
                  child: const Text('open the named product'),
                ),
              const SizedBox(height: 12),
              Text('If that is too much today', style: serif(15)),
              const SizedBox(height: 8),
              _panel(title: sw.nearby.label, body: sw.nearby.why),
              const SizedBox(height: 12),
              Text('The chain', style: serif(15)),
              const SizedBox(height: 6),
              Text(sw.consequence.chain.join('  →  '),
                  style: const TextStyle(
                      fontSize: 12.5, height: 1.6, color: tx2)),
              const SizedBox(height: 14),
              // the doors: the neighbour, the experiment, the habit
              if (species != null)
                _door(
                    '${species.emoji} Meet the ${species.name.toLowerCase()}',
                    'her page in the Neighbours',
                    () => Navigator.of(context)
                        .push(risePush(AtlasPage(species: species)))),
              if (lab != null)
                _door('🧪 Run the experiment', lab.question,
                    () => Navigator.of(context)
                        .push(risePush(LabPage(scenario: lab)))),
              for (final slug in sw.feeds)
                FutureBuilder<AppContent>(
                  future: loadContent(),
                  builder: (context, snap) {
                    final a = snap.data?.actions[slug];
                    if (a == null) return const SizedBox.shrink();
                    return _door(
                        '⚡ Make it a habit',
                        a.t,
                        () => showActionDetail(context, a,
                            onDone: () => _completeAction(a)));
                  },
                ),
              const SizedBox(height: 14),
              Text('Where this comes from', style: serif(15)),
              const SizedBox(height: 8),
              for (final src in sw.sources)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Semantics(
                    button: true,
                    label: 'Source: ${src.title}, ${src.org}. Opens '
                        'in the browser.',
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          Haptics.tick();
                          launchUrl(Uri.parse(src.url),
                              mode: LaunchMode.externalApplication);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: ExcludeSemantics(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(src.title,
                                    style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        height: 1.4,
                                        color: ink)),
                                const SizedBox(height: 2),
                                Text(src.org,
                                    style: const TextStyle(
                                        fontSize: 11, color: fern)),
                                const SizedBox(height: 4),
                                Text(src.what,
                                    style: const TextStyle(
                                        fontSize: 11.5,
                                        height: 1.5,
                                        color: tx2)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              Text(
                'Checked ${sw.reviewed} by ${sw.reviewer}. Things '
                'change; the date is the honesty. The same card, with '
                'its sources, is public at hopeling.app/swaps/${sw.id}/ '
                'so anyone can hold it to account.',
                style: const TextStyle(
                    fontSize: 10.5,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                    color: tx2),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _line(String kicker, String text, Color color, {String? sub}) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(kicker,
                  style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w800,
                      color: color)),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: serif(16, height: 1.3)),
                if (sub != null)
                  Text(sub,
                      style: const TextStyle(fontSize: 10.5, color: tx2)),
              ],
            ),
          ),
        ],
      );

  Widget _panel({required String title, required String body, String? foot}) =>
      Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700, color: ink)),
            const SizedBox(height: 4),
            Text(body,
                style: const TextStyle(fontSize: 12.5, height: 1.55, color: ink)),
            if (foot != null) ...[
              const SizedBox(height: 4),
              Text(foot,
                  style: const TextStyle(
                      fontSize: 10.5,
                      fontStyle: FontStyle.italic,
                      color: tx2)),
            ],
          ],
        ),
      );

  Widget _door(String title, String sub, VoidCallback onTap) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Semantics(
          button: true,
          label: '$title. $sub',
          child: Material(
            color: mint.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Haptics.tick();
                onTap();
              },
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: ExcludeSemantics(
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: ink)),
                          const SizedBox(height: 2),
                          Text(sub,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11.5, height: 1.4, color: tx2)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: tx2, size: 18),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}

/// A one-line door from a Lab experiment or a Neighbour's page to
/// the decision that reaches her. Silent when no card exists.
class SwapDoor extends StatelessWidget {
  final String? labId;
  final String? speciesId;
  const SwapDoor({super.key, this.labId, this.speciesId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SwapBook>(
      future: loadSwaps(),
      builder: (context, snap) {
        final book = snap.data;
        if (book == null) return const SizedBox.shrink();
        final sw = labId != null
            ? book.forLab(labId!)
            : (speciesId != null ? book.forSpecies(speciesId!) : null);
        if (sw == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Semantics(
            button: true,
            label: 'One decision that reaches her: ${sw.title}. '
                '${sw.question}',
            child: Material(
              color: const Color(0xFFF3EAD8),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Haptics.tick();
                  Sfx.play('tick', volume: 0.3);
                  Navigator.of(context).push(risePush(SwapPage(sw: sw)));
                },
                child: Padding(
                  padding: const EdgeInsets.all(13),
                  child: ExcludeSemantics(
                    child: Row(children: [
                      Text(sw.emoji, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                labId != null
                                    ? 'The repair in your kitchen'
                                    : 'One decision that reaches her',
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: ink)),
                            const SizedBox(height: 2),
                            Text('${sw.title}: ${sw.question}',
                                style: const TextStyle(
                                    fontSize: 11.5,
                                    height: 1.4,
                                    color: tx2)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: tx2, size: 18),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
