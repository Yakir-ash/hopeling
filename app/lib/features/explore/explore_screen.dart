// Explore - the Atlas. Twenty-eight worlds, each with its own atmosphere.
// Not an index: a place you descend into.

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/content.dart';
import 'world_screen.dart';

const iucnColors = {
  'CR': Color(0xFFB3261E),
  'EN': Color(0xFFD97706),
  'VU': Color(0xFFCA8A04),
  'NT': Color(0xFF65A30D),
  'LC': Color(0xFF16A34A),
};

const iucnNames = {
  'CR': 'Critically Endangered',
  'EN': 'Endangered',
  'VU': 'Vulnerable',
  'NT': 'Near Threatened',
  'LC': 'Least Concern',
};

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  AppContent? content;

  @override
  void initState() {
    super.initState();
    loadContent().then((c) {
      if (mounted) setState(() => content = c);
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = content;
    return Scaffold(
      body: SafeArea(
        child: c == null
            ? const Center(
                child: Text('Opening the atlas...',
                    style: TextStyle(color: tx2)))
            : CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 6),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('The Atlas', style: serif(28)),
                          const SizedBox(height: 4),
                          Text(
                              '${c.worlds.length} worlds · every one ends in something you can do',
                              style:
                                  const TextStyle(fontSize: 13, color: tx2)),
                          if (c.fromCache)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text('offline · showing your saved atlas',
                                  style:
                                      TextStyle(fontSize: 12, color: tx2)),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.95,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, i) => _WorldTile(world: c.worlds[i]),
                        childCount: c.worlds.length,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _WorldTile extends StatelessWidget {
  final World world;
  const _WorldTile({required this.world});

  @override
  Widget build(BuildContext context) {
    final ic = iucnColors[world.iucn];
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => WorldScreen(world: world)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(world.emo, style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 8),
              Text(world.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: serif(17)),
              const SizedBox(height: 4),
              Expanded(
                child: Text(world.sum,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11.5, height: 1.4, color: tx2)),
              ),
              if (ic != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: ic.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(iucnNames[world.iucn] ?? world.iucn,
                      style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: ic)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
