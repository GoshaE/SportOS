import 'models.dart';

/// Сервис стартового листа.
///
/// Формирует стартовый лист по конфигурации дисциплины и управляет
/// статусами атлетов (started, DNS, force start).
///
/// Поддерживает 5 режимов старта:
/// - Individual — раздельный с интервалом
/// - Mass — масс-старт (GUN)
/// - Wave — волнами (группы)
/// - Pursuit — преследование (интервал = отставание Day 1)
/// - Relay — эстафета (старт по передаче этапа)
class StartListService {
  final DisciplineConfig _config;
  final List<StartEntry> _entries = [];
  final List<StartWave> _waves;
  int _currentIndex = 0;

  StartListService({
    required DisciplineConfig config,
    List<StartWave> waves = const [],
  })  : _config = config,
        _waves = waves;

  // ─── Build Start List ────────────────────────────────────────

  /// Сформировать стартовый лист из списка атлетов.
  ///
  /// `pursuitGaps` — опционально, для pursuit-старта (bib → gap from day 1).
  void buildStartList(
    List<({String entryId, String bib, String name, String? category, String? waveId})> athletes, {
    Map<String, Duration>? pursuitGaps,
  }) {
    _entries.clear();
    _currentIndex = 0;

    for (var i = 0; i < athletes.length; i++) {
      final a = athletes[i];
      final planned = _calculatePlannedStart(i, a.waveId, pursuitGaps?[a.bib]);

      _entries.add(StartEntry(
        entryId: a.entryId,
        bib: a.bib,
        name: a.name,
        categoryName: a.category,
        waveId: a.waveId,
        startPosition: i,
        plannedStartTime: planned,
        pursuitGap: pursuitGaps?[a.bib],
      ));
    }

    // Для individual: первый стартующий — текущий
    if (_entries.isNotEmpty) {
      _entries[0].status = AthleteStatus.current;
    }
  }

  // ─── Calculate Planned Start ─────────────────────────────────

  DateTime _calculatePlannedStart(int position, String? waveId, Duration? pursuitGap) {
    switch (_config.startType) {
      case StartType.individual:
        // PlannedStart = firstStart + position * interval
        return _config.firstStartTime.add(_config.interval * position);

      case StartType.mass:
        // Все стартуют в одно время
        return _config.firstStartTime;

      case StartType.wave:
        // Найти волну → waveStart + offset внутри волны
        if (waveId != null) {
          final wave = _waves.where((w) => w.id == waveId).firstOrNull;
          if (wave != null) {
            // Позиция внутри волны
            final wavePos = _entries.where((e) => e.waveId == waveId).length;
            return wave.plannedStartTime.add(_config.interval * wavePos);
          }
        }
        // Fallback: как individual
        return _config.firstStartTime.add(_config.interval * position);

      case StartType.pursuit:
        // PlannedStart = leaderStart + pursuitGap
        if (pursuitGap != null) {
          return _config.firstStartTime.add(pursuitGap);
        }
        return _config.firstStartTime;

      case StartType.relay:
        // Первый этап = firstStart, остальные = при передаче
        return _config.firstStartTime;
    }
  }

  // ─── Add Athlete (after build) ───────────────────────────────

  /// Добавить спортсмена в уже сформированный стартовый лист.
  ///
  /// Рассчитывает plannedStartTime на основе текущей позиции в списке.
  void addAthlete({
    required String entryId,
    required String bib,
    required String name,
    String? category,
    String? waveId,
    Duration? pursuitGap,
  }) {
    final position = _entries.length;
    final planned = _calculatePlannedStart(position, waveId, pursuitGap);

    final entry = StartEntry(
      entryId: entryId,
      bib: bib,
      name: name,
      categoryName: category,
      waveId: waveId,
      startPosition: position,
      plannedStartTime: planned,
      pursuitGap: pursuitGap,
    );

    _entries.add(entry);

    // Если это первый атлет — сделать его текущим
    if (_entries.length == 1) {
      _entries[0].status = AthleteStatus.current;
      _currentIndex = 0;
    }
  }

  /// Удалить спортсмена из стартового листа (только если waiting/current).
  void removeAthlete(String bib) {
    final entry = _find(bib);
    if (entry == null) return;
    if (entry.status == AthleteStatus.started) return; // нельзя удалить стартовавшего

    final wasCurrent = entry.status == AthleteStatus.current;
    _entries.remove(entry);

    if (wasCurrent && _entries.isNotEmpty) {
      _advanceToNext();
    }
  }

  // ─── Actions ─────────────────────────────────────────────────

