import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: M2 — Регистрация на мероприятие (с собакой, промокодом, waiver)
class RegisterWizardScreen extends StatefulWidget {
  const RegisterWizardScreen({super.key});

  @override
  State<RegisterWizardScreen> createState() => _RegisterWizardScreenState();
}

class _RegisterWizardScreenState extends State<RegisterWizardScreen> {
  int _step = 0;
  String? _discipline = 'Скиджоринг 5км';
  String? _dog = 'Rex (Хаски)';
  bool _waiver = false;
  bool _pd = false;
  String _promo = '';
  bool _promoApplied = false;
  String _payMethod = 'card';
  bool _receiptUploaded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppAppBar(
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
        title: Text('Регистрация · шаг ${_step + 1}/3'),
      ),
      body: Stepper(
        currentStep: _step,
        onStepContinue: () {
          if (_step == 2) {
            if (!_waiver || !_pd) {
              AppSnackBar.error(context, 'Подтвердите согласия');
              return;
            }
            context.go('/my');
            AppSnackBar.success(context, 'Регистрация завершена!');
          } else {
            setState(() => _step++);
          }
        },
        onStepCancel: _step > 0 ? () => setState(() => _step--) : null,
        controlsBuilder: (ctx, details) => Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(children: [
            Expanded(child: AppButton.primary(
              text: _step == 2 ? 'Завершить регистрацию' : 'Далее',
              onPressed: details.onStepContinue ?? () {},
            )),
            if (_step > 0) ...[
              const SizedBox(width: 8),
              AppButton.secondary(text: 'Назад', onPressed: details.onStepCancel ?? () {}),
            ],
          ]),
        ),
        steps: [
          // ── Шаг 1: Дисциплина + категория ──
          Step(
            title: const Text('Дисциплина'),
            isActive: _step >= 0,
            content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppSelect<String>(
                label: 'Дисциплина',
                value: _discipline,
                items: ['Скиджоринг 5км', 'Скиджоринг 10км', 'Каникросс 3км', 'Нарты 30км']
                    .map((e) => SelectItem(value: e, label: e))
                    .toList(),
                onChanged: (v) => setState(() => _discipline = v),
              ),
              const SizedBox(height: 10),
              AppSelect<String>(
                label: 'Возрастная категория',
                value: 'M 25-34',
                items: ['M 18-24', 'M 25-34', 'M 35-44', 'Ж 25-34']
                    .map((e) => SelectItem(value: e, label: e))
                    .toList(),
                onChanged: (_) {},
              ),
            ]),
          ),

          // ── Шаг 2: Собака + промокод + оплата ──
          Step(
            title: const Text('Собака и оплата'),
            isActive: _step >= 1,
            content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AppSelect<String>(
                label: 'Выберите собаку',
                value: _dog,
                items: ['Rex (Хаски)', 'Luna (Маламут)', '+ Добавить собаку']
                    .map((e) => SelectItem(value: e, label: e))
                    .toList(),
                onChanged: (v) {
                  if (v == '+ Добавить собаку') {
                    context.push('/profile/dogs');
                  } else {
                    setState(() => _dog = v);
                  }
                },
              ),
              const SizedBox(height: 10),

              // Промокод
              Row(children: [
                Expanded(child: AppTextField(
                  label: 'Промокод (необязательно)',
                  prefixIcon: Icons.confirmation_number,
                  onChanged: (v) => setState(() => _promo = v),
                )),
                const SizedBox(width: 8),
                AppButton.secondary(
                  text: 'Применить',
                  onPressed: _promo.isNotEmpty ? () => setState(() => _promoApplied = true) : null,
                ),
              ]),
              if (_promoApplied) ...[
                const SizedBox(height: 6),
                AppInfoBanner.success(
                  title: 'Промокод применён',
                  subtitle: '-500₽ (скидка 20%)',
                ),
              ],
              const SizedBox(height: 12),

              // Стоимость
              AppCard(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('К оплате:', style: theme.textTheme.titleSmall),
                    Text(
                      _promoApplied ? '1 500₽' : '2 000₽',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _promoApplied ? cs.tertiary : null,
                      ),
                    ),
                  ]),
                ),
              ]),
              const SizedBox(height: 12),

              // Способ оплаты
              Text('Способ оплаты:', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'card', icon: Icon(Icons.credit_card, size: 16), label: Text('Перевод')),
                  ButtonSegment(value: 'sbp', icon: Icon(Icons.bolt, size: 16), label: Text('СБП')),
                  ButtonSegment(value: 'cash', icon: Icon(Icons.money, size: 16), label: Text('На месте')),
                ],
                selected: {_payMethod},
                onSelectionChanged: (s) => setState(() => _payMethod = s.first),
              ),
              const SizedBox(height: 8),

              if (_payMethod == 'card') ...[
                AppCard(children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Реквизиты для перевода:', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Row(children: [
                        Expanded(child: Text(
                          'Карта: 2200 7007 1234 5678\nПолучатель: Иванов И.И.\nНазначение: Рег BIB+Фио',
                          style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                        )),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () => AppSnackBar.info(context, 'Скопировано!'),
                        ),
                      ]),
                    ]),
                  ),
                ]),
                const SizedBox(height: 8),
                AppButton.secondary(
                  text: _receiptUploaded ? 'Чек загружен' : 'Загрузить чек/скриншот',
                  icon: _receiptUploaded ? Icons.check_circle : Icons.upload_file,
                  onPressed: () => setState(() => _receiptUploaded = true),
                ),
              ],
              if (_payMethod == 'sbp') ...[
                const SizedBox(height: 4),
                AppButton.primary(
                  text: 'Оплатить ${_promoApplied ? "1 500₽" : "2 000₽"} через СБП',
                  icon: Icons.bolt,
                  onPressed: () => AppSnackBar.info(context, 'Переход в приложение банка...'),
                ),
              ],
              if (_payMethod == 'cash')
                AppInfoBanner.warning(
                  title: 'Оплата на месте',
                  subtitle: 'При регистрации / чек-ине. Статус: Ожидает оплаты',
                ),
            ]),
          ),

          // ── Шаг 3: Согласия ──
          Step(
            title: const Text('Подтверждение'),
            isActive: _step >= 2,
            content: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Подтвердите документы:', style: theme.textTheme.titleSmall),
              const SizedBox(height: 6),
              CheckboxListTile(
                value: _waiver,
                onChanged: (v) => setState(() => _waiver = v!),
                title: Text('Waiver (отказ от претензий)', style: theme.textTheme.bodyMedium),
                subtitle: AppButton.text(text: 'Прочитать документ', onPressed: () {}),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
              CheckboxListTile(
                value: _pd,
                onChanged: (v) => setState(() => _pd = v!),
                title: Text('Согласие на обработку ПД', style: theme.textTheme.bodyMedium),
                subtitle: AppButton.text(text: 'Прочитать документ', onPressed: () {}),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
              const SizedBox(height: 8),
              AppCard(children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Итого:', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text('Дисциплина: $_discipline', style: theme.textTheme.bodySmall),
                    Text('Собака: $_dog', style: theme.textTheme.bodySmall),
                    Text('Оплата: ${_payMethod == 'card' ? 'Перевод на карту' : _payMethod == 'sbp' ? 'СБП' : 'На месте'}', style: theme.textTheme.bodySmall),
                    Text(_promoApplied ? 'Итого: 1 500₽ (промокод -500₽)' : 'Итого: 2 000₽', style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    if (_payMethod == 'card' && !_receiptUploaded)
                      AppInfoBanner.warning(title: 'Чек не загружен', subtitle: 'Статус: Ожидает проверки'),
                    if (_payMethod == 'card' && _receiptUploaded)
                      AppInfoBanner.success(title: 'Чек загружен', subtitle: 'Статус: На проверке'),
                    if (_payMethod == 'cash')
                      AppInfoBanner.warning(title: 'Ожидает оплаты', subtitle: 'Оплата на месте'),
                    if (_payMethod == 'sbp')
                      AppInfoBanner.success(title: 'Оплачено', subtitle: 'Через СБП'),
                  ]),
                ),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}
