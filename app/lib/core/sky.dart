// The Living Sky - the app's sky is the real sky.
//
// Law one of Hopeling wonder: one sky, everywhere. Time of day, a
// season-aware sunrise and sunset, and the true phase of the moon,
// all computed on device from the clock. No permissions, no network,
// no location. A parent can step outside, look up, and the moon in
// Hopeling matches the moon in the world. That is the whole trick,
// and it never stops being true.

import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;

// ---------- pure math (tested) ----------

/// The moon's phase right now, 0..1: 0 new, 0.25 first quarter,
/// 0.5 full, 0.75 last quarter. Mean-synodic math from the new moon
/// of 2000-01-06 18:14 UTC; lands within half a day of the almanac,
/// which is plenty to be right about tonight.
double moonPhase(DateTime t) {
  final epoch = DateTime.utc(2000, 1, 6, 18, 14);
  final days = t.toUtc().difference(epoch).inMinutes / 1440.0;
  const synodic = 29.530588861;
  final p = (days / synodic) % 1.0;
  return p < 0 ? p + 1.0 : p;
}

/// The moon as the sky shows it.
String moonPhaseEmoji(double p) {
  if (p < 1 / 16 || p >= 15 / 16) return '🌑';
  if (p < 3 / 16) return '🌒';
  if (p < 5 / 16) return '🌓';
  if (p < 7 / 16) return '🌔';
  if (p < 9 / 16) return '🌕';
  if (p < 11 / 16) return '🌖';
  if (p < 13 / 16) return '🌗';
  return '🌘';
}

/// The moon in kid words.
String moonPhaseName(double p) {
  if (p < 1 / 16 || p >= 15 / 16) return 'new moon';
  if (p < 3 / 16) return 'young crescent moon';
  if (p < 5 / 16) return 'half moon';
  if (p < 7 / 16) return 'almost-full moon';
  if (p < 9 / 16) return 'full moon';
  if (p < 11 / 16) return 'just-past-full moon';
  if (p < 13 / 16) return 'half moon';
  return 'old crescent moon';
}

/// Season-aware sunrise and sunset, in local hours. An honest
/// approximation for mid-latitudes: winter days short, summer days
/// long, no location asked for.
(double, double) sunTimes(DateTime local) {
  final doy = local
          .difference(DateTime(local.year, 1, 1))
          .inDays +
      1;
  final s = sin(2 * pi * (doy - 81) / 365.0);
  return (6.1 - 1.1 * s, 18.3 + 1.4 * s);
}

/// The day's hour as a double, 0..24.
double hourOf(DateTime t) => t.hour + t.minute / 60.0 + t.second / 3600.0;

// Sky keyframes: (top, mid, horizon), blended continuously so the
// sky never pops - it only turns, the way the real one does.
const _deepNight = [Color(0xFF141A33), Color(0xFF232C4E), Color(0xFF39406B)];
const _preDawn = [Color(0xFF232C4E), Color(0xFF3A4166), Color(0xFF6E5E7E)];
const _dawn = [Color(0xFF7E8BC0), Color(0xFFE8A9A2), Color(0xFFFFD9A8)];
const _morning = [Color(0xFF9CCBEF), Color(0xFFC6E4F4), Color(0xFFF2EFE0)];
const _noon = [Color(0xFF8FC4EE), Color(0xFFBFE0F2), Color(0xFFEAF2E2)];
const _golden = [Color(0xFF8FB4E0), Color(0xFFF2C48A), Color(0xFFFFE0B0)];
const _sunset = [Color(0xFF61688F), Color(0xFFE99B7A), Color(0xFFFFC48E)];
const _dusk = [Color(0xFF3A4168), Color(0xFF6E6390), Color(0xFFC08A8C)];
const _night = [Color(0xFF1B2440), Color(0xFF2A3558), Color(0xFF4A4E78)];

