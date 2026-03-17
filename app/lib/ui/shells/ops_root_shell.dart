import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/floating_nav_bar.dart'; // Added import

/// The Ops Shell wraps all judge/organizer screens with:
/// 1. An orange context banner at the top (with exit button)
/// 2. A 4-tab bottom navigation bar
class OpsRootShell extends StatelessWidget {
  final Widget child;

  const OpsRootShell({super.key, required this.child});

  int _calcIndex(String location) {
    if (location.contains('/checkin')) return 1;
    if (location.contains('/timing')) return 2;
    if (location.contains('/results')) return 3;
    return 0; // dash is default
  }

  String _eventId(String location) {
    final segments = location.split('/');
    final opsIdx = segments.indexOf('ops');
    if (opsIdx != -1 && opsIdx + 1 < segments.length) {
      return segments[opsIdx + 1];
    }
    return 'evt-1';
  }

  bool _shouldHideNavBar(String location) {
    // Hide bottom bar if we are deeper than the main ops tabs.
    // E.g., /ops/evt-1/timing/starter -> 5 segments (after split by /)
    // Actually, split('/') on '/ops/evt-1/timing/starter' gives:
    // ['', 'ops', 'evt-1', 'timing', 'starter'] -> length 5
    final segments = location.split('/').where((s) => s.isNotEmpty).toList();
    // basic ops routes: 'ops', 'evt-1', 'dash' -> length 3
    if (segments.length > 3) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final currentIndex = _calcIndex(location);
    final eventId = _eventId(location);
    final hideNavBar = _shouldHideNavBar(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: hideNavBar
          ? null
          : FloatingNavBar(
              currentIndex: currentIndex,
              onTap: (idx) {
                switch (idx) {
                  case 0:
                    context.go('/ops/$eventId/dash');
                  case 1:
                    context.go('/ops/$eventId/checkin');
                  case 2:
                    context.go('/ops/$eventId/timing');
                  case 3:
                    context.go('/ops/$eventId/results');
                }
              },
              items: const [
                FloatingNavItem(
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: 'Дашборд',
                ),
                FloatingNavItem(
                  icon: Icons.badge_outlined,
                  activeIcon: Icons.badge,
                  label: 'Чек-ин',
                ),
                FloatingNavItem(
                  icon: Icons.timer_outlined,
                  activeIcon: Icons.timer,
                  label: 'Тайминг',
                ),
                FloatingNavItem(
                  icon: Icons.emoji_events_outlined,
                  activeIcon: Icons.emoji_events,
                  label: 'Результаты',
                ),
              ],
            ),
    );
  }
}
