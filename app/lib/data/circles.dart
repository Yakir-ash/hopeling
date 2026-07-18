// Circles - connection without comparison. Small trusted groups on the
// PWA's own backend (create_circle / join_circle RPCs, members rows,
// is_member RLS), so a family spans PWA and native seamlessly. No feed,
// no followers, no ranking: a shared grove that waits, never wilts.

import 'dart:convert';

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/clock.dart';
import 'api.dart';
import 'save.dart';

final circlesTick = ValueNotifier<int>(0);

/// PWA weekKey(), verbatim (unpadded, Jan-1 based) - board parity depends
/// on producing byte-identical keys across platforms.
String weekKey([DateTime? now]) {
  final d = now ?? DateTime.now();
  final oj = DateTime(d.year, 1, 1);
  // JS getDay(): Sunday = 0. Dart weekday: Monday = 1..Sunday = 7.
  final ojDay = oj.weekday % 7;
  final days = d.difference(oj).inDays;
  final w = ((days + ojDay + 1) / 7).ceil();
  return '${d.year}-W$w';
}

class Circle {
  final int id;
  final String name;
  final String code;
  final String type; // family | friends | event (local metadata)
  Circle(this.id, this.name, this.code, {this.type = 'family'});

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'code': code, 'type': type};
  factory Circle.fromJson(Map<String, dynamic> j) => Circle(
      (j['id'] is int) ? j['id'] as int : int.tryParse('${j['id']}') ?? 0,
      (j['name'] ?? '').toString(),
      (j['code'] ?? '').toString(),
      type: (j['type'] ?? 'family').toString());
}

class Member {
  final String userId, name, week;
  final int weekActions, streak, total;
  Member(this.userId, this.name, this.week, this.weekActions, this.streak,
      this.total);
}

