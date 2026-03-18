import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../domain/event/event_config.dart';
import '../domain/timing/models.dart';

// ─────────────────────────────────────────────────────────────────
// CONFIG STORAGE — JSON file persistence for EventConfig
// ─────────────────────────────────────────────────────────────────

class ConfigStorage {
  static const _fileName = 'event_config.json';

  /// Save EventConfig to JSON file.
  static Future<void> save(EventConfig config, List<DisciplineConfig> disciplines) async {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/$_fileName');
    final json = _EventSerializer.toJson(config, disciplines);
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
  }

  /// Load EventConfig from JSON file. Returns null if no saved config.
  static Future<({EventConfig config, List<DisciplineConfig> disciplines})?> load() async {
    try {
      final dir = await getApplicationSupportDirectory();
      final file = File('${dir.path}/$_fileName');
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return _EventSerializer.fromJson(json);
    } catch (e) {
      // Corrupted file — return null, will use defaults
      return null;
    }
  }

  /// Delete saved config.
  static Future<void> clear() async {
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/$_fileName');
    if (await file.exists()) await file.delete();
  }
}

// ─────────────────────────────────────────────────────────────────
// SERIALIZER — converts EventConfig ↔ JSON Map
// ─────────────────────────────────────────────────────────────────

class _EventSerializer {
  static Map<String, dynamic> toJson(EventConfig c, List<DisciplineConfig> disciplines) {
    return {
      'id': c.id,
      'name': c.name,
      'startDate': c.startDate.toIso8601String(),
      'endDate': c.endDate?.toIso8601String(),
      'location': c.location,
      'description': c.description,
      'contactInfo': c.contactInfo,
      'logoUrl': c.logoUrl,
      'status': c.status.name,
      'isMultiDay': c.isMultiDay,
      'scoringMode': c.scoringMode.name,
      'dnfDayPolicy': c.dnfDayPolicy.name,
      'dsqDayPolicy': c.dsqDayPolicy.name,
      'bibDayPolicy': c.bibDayPolicy.name,
      'allowDogSwapBetweenDays': c.allowDogSwapBetweenDays,
      'ageCalculation': c.ageCalculation.name,
      'days': c.days.map(_dayToJson).toList(),
      'courses': c.courses.map(_courseToJson).toList(),
      'timingConfig': _timingToJson(c.timingConfig),
      'drawConfig': _drawToJson(c.drawConfig),
      'disciplines': disciplines.map(_disciplineToJson).toList(),
      'penaltyTemplates': c.penaltyTemplates.map(_penaltyToJson).toList(),
      'registrationDeadline': c.registrationConfig.registrationDeadline?.toIso8601String(),
    };
  }

  static ({EventConfig config, List<DisciplineConfig> disciplines}) fromJson(Map<String, dynamic> j) {
    final config = EventConfig(
      id: j['id'] as String? ?? 'evt-1',
      name: j['name'] as String? ?? '',
      startDate: DateTime.parse(j['startDate'] as String),
      endDate: j['endDate'] != null ? DateTime.parse(j['endDate'] as String) : null,
      location: j['location'] as String?,
      description: j['description'] as String?,
      contactInfo: j['contactInfo'] as String?,
      logoUrl: j['logoUrl'] as String?,
      status: _enumFromName(EventStatus.values, j['status'] as String?, EventStatus.draft),
      isMultiDay: j['isMultiDay'] as bool? ?? false,
      scoringMode: _enumFromName(ScoringMode.values, j['scoringMode'] as String?, ScoringMode.cumulative),
      dnfDayPolicy: _enumFromName(DayPolicy.values, j['dnfDayPolicy'] as String?, DayPolicy.penalized),
      dsqDayPolicy: _enumFromName(DayPolicy.values, j['dsqDayPolicy'] as String?, DayPolicy.strict),
      bibDayPolicy: _enumFromName(BibDayPolicy.values, j['bibDayPolicy'] as String?, BibDayPolicy.keep),
      allowDogSwapBetweenDays: j['allowDogSwapBetweenDays'] as bool? ?? false,
      ageCalculation: _enumFromName(AgeCalculation.values, j['ageCalculation'] as String?, AgeCalculation.byYear),
      days: (j['days'] as List?)?.map((d) => _dayFromJson(d as Map<String, dynamic>)).toList() ?? [],
      courses: (j['courses'] as List?)?.map((c) => _courseFromJson(c as Map<String, dynamic>)).toList() ?? [],
      timingConfig: j['timingConfig'] != null ? _timingFromJson(j['timingConfig'] as Map<String, dynamic>) : const TimingConfig(),
      drawConfig: j['drawConfig'] != null ? _drawFromJson(j['drawConfig'] as Map<String, dynamic>) : const DrawConfig(),
      penaltyTemplates: (j['penaltyTemplates'] as List?)?.map((p) => _penaltyFromJson(p as Map<String, dynamic>)).toList() ?? defaultPenaltyTemplates,
      registrationConfig: RegistrationConfig(
        registrationDeadline: j['registrationDeadline'] != null ? DateTime.parse(j['registrationDeadline'] as String) : null,
      ),
    );
    final disciplines = (j['disciplines'] as List?)?.map((d) => _disciplineFromJson(d as Map<String, dynamic>)).toList() ?? [];
    return (config: config, disciplines: disciplines);
  }

