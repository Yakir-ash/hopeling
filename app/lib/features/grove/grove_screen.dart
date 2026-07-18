// The Grove - home. The living sky, the swaying tree, today's fact and
// action, and the Thumb Promise: in Hopeling, promises are held, not tapped.

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/clock.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../core/notify.dart';
import '../../data/actions.dart' as engine;
import '../../data/api.dart';
import '../../data/content.dart';
import '../../data/guardian.dart';
import '../../data/pulse.dart';
import '../../data/rules.dart' as rules;
import '../../data/save.dart';
import '../act/act_sheet.dart';
import '../account/account_screen.dart';
import '../circles/circles_screen.dart';
import '../kids/kids_screen.dart';
import '../robin/robin_screen.dart';
import 'tree.dart';

class GroveScreen extends StatefulWidget {
  const GroveScreen({super.key});

  @override
  State<GroveScreen> createState() => _GroveScreenState();
}

class _GroveScreenState extends State<GroveScreen> {
  Save save = Save();
  engine.DayContent? day;
  bool booted = false;
  final TreePulse pulse = TreePulse();

  @override
  void initState() {
    super.initState();
    _boot();
    contentTick.addListener(_freshDay);
    saveTick.addListener(_boot);
  }

  @override
  void dispose() {
    contentTick.removeListener(_freshDay);
    saveTick.removeListener(_boot);
    super.dispose();
  }

  void _freshDay() {
    engine.loadToday().then((c) {
      if (mounted) setState(() => day = c);
    });
  }

  bool fog = false;
  String fogLine = '';
  bool robinOffer = false;
  String? gEmo; // the guardian's quiet mark at the roots

