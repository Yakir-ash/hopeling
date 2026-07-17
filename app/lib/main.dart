// Hopeling - small actions, real hope.
// The native companion. The PWA is the blueprint; this is the definitive
// version (NATIVE.md). Slices 1-2: foundation, the Thumb Promise, the Atlas.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/deeplink.dart';
import 'core/settings.dart';
import 'core/slugify.dart';
import 'core/theme.dart';
import 'core/widgets.dart';
import 'data/api.dart';
import 'data/content.dart';
import 'features/explore/explore_screen.dart';
import 'features/explore/species_screen.dart';
import 'features/explore/world_screen.dart';
import 'features/grove/grove_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Settings.instance.load();
  await Api.load();
  // Edge-to-edge: the sky owns the whole screen; bars go transparent.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  runApp(const HopelingApp());
}

class HopelingApp extends StatelessWidget {
  const HopelingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hopeling',
      debugShowCheckedModeBanner: false,
      theme: dawnlight(),
      home: const HomeShell(),
      onGenerateRoute: (settings) {
        final link = parseDeepLink(settings.name);
        if (link == null) return null;
        return MaterialPageRoute(builder: (_) => LinkResolver(link: link));
      },
    );
  }
}

/// Opens a deep link (hopeling://species/vaquita, hopeling://world/oceans)
/// once content is available; falls back to home gracefully.
class LinkResolver extends StatefulWidget {
  final DeepLink link;
  const LinkResolver({super.key, required this.link});

  @override
  State<LinkResolver> createState() => _LinkResolverState();
}

class _LinkResolverState extends State<LinkResolver> {
  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final c = await loadContent();
    if (!mounted) return;
    final nav = Navigator.of(context);
    if (widget.link.type == 'world') {
      for (final w in c.worlds) {
        if (w.slug == widget.link.id) {
          nav.pushReplacement(risePush(WorldScreen(world: w, content: c)));
          return;
        }
      }
    } else {
      for (final w in c.worlds) {
        for (var i = 0; i < w.species.length; i++) {
          if (slugify(w.species[i]) == widget.link.id) {
            nav.pushReplacement(risePush(
                SpeciesPager(world: w, content: c, initial: i)));
            return;
          }
        }
      }
    }
    nav.pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell()));
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: SizedBox.shrink());
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Connectivity may have returned while we were away: freshen quietly.
    if (state == AppLifecycleState.resumed) refreshContent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: tab,
        children: const [GroveScreen(), ExploreScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        backgroundColor: paper,
        indicatorColor: mint,
        destinations: const [
          NavigationDestination(
              icon: Text('🌱', style: TextStyle(fontSize: 22)),
              label: 'Grove'),
          NavigationDestination(
              icon: Text('🗺️', style: TextStyle(fontSize: 22)),
              label: 'Explore'),
        ],
      ),
    );
  }
}
