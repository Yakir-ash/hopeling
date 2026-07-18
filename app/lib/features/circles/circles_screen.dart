// Circles - "we are doing this together." A list of small trusted
// groves, a creation and joining flow, and the Shared Grove itself:
// collective presence without a leaderboard.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/clock.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/api.dart';
import '../../data/circles.dart';

class CirclesScreen extends StatefulWidget {
  final String? joinCode; // arriving via hopeling://circle/invite/{code}
  const CirclesScreen({super.key, this.joinCode});

  @override
  State<CirclesScreen> createState() => _CirclesScreenState();
}

class _CirclesScreenState extends State<CirclesScreen> {
  List<Circle> circles = [];
  List<Circle> archived = [];
  bool anon = false;
  final nameC = TextEditingController();
  final codeC = TextEditingController();
  final dnameC = TextEditingController();
  String type = 'family';
  String note = '';
  bool working = false;

  @override
  void initState() {
    super.initState();
    circlesTick.addListener(_reload);
    _reload();
    if (widget.joinCode != null) codeC.text = widget.joinCode!;
  }

  @override
  void dispose() {
    circlesTick.removeListener(_reload);
    nameC.dispose();
    codeC.dispose();
    dnameC.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final c = await Circles.mine();
    final a = await Circles.mine(archived: true);
    final an = await Circles.anonymous();
    final dn = await Circles.displayName();
    if (!mounted) return;
    setState(() {
      circles = c;
      archived = a;
      anon = an;
      if (dnameC.text.isEmpty) dnameC.text = dn;
    });
  }

  Future<bool> _ensureName() async {
    if (anon) return true;
    final n = dnameC.text.trim();
    if (n.isEmpty) {
      setState(() => note = 'A name for your circle to know you by?');
      return false;
    }
    await Circles.setDisplayName(n);
    return true;
  }

  Future<void> _create() async {
    if (nameC.text.trim().isEmpty || !await _ensureName()) return;
    setState(() {
      working = true;
      note = '';
    });
    final (c, err) = await Circles.create(nameC.text, type);
    if (!mounted) return;
    setState(() {
      working = false;
      note = err ?? '';
    });
    if (c != null) {
      Haptics.bloom(); // a circle forming is sacred
      nameC.clear();
      _openGrove(c);
    }
  }

  Future<void> _join() async {
    if (codeC.text.trim().isEmpty || !await _ensureName()) return;
    setState(() {
      working = true;
      note = '';
    });
    final (c, err) = await Circles.join(codeC.text);
    if (!mounted) return;
    setState(() {
      working = false;
      note = err ?? '';
    });
    if (c != null) {
      Haptics.bloom();
      codeC.clear();
      _openGrove(c);
    }
  }

  void _openGrove(Circle c) {
    Navigator.of(context)
        .push(risePush(SharedGroveScreen(circle: c)))
        .then((_) => _reload());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        title: Text('Circles', style: serif(19)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 40),
          children: [
            const Text(
              'Small trusted groves - family, friends, a classroom. '
              'Drops fall together. No feed, no ranking, no pressure.',
              style: TextStyle(fontSize: 13.5, height: 1.6, color: tx2),
            ),
            const SizedBox(height: 16),
            if (note.isNotEmpty) ...[
              Text(note,
                  style: const TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: fern)),
              const SizedBox(height: 12),
            ],
            for (final c in circles) _circleCard(c),
            if (working)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: LoadingSeed(line: 'Tending the grove...'),
              ),
            const SizedBox(height: 8),
            _panel(
              '🌱 Plant a new circle',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                      controller: nameC,
                      decoration: _field('circle name (e.g. Our Family)')),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: [
                    for (final t in const [
                      ['family', '🏡 Family'],
                      ['friends', '🫂 Friends'],
                      ['event', '🎪 Event'],
                    ])
                      ChoiceChip(
                        label: Text(t[1],
                            style: const TextStyle(fontSize: 12.5)),
                        selected: type == t[0],
                        selectedColor: mint,
                        onSelected: (_) => setState(() => type = t[0]),
                      ),
                  ]),
                  const SizedBox(height: 8),
                  _primary('Create · invite only', _create),
                ],
              ),
            ),
            _panel(
              '🔑 Join with a code',
              Column(
                children: [
                  TextField(
                      controller: codeC,
                      textCapitalization: TextCapitalization.characters,
                      decoration: _field('six-letter invite code')),
                  const SizedBox(height: 8),
                  _primary('Join the grove', _join),
                ],
              ),
            ),
            _panel(
              '🕊 How you appear',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                      controller: dnameC,
                      enabled: !anon,
                      decoration: _field('your name in circles')),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                            'Quiet mode: contribute drops without your name',
                            style:
                                TextStyle(fontSize: 12.5, color: tx2)),
                      ),
                      Switch(
                        value: anon,
                        activeThumbColor: fern,
                        onChanged: (v) async {
                          await Circles.setAnonymous(v);
                          setState(() => anon = v);
                          Circles.syncMine();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (archived.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('RESTING CIRCLES', style: kicker(tx2)),
              const SizedBox(height: 8),
              for (final c in archived)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(c.name,
                      style: const TextStyle(fontSize: 14, color: tx2)),
                  subtitle: const Text('archived · readable anytime',
                      style: TextStyle(fontSize: 11.5, color: tx2)),
                  trailing: TextButton(
                    onPressed: () async {
                      await Circles.restore(c);
                    },
                    child: const Text('Wake',
                        style: TextStyle(color: fern, fontSize: 13)),
                  ),
                  onTap: () => _openGrove(c),
                ),
            ],
            if (!Api.signedIn)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(CircleCopy.needAccount,
                    style: TextStyle(
                        fontSize: 12.5, height: 1.5, color: tx2)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _circleCard(Circle c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              mint.withValues(alpha: 0.35),
              Colors.white
            ]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Haptics.tick();
              _openGrove(c);
            },
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Text(
                      c.type == 'friends'
                          ? '🫂'
                          : c.type == 'event'
                              ? '🎪'
                              : '🏡',
                      style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name, style: serif(16)),
                        Text('code ${c.code}',
                            style: const TextStyle(
                                fontSize: 11.5, color: tx2)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: tx2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _field(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
      );

  Widget _primary(String label, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: fern,
              foregroundColor: paper,
              padding: const EdgeInsets.symmetric(vertical: 13)),
          onPressed: working ? null : onTap,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700)),
        ),
      );

  Widget _panel(String title, Widget child) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Corners.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: serif(15)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      );
}

