// The Nature Cinema - the kids film as an occasion, not a video in a
// list. The guide hands over a ticket, red curtains part, the room
// goes dark, and the film plays. Afterwards the lights come up gently
// and the journal is one door away: draw your favorite part. The film
// streams from hopeling.app (declared in the content document) and is
// cached like any photo - no platform players, no related-videos rabbit
// holes, nothing after the credits but the child's own imagination.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../../core/haptics.dart';
import '../../core/kid_theme.dart';
import '../../core/theme.dart' show Motion;
import 'journal_screen.dart';

/// One film on the program: an emoji poster, a title, its home.
class CinemaFilm {
  final String emo, title, url;
  const CinemaFilm(this.emo, this.title, this.url);
}

/// The cinema's program, declared in the content document: kidsCinema
/// is a list of films; the older single kidsFilm field still counts.
/// Editorially owned and additive - drop a new film on hopeling.app,
/// add a line to the contract, and the program grows.
Future<List<CinemaFilm>> cinemaProgram() async {
  try {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('contentCache');
    if (raw == null) return const [];
    final doc = jsonDecode(raw) as Map<String, dynamic>;
    final out = <CinemaFilm>[];
    for (final f in (doc['kidsCinema'] as List? ?? [])) {
      if (f is! Map) continue;
      final u = (f['u'] ?? '').toString();
      if (!u.startsWith('https://')) continue;
      out.add(CinemaFilm((f['e'] ?? '🎬').toString(),
          (f['t'] ?? 'A film').toString(), u));
    }
    if (out.isEmpty) {
      final u = (doc['kidsFilm'] ?? '').toString();
      if (u.startsWith('https://')) {
        out.add(CinemaFilm('🐝', 'Little Helpers', u));
      }
    }
    return out;
  } catch (_) {
    return const [];
  }
}

class CinemaScreen extends StatefulWidget {
  final String kidId;
  final void Function(String) speak;
  const CinemaScreen(
      {super.key, required this.kidId, required this.speak});

  @override
  State<CinemaScreen> createState() => _CinemaScreenState();
}

