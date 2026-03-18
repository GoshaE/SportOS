import 'dart:async';

import 'models.dart';
import 'race_clock.dart';
import 'start_list_service.dart';

// ─────────────────────────────────────────────────────────────────
// RACE SCHEDULER
// ─────────────────────────────────────────────────────────────────

/// Domain-level scheduler that runs independently of UI.
///
/// Checks [plannedStartTime] for all waiting athletes every [interval]
/// and fires [onAutoStart] when an athlete's start time has passed.
///
/// Lifecycle:
///   - Created by [RaceSessionNotifier.startSession()]
///   - Disposed by [RaceSessionNotifier.endSession()]
///
/// This ensures auto-starts happen even when the user is on
/// a different screen (Results, Marshal, Coach, etc.).
class RaceScheduler {
  final RaceClock clock;
  final StartListService startList;
  final DisciplineConfig config;

  /// Called when scheduler auto-starts an athlete.
  /// The callback should call [RaceSessionNotifier.markStarted]
  /// and then [RaceSessionNotifier._notify] to trigger rebuilds.
  final void Function(String bib, DateTime actualTime) onAutoStart;

  /// Called when an athlete exceeds cutoff time → auto-DNF.
  final void Function(String bib)? onCutoffDnf;

  Timer? _timer;

  /// How often to check for pending auto-starts.
  final Duration interval;

  RaceScheduler({
    required this.clock,
    required this.startList,
    required this.config,
    required this.onAutoStart,
    this.onCutoffDnf,
    this.interval = const Duration(milliseconds: 500),
  });

  /// Start the scheduler. Only auto-starts in individual start mode
  /// when [DisciplineConfig.manualStart] is false.
  void start() {
    // Scheduler always runs — also handles cutoff checks
    if (config.startType == StartType.individual && !config.manualStart) {
      _timer = Timer.periodic(interval, _tick);
    } else if (config.cutoffTime != null) {
      // Even for mass/wave — run for cutoff checks only
      _timer = Timer.periodic(interval, _tick);
    }
  }

  void _tick(Timer _) {
    final now = clock.now;

    // ── Auto-start (individual, non-manual only) ──
    if (config.startType == StartType.individual && !config.manualStart) {
      for (final a in startList.all) {
        if ((a.status == AthleteStatus.waiting || a.status == AthleteStatus.current) &&
            !a.plannedStartTime.isAfter(now)) {
          onAutoStart(a.bib, a.plannedStartTime);
        }
      }
    }

    // ── Cutoff enforcement ──
    final cutoff = config.cutoffTime;
    if (cutoff != null && onCutoffDnf != null) {
      for (final a in startList.all) {
        if (a.status == AthleteStatus.started) {
          final elapsed = now.difference(a.effectiveStartTime);
          if (elapsed > cutoff) {
            onCutoffDnf!(a.bib);
          }
        }
      }
    }
  }

  /// Stop the scheduler and release the timer.
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  /// Whether the scheduler is actively running.
  bool get isActive => _timer?.isActive ?? false;
}
