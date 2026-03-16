import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Посты хронометража — выбор роли
class OpsTimingHubScreen extends StatelessWidget {
  final String eventId;

  const OpsTimingHubScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Посты Хронометража'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Выберите вашу роль на текущую смену. Вы можете переключаться между постами в любой момент.',
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
          _buildPostCard(
            context, cs, theme,
            title: 'Тренерский Пост',
            desc: 'Персональные отсечки, разрывы между спортсменами, аналитика.',
            icon: Icons.sports,
            color: Colors.deepOrange,
            route: '/ops/$eventId/timing/coach',
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
