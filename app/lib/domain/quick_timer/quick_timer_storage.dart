import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'quick_timer_models.dart';

/// Локальное хранилище для Quick Timer (JSON-файлы в App Support).
class QuickTimerStorage {
  static const _historyFile = 'quick_timer_history.json';
  static const _groupsFile  = 'quick_timer_groups.json';

  static Future<Directory> _dir() async => getApplicationSupportDirectory();

  // ═══════════════════════════════════════
  // История сессий
  // ═══════════════════════════════════════

  static Future<List<QuickSession>> loadHistory() async {
    try {
      final file = File('${(await _dir()).path}/$_historyFile');
      if (!await file.exists()) return [];
      final raw = await file.readAsString();
      final list = jsonDecode(raw) as List;
      return list.map((j) => QuickSession.fromJson(j as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveSession(QuickSession session) async {
    final history = await loadHistory();
    final idx = history.indexWhere((s) => s.id == session.id);
    if (idx >= 0) {
      history[idx] = session;
    } else {
      history.insert(0, session);
    }
    await _persistHistory(history);
  }

  static Future<void> deleteSession(String sessionId) async {
    final history = await loadHistory();
    history.removeWhere((s) => s.id == sessionId);
    await _persistHistory(history);
  }

  static Future<void> _persistHistory(List<QuickSession> history) async {
    final file = File('${(await _dir()).path}/$_historyFile');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(
      history.map((s) => s.toJson()).toList(),
    ));
  }

  // ═══════════════════════════════════════
  // Сохранённые группы
  // ═══════════════════════════════════════

  static Future<List<SavedGroup>> loadGroups() async {
    try {
      final file = File('${(await _dir()).path}/$_groupsFile');
      if (!await file.exists()) return [];
      final raw = await file.readAsString();
      final list = jsonDecode(raw) as List;
      return list.map((j) => SavedGroup.fromJson(j as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveGroup(SavedGroup group) async {
    final groups = await loadGroups();
    final idx = groups.indexWhere((g) => g.id == group.id);
    if (idx >= 0) {
      groups[idx] = group;
    } else {
      groups.add(group);
    }
    await _persistGroups(groups);
  }

  static Future<void> deleteGroup(String groupId) async {
    final groups = await loadGroups();
    groups.removeWhere((g) => g.id == groupId);
    await _persistGroups(groups);
  }

  static Future<void> _persistGroups(List<SavedGroup> groups) async {
    final file = File('${(await _dir()).path}/$_groupsFile');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(
      groups.map((g) => g.toJson()).toList(),
    ));
  }
}
