// The Robin's settings - and the calm permission journey. The OS dialog
// is never shown before the explanation, and a refusal is respected
// forever (the app never nags its way back).

import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/notify.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/actions.dart' as engine;

class RobinScreen extends StatefulWidget {
  const RobinScreen({super.key});

  @override
  State<RobinScreen> createState() => _RobinScreenState();
}

class _RobinScreenState extends State<RobinScreen> {
  RobinPrefs? prefs;

  @override
  void initState() {
    super.initState();
    RobinPrefs.load().then((p) {
      if (mounted) setState(() => prefs = p);
    });
  }

  Future<void> _apply() async {
    await prefs!.save();
    await Robin.resync();
    if (mounted) setState(() {});
  }

  Future<void> _enable() async {
    final p = prefs!;
    if (p.denied) {
      _note('Reminders were declined before. You can allow them any time in '
          'your phone settings, and the robin will be ready.');
      return;
    }
    final agreed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: paper,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _Education(),
    );
    if (agreed != true) return;
    final granted = await Robin.requestPermission();
    if (!granted) {
      p.denied = true;
      await p.save();
      _note('That is completely fine. Hopeling works fully without reminders.');
      return;
    }
    p.enabled = true;
    p.offered = true;
    await _apply();
    Haptics.settle();
    _note('The robin will tap once a day at '
        '${p.hour.toString().padLeft(2, '0')}:${p.minute.toString().padLeft(2, '0')}.');
  }

  void _note(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _pickTime() async {
    final p = prefs!;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: p.hour, minute: p.minute),
      helpText: 'When should the robin tap?',
    );
    if (t == null) return;
    if (inQuietHours(t.hour)) {
      _note('That time falls in the quiet hours (21:00 to 08:00). '
          'The robin will tap at 08:00 instead - or pick a daytime hour.');
    }
    p.hour = t.hour;
    p.minute = t.minute;
    await _apply();
  }

  @override
  Widget build(BuildContext context) {
    final p = prefs;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        title: Text('The Robin', style: serif(19)),
      ),
      body: p == null
          ? const LoadingSeed()
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                children: [
                  const Text(
                    'One quiet reminder a day, at a time you choose. '
                    'No marketing. No streak warnings. No guilt, ever.',
                    style: TextStyle(fontSize: 14, height: 1.6, color: tx2),
                  ),
                  const SizedBox(height: 18),
                  _row(
                    '🐦',
                    'Daily reminder',
                    p.enabled
                        ? 'at ${p.hour.toString().padLeft(2, '0')}:${p.minute.toString().padLeft(2, '0')}'
                        : 'off',
                    trailing: Switch(
                      value: p.enabled,
                      activeThumbColor: fern,
                      onChanged: (v) async {
                        if (v) {
                          await _enable();
                        } else {
                          p.enabled = false;
                          await p.save();
                          await Robin.disable();
                          if (mounted) setState(() {});
                        }
                      },
                    ),
                  ),
                  if (p.enabled) ...[
                    _row('🕰', 'Reminder time', 'tap to change',
                        onTap: _pickTime),
                    _row(
                      '🤫',
                      'Silent Sunday',
                      'one weekly note instead of daily taps',
                      trailing: Switch(
                        value: p.silentSunday,
                        activeThumbColor: fern,
                        onChanged: (v) async {
                          p.silentSunday = v;
                          await _apply();
                        },
                      ),
                    ),
                    _row(
                      '🔒',
                      'Private previews',
                      'lock screen shows only "Hopeling has something small for you"',
                      trailing: Switch(
                        value: p.privatePreview,
                        activeThumbColor: fern,
                        onChanged: (v) async {
                          p.privatePreview = v;
                          await _apply();
                        },
                      ),
                    ),
                  ],
                  _row('🌙', 'Quiet hours', '21:00 to 08:00 - the robin sleeps too'),
                  const SizedBox(height: 20),
                  const Text(
                    'The robin only ever taps for things you asked for. '
                    'Turning it off changes nothing else in Hopeling.',
                    style: TextStyle(fontSize: 12.5, height: 1.6, color: tx2),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _row(String emo, String title, String sub,
      {Widget? trailing, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Corners.card),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Text(emo, style: const TextStyle(fontSize: 22)),
        title: Text(title,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700, color: ink)),
        subtitle: Text(sub,
            style: const TextStyle(fontSize: 12.5, height: 1.4, color: tx2)),
        trailing: trailing,
      ),
    );
  }
}

class _Education extends StatelessWidget {
  const _Education();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 26, 28, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🐦', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 12),
            Text('A quiet tap at the window', style: serif(21)),
            const SizedBox(height: 10),
            const Text(
              'Hopeling can send one gentle reminder at the time you choose. '
              'No marketing. No streak warnings. Nothing at night. '
              'You can change or stop this anytime.',
              style: TextStyle(fontSize: 14.5, height: 1.65, color: tx2),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: fern,
                        foregroundColor: paper,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Allow the robin'),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Not now',
                      style: TextStyle(color: tx2)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// hopeling://today/why - the explanation, straight from the notification.
class WhyScreen extends StatelessWidget {
  const WhyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.transparent, foregroundColor: ink),
      body: SafeArea(
        child: FutureBuilder<engine.DayContent>(
          future: engine.loadToday(),
          builder: (context, snap) {
            final d = snap.data;
            if (d == null) return const LoadingSeed();
            return Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WHY THIS MATTERS', style: kicker()),
                  const SizedBox(height: 12),
                  Text(d.act.t, style: serif(24, height: 1.3)),
                  const SizedBox(height: 16),
                  Text(d.act.why,
                      style: serif(17,
                          style: FontStyle.italic,
                          weight: FontWeight.w500,
                          height: 1.7,
                          color: tx2)),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                          backgroundColor: fern,
                          foregroundColor: paper,
                          padding:
                              const EdgeInsets.symmetric(vertical: 15)),
                      onPressed: () => Navigator.of(context)
                          .popUntil((r) => r.isFirst),
                      child: const Text('The promise is waiting in the grove'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
