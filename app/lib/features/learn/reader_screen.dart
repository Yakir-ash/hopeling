// The Reader - closer to a book than a webpage. Chapters page sideways,
// type is serif and unhurried, quizzes teach instead of grade, journeys
// end in reflection, and Museum Mode dissolves the interface entirely.
// Long-press any paragraph to keep it in your Nature Library.

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../core/clock.dart';
import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../data/api.dart';
import '../../data/content.dart';
import '../../data/notes.dart';
import '../../data/rules.dart' as rules;
import '../../data/save.dart';

class ReaderScreen extends StatefulWidget {
  final Journey journey;
  final AppContent content;
  final int initial;
  const ReaderScreen(
      {super.key,
      required this.journey,
      required this.content,
      this.initial = 0});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final PageController _pc;
  int page = 0;
  bool museum = false;
  bool museumChrome = true;
  final tts = FlutterTts();
  bool speaking = false;
  double rate = 0.5;

  Journey get j => widget.journey;

  @override
  void initState() {
    super.initState();
    page = widget.initial;
    _pc = PageController(initialPage: widget.initial);
    tts.setCompletionHandler(() {
      if (mounted) setState(() => speaking = false);
    });
  }

  @override
  void dispose() {
    tts.stop();
    _pc.dispose();
    super.dispose();
  }

  Future<void> _toggleSpeak() async {
    if (speaking) {
      await tts.stop();
      setState(() => speaking = false);
      return;
    }
    final l = j.lessons[page];
    await tts.setSpeechRate(rate);
    setState(() => speaking = true);
    await tts.speak('${l.t}. ${l.body}');
  }

  void _cycleRate() {
    setState(() => rate = rate >= 0.7 ? 0.35 : rate + 0.175);
    if (speaking) {
      tts.stop();
      speaking = false;
      _toggleSpeak();
    }
  }

