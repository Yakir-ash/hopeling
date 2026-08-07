// Pet care guides - the laminated card a good vet tech would tape
// inside a cabinet. Design rules (HUB.md, non-negotiable):
//
//   ORDER    red flags FIRST, always - "call a vet now if" is the
//            only question that matters in a worried minute
//   NEVER    doses, medications, or anything administered; comfort
//            measures are environmental only
//   BANNER   every page carries vetBanner; the app never generates
//            medical text at runtime - these words are static,
//            versioned, and human-reviewed before release
//   REVIEW   guidesReviewed stays 'unverified' until two humans
//            have read every word (RELEASE.md section 0 gate)
//
// Tone: calm, plain, specific. No scolding, no scare words. The
// reader is doing the right thing by reading.

/// Educational only - shown on every guide page.
const vetBanner =
    'This guide helps you notice and decide - it is not a '
    'veterinarian. When in doubt, call one: being told "that is '
    'nothing to worry about" is a good outcome, not a wasted call.';

/// Flips to a date once two humans have reviewed every word.
const guidesReviewed = 'unverified';

class PetGuide {
  final String id;
  final String emoji;
  final String title; // the worry, in the owner's own words
  final String who; // dogs | cats | dogs and cats
  final List<String> redFlags; // call a vet NOW if...
  final List<String> observe; // what to note before you call
  final List<String> causes; // common non-emergency explanations
  final List<String> comfort; // environmental comfort ONLY
  final String closing; // one calm line
  const PetGuide({
    required this.id,
    required this.emoji,
    required this.title,
    required this.who,
    required this.redFlags,
    required this.observe,
    required this.causes,
    required this.comfort,
    required this.closing,
  });
}

