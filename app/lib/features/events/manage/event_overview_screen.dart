import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../../domain/event/config_providers.dart';
import '../../../domain/event/event_config.dart';
import '../../../domain/timing/models.dart';
import 'widgets/event_hero_card.dart';

/// Screen ID: E1 — Обзор мероприятия (Организатор Dashboard)
class EventOverviewScreen extends ConsumerWidget {
  const EventOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final eventId = GoRouterState.of(context).pathParameters['eventId'] ?? 'evt-1';

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: cs.surfaceContainerLowest, // Lighter background for dashboard feel
        appBar: AppAppBar(
          forceBackButton: true,
          onBackButtonPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/my');
            }
          },
          title: Text(ref.watch(eventConfigProvider).name),
          actions: [
            IconButton(icon: const Icon(Icons.share), onPressed: () {}),
          ],
          bottom: AppPillTabBar(
            isScrollable: true,
            tabs: const ['Обзор', 'Настройки', 'Ресурсы'],
          ),
        ),
        body: TabBarView(
          children: [
            _buildDashboardTab(context, cs, isDark, eventId, theme, ref),
            _buildSetupTab(context, cs, isDark, eventId, theme, ref),
            _buildManagementTab(context, cs, isDark, eventId, theme),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // ТАБ 1: Обзор (Dashboard)
  // ===========================================================================
  Widget _buildDashboardTab(BuildContext context, ColorScheme cs, bool isDark, String eventId, ThemeData theme, WidgetRef ref) {
    final participants = ref.watch(participantsProvider);
    final totalParticipants = participants.length;
    final bibAssigned = participants.where((p) => p.bib.isNotEmpty).length;
    final vetPassed = participants.where((p) => p.vetStatus == VetStatus.passed).length;
    final mandatePassed = participants.where((p) => p.mandateStatus == MandateStatus.passed).length;

    // Checklist items — computed from real participant data
    final drawDone = participants.where((p) => p.startPosition != null).length;
    final startListDone = participants.where((p) => p.startPosition != null && p.bib.isNotEmpty).length;

    final checkItems = [
      _CheckItem('Жеребьёвка', totalParticipants == 0 ? 'Нет участников' : '$drawDone из $totalParticipants', drawDone, totalParticipants, Icons.shuffle, '/manage/$eventId/draw'),
      _CheckItem('Стартовый лист', totalParticipants == 0 ? 'Нет участников' : '$startListDone из $totalParticipants', startListDone, totalParticipants, Icons.format_list_numbered, '/manage/$eventId/startlist'),
      _CheckItem('BIB номера', totalParticipants == 0 ? 'Нет участников' : '$bibAssigned из $totalParticipants', bibAssigned, totalParticipants, Icons.confirmation_number, '/manage/$eventId/bibs'),
      _CheckItem('Ветконтроль', totalParticipants == 0 ? 'Нет участников' : '$vetPassed из $totalParticipants', vetPassed, totalParticipants, Icons.pets, '/manage/$eventId/vetcheck'),
      _CheckItem('Мандатная комиссия', totalParticipants == 0 ? 'Нет участников' : '$mandatePassed из $totalParticipants', mandatePassed, totalParticipants, Icons.assignment_turned_in, '/manage/$eventId/mandate'),
    ];
    final doneCount = checkItems.where((c) => c.done == c.total && c.total > 0).length;
    final totalChecks = checkItems.length;
    final overallProgress = totalChecks > 0 ? doneCount / totalChecks : 0.0;


    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      children: [
        // ═══ HERO CARD ═══
        const EventHeroCard(),
        const SizedBox(height: 16),

        // ═══ ACTION BUTTONS (real buttons, 2×2 grid) ═══
        Row(children: [
          Expanded(child: _actionButton(context, cs, Icons.qr_code_scanner, 'Чек-ин', () => context.push('/manage/$eventId/checkin'))),
          const SizedBox(width: 8),
          Expanded(child: _actionButton(context, cs, Icons.format_list_numbered, 'Старт-лист', () => context.push('/manage/$eventId/startlist'))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _actionButton(context, cs, Icons.people, 'Участники', () => context.push('/manage/$eventId/participants'))),
          const SizedBox(width: 8),
          Expanded(child: _actionButton(context, cs, Icons.campaign, 'Push-уведомление', () => _showAnnouncementsModal(context, cs))),
        ]),
        const SizedBox(height: 28),

        // ─── Preparation Progress ───
        Row(children: [
          Expanded(child: Text('Подготовка к старту', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurfaceVariant))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: overallProgress == 1.0 ? const Color(0xFF2E7D32).withOpacity(0.15) : cs.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              overallProgress == 1.0 ? '✓ Готово' : '$doneCount из $totalChecks',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: overallProgress == 1.0 ? const Color(0xFF2E7D32) : cs.primary),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: overallProgress,
            minHeight: 6,
            backgroundColor: cs.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation(overallProgress == 1.0 ? const Color(0xFF2E7D32) : cs.primary),
          ),
        ),
        const SizedBox(height: 14),

        // ─── Checklist ───
        ...checkItems.map((item) => _checklistCard(context, cs, isDark, item)),

        const SizedBox(height: 48),
      ],
    );
  }



  // ─── Action Button ───
  Widget _actionButton(BuildContext context, ColorScheme cs, IconData icon, String label, VoidCallback onTap) {
    return AppButton.smallSecondary(
      text: label,
      icon: icon,
      onPressed: onTap,
    );
  }

  // ===========================================================================
  // ТАБ 2: Настройки (Setup)
  // ===========================================================================
  Widget _buildSetupTab(BuildContext context, ColorScheme cs, bool isDark, String eventId, ThemeData theme, WidgetRef ref) {
    final eventConfig = ref.watch(eventConfigProvider);
    final disciplines = ref.watch(disciplineConfigsProvider);
    final courses = ref.watch(coursesProvider);

    // Summaries computed from providers
    final discSummary = disciplines.take(3).map((d) => d.name.split(' ').first).join(', ')
        + (disciplines.length > 3 ? '…' : '');

    final multiDaySummary = eventConfig.isMultiDay
        ? '${eventConfig.days.length} дн., ${switch (eventConfig.scoringMode) {
            ScoringMode.cumulative => 'суммарный',
            ScoringMode.perDay => 'по дням',
            ScoringMode.pursuit => 'преследование',
          }}'
        : 'Однодневное';

    final coursesSummary = courses.take(3).map((c) => c.name).join(', ')
        + (courses.length > 3 ? '…' : '');

    final cpCount = courses.fold<int>(0, (sum, c) => sum + c.checkpoints.length);

    final statusLabel = switch (eventConfig.status) {
      EventStatus.draft => 'Черновик',
      EventStatus.registrationOpen => 'Регистрация открыта',
      EventStatus.registrationClosed => 'Регистрация закрыта',
      EventStatus.inProgress => 'В процессе',
      EventStatus.completed => 'Завершено',
      EventStatus.archived => 'Архив',
    };
    
    const months = ['янв', 'фев', 'мар', 'апр', 'май', 'июн', 'июл', 'авг', 'сен', 'окт', 'ноя', 'дек'];
    final dateSummary = '${eventConfig.startDate.day} ${months[eventConfig.startDate.month - 1]}'
        '${eventConfig.endDate != null ? ' — ${eventConfig.endDate!.day} ${months[eventConfig.endDate!.month - 1]}' : ''}';

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        // ─── Основное ───
        AppMenuGroup(title: 'Основное', items: [
          AppMenuItem(
            icon: Icons.info_outline,
            label: eventConfig.name,
            subtitle: '$dateSummary · ${eventConfig.location ?? 'Не указано'}',
            badge: statusLabel,
            color: cs.primary,
            onTap: () => context.push('/manage/$eventId/basic-info'),
          ),
        ]),
        const SizedBox(height: 24),

        // ─── Регламент ───
        AppMenuGroup(title: 'Регламент', items: [
          AppMenuItem(
            icon: Icons.sports,
            label: 'Дисциплины и классы',
            badge: '${disciplines.length}',
            subtitle: discSummary,
            color: cs.primary,
            onTap: () => context.push('/manage/$eventId/disciplines'),
          ),
          AppMenuItem(
            icon: Icons.view_timeline,
            label: 'Расписание',
            badge: '${disciplines.length} стартов',
            subtitle: _scheduleSummary(disciplines),
            color: const Color(0xFF00838F),
            onTap: () => context.push('/manage/$eventId/schedule'),
          ),
          AppMenuItem(
            icon: Icons.calendar_month,
            label: 'Многодневность',
            badge: eventConfig.isMultiDay ? '${eventConfig.days.length} дн.' : 'Выкл',
            subtitle: multiDaySummary,
            color: cs.tertiary,
            onTap: () => context.push('/manage/$eventId/multiday'),
          ),
          AppMenuItem(
            icon: Icons.route,
            label: 'Трассы',
            badge: '${courses.length}',
            subtitle: coursesSummary.isNotEmpty ? '$coursesSummary · $cpCount КП' : 'Нет трасс',
            color: cs.secondary,
            onTap: () => context.push('/manage/$eventId/courses'),
          ),
        ]),
        const SizedBox(height: 24),

        // ─── Система ───
        AppMenuGroup(title: 'Система', items: [
          AppMenuItem(
            icon: Icons.table_chart,
            label: 'Отображение таблиц',
            subtitle: _displaySummary(disciplines),
            color: cs.primary,
            onTap: () => context.push('/manage/$eventId/display'),
          ),
          AppMenuItem(
            icon: Icons.timer,
            label: 'Хронометраж',
            subtitle: '0.001с, двойной хрон.',
            color: cs.secondary,
            onTap: () => context.push('/manage/$eventId/timing-settings'),
          ),
          AppMenuItem(
            icon: Icons.pets,
            label: 'Ветконтроль',
            subtitle: eventConfig.allowDogSwapBetweenDays ? 'Замена собак разрешена' : 'Обязательный',
            color: cs.tertiary,
            onTap: () => context.push('/manage/$eventId/vet'),
          ),
          AppMenuItem(
            icon: Icons.checklist,
            label: 'Предстартовый чек-лист',
            badge: '${eventConfig.checklistItems.length} пунктов',
            color: cs.secondary,
            onTap: () => context.push('/manage/$eventId/checklist'),
          ),
        ]),
        const SizedBox(height: 24),

        // ─── Участники ───
        AppMenuGroup(title: 'Участники', items: [
          AppMenuItem(
            icon: Icons.category,
            label: 'Категории',
            badge: eventConfig.raceCategories.isEmpty ? 'Не настроено' : '${eventConfig.raceCategories.length} категорий',
            subtitle: eventConfig.raceCategories.isEmpty
                ? 'CEC, OPEN, Юниоры…'
                : eventConfig.raceCategories.map((c) => c.shortName).take(4).join(', '),
            color: const Color(0xFF00838F),
            onTap: () => context.push('/manage/$eventId/categories'),
          ),
          AppMenuItem(
            icon: Icons.confirmation_number,
            label: 'Стартовые номера (BIB)',
            badge: eventConfig.bibPools.isEmpty ? 'Не настроено' : '${eventConfig.bibPools.length} пулов',
            subtitle: eventConfig.bibPools.isEmpty
                ? 'Настройте пулы номеров'
                : eventConfig.bibPools.map((p) => '${p.rangeStart}–${p.rangeEnd}').join(', '),
            color: const Color(0xFF6A1B9A),
            onTap: () => context.push('/manage/$eventId/bibs'),
          ),
          AppMenuItem(
            icon: Icons.app_registration,
            label: 'Регистрация',
            subtitle: 'Открыта, 60 слотов',
            color: cs.primary,
            onTap: () => context.push('/manage/$eventId/registration-settings'),
          ),
          AppMenuItem(
            icon: Icons.casino,
            label: 'Жеребьёвка',
            subtitle: 'Авто, по категориям',
            color: cs.secondary,
            onTap: () => context.push('/manage/$eventId/draw-settings'),
          ),
        ]),
        const SizedBox(height: 48),
      ],
    );
  }

  /// Краткая сводка DisplaySettings: какие колонки включены
  String _scheduleSummary(List<DisciplineConfig> disciplines) {
    if (disciplines.isEmpty) return 'Нет стартов';
    final sorted = List.of(disciplines)..sort((a, b) => a.firstStartTime.compareTo(b.firstStartTime));
    final first = sorted.first.firstStartTime;
    final last = sorted.fold<DateTime>(first, (max, d) {
      final end = d.firstStartTime.add(d.cutoffTime ?? const Duration(hours: 2));
      return end.isAfter(max) ? end : max;
    });
    return '${first.hour.toString().padLeft(2, '0')}:${first.minute.toString().padLeft(2, '0')} – '
        '${last.hour.toString().padLeft(2, '0')}:${last.minute.toString().padLeft(2, '0')}';
  }

  String _displaySummary(List<DisciplineConfig> disciplines) {
    if (disciplines.isEmpty) return 'Нет дисциплин';
    final ds = disciplines.first.displaySettings;
    final parts = <String>[];
    if (ds.showLapSplits) parts.add('сплиты');
    if (ds.showCheckpoints) parts.add('КП');
    if (ds.showSpeed) parts.add('скорость');
    if (ds.showDogNames) parts.add('собаки');
    if (parts.isEmpty) parts.add('базовый');
    return parts.join(', ');
  }

  // ===========================================================================
  // ТАБ 3: Ресурсы (Management)
  // ===========================================================================
  Widget _buildManagementTab(BuildContext context, ColorScheme cs, bool isDark, String eventId, ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      children: [
        AppMenuGroup(title: 'Организация', items: [
          AppMenuItem(icon: Icons.payments, label: 'Финансы и сборы', badge: '157.5К', color: cs.primary, onTap: () => context.push('/manage/$eventId/finances')),
          AppMenuItem(icon: Icons.people, label: 'Участники', badge: '48 чел', color: cs.secondary, onTap: () => context.push('/manage/$eventId/participants')),
          AppMenuItem(icon: Icons.badge, label: 'Команда организаторов', badge: '5 чел', color: cs.secondary, onTap: () => context.push('/manage/$eventId/team')),
          AppMenuItem(icon: Icons.description, label: 'Документы и положения', badge: '4', color: cs.onSurfaceVariant, onTap: () => context.push('/manage/$eventId/documents')),
        ]),
        const SizedBox(height: 24),

        // Post-race: Results & Ceremonies (Highlighted)
        Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [cs.primary.withOpacity(0.3), cs.secondary.withOpacity(0.3)]),
            borderRadius: BorderRadius.circular(22),
          ),
          child: _buildGlassCard(
            cs: cs,
            isDark: isDark,
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppMenuGroup(title: 'Итоги и награждение', items: [
                  AppMenuItem(icon: Icons.leaderboard, label: 'Live результаты и сплиты', color: cs.primary, onTap: () => context.push('/results/$eventId/live')),
                  AppMenuItem(icon: Icons.article, label: 'Официальные протоколы', color: cs.secondary, onTap: () => context.push('/results/$eventId/protocol')),
                  AppMenuItem(icon: Icons.gavel, label: 'Протесты и апелляции', badge: '0', color: cs.tertiary, onTap: () => context.push('/results/$eventId/protests')),
                  AppMenuItem(icon: Icons.workspace_premium, label: 'Генерация дипломов', color: cs.primary, onTap: () => context.push('/results/$eventId/diplomas')),
                ]),
              ],
            ),
          ),
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  // ===========================================================================
  // Вспомогательные виджеты
  // ===========================================================================

  Widget _buildGlassCard({
    required ColorScheme cs,
    required bool isDark,
    double? height,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    BorderRadiusGeometry? borderRadius,
    Gradient? gradient,
    required Widget child,
  }) {
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: gradient != null ? null : (isDark ? cs.surfaceContainerHigh.withOpacity(0.5) : Colors.white.withOpacity(0.9)),
        gradient: gradient,
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        border: Border.all(
          color: gradient != null ? Colors.transparent : (isDark ? Colors.white.withOpacity(0.1) : cs.outlineVariant.withOpacity(0.3)),
          width: 1,
        ),
        boxShadow: gradient != null ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }




  // ─── Checklist Card ───
  Widget _checklistCard(BuildContext context, ColorScheme cs, bool isDark, _CheckItem item) {
    final isDone = item.done == item.total && item.total > 0;
    final isPartial = item.done > 0 && item.done < item.total;
    final progress = item.total > 0 ? item.done / item.total : 0.0;

    final statusColor = isDone ? const Color(0xFF2E7D32) : isPartial ? cs.tertiary : cs.onSurfaceVariant;
    final bgColor = isDone ? const Color(0xFF2E7D32).withOpacity(0.05) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: bgColor ?? (isDark ? cs.surfaceContainerHigh.withOpacity(0.3) : Colors.white.withOpacity(0.8)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withOpacity(isDone ? 0.25 : 0.1)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push(item.route),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            // Icon
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isDone ? Icons.check_circle : item.icon,
                size: 20,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 12),
            // Title + subtitle + mini progress
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, style: TextStyle(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
                decoration: isDone ? TextDecoration.lineThrough : null,
                decorationColor: cs.onSurfaceVariant,
              )),
              const SizedBox(height: 2),
              Text(item.subtitle, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              if (!isDone && item.total > 1) ...[  
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3,
                    backgroundColor: cs.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(statusColor),
                  ),
                ),
              ],
            ])),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 20, color: cs.onSurfaceVariant.withOpacity(0.4)),
          ]),
        ),
      ),
    );
  }

  void _showAnnouncementsModal(BuildContext context, ColorScheme cs) {
    AppBottomSheet.show(
      context,
      title: 'Push-уведомления',
      initialHeight: 0.85,
      actions: [
        AppButton.primary(
          text: 'Отправить Push-уведомление',
          icon: Icons.send,
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
            AppSnackBar.success(context, 'Уведомление отправлено');
          },
        ),
      ],
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Массовая рассылка важных сообщений', style: TextStyle(color: cs.onSurfaceVariant)),
        const SizedBox(height: 16),
        const Text('Получатели', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilterChip(label: const Text('Все участники (48)'), selected: true, onSelected: (_) {}),
          FilterChip(label: const Text('Судьи и волонтёры (5)'), selected: false, onSelected: (_) {}),
          FilterChip(label: const Text('Скиджоринг 5км (21)'), selected: false, onSelected: (_) {}),
        ]),
        const SizedBox(height: 16),
        AppTextField(label: 'Заголовок', hintText: 'Важное изменение в расписании'),
        const SizedBox(height: 12),
        AppTextField(label: 'Текст сообщения', hintText: 'Старт дистанции 5км переносится на 10:30...', maxLines: 4),
      ]),
    );
  }




}

/// Data class for checklist items on the dashboard.
class _CheckItem {
  final String title;
  final String subtitle;
  final int done;
  final int total;
  final IconData icon;
  final String route;

  const _CheckItem(this.title, this.subtitle, this.done, this.total, this.icon, this.route);
}