  // ── RaceDay ──
  static Map<String, dynamic> _dayToJson(RaceDay d) => {
    'dayNumber': d.dayNumber,
    'date': d.date.toIso8601String(),
    'disciplineIds': d.disciplineIds,
    'startOrder': d.startOrder.name,
    'startTimeH': d.startTime.hour,
    'startTimeM': d.startTime.minute,
    'vetCheck': d.vetCheck,
  };

  static RaceDay _dayFromJson(Map<String, dynamic> j) => RaceDay(
    dayNumber: j['dayNumber'] as int,
    date: DateTime.parse(j['date'] as String),
    disciplineIds: (j['disciplineIds'] as List).cast<String>(),
    startOrder: _enumFromName(StartOrder.values, j['startOrder'] as String?, StartOrder.draw),
    startTime: TimeOfDay(hour: j['startTimeH'] as int? ?? 10, minute: j['startTimeM'] as int? ?? 0),
    vetCheck: j['vetCheck'] as bool? ?? true,
  );

  // ── Course ──
  static Map<String, dynamic> _courseToJson(Course c) => {
    'id': c.id,
    'name': c.name,
    'distanceKm': c.distanceKm,
    'gpxPath': c.gpxPath,
    'elevationGainM': c.elevationGainM,
    'description': c.description,
    'checkpoints': c.checkpoints.map((cp) => {
      'id': cp.id, 'name': cp.name, 'distanceKm': cp.distanceKm, 'order': cp.order,
    }).toList(),
  };

  static Course _courseFromJson(Map<String, dynamic> j) => Course(
    id: j['id'] as String,
    name: j['name'] as String,
    distanceKm: (j['distanceKm'] as num).toDouble(),
    gpxPath: j['gpxPath'] as String?,
    elevationGainM: j['elevationGainM'] as int?,
    description: j['description'] as String?,
    checkpoints: (j['checkpoints'] as List?)?.map((cp) => CheckpointDef(
      id: (cp as Map<String, dynamic>)['id'] as String,
      name: cp['name'] as String,
      distanceKm: (cp['distanceKm'] as num?)?.toDouble(),
      order: cp['order'] as int,
    )).toList() ?? [],
  );

  // ── TimingConfig ──
  static Map<String, dynamic> _timingToJson(TimingConfig t) => {
    'precision': t.precision.name,
    'timeFormat': t.timeFormat,
    'dualTiming': t.dualTiming,
    'gpsTracking': t.gpsTracking,
    'auditLog': t.auditLog,
    'doubleDnfConfirm': t.doubleDnfConfirm,
    'photoFinish': t.photoFinish,
  };

  static TimingConfig _timingFromJson(Map<String, dynamic> j) => TimingConfig(
    precision: _enumFromName(TimingPrecision.values, j['precision'] as String?, TimingPrecision.tenths),
    timeFormat: j['timeFormat'] as String? ?? 'HH:mm:ss.S',
    dualTiming: j['dualTiming'] as bool? ?? false,
    gpsTracking: j['gpsTracking'] as bool? ?? false,
    auditLog: j['auditLog'] as bool? ?? true,
    doubleDnfConfirm: j['doubleDnfConfirm'] as bool? ?? true,
    photoFinish: j['photoFinish'] as bool? ?? false,
  );

