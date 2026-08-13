// The Lab's engine - an ecosystem is a graph, and the graph is
// the pedagogy (LAB.md section 1).
//
//   NODES   populations and resources, each with its own slow
//           logistic growth and baseline drift
//   EDGES   interactions between nodes - and EVERY edge carries
//           its own "why" and, where it claims reality, a source.
//           The cause-and-effect explorer is not built beside the
//           model; it IS the model, made tappable.
//   DRIVERS the outside hands (warming, fishing, bees lost) -
//           the levers users pull, applied per scenario option
//
// Honest uncertainty without dice (LAB.md section 4): every run
// happens three deterministic times - cautious, best estimate,
// severe - by scaling interaction strengths. Same lever, same
// band, every time.
//
// Repair acts (section 6) continue from the degraded end state
// with restoration drives, under a hysteresis drag: the way back
// is slower than the way down. Nodes that fell below their
// collapse threshold recover at a crippled rate - some doors
// close. Deterministic, stated, never dramatized.

class EcoNode {
  final String id;
  final String name;
  final String emoji;
  final double init; // starting level, 0..1
  final double g; // logistic growth coefficient
  final double s; // baseline linear drift (often negative)
  final double? collapseBelow; // threshold: below this, the door
  final double collapsedG; // ...closes to this growth instead
  const EcoNode(this.id, this.name, this.emoji,
      {required this.init,
      this.g = 0,
      this.s = 0,
      this.collapseBelow,
      this.collapsedG = 0.02});
}

class EcoEdge {
  final String from, to;
  final double w; // strength: d(to) += w * from * to
  final String why; // the tappable explanation - always present
  final String? cite; // where the interaction claims reality
  const EcoEdge(this.from, this.to, this.w,
      {required this.why, this.cite});
}

/// What one lever setting does to the nodes: added logistic
/// coefficient (dg) and added linear coefficient (dl) per node id.
class NodeDrive {
  final double dg;
  final double dl;
  const NodeDrive({this.dg = 0, this.dl = 0});
}

class LabMoment {
  final int step;
  final String text;
  const LabMoment(this.step, this.text);
}

class LabOption {
  final String label;
  final Map<String, NodeDrive> drives; // node id -> drive
  final double scalar; // free per-option number (e.g. fishing f)
  final List<LabMoment> moments;
  final String epilogue;
  const LabOption(this.label, this.drives, this.moments,
      this.epilogue,
      {this.scalar = 0});
}

/// A series shown but not simulated: value = from * (base +
/// mul * option.scalar), clamped. The fishers' catch, mostly.
class DerivedSeries {
  final String fromId;
  final String name;
  final String emoji;
  final double base;
  final double mul;
  const DerivedSeries(this.fromId, this.name, this.emoji,
      {required this.base, this.mul = 0});
}

/// The repair act: restoration drives, applied from the end
/// state, under hysteresis drag.
class RepairAct {
  final String label; // the door: "Now repair it" / a rewind
  final String description;
  final Map<String, NodeDrive> drives;
  final double drag; // scales positive logistic growth; < 1 =
  // recovery is slower than damage (hysteresis)
  final List<LabMoment> moments;
  final String epilogue;
  const RepairAct(this.label, this.description, this.drives,
      this.moments, this.epilogue,
      {this.drag = 0.6});
}

/// Real observations, drawn as dots over the model's line.
class RealData {
  final String nodeId;
  final String label; // what and whose numbers, honestly
  final String cite;
  final Map<int, double> points; // step index -> normalized value
  const RealData(this.nodeId, this.label, this.cite, this.points);
}

/// Under the Hood - the four-part honesty panel, hand-written.
class UnderHood {
  final String know; // what we know
  final String estimate; // what scientists estimate
  final String simplified; // what this model leaves out
  final String uncertain; // which curve to trust least
  const UnderHood(
      {required this.know,
      required this.estimate,
      required this.simplified,
      required this.uncertain});
}

class LabScenario {
  final String id;
  final String emoji;
  final String title;
  final String wing; // the ecosystem wing this belongs to
  final String question;
  final String leverName;
  final List<EcoNode> nodes;
  final List<EcoEdge> edges;
  final List<LabOption> options;
  final List<DerivedSeries> derived;
  final RepairAct? repair;
  final RealData? realData;
  final UnderHood hood;
  final String? citation;
  final String? citationUrl;
  final int steps;
  final int predictIndex; // which visible series to ask about
  const LabScenario({
    required this.id,
    required this.emoji,
    required this.title,
    required this.wing,
    required this.question,
    required this.leverName,
    required this.nodes,
    required this.edges,
    required this.options,
    required this.hood,
    this.derived = const [],
    this.repair,
    this.realData,
    this.citation,
    this.citationUrl,
    this.steps = 12,
    this.predictIndex = 1,
  });

