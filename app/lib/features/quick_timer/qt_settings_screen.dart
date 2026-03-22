import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportos_app/core/widgets/widgets.dart';

import '../../domain/quick_timer/quick_timer_models.dart';
import '../../domain/quick_timer/quick_timer_providers.dart';
import 'widgets/qt_group_picker_sheet.dart';

/// QT Settings — Полная страница настроек быстрого секундомера.
///
/// Две секции:
/// 1. **Сессия** — режим старта, круги, интервал, группы
/// 2. **Отображение** — подсветка лучших, колонки таблицы
class QtSettingsScreen extends ConsumerStatefulWidget {
  const QtSettingsScreen({super.key});

  @override
  ConsumerState<QtSettingsScreen> createState() => _QtSettingsScreenState();
}

class _QtSettingsScreenState extends ConsumerState<QtSettingsScreen> {
  late QuickStartMode _mode;
  late int _laps;
  late int _interval;

  @override
  void initState() {
    super.initState();
    final session = ref.read(quickSessionProvider);
    _mode = session?.mode ?? QuickStartMode.mass;
    _laps = session?.totalLaps ?? 1;
    _interval = session?.intervalSeconds ?? 30;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final session = ref.watch(quickSessionProvider);
    final isRunning = session?.status == QuickSessionStatus.running;
    final displaySettings = ref.watch(qtDisplaySettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // ═══════════════════════════════════════
          // СЕКЦИЯ 1: Сессия
          // ═══════════════════════════════════════
          _SectionHeader(icon: Icons.timer, title: 'Сессия', color: cs.primary),
          const SizedBox(height: 12),

          AppCard(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Режим старта ──
              _SettingLabel('РЕЖИМ СТАРТА', cs),
              const SizedBox(height: 8),
              SegmentedButton<QuickStartMode>(
                segments: const [
                  ButtonSegment(value: QuickStartMode.mass, label: Text('Масс'), icon: Icon(Icons.groups)),
                  ButtonSegment(value: QuickStartMode.interval, label: Text('Интервал'), icon: Icon(Icons.timer)),
                  ButtonSegment(value: QuickStartMode.manual, label: Text('Ручной'), icon: Icon(Icons.touch_app)),
                ],
                selected: {_mode},
                onSelectionChanged: isRunning ? null : (s) {
                  setState(() => _mode = s.first);
                  ref.read(quickSessionProvider.notifier).updateSettings(mode: _mode);
                },
              ),
              const SizedBox(height: 8),
              AppInfoBanner.info(
                title: _mode == QuickStartMode.mass
                    ? 'Все стартуют одновременно'
                    : _mode == QuickStartMode.interval
                        ? 'Автоматический старт через интервал'
                        : 'Тренер запускает каждого вручную',
              ),

              const SizedBox(height: 20),
              // ── Количество кругов ──
              _SettingLabel('КОЛИЧЕСТВО КРУГОВ', cs),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final n in [1, 2, 3, 4, 5])
                    ChoiceChip(
                      label: Text('$n'),
                      selected: _laps == n,
                      onSelected: (_) {
                        setState(() => _laps = n);
                        ref.read(quickSessionProvider.notifier).updateSettings(totalLaps: n);
                      },
                    ),
                ],
              ),

