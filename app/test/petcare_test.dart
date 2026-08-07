// The pet-care guides' constitution, enforced: red flags exist and
// come first, nothing is ever dosed or administered, the tone stays
// calm, the vet banner stands, and the safety-critical warnings
// (blocked male cats, lilies, xylitol) are actually present.

import 'package:flutter_test/flutter_test.dart';
import 'package:hopeling/data/petcare.dart';

void main() {
  group('shape', () {
    test('twelve guides, unique ids, complete sections', () {
      expect(petGuides.length, 12);
      expect(petGuides.map((g) => g.id).toSet().length, 12);
      for (final g in petGuides) {
        expect(g.redFlags.length, greaterThanOrEqualTo(3),
            reason: '${g.id} red flags');
        expect(g.observe.length, greaterThanOrEqualTo(2),
            reason: '${g.id} observe');
        expect(g.causes.isNotEmpty, isTrue, reason: '${g.id} causes');
        expect(g.comfort.length, greaterThanOrEqualTo(2),
            reason: '${g.id} comfort');
        expect(g.closing.trim().isNotEmpty, isTrue,
            reason: '${g.id} closing');
        expect(g.who, isIn(['dogs', 'cats', 'dogs and cats']));
      }
    });
  });

  group('never a pharmacy', () {
    test('no doses, no medications, nothing administered', () {
      const banned = [
        ' mg', 'dosage', 'dose of', 'half a tablet', 'aspirin',
        'ibuprofen', 'tylenol', 'paracetamol', 'benadryl',
        'administer', 'antihistamine', 'pepto',
      ];
      for (final g in petGuides) {
        final all = [
          g.title,
          ...g.redFlags,
          ...g.observe,
          ...g.causes,
          ...g.comfort,
          g.closing,
        ].join(' ').toLowerCase();
        for (final b in banned) {
          expect(all.contains(b), isFalse, reason: '${g.id}: "$b"');
        }
      }
    });
  });

  group('calm and clean', () {
    test('no scare words, no scolding, no dashes', () {
      for (final g in petGuides) {
        final all = [
          g.title,
          ...g.redFlags,
          ...g.observe,
          ...g.causes,
          ...g.comfort,
          g.closing,
        ].join(' ');
        for (final bad in ['panic', 'hurry up', 'stupid', 'fault']) {
          expect(all.toLowerCase().contains(bad), isFalse,
              reason: '${g.id}: "$bad"');
        }
        expect(all.contains('—'), isFalse, reason: g.id);
        expect(all.contains('–'), isFalse, reason: g.id);
      }
      expect(vetBanner.contains('—'), isFalse);
    });
  });

  group('the banner and the review gate', () {
    test('the banner says what it must', () {
      expect(vetBanner.toLowerCase(), contains('veterinarian'));
      expect(vetBanner.length, greaterThan(80));
    });
    test('review status is unverified or a real date', () {
      expect(
          RegExp(r'^(unverified|\d{4}-\d{2}-\d{2})$')
              .hasMatch(guidesReviewed),
          isTrue);
    });
  });

  group('the warnings that save lives are present', () {
    String flags(String id) => petGuides
        .firstWhere((g) => g.id == id)
        .redFlags
        .join(' ')
        .toLowerCase();

    test('blocked male cat is named an emergency', () {
      final f = flags('litter-box');
      expect(f, contains('male'));
      expect(f, contains('emergency'));
    });
    test('lilies are flagged for cats', () {
      expect(flags('ate-something-bad'), contains('lily'));
    });
    test('chocolate, grapes, and xylitol are flagged', () {
      final f = flags('ate-something-bad');
      expect(f, contains('chocolate'));
      expect(f, contains('grapes'));
      expect(f, contains('xylitol'));
    });
    test('bloat (retching without result) is flagged for dogs', () {
      expect(flags('dog-vomiting'), contains('nothing comes'));
    });
    test('the cat 24-hour fasting rule is stated', () {
      expect(flags('cat-not-eating'), contains('24 hours'));
    });
    test('never induce vomiting without professional say-so', () {
      final g = petGuides
          .firstWhere((x) => x.id == 'ate-something-bad');
      expect(g.comfort.join(' ').toLowerCase(),
          contains('do not try to make her vomit'));
    });
  });
}
