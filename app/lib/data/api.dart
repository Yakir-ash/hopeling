// Supabase, hand-rolled (the same surface social.js uses - no SDK lock-in).
// Email OTP sign-in, session persistence with refresh, and the saves table:
// one row, one document, the whole grove (FLUTTER-CONTRACTS.md Contract 1).

import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

const _base = 'https://cpdjabynilymlfouozcc.supabase.co';
const _key = 'sb_publishable_M6ZB-wVDNOvrhzvFE5Fa8A_9jz9L8eL';

class Session {
  String access;
  String refresh;
  final String uid;
  final String email;
  Session(this.access, this.refresh, this.uid, this.email);

  Map<String, dynamic> toJson() =>
      {'a': access, 'r': refresh, 'u': uid, 'e': email};
  factory Session.fromJson(Map<String, dynamic> j) => Session(
      (j['a'] ?? '').toString(),
      (j['r'] ?? '').toString(),
      (j['u'] ?? '').toString(),
      (j['e'] ?? '').toString());
}

class Api {
  static Session? session;
  static bool get signedIn => session != null;

  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('session');
    if (raw != null) {
      try {
        session = Session.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
  }

  static Future<void> _persistSession() async {
    final p = await SharedPreferences.getInstance();
    if (session == null) {
      await p.remove('session');
    } else {
      await p.setString('session', jsonEncode(session!.toJson()));
    }
  }

  static Future<(int, String)> _post(String path, Map<String, dynamic> body,
      {bool auth = false, Map<String, String> headers = const {}}) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    final req = await client.postUrl(Uri.parse('$_base$path'));
    req.headers.set('apikey', _key);
    req.headers.set('content-type', 'application/json');
    if (auth && session != null) {
      req.headers.set('authorization', 'Bearer ${session!.access}');
    }
    headers.forEach(req.headers.set);
    req.write(jsonEncode(body));
    final res = await req.close();
    final text = await res.transform(utf8.decoder).join();
    return (res.statusCode, text);
  }

  static Future<(int, String)> _get(String path, {bool auth = false}) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    final req = await client.getUrl(Uri.parse('$_base$path'));
    req.headers.set('apikey', _key);
    if (auth && session != null) {
      req.headers.set('authorization', 'Bearer ${session!.access}');
    }
    final res = await req.close();
    final text = await res.transform(utf8.decoder).join();
    return (res.statusCode, text);
  }

  /// null on success; a human sentence on failure.
  static Future<String?> requestOtp(String email) async {
    try {
      final (code, _) =
          await _post('/auth/v1/otp', {'email': email, 'create_user': true});
      if (code >= 200 && code < 300) return null;
      return 'The code could not be sent. One more try?';
    } catch (_) {
      return 'The path to the cloud needs a connection. Your grove is safe here meanwhile.';
    }
  }

  static Future<String?> verifyOtp(String email, String token) async {
    try {
      final (code, text) = await _post(
          '/auth/v1/verify', {'type': 'email', 'email': email, 'token': token});
      if (code < 200 || code >= 300) {
        return 'That code did not match. Check the newest email?';
      }
      final j = jsonDecode(text) as Map<String, dynamic>;
      final user = j['user'] as Map<String, dynamic>?;
      session = Session(
          (j['access_token'] ?? '').toString(),
          (j['refresh_token'] ?? '').toString(),
          (user?['id'] ?? '').toString(),
          email);
      await _persistSession();
      return null;
    } catch (_) {
      return 'The path to the cloud needs a connection right now.';
    }
  }

  static Future<bool> _refreshToken() async {
    if (session == null) return false;
    try {
      final (code, text) = await _post(
          '/auth/v1/token?grant_type=refresh_token',
          {'refresh_token': session!.refresh});
      if (code < 200 || code >= 300) return false;
      final j = jsonDecode(text) as Map<String, dynamic>;
      session!.access = (j['access_token'] ?? '').toString();
      session!.refresh =
          (j['refresh_token'] ?? session!.refresh).toString();
      await _persistSession();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// The cloud copy of the one document, or null (none, offline, or unreadable).
  /// `corrupted` distinguishes "no backup" from "backup unreadable".
  static Future<(Map<String, dynamic>?, bool corrupted)> fetchSave() async {
    if (session == null) return (null, false);
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final (code, text) = await _get(
            '/rest/v1/saves?select=data&user_id=eq.${session!.uid}',
            auth: true);
        if (code == 401 && attempt == 0) {
          if (!await _refreshToken()) return (null, false);
          continue;
        }
        if (code < 200 || code >= 300) return (null, false);
        final rows = jsonDecode(text) as List;
        if (rows.isEmpty) return (null, false);
        final data = rows[0]['data'];
        if (data is Map<String, dynamic>) return (data, false);
        return (null, true);
      } catch (_) {
        return (null, false);
      }
    }
    return (null, false);
  }

  static Future<bool> pushSave(Map<String, dynamic> doc) async {
    if (session == null) return false;
    for (var attempt = 0; attempt < 2; attempt++) {
      final (code, _) = await _post(
        '/rest/v1/saves',
        {
          'user_id': session!.uid,
          'data': doc,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        auth: true,
        headers: {'prefer': 'resolution=merge-duplicates'},
      ).catchError((_) => (0, ''));
      if (code == 401 && attempt == 0) {
        if (!await _refreshToken()) return false;
        continue;
      }
      return code >= 200 && code < 300;
    }
    return false;
  }

  /// Local sign-out only: the grove on this phone is untouched.
  static Future<void> signOut() async {
    session = null;
    await _persistSession();
  }
}
