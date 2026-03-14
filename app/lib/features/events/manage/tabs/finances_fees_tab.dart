import 'package:flutter/material.dart';
import '../../../../core/widgets/widgets.dart';

class FinancesFeesTab extends StatefulWidget {
  const FinancesFeesTab({super.key});

  @override
  State<FinancesFeesTab> createState() => _FinancesFeesTabState();
}

class _FinancesFeesTabState extends State<FinancesFeesTab> {
  String _paymentTier = 'sbp';
  String _pricingMode = 'single';
  bool _earlyBird = true;
  String _earlyBirdType = 'percent';
  int _earlyBirdValue = 15;
  int _bookingTimeout = 24;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(padding: const EdgeInsets.all(12), children: [
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
        AppCard(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [
              Icon(Icons.payments, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              const Text('Цены', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const Spacer(),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'single', label: Text('Единая', style: TextStyle(fontSize: 11))),
                  ButtonSegment(value: 'per_discipline', label: Text('По дисц.', style: TextStyle(fontSize: 11))),
                ],
                selected: {_pricingMode},
                onSelectionChanged: (s) => setState(() => _pricingMode = s.first),
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
              ),
            ]),
            const SizedBox(height: 16),
            if (_pricingMode == 'single')
              _priceRow(cs, 'Единая цена', 5000, cs.primary)
            else ...[
              _priceRow(cs, 'Скиджоринг 5км', 2000, cs.primary),
              _priceRow(cs, 'Скиджоринг 10км', 2500, cs.secondary),
              _priceRow(cs, 'Каникросс 3км', 1500, cs.tertiary),
              _priceRow(cs, 'Нарты 15км', 3000, cs.error),
              const SizedBox(height: 8),
              OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.add, size: 16), label: const Text('Добавить дисциплину'), style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact)),
            ],
          ],
        ),
        const SizedBox(height: 12),

        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: AppCard(
            padding: const EdgeInsets.all(16),
            backgroundColor: _earlyBird ? cs.tertiary.withValues(alpha: 0.1) : null,
            borderColor: _earlyBird ? cs.tertiary.withValues(alpha: 0.3) : null,
            children: [
              Row(children: [
                Icon(Icons.access_time_filled, color: _earlyBird ? cs.tertiary : cs.onSurfaceVariant, size: 20),
                const SizedBox(width: 8),
                const Expanded(child: Text('Early Bird', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                SizedBox(
                  height: 24,
                  child: Switch(value: _earlyBird, onChanged: (v) => setState(() => _earlyBird = v)),
                ),
              ]),
              if (_earlyBird) ...[
                const SizedBox(height: 12),
                Row(children: [
                  SegmentedButton<String>(
                    segments: const [ButtonSegment(value: 'percent', label: Text('%', style: TextStyle(fontSize: 12))), ButtonSegment(value: 'fixed', label: Text('₽', style: TextStyle(fontSize: 12)))],
                    selected: {_earlyBirdType},
                    onSelectionChanged: (s) => setState(() => _earlyBirdType = s.first),
                    style: const ButtonStyle(visualDensity: VisualDensity.compact),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_earlyBirdType == 'fixed' ? '−$_earlyBirdValue ₽' : '−$_earlyBirdValue%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: cs.tertiary), textAlign: TextAlign.right)),
                ]),
                const SizedBox(height: 8),
                Text('Действует до 01.03.2026', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
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
              DropdownButtonFormField<int>(
                initialValue: _bookingTimeout,
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                items: [12, 24, 48, 72].map((h) => DropdownMenuItem(value: h, child: Text('$h ч.'))).toList(),
                onChanged: (v) => setState(() => _bookingTimeout = v!),
              ),
              const SizedBox(height: 8),
              Text('На оплату после брони', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ],
          )),
        ]),
        const SizedBox(height: 12),

        if (_paymentTier == 'requisites') AppCard(
          padding: const EdgeInsets.all(16),
          children: [
            Row(children: [Icon(Icons.account_balance, size: 20, color: cs.primary), const SizedBox(width: 8), const Text('Реквизиты', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))]),
            const SizedBox(height: 16),
            _reqCard(cs, Icons.credit_card, '4276 **** **** 1234', 'Сбербанк'),
            _reqCard(cs, Icons.person, 'Иванов Иван Иванович', 'Получатель'),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.add, size: 16), label: const Text('Альтернативные реквизиты'), style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact)),
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
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Провайдер', border: OutlineInputBorder(), isDense: true), initialValue: 'tinkoff',
                items: const [DropdownMenuItem(value: 'tinkoff', child: Text('Tinkoff Acquiring')), DropdownMenuItem(value: 'yookassa', child: Text('YooKassa')), DropdownMenuItem(value: 'cloud', child: Text('CloudPayments'))],
                onChanged: (_) {},
              ),
              const SizedBox(height: 12),
            ],
            const TextField(decoration: InputDecoration(labelText: 'ИНН', border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Merchant ID / Terminal Key', border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: FilledButton.icon(
              onPressed: () => AppSnackBar.info(context, 'Тестовое подключение...'),
              icon: const Icon(Icons.check, size: 18), label: const Text('Подключить интеграцию'),
            )),
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
          Radio<String>(value: value, groupValue: _paymentTier, onChanged: (v) => setState(() => _paymentTier = v!), visualDensity: VisualDensity.compact),
        ]),
      ),
    );
  }

  Widget _priceRow(ColorScheme cs, String label, int price, Color color) {
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
      Container(width: 4, height: 32, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Text('$price ₽', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 15)),
      ),
      const SizedBox(width: 4),
      IconButton(icon: const Icon(Icons.edit, size: 18), visualDensity: VisualDensity.compact, onPressed: () {}, color: cs.onSurfaceVariant),
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
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, fontFamily: 'monospace')),
          Text(label, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
        ])),
        IconButton(icon: const Icon(Icons.copy, size: 16), visualDensity: VisualDensity.compact, onPressed: () {}, color: cs.primary),
      ]),
    );
  }
}
