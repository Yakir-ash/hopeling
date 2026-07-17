// A world page: the honest picture. Threats with sources sit beside
// reasons for hope, and the page ends - as every Hopeling page must -
// in something you can do. The IUCN bar draws itself to teach the
// Red List viscerally, every single time.

import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/content.dart';
import '../../data/packs.dart';
import 'explore_screen.dart' show iucnColors, iucnNames;
import 'species_screen.dart';

class WorldScreen extends StatelessWidget {
  final World world;
  final AppContent content;
  const WorldScreen({super.key, required this.world, required this.content});

  @override
  Widget build(BuildContext context) {
    final sky = skyColors(DateTime.now().hour);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        title: Text('${world.emo}  ${world.name}', style: serif(20)),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: const Alignment(0, -0.5),
              colors: sky),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          children: [
            Text(world.sum,
                style: const TextStyle(
                    fontSize: 15, height: 1.55, color: tx2)),
            if (world.iucn.isNotEmpty) ...[
              const SizedBox(height: 18),
              IucnBar(code: world.iucn),
            ],
            if (world.overview.isNotEmpty)
              _Section('THE PICTURE',
                  child: _Prose(world.overview)),
            if (world.science.isNotEmpty)
              _Section('THE SCIENCE', child: _Prose(world.science)),
            if (world.stats.isNotEmpty)
              _Section('IN NUMBERS',
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: world.stats
                        .map((s) => _StatChip(
                            label: s[0], value: s.length > 1 ? s[1] : ''))
                        .toList(),
                  )),
            if (world.facts.isNotEmpty)
              _Section('WORTH REPEATING AT DINNER',
                  child: Column(
                    children: world.facts
                        .take(4)
                        .map((f) => _FactCard(
                            text: f[0], src: f.length > 1 ? f[1] : ''))
                        .toList(),
                  )),
            if (world.threats.isNotEmpty)
              _Section('WHAT THEY FACE',
                  child: Column(
                    children: world.threats
                        .map((t) => _EdgeCard(
                            title: t[0],
                            text: t.length > 1 ? t[1] : '',
                            src: t.length > 2 ? t[2] : '',
                            edge: const Color(0xFFE3B8A5)))
                        .toList(),
                  )),
            if (world.doing.isNotEmpty)
              _Section('WHAT IS ALREADY WORKING',
                  child: Column(
                    children: world.doing
                        .map((t) => _EdgeCard(
                            title: t[0],
                            text: t.length > 1 ? t[1] : '',
                            src: '',
                            edge: mint))
                        .toList(),
                  )),
            if (world.hope.isNotEmpty)
              _Section('REASONS FOR HOPE',
                  child: Column(
                    children: world.hope
                        .map((t) => _EdgeCard(
                            title: t[0],
                            text: t.length > 1 ? t[1] : '',
                            src: '',
                            edge: mint))
                        .toList(),
                  )),
            if (world.species.isNotEmpty)
              _Section('MEET THEM',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var i = 0; i < world.species.length; i++)
                            ActionChip(
                              label: Text(world.species[i],
                                  style: const TextStyle(fontSize: 13)),
                              backgroundColor: Colors.white,
                              side: BorderSide(
                                  color: fern.withValues(alpha: 0.25)),
                              onPressed: () {
                                Haptics.tick();
                                Navigator.of(context).push(risePush(
                                    SpeciesPager(
                                        world: world,
                                        content: content,
                                        initial: i)));
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _PackButton(world: world),
                    ],
                  )),
            const SizedBox(height: 34),
            Center(
              child: Text('every world ends in something you can do',
                  style: const TextStyle(
                      fontSize: 12, letterSpacing: 1.5, color: tx2)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- keep a world on the phone ----------
class _PackButton extends StatefulWidget {
  final World world;
  const _PackButton({required this.world});

  @override
  State<_PackButton> createState() => _PackButtonState();
}

class _PackButtonState extends State<_PackButton> {
  bool? kept;
  int done = 0, total = 0;
  bool working = false;

  @override
  void initState() {
    super.initState();
    hasPack(widget.world.slug).then((v) {
      if (mounted) setState(() => kept = v);
    });
  }

  Future<void> _download() async {
    setState(() {
      working = true;
      total = widget.world.species.length;
      done = 0;
    });
    await downloadWorldPack(widget.world, onProgress: (d, t) {
      if (mounted) setState(() => done = d);
    });
    Haptics.settle();
    if (mounted) {
      setState(() {
        working = false;
        kept = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.world.species.isEmpty) return const SizedBox.shrink();
    if (kept == true) {
      return const OfflineLeaf(line: 'this world is kept on your phone');
    }
    if (working) {
      return Text('🍃 gathering portraits... $done / $total',
          style: const TextStyle(fontSize: 12.5, color: tx2));
    }
    return TextButton.icon(
      onPressed: kept == null ? null : _download,
      style: TextButton.styleFrom(foregroundColor: fern),
      icon: const Icon(Icons.download_outlined, size: 18),
      label: const Text('Keep this world on your phone',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
    );
  }
}

// ---------- the drawing IUCN bar ----------
class IucnBar extends StatefulWidget {
  final String code;
  const IucnBar({super.key, required this.code});

  @override
  State<IucnBar> createState() => _IucnBarState();
}

class _IucnBarState extends State<IucnBar> {
  double target = 0;

  static const positions = {
    'LC': 0.12,
    'NT': 0.38,
    'VU': 0.56,
    'EN': 0.74,
    'CR': 0.92,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => target = positions[widget.code] ?? 0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = iucnColors[widget.code] ?? fern;
    final name = iucnNames[widget.code] ?? widget.code;
    final reduced = Motion.reduced(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 18,
          child: LayoutBuilder(
            builder: (context, box) => Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: 4,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      gradient: const LinearGradient(colors: [
                        Color(0xFF16A34A),
                        Color(0xFFCA8A04),
                        Color(0xFFD97706),
                        Color(0xFFB3261E),
                      ]),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: reduced
                      ? Duration.zero
                      : const Duration(milliseconds: 1600),
                  curve: Curves.easeInOutCubic,
                  left: (target * box.maxWidth) - 9,
                  top: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 6),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Least Concern',
                style: TextStyle(fontSize: 10.5, color: tx2)),
            Text(name,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800, color: color)),
            const Text('Extinct',
                style: TextStyle(fontSize: 10.5, color: tx2)),
          ],
        ),
      ],
    );
  }
}

