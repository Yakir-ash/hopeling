// The Nature Journal - one page a day, drawn by the child's own hand.
// Comics and walks pour the world in; the journal is where something
// comes back out. Constitution: the art never leaves the device (it is
// saved to app documents, not the cloud, not the save document), a
// missed day is just a missed day (tomorrow's page is always fresh,
// no streaks, no empty-page guilt), and the museum belongs to the
// family - the parent sees it through the gate, the child anytime.

import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../core/clock.dart';

// ---------- pure logic (tested) ----------

/// Gentle prompts, one per day, rotating with the same daily hash the
/// whole app trusts. Invitations, never assignments - "draw" is the
/// only verb, and skipping is always fine.
const journalPrompts = [
  'Draw something you saw outside today.',
  'Draw your favorite animal doing its favorite thing.',
  'Draw the sky exactly how it looks right now.',
  'Draw a tree you know.',
  'Draw the smallest creature you can think of.',
  'Draw what the wind might look like.',
  'Draw an animal getting ready to sleep.',
  'Draw a flower for a bee to find.',
  'Draw where a fox might live.',
  'Draw the sea, or a river, or a puddle.',
  'Draw a bird singing its morning song.',
  'Draw something green.',
  'Draw what you would see from a bird\'s nest.',
  'Draw your grove.',
];

String journalPrompt([DateTime? now]) =>
    journalPrompts[dailyIndex(journalPrompts.length, 'jr', now)];

/// j_<kidId>_<yyyy-mm-dd>.png
String journalFileName(String kidId, String day) => 'j_${kidId}_$day.png';

/// The day inside a journal file name, or null for strangers.
String? journalDayOf(String name, String kidId) {
  final prefix = 'j_${kidId}_';
  if (!name.startsWith(prefix) || !name.endsWith('.png')) return null;
  final day = name.substring(prefix.length, name.length - 4);
  return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day) ? day : null;
}

class JournalCopy {
  static const door = '🎨 My journal';
  static const doorSub = 'a fresh page every day';
  static const saved = 'Into your museum it goes! 🌟';
  static const emptyMuseum =
      'The museum opens with the first drawing. No hurry - '
      'tomorrow always brings a fresh page.';
  static const museumTitle = 'The museum';
}

// ---------- device-local storage ----------

class Journal {
  static Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/journal');
    if (!await d.exists()) await d.create(recursive: true);
    return d;
  }

  /// Saves to today's page, or back onto an older page when [day] is
  /// given (editing in the museum keeps the page's original date).
  static Future<void> save(String kidId, Uint8List png,
      {String? day}) async {
    final d = await _dir();
    await File('${d.path}/${journalFileName(kidId, day ?? todayStr())}')
        .writeAsBytes(png);
  }

  /// All pages for a child, newest first: (day, file).
  static Future<List<(String, File)>> entries(String kidId) async {
    try {
      final d = await _dir();
      final out = <(String, File)>[];
      await for (final f in d.list()) {
        if (f is! File) continue;
        final day = journalDayOf(f.uri.pathSegments.last, kidId);
        if (day != null) out.add((day, f));
      }
      out.sort((a, b) => b.$1.compareTo(a.$1));
      return out;
    } catch (_) {
      return [];
    }
  }

  static Future<int> pageCount(String kidId) async =>
      (await entries(kidId)).length;
}