const petGuides = <PetGuide>[
  PetGuide(
    id: 'dog-not-eating',
    emoji: '🍽️',
    title: 'My dog is not eating',
    who: 'dogs',
    redFlags: [
      'She also vomits, has diarrhea, or seems weak or wobbly.',
      'Her belly looks swollen or feels hard, or she tries to '
          'vomit and nothing comes out - this one is urgent.',
      'She is a puppy, tiny, or elderly - small bodies run out of '
          'reserves fast.',
      'She has not eaten anything for more than a day, or refuses '
          'water too.',
      'She recently got into trash, chemicals, or human food like '
          'chocolate, grapes, or sugar-free gum.',
    ],
    observe: [
      'When she last ate normally, and what has she refused since '
          '- her usual food? treats? everything?',
      'Is she drinking? Watch the water bowl.',
      'Energy: is she greeting you, walking normally, wagging?',
      'Anything new: food brand, home, visitors, heat, another '
          'animal, missing toy she may have swallowed.',
    ],
    causes: [
      'A warm day, a stressful change, or a rich treat earlier '
          'can pause a healthy appetite for a meal or two.',
      'Dental pain - dogs with a sore tooth often want food but '
          'drop it or chew on one side.',
      'A new food she simply distrusts; dogs are more loyal to '
          'smells than to brands.',
    ],
    comfort: [
      'Keep fresh water always within reach.',
      'Offer her usual food at the usual time, then take it up '
          'calmly - a circus of alternatives teaches holding out.',
      'Give her a quiet, cool place to rest and skip the vigorous '
          'walk today.',
    ],
    closing: 'One skipped meal in a bright-eyed dog is usually a '
        'story; two days without food is always a phone call.',
  ),
  PetGuide(
    id: 'cat-not-eating',
    emoji: '🐱',
    title: 'My cat is not eating',
    who: 'cats',
    redFlags: [
      'She has eaten nothing for 24 hours - cats are NOT small '
          'dogs; a fasting cat can develop dangerous liver trouble '
          'within days, so this alone is a same-day call.',
      'Her gums or the whites of her eyes look yellowish.',
      'She also vomits repeatedly, hides constantly, or breathes '
          'with her mouth open.',
      'She strains in the litter box or cries there - see the '
          'litter box guide; in a male cat this is an emergency.',
    ],
    observe: [
      'Exactly how long since she ate anything at all, treats '
          'included.',
      'Is she drinking, grooming, using the litter box?',
      'Weigh the situation change: new food, new pet, moved '
          'furniture, construction noise - cats resign quietly.',
      'Check her mouth if she allows: drooling, pawing at it, a '
          'smell.',
    ],
    causes: [
      'Stress - cats answer change with hunger strikes more than '
          'any other animal in the house.',
      'A switched food or even a switched bowl; whiskers are '
          'fussy about deep, narrow dishes.',
      'Dental pain, especially in older cats.',
    ],
    comfort: [
      'Offer the food she loved last week, slightly warmed - '
          'scent is appetite for cats.',
      'Feed her somewhere calm and elevated, away from other '
          'animals and foot traffic.',
      'Keep water fresh and wide-bowled; some cats drink more '
          'from moving or elevated water.',
    ],
    closing: 'With cats the calendar is strict: a full day of '
        'nothing eaten is the day you call.',
  ),
  PetGuide(
    id: 'dog-vomiting',
    emoji: '🤢',
    title: 'My dog is vomiting',
    who: 'dogs',
    redFlags: [
      'She retches without bringing anything up, paces, and her '
          'belly looks bloated or tight - go now; this can be the '
          'stomach twisting, and hours matter.',
      'There is blood, or material that looks like coffee grounds.',
      'She vomits again and again within a few hours, or cannot '
          'keep water down.',
      'She may have swallowed a toy, a sock, a corn cob, bones, '
          'or something toxic.',
      'She is also weak, shaking, or her gums are pale.',
    ],
    observe: [
      'How many times, over how long, and what came up - food? '
          'yellow foam? anything unusual? A photo helps the vet '
          'more than a description.',
      'When she last ate, and whether the food stayed down before.',
      'Her energy between episodes: playing, or flat?',
      'What she had access to: trash, compost, plants, chews.',
    ],
    causes: [
      'The classic: she ate too fast, too much, or too weird - '
          'one vomit followed by normal cheer is common.',
      'Early-morning yellow foam on an empty stomach happens in '
          'some healthy dogs.',
      'Grass-eating and a single vomit is ordinary dog behavior, '
          'not an alarm by itself.',
    ],
    comfort: [
      'Let her stomach rest - no food for a couple of hours; calm '
          'is the treatment.',
      'Offer small sips of water rather than free gulping of a '
          'full bowl.',
      'Keep her quiet and skip meals-as-apology; her next meal '
          'should be small and unremarkable.',
    ],
    closing: 'One vomit in a happy dog is a shrug; repeated '
        'vomiting, or a bloated dog who cannot vomit, is a siren.',
  ),
  PetGuide(
    id: 'cat-vomiting',
    emoji: '🪮',
    title: 'My cat is vomiting',
    who: 'cats',
    redFlags: [
      'She vomits several times in a day, or day after day.',
      'There is blood, or she is also refusing food (see the '
          'not-eating guide - the 24-hour rule applies).',
      'She may have chewed a lily, string, ribbon, or a hair '
          'tie - lilies are seriously toxic to cats, and swallowed '
          'string can be an emergency even when she seems fine.',
      'She is lethargic, hiding, or breathing oddly between '
          'episodes.',
    ],
    observe: [
      'Hairball or vomit? A hairball is mostly hair, tube-shaped, '
          'and followed by normal behavior.',
      'Count per week - an occasional hairball is life with a '
          'cat; several vomits a week is a pattern worth a call.',
      'Any plants, threads, ribbons, or rubber bands within reach?',
      'Food gulped too fast? Some cats inhale and return breakfast '
          'within minutes, then are perfectly well.',
    ],
    causes: [
      'Hairballs, especially in shedding season and long-haired '
          'cats.',
      'Eating too fast - the returned food looks barely chewed.',
      'A sensitive stomach meeting a new food too suddenly; '
          'switches want a slow week, not a day.',
    ],
    comfort: [
      'Brush her more during shedding season - hair in the brush '
          'is hair not in her stomach.',
      'Slow the gulper: a flat wide dish or a puzzle feeder turns '
          'inhaling into eating.',
      'Keep tempting threads, ties, and lilies out of the house '
          'entirely; with cats, prevention is the whole game.',
    ],
    closing: 'An occasional hairball is housekeeping; a vomiting '
        'pattern, or any chance of string or lilies, is a call.',
  ),
  PetGuide(
    id: 'dog-diarrhea',
    emoji: '💩',
    title: 'My dog has diarrhea',
    who: 'dogs',
    redFlags: [
      'There is blood, or the stool is black and tar-like.',
      'She is a puppy, especially not fully vaccinated - puppies '
          'dehydrate fast and some causes are serious; call the '
          'same day.',
      'She is also vomiting, weak, or refusing water.',
      'It has lasted more than two days despite a calm stomach '
          'routine.',
      'She may have eaten trash, compost, a dead thing, or '
          'human medication.',
    ],
    observe: [
      'Consistency and color, unglamorous but gold to a vet - a '
          'photo spares you the vocabulary.',
      'How often, and is it getting better or worse?',
      'Is she drinking and keeping water down?',
      'Diet detective work: new food, table scraps, something '
          'scavenged on a walk?',
    ],
    causes: [
      'She ate something her stomach voted against - the most '
          'common cause by far.',
      'A sudden food switch; guts like slow changes.',
      'Excitement or stress, especially after boarding, travel, '
          'or visitors.',
    ],
    comfort: [
      'Water always available - hydration is the main job while '
          'this passes.',
      'Keep meals small, plain, and boring for a day or two.',
      'Rest instead of the dog park, and keep her away from '
          'other dogs\' business until this clears.',
    ],
    closing: 'A day of simple diarrhea in a drinking, wagging dog '
        'usually passes; blood, black stool, or a puppy never '
        'waits.',
  ),
  PetGuide(
    id: 'dog-limping',
    emoji: '🦴',
    title: 'My dog is limping',
    who: 'dogs',
    redFlags: [
      'She will not put the paw down at all, or a limb hangs at '
          'a wrong angle.',
      'There is a wound, serious swelling, or she cries when the '
          'leg is touched.',
      'The limp follows a fall, a jump gone wrong, or a car - '
          'even if she walks it off; adrenaline hides damage.',
      'She is also feverish-warm, flat, or refusing food.',
    ],
    observe: [
      'Which leg, and is it constant or only after rest or only '
          'after play? Vets love a video of the walk.',
      'Check the paw itself in good light: pads, and the fur '
          'between them - thorns, glass, a torn nail, a burr, '
          'road salt.',
      'Did it start suddenly on a walk, or creep in over weeks?',
      'Better, worse, or the same after a night of rest?',
    ],
    causes: [
      'Something in the paw - the number-one finding, and the '
          'reason to look there first.',
      'A simple strain from an athletic afternoon; like ours, '
          'their muscles complain the next day.',
      'In older dogs, stiffness after rest that eases with '
          'walking often points to joints wearing - worth a '
          'calm appointment, not a night drive.',
    ],
    comfort: [
      'Rest is the medicine you are allowed to give: short leash '
          'walks only, no fetch, no stairs marathon.',
      'If you find a thorn you can grip easily, remove it gently '
          'and keep the paw clean - anything deeper belongs to '
          'the vet.',
      'A comfortable, warm bed off slippery floors.',
    ],
    closing: 'A mild limp gets a paw check and two quiet days; a '
        'leg not used at all gets a vet today.',
  ),
  PetGuide(
    id: 'cat-hiding',
    emoji: '🫥',
    title: 'My cat is hiding and quiet',
    who: 'cats',
    redFlags: [
      'She is also not eating (the 24-hour rule), not drinking, '
          'or has not used the litter box.',
      'Her breathing is fast, noisy, or open-mouthed - in a cat '
          'that is always urgent.',
      'She cries when touched or picked up.',
      'The hiding is total and new: not even food, treats, or '
          'her favorite person brings her out.',
    ],
    observe: [
      'Is she eating, drinking, and using the box? Hidden but '
          'functioning is a different story from hidden and '
          'shut down.',
      'What changed: guests, a new animal, construction, a move, '
          'furniture rearranged, another cat visible through the '
          'window.',
      'Does she come out at night when the house sleeps? Food '
          'quietly vanishing is a good sign.',
      'Her posture when you find her: loafing comfortably, or '
          'hunched tight with squinted eyes?',
    ],
    causes: [
      'Stress - hiding is the first sentence in a cat\'s only '
          'language for it.',
      'A household change you barely registered and she deeply '
          'did.',
      'Heat, fireworks, storms; many cats file all three under '
          'the bed.',
    ],
    comfort: [
      'Let her hide - dragging a cat to comfort teaches her the '
          'hiding place was not safe either.',
      'Move food, water, and a litter box quietly closer to her '
          'refuge.',
      'Restore routine and lower the noise; predictability is '
          'cat medicine.',
    ],
    closing: 'A cat who hides but eats is coping; a cat who hides '
        'from food itself is asking you to call.',
  ),
  PetGuide(
    id: 'ate-something-bad',
    emoji: '⚠️',
    title: 'My pet ate something she should not have',
    who: 'dogs and cats',
    redFlags: [
      'Chocolate, grapes or raisins, onions, sugar-free gum or '
          'anything sweetened with xylitol, alcohol, or human '
          'medication - call a vet or a pet poison hotline NOW, '
          'even if she seems completely fine.',
      'For cats: any part of a lily, including pollen licked off '
          'fur - this is a true emergency.',
      'Rat poison, slug bait, antifreeze - now, and bring the '
          'packaging.',
      'A sock, a toy, a corn cob, skewers, or bones - and she '
          'vomits, strains, or stops eating in the days after.',
      'Any struggle to breathe, drooling, wobbling, or seizures.',
    ],
    observe: [
      'What, how much, and when - the packaging or a photo of '
          'the remains answers the vet\'s first three questions.',
      'Her weight matters to the person on the phone; know it '
          'roughly.',
      'Keep the wrapper, plant, or chewed object; it rides along '
          'to the clinic.',
    ],
    causes: [
      'Curiosity plus opportunity - this is a normal pet '
          'afternoon gone sideways, not a character flaw in '
          'anyone.',
    ],
    comfort: [
      'Do NOT try to make her vomit unless a veterinary '
          'professional on the phone tells you to - with some '
          'substances that doubles the harm.',
      'Remove the rest of whatever it was from reach of all '
          'animals in the house.',
      'Stay calm and dial - with poisons, the phone call IS the '
          'first aid.',
    ],
    closing: 'The golden rule of swallowed mysteries: when the '
        'list above is involved, you call first and watch later, '
        'never the other way around.',
  ),
  PetGuide(
    id: 'itching',
    emoji: '🪳',
    title: 'My pet keeps scratching',
    who: 'dogs and cats',
    redFlags: [
      'She has scratched or licked a spot raw, open, or smelly.',
      'Her face or muzzle is swelling, or hives appear suddenly '
          '- especially after a sting, new food, or medication.',
      'She seems miserable: scratching interrupts sleep, meals, '
          'and play.',
      'Patches of fur are falling out, or the skin looks angry '
          'over large areas.',
    ],
    observe: [
      'Where: ears, paws, belly, base of the tail? The map of '
          'the itch is half the diagnosis.',
      'Part the fur at the tail base and look for flea dirt - '
          'black specks that smear reddish on a wet tissue.',
      'Season and setting: new grass, new shampoo, new bed, new '
          'food, other animals scratching too?',
      'Ears: shaking, tilting, a smell, dark crumbs inside?',
    ],
    causes: [
      'Fleas remain the world champion, even in clean homes and '
          'on animals who never go out - one hitchhiker is '
          'enough.',
      'Environmental allergies (pollens, dust mites), often '
          'seasonal, often via the paws - the licking is itching.',
      'Dry winter skin, or a shampoo that was kinder to you '
          'than to her.',
    ],
    comfort: [
      'Wash bedding hot and vacuum the favorite spots - the '
          'environment is part of the animal.',
      'Keep her nails short so scratching does less damage while '
          'you sort out the cause.',
      'Note the pattern for the vet rather than trying products '
          'one after another - each experiment muddies the trail.',
    ],
    closing: 'An itch with a cause is fixable; the errand is '
        'finding it with your vet, not outscratching it.',
  ),
  PetGuide(
    id: 'drinking-more',
    emoji: '💧',
    title: 'My pet is drinking much more than usual',
    who: 'dogs and cats',
    redFlags: [
      'The thirst comes with weight loss, vomiting, or exhaustion.',
      'She suddenly has accidents in the house, or the litter '
          'box is heavy and soaked daily.',
      'She drinks desperately - emptying bowls, seeking toilets '
          'and puddles.',
      'She is older and the change arrived over weeks - book the '
          'vet this week, not this hour, but do book it.',
    ],
    observe: [
      'Measure, do not guess: fill the bowl from a measuring cup '
          'for two days and note what disappears.',
      'Heat, exercise, and a switch from wet food to dry all '
          'raise honest thirst - rule the innocent causes in or '
          'out.',
      'Watch the other end too: more urine, accidents, a '
          'sweetish smell?',
      'Appetite up, down, or strange alongside?',
    ],
    causes: [
      'Summer, a salty treat, a big day of play - thirst with a '
          'reason and an end.',
      'Diet changes, especially toward dry food.',
      'Persistent unexplained thirst in middle-aged and older '
          'pets has common, manageable medical causes - kidneys, '
          'hormones, sugar - and all of them prefer being found '
          'early.',
    ],
    comfort: [
      'Never restrict water to test the question - she drinks '
          'because her body asks; the vet finds out why.',
      'Keep bowls clean and full, and keep the measuring notes; '
          'two days of numbers beat a month of impressions.',
    ],
    closing: 'Thirst is a gauge on the dashboard: a spike after a '
        'hot day is normal, a needle that stays high is a '
        'scheduled appointment.',
  ),
  PetGuide(
    id: 'litter-box',
    emoji: '🚽',
    title: 'My cat\'s litter box habits changed',
    who: 'cats',
    redFlags: [
      'She strains, squats repeatedly with little or nothing '
          'coming, or cries in the box - in a MALE cat treat '
          'this as an emergency and go NOW; a blocked cat can '
          'die within a day or two.',
      'Blood in the urine, or licking underneath constantly.',
      'No urine at all for a day.',
      'She stops using the box suddenly after years of '
          'reliability - that is a message, and sometimes a '
          'medical one.',
    ],
    observe: [
      'Clumps: how many, how big, versus her normal? The box '
          'keeps honest records.',
      'Where do the accidents happen - soft things, one corner, '
          'beside the box itself?',
      'Anything about the box changed: new litter, new spot, a '
          'lid added, another animal ambushing the route?',
      'Straining versus producing: watch one visit through.',
    ],
    causes: [
      'The box itself: too dirty, too hidden, too exposed, too '
          'few for the number of cats (one each plus one spare '
          'is the classic rule).',
      'Stress marking territory after household changes.',
      'Litter changed to a texture she vetoes.',
    ],
    comfort: [
      'Scoop daily and add a second box in a quiet, escapable '
          'spot.',
      'Return to the litter she always used; experiments can '
          'wait.',
      'Clean accidents with an enzyme cleaner, never ammonia - '
          'ammonia smells like urine and invites a repeat.',
      'Never punish - a cat cannot connect it, and fear makes '
          'every version of this worse.',
    ],
    closing: 'A protest is solved with boxes and calm; a male cat '
        'straining is solved with car keys.',
  ),
  PetGuide(
    id: 'getting-old',
    emoji: '🕰️',
    title: 'My pet is slowing down with age',
    who: 'dogs and cats',
    redFlags: [
      'Slowing down arrived in weeks, not months - fast changes '
          'are illness until proven otherwise.',
      'She struggles to breathe after mild effort, coughs at '
          'night, or faints.',
      'She stops eating, loses weight visibly, or drinks '
          'dramatically more.',
      'She cries, pants, or paces at rest - pain in old animals '
          'hides behind restlessness.',
      'She gets lost in corners or stares at walls - worth a '
          'vet conversation, and kinder routines can help.',
    ],
    observe: [
      'Keep a simple diary for two weeks: stairs, walks, play, '
          'appetite, nights. Trends beat memories.',
      'Stiff after rest but smoother when warmed up? Classic '
          'joint wear - very treatable comfort exists at the '
          'vet.',
      'Hearing and eyesight: does she startle now, miss thrown '
          'treats, bump the furniture at dusk?',
      'Weight along the spine and ribs - feel monthly; fur hides '
          'change.',
    ],
    causes: [
      'Honest age: shorter walks, longer naps, deeper attachment '
          'to sunbeams - the good kind of slowing.',
      'Joint wear, the most common and most treatable companion '
          'of age.',
      'Teeth again - old mouths make eating a chore before they '
          'make it impossible.',
    ],
    comfort: [
      'Bring the world closer: bowls off the floor a little, a '
          'ramp where there were jumps, a warm bed away from '
          'drafts and off slick floors.',
      'Keep walks and play going - shorter and gentler, not '
          'gone; motion is the oil of old joints.',
      'Book the senior check-up twice a year; age itself is not '
          'a disease, but it likes company that is.',
    ],
    closing: 'Old age should look like a slower version of her - '
        'the moment it looks like a different animal, that is '
        'not age, and it deserves a call.',
  ),
  PetGuide(
    id: 'new-pet-home',
    emoji: '🏠',
    title: 'We just adopted - the first days',
    who: 'dogs and cats',
    redFlags: [
      'No eating for 24 hours (cats) or 48 hours (dogs) despite '
          'quiet and patience.',
      'Diarrhea with blood, repeated vomiting, coughing fits, or '
          'discharge from eyes or nose - new homes sometimes '
          'unwrap brewing infections; shelters want to know too.',
      'Straining in the litter box (male cats: emergency).',
      'Any behavior that frightens you around children - call '
          'the rescue before anything else; they know this '
          'animal and want to help.',
    ],
    observe: [
      'Give her a small base camp first - one quiet room beats '
          'the whole house; confidence grows outward.',
      'Appetite, water, and bathroom habits in a simple note - '
          'the first week writes her baseline.',
      'Let her set the pace of affection; sitting on the floor '
          'reading aloud does more than reaching.',
      'Keep the shelter\'s food going before any switch, and '
          'switch slowly over a week when you do.',
    ],
    causes: [
      'Nearly every oddity of week one - hiding, skipped meals, '
          'pacing, shadowing you, ignoring you - is adjustment, '
          'not defect.',
      'The 3-3-3 rhythm many rescues describe: three days of '
          'overwhelm, three weeks of settling, three months to '
          'full trust.',
    ],
    comfort: [
      'Routine, routine, routine - same times, same words, same '
          'walks; predictability is how you say "you live here" '
          'in animal.',
      'One new thing per day at most: today the hallway, not '
          'the dog park.',
      'Register with a local vet this week and book the intro '
          'check-up - a calm first visit before any crisis pays '
          'for itself for years.',
    ],
    closing: 'You did a rare good thing; give it three weeks '
        'before you judge how it is going - she is learning an '
        'entire world, and you are most of it.',
  ),
];
