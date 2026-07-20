// Missions - "there is meaningful work happening near me, and I can
// take part." A curated shelf (never a feed), safety before Start,
// data-use before Submit, private participation always honored.

import 'package:flutter/material.dart';

import '../../core/clock.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/api.dart';
import '../../data/content.dart';
import '../../data/guardian.dart';
import '../../data/missions.dart';
import '../../data/save.dart';

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({super.key});

  @override
  State<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends State<MissionsScreen> {
  List<Mission> missions = [];
  Map<String, Participation> parts = {};
  String? guardianWorlds;
  List<String> gCats = [];
  int pendingObs = 0;

  @override
  void initState() {
    super.initState();
    missionTick.addListener(_reload);
    contentTick.addListener(_freshen);
    _reload();
  }

  @override
  void dispose() {
    missionTick.removeListener(_reload);
    contentTick.removeListener(_freshen);
    super.dispose();
  }

  void _freshen() {
    invalidateMissionCache();
    _reload();
  }

  Future<void> _reload() async {
    await loadContent(); // ensures the cache the missions parse from
    final m = await loadMissions();
    final p = await MissionStore.all();
    final s = await Store.load();
    final q = await ObsQueue.all();
    final gid = Guardianship.activeId(s);
    final c = await loadContent();
    if (!mounted) return;
    setState(() {
      missions = m;
      parts = p;
      gCats = gid == null
          ? []
          : (c.guardianById(gid)?.cats ?? []);
      pendingObs = q.length;
    });
  }

  List<Mission> _fit(bool Function(Mission) test) => [
        for (final m in missions)
          if (missionFit(m, DateTime.now()) == MissionFit.eligible &&
              test(m))
            m
      ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final seasonal = _fit((m) => m.months.isNotEmpty);
    final guardian = _fit(
        (m) => gCats.isNotEmpty && m.cats.any(gCats.contains));
    final home = _fit((m) => m.type == 'home' || m.type == 'observe');
    final science = _fit((m) => m.type == 'science');
    final asleep = [
      for (final m in missions)
        if (missionFit(m, now) == MissionFit.outOfSeason) m
    ];
    final done = [
      for (final m in missions)
        if ((parts[m.id]?.state ?? '').startsWith('completed')) m
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        title: Text('🧭 Missions', style: serif(19)),
      ),
      body: SafeArea(
        child: missions.isEmpty
            ? const LoadingSeed(line: 'Reading the field notes...')
            : ListView(
                padding: EdgeInsets.fromLTRB(24, 4, 24,
                    32 + MediaQuery.of(context).padding.bottom),
                children: [
                  const Text(MissionCopy.intro,
                      style: TextStyle(
                          fontSize: 13.5, height: 1.6, color: tx2)),
                  const SizedBox(height: 6),
                  const OfflineLeaf(line: MissionCopy.noLocation),
                  if (pendingObs > 0) ...[
                    const SizedBox(height: 10),
                    Text(
                        '🍃 $pendingObs ${pendingObs == 1 ? 'observation rests' : 'observations rest'} on a leaf, joining when the cloud is in reach.',
                        style: const TextStyle(
                            fontSize: 12.5, color: tx2)),
                  ],
                  _section('THIS SEASON', seasonal),
                  if (guardian.isNotEmpty)
                    _section("FROM YOUR GUARDIAN'S WORLD", guardian),
                  _section('TRY FROM HOME', home),
                  _section('CITIZEN SCIENCE', science),
                  if (done.isNotEmpty) _section('YOUR FIELD RECORD', done),
                  if (asleep.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text('SLEEPING UNTIL THEIR SEASON', style: kicker(tx2)),
                    const SizedBox(height: 8),
                    for (final m in asleep)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('· ${m.t}',
                            style: const TextStyle(
                                fontSize: 13, color: tx2)),
                      ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _section(String title, List<Mission> items) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Text(title, style: kicker()),
        const SizedBox(height: 10),
        for (final m in items) _card(m),
      ],
    );
  }

  Widget _card(Mission m) {
    final part = parts[m.id] ?? Participation();
    final state = part.state;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Corners.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(Corners.card),
          onTap: () {
            Haptics.tick();
            Navigator.of(context)
                .push(risePush(MissionDetail(mission: m)))
                .then((_) => _reload());
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.t, style: serif(16, height: 1.3)),
                const SizedBox(height: 6),
                Text(m.sum,
                    style: const TextStyle(
                        fontSize: 13, height: 1.5, color: tx2)),
                const SizedBox(height: 8),
                Text(
                    '~${m.min} min'
                    '${m.family ? ' · family friendly' : ''}'
                    '${m.supervision != 'none' ? ' · 🤝 with company' : ''}'
                    '${state == 'completedPrivate' ? ' · ✅ done, privately' : state == 'completedSubmitted' ? ' · ✅ done, submitted' : state == 'started' || state == 'drafted' ? ' · in progress' : ''}',
                    style: const TextStyle(fontSize: 11.5, color: tx2)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MissionDetail extends StatefulWidget {
  final Mission mission;
  const MissionDetail({super.key, required this.mission});

  @override
  State<MissionDetail> createState() => _MissionDetailState();
}

class _MissionDetailState extends State<MissionDetail> {
  Participation part = Participation();
  final Map<String, dynamic> answers = {};
  final noteC = TextEditingController();

  Mission get m => widget.mission;

  @override
  void initState() {
    super.initState();
    MissionStore.of(m.id).then((p) {
      if (mounted) {
        setState(() {
          part = p;
          answers.addAll(p.draft);
        });
      }
    });
  }

  @override
  void dispose() {
    noteC.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    part
      ..state = 'started'
      ..startedDay = todayStr();
    await MissionStore.put(m.id, part);
    Haptics.settle();
    setState(() {});
  }

  Future<void> _saveDraft() async {
    part
      ..state = 'drafted'
      ..draft = Map<String, dynamic>.from(answers);
    await MissionStore.put(m.id, part);
  }

  Map<String, dynamic> get _protocolPayload => {
        for (final f in m.protocol)
          if (f.kind != 'note' && answers[f.k] != null) f.k: answers[f.k]
      };

  Future<void> _finishPrivately() async {
    await _saveDraft();
    await completeMission(m.id, part, submitted: false);
    Haptics.yourDrop();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(MissionCopy.privateSaved)));
      setState(() {});
    }
  }

  Future<void> _preview() async {
    final payload = _protocolPayload;
    final go = await showModalBottomSheet<bool>(
      context: context,
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
              Text(MissionCopy.previewTitle, style: serif(19)),
              const SizedBox(height: 8),
              const Text(MissionCopy.previewNote,
                  style: TextStyle(
                      fontSize: 12.5, height: 1.55, color: tx2)),
              const SizedBox(height: 12),
              for (final f in m.protocol)
                if (f.kind != 'note')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                        '· ${f.label}: ${answers[f.k] ?? '(empty)'}',
                        style: const TextStyle(
                            fontSize: 13.5, color: ink)),
                  ),
              if (m.dataUse.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(m.dataUse,
                    style: const TextStyle(
                        fontSize: 11.5, height: 1.55, color: tx2)),
              ],
              const SizedBox(height: 16),
              Row(children: [
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: fern, foregroundColor: paper),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Submit'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Keep it private',
                      style: TextStyle(color: tx2)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
    if (go == true) {
      await _saveDraft();
      await ObsQueue.enqueue(m.id, payload);
      await completeMission(m.id, part, submitted: true);
      Haptics.yourDrop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(Api.signedIn
                ? MissionCopy.submitted
                : MissionCopy.guest)));
        setState(() {});
      }
    } else if (go == false) {
      await _finishPrivately();
    }
  }

  @override
  Widget build(BuildContext context) {
    final started = part.state == 'started' ||
        part.state == 'drafted' ||
        part.state.startsWith('completed');
    final completed = part.state.startsWith('completed');
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: ink,
          title: Text(m.t, style: serif(17))),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(
              24, 4, 24, 40 + MediaQuery.of(context).padding.bottom),
          children: [
            Text(m.sum,
                style: serif(16,
                    style: FontStyle.italic,
                    weight: FontWeight.w500,
                    height: 1.5,
                    color: tx2)),
            const SizedBox(height: 14),
            // Safety first, before Start, never a footnote.
            if (m.safety.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3DD),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('BEFORE YOU START', style: kicker()),
                    const SizedBox(height: 6),
                    for (final s in m.safety)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('· $s',
                            style: const TextStyle(
                                fontSize: 13, height: 1.5, color: ink)),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text('WHY THIS MATTERS', style: kicker()),
            const SizedBox(height: 6),
            Text(m.desc,
                style: const TextStyle(
                    fontSize: 14, height: 1.65, color: ink)),
            const SizedBox(height: 16),
            Text('HOW TO', style: kicker()),
            const SizedBox(height: 6),
            for (var i = 0; i < m.steps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text('${i + 1}.  ${m.steps[i]}',
                    style: const TextStyle(
                        fontSize: 14, height: 1.55, color: ink)),
              ),
            const SizedBox(height: 10),
            Text(freshnessLine(m, DateTime.now()),
                style: const TextStyle(fontSize: 11, color: tx2)),
            const SizedBox(height: 4),
            Text('SOURCES', style: kicker(tx2)),
            for (final s in m.sources)
              Text('· $s',
                  style: const TextStyle(
                      fontSize: 11.5, height: 1.6, color: tx2)),
            const SizedBox(height: 20),
            if (!started)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: fern,
                      foregroundColor: paper,
                      padding:
                          const EdgeInsets.symmetric(vertical: 15)),
                  onPressed: _start,
                  child: const Text('Start the mission',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            if (started && !completed && m.protocol.isNotEmpty) ...[
              Text('YOUR OBSERVATION', style: kicker()),
              const SizedBox(height: 10),
              for (final f in m.protocol) _field(f),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: fern, foregroundColor: paper),
                    onPressed: _preview,
                    child: const Text('Review & finish'),
                  ),
                ),
              ]),
              TextButton(
                onPressed: _finishPrivately,
                child: const Text('Finish privately, submit nothing',
                    style: TextStyle(fontSize: 12.5, color: tx2)),
              ),
            ],
            if (started && !completed && m.protocol.isEmpty)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: fern, foregroundColor: paper),
                  onPressed: _finishPrivately,
                  child: const Text('I did it'),
                ),
              ),
            if (completed)
              Center(
                child: Text(
                    part.state == 'completedSubmitted'
                        ? '✅ Done - your observation was shared.'
                        : '✅ Done - kept privately, as you chose.',
                    style: serif(15,
                        weight: FontWeight.w500, color: fern)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _field(ProtocolField f) {
    if (f.kind == 'count') {
      final v = (answers[f.k] is int) ? answers[f.k] as int : 0;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(children: [
          Expanded(
              child: Text(f.label,
                  style: const TextStyle(fontSize: 14, color: ink))),
          IconButton(
              onPressed: v <= 0
                  ? null
                  : () {
                      setState(() => answers[f.k] = v - 1);
                      _saveDraft();
                    },
              icon: const Icon(Icons.remove_circle_outline, color: tx2)),
          Text('$v',
              style: serif(18, weight: FontWeight.w700)),
          IconButton(
              onPressed: () {
                Haptics.tick();
                setState(() => answers[f.k] = v + 1);
                _saveDraft();
              },
              icon: const Icon(Icons.add_circle_outline, color: fern)),
        ]),
      );
    }
    if (f.kind == 'choice') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(f.label,
                style: const TextStyle(fontSize: 14, color: ink)),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final o in f.opts)
                ChoiceChip(
                  label:
                      Text(o, style: const TextStyle(fontSize: 12.5)),
                  selected: answers[f.k] == o,
                  selectedColor: mint,
                  onSelected: (_) {
                    setState(() => answers[f.k] = o);
                    _saveDraft();
                  },
                ),
            ]),
          ],
        ),
      );
    }
    // note: private by design, never part of the protocol payload
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: noteC,
        maxLines: 2,
        onChanged: (t) {
          answers[f.k] = t;
          _saveDraft();
        },
        decoration: InputDecoration(
          labelText: '${f.label} (private)',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
        ),
        style: const TextStyle(fontSize: 13.5),
      ),
    );
  }
}