/// The three colors of the sky at this exact minute: top, middle,
/// horizon. Continuous - two minutes apart are nearly identical,
/// two hours apart are different worlds.
List<Color> skyStops(DateTime t) {
  final (sr, ss) = sunTimes(t);
  final h = hourOf(t);
  final keys = <(double, List<Color>)>[
    (0.0, _deepNight),
    (sr - 1.3, _preDawn),
    (sr, _dawn),
    (sr + 1.5, _morning),
    (12.5, _noon),
    (ss - 1.2, _golden),
    (ss, _sunset),
    (ss + 0.8, _dusk),
    (ss + 1.8, _night),
    (24.0, _deepNight),
  ];
  for (var i = 1; i < keys.length; i++) {
    if (h <= keys[i].$1) {
      final (h0, c0) = keys[i - 1];
      final (h1, c1) = keys[i];
      final f = h1 == h0 ? 0.0 : ((h - h0) / (h1 - h0)).clamp(0.0, 1.0);
      return [
        Color.lerp(c0[0], c1[0], f)!,
        Color.lerp(c0[1], c1[1], f)!,
        Color.lerp(c0[2], c1[2], f)!,
      ];
    }
  }
  return _deepNight;
}

/// A soft wash of the current sky for surfaces that only want a
/// tint: [tint, transparent-friendly base]. Drop-in for the old
/// hour-bucket skyColors.
List<Color> skyWash(DateTime t, Color base) =>
    [Color.lerp(skyStops(t)[1], Colors.white, 0.62)!, base];

/// Is the sky dark enough that words on it should be light?
bool skyIsDark(DateTime t) {
  final top = skyStops(t)[0];
  return top.computeLuminance() < 0.16;
}

/// How deep into night we are, 0 (broad day) .. 1 (deep night).
double nightness(DateTime t) {
  final lum = skyStops(t)[0].computeLuminance();
  return ((0.30 - lum) / 0.28).clamp(0.0, 1.0);
}

/// One quiet, true line about the sky right now. Empty in plain
/// daylight - the sky speaks softly by simply being right.
String skyLine(DateTime t) {
  final (sr, ss) = sunTimes(t);
  final h = hourOf(t);
  if (h < sr - 0.4 || h > ss + 1.0) {
    final p = moonPhase(t);
    return '${moonPhaseEmoji(p)} A ${moonPhaseName(p)} is out tonight';
  }
  if (h < sr + 0.9) return '🌅 The sun is just waking up';
  if (h > ss - 1.1) return '🌇 Golden hour - the sky is putting on its show';
  return '';
}

// ---------- the painter ----------

class SkyPainter extends CustomPainter {
  final DateTime now;
  final Color? fadeTo;
  final int seed;

  /// Compact skies (short headers with words on them) keep the moon
  /// small and anchored in a quiet corner instead of walking it
  /// across the text, and let the UI's own sun be the sun.
  final bool compact;

  /// Seconds of animation time, driven by the night ticker. Null or
  /// frozen means a still sky (day, or reduced motion).
  final ValueListenable<double>? anim;

  /// Seconds into the animation when tonight's shooting star begins,
  /// or infinity on the six nights out of seven when there is none.
  final double starAt;

  SkyPainter(this.now,
      {this.fadeTo,
      this.seed = 3,
      this.compact = false,
      this.anim,
      this.starAt = double.infinity})
      : super(repaint: anim);

