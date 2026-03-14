import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/floating_nav_bar.dart';

/// L1: MainShell — Floating Pill NavBar с 5-ю табами.
/// Все не-Ops экраны рендерятся внутри этого Shell.
class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: FloatingNavBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        items: const [
          FloatingNavItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Главная',
          ),
          FloatingNavItem(
            icon: Icons.event_outlined,
            activeIcon: Icons.event_rounded,
            label: 'События',
          ),
          FloatingNavItem(
            icon: Icons.groups_outlined,
            activeIcon: Icons.groups_rounded,
            label: 'Клубы',
          ),
          FloatingNavItem(
            icon: Icons.notifications_outlined,
            activeIcon: Icons.notifications_rounded,
            badge: '3',
            label: 'Входящие',
          ),
          FloatingNavItem(
            icon: Icons.person_outlined,
            activeIcon: Icons.person_rounded,
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}
