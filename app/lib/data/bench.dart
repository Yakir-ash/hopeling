// The Classroom Bench's lesson plans - the only part of the Lab
// written for the grown-up at the front of the room.
//
// Everything else in the Lab speaks to one person holding one
// phone. A classroom is a different animal: thirty guesses, one
// screen, and a teacher who has eleven minutes and cannot be
// surprised by her own material. So every experiment carries a
// plan, and every plan carries the one thing lesson plans never
// admit: WHAT THE ROOM USUALLY SAYS FIRST, and why that answer
// is reasonable.
//
// The laws of the Lab still hold here. No scores. No grades. The
// show of hands is a reading of the room, never a mark, and the
// room is allowed to be right for the wrong reason and wrong for
// a good one. A prediction is how a scientist says hello to a
// question - thirty of them at once is just a louder hello.
//
// The words below are hand-written, like every word in the Lab.

class BenchLesson {
  /// The sentence to put on the board before anything runs.
  final String board;

  /// What rooms usually answer first, and why it is a reasonable
  /// answer. Teachers get the misconception BEFORE the lesson,
  /// not a warning after it goes sideways.
  final String misconception;

  /// Which lever the whole room predicts about, by option index.
  /// NEVER 0: bench one is the control, and the room's question is
  /// always comparative ("compared with bench one, where does the
  /// focus line finish?"). A controlled experiment answers a
  /// comparison, so that is what we ask the room for.
  final int ask;

  /// Three prompts, in order: notice, explain, carry it outside.
  final List<String> discuss;

  /// The sentence to leave standing in the room.
  final String closing;

  /// Honest running time, start to last word.
  final int minutes;

  const BenchLesson({
    required this.board,
    required this.misconception,
    required this.ask,
    required this.discuss,
    required this.closing,
    required this.minutes,
  });
}

