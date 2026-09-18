// The Schoolhouse's front door - the five jobs, decided here so
// they can be tested without a widget (V2-AUDIT.md sections 2-3).
//
// The School is not a library with a lobby. It is five jobs:
//   1. do one thing outside today      (the Errand - the first law)
//   2. continue what you were learning (paths, journeys)
//   3. five minutes of wonder          (one short thing, by the day)
//   4. experiment                      (the Lab, headlined by the
//                                       fortnight's experiment)
//   5. go deeper                       (paths and journeys, one shelf)
//
// Discovery uses three signals we already have and nothing else:
// the calendar (deterministic, a book not a slot machine), the
// notebook (what was earned), and the door (the doorkeeper's
// answer). No feed. No "for you". Remembering what she did and
// knowing what day it is IS understanding the user.

import 'almanac.dart' show dayOfYear;
import 'lab.dart';
import 'mysteries.dart' show weekOfYear;

/// The kinds of five-minute wonder the School can hand you.
enum FiveKind { listening, mystery, lab, neighbour }

class FiveMinute {
  final FiveKind kind;
  final String? labId; // when kind == lab
  const FiveMinute(this.kind, {this.labId});
}

/// The order a door prefers. 'wonder' leans to the ear and the
/// neighbours; 'act' leans to experiments with a repair; everyone
/// else gets the mystery first, because a mystery is the gentlest
/// way into a school.
List<FiveKind> _orderFor(String? door) => switch (door) {
      'wonder' => const [
          FiveKind.listening,
          FiveKind.neighbour,
          FiveKind.mystery,
          FiveKind.lab
        ],
      'act' => const [
          FiveKind.lab,
          FiveKind.mystery,
          FiveKind.listening,
          FiveKind.neighbour
        ],
      _ => const [
          FiveKind.mystery,
          FiveKind.listening,
          FiveKind.lab,
          FiveKind.neighbour
        ],
    };

/// One short thing for today, chosen by the calendar and leaned by
/// the door. Same day, same door, same pick - every time.
FiveMinute fiveMinutePick(DateTime t, String? door) {
  final order = _orderFor(door);
  final kind = order[(dayOfYear(t) + t.year) % order.length];
  if (kind == FiveKind.lab) {
    // the experiment of the day: every scenario gets its turn, and
    // repair-carrying ones come first for the 'act' door
    final pool = door == 'act'
        ? [for (final s in labScenarios) if (s.repair != null) s]
        : labScenarios;
    final s = pool[(dayOfYear(t) + t.year) % pool.length];
    return FiveMinute(kind, labId: s.id);
  }
  return FiveMinute(kind);
}

/// The Lab's heartbeat: a featured experiment each fortnight,
/// chosen by the calendar like everything else.
LabScenario fortnightExperiment(DateTime t) =>
    labScenarios[(weekOfYear(t) ~/ 2 + t.year) % labScenarios.length];

/// The rooms behind the front door, for the one quiet line at the
/// bottom of the Schoolhouse. Order is the order a visitor would
/// want them, not the order they were built.
const schoolRooms = <(String, String, String)>[
  ('🧪', 'The Lab', 'twelve experiments, three living worlds'),
  ('🎧', 'The Listening Post', 'five voices to know by ear'),
  ('🕵️', 'Mysteries', 'one a week, five clues, one answer'),
  ('🥾', 'Paths', 'walks with a field note at the end of each'),
  ('📚', 'Journeys', 'the long reads, chapter by chapter'),
  ('🧑‍🏫', 'The Classroom Bench', 'for the grown-up at the front of the room'),
];