  Future<void> _markRead(int i) async {
    final s = await Store.load();
    final lessons =
        (s.extra['lessons'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final key = j.lessonKey(i);
    if (lessons[key] == true) return;
    lessons[key] = true;
    s.extra['lessons'] = lessons;
    // PWA parity: a finished chapter counts as today's care (ui.js:344).
    rules.complete(s, todayStr());
    await Store.persist(s);
    saveTick.value++;
    if (Api.signedIn) Api.pushSave(s.toJson());
    Haptics.settle();
  }

  bool get night => DateTime.now().hour >= 21 || DateTime.now().hour < 5;
  Color get bg =>
      museum ? (night ? nightsoil : const Color(0xFFF7F1E3)) : paper;
  Color get fg => museum && night ? const Color(0xFFE8EFE9) : ink;
  Color get fg2 => museum && night ? const Color(0xFF9DB0A2) : tx2;

  @override
  Widget build(BuildContext context) {
    final total = j.lessons.length;
    return Scaffold(
      backgroundColor: bg,
      body: GestureDetector(
        onTap: museum
            ? () => setState(() => museumChrome = !museumChrome)
            : null,
        child: SafeArea(
          child: Column(
            children: [
              if (!museum || museumChrome)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: fg2),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          '${j.badge} ${j.t}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: serif(15, color: fg, weight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Read aloud',
                        icon: Icon(
                            speaking ? Icons.stop_circle_outlined : Icons.volume_up_outlined,
                            color: speaking ? fern : fg2),
                        onPressed: _toggleSpeak,
                      ),
                      if (speaking)
                        TextButton(
                          onPressed: _cycleRate,
                          child: Text('${(rate / 0.5).toStringAsFixed(1)}x',
                              style: TextStyle(fontSize: 12, color: fg2)),
                        ),
                      IconButton(
                        tooltip: museum ? 'Leave Museum Mode' : 'Museum Mode',
                        icon: Icon(
                            museum ? Icons.close_fullscreen : Icons.museum_outlined,
                            color: museum ? fern : fg2),
                        onPressed: () {
                          Haptics.settle();
                          setState(() {
                            museum = !museum;
                            museumChrome = true;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              // chapter dots: exploration, not a progress bar
              if (!museum)
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < total; i++)
                        Container(
                          width: i == page ? 18 : 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: i == page
                                ? fern
                                : fern.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: PageView.builder(
                  controller: _pc,
                  itemCount: total,
                  onPageChanged: (i) {
                    tts.stop();
                    setState(() {
                      page = i;
                      speaking = false;
                    });
                    Haptics.tick();
                  },
                  itemBuilder: (context, i) => _Chapter(
                    journey: j,
                    index: i,
                    museum: museum,
                    fg: fg,
                    fg2: fg2,
                    isLast: i == total - 1,
                    onRead: () => _markRead(i),
                    onNext: i < total - 1
                        ? () => _pc.nextPage(
                            duration: Motion.rise, curve: Motion.riseCurve)
                        : null,
                    recommendation: _recommend(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A quiet curator: suggest one other journey, never a feed.
  Journey? _recommend() {
    final others =
        widget.content.journeys.where((o) => o.slug != j.slug).toList();
    if (others.isEmpty) return null;
    return others[j.slug.hashCode.abs() % others.length];
  }
}

class _Chapter extends StatefulWidget {
  final Journey journey;
  final int index;
  final bool museum;
  final Color fg, fg2;
  final bool isLast;
  final Future<void> Function() onRead;
  final VoidCallback? onNext;
  final Journey? recommendation;
  const _Chapter(
      {required this.journey,
      required this.index,
      required this.museum,
      required this.fg,
      required this.fg2,
      required this.isLast,
      required this.onRead,
      this.onNext,
      this.recommendation});

  @override
  State<_Chapter> createState() => _ChapterState();
}

class _ChapterState extends State<_Chapter>
    with AutomaticKeepAliveClientMixin {
  bool marked = false;
  bool simple = false;
  final reflectC = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    reflection(widget.journey.slug).then((t) {
      if (mounted && t.isNotEmpty) reflectC.text = t;
    });
  }

  @override
  void dispose() {
    reflectC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = widget.journey.lessons[widget.index];
    final source = simple && l.bodySimple.isNotEmpty ? l.bodySimple : l.body;
    final paras = source
        .split(RegExp(r'\n+'))
        .where((p) => p.trim().isNotEmpty)
        .toList();
    final bodySize = widget.museum ? 19.0 : 16.5;
    return ListView(
      padding: EdgeInsets.fromLTRB(28, widget.museum ? 34 : 14, 28,
          40 + MediaQuery.of(context).padding.bottom),
      children: [
        Text(
            'CHAPTER ${widget.index + 1} OF ${widget.journey.lessons.length} · ${l.min} MIN',
            style: kicker(widget.museum ? widget.fg2 : fern)),
        const SizedBox(height: 10),
        Text(l.t, style: serif(26, color: widget.fg, height: 1.25)),
        if (l.bodySimple.isNotEmpty && !widget.museum)
          GestureDetector(
            onTap: () {
              Haptics.tick();
              setState(() => simple = !simple);
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                  simple ? 'Show the full version' : '🌱 Explain simply',
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: fern)),
            ),
          ),
        const SizedBox(height: 18),
        for (final p in paras)
          GestureDetector(
            onLongPress: () {
              Haptics.tick();
              keepQuote(p.trim(), widget.journey.t);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('📖 Kept in your Nature Library.'),
                  duration: Duration(seconds: 2)));
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(p.trim(),
                  style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: bodySize,
                      height: 1.85,
                      color: widget.fg)),
            ),
          ),
        if (l.quiz.isNotEmpty && !widget.museum) ...[
          const SizedBox(height: 10),
          for (final q in l.quiz) _QuizBlock(q: q, fg: widget.fg, fg2: widget.fg2),
        ],
        const SizedBox(height: 20),
        if (!widget.museum)
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: marked ? mint : fern,
              foregroundColor: marked ? ink : paper,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () async {
              await widget.onRead();
              if (mounted) setState(() => marked = true);
              widget.onNext?.call();
            },
            child: Text(
                marked
                    ? 'Chapter kept 🌱'
                    : widget.isLast
                        ? 'Finish the journey'
                        : 'Carry on →',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        if (widget.isLast && !widget.museum) ...[
          const SizedBox(height: 30),
          Text('BEFORE YOU GO', style: kicker()),
          const SizedBox(height: 8),
          Text('What surprised you most?',
              style: serif(17, color: widget.fg)),
          const SizedBox(height: 10),
          TextField(
            controller: reflectC,
            maxLines: 3,
            onChanged: (t) => saveReflection(widget.journey.slug, t),
            decoration: InputDecoration(
              hintText: 'A private note, kept on this phone...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          if (widget.recommendation != null) ...[
            const SizedBox(height: 26),
            Text('IF THIS STAYED WITH YOU', style: kicker()),
            const SizedBox(height: 8),
            Text(
                '${widget.recommendation!.badge} ${widget.recommendation!.t} is waiting on the shelf.',
                style: TextStyle(
                    fontSize: 14, height: 1.5, color: widget.fg2)),
          ],
        ],
      ],
    );
  }
}

// A quiz that teaches. Wrong answers explain; nothing is scored.
class _QuizBlock extends StatefulWidget {
  final QuizQ q;
  final Color fg, fg2;
  const _QuizBlock({required this.q, required this.fg, required this.fg2});

  @override
  State<_QuizBlock> createState() => _QuizBlockState();
}

class _QuizBlockState extends State<_QuizBlock> {
  int? chosen;

  @override
  Widget build(BuildContext context) {
    final q = widget.q;
    final answered = chosen != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: ink.withValues(alpha: 0.06),
              blurRadius: 14,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('A MOMENT OF WONDER', style: kicker()),
          const SizedBox(height: 8),
          Text(q.q, style: serif(16, height: 1.4)),
          const SizedBox(height: 12),
          for (var i = 0; i < q.opts.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: answered
                    ? null
                    : () {
                        setState(() => chosen = i);
                        if (i == q.a) Haptics.settle();
                      },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: !answered
                        ? paper
                        : i == q.a
                            ? mint.withValues(alpha: 0.5)
                            : i == chosen
                                ? const Color(0xFFF6E3DC)
                                : paper,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                      '${answered && i == q.a ? '🌱 ' : ''}${q.opts[i]}',
                      style: const TextStyle(
                          fontSize: 14, height: 1.4, color: ink)),
                ),
              ),
            ),
          if (answered)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                chosen == q.a
                    ? 'Exactly. Now you know something most people do not.'
                    : 'Not quite - and now the real answer will stay with you: ${q.opts[q.a]}.',
                style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                    color: tx2),
              ),
            ),
        ],
      ),
    );
  }
}
