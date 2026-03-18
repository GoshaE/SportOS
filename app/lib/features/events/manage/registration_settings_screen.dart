import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';
import '../../../domain/event/config_providers.dart';
import '../../../domain/event/event_config.dart' hide TimeOfDay;

/// Настройки регистрации — подключено к Config Engine.
///
/// Управление: открытие/закрытие, лимиты, waitlist,
/// поля формы (required/optional/hidden), кастомные поля.
class RegistrationSettingsScreen extends ConsumerWidget {
  const RegistrationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(eventConfigProvider);
    final reg = config.registrationConfig;
    final cs = Theme.of(context).colorScheme;

    void update(RegistrationConfig Function(RegistrationConfig r) fn) {
      ref.read(eventConfigProvider.notifier).update(
        (c) => c.copyWith(registrationConfig: fn(c.registrationConfig)),
      );
    }

    return Scaffold(
      appBar: AppAppBar(title: const Text('Регистрация')),
      body: ListView(padding: const EdgeInsets.all(16), children: [

        // ─── Статус ───
        _section(cs, 'Статус'),
        AppCard(padding: EdgeInsets.zero, children: [
          Column(children: [
            AppSettingsTile.toggle(
              title: 'Регистрация открыта',
              subtitle: reg.isOpen ? 'Участники могут подавать заявки' : 'Заявки не принимаются',
              value: reg.isOpen,
              onChanged: (v) => update((r) => r.copyWith(isOpen: v)),
            ),
          ]),
        ]),
        const SizedBox(height: 16),

        // ─── Лимиты ───
        _section(cs, 'Лимиты'),
        AppCard(padding: EdgeInsets.zero, children: [
          Column(children: [
            AppSettingsTile.nav(
              title: 'Макс. участников',
              subtitle: reg.maxParticipants?.toString() ?? 'Без лимита',
              onTap: () => _editNumber(context, 'Макс. участников', reg.maxParticipants, (v) {
                update((r) => r.copyWith(maxParticipants: v ?? 0));
              }),
            ),
            const Divider(height: 1, indent: 16),
            AppSettingsTile.toggle(
              title: 'Waitlist',
              subtitle: reg.waitlistEnabled
                  ? 'Вкл. (макс. ${reg.waitlistMax ?? '∞'})'
                  : 'Выключен',
              value: reg.waitlistEnabled,
              onChanged: (v) => update((r) => r.copyWith(waitlistEnabled: v)),
            ),
          ]),
        ]),
        const SizedBox(height: 16),

        // ─── Публичность ───
        _section(cs, 'Публичность'),
        AppCard(padding: EdgeInsets.zero, children: [
          Column(children: [
            AppSettingsTile.toggle(
              title: 'Публичный стартовый лист',
              value: reg.publicStartList,
              onChanged: (v) => update((r) => r.copyWith(publicStartList: v)),
            ),
            const Divider(height: 1, indent: 16),
            AppSettingsTile.toggle(
              title: 'Публичные результаты',
              value: reg.publicResults,
              onChanged: (v) => update((r) => r.copyWith(publicResults: v)),
            ),
          ]),
        ]),
        const SizedBox(height: 16),

        // ─── Возраст ───
        _section(cs, 'Расчёт возраста'),
        AppCard(padding: EdgeInsets.zero, children: [
          Column(children: [
            AppSettingsTile.nav(
              title: 'Метод расчёта',
              subtitle: config.ageCalculation == AgeCalculation.byYear
                  ? 'По году рождения (стандарт FIS)'
                  : 'Точный на дату гонки',
              onTap: () {
                final next = config.ageCalculation == AgeCalculation.byYear
                    ? AgeCalculation.exactDate
                    : AgeCalculation.byYear;
                ref.read(eventConfigProvider.notifier).update(
                    (c) => c.copyWith(ageCalculation: next));
              },
            ),
          ]),
        ]),
        const SizedBox(height: 16),

        // ─── Оплата ───
        _section(cs, 'Возврат оплаты'),
        AppCard(padding: EdgeInsets.zero, children: [
          Column(children: [
            AppSettingsTile.toggle(
              title: 'Возврат разрешён',
              subtitle: reg.refundEnabled ? 'До ${reg.refundDeadlineHours}ч до старта' : 'Без возврата',
              value: reg.refundEnabled,
              onChanged: (v) => update((r) => r.copyWith(refundEnabled: v)),
            ),
          ]),
        ]),
        const SizedBox(height: 24),

        // ─── Поля формы: участник ───
        _section(cs, 'Поля формы: участник'),
        _fieldInfo(cs),
        const SizedBox(height: 8),
        AppCard(padding: EdgeInsets.zero, children: [
          Column(children: [
            _FieldRow(label: 'ФИО', icon: Icons.person, value: reg.fieldName,
              locked: true, onChanged: (_) {}),
            const Divider(height: 1, indent: 16),
            _FieldRow(label: 'Дата рождения', icon: Icons.cake, value: reg.fieldBirthDate,
              onChanged: (v) => update((r) => r.copyWith(fieldBirthDate: v))),
            const Divider(height: 1, indent: 16),
            _FieldRow(label: 'Пол', icon: Icons.wc, value: reg.fieldGender,
              onChanged: (v) => update((r) => r.copyWith(fieldGender: v))),
            const Divider(height: 1, indent: 16),
            _FieldRow(label: 'Телефон', icon: Icons.phone, value: reg.fieldPhone,
              onChanged: (v) => update((r) => r.copyWith(fieldPhone: v))),
            const Divider(height: 1, indent: 16),
            _FieldRow(label: 'E-mail', icon: Icons.email, value: reg.fieldEmail,
              onChanged: (v) => update((r) => r.copyWith(fieldEmail: v))),
            const Divider(height: 1, indent: 16),
            _FieldRow(label: 'Клуб / команда', icon: Icons.group, value: reg.fieldClub,
              onChanged: (v) => update((r) => r.copyWith(fieldClub: v))),
            const Divider(height: 1, indent: 16),
            _FieldRow(label: 'Город', icon: Icons.location_city, value: reg.fieldCity,
              onChanged: (v) => update((r) => r.copyWith(fieldCity: v))),
          ]),
        ]),
        const SizedBox(height: 16),

        // ─── Поля формы: собака ───
        _section(cs, 'Поля формы: собака'),
        Text('Включите для ездового спорта', style: TextStyle(fontSize: 11, color: cs.outline)),
        const SizedBox(height: 8),
        AppCard(padding: EdgeInsets.zero, children: [
          Column(children: [
            _FieldRow(label: 'Кличка собаки', icon: Icons.pets, value: reg.fieldDogName,
              onChanged: (v) => update((r) => r.copyWith(fieldDogName: v))),
            const Divider(height: 1, indent: 16),
            _FieldRow(label: 'Порода', icon: Icons.pets, value: reg.fieldDogBreed,
              onChanged: (v) => update((r) => r.copyWith(fieldDogBreed: v))),
            const Divider(height: 1, indent: 16),
            _FieldRow(label: 'Вет. справка', icon: Icons.medical_services, value: reg.fieldVetCert,
              onChanged: (v) => update((r) => r.copyWith(fieldVetCert: v))),
            const Divider(height: 1, indent: 16),
            _FieldRow(label: 'Чип-номер', icon: Icons.nfc, value: reg.fieldChipNumber,
              onChanged: (v) => update((r) => r.copyWith(fieldChipNumber: v))),
          ]),
        ]),
        const SizedBox(height: 16),

        // ─── Кастомные поля ───
        _section(cs, 'Свои поля'),
        if (reg.customFields.isNotEmpty) ...[
          ...reg.customFields.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: AppCard(padding: EdgeInsets.zero, children: [
              ListTile(
                dense: true,
                leading: Icon(_typeIcon(f.type), size: 18, color: cs.primary),
                title: Text(f.label, style: const TextStyle(fontSize: 13)),
                subtitle: Text(_visibilityLabel(f.visibility), style: TextStyle(fontSize: 11, color: cs.outline)),
                trailing: IconButton(
                  icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
                  onPressed: () {
                    final updated = List<CustomField>.from(reg.customFields)
                      ..removeWhere((c) => c.id == f.id);
                    update((r) => r.copyWith(customFields: updated));
                  },
                ),
              ),
            ]),
          )),
        ],
        OutlinedButton.icon(
          onPressed: () => _addCustomField(context, update, reg),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Добавить поле'),
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

  Widget _fieldInfo(ColorScheme cs) {
    return Row(children: [
      _legend(cs, '🔴', 'Обязательное'),
      const SizedBox(width: 12),
      _legend(cs, '🟡', 'Необязательное'),
      const SizedBox(width: 12),
      _legend(cs, '⚫', 'Скрытое'),
    ]);
  }

  Widget _legend(ColorScheme cs, String dot, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(dot, style: const TextStyle(fontSize: 10)),
      const SizedBox(width: 3),
      Text(text, style: TextStyle(fontSize: 10, color: cs.outline)),
    ]);
  }

