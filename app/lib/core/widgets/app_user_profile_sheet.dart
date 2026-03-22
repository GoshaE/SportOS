import 'package:flutter/material.dart';
import 'widgets.dart';

/// Universal User Profile Modal
///
/// Shows a rich, iOS-style profile card for any user.
/// Includes their stats, timeline, and contextual management buttons
/// if opened by an organizer.
class AppUserProfileSheet {
  static void show(
    BuildContext outerContext, {
    required Map<String, dynamic> user,
    bool isOrganizer = false,
    List<Widget> Function(BuildContext innerContext)? contextActionsBuilder,
  }) {
    final cs = Theme.of(outerContext).colorScheme;
    final String name = user['name'] ?? 'Неизвестный участник';
    final String initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    // Fallback info
    final String club = user['club'] ?? 'Без клуба';
    final String role = user['role'] ?? 'volunteer';

    AppBottomSheet.show(
      outerContext,
      title: 'Профиль участника',
      initialHeight: 0.85,
      child: SizedBox(
        height: MediaQuery.of(outerContext).size.height * 0.8,
        child: Navigator(
          onGenerateRoute: (settings) {
            return AppGlassRoute(
              child: Builder(
                builder: (innerContext) => SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1. Hero Header
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: cs.primaryContainer,
                        child: Text(
                          initial,
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        club,
                        style: TextStyle(
                          fontSize: 14,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 2. Bento Stats
                      Row(
                        children: [
                          Expanded(
                            child: AppStatCard(
                              value: '4.8',
                              label: 'Рейтинг',
                              color: cs.secondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppStatCard(
                              value: '12',
                              label: 'Гонок',
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppStatCard(
                              value: 'Top 5%',
                              label: 'Ранг',
                              color: cs.tertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 3. Organizer Context Actions
                      if (isOrganizer &&
                          contextActionsBuilder != null &&
                          contextActionsBuilder(innerContext).isNotEmpty)
                        ...(() {
                          final contextActions = contextActionsBuilder(
                            innerContext,
                          );
                          return [
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Управление',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            AppCard(
                              padding: const EdgeInsets.all(4),
                              children: [
                                for (
                                  int i = 0;
                                  i < contextActions.length;
                                  i++
                                ) ...[
                                  contextActions[i],
                                  if (i < contextActions.length - 1)
                                    const Divider(height: 1, indent: 56),
                                ],
                              ],
                            ),
                            const SizedBox(height: 24),
                          ];
                        }())
                      else if (role != 'volunteer' && role != 'competitor') ...[
                        // If not an organizer looking at it, but the person HAS a role, show role badge
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Icon(Icons.shield, size: 16, color: cs.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Команда организаторов',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: cs.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // 4. Timeline
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Последние отметки',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildTimelineItem(
                            innerContext,
                            '09:00:00',
                            'Старт',
                            isCompleted: true,
                            isFirst: true,
                          ),
                          _buildTimelineItem(
                            innerContext,
                            '09:45:12',
                            'CP1 — 3км',
                            isCompleted: true,
                          ),
                          _buildTimelineItem(
                            innerContext,
                            '—',
                            'CP2 — 5км',
                            isCurrent: true,
                          ),
                          _buildTimelineItem(
                            innerContext,
                            '—',
                            'Финиш',
                            isLast: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  static Widget _buildTimelineItem(
    BuildContext context,
    String time,
    String label, {
    bool isCompleted = false,
    bool isCurrent = false,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final cs = Theme.of(context).colorScheme;
    final color = isCompleted
        ? cs.primary
        : (isCurrent ? cs.tertiary : cs.outlineVariant);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline graphics
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(
                  width: 2,
                  height: 16,
                  color: isFirst ? Colors.transparent : color,
                ),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isCompleted ? color : Colors.transparent,
                    border: Border.all(color: color, width: 2),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast
                        ? Colors.transparent
                        : (isCompleted ? color : cs.outlineVariant),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isCompleted || isCurrent
                          ? cs.onSurface
                          : cs.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 14,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontWeight: isCompleted
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isCompleted ? cs.onSurface : cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
