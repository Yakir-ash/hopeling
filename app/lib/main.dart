// Hopeling - small actions, real hope.
// The native companion. The PWA is the blueprint; this is the definitive
// version (NATIVE.md). Slices 1-2: foundation, the Thumb Promise, the Atlas.

import 'package:flutter/material.dart';

import 'core/theme.dart';
import 'features/explore/explore_screen.dart';
import 'features/grove/grove_screen.dart';

void main() => runApp(const HopelingApp());

class HopelingApp extends StatelessWidget {
  const HopelingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hopeling',
      debugShowCheckedModeBanner: false,
      theme: dawnlight(),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int tab = 0;

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