// ---------- the Shared Grove ----------
class SharedGroveScreen extends StatefulWidget {
  final Circle circle;
  const SharedGroveScreen({super.key, required this.circle});

  @override
  State<SharedGroveScreen> createState() => _SharedGroveScreenState();
}

class _SharedGroveScreenState extends State<SharedGroveScreen> {
  List<Member> members = [];
  bool loaded = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    await Circles.syncMine();
    final m = await Circles.members(widget.circle.id);
    if (mounted) {
      setState(() {
        members = m;
        loaded = true;
      });
    }
  }

  Future<void> _share() async {
    final text =
        CircleCopy.invite(widget.circle.name, widget.circle.code);
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Invitation copied - send it to someone trusted.')));
    }
  }

  Future<void> _leave() async {
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
              Text(CircleCopy.leaveTitle, style: serif(20)),
              const SizedBox(height: 8),
              const Text(CircleCopy.leaveBody,
                  style:
                      TextStyle(fontSize: 14, height: 1.6, color: tx2)),
              const SizedBox(height: 16),
              Row(children: [
                OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child:
                        const Text('Leave', style: TextStyle(color: ink))),
                TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child:
                        const Text('Stay', style: TextStyle(color: fern))),
              ]),
            ],
          ),
        ),
      ),
    );
    if (sure != true) return;
    if (await Circles.leave(widget.circle) && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text(CircleCopy.left)));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wk = weekKey();
    final total = weekTotal(members, wk);
    final people = weekParticipants(members, wk);
    final stage = total == 0
        ? 0
        : total < 5
            ? 1
            : total < 15
                ? 2
                : total < 40
                    ? 3
                    : 4;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        title: Text(widget.circle.name, style: serif(19)),
        actions: [
          IconButton(
              tooltip: 'Invite someone trusted',
              onPressed: _share,
              icon: const Icon(Icons.ios_share, color: tx2)),
        ],
      ),
      body: SafeArea(
        child: !loaded
            ? const LoadingSeed(line: 'Walking to the shared grove...')
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 6, 24, 40),
                children: [
                  Center(
                    child: Semantics(
                      label:
                          'Your circle added $total verified actions this week. $people members participated.',
                      child: Column(
                        children: [
                          Text(['🌰', '🌱', '🌿', '🌳', '🌲'][stage],
                              style: const TextStyle(fontSize: 64)),
                          const SizedBox(height: 8),
                          Text(groveSummary(members, wk),
                              textAlign: TextAlign.center,
                              style: serif(17,
                                  weight: FontWeight.w500, height: 1.4)),
                          const SizedBox(height: 4),
                          const Text('grown by everyone, ranked by no one',
                              style:
                                  TextStyle(fontSize: 11.5, color: tx2)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text('PRESENT IN THE GROVE', style: kicker()),
                  const SizedBox(height: 10),
                  // Join order, never score order. Equal drops, equal light.
                  for (final m in members)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                                m.userId == Api.session?.uid
                                    ? '${m.name} (you)'
                                    : m.name,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: ink)),
                          ),
                          if (m.week == wk && m.weekActions > 0)
                            Text('💧 ${m.weekActions}',
                                style: const TextStyle(
                                    fontSize: 12.5, color: tx2)),
                          if (m.userId != Api.session?.uid)
                            IconButton(
                              tooltip: 'Send warmth',
                              onPressed: () {
                                Haptics.settle();
                                Circles.cheer(
                                    widget.circle.id, m.userId);
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(const SnackBar(
                                        content: Text(
                                            '💚 Warmth sent, quietly.')));
                              },
                              icon: const Text('💚',
                                  style: TextStyle(fontSize: 16)),
                            ),
                        ],
                      ),
                    ),
                  if (members.length < 2) ...[
                    const SizedBox(height: 8),
                    Text(
                        'A grove grows warmer with company. Share the code '
                        '${widget.circle.code} with someone trusted.',
                        style: const TextStyle(
                            fontSize: 13, height: 1.5, color: tx2)),
                  ],
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () async {
                      await Circles.archive(widget.circle);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(CircleCopy.archived)));
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Archive this circle',
                        style: TextStyle(fontSize: 13, color: tx2)),
                  ),
                  TextButton(
                    onPressed: _leave,
                    child: const Text(CircleCopy.leaveTitle,
                        style: TextStyle(fontSize: 13, color: tx2)),
                  ),
                ],
              ),
      ),
    );
  }
}