  // ── DrawConfig ──
  static Map<String, dynamic> _drawToJson(DrawConfig d) => {
    'mode': d.mode.name,
    'grouping': d.grouping.name,
    'bufferMinutes': d.bufferMinutes,
    'onlyApproved': d.onlyApproved,
  };

  static DrawConfig _drawFromJson(Map<String, dynamic> j) => DrawConfig(
    mode: _enumFromName(DrawMode.values, j['mode'] as String?, DrawMode.auto),
    grouping: _enumFromName(DrawGrouping.values, j['grouping'] as String?, DrawGrouping.joint),
    bufferMinutes: j['bufferMinutes'] as int? ?? 5,
    onlyApproved: j['onlyApproved'] as bool? ?? true,
  );

  // ── DisciplineConfig ──
  static Map<String, dynamic> _disciplineToJson(DisciplineConfig d) => {
    'id': d.id,
    'name': d.name,
    'distanceKm': d.distanceKm,
    'startType': d.startType.name,
    'intervalSec': d.interval.inSeconds,
    'firstStartTime': d.firstStartTime.toIso8601String(),
    'laps': d.laps,
    'minLapTimeSec': d.minLapTime.inSeconds,
    'cutoffTimeSec': d.cutoffTime?.inSeconds,
    'tieBreakMode': d.tieBreakMode,
    'bufferBetweenWavesSec': d.bufferBetweenWaves.inSeconds,
    'manualStart': d.manualStart,
    'courseId': d.courseId,
    'dayNumber': d.dayNumber,
    'maxParticipants': d.maxParticipants,
    'categories': d.categories,
    'priceRub': d.priceRub,
    'lapLengthM': d.lapLengthM,
  };

  static DisciplineConfig _disciplineFromJson(Map<String, dynamic> j) => DisciplineConfig(
    id: j['id'] as String,
    name: j['name'] as String,
    distanceKm: (j['distanceKm'] as num).toDouble(),
    startType: _enumFromName(StartType.values, j['startType'] as String?, StartType.individual),
    interval: Duration(seconds: j['intervalSec'] as int? ?? 30),
    firstStartTime: DateTime.parse(j['firstStartTime'] as String),
    laps: j['laps'] as int? ?? 1,
    minLapTime: Duration(seconds: j['minLapTimeSec'] as int? ?? 20),
    cutoffTime: j['cutoffTimeSec'] != null ? Duration(seconds: j['cutoffTimeSec'] as int) : null,
    tieBreakMode: j['tieBreakMode'] as String? ?? 'shared',
    bufferBetweenWaves: Duration(seconds: j['bufferBetweenWavesSec'] as int? ?? 0),
    manualStart: j['manualStart'] as bool? ?? false,
    courseId: j['courseId'] as String?,
    dayNumber: j['dayNumber'] as int?,
    maxParticipants: j['maxParticipants'] as int?,
    categories: (j['categories'] as List?)?.cast<String>() ?? [],
    priceRub: j['priceRub'] as int?,
    lapLengthM: j['lapLengthM'] as int?,
  );

  // ── PenaltyTemplate ──
  static Map<String, dynamic> _penaltyToJson(PenaltyTemplate p) => {
    'id': p.id,
    'code': p.code,
    'description': p.description,
    'timePenaltySec': p.timePenalty?.inSeconds,
    'sortOrder': p.sortOrder,
  };

  static PenaltyTemplate _penaltyFromJson(Map<String, dynamic> j) => PenaltyTemplate(
    id: j['id'] as String,
    code: j['code'] as String,
    description: j['description'] as String,
    timePenalty: j['timePenaltySec'] != null ? Duration(seconds: j['timePenaltySec'] as int) : null,
    sortOrder: j['sortOrder'] as int? ?? 0,
  );

  // ── Helper ──
  static T _enumFromName<T extends Enum>(List<T> values, String? name, T defaultValue) {
    if (name == null) return defaultValue;
    return values.firstWhere((e) => e.name == name, orElse: () => defaultValue);
  }
}