  @override
  void paint(Canvas canvas, Size s) {
    final stops = skyStops(now);
    final (sr, ss) = sunTimes(now);
    final h = hourOf(now);
    final dark = nightness(now);

    canvas.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.55, 1.0],
          colors: stops,
        ).createShader(Offset.zero & s),
    );

    // stars, arriving with the dark
    if (dark > 0.15) {
      final r = Random(seed);
      final a = (dark - 0.15) / 0.85;
      for (var i = 0; i < 36; i++) {
        canvas.drawCircle(
            Offset(s.width * r.nextDouble(),
                s.height * r.nextDouble() * 0.7),
            0.7 + r.nextDouble() * 0.9,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.75 * a));
      }
    }

    // the sun, riding its arc from sunrise to sunset
    if (!compact && h > sr && h < ss) {
      final prog = (h - sr) / (ss - sr);
      final cx = s.width * (0.12 + 0.76 * prog);
      final alt = sin(pi * prog);
      final cy = s.height * (0.85 - 0.62 * alt);
      final low = 1.0 - alt; // warm and swollen near the horizon
      final core = Color.lerp(const Color(0xFFFFF6D8),
          const Color(0xFFFFB25E), low * 0.9)!;
      canvas.drawCircle(
          Offset(cx, cy),
          16.0 + 8.0 * low,
          Paint()
            ..color = core.withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14));
      canvas.drawCircle(Offset(cx, cy), 9.0 + 3.0 * low,
          Paint()..color = core.withValues(alpha: 0.9));
    }

    // the true moon: crossing the night in full scenes, resting in
    // the header's quiet corner in compact ones
    if (dark > 0.2) {
      final nightLen = 24.0 - (ss - sr);
      final sinceSet = (h - ss + 24.0) % 24.0;
      final np = (sinceSet / nightLen).clamp(0.0, 1.0);
      final cx =
          s.width * (compact ? 0.585 : 0.15 + 0.70 * np);
      final cy = s.height *
          (compact ? 0.24 : 0.52 - 0.36 * sin(pi * np));
      final p = moonPhase(now);
      final lit = (1.0 - cos(2 * pi * p)) / 2.0;
      final r = compact ? 9.0 : 12.0;
      // glow grows with how full she is
      canvas.drawCircle(
          Offset(cx, cy),
          r + 10.0,
          Paint()
            ..color = const Color(0xFFF6EFC1)
                .withValues(alpha: 0.20 * lit * dark)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
      // the lit disc, then the earth's shadow, offset by the phase
      canvas.save();
      canvas.clipPath(
          Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r)));
      canvas.drawCircle(Offset(cx, cy), r,
          Paint()..color = const Color(0xFFEFE8CF));
      final waxing = p <= 0.5;
      final off = waxing ? -4.0 * r * p : 4.0 * r * (1.0 - p);
      canvas.drawCircle(
          Offset(cx + off, cy),
          r,
          Paint()
            ..color = Color.lerp(
                stops[0], const Color(0xFF1A2138), 0.4)!);
      canvas.restore();
    }

    // slow clouds by day, crawling as the minutes pass
    if (dark < 0.5) {
      final minuteOfDay = now.hour * 60.0 + now.minute;
      final cloud = Paint()
        ..color = Colors.white.withValues(alpha: 0.30 * (1.0 - dark))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      for (var i = 0; i < 3; i++) {
        final cx = ((seed * 61.0 + i * 260.0 + minuteOfDay * (0.9 + i * 0.3)) %
                (s.width + 220.0)) -
            110.0;
        final cy = s.height * (0.14 + i * 0.15);
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(cx, cy), width: 110, height: 22),
            cloud);
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(cx + 30.0, cy - 8.0),
                width: 60,
                height: 18),
            cloud);
      }
    }

    final t = anim?.value ?? 0.0;

    // fireflies, rising once the dark is real
    if (dark > 0.25) {
      final low = compact ? 0.12 : 0.35;
      final high = compact ? 0.5 : 0.95;
      final n = compact ? 5 : 9;
      for (var i = 0; i < n; i++) {
        final fr = Random(seed * 31 + i);
        final bx = s.width * (0.06 + 0.88 * fr.nextDouble());
        final drift = 0.015 + fr.nextDouble() * 0.02;
        final ph = fr.nextDouble() * 2 * pi;
        final rise = ((t * drift + fr.nextDouble()) % 1.0);
        final fy = s.height * (high - (high - low) * rise);
        final fx = bx + sin(t * 0.4 + ph) * 14.0;
        final pulse =
            0.3 + 0.7 * ((sin(t * 1.8 + ph) + 1.0) / 2.0);
        final a = pulse * ((dark - 0.25) / 0.75).clamp(0.0, 1.0);
        canvas.drawCircle(
            Offset(fx, fy),
            7.0,
            Paint()
              ..color = const Color(0xFFFFF3A6)
                  .withValues(alpha: 0.25 * a)
              ..maskFilter =
                  const MaskFilter.blur(BlurStyle.normal, 6));
        canvas.drawCircle(
            Offset(fx, fy),
            1.8,
            Paint()
              ..color = const Color(0xFFFFF9D6)
                  .withValues(alpha: 0.9 * a));
      }
    }

    // the shooting star: one night in seven, once, and then gone
    final starT = t - starAt;
    if (dark > 0.3 && starT >= 0.0 && starT <= 1.1) {
      final p = Curves.easeOut.transform((starT / 1.1).clamp(0.0, 1.0));
      final from = Offset(s.width * 0.95, s.height * 0.06);
      final to = Offset(s.width * 0.30, s.height * 0.30);
      final head = Offset.lerp(from, to, p)!;
      final dir = (to - from) / (to - from).distance;
      final fade = (1.0 - starT / 1.1).clamp(0.0, 1.0);
      // the tail, thinning back the way she came
      for (var k = 0; k < 8; k++) {
        final back = head - dir * (k * 9.0);
        canvas.drawCircle(
            back,
            2.4 - k * 0.25,
            Paint()
              ..color = Colors.white
                  .withValues(alpha: fade * (1.0 - k / 8.0) * 0.8));
      }
      canvas.drawCircle(
          head,
          3.2,
          Paint()
            ..color = Colors.white.withValues(alpha: fade)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    }

    // fade the foot of the sky into the page beneath it
    if (fadeTo != null) {
      canvas.drawRect(
        Offset.zero & s,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.45, 1.0],
            colors: [fadeTo!.withValues(alpha: 0.0), fadeTo!],
          ).createShader(Offset.zero & s),
      );
    }
  }

  @override
  bool shouldRepaint(SkyPainter old) =>
      old.now.minute != now.minute || old.fadeTo != fadeTo;
}

