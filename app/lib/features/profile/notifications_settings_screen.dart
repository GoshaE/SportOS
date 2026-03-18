import 'package:flutter/material.dart';
import '../../core/widgets/widgets.dart';
import '../../core/theme/app_colors.dart';
import 'package:sportos_app/core/widgets/app_app_bar.dart';

/// Screen: Notification Settings (extracted from SettingsScreen)
/// Controls per-group per-channel notification toggles + quiet mode.
class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  // Уведомления per-group per-channel (TODO: → Riverpod provider)
  final Map<String, Map<String, bool>> _notif = {
    'events':    {'push': true,  'email': true,  'tg': true},
    'clubs':     {'push': true,  'email': false, 'tg': true},
    'trainer':   {'push': true,  'email': false, 'tg': true},
    'dogs':      {'push': true,  'email': false, 'tg': false},
    'marketing': {'push': false, 'email': false, 'tg': false},
  };

  bool _quietMode = false;
  final String _quietFrom = '23:00';
  final String _quietTo = '07:00';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    

    return Scaffold(
      appBar: AppAppBar(title: const Text('Уведомления')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ═══ Каналы по категориям ═══
          AppSectionHeader(title: 'Категории', icon: Icons.category),
          _notifGroup('Мероприятия', Icons.emoji_events, 'events', 'Результаты, стартовые листы, расписание'),
          _notifGroup('Клубы', Icons.groups, 'clubs', 'Заявки, взносы, мероприятия клуба'),
          _notifGroup('Тренер', Icons.sports, 'trainer', 'Результаты воспитанников, PB'),
          _notifGroup('Собаки', Icons.pets, 'dogs', 'Вакцинации, ветконтроль'),
          _notifGroup('Маркетинг', Icons.campaign, 'marketing', 'Новости, рекомендации'),
          const SizedBox(height: 16),

          // ═══ Тихий режим ═══
          AppSectionHeader(title: 'Тихий режим', icon: Icons.do_not_disturb_on),
          Card(
            child: Column(children: [
              SwitchListTile(
                title: const Text('Тихий режим'),
                subtitle: Text(
                  _quietMode ? '$_quietFrom — $_quietTo' : 'Выключен',
                  style: theme.textTheme.bodySmall,
                ),
                value: _quietMode,
                secondary: const Icon(Icons.nights_stay),
                onChanged: (v) => setState(() => _quietMode = v),
              ),
              if (_quietMode) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    Expanded(child: AppButton.secondary(text: 'С $_quietFrom', onPressed: () {})),
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('—')),
                    Expanded(child: AppButton.secondary(text: 'До $_quietTo', onPressed: () {})),
                  ]),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: AppInfoBanner.error(
                    title: 'Критичные уведомления доставляются всегда',
                    subtitle: 'SOS, Security Alert',
                  ),
                ),
              ],
            ]),
          ),
        ],
      ),
    );
  }

  Widget _notifGroup(String label, IconData icon, String key, String description) {
    final channels = _notif[key]!;
    final activeCount = channels.values.where((v) => v).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ExpansionTile(
        leading: Icon(icon, size: 20),
        title: Text(label, style: Theme.of(context).textTheme.titleSmall),
        subtitle: Text(description, style: Theme.of(context).textTheme.bodySmall),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (activeCount > 0)
            StatusBadge(text: '$activeCount/3', type: BadgeType.info)
          else
            const Icon(Icons.notifications_off, size: 16, color: Colors.grey),
          const SizedBox(width: 4),
        ]),
        children: [
          _channelSwitch(key, 'push', 'Push', Icons.notifications_active, Theme.of(context).colorScheme.primary),
          _channelSwitch(key, 'email', 'Email', Icons.email, Theme.of(context).colorScheme.tertiary),
          _channelSwitch(key, 'tg', 'Telegram', Icons.telegram, AppColors.accent),
        ],
      ),
    );
  }

  Widget _channelSwitch(String group, String channel, String label, IconData icon, Color color) {
    return SwitchListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      secondary: Icon(icon, size: 18, color: color),
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      value: _notif[group]![channel]!,
      onChanged: (v) => setState(() => _notif[group]![channel] = v),
    );
  }
}
