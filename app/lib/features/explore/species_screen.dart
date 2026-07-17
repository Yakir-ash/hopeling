// Species - immersive portraits, made for thumbs: swipe moves between
// the species of a world, the photo owns the top of the screen, and the
// page ends where every Hopeling page ends: something you can do.

import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/content.dart';
import '../../data/wiki.dart';
import 'world_screen.dart' show IucnBar;

class SpeciesPager extends StatefulWidget {
  final World world;
  final AppContent content;
  final int initial;
  const SpeciesPager(
      {super.key,
      required this.world,
      required this.content,
      this.initial = 0});

  @override
  State<SpeciesPager> createState() => _SpeciesPagerState();
}

class _SpeciesPagerState extends State<SpeciesPager> {
  late final PageController _pc;
  late int index;

  @override
  void initState() {
    super.initState();
    index = widget.initial;
    _pc = PageController(initialPage: widget.initial);
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final names = widget.world.species;
    return Scaffold(
      backgroundColor: paper,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pc,
            itemCount: names.length,
            onPageChanged: (i) {
              Haptics.tick();
              setState(() => index = i);
            },
            itemBuilder: (context, i) => _SpeciesPage(
                name: names[i],
                world: widget.world,
                content: widget.content),
          ),
          // Back + position, floating over the photo
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _GlassButton(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.of(context).pop()),
                  const Spacer(),
                  if (names.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text('${index + 1} / ${names.length}  ·  swipe',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _SpeciesPage extends StatelessWidget {
  final String name;
  final World world;
  final AppContent content;
  const _SpeciesPage(
      {required this.name, required this.world, required this.content});

  @override
  Widget build(BuildContext context) {
    final act = world.acts.isNotEmpty ? content.actions[world.acts.first] : null;
    return FutureBuilder<WikiSummary?>(
      future: wikiSummary(name),
      builder: (context, snap) {
        final w = snap.data;
        final waiting = snap.connectionState != ConnectionState.done;
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            // The portrait owns the top of the screen.
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.44,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (w != null && (w.img.isNotEmpty || w.imgSmall.isNotEmpty))
                    WikiImage(big: w.img, small: w.imgSmall, emo: world.emo)
                  else
                    _emojiFallback(),
                  // Name over a soft gradient, readable on any photo.
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(24, 40, 24, 18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.55),
                          ],
                        ),
                      ),
                      child: Text(name,
                          style: serif(30,
                              color: Colors.white, height: 1.15)),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 20, 24, 40 + MediaQuery.of(context).padding.bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${world.emo} FROM THE WORLD OF ${world.name.toUpperCase()}',
                      style: kicker()),
                  const SizedBox(height: 14),
                  if (waiting)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: LoadingSeed(line: 'Finding their portrait...'),
                    )
                  else ...[
                    Text(
                      w?.extract ?? world.sum,
                      style: const TextStyle(
                          fontSize: 15, height: 1.65, color: ink),
                    ),
                    const SizedBox(height: 10),
                    Text(
                        w != null
                            ? 'PORTRAIT AND PHOTO VIA WIKIPEDIA, CC BY-SA'
                            : 'PORTRAIT WAITS FOR THE NEXT CONNECTION',
                        style: const TextStyle(
                            fontSize: 9.5, letterSpacing: 1, color: tx2)),
                  ],
                  if (world.iucn.isNotEmpty) ...[
                    const SizedBox(height: 22),
                    IucnBar(code: world.iucn),
                  ],
                  if (act != null) ...[
                    const SizedBox(height: 26),
                    Text('ONE THING YOU CAN DO FOR THEM TODAY',
                        style: kicker()),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                              color: ink.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 6)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(act.t, style: serif(16, height: 1.35)),
                          const SizedBox(height: 6),
                          Text(act.why,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  height: 1.5,
                                  color: tx2)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _emojiFallback() => Container(
        color: mint.withValues(alpha: 0.2),
        alignment: Alignment.center,
        child: Text(world.emo, style: const TextStyle(fontSize: 72)),
      );
}
