// Explore - the Atlas. Twenty-eight worlds, each with its own atmosphere.
// Cached-first: the atlas opens instantly from the phone, and wind
// (pull-to-refresh) brings fresh air when you ask for it.

import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
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
    contentTick.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    contentTick.removeListener(_reload);
    super.dispose();
  }

  void _reload() {
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
            ? const LoadingSeed(line: 'Opening the atlas...')
            : c.worlds.isEmpty
                ? _FirstWind(onRetry: () async {
                    await refreshContent();
                    _reload();
                  })
                : WindRefresh(
                    onRefresh: () async {
                      await refreshContent();
                      _reload();
                    },
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
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
                                    style: const TextStyle(
                                        fontSize: 13, color: tx2)),
                                if (c.fromCache)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: OfflineLeaf(),
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
                              (context, i) =>
                                  _WorldTile(world: c.worlds[i], content: c),
                              childCount: c.worlds.length,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

/// First-ever launch with no connection yet: honest, warm, no alarm.
class _FirstWind extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _FirstWind({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🍃', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 14),
            Text('The atlas arrives with the first wind.', style: serif(19)),
            const SizedBox(height: 8),
            const Text(
                'Connect once and the whole world stays on your phone, forever.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, height: 1.5, color: tx2)),
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: fern, foregroundColor: paper),
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorldTile extends StatelessWidget {
  final World world;
  final AppContent content;
  const _WorldTile({required this.world, required this.content});

  @override
  Widget build(BuildContext context) {
    final ic = iucnColors[world.iucn];
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Haptics.tick();
          Navigator.of(context)
              .push(risePush(WorldScreen(world: world, content: content)));
        },
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