const benchLessons = <String, BenchLesson>{
  'meadow': BenchLesson(
    board: 'If the bees go, who feels it last?',
    misconception:
        'The room answers "the flowers" almost immediately, and '
        'that answer is right and it is the easy half. Hold the '
        'question open until somebody says a word that is not a '
        'plant. The lesson lives in the gap between those two '
        'answers.',
    ask: 2,
    discuss: [
      'Which line moved first, and which line moved most? They '
          'are not the same line, and that is the whole idea.',
      'No fox ever met a bee. Trace the path out loud, animal by '
          'animal, until you get from a bee to a fox.',
      'Name one thing in this building that would notice if the '
          'bees went. Now name the thing that would notice '
          'second.',
    ],
    closing:
        'Nothing in the meadow starves on the first day. That is '
        'exactly what makes it hard to see in time.',
    minutes: 15,
  ),
  'wolves': BenchLesson(
    board: 'Wolves eat elk. So what happens to the trees?',
    misconception:
        'Most rooms predict the willows fall, because the word '
        '"predator" does their thinking for them. Do not correct '
        'it. Twenty five years of model, laid over the real '
        'Yellowstone counts, will do it better than you can.',
    ask: 1,
    discuss: [
      'A wolf never ate a willow. Draw the arrows on the board, '
          'wolf to elk to willow, and make somebody say the '
          'middle one out loud.',
      'Turn on the real counts. Where does our model match '
          'Yellowstone, and where does it miss? What might be '
          'missing from three boxes and three arrows?',
      'Now run the rewind and take the wolves back out. Does the '
          'valley simply return to where it started?',
    ],
    closing:
        'A predator turned out to be a gardener. That sentence '
        'should feel strange, and it should stay strange.',
    minutes: 20,
  ),
  'sea': BenchLesson(
    board: 'Two degrees. That sounds small. Small compared to '
        'what?',
    misconception:
        'Two degrees sounds like the difference between wearing '
        'a jumper and not wearing one, so rooms predict a small '
        'dent. Before you run anything, ask what two degrees of '
        'body temperature means. Let that sit.',
    ask: 2,
    discuss: [
      'The coral line and the fish line do not fall together. '
          'Which one leads, and by how long?',
      'The catch is the only line here with people standing on '
          'the end of it. Who, exactly? Name them.',
      'Compare one degree with two. Is the damage twice as big, '
          'or is it doing something else?',
    ],
    closing:
        'A reef does not fail on the day it dies. It fails on the '
        'day it stops recovering, and nobody is watching that '
        'day.',
    minutes: 15,
  ),
  'beaver': BenchLesson(
    board: 'One animal builds one dam. How far does the change '
        'travel?',
    misconception:
        'A dam reads as a blockage, a thing that stops water. '
        'Watch for the moment somebody realises it is a thing '
        'that STORES water, and hand that person the floor.',
    ask: 1,
    discuss: [
      'Which arrived first in the model, the water or the fish? '
          'Which HAD to arrive first?',
      'The herons are the last line to move. Why do the birds '
          'wait?',
      'What could people build that does the same job? What '
          'would it cost, and who would maintain it in year '
          'twenty?',
    ],
    closing:
        'The beaver is not doing anyone a favour. It is doing '
        'beaver things, and a whole valley leans on the side '
        'effect.',
    minutes: 15,
  ),
  'runoff': BenchLesson(
    board: 'More fertilizer means more growth. Growth is good. '
        'So where does this go wrong?',
    misconception:
        'Rooms predict the fish fall, and most of them say '
        '"poison". Nothing in this model poisons anything. The '
        'killer is a plant having the best year of its life.',
    ask: 1,
    discuss: [
      'The algae line rises and the oxygen line falls. What is '
          'the arrow between them actually made of?',
      'Nobody here did anything reckless. Where would you put a '
          'rule, and who pays for it?',
      'Run the buffer strip. Why does a thin band of plants '
          'along one bank do so much?',
    ],
    closing:
        'Too much of a good thing is not a saying here. It is a '
        'mechanism, and it has a body count.',
    minutes: 15,
  ),
  'overfish': BenchLesson(
    board: 'How hard can you push before something breaks? '
        'Everybody writes down a number first.',
    misconception:
        'Rooms expect the catch to shrink smoothly as pressure '
        'rises, which means they expect a warning. Have each '
        'group write the percentage where they think it breaks, '
        'and keep those numbers visible until the end.',
    ask: 2,
    discuss: [
      'Between which two settings did the floor give way? Was '
          'there any warning in the line before it?',
      'For a while the catch went UP while the fish went down. '
          'Standing on a boat in those years, what would you '
          'have believed?',
      'Run the moratorium. How many years, and does it come all '
          'the way back?',
    ],
    closing:
        'The dangerous part of a cliff is not the drop. It is the '
        'flat ground just before it.',
    minutes: 20,
  ),
  'mpa': BenchLesson(
    board: 'Close a third of the sea to fishing. What happens to '
        'the boats?',
    misconception:
        'The room predicts the catch falls, and they are '
        'reasoning cleanly from a fixed pie. That is a good '
        'model of a pizza. The lesson is that this pie is alive '
        'and makes more pie.',
    ask: 2,
    discuss: [
      'For a while the catch really does drop. How long does '
          'that stretch last, and who has to survive it?',
      'Where do the extra fish come from? Say the word '
          '"spillover" only after somebody has described it '
          'without it.',
      'This is a policy that costs its supporters first and pays '
          'them later. What does that do to the politics of '
          'passing it?',
    ],
    closing:
        'Protecting a third of the sea was never generosity '
        'toward fish. It was arithmetic on behalf of fishers.',
    minutes: 15,
  ),
  'fire': BenchLesson(
    board: 'Every fire is put out, every time, for eighty years. '
        'What have we built?',
    misconception:
        'Putting out fires is the most obviously good act anyone '
        'in the room can imagine. That is the trap. Make them '
        'defend it out loud before you run a single year.',
    ask: 1,
    discuss: [
      'The fuel line climbs quietly for decades. What is '
          'happening on the forest floor during those quiet '
          'years?',
      'Some flowers only appear after a burn. What does that '
          'tell you about how old fire is in this forest?',
      'Who would you have had to convince, in year ten, to let a '
          'small fire burn? What exactly would you have said to '
          'them?',
    ],
    closing:
        'Safety, saved up and never spent, became the danger. The '
        'forest kept every receipt.',
    minutes: 15,
  ),
  'ice': BenchLesson(
    board: 'Ice is white. Water is dark. Why should that matter?',
    misconception:
        'Rooms treat melting as a straight line: warmer, less '
        'ice, evenly, forever. The loop is what turns a straight '
        'line into a slope that steepens under its own weight.',
    ask: 2,
    discuss: [
      'Find the arrow that leaves the ice and comes back to the '
          'ice. What is that arrow made of?',
      'A loop that feeds itself: name another one, from anywhere '
          'in your life. Money, sleep, practice, anything.',
      'Run the cooling. Why does the ice not simply retrace its '
          'own line back up?',
    ],
    closing:
        'A mirror that melts stops being a mirror. That is the '
        'entire physics lesson, and it fits in one sentence.',
    minutes: 15,
  ),
  'corridor': BenchLesson(
    board: 'Two parks, one road between them, the same number of '
        'hedgehogs either way. Does the road matter?',
    misconception:
        'If the population is the same size in both worlds, '
        'rooms expect the same outcome. That being cut in half '
        'is itself an injury has to be discovered here, not '
        'announced.',
    ask: 1,
    discuss: [
      'Both worlds begin with the same animals. What, exactly, '
          'is different?',
      'The health line moves before the hedgehog line does. Why '
          'is that order the important part?',
      'Walk the road outside this building in your head. Where '
          'would you plant the green line, and what is already '
          'in the way?',
    ],
    closing:
        'You can lose an animal without anything dying. You can '
        'lose it by cutting its ground in half.',
    minutes: 15,
  ),
  'light': BenchLesson(
    board: 'A streetlight burns all night. Who is awake to pay '
        'for it?',
    misconception:
        'Light does not read as pollution: it has no smell, and '
        'it makes people feel safer. Expect the room to defend '
        'it, and let them, because the answer here is not '
        'darkness.',
    ask: 2,
    discuss: [
      'The songbirds are third in line. Trace the arrows from '
          'lamp to bird and make somebody say the middle one.',
      'Compare "shielded, warm and dimmed" with a fully dark '
          'street. How much of the gain came from the cheaper '
          'option?',
      'Find one light on this building that could point down '
          'instead of out. Who would you have to ask?',
    ],
    closing:
        'This is the rarest kind of pollution: most of it can be '
        'switched off tonight, and tonight it is gone.',
    minutes: 15,
  ),
  'sill': BenchLesson(
    board: 'One balcony. Be honest: can it possibly matter?',
    misconception:
        'The room splits, and the doubters are not being '
        'cynical. They are right at the scale of one window and '
        'wrong at the scale of a street. Get BOTH sentences said '
        'out loud before you run it.',
    ask: 2,
    discuss: [
      'What is the smallest change here that still shows up in '
          'the second line?',
      'One window box is a dot. What turns a dot into a road?',
      'Count the windowsills on the front of this building. Now '
          'say that number out loud.',
    ],
    closing:
        'The answer is no, and then yes, and the only thing that '
        'moves it is how many of you do it.',
    minutes: 10,
  ),
};