class _CinemaScreenState extends State<CinemaScreen>
    with SingleTickerProviderStateMixin {
  // lobby -> curtains -> playing -> lightsUp
  String phase = 'lobby';
  VideoPlayerController? player;
  String? error;
  List<CinemaFilm> program = [];
  CinemaFilm? picked;
  late final AnimationController curtains = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void initState() {
    super.initState();
    cinemaProgram().then((p) {
      if (mounted) setState(() => program = p);
    });
  }

  @override
  void dispose() {
    curtains.dispose();
    player?.dispose();
    super.dispose();
  }

  Future<void> _start(CinemaFilm film) async {
    setState(() {
      picked = film;
      phase = 'curtains';
      error = null;
    });
    Haptics.settle();
    try {
      final f = await DefaultCacheManager().getSingleFile(film.url);
      final c = VideoPlayerController.file(f);
      await c.initialize();
      if (!mounted) {
        c.dispose();
        return;
      }
      player = c;
      c.addListener(() {
        if (!mounted) return;
        final v = c.value;
        if (v.position >= v.duration && !v.isPlaying &&
            phase == 'playing') {
          setState(() => phase = 'lightsUp');
          widget.speak('That was our film. What was your favorite part?');
        }
      });
      if (!Motion.still(context)) {
        await curtains.forward();
      }
      setState(() => phase = 'playing');
      await c.play();
    } catch (_) {
      if (mounted) {
        setState(() {
          phase = 'lobby';
          error =
              'That reel is still on its way to the cinema - try another, '
              'or come back when the sky has internet.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1420), // cinema dark
      body: SafeArea(
        child: Stack(children: [
          Column(children: [
            Row(children: [
              const SizedBox(width: 8),
              const Text('🎬', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                  child: Text('Nature cinema',
                      style: kidTitle(18, color: const Color(0xFFF3E9D2)))),
              IconButton(
                  tooltip: 'Leave the cinema',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close,
                      color: Color(0xFF8B7E8A), size: 20)),
            ]),
            Expanded(child: Center(child: _stage())),
          ]),
        ]),
      ),
    );
  }

  Widget _stage() {
    switch (phase) {
      case 'lobby':
        return ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(28),
          children: [
            const Center(
              child: KidDrift(
                  amount: 5,
                  child: Text('🎟', style: TextStyle(fontSize: 56))),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text('One ticket, just for you',
                  style: kidTitle(22, color: const Color(0xFFF3E9D2))),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                  program.length > 1
                      ? 'tonight\'s program - pick a film'
                      : 'a little film made for you',
                  textAlign: TextAlign.center,
                  style: kidBody(14, color: const Color(0xFF8B7E8A))),
            ),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!,
                  textAlign: TextAlign.center,
                  style: kidBody(13, color: const Color(0xFFD9C2F0))),
            ],
            const SizedBox(height: 22),
            if (program.isEmpty)
              Center(
                child: Text(
                    'The cinema is still being built - come back when '
                    'the sky has internet.',
                    textAlign: TextAlign.center,
                    style:
                        kidBody(13.5, color: const Color(0xFF8B7E8A))),
              ),
            for (final f in program)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: KidSquish(
                  semanticLabel: 'Watch ${f.title}',
                  onTap: () => _start(f),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2030),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: const Color(0xFF8C2B32), width: 2),
                    ),
                    child: Row(children: [
                      Text(f.emo,
                          style: const TextStyle(fontSize: 34)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(f.title,
                            style: kidTitle(16,
                                color: const Color(0xFFF3E9D2))),
                      ),
                      Text('🍿',
                          style: const TextStyle(fontSize: 20)),
                    ]),
                  ),
                ),
              ),
          ],
        );
      case 'curtains':
        return _curtainView(loading: true);
      case 'playing':
        final p = player!;
        return GestureDetector(
          onTap: () {
            Haptics.tick();
            setState(() =>
                p.value.isPlaying ? p.pause() : p.play());
          },
          child: Stack(alignment: Alignment.center, children: [
            AspectRatio(
                aspectRatio: p.value.aspectRatio == 0
                    ? 16 / 9
                    : p.value.aspectRatio,
                child: VideoPlayer(p)),
            if (!p.value.isPlaying)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow,
                    color: Colors.white, size: 44),
              ),
          ]),
        );
      default: // lightsUp
        return Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('✨', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 14),
            Text('That was our film!',
                style: kidTitle(22, color: const Color(0xFFF3E9D2))),
            const SizedBox(height: 8),
            Text('What was your favorite part?',
                style: kidBody(14.5, color: const Color(0xFF8B7E8A))),
            const SizedBox(height: 22),
            KidSquish(
              semanticLabel: 'Draw your favorite part in the journal',
              onTap: () => Navigator.of(context).pushReplacement(
                  kidPush(JournalPage(
                      kidId: widget.kidId, speak: widget.speak))),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 13),
                decoration: BoxDecoration(
                  color: kidSun,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text('🎨 Draw your favorite part',
                    style: kidTitle(15)),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Back to my rooms',
                  style: kidBody(13, color: const Color(0xFF8B7E8A))),
            ),
          ]),
        );
    }
  }

  Widget _curtainView({required bool loading}) {
    return AnimatedBuilder(
      animation: curtains,
      builder: (_, __) => AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(children: [
          Container(color: Colors.black),
          if (loading)
            Center(
                child: Text('shhh...',
                    style:
                        kidBody(14, color: const Color(0xFF8B7E8A)))),
          // two red velvet curtains parting
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor:
                  (0.5 * (1 - curtains.value)).clamp(0.0, 0.5) + 0.001,
              heightFactor: 1,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Color(0xFF8C2B32),
                    Color(0xFF5E1B21)
                  ]),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor:
                  (0.5 * (1 - curtains.value)).clamp(0.0, 0.5) + 0.001,
              heightFactor: 1,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Color(0xFF5E1B21),
                    Color(0xFF8C2B32)
                  ]),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
