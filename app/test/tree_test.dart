// The living tree vs its constitution: structure is deterministic
// (golden-ready), growth follows the oracle's stages, seasons follow
// the real calendar, wind knows the hour, and there is always a branch
// for a friend to land on.

import 'package:flutter_test/flutter_test.dart';

import 'package:hopeling/features/grove/tree.dart';

void main() {
  test('same stage grows the same tree, forever', () {
    final a = TreeSpec.grow(5);
    final b = TreeSpec.grow(5);
    expect(a.branches.length, b.branches.length);
    expect(a.clusters.length, b.clusters.length);
    for (var i = 0; i < a.branches.length; i++) {
      expect(a.branches[i].b, b.branches[i].b);
    }
    for (var i = 0; i < a.clusters.length; i++) {
      expect(a.clusters[i].at, b.clusters[i].at);
    }
  });

  test('the tree gains structure as the rhythm deepens', () {
    final counts = [for (var s = 0; s <= 7; s++) TreeSpec.grow(s).branches.length];
    expect(counts[0], 0); // the sleeping seed holds everything, shows nothing
    expect(counts[1], 1); // one brave stem
    expect(counts[2] >= 3, true);
    expect(counts[4] > counts[2], true);
    expect(counts[7] > counts[4], true);
    expect(counts[7] > 10, true); // an ancient grove is a real crown
    // and bounded: performance is part of the design
    expect(counts[7] < 120, true);
    expect(TreeSpec.grow(7).clusters.length < 80, true);
  });

  test('leaves arrive with branches, and friends always have a perch', () {
    for (var s = 1; s <= 7; s++) {
      final t = TreeSpec.grow(s);
      expect(t.clusters, isNotEmpty, reason: 'stage $s has foliage');
    }
    // by the robin's arrival (stage 3+, streak 7) there is somewhere to land
    for (var s = 3; s <= 7; s++) {
      expect(TreeSpec.grow(s).perches, isNotEmpty);
    }
    expect(TreeSpec.grow(7).perches.length >= 3, true);
  });

  test('everything stays inside the canvas', () {
    for (var s = 0; s <= 7; s++) {
      final t = TreeSpec.grow(s);
      for (final b in t.branches) {
        expect(b.b.dx > -0.05 && b.b.dx < 1.05, true);
        expect(b.b.dy > -0.02 && b.b.dy < 1.0, true);
      }
      for (final c in t.clusters) {
        expect(c.at.dy > 0.0 && c.at.dy < 1.0, true);
      }
    }
  });

  test('seasons follow the real calendar', () {
    expect(seasonOf(4), 'spring');
    expect(seasonOf(7), 'summer');
    expect(seasonOf(10), 'autumn');
    expect(seasonOf(1), 'winter');
    expect(seasonPalette('autumn').first.toARGB32() != seasonPalette('summer').first.toARGB32(),
        true);
    expect(seasonLeafKeep('winter') < 1.0, true); // winter thins the crown
    expect(seasonBlossoms('spring'), true);
    expect(seasonBlossoms('summer'), false);
  });

  test('the wind knows the hour: evening breathes, night rests', () {
    expect(windStrength(18), 1.0);
    expect(windStrength(23) < windStrength(18), true);
    expect(windStrength(3), windStrength(23));
    expect(windStrength(11), 0.6);
    for (var h = 0; h < 24; h++) {
      expect(windStrength(h) > 0 && windStrength(h) <= 1.0, true);
    }
  });
}
