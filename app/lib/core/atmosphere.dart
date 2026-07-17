// Every world has its own weather. Entering Oceans must not feel like
// entering Forests: each world carries an atmosphere - a deep tone for its
// hero, a wash for its tiles, an accent for its typography.

import 'package:flutter/material.dart';

import 'theme.dart';

class Atmosphere {
  final Color deep; // hero overlays, immersive surfaces
  final Color accent; // kickers, highlights
  const Atmosphere(this.deep, this.accent);

  LinearGradient tileWash() => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [accent.withValues(alpha: 0.16), Colors.white],
      );

  LinearGradient heroVeil() => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          deep.withValues(alpha: 0.35),
          deep.withValues(alpha: 0.75),
        ],
      );
}

const _ocean = Atmosphere(Color(0xFF0B3D4C), Color(0xFF14708D));
const _arctic = Atmosphere(Color(0xFF3C5D74), Color(0xFF5B87A6));
const _forest = Atmosphere(Color(0xFF1E4533), fern);
const _fresh = Atmosphere(Color(0xFF1E5E6E), Color(0xFF2E86A0));
const _home = Atmosphere(Color(0xFF6E4E1E), Color(0xFFA0742E));

const _bySlug = <String, Atmosphere>{
  'oceans': _ocean, 'coral-reefs': _ocean, 'sea-turtles': _ocean,
  'whales': _ocean, 'sharks': _ocean, 'dolphins': _ocean,
  'penguins': _arctic, 'polar-bears': _arctic,
  'forests': _forest, 'wetlands': _fresh, 'freshwater': _fresh,
  'frogs': _fresh,
  'elephants': _forest, 'gorillas': _forest, 'orangutans': _forest,
  'lions': _home, 'tigers': _forest, 'pandas': _forest, 'rhinos': _home,
  'wolves': _forest, 'foxes': _home,
  'birds': _home, 'bees': _home, 'butterflies': _home, 'bats': _home,
  'dogs': _home, 'cats': _home, 'farm-animals': _home,
};

Atmosphere atmosphereOf(String slug) => _bySlug[slug] ?? _forest;
