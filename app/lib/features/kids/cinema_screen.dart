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

/// The film's home, declared in the content document (kidsFilm).
Future<String?> kidsFilmUrl() async {
  try {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('contentCache');
    if (raw == null) return null;
    final doc = jsonDecode(raw) as Map<String, dynamic>;
    final u = (doc['kidsFilm'] ?? '').toString();
    return u.startsWith('https://') ? u : null;
  } catch (_) {
    return null;
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
  late final AnimationController curtains = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void initState() {
    super.initState();
    widget.speak('One ticket, just for you. Ready when you are.');
  }

  @override
  void dispose() {
    curtains.dispose();
    player?.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => phase = 'curtains');
    Haptics.settle();
    final url = await kidsFilmUrl();
    if (url == null) {
      setState(() {
        phase = 'lobby';
        error = 'The cinema is still being built - '
            'come back when the sky has internet.';
      });
      return;
    }
    try {
      final f = await DefaultCacheManager().getSingleFile(url);
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
          error = 'The projector sneezed. Try again in a moment.';
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
        return Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const KidDrift(
                amount: 5,
                child: Text('🎟', style: TextStyle(fontSize: 64))),
            const SizedBox(height: 18),
            Text('One ticket, just for you',
                style: kidTitle(22, color: const Color(0xFFF3E9D2))),
            const SizedBox(height: 8),
            Text('a little film about small helpers like you',
                textAlign: TextAlign.center,
                style: kidBody(14, color: const Color(0xFF8B7E8A))),
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!,
                  textAlign: TextAlign.center,
                  style: kidBody(13, color: const Color(0xFFD9C2F0))),
            ],
            const SizedBox(height: 22),
            KidSquish(
              semanticLabel: 'Take your seat and start the film',
              onTap: _start,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF8C2B32),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text('Take your seat 🍿',
                    style: kidTitle(16, color: const Color(0xFFF3E9D2))),
              ),
            ),
          ]),
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