  /// Отметить «Ушёл» — текущий атлет стартовал.
  ///
  /// Для Individual: `actualStartTime` может отличаться от planned.
  /// Для Mass: используется `markStartedAll()`.
  /// [actualTime] must be provided by the caller via [RaceClock.stamp()].
  void markStarted(String bib, {required DateTime actualTime}) {
    final entry = _find(bib);
    if (entry == null) return;

    entry.status = AthleteStatus.started;
    entry.actualStartTime = actualTime;

    // Перейти к следующему (Individual)
    if (_config.startType == StartType.individual || _config.startType == StartType.wave) {
      _advanceToNext();
    }
  }

  /// GUN START — все стартуют одновременно.
  /// [gunTime] must be provided by the caller via [RaceClock.stamp()].
  void markStartedAll({required DateTime gunTime}) {
    for (final e in _entries) {
      if (e.status == AthleteStatus.waiting || e.status == AthleteStatus.current) {
        e.status = AthleteStatus.started;
        e.actualStartTime = gunTime;
        e.plannedStartTime = gunTime; // для mass — planned = actual
      }
    }
    _currentIndex = _entries.length; // все стартовали
  }

  /// DNS — не стартовал.
  void markDns(String bib) {
    final entry = _find(bib);
    if (entry == null) return;

    final wasCurrent = entry.status == AthleteStatus.current;
    entry.status = AthleteStatus.dns;

    if (wasCurrent) {
      _advanceToNext();
    }
  }

  /// Отменить DNS.
  void undoDns(String bib) {
    final entry = _find(bib);
    if (entry == null || entry.status != AthleteStatus.dns) return;

    entry.status = AthleteStatus.waiting;
  }

  /// Принудительный ранний старт.
  /// [actualTime] must be provided by the caller via [RaceClock.stamp()].
  void forceStart(String bib, {required DateTime actualTime}) {
    final entry = _find(bib);
    if (entry == null) return;

    entry.status = AthleteStatus.started;
    entry.actualStartTime = actualTime;
  }

  /// DNF — сход с дистанции (только для started атлетов).
  void markDnf(String bib) {
    final entry = _find(bib);
    if (entry == null) return;
    if (entry.status != AthleteStatus.started) return; // можно снять только на трассе

    entry.status = AthleteStatus.dnf;
  }

  /// Отменить DNF → вернуть на трассу.
  void undoDnf(String bib) {
    final entry = _find(bib);
    if (entry == null || entry.status != AthleteStatus.dnf) return;

    entry.status = AthleteStatus.started;
  }

  /// DSQ — дисквалификация (можно для любого started/finished/dnf).
  void markDsq(String bib) {
    final entry = _find(bib);
    if (entry == null) return;

    entry.status = AthleteStatus.dsq;
  }

  /// Финишировал — все круги пройдены.
  void markFinished(String bib) {
    final entry = _find(bib);
    if (entry == null) return;
    if (entry.status != AthleteStatus.started) return;

    entry.status = AthleteStatus.finished;
  }

  /// Эстафета: передача этапа.
  /// `nextBib` стартует в момент, когда `prevBib` финишировал.
  void relayHandoff(String nextBib, DateTime handoffTime) {
    final entry = _find(nextBib);
    if (entry == null) return;

    entry.status = AthleteStatus.started;
    entry.actualStartTime = handoffTime;
    entry.plannedStartTime = handoffTime;
  }

  // ─── Queries ─────────────────────────────────────────────────

  /// Текущий атлет на старте (Individual/Wave).
  StartEntry? get currentAthlete {
    if (_currentIndex >= _entries.length) return null;
    return _entries[_currentIndex];
  }

  /// Оставшихся (не стартовавших и не DNS).
  int get remaining =>
      _entries.where((e) =>
          e.status == AthleteStatus.waiting || e.status == AthleteStatus.current).length;

  /// Стартовавших.
  int get startedCount =>
      _entries.where((e) => e.status == AthleteStatus.started).length;

  /// Все записи.
  List<StartEntry> get all => List.unmodifiable(_entries);

  /// Конфигурация.
  DisciplineConfig get config => _config;

  /// Найти по BIB.
  StartEntry? findByBib(String bib) => _find(bib);

  // ─── Internal ────────────────────────────────────────────────

  StartEntry? _find(String bib) {
    return _entries.where((e) => e.bib == bib).firstOrNull;
  }

  void _advanceToNext() {
    // Найти следующего waiting
    for (var i = 0; i < _entries.length; i++) {
      if (_entries[i].status == AthleteStatus.waiting) {
        _currentIndex = i;
        _entries[i].status = AthleteStatus.current;
        return;
      }
    }
    _currentIndex = _entries.length; // все прошли
  }
}