  void _editNumber(BuildContext context, String title, int? current, ValueChanged<int?> onSave) {
    final ctrl = TextEditingController(text: current?.toString() ?? '');
    AppBottomSheet.show(context, title: title, child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(
        controller: ctrl,
        decoration: const InputDecoration(labelText: 'Количество', border: OutlineInputBorder(), hintText: 'Пустое = без лимита'),
        keyboardType: TextInputType.number,
        autofocus: true,
      ),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, child: FilledButton(
        onPressed: () {
          onSave(int.tryParse(ctrl.text));
          Navigator.pop(context);
        },
        child: const Text('Сохранить'),
      )),
    ]));
  }

  void _addCustomField(BuildContext context, void Function(RegistrationConfig Function(RegistrationConfig)) update, RegistrationConfig reg) {
    final ctrl = TextEditingController();
    var type = CustomFieldType.text;
    var vis = FieldVisibility.optional;

    AppBottomSheet.show(context, title: 'Новое поле', child: StatefulBuilder(
      builder: (ctx, setModal) => Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Название поля *', border: OutlineInputBorder(), hintText: 'Например: Номер лицензии'),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: DropdownButtonFormField<CustomFieldType>(
            initialValue: type,
            decoration: const InputDecoration(labelText: 'Тип', border: OutlineInputBorder(), isDense: true),
            items: const [
              DropdownMenuItem(value: CustomFieldType.text, child: Text('Текст')),
              DropdownMenuItem(value: CustomFieldType.number, child: Text('Число')),
              DropdownMenuItem(value: CustomFieldType.checkbox, child: Text('Галочка')),
            ],
            onChanged: (v) => setModal(() => type = v!),
          )),
          const SizedBox(width: 12),
          Expanded(child: DropdownButtonFormField<FieldVisibility>(
            initialValue: vis,
            decoration: const InputDecoration(labelText: 'Режим', border: OutlineInputBorder(), isDense: true),
            items: const [
              DropdownMenuItem(value: FieldVisibility.required, child: Text('Обязательное')),
              DropdownMenuItem(value: FieldVisibility.optional, child: Text('Необязательное')),
            ],
            onChanged: (v) => setModal(() => vis = v!),
          )),
        ]),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, child: FilledButton.icon(
          onPressed: () {
            if (ctrl.text.trim().isEmpty) { AppSnackBar.error(context, 'Введите название'); return; }
            final field = CustomField(
              id: 'cf-${DateTime.now().millisecondsSinceEpoch}',
              label: ctrl.text.trim(),
              type: type,
              visibility: vis,
            );
            update((r) => r.copyWith(customFields: [...r.customFields, field]));
            Navigator.pop(ctx);
          },
          icon: const Icon(Icons.add),
          label: const Text('Добавить'),
        )),
      ]),
    ));
  }

  String _visibilityLabel(FieldVisibility v) => switch (v) {
    FieldVisibility.required => 'Обязательное',
    FieldVisibility.optional => 'Необязательное',
    FieldVisibility.hidden => 'Скрытое',
  };

  IconData _typeIcon(CustomFieldType t) => switch (t) {
    CustomFieldType.text => Icons.text_fields,
    CustomFieldType.number => Icons.pin,
    CustomFieldType.dropdown => Icons.list,
    CustomFieldType.checkbox => Icons.check_box,
  };
}