  /// The series shown on screen, in order: nodes then derived.
  List<(String, String)> get seriesNames => [
        for (final n in nodes) (n.name, n.emoji),
        for (final d in derived) (d.name, d.emoji),
      ];
}

double _clamp(double v) => v < 0.02 ? 0.02 : (v > 1.0 ? 1.0 : v);

/// One deterministic run. [band] scales interaction strengths:
/// 0.8 cautious, 1.0 best estimate, 1.2 severe.
/// Returns series per node (then derived), [steps] values each.
/// If [from] is given, continues from those levels (repair);
/// [drag] scales positive logistic growth; [collapsed] marks
/// nodes whose doors have closed.
List<List<double>> runOnce(
  LabScenario s,
  LabOption opt, {
  double band = 1.0,
  List<double>? from,
  double drag = 1.0,
  Set<String> collapsed = const {},
}) {
  final n = s.nodes.length;
  final x = List<double>.generate(
      n, (i) => from != null ? from[i] : s.nodes[i].init);
  final out =
      List.generate(n + s.derived.length, (_) => <double>[]);
  for (var step = 0; step < s.steps; step++) {
    for (var i = 0; i < n; i++) {
      out[i].add(x[i]);
    }
    for (var d = 0; d < s.derived.length; d++) {
      final der = s.derived[d];
      final fi = s.nodes.indexWhere((e) => e.id == der.fromId);
      out[n + d].add(
          _clamp(x[fi] * (der.base + der.mul * opt.scalar)));
    }
    final next = List<double>.from(x);
    for (var i = 0; i < n; i++) {
      final node = s.nodes[i];
      final drive = opt.drives[node.id] ?? const NodeDrive();
      var gEff = node.g +
          band * drive.dg; // drivers scale with the band too
      if (collapsed.contains(node.id)) gEff = node.collapsedG;
      if (gEff > 0) gEff *= drag;
      var dx = gEff * x[i] * (1 - x[i]) +
          (node.s + band * drive.dl) * x[i];
      for (final e in s.edges) {
        if (e.to == node.id) {
          final fi = s.nodes.indexWhere((k) => k.id == e.from);
          dx += band * e.w * x[fi] * x[i];
        }
      }
      next[i] = _clamp(x[i] + dx);
    }
    for (var i = 0; i < n; i++) {
      x[i] = next[i];
    }
  }
  return out;
}

class LabRun {
  final List<List<double>> lo, mid, hi; // the three honest runs
  final Set<String> collapsed; // doors that closed (mid run)
  const LabRun(this.lo, this.mid, this.hi, this.collapsed);
}

/// The three-run band for a scenario option. Deterministic:
/// same lever, same band, every time.
LabRun runBands(LabScenario s, int option) {
  final opt = s.options[option];
  final lo = runOnce(s, opt, band: 0.8);
  final mid = runOnce(s, opt, band: 1.0);
  final hi = runOnce(s, opt, band: 1.2);
  final collapsed = <String>{};
  for (var i = 0; i < s.nodes.length; i++) {
    final t = s.nodes[i].collapseBelow;
    if (t != null && mid[i].any((v) => v <= t)) {
      collapsed.add(s.nodes[i].id);
    }
  }
  return LabRun(lo, mid, hi, collapsed);
}

/// The repair act, continued from the degraded end state, under
/// hysteresis drag, with closed doors staying mostly closed.
LabRun runRepair(LabScenario s, int option) {
  final r = s.repair!;
  final main = runBands(s, option);
  List<List<double>> cont(List<List<double>> base, double band) {
    final from = [
      for (var i = 0; i < s.nodes.length; i++) base[i].last
    ];
    final opt = LabOption('repair', r.drives, const [], '',
        scalar: s.options[option].scalar);
    return runOnce(s, opt,
        band: band,
        from: from,
        drag: r.drag,
        collapsed: main.collapsed);
  }

  return LabRun(cont(main.lo, 0.8), cont(main.mid, 1.0),
      cont(main.hi, 1.2), main.collapsed);
}
