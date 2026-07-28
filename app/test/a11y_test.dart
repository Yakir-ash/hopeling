// Accessibility guards for the V2 surfaces: every tappable thing
// is big enough for real fingers (48dp, Android guideline) and
// carries a label a screen reader can speak. These run on every
// test pass, so a regression can never slip in quietly.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopeling/features/atlas/atlas_screen.dart';
import 'package:hopeling/features/fieldguide/fieldguide_screen.dart';
import 'package:hopeling/features/mystery/mystery_screen.dart';
import 'package:hopeling/features/paths/paths_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pump(WidgetTester tester, Widget screen) async {
  await tester.binding.setSurfaceSize(const Size(800, 1400));
  await tester.pumpWidget(MaterialApp(home: screen));
  // let prefs futures and first frames settle
  await tester.pumpAndSettle(const Duration(milliseconds: 100));
}

Future<void> _guard(WidgetTester tester) async {
  final handle = tester.ensureSemantics();
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(
      tester, meetsGuideline(labeledTapTargetGuideline));
  handle.dispose();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('the Living Atlas meets tap-target and label guidelines',
      (tester) async {
    await _pump(tester, const AtlasScreen());
    await _guard(tester);
  });

  testWidgets('Paths meets tap-target and label guidelines',
      (tester) async {
    await _pump(tester, const PathsScreen());
    await _guard(tester);
  });

  testWidgets('the Mystery meets tap-target and label guidelines',
      (tester) async {
    await _pump(tester, const MysteryScreen());
    await _guard(tester);
  });

  testWidgets('the Field Guide meets tap-target and label guidelines',
      (tester) async {
    await _pump(tester, const FieldGuideScreen());
    await _guard(tester);
  });
}
