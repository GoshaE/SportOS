import 'package:flutter/material.dart';
import '../../../../core/widgets/widgets.dart';

class FinancesPromosTab extends StatefulWidget {
  final List<Map<String, dynamic>> promos;

  const FinancesPromosTab({super.key, required this.promos});

  @override
  State<FinancesPromosTab> createState() => _FinancesPromosTabState();
}

class _FinancesPromosTabState extends State<FinancesPromosTab> {
  late List<Map<String, dynamic>> _promos;

  @override
  void initState() {
    super.initState();
    _promos = List.from(widget.promos);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    int activeCount = _promos.where((p) => p['active']).length;
    int usedCount = _promos.fold(0, (sum, p) => sum + (p['used'] as int));

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(children: [
          Expanded(child: AppStatCard(value: '$activeCount', label: 'Активных кодов', icon: Icons.local_activity, color: cs.primary)),
          const SizedBox(width: 8),
          Expanded(child: AppStatCard(value: '$usedCount', label: 'Активаций', icon: Icons.check_circle, color: cs.secondary)),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Список промокодов', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          OutlinedButton.icon(
            onPressed: () => _showCreatePromo(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Добавить'),
            style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
          ),
        ]),
        const SizedBox(height: 12),
        if (_promos.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(children: [
                Icon(Icons.local_offer, size: 48, color: cs.onSurfaceVariant.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text('Нет промокодов', style: TextStyle(color: cs.onSurfaceVariant)),
              ]),
            ),
          )
        else
          ..._promos.asMap().entries.map((e) {
            final p = e.value;
            final discountText = p['type'] == 'percent' ? '−${p['value']}%' : '−${p['value']}₽';
            final progress = p['maxUses'] > 0 ? (p['used'] as int) / (p['maxUses'] as int) : 0.0;
            final promoColor = p['type'] == 'percent' ? cs.secondary : cs.primary;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                padding: EdgeInsets.zero,
                backgroundColor: p['active'] ? null : cs.surfaceContainerHighest.withValues(alpha: 0.3),
                borderColor: p['active'] ? promoColor.withValues(alpha: 0.3) : cs.outlineVariant.withValues(alpha: 0.3),
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: p['active'] ? promoColor.withValues(alpha: 0.05) : null,
                        border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4))),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: promoColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(p['code'], style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'monospace', fontSize: 16, letterSpacing: 1.5, color: p['active'] ? promoColor : cs.outline)),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: promoColor, borderRadius: BorderRadius.circular(6)),
                          child: Text(discountText, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onPrimary)),
                        ),
                        const Spacer(),
                        Switch(value: p['active'], onChanged: (v) => setState(() => p['active'] = v), activeTrackColor: promoColor),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('Использовано', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                          Text('${p['used']} / ${p['maxUses'] == 0 ? '∞' : p['maxUses']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ]),
                        const SizedBox(height: 8),
                        ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          backgroundColor: cs.surfaceContainerHighest,
                          color: progress >= 1.0 ? cs.error : promoColor, minHeight: 8,
                        )),
                        const SizedBox(height: 16),
                        Row(children: [
                          Icon(Icons.calendar_today, size: 14, color: cs.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text('До ${p['validUntil']}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                          const Spacer(),
                          Icon(Icons.sports, size: 14, color: cs.onSurfaceVariant),
                          const SizedBox(width: 6),
                          Text('${p['disciplines']}', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                        ]),
                      ]),
                    ),
                  ]),
                ],
              ),
            );
          }),
        const SizedBox(height: 80),
      ],
    );
  }

  void _showCreatePromo(BuildContext context) {
    AppBottomSheet.show(
      context,
      title: 'Новый промокод',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const TextField(decoration: InputDecoration(labelText: 'Код (например, SALE20)', border: OutlineInputBorder()), textCapitalization: TextCapitalization.characters),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Тип скидки', border: OutlineInputBorder()),
            initialValue: 'percent', items: const [DropdownMenuItem(value: 'percent', child: Text('Процент %')), DropdownMenuItem(value: 'fixed', child: Text('Сумма ₽'))],
            onChanged: (_) {},
          )),
          const SizedBox(width: 16),
          const Expanded(child: TextField(decoration: InputDecoration(labelText: 'Значение', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
        ]),
        const SizedBox(height: 16),
        const TextField(decoration: InputDecoration(labelText: 'Кол-во использований (0 - безлим)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
        const SizedBox(height: 24),
        FilledButton(onPressed: () {
          Navigator.of(context, rootNavigator: true).pop();
          AppSnackBar.success(context, 'Промокод создан');
        }, child: const Text('Создать')),
      ]),
    );
  }
}
