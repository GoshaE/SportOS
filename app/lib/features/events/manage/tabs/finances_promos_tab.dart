import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../domain/event/config_providers.dart';
import '../../../../domain/event/event_config.dart' hide TimeOfDay;

/// Вкладка «Промокоды» — подключена к Config Engine (PricingConfig.promoCodes).
class FinancesPromosTab extends ConsumerWidget {
  const FinancesPromosTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final pricing = ref.watch(eventConfigProvider).pricingConfig;
    final promos = pricing.promoCodes;

    void updatePricing(PricingConfig Function(PricingConfig p) fn) {
      ref.read(eventConfigProvider.notifier).update(
        (c) => c.copyWith(pricingConfig: fn(c.pricingConfig)),
      );
    }

    final activeCount = promos.where((p) => p.isActive && !p.isExhausted).length;
    final usedCount = promos.fold<int>(0, (sum, p) => sum + p.usedCount);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // ─── Статистика ───
        Row(children: [
          Expanded(child: AppStatCard(value: '$activeCount', label: 'Активных кодов', icon: Icons.local_activity, color: cs.primary)),
          const SizedBox(width: 8),
          Expanded(child: AppStatCard(value: '$usedCount', label: 'Активаций', icon: Icons.check_circle, color: cs.secondary)),
        ]),
        const SizedBox(height: 16),

        // ─── Заголовок + кнопка ───
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Список промокодов', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          AppButton.smallSecondary(text: 'Добавить', icon: Icons.add, onPressed: () => _showCreatePromo(context, updatePricing)),
        ]),
        const SizedBox(height: 12),

        // ─── Список ───
        if (promos.isEmpty)
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
          ...promos.asMap().entries.map((entry) {
            final i = entry.key;
            final promo = entry.value;
            final discountText = '−${promo.discountPercent}%';
            final progress = promo.maxUses != null && promo.maxUses! > 0
                ? promo.usedCount / promo.maxUses!
                : 0.0;
            final promoColor = cs.secondary;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppCard(
                padding: EdgeInsets.zero,
                backgroundColor: promo.isActive ? null : cs.surfaceContainerHighest.withValues(alpha: 0.3),
                borderColor: promo.isActive ? promoColor.withValues(alpha: 0.3) : cs.outlineVariant.withValues(alpha: 0.3),
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: promo.isActive ? promoColor.withValues(alpha: 0.05) : null,
                        border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.4))),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: promoColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: Text(promo.code, style: TextStyle(fontWeight: FontWeight.w800, fontFeatures: const [FontFeature.tabularFigures()], fontSize: 16, letterSpacing: 1.5, color: promo.isActive ? promoColor : cs.outline)),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: promoColor, borderRadius: BorderRadius.circular(6)),
                          child: Text(discountText, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onPrimary)),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.delete_outline, size: 20, color: cs.error),
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            final updated = List<PromoCode>.from(promos)..removeAt(i);
                            updatePricing((p) => p.copyWith(promoCodes: updated));
                          },
                        ),
                      ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Text('Использовано', style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                          Text(
                            promo.maxUses != null
                                ? '${promo.usedCount} / ${promo.maxUses}'
                                : '${promo.usedCount} (без лимита)',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ]),
                        if (promo.maxUses != null && promo.maxUses! > 0) ...[
                          const SizedBox(height: 8),
                          ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
                            value: progress.clamp(0.0, 1.0),
                            backgroundColor: cs.surfaceContainerHighest,
                            color: progress >= 1.0 ? cs.error : promoColor, minHeight: 8,
                          )),
                        ],
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

  void _showCreatePromo(BuildContext context, void Function(PricingConfig Function(PricingConfig)) updatePricing) {
    final codeCtrl = TextEditingController();
    final discountCtrl = TextEditingController(text: '10');
    final maxCtrl = TextEditingController();

    AppBottomSheet.show(
      context,
      title: 'Новый промокод',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AppTextField(
          label: 'Код (например, SALE20)',
          controller: codeCtrl,
          hintText: 'EARLY2026',
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: AppTextField(
            label: 'Скидка %',
            controller: discountCtrl,
            keyboardType: TextInputType.number,
          )),
          const SizedBox(width: 16),
          Expanded(child: AppTextField(
            label: 'Макс. использований',
            controller: maxCtrl,
            hintText: '∞',
            keyboardType: TextInputType.number,
          )),
        ]),
        const SizedBox(height: 24),
        AppButton.primary(text: 'Создать', onPressed: () {
          if (codeCtrl.text.trim().isEmpty) {
            AppSnackBar.error(context, 'Введите код промокода');
            return;
          }
          final promo = PromoCode(
            id: 'promo-${DateTime.now().millisecondsSinceEpoch}',
            code: codeCtrl.text.trim().toUpperCase(),
            discountPercent: (int.tryParse(discountCtrl.text) ?? 10).clamp(1, 100),
            maxUses: int.tryParse(maxCtrl.text),
          );
          updatePricing((p) => p.copyWith(promoCodes: [...p.promoCodes, promo]));
          Navigator.of(context, rootNavigator: true).pop();
          AppSnackBar.success(context, 'Промокод ${promo.code} создан');
        }),
      ]),
    );
  }
}