class Circles {
  static Future<List<Circle>> mine({bool archived = false}) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(archived ? 'archivedCircles' : 'myCircles');
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => Circle.fromJson(
              (e as Map).map((k, v) => MapEntry(k.toString(), v))))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveList(List<Circle> list,
      {bool archived = false}) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(archived ? 'archivedCircles' : 'myCircles',
        jsonEncode(list.map((c) => c.toJson()).toList()));
    circlesTick.value++;
  }

  static Future<String> displayName() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('displayName') ?? '';
  }

  static Future<void> setDisplayName(String n) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('displayName', n.trim());
  }

  /// Privacy: contribute drops without a readable name.
  static Future<bool> anonymous() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('circleAnon') ?? false;
  }

  static Future<void> setAnonymous(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('circleAnon', v);
  }

  static Future<String> _effectiveName() async =>
      (await anonymous()) ? CircleCopy.anonName : (await displayName());

  /// Create on the shared backend; idempotent locally (no duplicates).
  static Future<(Circle?, String?)> create(String name, String type) async {
    if (!Api.signedIn) return (null, CircleCopy.needAccount);
    try {
      final (code, body) = await Api.rpc('create_circle',
          {'cname': name.trim(), 'dname': await _effectiveName()});
      if (code < 200 || code >= 300) return (null, CircleCopy.trouble);
      final j = jsonDecode(body);
      final row = (j is List && j.isNotEmpty) ? j.first : j;
      final c = Circle(
          (row['id'] is int) ? row['id'] as int : int.parse('${row['id']}'),
          name.trim(),
          (row['code'] ?? '').toString(),
          type: type);
      final list = await mine();
      if (!list.any((x) => x.id == c.id)) {
        list.add(c);
        await _saveList(list);
      }
      return (c, null);
    } catch (_) {
      return (null, CircleCopy.offline);
    }
  }

  static Future<(Circle?, String?)> join(String inviteCode,
      {String type = 'family'}) async {
    if (!Api.signedIn) return (null, CircleCopy.needAccount);
    try {
      final (code, body) = await Api.rpc('join_circle', {
        'ccode': inviteCode.trim().toUpperCase(),
        'dname': await _effectiveName()
      });
      if (code < 200 || code >= 300) return (null, CircleCopy.badCode);
      final j = jsonDecode(body);
      final row = (j is List && j.isNotEmpty) ? j.first : j;
      if (row == null) return (null, CircleCopy.badCode);
      final c = Circle(
          (row['id'] is int) ? row['id'] as int : int.parse('${row['id']}'),
          (row['name'] ?? 'Circle').toString(),
          inviteCode.trim().toUpperCase(),
          type: type);
      final list = await mine();
      if (!list.any((x) => x.id == c.id)) {
        list.add(c);
        await _saveList(list);
      }
      return (c, null);
    } catch (_) {
      return (null, CircleCopy.offline);
    }
  }

  static Future<List<Member>> members(int circleId) async {
    try {
      final (code, body) = await Api.restGet(
          '/rest/v1/members?circle_id=eq.$circleId'
          '&select=user_id,name,week,week_actions,streak,total_actions');
      if (code < 200 || code >= 300) return [];
      return [
        for (final m in jsonDecode(body) as List)
          Member(
              (m['user_id'] ?? '').toString(),
              (m['name'] ?? '').toString(),
              (m['week'] ?? '').toString(),
              (m['week_actions'] is int) ? m['week_actions'] as int : 0,
              (m['streak'] is int) ? m['streak'] as int : 0,
              (m['total_actions'] is int) ? m['total_actions'] as int : 0)
      ];
    } catch (_) {
      return [];
    }
  }

  /// Push my current stats to every circle (the PWA's syncCircles).
  /// Fire-and-forget after any completion; server-authoritative rows.
  static Future<void> syncMine() async {
    if (!Api.signedIn) return;
    final list = await mine();
    if (list.isEmpty) return;
    final s = await Store.load();
    final wk = weekKey();
    var weekDrops = 0;
    s.log.forEach((d, n) {
      if (weekKey(DateTime.parse('${d}T12:00:00')) == wk) weekDrops += n;
    });
    final body = {
      'name': await _effectiveName(),
      'week': wk,
      'week_actions': weekDrops > 1000 ? 1000 : weekDrops,
      'streak': s.streak,
      'total_actions': s.xp,
      'last_action': todayStr(),
    };
    for (final c in list) {
      Api.restSend(
          'PATCH',
          '/rest/v1/members?circle_id=eq.${c.id}'
          '&user_id=eq.${Api.session!.uid}',
          body).catchError((_) => (0, ''));
      Api.rpc('feed_flame', {'cid': c.id}).catchError((_) => (0, ''));
    }
  }

  /// Leave without guilt: personal history stays personal; the row goes.
  static Future<bool> leave(Circle c) async {
    try {
      final (code, _) = await Api.restSend(
          'DELETE',
          '/rest/v1/members?circle_id=eq.${c.id}'
          '&user_id=eq.${Api.session?.uid}',
          null);
      if (code < 200 || code >= 300) return false;
    } catch (_) {
      return false;
    }
    final list = await mine()..removeWhere((x) => x.id == c.id);
    await _saveList(list);
    return true;
  }

  /// Archive locally: read-only memory, restorable, nothing deleted.
  static Future<void> archive(Circle c) async {
    final list = await mine()..removeWhere((x) => x.id == c.id);
    await _saveList(list);
    final arch = await mine(archived: true);
    if (!arch.any((x) => x.id == c.id)) {
      arch.add(c);
      await _saveList(arch, archived: true);
    }
  }

  static Future<void> restore(Circle c) async {
    final arch = await mine(archived: true)
      ..removeWhere((x) => x.id == c.id);
    await _saveList(arch, archived: true);
    final list = await mine();
    if (!list.any((x) => x.id == c.id)) {
      list.add(c);
      await _saveList(list);
    }
  }

  /// A gentle cheer: private, weekly-idempotent by upsert.
  static Future<void> cheer(int circleId, String toUser) async {
    Api.restSend('POST', '/rest/v1/cheers', {
      'circle_id': circleId,
      'to_user': toUser,
      'week': weekKey(),
    }).catchError((_) => (0, ''));
  }
}

// ---------- board math, pure and tested ----------
/// Stale weeks never count (the sim's own rule).
int weekTotal(List<Member> rows, String wk) => [
      for (final m in rows)
        if (m.week == wk) m.weekActions
    ].fold(0, (a, b) => a + b);

int weekParticipants(List<Member> rows, String wk) =>
    rows.where((m) => m.week == wk && m.weekActions > 0).length;

/// The grouped summary: cooperative, never comparative.
String groveSummary(List<Member> rows, String wk) {
  final total = weekTotal(rows, wk);
  final people = weekParticipants(rows, wk);
  if (total == 0) return CircleCopy.quietWeek;
  return '$people ${people == 1 ? 'person' : 'people'} added '
      '$total ${total == 1 ? 'drop' : 'drops'} this week.';
}

class CircleCopy {
  static const anonName = 'A quiet member';
  static const needAccount =
      'Circles live in the cloud - sign in first, and your grove follows.';
  static const trouble = 'The circle could not form just now. One more try?';
  static const badCode =
      'That code did not open a circle. Check it with the person who sent it?';
  static const offline =
      'The cloud is out of reach. Your circle will be here when it returns.';
  static const quietWeek = 'The grove has been quiet this week. It waits.';
  static const firstDrop = 'The first drop of your shared grove.';
  static String invite(String name, String code) =>
      'Join my circle "$name" on Hopeling 🌱 code: $code '
      'or tap: hopeling://circle/invite/$code';
  static const leaveTitle = 'Leave this circle';
  static const leaveBody =
      'Your personal history stays yours. The circle keeps its shared '
      'drops. You can always be invited again.';
  static const left = 'You left quietly. Nothing was broken.';
  static const archived =
      'The circle rests in your history, readable anytime.';
}
