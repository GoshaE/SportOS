import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../domain/event/config_providers.dart';
import '../../../../domain/event/event_config.dart' hide TimeOfDay;

/// Вкладка «Взносы» — подключена к Config Engine.
class FinancesFeesTab extends ConsumerStatefulWidget {
  const FinancesFeesTab({super.key});

  @override
  ConsumerState<FinancesFeesTab> createState() => _FinancesFeesTabState();
}

class _FinancesFeesTabState extends ConsumerState<FinancesFeesTab> {
  String _paymentTier = 'sbp';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final config = ref.watch(eventConfigProvider);
    final pricing = config.pricingConfig;
    final disciplines = ref.watch(disciplineConfigsProvider);

    void updatePricing(PricingConfig Function(PricingConfig p) fn) {
      ref.read(eventConfigProvider.notifier).update(
        (c) => c.copyWith(pricingConfig: fn(c.pricingConfig)),
      );
    }

    return ListView(padding: const EdgeInsets.all(12), children: [
      // ─── Способ оплаты ───
      AppCard(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Icon(Icons.credit_card, size: 20, color: cs.primary),
            const SizedBox(width: 8),
            const Text('Способ приёма платежей', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
          const SizedBox(height: 16),
          _tierOption(cs, 'free', Icons.money_off, 'Бесплатное', 'Взносы не взимаются', null),
          _tierOption(cs, 'requisites', Icons.credit_card, 'По реквизитам', 'Физлицо · ручное подтверждение · 0%', null),
          _tierOption(cs, 'sbp', Icons.currency_ruble, 'СБП для бизнеса', 'ИП / самозанятый · авто · 0.4–0.7%', cs.primary),
          _tierOption(cs, 'acquiring', Icons.payment, 'Онлайн-эквайринг', 'ИП / ООО · Tinkoff / YooKassa · 1.5–3.5%', cs.secondary),
          if (_paymentTier == 'sbp') Padding(padding: const EdgeInsets.only(top: 8), child: AppInfoBanner.warning(title: 'Требуется ИП/самозанятый. Подключите СБП через банк.')),
          if (_paymentTier == 'acquiring') Padding(padding: const EdgeInsets.only(top: 8), child: AppInfoBanner.warning(title: 'Требуется ИП/ООО. Поддерживается: карты, SberPay, TinkoffPay, MirPay, СБП.')),
        ],
      ),
      const SizedBox(height: 12),

      if (_paymentTier != 'free') ...[
        // ─── Валюта ───
        AppCard(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              Icon(Icons.language, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              const Text('Валюта', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'RUB', label: Text('₽', style: TextStyle(fontSize: 12))),
                  ButtonSegment(value: 'USD', label: Text('\$', style: TextStyle(fontSize: 12))),
                  ButtonSegment(value: 'EUR', label: Text('€', style: TextStyle(fontSize: 12))),
                  ButtonSegment(value: 'KZT', label: Text('₸', style: TextStyle(fontSize: 12))),
                ],
                selected: {pricing.currency},
                onSelectionChanged: (s) => updatePricing((p) => p.copyWith(currency: s.first)),
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
              ),
            ]),
          ],
        ),
        const SizedBox(height: 12),

        // ─── Цены по дисциплинам ───
        AppCard(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              Icon(Icons.payments, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              const Text('Цены по дисциплинам', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
            const SizedBox(height: 16),
            ...disciplines.asMap().entries.map((entry) {
              final i = entry.key;
              final d = entry.value;
              final symbol = _currencySymbol(pricing.currency);
              return _priceRow(cs, d.name, d.priceRub, symbol, _sportColor(cs, i), () {
                _editPrice(context, d.name, d.id, d.priceRub, symbol);
              });
            }),
          ],
        ),
        const SizedBox(height: 12),

        // ─── Early Bird + Таймаут ───
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: AppCard(
            padding: const EdgeInsets.all(16),
            backgroundColor: pricing.earlyBirdEnabled ? cs.tertiary.withValues(alpha: 0.1) : null,
            borderColor: pricing.earlyBirdEnabled ? cs.tertiary.withValues(alpha: 0.3) : null,
            children: [
              Row(children: [
                Icon(Icons.access_time_filled, color: pricing.earlyBirdEnabled ? cs.tertiary : cs.onSurfaceVariant, size: 20),
                const SizedBox(width: 8),
                const Expanded(child: Text('Early Bird', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                SizedBox(
                  height: 24,
                  child: Switch(
                    value: pricing.earlyBirdEnabled,
                    onChanged: (v) => updatePricing((p) => p.copyWith(earlyBirdEnabled: v)),
                  ),
                ),
              ]),
              if (pricing.earlyBirdEnabled) ...[
                const SizedBox(height: 12),
                Row(children: [
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'percent', label: Text('%', style: TextStyle(fontSize: 12))),
                      ButtonSegment(value: 'fixed', label: Text('₽', style: TextStyle(fontSize: 12))),
                    ],
                    selected: const {'percent'},
                    onSelectionChanged: (_) {},
                    style: const ButtonStyle(visualDensity: VisualDensity.compact),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: GestureDetector(
                    onTap: () => _editDiscount(context, pricing.earlyBirdDiscountPercent, updatePricing),
                    child: Text(
                      '−${pricing.earlyBirdDiscountPercent}%',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: cs.tertiary),
                      textAlign: TextAlign.right,
                    ),
                  )),
                ]),
                const SizedBox(height: 8),
                GestureDetector(
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
                  child: Text(
                    pricing.earlyBirdDeadline != null
                        ? 'До ${_fmtDate(pricing.earlyBirdDeadline!)}'
                        : 'Нажмите для выбора даты',
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ],
          )),
          const SizedBox(width: 8),
          Expanded(child: AppCard(
            padding: const EdgeInsets.all(16),
            children: [
              Row(children: [
                Icon(Icons.timer_outlined, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                const Expanded(child: Text('Таймаут', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
              ]),
              const SizedBox(height: 12),
              AppSelect<int>(
                label: 'Таймаут',
                value: config.registrationConfig.refundDeadlineHours,
                items: [12, 24, 48, 72].map((h) => SelectItem(value: h, label: '$h ч.')).toList(),
                onChanged: (v) {
                  ref.read(eventConfigProvider.notifier).update(
                    (c) => c.copyWith(registrationConfig: c.registrationConfig.copyWith(refundDeadlineHours: v)),
                  );
                },
              ),
              const SizedBox(height: 8),
              Text('На оплату после брони', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ],
          )),
        ]),
        const SizedBox(height: 12),

        // ─── Интеграция ───
        if (_paymentTier == 'requisites') AppCard(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [Icon(Icons.account_balance, size: 20, color: cs.primary), const SizedBox(width: 8), const Text('Реквизиты', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))]),
            const SizedBox(height: 16),
            _reqCard(cs, Icons.credit_card, '4276 **** **** 1234', 'Сбербанк'),
            _reqCard(cs, Icons.person, 'Иванов Иван Иванович', 'Получатель'),
            const SizedBox(height: 8),
            AppButton.smallSecondary(text: 'Альтернативные реквизиты', icon: Icons.add, onPressed: () {}),
          ],
        ),
        if (_paymentTier == 'sbp' || _paymentTier == 'acquiring') AppCard(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              Icon(_paymentTier == 'sbp' ? Icons.account_balance : Icons.link, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              Text(_paymentTier == 'sbp' ? 'СБП Интеграция' : 'Эквайринг', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
            const SizedBox(height: 16),
            if (_paymentTier == 'acquiring') ...[
              AppSelect<String>(
                label: 'Провайдер',
                value: 'tinkoff',
                items: const [
                  SelectItem(value: 'tinkoff', label: 'Tinkoff Acquiring'),
                  SelectItem(value: 'yookassa', label: 'YooKassa'),
                  SelectItem(value: 'cloud', label: 'CloudPayments'),
                ],
                onChanged: (_) {},
              ),
              const SizedBox(height: 12),
            ],
            AppTextField(label: 'ИНН'),
            const SizedBox(height: 12),
            AppTextField(label: 'Merchant ID / Terminal Key'),
            const SizedBox(height: 16),
            AppButton.primary(
              text: 'Подключить интеграцию',
              icon: Icons.check,
              onPressed: () => AppSnackBar.info(context, 'Тестовое подключение...'),
            ),
          ],
        ),
      ],
      const SizedBox(height: 80),
    ]);
  }

  Widget _tierOption(ColorScheme cs, String value, IconData icon, String title, String subtitle, Color? color) {
    final selected = _paymentTier == value;
    final c = color ?? cs.primary;
    return GestureDetector(
      onTap: () => setState(() => _paymentTier = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? c.withValues(alpha: 0.1) : cs.surfaceContainerHighest.withValues(alpha: 0.3),
          border: Border.all(color: selected ? c.withValues(alpha: 0.5) : cs.outlineVariant.withValues(alpha: 0.5), width: selected ? 1.5 : 1),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: selected ? c.withValues(alpha: 0.2) : cs.surfaceContainerHighest, shape: BoxShape.circle),
            child: Icon(icon, size: 20, color: selected ? c : cs.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: selected ? c : cs.onSurface)),
            Text(subtitle, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ])),
          if (selected) Icon(Icons.radio_button_checked, color: c, size: 20) else Icon(Icons.radio_button_unchecked, color: cs.onSurfaceVariant.withValues(alpha: 0.5), size: 20),
        ]),
      ),
    );
  }

  Widget _priceRow(ColorScheme cs, String label, int? price, String symbol, Color color, VoidCallback onEdit) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
      Container(width: 4, height: 32, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Text(price != null ? '$price $symbol' : 'Бесплатно', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
      ),
      const SizedBox(width: 4),
      IconButton(icon: const Icon(Icons.edit, size: 18), visualDensity: VisualDensity.compact, onPressed: onEdit, color: cs.onSurfaceVariant),
    ]));
  }

  Color _sportColor(ColorScheme cs, int i) => [cs.primary, cs.secondary, cs.tertiary, cs.error, cs.primary][i % 5];

  String _currencySymbol(String code) => switch (code) {
    'RUB' => '₽', 'USD' => '\$', 'EUR' => '€', 'KZT' => '₸', 'BYN' => 'Br', _ => code,
  };

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

  void _editPrice(BuildContext context, String name, String discId, int? current, String symbol) {
    final ctrl = TextEditingController(text: '${current ?? 0}');
    AppBottomSheet.show(context, title: name, child: Column(mainAxisSize: MainAxisSize.min, children: [
      AppTextField(
        label: 'Цена ($symbol)',
        controller: ctrl,
        hintText: '0 = бесплатно',
        keyboardType: TextInputType.number,
        autofocus: true,
      ),
      const SizedBox(height: 16),
      AppButton.primary(
        text: 'Сохранить',
        onPressed: () {
          final price = int.tryParse(ctrl.text) ?? 0;
          ref.read(eventConfigProvider.notifier).updateDiscipline(
            discId, (d) => d.copyWith(priceRub: price > 0 ? price : null),
          );
          Navigator.pop(context);
        },
      ),
    ]));
  }

  void _editDiscount(BuildContext context, int current, void Function(PricingConfig Function(PricingConfig)) updatePricing) {
    final ctrl = TextEditingController(text: '$current');
    AppBottomSheet.show(context, title: 'Скидка Early Bird', child: Column(mainAxisSize: MainAxisSize.min, children: [
      AppTextField(
        label: 'Процент',
        controller: ctrl,
        keyboardType: TextInputType.number,
        autofocus: true,
      ),
      const SizedBox(height: 16),
      AppButton.primary(
        text: 'Сохранить',
        onPressed: () {
          updatePricing((p) => p.copyWith(earlyBirdDiscountPercent: (int.tryParse(ctrl.text) ?? 20).clamp(1, 100)));
          Navigator.pop(context);
        },
      ),
    ]));
  }

  Widget _reqCard(ColorScheme cs, IconData icon, String value, String label) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: cs.surfaceContainerHighest.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Icon(icon, size: 20, color: cs.primary),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, fontFeatures: [FontFeature.tabularFigures()])),
          Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ])),
        IconButton(icon: const Icon(Icons.copy, size: 16), visualDensity: VisualDensity.compact, onPressed: () {}, color: cs.primary),
      ]),
    );
  }
}
