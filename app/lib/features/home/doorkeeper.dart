// The Doorkeeper - the co-founder's idea, kept to its best self.
// One warm question at the first adult open: what brings you to
// the valley? Five answers, each opening a room that already
// exists. It is a greeting, not a filing system: the answer stays
// on this device, changes anytime from Me, and never locks a
// door. Naming what you came for is itself the retention
// mechanic - people return to what they said out loud.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/haptics.dart';
import '../../core/sfx.dart';
import '../../core/theme.dart';

class Doorkeeper {
  /// Ask only once, and only if no door was ever chosen.
  static Future<bool> shouldAsk() async {
    final p = await SharedPreferences.getInstance();
    return !(p.getBool('doorAsked') ?? false);
  }

  static Future<void> save(String id) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('doorAsked', true);
    await p.setString('valleyDoor', id);
  }

  static Future<String?> door() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('valleyDoor');
  }
}

class Door {
  final String id, emoji, title, sub;
  const Door(this.id, this.emoji, this.title, this.sub);
}

const valleyDoors = [
  Door('animal', '🐾', 'An animal I care for',
      'guides for the worried nights, and the good years'),
  Door('quiet', '🌙', 'Somewhere quiet to breathe',
      'a hillside, a real sky, and nothing that hurries you'),
  Door('child', '🧒', 'A child I want to show the world',
      'a whole gentle mode that is theirs alone'),
  Door('act', '⚡', 'I want to do something real',
      'shelters, wild places, and help - near you'),
  Door('wonder', '🔭', 'Curiosity about the living world',
      'an atlas that knows what time it is'),
];

/// Shown once as a full-screen page; pops with the chosen door id
/// (or 'wander' for the quiet skip at the bottom).
class DoorkeeperScreen extends StatelessWidget {
  const DoorkeeperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: paper,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(26, 28, 26, 24),
          children: [
            Text('What brings you\nto the valley?', style: serif(26)),
            const SizedBox(height: 8),
            const Text(
              'There is no wrong door - and you can change yours '
              'anytime, under Me.',
              style: TextStyle(fontSize: 13, height: 1.5, color: tx2),
            ),
            const SizedBox(height: 22),
            for (final d in valleyDoors)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: Semantics(
                  button: true,
                  label: '${d.title}. ${d.sub}',
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        Haptics.tick();
                        Sfx.play('pop', volume: 0.3);
                        Doorkeeper.save(d.id);
                        Navigator.of(context).pop(d.id);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 15),
                        child: ExcludeSemantics(
                          child: Row(children: [
                            Text(d.emoji,
                                style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(d.title,
                                      style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: ink)),
                                  const SizedBox(height: 2),
                                  Text(d.sub,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          height: 1.4,
                                          color: tx2)),
                                ],
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Center(
              child: Semantics(
                button: true,
                label: 'Just let me wander',
                child: TextButton(
                  onPressed: () {
                    Haptics.tick();
                    Doorkeeper.save('wander');
                    Navigator.of(context).pop('wander');
                  },
                  child: const Text('just let me wander',
                      style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: tx2)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
