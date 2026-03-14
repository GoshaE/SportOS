import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen: Настройки темы
/// 3 секции: Режим (Light/Dark/System) → Стиль (Zinc/Slate) → Цвет (Accent)
class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final themeState = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppAppBar(title: const Text('Оформление')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ═══ 1. Режим темы ═══
          AppSectionHeader(title: 'Режим', icon: Icons.brightness_6),
          const SizedBox(height: 8),
          Row(children: [
            _modeChip(context, ref, Icons.light_mode, 'Светлая', ThemeMode.light, themeState.mode),
            const SizedBox(width: 8),
            _modeChip(context, ref, Icons.brightness_auto, 'Авто', ThemeMode.system, themeState.mode),
            const SizedBox(width: 8),
            _modeChip(context, ref, Icons.dark_mode, 'Тёмная', ThemeMode.dark, themeState.mode),
          ]),

          const SizedBox(height: 24),

          // ═══ 2. Стиль (база) ═══
          AppSectionHeader(title: 'Стиль', icon: Icons.layers),
          const SizedBox(height: 4),
          Text('Нейтральные тона поверхностей и фонов',
            style: theme.textTheme.bodySmall?.copyWith(color: cs.outline),
          ),
          const SizedBox(height: 10),
          Row(
            children: basePresets.map((preset) {
              final isSelected = preset.id == themeState.presetId;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: preset != basePresets.last ? 8.0 : 0,
                  ),
                  child: _PresetCard(
                    preset: preset,
                    isSelected: isSelected,
                    isDark: theme.brightness == Brightness.dark,
                    onTap: () => ref.read(themeProvider.notifier).setPreset(preset.id),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // ═══ 3. Основной цвет ═══
          AppSectionHeader(title: 'Основной цвет', icon: Icons.palette),
          const SizedBox(height: 4),
          Text('Кнопки, ссылки, индикаторы и акценты',
            style: theme.textTheme.bodySmall?.copyWith(color: cs.outline),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 10, runSpacing: 10, children: accentColors.map((accent) {
            final isSelected = accent.id == themeState.accentId;
            final displayColor = theme.brightness == Brightness.dark
                ? accent.darkVariant
                : accent.color;
            return _AccentDot(
              color: displayColor,
              name: accent.name,
              isSelected: isSelected,
              onTap: () => ref.read(themeProvider.notifier).setAccent(accent.id),
            );
          }).toList()),

          const SizedBox(height: 28),

          // ═══ Превью ═══
          AppSectionHeader(title: 'Предпросмотр', icon: Icons.visibility),
          const SizedBox(height: 8),
          _ThemePreview(theme: theme),
        ],
      ),
    );
  }

  Widget _modeChip(BuildContext context, WidgetRef ref, IconData icon, String label, ThemeMode mode, ThemeMode current) {
    final cs = Theme.of(context).colorScheme;
    final isSelected = mode == current;
    return Expanded(
      child: Material(
        color: isSelected ? cs.primaryContainer : cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => ref.read(themeProvider.notifier).setMode(mode),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 22, color: isSelected ? cs.primary : cs.onSurfaceVariant),
              const SizedBox(height: 6),
              Text(label, style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              )),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Карточка базового стиля ──
class _PresetCard extends StatelessWidget {
  final BasePreset preset;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _PresetCard({
    required this.preset,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final palette = isDark ? preset.dark : preset.light;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? cs.primary : cs.outlineVariant.withValues(alpha: 0.3),
          width: isSelected ? 2.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(preset.icon, size: 18, color: isSelected ? cs.primary : cs.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(child: Text(preset.name, style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? cs.primary : cs.onSurface,
                  ))),
                  if (isSelected) Icon(Icons.check_circle, size: 18, color: cs.primary),
                ]),
                const SizedBox(height: 4),
                Text(preset.subtitle,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                // Surface color strip preview
                Row(children: [
                  _swatch(palette.surface),
                  const SizedBox(width: 3),
                  _swatch(palette.surfaceContainerLow),
                  const SizedBox(width: 3),
                  _swatch(palette.surfaceContainerHigh),
                  const SizedBox(width: 3),
                  _swatch(palette.surfaceContainerHighest),
                  const SizedBox(width: 3),
                  _swatch(palette.outline),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _swatch(Color color) => Expanded(
    child: Container(
      height: 20,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.black12, width: 0.5),
      ),
    ),
  );
}

// ── Точка акцентного цвета ──
class _AccentDot extends StatelessWidget {
  final Color color;
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _AccentDot({
    required this.color,
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: isSelected
                ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3)
                : Border.all(color: Colors.black12, width: 1),
            boxShadow: isSelected
                ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 1)]
                : null,
          ),
          child: isSelected
              ? const Icon(Icons.check, color: Colors.white, size: 20)
              : null,
        ),
        const SizedBox(height: 4),
        Text(name, style: TextStyle(
          fontSize: 10,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        )),
      ]),
    );
  }
}

// ── Превью темы ──
class _ThemePreview extends StatelessWidget {
  final ThemeData theme;
  const _ThemePreview({required this.theme});

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Как выглядят элементы', style: theme.textTheme.titleSmall),
          const SizedBox(height: 12),

          // Кнопки
          Row(children: [
            Expanded(child: FilledButton(onPressed: () {}, child: const Text('Главная'))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Вторая'))),
            const SizedBox(width: 8),
            Expanded(child: TextButton(onPressed: () {}, child: const Text('Текст'))),
          ]),
          const SizedBox(height: 12),

          // Чипы
          Wrap(spacing: 8, children: [
            FilterChip(label: const Text('Активный'), selected: true, onSelected: (_) {}),
            FilterChip(label: const Text('Обычный'), selected: false, onSelected: (_) {}),
          ]),
          const SizedBox(height: 12),

          // Переключатель
          SwitchListTile(
            title: const Text('Переключатель'),
            value: true,
            onChanged: (_) {},
            dense: true,
          ),
          const SizedBox(height: 8),

          // Прогресс
          LinearProgressIndicator(value: 0.65, borderRadius: BorderRadius.circular(8)),
          const SizedBox(height: 12),

          // Цвета
          Row(children: [
            _colorSwatch('Primary', cs.primary),
            _colorSwatch('Secondary', cs.secondary),
            _colorSwatch('Surface', cs.surface),
            _colorSwatch('Outline', cs.outline),
          ]),
        ]),
      ),
    );
  }

  Widget _colorSwatch(String label, Color color) {
    return Expanded(child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(children: [
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black12, width: 0.5),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 9)),
      ]),
    ));
  }
}
