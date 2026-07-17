// The cloud door. Sign in with a code, and your grove gains a home that
// survives phones. Never blocks, never loses, never rushes.

import 'package:flutter/material.dart';

import '../../core/haptics.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../data/api.dart';
import '../../data/save.dart';
import 'migration_screen.dart';

enum _Phase { email, code, working, signedIn }

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  _Phase phase = Api.signedIn ? _Phase.signedIn : _Phase.email;
  final emailC = TextEditingController();
  final codeC = TextEditingController();
  String note = '';
  String workingLine = '';

  @override
  void dispose() {
    emailC.dispose();
    codeC.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = emailC.text.trim();
    if (!email.contains('@')) {
      setState(() => note = 'That does not look like an email yet.');
      return;
    }
    setState(() {
      note = '';
      workingLine = 'Sending your code...';
      phase = _Phase.working;
    });
    final err = await Api.requestOtp(email);
    if (!mounted) return;
    setState(() {
      if (err == null) {
        phase = _Phase.code;
        note = 'A code is on its way from hello@hopeling.app.';
      } else {
        phase = _Phase.email;
        note = err;
      }
    });
  }

  Future<void> _verify() async {
    final code = codeC.text.trim();
    if (!RegExp(r'^[0-9]{6,10}$').hasMatch(code)) {
      setState(() => note = 'The code is the 6 to 10 digits from the email.');
      return;
    }
    setState(() {
      note = '';
      workingLine = 'Opening the cloud...';
      phase = _Phase.working;
    });
    final err = await Api.verifyOtp(emailC.text.trim(), code);
    if (!mounted) return;
    if (err != null) {
      setState(() {
        phase = _Phase.code;
        note = err;
      });
      return;
    }
    Haptics.settle();
    await _afterSignIn();
  }

  /// The heart of slice 3. Everything is persisted BEFORE any ceremony;
  /// interruption at any point loses nothing.
  Future<void> _afterSignIn() async {
    setState(() {
      workingLine = 'Looking for your grove...';
      phase = _Phase.working;
    });
    final local = await Store.load();
    final (cloudDoc, corrupted) = await Api.fetchSave();
    if (!mounted) return;

    if (corrupted) {
      setState(() {
        phase = _Phase.signedIn;
        note =
            'Your cloud backup could not be read. Your grove on this phone is untouched, and your next backup will replace it.';
      });
      Api.pushSave(local.toJson());
      return;
    }

    if (cloudDoc == null) {
      // First sign-in or guest promotion: this phone's grove becomes the cloud copy.
      final ok = await Api.pushSave(local.toJson());
      if (!mounted) return;
      setState(() {
        phase = _Phase.signedIn;
        note = ok
            ? (local.meaningful
                ? 'Your grove now has a home in the clouds. It will follow you to any phone.'
                : 'Welcome. Your grove will back itself up as it grows.')
            : 'Signed in. The first backup will happen when the connection allows.';
      });
      return;
    }

    // A life exists in the cloud: merge, persist FIRST, then celebrate.
    final cloud = Save.fromJson(cloudDoc);
    final merged = Save.merge(local, cloud);
    await Store.persist(merged);
    saveTick.value++;
    Api.pushSave(merged.toJson()); // reconcile upward, fire and forget
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
        risePush(MigrationScreen(save: merged)));
  }

  Future<void> _backupNow() async {
    setState(() => note = 'Backing up...');
    final local = await Store.load();
    final ok = await Api.pushSave(local.toJson());
    if (mounted) {
      setState(() => note = ok
          ? 'Backed up. Your grove is safe in two places.'
          : 'The cloud is out of reach right now. It will catch up.');
    }
  }

  Future<void> _restore() async {
    await _afterSignIn();
  }

  Future<void> _signOut() async {
    await Api.signOut();
    if (mounted) {
      setState(() {
        phase = _Phase.email;
        note = 'Signed out. Your grove stays on this phone, whole.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: ink,
        title: Text('Your grove, everywhere', style: serif(19)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 40),
          children: [
            const Text(
              'One email, one code, no password. Your tree, streak, and badges follow you to any phone - including from the Hopeling web app.',
              style: TextStyle(fontSize: 14, height: 1.6, color: tx2),
            ),
            const SizedBox(height: 24),
            if (note.isNotEmpty) ...[
              Text(note,
                  style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                      color: fern)),
              const SizedBox(height: 16),
            ],
            if (phase == _Phase.working)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: LoadingSeed(line: workingLine),
              ),
            if (phase == _Phase.email) ...[
              TextField(
                controller: emailC,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: _field('your@email.com'),
              ),
              const SizedBox(height: 14),
              _primary('Send me a code', _sendCode),
            ],
            if (phase == _Phase.code) ...[
              TextField(
                controller: codeC,
                keyboardType: TextInputType.number,
                maxLength: 10,
                decoration: _field('the code from the email'),
              ),
              const SizedBox(height: 6),
              _primary('Open my grove', _verify),
              TextButton(
                onPressed: _sendCode,
                child: const Text('Send a new code',
                    style: TextStyle(color: fern)),
              ),
            ],
            if (phase == _Phase.signedIn) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(Corners.card),
                ),
                child: Row(
                  children: [
                    const Text('☁️', style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(Api.session?.email ?? '',
                          style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: ink)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _primary('Back up now', _backupNow),
              const SizedBox(height: 10),
              _secondary('Restore from the cloud', _restore),
              const SizedBox(height: 10),
              _secondary('Sign out (grove stays here)', _signOut),
            ],
          ],
        ),
      ),
    );
  }

  InputDecoration _field(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Corners.button),
          borderSide: BorderSide.none,
        ),
      );

  Widget _primary(String label, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: fern,
            foregroundColor: paper,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Corners.button)),
          ),
          onPressed: onTap,
          child: Text(label,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      );

  Widget _secondary(String label, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: ink,
            side: BorderSide(color: fern.withValues(alpha: 0.4)),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Corners.button)),
          ),
          onPressed: onTap,
          child: Text(label,
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      );
}
