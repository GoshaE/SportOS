import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/widgets.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen ID: C4 — Создать клуб (визард с 3 шагами)
class CreateClubScreen extends StatefulWidget {
  const CreateClubScreen({super.key});

  @override
  State<CreateClubScreen> createState() => _CreateClubScreenState();
}

class _CreateClubScreenState extends State<CreateClubScreen> {
  int _step = 0;
  String _feeType = 'annual';
  final Set<String> _sports = {};

  static const _sportList = <String, (String, IconData)>{
    'sled': ('Ездовой спорт', Icons.pets),
    'canicross': ('Каникросс', Icons.directions_run),
    'trail': ('Трейл', Icons.terrain),
    'running': ('Лёгкая атлетика', Icons.directions_run),
    'skiing': ('Лыжные гонки', Icons.downhill_skiing),
    'cycling': ('Велоспорт', Icons.pedal_bike),
    'swimming': ('Плавание', Icons.pool),
    'triathlon': ('Триатлон', Icons.emoji_events),
  };

  static const _stepTitles = ['О клубе', 'Спорт и контакты', 'Взносы'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppAppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('Создать клуб'),
      ),
      body: Column(children: [
        // ── Step indicator ──
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Row(
            children: List.generate(3, (i) {
              final active = i <= _step;
              final current = i == _step;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: i > 0 ? 4 : 0),
                  child: Column(children: [
                    Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: active ? cs.primary : cs.outlineVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _stepTitles[i],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: current ? FontWeight.bold : FontWeight.normal,
                        color: current ? cs.primary : cs.onSurfaceVariant,
                      ),
                    ),
                  ]),
                ),
              );
            }),
          ),
        ),

        // ── Step content ──
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: [_stepAbout, _stepSports, _stepFees][_step](theme, cs),
          ),
        ),

        // ── Bottom actions ──
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              if (_step > 0)
                Expanded(
                  child: AppButton.secondary(
                    text: 'Назад',
                    onPressed: () => setState(() => _step--),
                  ),
                ),
              if (_step > 0) const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: AppButton.primary(
                  text: _step < 2 ? 'Продолжить' : '🚀 Создать клуб',
                  onPressed: () {
                    if (_step < 2) {
                      setState(() => _step++);
                    } else {
                      AppSnackBar.success(context, 'Клуб «Быстрые лапы» создан! 🎉');
                      context.push('/clubs/club-1');
                    }
                  },
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════
  // Step 1: О клубе
  // ═══════════════════════════════════════
  Widget _stepAbout(ThemeData theme, ColorScheme cs) {
    return ListView(
      key: const ValueKey('step-0'),
      padding: const EdgeInsets.all(20),
      children: [
        // Hero section
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary.withValues(alpha: 0.08), cs.tertiary.withValues(alpha: 0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: [
            AppAvatar(name: '📷', size: 80, editable: true, onEdit: () {}),
            const SizedBox(height: 8),
            Text('Логотип клуба', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text('Нажмите чтобы загрузить', style: TextStyle(fontSize: 11, color: cs.outline)),
          ]),
        ),
        const SizedBox(height: 20),

        const AppTextField(
          label: 'Название клуба *',
          prefixIcon: Icons.badge,
          hintText: 'Быстрые лапы',
        ),
        const SizedBox(height: 14),
        const AppTextField(
          label: 'Город *',
          prefixIcon: Icons.location_city,
          hintText: 'Санкт-Петербург',
        ),
        const SizedBox(height: 14),
        const AppTextField(
          label: 'Описание',
          prefixIcon: Icons.description,
          hintText: 'Расскажите о вашем клубе...',
          maxLines: 3,
        ),
      ],
    );
  }

  // ═══════════════════════════════════════
  // Step 2: Спорт и контакты
  // ═══════════════════════════════════════
  Widget _stepSports(ThemeData theme, ColorScheme cs) {
    return ListView(
      key: const ValueKey('step-1'),
      padding: const EdgeInsets.all(20),
      children: [
        AppSectionHeader(title: 'Виды спорта *', icon: Icons.sports, padding: EdgeInsets.zero),
        const SizedBox(height: 4),
        Text('Выберите один или несколько', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: _sportList.entries.map((e) {
          final selected = _sports.contains(e.key);
          return FilterChip(
            avatar: Icon(e.value.$2, size: 18),
            label: Text(e.value.$1),
            selected: selected,
            onSelected: (v) => setState(() {
              if (v) { _sports.add(e.key); } else { _sports.remove(e.key); }
            }),
          );
        }).toList()),

        const SizedBox(height: 24),
        AppSectionHeader(title: 'Контакты', icon: Icons.contact_mail, padding: EdgeInsets.zero),
        const SizedBox(height: 4),
        Text('Как участники смогут связаться с клубом', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 12),
        const AppTextField(label: 'Telegram', prefixIcon: Icons.telegram, hintText: '@ваш_канал'),
        const SizedBox(height: 10),
        const AppTextField(label: 'VK', prefixIcon: Icons.language, hintText: 'vk.com/ваша_группа'),
        const SizedBox(height: 10),
        const AppTextField(label: 'Email', prefixIcon: Icons.email, hintText: 'club@example.ru'),
      ],
    );
  }

  // ═══════════════════════════════════════
  // Step 3: Взносы
  // ═══════════════════════════════════════
  Widget _stepFees(ThemeData theme, ColorScheme cs) {
    return ListView(
      key: const ValueKey('step-2'),
      padding: const EdgeInsets.all(20),
      children: [
        AppSectionHeader(title: 'Членский взнос', icon: Icons.attach_money, padding: EdgeInsets.zero),
        const SizedBox(height: 4),
        Text('Настройте оплату для участников', style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 16),

        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'free', icon: Icon(Icons.money_off, size: 18), label: Text('Бесплатно')),
            ButtonSegment(value: 'annual', icon: Icon(Icons.calendar_month, size: 18), label: Text('Ежегодный')),
            ButtonSegment(value: 'monthly', icon: Icon(Icons.date_range, size: 18), label: Text('Месячный')),
          ],
          selected: {_feeType},
          onSelectionChanged: (s) => setState(() => _feeType = s.first),
        ),

        if (_feeType == 'free') ...[
          const SizedBox(height: 24),
          AppInfoBanner(
            title: 'Бесплатный клуб',
            subtitle: 'Любой может присоединиться без оплаты. Вы сможете включить взносы позже.',
            icon: Icons.celebration,
          ),
        ] else ...[
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: AppTextField(label: 'Взрослый ₽ *', hintText: _feeType == 'annual' ? '3000' : '500')),
            const SizedBox(width: 8),
            const Expanded(child: AppTextField(label: 'Ребёнок ₽', hintText: '1500')),
          ]),
          const SizedBox(height: 10),
          const AppTextField(label: 'Семейный ₽ (необязательно)', hintText: '5000'),

          const SizedBox(height: 16),
          AppInfoBanner(
            title: 'Процесс вступления',
            subtitle: 'Заявка → Одобрение → Оплата взноса → Активный участник',
            icon: Icons.route,
          ),
        ],

        const SizedBox(height: 24),
        // Preview card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.visibility, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text('Предпросмотр', style: theme.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                const AppAvatar(name: '📷', size: 44),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Ваш клуб', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text(
                    _feeType == 'free' ? 'Бесплатное вступление' : 'Взнос: ${_feeType == 'annual' ? '3 000 ₽/год' : '500 ₽/мес'}',
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ])),
                StatusBadge(
                  text: _feeType == 'free' ? 'Бесплатно' : 'Платный',
                  type: _feeType == 'free' ? BadgeType.success : BadgeType.info,
                ),
              ]),
            ]),
          ),
        ),
      ],
    );
  }
}