  Future<void> _boot() async {
    final s = await Store.load();
    if (mounted) setState(() { save = s; booted = true; });
    _freshDay();
    _reconcile(s);
    // The contextual invitation: only after value has been felt (3 drops),
    // only once, never on first launch.
    final rp = await RobinPrefs.load();
    final gp = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        robinOffer =
            !rp.offered && !rp.enabled && !rp.denied && s.xp >= 3;
        gEmo = Guardianship.activeId(s) != null
            ? gp.getString('guardianEmo')
            : null;
      });
    }
    // The Welcome-Back Fog: once per day, only for 5-13 missed days.
    final r = rules.assess(s, todayStr());
    if (r.category == rules.ReturnCategory.fog) {
      final p = await SharedPreferences.getInstance();
      if (p.getString('fogDay') != todayStr()) {
        await p.setString('fogDay', todayStr());
        if (mounted) {
          setState(() {
            fog = true;
            fogLine = rules.Lines.returned(r);
          });
        }
      }
    }
  }

  /// Quiet multi-device reconciliation: if signed in, merge the cloud copy
  /// in the background. Never blocks, never shows a spinner, never loses.
  Future<void> _reconcile(Save local) async {
    if (!Api.signedIn) return;
    final (cloudDoc, _) = await Api.fetchSave();
    if (cloudDoc == null || !mounted) return;
    final merged = Save.merge(local, Save.fromJson(cloudDoc));
    if (merged.xp != local.xp ||
        merged.streak != local.streak ||
        merged.log.length != local.log.length) {
      await Store.persist(merged);
      if (mounted) setState(() => save = merged);
    }
  }

  String get greeting {
    final h = DateTime.now().hour;
    if (h >= 5 && h < 12) return 'Good morning 🌅';
    if (h >= 12 && h < 17) return 'Good afternoon ☀️';
    if (h >= 17 && h < 21) return 'Good evening 🌇';
    return 'Good night 🌙';
  }

  void _toast(String msg, {int seconds = 3}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), duration: Duration(seconds: seconds)));
  }

  void _onCommit() {
    // The engine decides; the UI renders. Persist FIRST - the ceremony is
    // decoration, the promise is data.
    final act = day?.act ?? engine.fallbackAction();
    late rules.CompleteOutcome out;
    setState(() => out = engine.recordCompletion(save, act, todayStr()));
    Store.persist(save);
    engine.recordDoneLocally(act.slug); // feeds the cooldown engine
    Pulse.add(); // one durable event, queued before any animation
    if (Api.signedIn) Api.pushSave(save.toJson()); // quiet auto-backup
    // A door to related learning, opened once, never pushed.
    if (out.firstOfDay) {
      loadContent().then((c) {
        final j = engine.relatedJourney(c, act.slug);
        if (j != null && mounted) {
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              _toast('📖 A chapter of "${j.t}" connects to what you just did.');
            }
          });
        }
      });
    }
    // The ceremony (under 1.5s): the tree breathes, a few drops fall.
    pulse.breathe();
    Haptics.yourDrop();
    if (!Motion.still(context)) RainBurst.show(context);
    // One voice at a time, most meaningful first. Never alarm, never red.
    if (out.ringAdded != null) {
      _toast('🪵 ${rules.Lines.ringFormed(out.ringAdded!)}');
    } else if (out.freezeUsed) {
      _toast('🍂 ${rules.Lines.freezeUsed}');
    } else if (out.newFriend != null) {
      Haptics.bloom(); // a friend arriving is sacred
      _toast('${rules.Lines.friendArrived(out.newFriend!)}', seconds: 4);
    } else if (out.freezeEarned) {
      _toast('🌿 ${rules.Lines.freezeEarned(save.freezes)}');
    } else {
      _toast('🌧 ${Api.signedIn ? RainCopy.joined : RainCopy.guest}',
          seconds: 2);
    }
  }

  void _onRepair() {
    // Persist before any animation completes (atomicity rule).
    setState(() => rules.repair(save, todayStr()));
    Store.persist(save);
    if (Api.signedIn) Api.pushSave(save.toJson());
    _toast('🌱 ${rules.Lines.repaired}');
  }

  /// The return experience: distinct, quiet, never punitive.
  List<Widget> _returnRegion() {
    final r = rules.assess(save, todayStr());
    final region = <Widget>[];
    if (r.category == rules.ReturnCategory.oneDay && r.repairAvailable) {
      region.add(RepairLeaf(onRepaired: _onRepair));
      region.add(const SizedBox(height: 20));
    } else if (r.category == rules.ReturnCategory.oneDay ||
        r.category == rules.ReturnCategory.short ||
        r.category == rules.ReturnCategory.long) {
      region.add(Center(
        child: Text(rules.Lines.returned(r),
            textAlign: TextAlign.center,
            style: serif(15,
                style: FontStyle.italic,
                weight: FontWeight.w500,
                color: tx2)),
      ));
      region.add(const SizedBox(height: 20));
    }
    return region;
  }

  @override
  Widget build(BuildContext context) {
    final d = day;
    final sky = skyColors(DateTime.now().hour);
    return Scaffold(
      body: Stack(children: [
        Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: const Alignment(0, -0.2),
            colors: sky,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 40),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(greeting, style: serif(26)),
                        const SizedBox(height: 4),
                        Text(todayStr(),
                            style: const TextStyle(
                                fontSize: 12, letterSpacing: 2, color: tx2)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Little Helpers - kids mode',
                    onPressed: () => Navigator.of(context)
                        .push(risePush(const KidsParentScreen())),
                    icon: const Text('🧒', style: TextStyle(fontSize: 19)),
                  ),
                  IconButton(
                    tooltip: 'Circles - together',
                    onPressed: () => Navigator.of(context)
                        .push(risePush(const CirclesScreen())),
                    icon: const Text('👥', style: TextStyle(fontSize: 19)),
                  ),
                  IconButton(
                    tooltip: 'The Robin - reminders',
                    onPressed: () => Navigator.of(context)
                        .push(risePush(const RobinScreen())),
                    icon: const Text('🐦', style: TextStyle(fontSize: 20)),
                  ),
                  IconButton(
                    tooltip: 'Your grove, everywhere',
                    onPressed: () => Navigator.of(context)
                        .push(risePush(const AccountScreen())),
                    icon: Icon(
                        Api.signedIn
                            ? Icons.cloud_done_outlined
                            : Icons.cloud_outlined,
                        color: tx2,
                        size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              ..._returnRegion(),
              Center(
                child: Column(
                  children: [
                    Semantics(
                      label: rules.Lines.rhythm(save, todayStr()),
                      child: Builder(builder: (context) {
                        final idx = rules.stageIdx(save.streak);
                        final st = rules.painterStage(idx);
                        final friends =
                            rules.friendsFor(rules.groveBest(save));
                        // The canvas grows with the tree: a seed does not
                        // need a grove's worth of sky above it.
                        final ts = [96.0, 122.0, 148.0, 170.0, 180.0][st];
                        return SizedBox(
                          width: ts,
                          height: ts,
                          child: Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              TreeView(
                                stage: st,
                                still: Motion.still(context),
                                pulse: pulse,
                                size: ts,
                              ),
                              // Friends perch on the canopy - earned at
                              // best-ever milestones, staying forever.
                              if (friends.isNotEmpty && st >= 2)
                                Positioned(
                                  top: ts * 0.10,
                                  child: Text(
                                      friends.take(4).join('  '),
                                      style:
                                          const TextStyle(fontSize: 15)),
                                ),
                              // The guardian keeps quiet company at the
                              // roots. It never wilts, never leaves.
                              if (gEmo != null)
                                Positioned(
                                  bottom: ts * 0.04,
                                  right: ts * 0.08,
                                  child: Semantics(
                                    label:
                                        'Your guardian species keeps company at the roots',
                                    child: Text(gEmo!,
                                        style: const TextStyle(
                                            fontSize: 15)),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(rules.stageLabel(rules.stageIdx(save.streak)),
                        style: serif(17, weight: FontWeight.w500)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(99),
                        boxShadow: [
                          BoxShadow(
                              color: ink.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Text(
                          '🔥 ${save.streak} day streak · best ${rules.groveBest(save)} · ${save.xp} drops',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: ink)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 34),
              Text("TODAY'S FACT", style: kicker()),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [fern, deep]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    d == null
                        ? Text('Listening to the world...',
                            style: serif(20,
                                color: Colors.white,
                                style: FontStyle.italic,
                                weight: FontWeight.w500,
                                height: 1.5))
                        : SimplyText(
                            text: d.factText,
                            simpleText: d.factSimple,
                            linkColor: mint,
                            style: serif(20,
                                color: Colors.white,
                                style: FontStyle.italic,
                                weight: FontWeight.w500,
                                height: 1.5),
                          ),
                    const SizedBox(height: 12),
                    Text(
                      d == null ? '' : '- ${d.factSrc.toUpperCase()}',
                      style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.5,
                          color: Colors.white.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text("TODAY'S ACTION", style: kicker()),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: ink.withValues(alpha: 0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: d == null
                          ? null
                          : () {
                              Haptics.tick();
                              showActionDetail(context, d.act);
                            },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(d == null ? '...' : d.act.t,
                              style: serif(19, height: 1.35)),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsetsDirectional.only(
                                start: 12),
                            decoration: const BoxDecoration(
                              border: BorderDirectional(
                                  start:
                                      BorderSide(color: mint, width: 3)),
                            ),
                            child: Text(d == null ? '' : d.act.why,
                                style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 14,
                                    height: 1.55,
                                    color: tx2)),
                          ),
                          if (d != null && d.act.steps.isNotEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text('tap for steps and the science →',
                                  style: TextStyle(
                                      fontSize: 11.5, color: fern)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                        d == null
                            ? ''
                            : '~${d.act.min} minutes${d.fromCache ? '   ·   offline' : ''}',
                        style: const TextStyle(fontSize: 12, color: tx2)),
                    if (d != null) ...[
                      const SizedBox(height: 4),
                      Text(d.reason,
                          style: const TextStyle(
                              fontSize: 11.5,
                              fontStyle: FontStyle.italic,
                              color: fern)),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton(
                          onPressed: () async {
                            final chosen = await showAlternates(context);
                            if (chosen != null) _freshDay();
                          },
                          child: const Text('Something else today?',
                              style:
                                  TextStyle(fontSize: 12, color: tx2)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    HoldToCommit(
                      done: save.doneOn(todayStr()),
                      onCommit: _onCommit,
                    ),
                  ],
                ),
              ),
              if (robinOffer) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🐦 A quiet tap at the window?',
                          style: serif(16)),
                      const SizedBox(height: 6),
                      const Text(
                          'One reminder a day, at a time you choose. No guilt, ever.',
                          style: TextStyle(
                              fontSize: 13, height: 1.5, color: tx2)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          FilledButton(
                            style: FilledButton.styleFrom(
                                backgroundColor: fern,
                                foregroundColor: paper),
                            onPressed: () async {
                              final rp = await RobinPrefs.load();
                              rp.offered = true;
                              await rp.save();
                              if (!context.mounted) return;
                              setState(() => robinOffer = false);
                              Navigator.of(context)
                                  .push(risePush(const RobinScreen()));
                            },
                            child: const Text('Choose a time'),
                          ),
                          TextButton(
                            onPressed: () async {
                              final rp = await RobinPrefs.load();
                              rp.offered = true;
                              await rp.save();
                              if (mounted) {
                                setState(() => robinOffer = false);
                              }
                            },
                            child: const Text('Not now',
                                style: TextStyle(color: tx2)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 40),
              const Center(
                child: Text('small actions, real hope',
                    style:
                        TextStyle(fontSize: 12, letterSpacing: 3, color: tx2)),
              ),
            ],
          ),
        ),
        ),
        if (fog)
          _FogLayer(
              line: fogLine,
              still: Motion.still(context),
              onDone: () => setState(() => fog = false)),
      ]),
    );
  }
}

// ---------- the welcome-back fog ----------
// Five to thirteen days away: the grove appears through morning fog that
// clears in about three seconds. No modal, no dismissal, no numbers first.
class _FogLayer extends StatefulWidget {
  final String line;
  final bool still;
  final VoidCallback onDone;
  const _FogLayer(
      {required this.line, required this.still, required this.onDone});

  @override
  State<_FogLayer> createState() => _FogLayerState();
}

class _FogLayerState extends State<_FogLayer> {
  double opacity = 1;

  @override
  void initState() {
    super.initState();
    if (widget.still) {
      // Reduced motion: a brief still veil, then gone.
      Future.delayed(const Duration(milliseconds: 1800), widget.onDone);
    } else {
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) setState(() => opacity = 0);
      });
      Future.delayed(const Duration(milliseconds: 3400), widget.onDone);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: opacity,
        duration:
            widget.still ? Duration.zero : const Duration(milliseconds: 2000),
        child: Container(
          color: paper.withValues(alpha: 0.96),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🌫', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 16),
              Text(widget.line,
                  textAlign: TextAlign.center,
                  style: serif(20, weight: FontWeight.w500, height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------- the repair leaf ----------
// Yesterday fell. Slide the leaf back to the branch - or use the button.
// Persisted the instant it lands; the animation follows the data.
class RepairLeaf extends StatefulWidget {
  final VoidCallback onRepaired;
  const RepairLeaf({super.key, required this.onRepaired});

  @override
  State<RepairLeaf> createState() => _RepairLeafState();
}

class _RepairLeafState extends State<RepairLeaf> {
  double t = 0; // 0 fallen .. 1 mended
  bool done = false;
  final Set<int> _ticked = {};

  void _finish() {
    if (done) return;
    setState(() {
      done = true;
      t = 1;
    });
    Haptics.settle();
    widget.onRepaired();
  }

  @override
  Widget build(BuildContext context) {
    if (Motion.reduced(context)) {
      // Accessible and reduced-motion path: one clear button.
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(rules.Lines.repairOffer,
                style: serif(15, weight: FontWeight.w500)),
            const SizedBox(height: 10),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: fern, foregroundColor: paper),
              onPressed: done ? null : _finish,
              child: Text(done ? 'Yesterday is mended 🌱' : 'Repair yesterday'),
            ),
          ],
        ),
      );
    }
    return Semantics(
      label: 'Repair yesterday',
      button: true,
      onTap: _finish,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: ink.withValues(alpha: 0.07),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(done ? rules.Lines.repaired : rules.Lines.repairOffer,
                style: serif(15, weight: FontWeight.w500)),
            const SizedBox(height: 12),
            LayoutBuilder(builder: (context, box) {
              final w = box.maxWidth;
              final leafX = t * (w - 44);
              return SizedBox(
                height: 44,
                child: Stack(
                  children: [
                    // the path back
                    Positioned(
                      top: 20,
                      left: 8,
                      right: 8,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          color: mint.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // the branch, waiting
                    const Positioned(
                      right: 0,
                      top: 8,
                      child: Text('🌿', style: TextStyle(fontSize: 24)),
                    ),
                    // the fallen leaf, draggable home
                    AnimatedPositioned(
                      duration: done
                          ? const Duration(milliseconds: 250)
                          : Duration.zero,
                      left: leafX,
                      top: 6,
                      child: GestureDetector(
                        onHorizontalDragUpdate: done
                            ? null
                            : (d) {
                                setState(() {
                                  t = (t + d.delta.dx / (w - 44))
                                      .clamp(0.0, 1.0);
                                });
                                for (final q in [1, 2, 3]) {
                                  if (t >= q / 4 && !_ticked.contains(q)) {
                                    _ticked.add(q);
                                    Haptics.tick();
                                  }
                                }
                                if (t >= 0.92) _finish();
                              },
                        onHorizontalDragEnd: done
                            ? null
                            : (_) {
                                if (t < 0.92) {
                                  setState(() => t = 0);
                                  _ticked.clear();
                                }
                              },
                        child: Text(done ? '🌱' : '🍂',
                            style: const TextStyle(fontSize: 30)),
                      ),
                    ),
                  ],
                ),
              );
            }),
            TextButton(
              onPressed: done ? null : _finish,
              child: const Text('Repair yesterday',
                  style: TextStyle(fontSize: 12.5, color: fern)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- the Thumb Promise ----------
// Press and hold. A gold ring draws itself around the button under your
// finger, with a haptic tick at each quarter. Release early and it undoes
// itself - no promise was made. Reduced motion: a plain, honest button.
class HoldToCommit extends StatefulWidget {
  final bool done;
  final VoidCallback onCommit;
  final String? label;
  final String? doneLabel;
  const HoldToCommit(
      {super.key,
      required this.done,
      required this.onCommit,
      this.label,
      this.doneLabel});

  @override
  State<HoldToCommit> createState() => _HoldToCommitState();
}

class _HoldToCommitState extends State<HoldToCommit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  final Set<int> _ticked = {};

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: Motion.hold);
    _c.addListener(_onTickCheck);
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        Haptics.commit();
        widget.onCommit();
        _ticked.clear();
        _c.animateBack(0, duration: const Duration(milliseconds: 400));
      }
    });
  }

  void _onTickCheck() {
    for (final q in [1, 2, 3]) {
      if (_c.value >= q / 4 && !_ticked.contains(q)) {
        _ticked.add(q);
        Haptics.tick();
      }
    }
    setState(() {});
  }

  void _cancel() {
    if (_c.status == AnimationStatus.forward) {
      _ticked.clear();
      _c.animateBack(0, duration: const Duration(milliseconds: 250));
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.done
        ? (widget.doneLabel ?? 'Done today 🌱 hold for one more')
        : (widget.label != null
            ? 'Hold: ${widget.label}'
            : 'Hold to do it');
    if (Motion.reduced(context)) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: widget.done ? mint : fern,
            foregroundColor: widget.done ? ink : paper,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: widget.onCommit,
          child: Text(widget.done ? 'Done today 🌱 (one more)' : 'I did it',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      );
    }
    return Semantics(
      button: true,
      label: label,
      onTap: widget.onCommit,
      child: GestureDetector(
        onTapDown: (_) {
          _ticked.clear();
          _c.forward(from: _c.value);
        },
        onTapUp: (_) => _cancel(),
        onTapCancel: _cancel,
        child: CustomPaint(
          foregroundPainter: _RingPainter(_c.value),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: widget.done ? mint : fern,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: widget.done ? ink : paper),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double t;
  _RingPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(1.5, 1.5, size.width - 3, size.height - 3),
      const Radius.circular(16),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final m = metrics.first;
    final drawn = m.extractPath(0, m.length * t.clamp(0.0, 1.0));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = gold;
    canvas.drawPath(drawn, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.t != t;
}

// ---------- it rains when you act ----------
class RainBurst {
  static void show(BuildContext context) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _RainLayer(onDone: () => entry.remove()),
    );
    overlay.insert(entry);
  }
}

class _RainLayer extends StatefulWidget {
  final VoidCallback onDone;
  const _RainLayer({required this.onDone});

  @override
  State<_RainLayer> createState() => _RainLayerState();
}

class _RainLayerState extends State<_RainLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  final List<List<double>> drops = List.generate(
      16, (_) => [Random().nextDouble(), 0.5 + Random().nextDouble() * 0.5]);

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: Motion.fall)
      ..forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) => CustomPaint(
          size: MediaQuery.of(context).size,
          painter: _RainPainter(_c.value, drops),
        ),
      ),
    );
  }
}

class _RainPainter extends CustomPainter {
  final double t;
  final List<List<double>> drops;
  _RainPainter(this.t, this.drops);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = fern.withValues(alpha: 0.55)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final d in drops) {
      final progress = (t / d[1]).clamp(0.0, 1.0);
      if (progress >= 1) continue;
      final x = d[0] * size.width;
      final y = progress * size.height;
      canvas.drawLine(Offset(x, y), Offset(x, y + 18), paint);
    }
  }

  @override
  bool shouldRepaint(_RainPainter old) => old.t != t;
}
