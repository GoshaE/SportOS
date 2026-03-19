import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// DrawResult data that gets persisted.
class DrawResultData {
  final String disciplineId;
  final String status; // 'pending', 'draft', 'approved'
  final List<DrawEntryData> entries;

  const DrawResultData({
    required this.disciplineId,
    this.status = 'pending',
    this.entries = const [],
  });

  DrawResultData copyWith({String? status, List<DrawEntryData>? entries}) =>
      DrawResultData(
        disciplineId: disciplineId,
        status: status ?? this.status,
        entries: entries ?? this.entries,
      );

  Map<String, dynamic> toJson() => {
    'disciplineId': disciplineId,
    'status': status,
    'entries': entries.map((e) => e.toJson()).toList(),
  };

  factory DrawResultData.fromJson(Map<String, dynamic> j) => DrawResultData(
    disciplineId: j['disciplineId'] as String,
    status: j['status'] as String? ?? 'pending',
    entries: (j['entries'] as List? ?? [])
        .map((e) => DrawEntryData.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

/// One participant entry in the draw (no BIB — bib is assigned separately).
class DrawEntryData {
  final int position;
  final String participantId;
  final String name;
  final String gender;
  final String dog;
  final String startTime;
  final String? category;
  final String? city;

  const DrawEntryData({
    required this.position,
    required this.participantId,
    required this.name,
    required this.gender,
    required this.dog,
    required this.startTime,
    this.category,
    this.city,
  });

  DrawEntryData copyWith({int? position, String? startTime}) =>
      DrawEntryData(
        position: position ?? this.position,
        participantId: participantId,
        name: name,
        gender: gender,
        dog: dog,
        startTime: startTime ?? this.startTime,
        category: category,
        city: city,
      );

  Map<String, dynamic> toJson() => {
    'position': position,
    'participantId': participantId,
    'name': name,
    'gender': gender,
    'dog': dog,
    'startTime': startTime,
    'category': category,
    'city': city,
  };

  factory DrawEntryData.fromJson(Map<String, dynamic> j) => DrawEntryData(
    position: j['position'] as int,
    participantId: j['participantId'] as String,
    name: j['name'] as String,
    gender: j['gender'] as String? ?? '?',
    dog: j['dog'] as String? ?? '',
    startTime: j['startTime'] as String? ?? '00:00:00',
    category: j['category'] as String?,
    city: j['city'] as String?,
  );
}

/// Persistence for draw results.
class DrawStorage {
  static const _fileName = 'draw_results.json';

  static Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// Save all draw results to disk.
  static Future<void> save(Map<String, DrawResultData> results) async {
    final file = await _file();
    final map = results.map((k, v) => MapEntry(k, v.toJson()));
    await file.writeAsString(jsonEncode(map));
  }

  /// Load draw results from disk.
  static Future<Map<String, DrawResultData>> load() async {
    try {
      final file = await _file();
      if (!file.existsSync()) return {};
      final raw = await file.readAsString();
      if (raw.isEmpty) return {};
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((k, v) =>
          MapEntry(k, DrawResultData.fromJson(v as Map<String, dynamic>)));
    } catch (_) {
      return {};
    }
  }

  /// Clear all saved draw results.
  static Future<void> clear() async {
    try {
      final file = await _file();
      if (file.existsSync()) await file.delete();
    } catch (_) {
      // ignore
    }
  }
}