// ---------- pieces ----------
class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section(this.title, {required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: kicker()),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Prose extends StatelessWidget {
  final String text;
  const _Prose(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 14.5, height: 1.65, color: ink));
}

class _StatChip extends StatelessWidget {
  final String label, value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: serif(17)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: tx2)),
        ],
      ),
    );
  }
}

class _FactCard extends StatelessWidget {
  final String text, src;
  const _FactCard({required this.text, required this.src});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text,
              style: serif(15,
                  style: FontStyle.italic,
                  weight: FontWeight.w500,
                  height: 1.5)),
          if (src.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('- ${src.toUpperCase()}',
                style: const TextStyle(
                    fontSize: 10, letterSpacing: 1.2, color: tx2)),
          ],
        ],
      ),
    );
  }
}

class _EdgeCard extends StatelessWidget {
  final String title, text, src;
  final Color edge;
  const _EdgeCard(
      {required this.title,
      required this.text,
      required this.src,
      required this.edge});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border(left: BorderSide(color: edge, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14.5, fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 6),
          Text(text,
              style:
                  const TextStyle(fontSize: 13.5, height: 1.55, color: tx2)),
          if (src.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(src.toUpperCase(),
                style: const TextStyle(
                    fontSize: 9.5, letterSpacing: 1, color: tx2)),
          ],
        ],
      ),
    );
  }
}
