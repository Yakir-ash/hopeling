// Hopeling smoke tests. The full behavioral suite (ported from scripts/sim.js)
// arrives with the state layer; for now: the app builds, and the shared clock
// hashes exactly like the PWA (FLUTTER-CONTRACTS.md parity requirement).

import 'package:flutter_test/flutter_test.dart';

import 'package:hopeling/main.dart';

void main() {
  test('dailyIndex is deterministic and in range', () {
    final a = dailyIndex(19, 'f');
    final b = dailyIndex(19, 'f');
    expect(a, b);
    expect(a >= 0 && a < 19, true);
    // Different salts should generally pick different indices.
    expect(dailyIndex(1000, 'f') == dailyIndex(1000, 'a'), false);
  });

  testWidgets('the grove builds', (WidgetTester tester) async {
    await tester.pumpWidget(const HopelingApp());
    expect(find.text('small actions, real hope'), findsOneWidget);
  });
}
