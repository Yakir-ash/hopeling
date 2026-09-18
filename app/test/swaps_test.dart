// This-not-that's constitution: one knowledge file, ingredients
// first, every card dated and sourced, every neighbour real, every
// experiment real, every action it feeds real, and no ranking
// anywhere for money to lean on.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopeling/data/almanac.dart';
import 'package:hopeling/data/lab.dart';
import 'package:hopeling/data/rules.dart' as rules;
import 'package:hopeling/data/save.dart';
import 'package:hopeling/data/swaps.dart';

SwapBook _book() =>
    parseSwaps(File('assets/knowledge/swaps.json').readAsStringSync());

void main() {
  group('the knowledge file', () {
    test('parses, and is the three cards we promised', () {
      final b = _book();
      expect(b.v, 1);
      expect(b.audience, 'adults');
      expect(b.license.isNotEmpty, isTrue);
      expect(b.swaps.map((s) => s.id).toList(),
          ['detergent', 'garden', 'apple']);
    });

    test('every card is complete: avoid, prefer, pick, nearby, '
        'consequence, sources, date', () {
      for (final s in _book().swaps) {
        expect(s.emoji.isNotEmpty, isTrue, reason: s.id);
        expect(s.title.isNotEmpty, isTrue, reason: s.id);
        expect(s.question.endsWith('?'), isTrue, reason: s.id);
        expect(s.avoid, isNotEmpty, reason: s.id);
        expect(s.prefer, isNotEmpty, reason: s.id);
        for (final a in s.avoid) {
          expect(a.ingredient.isNotEmpty, isTrue, reason: s.id);
          expect(a.why.length, greaterThan(40), reason: s.id);
          // how it hides on a label: never empty, so a person can
          // actually read the back of the bottle
          expect(a.aka, isNotEmpty, reason: '${s.id}: ${a.ingredient}');
        }
        for (final p in s.prefer) {
          expect(p.trait.isNotEmpty, isTrue, reason: s.id);
          expect(p.why.isNotEmpty, isTrue, reason: s.id);
        }
        expect(s.pick.label.isNotEmpty, isTrue, reason: s.id);
        expect(s.pick.note.isNotEmpty, isTrue, reason: s.id);
        expect(s.nearby.label.isNotEmpty, isTrue, reason: s.id);
        expect(s.consequence.line.isNotEmpty, isTrue, reason: s.id);
        expect(s.consequence.chain.length, greaterThanOrEqualTo(3),
            reason: s.id);
        expect(s.sources.length, greaterThanOrEqualTo(2), reason: s.id);
        for (final src in s.sources) {
          expect(src.url.startsWith('https://'), isTrue, reason: s.id);
          expect(src.title.isNotEmpty, isTrue, reason: s.id);
          expect(src.what.isNotEmpty, isTrue,
              reason: '${s.id}: every source says what it carries');
        }
        expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s.reviewed), isTrue,
            reason: '${s.id}: reviewed is a date');
        expect(s.reviewer.isNotEmpty, isTrue, reason: s.id);
        expect(s.drops, 1, reason: s.id);
      }
    });

    test('no ranking exists, and no brand is named until a person '
        'checks one', () {
      for (final s in _book().swaps) {
        // the pick is a trait: it must not carry a link without a
        // checked date, and today it carries neither
        if (s.pick.link != null) {
          expect(s.pick.linkChecked, isNotNull, reason: s.id);
        }
        expect(s.pick.link, isNull, reason: '${s.id}: not yet verified');
      }
    });

    test('the house rules hold: no dashes, no fear, no scores', () {
      final raw = File('assets/knowledge/swaps.json').readAsStringSync();
      expect(raw.contains('—'), isFalse);
      expect(raw.contains('–'), isFalse);
      final low = raw.toLowerCase();
      for (final bad in [
        'toxic!', 'poison!', 'deadly', 'cancer', 'score', 'points',
        'act now', 'hurry', 'last chance',
      ]) {
        expect(low.contains(bad), isFalse, reason: bad);
      }
    });
  });

  group('every thread is real', () {
    test('the neighbour exists in the almanac', () {
      for (final s in _book().swaps) {
        expect(atlasById(s.consequence.species), isNotNull,
            reason: '${s.id} -> ${s.consequence.species}');
      }
    });

    test('the experiment exists in the Lab', () {
      for (final s in _book().swaps) {
        expect(labScenarioById(s.consequence.lab), isNotNull,
            reason: '${s.id} -> ${s.consequence.lab}');
      }
    });

    test('the action it feeds exists on the shelf', () {
      final c = jsonDecode(
              File('../hopeling-web/content.json').readAsStringSync())
          as Map<String, dynamic>;
      final actions = c['actions'] as Map<String, dynamic>;
      for (final s in _book().swaps) {
        expect(s.feeds, isNotEmpty, reason: s.id);
        for (final slug in s.feeds) {
          expect(actions.containsKey(slug), isTrue,
              reason: '${s.id} feeds $slug');
        }
      }
    });

    test('three cards, three different neighbours, three different '
        'experiments', () {
      final b = _book();
      expect(b.swaps.map((s) => s.consequence.species).toSet().length, 3);
      expect(b.swaps.map((s) => s.consequence.lab).toSet().length, 3);
      expect(b.forSpecies('frog')?.id, 'detergent');
      expect(b.forSpecies('hedgehog')?.id, 'garden');
      expect(b.forSpecies('honeybee')?.id, 'apple');
      expect(b.forLab('runoff')?.id, 'detergent');
      expect(b.forLab('nowhere'), isNull);
    });
  });

  group('the decision is the act', () {
    test('a decision is a drop, remembered in the save, never a '
        'purchase', () {
      final b = _book();
      final s = Save();
      final out = recordSwapDecision(s, b.swaps.first, '2026-09-18');
      expect(out, isA<rules.CompleteOutcome>());
      expect(s.log['2026-09-18'], 1);
      expect((s.extra['swaps'] as Map)['detergent'], '2026-09-18');
      // nothing about money, ever
      expect(s.toJson().toString().toLowerCase().contains('purchase'),
          isFalse);
    });

    test('the eight-second surface is exactly one of each', () {
      for (final s in _book().swaps) {
        expect(s.firstAvoid.ingredient, s.avoid.first.ingredient);
        expect(s.firstPrefer.trait, s.prefer.first.trait);
      }
    });
  });
}
