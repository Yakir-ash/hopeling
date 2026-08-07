// Pet care guides - the quiet shelf. NOT location-based, works
// fully offline, adult surface only. Every page: red flags first
// in the warm-alarm card, then observe / common causes / comfort,
// and the vet banner always. The app never generates medical text;
// these pages render static, human-reviewed words from petcare.dart.

import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/petcare.dart';

class PetCareScreen extends StatelessWidget {
  const PetCareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: ink,
          title: Text('When something seems off', style: serif(19))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            const Text(
              'Calm first steps for the common worries. Each guide '
              'starts with the signs that mean "call a vet now" - '
              'because that is the question that matters.',
              style: TextStyle(fontSize: 13, height: 1.6, color: tx2),
            ),
            const SizedBox(height: 14),
            for (final g in petGuides)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Semantics(
                  button: true,
                  label: '${g.title}. For ${g.who}.',
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        Haptics.tick();
                        Navigator.of(context)
                            .push(risePush(PetGuidePage(guide: g)));
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        child: ExcludeSemantics(
                          child: Row(children: [
                            Text(g.emoji,
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(g.title,
                                      style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: ink)),
                                  const SizedBox(height: 2),
                                  Text(g.who,
                                      style: const TextStyle(
                                          fontSize: 11.5, color: tx2)),
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
              ),
            const SizedBox(height: 8),
            const Text(
              vetBanner,
              style: TextStyle(
                  fontSize: 11.5,
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                  color: tx2),
            ),
          ],
        ),
      ),
    );
  }
}

class PetGuidePage extends StatelessWidget {
  final PetGuide guide;
  const PetGuidePage({super.key, required this.guide});

  Widget _section(String title, List<String> lines,
      {Color? color, Color textColor = ink}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: color ?? Colors.white,
          borderRadius: BorderRadius.circular(22)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: serif(15)),
          const SizedBox(height: 8),
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('•  $l',
                  style: TextStyle(
                      fontSize: 13, height: 1.55, color: textColor)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = guide;
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: ink,
          title: Text('${g.emoji} ${g.title}', style: serif(17))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            // RED FLAGS FIRST - always, by constitution
            _section('Call a vet now if', g.redFlags,
                color: const Color(0xFFF6E9E4)),
            _section('What to notice and note down', g.observe),
            _section('Often it is simply', g.causes,
                color: const Color(0xFFEFF5EC)),
            _section('Safe comfort while you watch', g.comfort),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFE3C2).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(18)),
              child: Text(g.closing,
                  style: const TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      fontStyle: FontStyle.italic,
                      color: ink)),
            ),
            const SizedBox(height: 12),
            const Text(
              vetBanner,
              style: TextStyle(
                  fontSize: 11.5,
                  height: 1.6,
                  fontStyle: FontStyle.italic,
                  color: tx2),
            ),
          ],
        ),
      ),
    );
  }
}
