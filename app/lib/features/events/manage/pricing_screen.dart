import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../../domain/event/config_providers.dart';
import '../../../domain/event/event_config.dart' hide TimeOfDay;

/// P1 — Ценообразование.
///
/// Цена per-discipline (priceRub), early bird, промокоды, валюта.
class PricingScreen extends ConsumerWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(eventConfigProvider);
    final pricing = config.pricingConfig;
    final disciplines = ref.watch(disciplineConfigsProvider);
    final cs = Theme.of(context).colorScheme;

    void updatePricing(PricingConfig Function(PricingConfig p) fn) {
      ref.read(eventConfigProvider.notifier).update(
        (c) => c.copyWith(pricingConfig: fn(c.pricingConfig)),
      );
    }

    // Total revenue estimate
    final totalBase = disciplines.fold<int>(0, (sum, d) => sum + (d.priceRub ?? 0));

    return Scaffold(
      appBar: AppAppBar(title: const Text('Ценообразование')),
      body: ListView(padding: const EdgeInsets.all(16), children: [

        // ─── Цены по дисциплинам ───
        _section(cs, 'Стоимость участия'),
        AppCard(padding: EdgeInsets.zero, children: [
          Column(children: [
            ...disciplines.asMap().entries.map((entry) {
              final i = entry.key;
              final d = entry.value;
              return Column(children: [
                if (i > 0) const Divider(height: 1, indent: 16),
                ListTile(
                  dense: true,
                  leading: Icon(Icons.sports, size: 18, color: cs.primary),
                  title: Text(d.name, style: const TextStyle(fontSize: 13)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      d.priceRub != null ? '${d.priceRub} ${_currencySymbol(pricing.currency)}' : 'Бесплатно',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: d.priceRub != null ? cs.primary : cs.outline,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.edit, size: 14, color: cs.outline),
                  ]),
                  onTap: () => _editDisciplinePrice(context, ref, d, pricing.currency),
                ),
              ]);
            }),
          ]),
        ]),
        if (totalBase > 0) ...[
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Text('Итого (все дисциплины): ', style: TextStyle(fontSize: 12, color: cs.outline)),
            Text('$totalBase ${_currencySymbol(pricing.currency)}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.primary)),
          ]),
        ],
        const SizedBox(height: 20),

        // ─── Валюта ───
        _section(cs, 'Валюта'),
        AppCard(padding: EdgeInsets.zero, children: [
          Column(children: [
            AppSettingsTile.nav(
              title: 'Валюта',
              subtitle: _currencyName(pricing.currency),
              onTap: () => _pickCurrency(context, updatePricing),
            ),
          ]),
        ]),
        const SizedBox(height: 16),

        // ─── Early Bird ───
        _section(cs, 'Ранняя регистрация'),
        AppCard(padding: EdgeInsets.zero, children: [
          Column(children: [
            AppSettingsTile.toggle(
              title: 'Early Bird',
              subtitle: pricing.earlyBirdEnabled
                  ? 'Скидка ${pricing.earlyBirdDiscountPercent}%${pricing.earlyBirdDeadline != null ? ' до ${_fmtDate(pricing.earlyBirdDeadline!)}' : ''}'
                  : 'Выключено',
              value: pricing.earlyBirdEnabled,
              onChanged: (v) => updatePricing((p) => p.copyWith(earlyBirdEnabled: v)),
            ),
            if (pricing.earlyBirdEnabled) ...[
              const Divider(height: 1, indent: 16),
              AppSettingsTile.nav(
                title: 'Скидка',
                subtitle: '${pricing.earlyBirdDiscountPercent}%',
                onTap: () => _editPercent(context, pricing.earlyBirdDiscountPercent, (v) {
                  updatePricing((p) => p.copyWith(earlyBirdDiscountPercent: v));
                }),
              ),
              const Divider(height: 1, indent: 16),
              AppSettingsTile.nav(
                title: 'Действует до',
                subtitle: pricing.earlyBirdDeadline != null
                    ? _fmtDate(pricing.earlyBirdDeadline!)
                    : 'Не задано',
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: pricing.earlyBirdDeadline ?? config.startDate.subtract(const Duration(days: 14)),
                    firstDate: DateTime.now(),
                    lastDate: config.startDate,
                  );
                  if (date != null) {
                    updatePricing((p) => p.copyWith(earlyBirdDeadline: date));
                  }
                },
              ),
            ],
          ]),
        ]),
        const SizedBox(height: 16),

        // ─── Промокоды ───
        _section(cs, 'Промокоды'),
        if (pricing.promoCodes.isNotEmpty)
          AppCard(padding: EdgeInsets.zero, children: [
            Column(children: [
              ...pricing.promoCodes.asMap().entries.map((entry) {
                final i = entry.key;
                final promo = entry.value;
                return Column(children: [
                  if (i > 0) const Divider(height: 1, indent: 16),
                  ListTile(
                    dense: true,
                    leading: Icon(
                      promo.isActive && !promo.isExhausted ? Icons.discount : Icons.block,
                      size: 18,
                      color: promo.isActive && !promo.isExhausted ? Colors.green : cs.error,
                    ),
                    title: Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(promo.code, style: TextStyle(
                          fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold,
                          color: promo.isActive ? cs.onSurface : cs.outline,
                        )),
                      ),
                      const SizedBox(width: 8),
                      Text('-${promo.discountPercent}%', style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold,
                        color: promo.isActive ? Colors.green : cs.outline,
                      )),
                    ]),
                    subtitle: Text(
                      promo.maxUses != null
                          ? 'Использовано: ${promo.usedCount}/${promo.maxUses}'
                          : 'Использовано: ${promo.usedCount} (без лимита)',
                      style: TextStyle(fontSize: 11, color: cs.outline),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
                      onPressed: () {
                        final updated = List<PromoCode>.from(pricing.promoCodes)..removeAt(i);
                        updatePricing((p) => p.copyWith(promoCodes: updated));
                      },
                    ),
                  ),
                ]);
              }),
            ]),
          ]),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _addPromo(context, updatePricing, pricing),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Добавить промокод'),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }

  Widget _section(ColorScheme cs, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.primary)),
    );
  }

  String _currencySymbol(String code) => switch (code) {
    'RUB' => '₽',
    'USD' => '\$',
    'EUR' => '€',
    'KZT' => '₸',
    'BYN' => 'Br',
    _ => code,
  };

  String _currencyName(String code) => switch (code) {
    'RUB' => '₽ — Российский рубль',
    'USD' => '\$ — Доллар США',
    'EUR' => '€ — Евро',
    'KZT' => '₸ — Тенге',
    'BYN' => 'Br — Белорусский рубль',
    _ => code,
  };

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  void _editDisciplinePrice(BuildContext context, WidgetRef ref, dynamic disc, String currency) {
    final ctrl = TextEditingController(text: '${disc.priceRub ?? 0}');
    AppBottomSheet.show(context, title: disc.name, child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: 'Цена (${_currencySymbol(currency)})',
          border: const OutlineInputBorder(),
          hintText: '0 = бесплатно',
        ),
        keyboardType: TextInputType.number,
        autofocus: true,
      ),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, child: FilledButton(
        onPressed: () {
          final price = int.tryParse(ctrl.text) ?? 0;
          ref.read(eventConfigProvider.notifier).updateDiscipline(
            disc.id,
            (d) => d.copyWith(priceRub: price > 0 ? price : null),
          );
          Navigator.pop(context);
        },
        child: const Text('Сохранить'),
      )),
    ]));
  }

  void _editPercent(BuildContext context, int current, ValueChanged<int> onSave) {
    final ctrl = TextEditingController(text: '$current');
    AppBottomSheet.show(context, title: 'Скидка %', child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(
        controller: ctrl,
        decoration: const InputDecoration(labelText: 'Процент скидки', border: OutlineInputBorder(), suffixText: '%'),
        keyboardType: TextInputType.number,
        autofocus: true,
      ),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, child: FilledButton(
        onPressed: () {
          onSave((int.tryParse(ctrl.text) ?? 20).clamp(1, 100));
          Navigator.pop(context);
        },
        child: const Text('Сохранить'),
      )),
    ]));
  }

  void _pickCurrency(BuildContext context, void Function(PricingConfig Function(PricingConfig)) updatePricing) {
    const currencies = ['RUB', 'USD', 'EUR', 'KZT', 'BYN'];
    AppBottomSheet.show(context, title: 'Валюта', child: Column(mainAxisSize: MainAxisSize.min, children: [
      ...currencies.map((code) => ListTile(
        title: Text(_currencyName(code)),
        onTap: () {
          updatePricing((p) => p.copyWith(currency: code));
          Navigator.pop(context);
        },
      )),
    ]));
  }

  void _addPromo(BuildContext context, void Function(PricingConfig Function(PricingConfig)) updatePricing, PricingConfig pricing) {
    final codeCtrl = TextEditingController();
    final discountCtrl = TextEditingController(text: '10');
    final maxCtrl = TextEditingController();

    AppBottomSheet.show(context, title: 'Новый промокод', child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(
        controller: codeCtrl,
        decoration: const InputDecoration(labelText: 'Код *', border: OutlineInputBorder(), hintText: 'EARLY2026'),
        textCapitalization: TextCapitalization.characters,
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: TextField(
          controller: discountCtrl,
          decoration: const InputDecoration(labelText: 'Скидка %', border: OutlineInputBorder(), isDense: true),
          keyboardType: TextInputType.number,
        )),
        const SizedBox(width: 12),
        Expanded(child: TextField(
          controller: maxCtrl,
          decoration: const InputDecoration(labelText: 'Макс. исп.', border: OutlineInputBorder(), isDense: true, hintText: '∞'),
          keyboardType: TextInputType.number,
        )),
      ]),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, child: FilledButton.icon(
        onPressed: () {
          if (codeCtrl.text.trim().isEmpty) { AppSnackBar.error(context, 'Введите код'); return; }
          final promo = PromoCode(
            id: 'promo-${DateTime.now().millisecondsSinceEpoch}',
            code: codeCtrl.text.trim().toUpperCase(),
            discountPercent: (int.tryParse(discountCtrl.text) ?? 10).clamp(1, 100),
            maxUses: int.tryParse(maxCtrl.text),
          );
          updatePricing((p) => p.copyWith(promoCodes: [...p.promoCodes, promo]));
          Navigator.pop(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      )),
    ]));
  }
}