// ─── Field Row with 3-state toggle ───

class _FieldRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final FieldVisibility value;
  final bool locked;
  final ValueChanged<FieldVisibility> onChanged;

  const _FieldRow({
    required this.label,
    required this.icon,
    required this.value,
    this.locked = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = switch (value) {
      FieldVisibility.required => Colors.red,
      FieldVisibility.optional => Colors.orange,
      FieldVisibility.hidden => cs.outline,
    };

    return ListTile(
      dense: true,
      leading: Icon(icon, size: 18, color: color),
      title: Text(label, style: TextStyle(
        fontSize: 13,
        color: value == FieldVisibility.hidden ? cs.outline : cs.onSurface,
        decoration: value == FieldVisibility.hidden ? TextDecoration.lineThrough : null,
      )),
      trailing: locked
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
              child: const Text('Обяз.', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
            )
          : SegmentedButton<FieldVisibility>(
              selected: {value},
              onSelectionChanged: (v) => onChanged(v.first),
              segments: const [
                ButtonSegment(value: FieldVisibility.required, label: Text('Обяз.', style: TextStyle(fontSize: 10))),
                ButtonSegment(value: FieldVisibility.optional, label: Text('Опц.', style: TextStyle(fontSize: 10))),
                ButtonSegment(value: FieldVisibility.hidden, label: Text('Выкл.', style: TextStyle(fontSize: 10))),
              ],
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
    );
  }
}