BenchLesson? benchLessonFor(String scenarioId) =>
    benchLessons[scenarioId];

/// The three answers a room may give. Comparative, because that
/// is the only kind of question a controlled experiment can
/// actually answer.
const benchAnswers = ['higher', 'lower', 'about the same'];

/// Where the chosen lever's focus line finishes against bench
/// one's. The dead band is deliberately narrow but real: a two
/// point difference on a hand-tuned model is not a finding, and
/// we will not let a classroom treat it as one.
String benchVerdict(double baselineEnd, double leverEnd) {
  final d = leverEnd - baselineEnd;
  if (d > 0.03) return 'higher';
  if (d < -0.03) return 'lower';
  return 'about the same';
}

/// How the room's hands are read back to it. Never a mark: the
/// tally describes where a room stood, and the disagreement is
/// stated as the more interesting outcome, because it is.
String roomVerdict(
    Map<String, int> hands, String modelWord, String focus) {
  final total = hands.values.fold<int>(0, (a, b) => a + b);
  if (total == 0) {
    return 'No hands counted, which is a fine way to run it too. '
        'The model says $focus: $modelWord. Ask the room whether '
        'that is what they had assumed, before they saw it.';
  }
  final top =
      hands.entries.reduce((a, b) => a.value >= b.value ? a : b);
  final tied = hands.values.where((v) => v == top.value).length > 1;
  if (tied) {
    return 'The room split evenly, and the model says $focus: '
        '$modelWord. Keep both sentences alive in the room: a '
        'class that agrees too early stops looking.';
  }
  if (top.key == modelWord) {
    return 'Most of the room read the web the way the model does '
        '($focus: $modelWord). Which means the interesting work '
        'is still ahead of you: they now have to say WHY, and '
        '"because I guessed it" is not a why.';
  }
  return 'The room said $focus: ${top.key}. The model says '
      '$focus: $modelWord. This is the best place a lesson can '
      'begin: somewhere in the web below is one thread the room '
      'and the model read differently, and finding it is the '
      'whole lesson.';
}