              // ── Интервал (только для interval mode) ──
              if (_mode == QuickStartMode.interval) ...[
                const SizedBox(height: 20),
                _SettingLabel('ИНТЕРВАЛ МЕЖДУ СТАРТАМИ', cs),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final sec in [15, 30, 45, 60])
                      ChoiceChip(
                        label: Text('$secс'),
                        selected: _interval == sec,
                        onSelected: isRunning ? null : (_) {
                          setState(() => _interval = sec);
                          ref.read(quickSessionProvider.notifier).updateSettings(intervalSeconds: sec);
                        },
                      ),
                  ],
                ),
              ],
            ],
          ),

          const SizedBox(height: 12),
          // ── Группы ──
          AppCard(
            padding: const EdgeInsets.all(16),
            children: [
              _SettingLabel('ГРУППЫ СПОРТСМЕНОВ', cs),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: AppButton.small(
                    text: 'Из книги',
                    icon: Icons.folder_open,
                    onPressed: () => showQtGroupPickerSheet(context, ref),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AppButton.smallSecondary(
                    text: 'Сохранить',
                    icon: Icons.save_alt,
                    onPressed: session != null ? () => _showSaveGroupSheet(context, ref, session) : null,
                  ),
                ),
              ]),
            ],
          ),

          const SizedBox(height: 24),

          // ═══════════════════════════════════════
          // СЕКЦИЯ 2: Отображение таблицы
          // ═══════════════════════════════════════
          _SectionHeader(icon: Icons.table_chart, title: 'Таблица', color: cs.tertiary),
          const SizedBox(height: 12),

          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
            children: [
              _SettingSwitch(
                icon: Icons.auto_awesome,
                title: 'Лучший круг',
                subtitle: 'Подсветка лучшего времени на каждом круге',
                value: displaySettings.showBestLap,
                activeColor: cs.primary,
                onChanged: (v) => ref.read(qtDisplaySettingsProvider.notifier).update(
                    displaySettings.copyWith(showBestLap: v)),
              ),
              Divider(height: 1, indent: 56, color: cs.outlineVariant.withOpacity(0.15)),
              _SettingSwitch(
                icon: Icons.swap_horiz,
                title: 'Колонка Δ (разрыв)',
                subtitle: 'Разница от лидера',
                value: displaySettings.showGapColumn,
                activeColor: cs.error,
                onChanged: (v) => ref.read(qtDisplaySettingsProvider.notifier).update(
                    displaySettings.copyWith(showGapColumn: v)),
              ),
              Divider(height: 1, indent: 56, color: cs.outlineVariant.withOpacity(0.15)),
              _SettingSwitch(
                icon: Icons.view_column,
                title: 'Колонки кругов',
                subtitle: 'Отдельные колонки L1, L2...',
                value: displaySettings.showLapColumns,
                activeColor: cs.primary,
                onChanged: (v) => ref.read(qtDisplaySettingsProvider.notifier).update(
                    displaySettings.copyWith(showLapColumns: v)),
              ),
            ],
          ),

          // ── Новая сессия ──
          if (session?.status == QuickSessionStatus.finished) ...[
            const SizedBox(height: 24),
            AppButton.danger(
              text: 'Новая сессия',
              icon: Icons.refresh,
              onPressed: () {
                AppDialog.confirm(
                  context,
                  title: 'Начать новую сессию?',
                  message: 'Текущие результаты сохранены в истории.',
                ).then((ok) {
                  if (ok == true && context.mounted) {
                    ref.read(quickSessionProvider.notifier).reset();
                    Navigator.of(context).pop();
                  }
                });
              },
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showSaveGroupSheet(BuildContext context, WidgetRef ref, QuickSession session) {
    if (session.athletes.isEmpty) {
      AppSnackBar.info(context, 'Добавьте участников');
      return;
    }

    final nameCtrl = TextEditingController();

    AppBottomSheet.show(
      context,
      title: 'Сохранить как группу',
      initialHeight: 0.35,
      actions: [
        AppButton.primary(
          text: 'Сохранить',
          icon: Icons.save,
          onPressed: () {
            final name = nameCtrl.text.trim();
            if (name.isEmpty) return;

            final group = SavedGroup(
              id: 'grp-${DateTime.now().millisecondsSinceEpoch}',
              name: name,
              members: session.athletes
                  .map((a) => SavedGroupMember(name: a.name, defaultBib: a.bib))
                  .toList(),
            );
            ref.read(savedGroupsProvider.notifier).save(group);

            Navigator.of(context, rootNavigator: true).pop();
            AppSnackBar.success(context, 'Группа «$name» сохранена');
          },
        ),
      ],
      child: AppTextField(
        label: 'Название группы',
        hintText: 'Младшая группа',
        controller: nameCtrl,
        autofocus: true,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// PRIVATE WIDGETS
// ─────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      const SizedBox(width: 10),
      Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: 0.5,
      )),
    ]);
  }
}

class _SettingLabel extends StatelessWidget {
  final String text;
  final ColorScheme cs;

  const _SettingLabel(this.text, this.cs);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(
      fontSize: 11, fontWeight: FontWeight.w800,
      color: cs.onSurfaceVariant,
      letterSpacing: 1,
    ));
  }
}

class _SettingSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  const _SettingSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeTrackColor: activeColor,
      secondary: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: (value ? activeColor : cs.onSurfaceVariant).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: value ? activeColor : cs.onSurfaceVariant),
      ),
      title: Text(title, style: TextStyle(
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      )),
      subtitle: Text(subtitle, style: TextStyle(
        fontSize: 12,
        color: cs.onSurfaceVariant,
      )),
    );
  }
}
