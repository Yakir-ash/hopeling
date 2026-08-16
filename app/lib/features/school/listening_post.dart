// The Listening Post - ear training as meeting, never testing.
// Five real voices (cached after first listen, like the fable
// voice), a memory hook for each, the who-is-singing quiz where
// a wrong answer is just another introduction, and the Dawn Sit
// - the rite that walks the trained ear outside. Every recordist
// credited by name.

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:just_audio/just_audio.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/haptics.dart';
import '../../core/sfx.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/errands.dart';
import '../../data/fieldguide.dart';
import '../../data/listening.dart';

class ListeningPostScreen extends StatefulWidget {
  const ListeningPostScreen({super.key});

  @override
  State<ListeningPostScreen> createState() =>
      _ListeningPostScreenState();
}

class _ListeningPostScreenState
    extends State<ListeningPostScreen> {
  final AudioPlayer _player = AudioPlayer();
  String? playing; // voice id currently playing
  Set<String> metVoices = {};
  Set<String> namedVoices = {};
  bool dawnOpen = false;
  bool dawnWalkedToday = false;

  @override
  void initState() {
    super.initState();
    _reload();
    _player.playerStateStream.listen((st) {
      if (st.processingState == ProcessingState.completed &&
          mounted) {
        setState(() => playing = null);
      }
    });
  }

  Future<void> _reload() async {
    final m = await Listening.met();
    final n = await Listening.named();
    final open = await Listening.dawnSitOpen();
    if (!mounted) return;
    setState(() {
      metVoices = m;
      namedVoices = n;
      dawnOpen = open;
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle(BirdVoice v) async {
    Haptics.tick();
    if (playing == v.id) {
      await _player.stop();
      if (mounted) setState(() => playing = null);
      return;
    }
    setState(() => playing = v.id);
    Listening.meet(v.id).then((_) => _reload());
    try {
      // cache-then-play, the fable voice's own pattern:
      // offline after the first listen
      final f =
          await DefaultCacheManager().getSingleFile(v.url);
      if (!mounted || playing != v.id) return;
      await _player.setFilePath(f.path);
      if (!mounted || playing != v.id) return;
      await _player.play();
    } catch (_) {
      if (mounted && playing == v.id) {
        setState(() => playing = null);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Her voice needs the internet once - '
                'after that it lives on your phone.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: ink,
          title: Text('🎧 The Listening Post', style: serif(19))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            const Text(
              'Five neighbors to know by ear. Learn their voices '
              'here, and within a week the morning racket outside '
              'becomes a room full of people you know.',
              style: TextStyle(fontSize: 13, height: 1.6, color: tx2),
            ),
            const SizedBox(height: 14),
            for (final v in birdVoices) _voiceCard(v),
            const SizedBox(height: 6),
            // the quiz door
            Semantics(
              button: true,
              label: 'Who is singing? The listening game.',
              child: Material(
                color: mint.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    Haptics.tick();
                    Sfx.play('pop', volume: 0.3);
                    await _player.stop();
                    if (!mounted) return;
                    setState(() => playing = null);
                    await Navigator.of(context)
                        .push(risePush(const WhoSingsScreen()));
                    _reload();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: ExcludeSemantics(
                      child: Row(children: [
                        const Text('❓',
                            style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text('Who is singing?',
                                  style: serif(15)),
                              const SizedBox(height: 2),
                              Text(
                                  namedVoices.isEmpty
                                      ? 'a voice plays - you say '
                                          'who. No grades, only '
                                          'introductions.'
                                      : '${namedVoices.length} of '
                                          '${birdVoices.length} '
                                          'neighbors named so far',
                                  style: const TextStyle(
                                      fontSize: 12, color: tx2)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: tx2, size: 20),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // THE DAWN SIT - the rite
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  const Color(0xFFFFE3C2),
                  gold.withValues(alpha: 0.2)
                ]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text('🌅',
                        style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text('The Dawn Sit', style: serif(15)),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                      dawnOpen
                          ? dawnSit.text
                          : 'The rite of this room. It opens '
                              'when you have named all five '
                              'voices - the ear must be ready '
                              'for the real chorus.',
                      style: const TextStyle(
                          fontSize: 13, height: 1.6, color: ink)),
                  if (dawnOpen) ...[
                    const SizedBox(height: 10),
                    if (dawnWalkedToday)
                      const Text(
                          '🍃 Sat. The guide kept the page.',
                          style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: tx2))
                    else
                      Semantics(
                        button: true,
                        label: 'I sat with the dawn. Write it in '
                            'my guide.',
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius:
                                BorderRadius.circular(14),
                            onTap: () async {
                              Haptics.tick();
                              Sfx.play('chime', volume: 0.4);
                              final day = DateTime.now()
                                  .difference(
                                      DateTime.utc(2020, 1, 1))
                                  .inDays;
                              await FieldGuide.earn('errand',
                                  'err:${dawnSit.id}:$day');
                              if (mounted) {
                                setState(
                                    () => dawnWalkedToday = true);
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 11),
                              child: ExcludeSemantics(
                                child: Text(
                                    '🌅 I sat with the dawn - '
                                    'write it in my guide',
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight:
                                            FontWeight.w700,
                                        color: ink)),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _CreditsPanel(),
          ],
        ),
      ),
    );
  }

  Widget _voiceCard(BirdVoice v) {
    final isPlaying = playing == v.id;
    final wasMet = metVoices.contains(v.id);
    final wasNamed = namedVoices.contains(v.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Semantics(
              button: true,
              label: isPlaying
                  ? 'Pause ${v.name}'
                  : 'Play the ${v.name}',
              child: Material(
                color: mint.withValues(alpha: 0.5),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => _toggle(v),
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: fern,
                        size: 26),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(v.emoji,
                        style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 6),
                    Flexible(
                        child: Text(v.name, style: serif(14.5))),
                    if (wasNamed)
                      const Text('  🍃',
                          style: TextStyle(fontSize: 12)),
                  ]),
                  Text(v.sci,
                      style: const TextStyle(
                          fontSize: 10.5,
                          fontStyle: FontStyle.italic,
                          color: tx2)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text(v.hook,
              style: const TextStyle(
                  fontSize: 12.5, height: 1.55, color: ink)),
          if (wasMet) ...[
            const SizedBox(height: 6),
            Text('${v.story}\n🕐 ${v.when}',
                style: const TextStyle(
                    fontSize: 11.5, height: 1.5, color: tx2)),
          ],
        ],
      ),
    );
  }
}

/// The who-is-singing game. A voice plays unnamed; three doors;
/// a wrong door is just another introduction - the reveal is
/// always warm, and the replay button is always there.
class WhoSingsScreen extends StatefulWidget {
  const WhoSingsScreen({super.key});

  @override
  State<WhoSingsScreen> createState() => _WhoSingsScreenState();
}

class _WhoSingsScreenState extends State<WhoSingsScreen> {
  final AudioPlayer _player = AudioPlayer();
  late final List<QuizRound> rounds = quizRounds(DateTime.now());
  int round = 0;
  String? chosen; // chosen voice id this round
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _play();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    final v = rounds[round].answer;
    setState(() => loading = true);
    try {
      final f =
          await DefaultCacheManager().getSingleFile(v.url);
      if (!mounted) return;
      await _player.setFilePath(f.path);
      if (!mounted) return;
      setState(() => loading = false);
      await _player.play();
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  void _choose(BirdVoice pick) {
    if (chosen != null) return;
    Haptics.tick();
    final r = rounds[round];
    setState(() => chosen = pick.id);
    if (pick.id == r.answer.id) {
      Sfx.play('chime', volume: 0.4);
      Listening.name(r.answer.id);
    } else {
      Sfx.play('drop', volume: 0.3);
    }
  }

  void _next() async {
    Haptics.tick();
    await _player.stop();
    if (round < rounds.length - 1) {
      setState(() {
        round++;
        chosen = null;
      });
      _play();
    } else {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = rounds[round];
    final done = chosen != null;
    final right = chosen == r.answer.id;
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: ink,
          title: Text('❓ Who is singing?', style: serif(18))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('voice ${round + 1} of ${rounds.length}',
                  style: const TextStyle(
                      fontSize: 11, letterSpacing: 1, color: tx2)),
              const SizedBox(height: 14),
              // the mystery singer
              Center(
                child: Semantics(
                  button: true,
                  label: 'Play the mystery voice again',
                  child: Material(
                    color: mint.withValues(alpha: 0.5),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        Haptics.tick();
                        _play();
                      },
                      child: SizedBox(
                        width: 84,
                        height: 84,
                        child: loading
                            ? const Padding(
                                padding: EdgeInsets.all(30),
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: fern))
                            : const Icon(Icons.hearing_rounded,
                                color: fern, size: 36),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text('tap to hear her again - as often as '
                    'you like',
                    style: TextStyle(fontSize: 11, color: tx2)),
              ),
              const SizedBox(height: 20),
              for (final opt in r.options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Semantics(
                    button: true,
                    label: opt.name,
                    child: Material(
                      color: !done
                          ? Colors.white
                          : opt.id == r.answer.id
                              ? mint
                              : (opt.id == chosen
                                  ? const Color(0xFFF6E9E4)
                                  : Colors.white),
                      borderRadius: BorderRadius.circular(18),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _choose(opt),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: ExcludeSemantics(
                            child: Row(children: [
                              Text(opt.emoji,
                                  style: const TextStyle(
                                      fontSize: 18)),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(opt.name,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight:
                                              FontWeight.w600,
                                          color: ink))),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const Spacer(),
              if (done) ...[
                Text(
                  right
                      ? 'That\'s her - the ${r.answer.name}. '
                          '${r.answer.hook}'
                      : 'That was the ${r.answer.name} - '
                          '${r.answer.hook} Play her again and '
                          'let it settle; there is no clock on '
                          'meeting a neighbor.',
                  style: const TextStyle(
                      fontSize: 13, height: 1.6, color: ink),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: fern),
                  onPressed: _next,
                  child: Text(round < rounds.length - 1
                      ? 'next voice'
                      : 'done for today'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CreditsPanel extends StatefulWidget {
  @override
  State<_CreditsPanel> createState() => _CreditsPanelState();
}

class _CreditsPanelState extends State<_CreditsPanel> {
  bool open = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      expanded: open,
      label: 'The recordists - whose ears these were.',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Haptics.tick();
            setState(() => open = !open);
          },
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Text('🎙️', style: TextStyle(fontSize: 15)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text('Whose ears these were',
                            style: serif(13.5))),
                    Icon(open ? Icons.expand_less : Icons.expand_more,
                        size: 18, color: tx2),
                  ]),
                  if (open) ...[
                    const SizedBox(height: 8),
                    const Text(
                        'Every voice here was recorded in the '
                        'field by a real person and shared '
                        'through xeno-canto.org under Creative '
                        'Commons licenses. Thank you:',
                        style: TextStyle(
                            fontSize: 11.5, height: 1.5, color: tx2)),
                    const SizedBox(height: 8),
                    for (final v in birdVoices)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: InkWell(
                          onTap: () {
                            Haptics.tick();
                            launchUrl(Uri.parse(v.xcUrl),
                                mode:
                                    LaunchMode.externalApplication);
                          },
                          child: Text(
                              '${v.name} - ${v.recordist} '
                              '(${v.xc})',
                              style: const TextStyle(
                                  fontSize: 11.5,
                                  color: fern,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
