import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import 'package:sportos_app/core/widgets/widgets.dart';
import 'package:sportos_app/domain/timing/timing.dart';

/// Посты хронометража — выбор роли.
///
/// При открытии инициализирует [RaceSession] (единое состояние гонки).
/// Все вложенные экраны (Стартёр, Финиш, Маршал, Диктор) читают из него.
class OpsTimingHubScreen extends ConsumerStatefulWidget {
  final String eventId;

  const OpsTimingHubScreen({super.key, required this.eventId});

  @override
  ConsumerState<OpsTimingHubScreen> createState() => _OpsTimingHubScreenState();
}

class _OpsTimingHubScreenState extends ConsumerState<OpsTimingHubScreen> {

  @override
  void initState() {
    super.initState();
    // Инициализировать RaceSession если ещё нет
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureSession();
    });
  }

  void _ensureSession() {
    final session = ref.read(raceSessionProvider);
    if (session != null) return; // уже инициализирована

    // TODO: загружать из БД (Drift) по eventId
    // Сейчас — мок-данные для демо
    final raceStart = DateTime.now().add(const Duration(minutes: 5));

    final config = DisciplineConfig(
      id: 'disc-${widget.eventId}',
      name: 'Скиджоринг 6 км',
      distanceKm: 6.0,
      startType: StartType.individual,
      interval: const Duration(seconds: 30),
      firstStartTime: raceStart,
      laps: 2,
      minLapTime: const Duration(seconds: 20),
    );

    ref.read(raceSessionProvider.notifier).startSession(config, [
      (entryId: 'e1', bib: '07', name: 'Петров А.А.', category: 'Скидж.', waveId: null),
      (entryId: 'e2', bib: '12', name: 'Сидоров Б.Б.', category: 'Скидж.', waveId: null),
      (entryId: 'e3', bib: '24', name: 'Иванов В.В.', category: 'Нарты', waveId: null),
      (entryId: 'e4', bib: '31', name: 'Козлов В.В.', category: 'Нарты', waveId: null),
      (entryId: 'e5', bib: '42', name: 'Морозов Д.Д.', category: 'Скидж.', waveId: null),
      (entryId: 'e6', bib: '55', name: 'Волков Е.Е.', category: 'Пулка', waveId: null),
      (entryId: 'e7', bib: '63', name: 'Лебедев С.С.', category: 'Скидж.', waveId: null),
      (entryId: 'e8', bib: '77', name: 'Новиков З.З.', category: 'Нарты', waveId: null),
      (entryId: 'e9', bib: '88', name: 'Кузнецов П.П.', category: 'Скидж.', waveId: null),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final session = ref.watch(raceSessionProvider);
    final eventId = widget.eventId;

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Посты Хронометража'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Session info
          if (session != null) ...[
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              backgroundColor: cs.primaryContainer.withValues(alpha: 0.15),
              borderColor: cs.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
              children: [
                Row(children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    '${session.config.name} · ${session.startList.all.length} участников · ${session.config.laps} круга',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.primary),
                  )),
                ]),
              ],
            ),
            const SizedBox(height: 8),
          ],

          Text(
            'Выберите вашу роль на текущую смену. Данные синхронизируются между всеми постами.',
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          _buildPostCard(
            context, cs, theme,
            title: 'Стартёр (Выпуск)',
            desc: 'Управление стартовыми интервалами, фиксация DNS, масс-старты.',
            icon: Icons.flag,
            color: cs.primary,
            route: '/ops/$eventId/timing/starter',
          ),
          _buildPostCard(
            context, cs, theme,
            title: 'Судья на Финише',
            desc: 'Фиксация точного времени финиша, работа с Мастер-Нодой.',
            icon: Icons.sports_score,
            color: cs.tertiary,
            route: '/ops/$eventId/timing/finish',
          ),
          _buildPostCard(
            context, cs, theme,
            title: 'Маршал (Чекпоинт)',
            desc: 'Фиксация сплитов (отсечек) на трассе, контроль прохождения.',
            icon: Icons.location_on,
            color: cs.secondary,
            route: '/ops/$eventId/timing/marshal',
          ),
          _buildPostCard(
            context, cs, theme,
            title: 'Диктор',
            desc: 'ТОП-5, подсказки, карточки атлетов — информация для трансляции.',
            icon: Icons.mic,
            color: cs.error,
            route: '/ops/$eventId/timing/dictator',
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(
    BuildContext context, ColorScheme cs, ThemeData theme, {
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required String route,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.go(route),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 3),
                    Text(desc, style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: cs.onSurfaceVariant, size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
