import 'package:flutter/material.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../core/widgets/widgets.dart';

/// Screen ID: O5 — GPS Карта трассы (прототип)
class GpsMapScreen extends StatelessWidget {
  const GpsMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Карта трассы'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Text('GPS Active', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10, fontWeight: FontWeight.bold, color: cs.primary)),
            ]),
          ),
        ],
      ),
      body: Column(children: [
        // Info bar
        Container(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(children: [
            Icon(Icons.directions_run, size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text('12 на трассе', style: theme.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
            const Spacer(),
            Wrap(spacing: 12, children: [
              _legend(context, cs, '🔵', 'Спортсмен'),
              _legend(context, cs, '🟢', 'Checkpoint'),
              _legend(context, cs, '🏁', 'Старт/Финиш'),
              _legend(context, cs, '🚩', 'Маршал'),
            ]),
          ]),
        ),

        // Map placeholder
        Expanded(child: Stack(children: [
          Container(
            color: cs.primaryContainer.withValues(alpha: 0.05),
            child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.map, size: 64, color: cs.primary.withValues(alpha: 0.3)),
              const SizedBox(height: 8),
              Text('Карта трассы', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.primary)),
              const SizedBox(height: 4),
              Text('Здесь будет MapboxGL / OpenStreetMap', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ])),
          ),
          Positioned(left: 50, top: 80, child: _mapPin(context, cs, '🏁', 'Старт', cs.primary)),
          Positioned(right: 50, top: 80, child: _mapPin(context, cs, '🏁', 'Финиш', cs.error)),
          Positioned(left: 100, top: 180, child: _mapPin(context, cs, '🚩', 'CP 3км', cs.tertiary)),
          Positioned(right: 120, top: 250, child: _mapPin(context, cs, '🚩', 'CP 6км', cs.tertiary)),
          Positioned(left: 80, top: 150, child: _athlete(context, cs, '42', 'Морозов')),
          Positioned(left: 160, top: 200, child: _athlete(context, cs, '07', 'Петров')),
          Positioned(right: 80, top: 180, child: _athlete(context, cs, '55', 'Волков')),
        ])),

        // Controls
        SafeArea(child: Padding(padding: const EdgeInsets.all(8), child: Row(children: [
          Expanded(child: AppButton.secondary(text: 'Слои', icon: Icons.layers, onPressed: () {})),
          const SizedBox(width: 8),
          Expanded(child: AppButton.secondary(text: 'Позиция', icon: Icons.my_location, onPressed: () {})),
          const SizedBox(width: 8),
          Expanded(child: AppButton.secondary(text: 'Полный', icon: Icons.fullscreen, onPressed: () {})),
        ]))),
      ]),
    );
  }

  Widget _legend(BuildContext context, ColorScheme cs, String emoji, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Text(emoji, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10)),
    const SizedBox(width: 2),
    Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9, color: cs.onSurfaceVariant)),
  ]);

  Widget _mapPin(BuildContext context, ColorScheme cs, String emoji, String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withValues(alpha: 0.3))),
    child: Text('$emoji $label', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10, color: color)),
  );

  Widget _athlete(BuildContext context, ColorScheme cs, String bib, String name) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
    decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(12)),
    child: Text('$bib $name', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
  );
}
