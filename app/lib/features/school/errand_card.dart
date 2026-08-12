// The Errand card - one small task that cannot be done on a
// phone. Lives wherever learning happens (the Wonder sheet, the
// Learn hall). Self-reported, untested, trusted: the tap says
// "I went", the Field Guide grows a page, and nothing ever nags.

import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/sfx.dart';
import '../../core/sky.dart';
import '../../core/theme.dart';
import '../../data/errands.dart';

class ErrandCard extends StatefulWidget {
  const ErrandCard({super.key});

  @override
  State<ErrandCard> createState() => _ErrandCardState();
}

class _ErrandCardState extends State<ErrandCard> {
  bool walked = false;

  @override
  void initState() {
    super.initState();
    Errands.walkedToday().then((w) {
      if (mounted) setState(() => walked = w);
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final e = errandOfDay(now, dark: skyIsDark(now));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          mint.withValues(alpha: 0.45),
          Colors.white,
        ]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(e.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text('Today\'s errand', style: serif(14.5)),
          ]),
          const SizedBox(height: 8),
          Text(e.text,
              style: const TextStyle(
                  fontSize: 13.5, height: 1.6, color: ink)),
          const SizedBox(height: 12),
          if (walked)
            Row(children: [
              const Text('🍃', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Walked. Your guide kept the page: '
                    '"${e.note}"',
                    style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                        color: tx2)),
              ),
            ])
          else
            Semantics(
              button: true,
              label: 'I went. Write it in my field guide.',
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    Haptics.tick();
                    Sfx.play('chime', volume: 0.4);
                    await Errands.walk(e);
                    if (mounted) setState(() => walked = true);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: 14, vertical: 11),
                    child: ExcludeSemantics(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🍃', style: TextStyle(fontSize: 15)),
                          SizedBox(width: 8),
                          Text('I went - write it in my guide',
                              style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: ink)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 6),
          const Text(
            'This one cannot be done on a phone - that is the '
            'point. No one checks. The going is the grade.',
            style: TextStyle(fontSize: 10.5, color: tx2),
          ),
        ],
      ),
    );
  }
}
