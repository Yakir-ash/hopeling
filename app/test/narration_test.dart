// The recorded Storyteller vs the constitution: all-or-nothing per
// line (never a mid-line voice change), and absence of recordings is
// always safe - the device voice simply carries the story.

import 'package:flutter_test/flutter_test.dart';

import 'package:hopeling/core/narration.dart';
import 'package:hopeling/core/storyteller.dart';

void main() {
  test('a line is only narrated when every sentence is covered', () {
    final files = {'The fox slept.': 'a.mp3', 'Dawn came.': 'b.mp3'};
    expect(fullyNarrated(['The fox slept.', 'Dawn came.'], files), true);
    expect(fullyNarrated(['The fox slept.', 'A new line.'], files),
        false); // one miss = whole line falls back
    expect(fullyNarrated([], files), false);
    expect(fullyNarrated(['The fox slept.'], null), false); // no manifest
  });

  test('the lookup key is exactly the speakable sentence', () {
    // what narrate.js writes and what the app looks up must agree
    final sents = storySentences('The end 🌟').map(speakable).toList();
    expect(sents, ['The end']);
    final sents2 = storySentences('Bees dance! Did you know? 🐝')
        .map(speakable)
        .where((s) => s.isNotEmpty)
        .toList();
    expect(sents2, ['Bees dance!', 'Did you know?']);
  });
}