/// The sky as a widget: paints the real sky and quietly keeps it
/// true, re-checking the clock every half minute. After dark it
/// wakes a ticker for the living parts - fireflies, and one night
/// in seven, a single shooting star. Reduced motion keeps the sky
/// still.
class LivingSky extends StatefulWidget {
  final Color? fadeTo;
  final int seed;
  final bool compact;
  const LivingSky(
      {super.key, this.fadeTo, this.seed = 3, this.compact = false});

  @override
  State<LivingSky> createState() => _LivingSkyState();
}

class _LivingSkyState extends State<LivingSky>
    with SingleTickerProviderStateMixin {
  Timer? _tick;
  Ticker? _night;
  final _anim = ValueNotifier<double>(0.0);
  double _starAt = double.infinity;
  bool _rolled = false;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
      _syncTicker();
    });
    _night = createTicker((elapsed) {
      _anim.value = elapsed.inMilliseconds / 1000.0;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTicker();
  }

  void _syncTicker() {
    if (!mounted) return;
    final reduced = MediaQuery.of(context).disableAnimations;
    final wantAlive = !reduced && nightness(DateTime.now()) > 0.2;
    if (wantAlive && !_night!.isActive) {
      // this counts as a night open: roll for the star, once
      if (!_rolled) {
        _rolled = true;
        final r = Random();
        if (r.nextInt(7) == 0) {
          _starAt = 5.0 + r.nextDouble() * 15.0;
        }
      }
      _night!.start();
    } else if (!wantAlive && _night!.isActive) {
      _night!.stop();
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    _night?.dispose();
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: SkyPainter(DateTime.now(),
            fadeTo: widget.fadeTo,
            seed: widget.seed,
            compact: widget.compact,
            anim: _anim,
            starAt: _starAt),
        size: Size.infinite,
      );
}

/// Law three, gently: everything alive breathes. Scales its child
/// 1.000 to 1.015 over an eight second cycle - just enough that a
/// scene feels like a creature, never enough to name. Still under
/// reduced motion.
class Breath extends StatefulWidget {
  final Widget child;
  const Breath({super.key, required this.child});

  @override
  State<Breath> createState() => _BreathState();
}

class _BreathState extends State<Breath>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(seconds: 4));

  @override
  void initState() {
    super.initState();
    _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.scale(
        scale: 1.0 +
            0.015 * Curves.easeInOut.transform(_c.value),
        child: child,
      ),
      child: widget.child,
    );
  }
}
