import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:animations/animations.dart';

// Shells
import '../ui/shells/main_shell.dart';
import '../ui/shells/ops_root_shell.dart';

// Auth
import '../features/auth/welcome_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/otp_verify_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/qr_pairing_screen.dart';

// Hub Feed
import '../features/hub_feed/hub_feed_screen.dart';
import '../features/hub_feed/hub_search_screen.dart';

// Events
import '../features/events/event_detail_screen.dart';
import '../features/events/register_wizard_screen.dart';
import '../features/events/my_events_screen.dart';
import '../features/events/create_event_wizard_screen.dart';

// Event Manage
import '../features/events/manage/event_overview_screen.dart';
import '../features/events/manage/disciplines_screen.dart';
import '../features/events/manage/participants_screen.dart';
import '../features/events/manage/team_screen.dart';
import '../features/events/manage/finances_screen.dart';
import '../features/events/manage/documents_screen.dart';
import '../features/events/manage/multi_day_config_screen.dart';
import '../features/events/manage/basic_info_screen.dart';
import '../features/events/manage/bib_pool_screen.dart';
import '../features/events/manage/day_schedule_screen.dart';
import '../features/events/manage/courses_screen.dart';
import '../features/events/manage/display_settings_screen.dart';
import '../features/events/manage/timing_settings_screen.dart';
import '../features/events/manage/vet_settings_screen.dart';
import '../features/events/manage/registration_settings_screen.dart';
import '../features/events/manage/draw_settings_screen.dart';
import '../features/events/manage/categories_screen.dart';
import '../features/events/manage/prestart_checklist_screen.dart';
import '../features/events/manage/excel_import_screen.dart';
import '../features/events/series_screen.dart';

// Race Preparation
import '../features/events/prep/draw_screen.dart';
import '../features/events/prep/start_list_screen.dart';
import '../features/events/prep/bib_assign_screen.dart';
import '../features/events/prep/vet_check_screen.dart';
import '../features/events/prep/check_in_screen.dart';
import '../features/events/prep/mandate_screen.dart';

// Ops (Race Mode)
import '../features/ops/ops_dashboard_screen.dart';
import '../features/ops/ops_timing_hub_screen.dart';
import '../features/ops/starter_screen.dart';
import '../features/ops/finish_screen.dart';
import '../features/ops/marshal_screen.dart';
import '../features/ops/dictator_screen.dart';
import '../features/ops/gps_map_screen.dart';
import '../features/coach/coach_timing_screen.dart';

// Quick Timer
import '../features/quick_timer/quick_timer_screen.dart';
import '../features/quick_timer/quick_timer_results_screen.dart';
import '../features/quick_timer/quick_timer_history_screen.dart';
import '../features/quick_timer/qt_settings_screen.dart';

// Results
import '../features/results/live_results_screen.dart';
import '../features/results/protocol_screen.dart';
import '../features/results/protests_screen.dart';
import '../features/results/diploma_gen_screen.dart';

import '../features/profile/profile_screen.dart';
import '../features/profile/profile_documents_screen.dart';
import '../features/profile/my_dogs_screen.dart';
import '../features/profile/dog_detail_screen.dart';
import '../features/profile/my_results_screen.dart';
import '../features/profile/my_diplomas_screen.dart';
import '../features/profile/settings_screen.dart';
import '../features/profile/notifications_settings_screen.dart';
import '../features/profile/theme_settings_screen.dart';

// Trainer
import '../features/profile/trainer_screen.dart';

// Clubs
import '../features/clubs/my_clubs_screen.dart';
import '../features/clubs/club_profile_screen.dart';
import '../features/clubs/club_manage_screen.dart';
import '../features/clubs/create_club_screen.dart';

// Notifications
import '../features/notifications/inbox_screen.dart';

// Navigator keys for StatefulShellRoute branches
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _hubNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'hubNav');
final _myNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'myNav');
final _clubsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'clubsNav');
final _notificationsNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'notifNav');
final _profileNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'profNav');

/// Маршрутизатор SportOS.
/// 
/// Все 38+ экранов с Role-based Guards.
final GoRouter router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/hub',
  routes: [
    // ═══════════════════════════════════════════════
    // L1: MainShell — BottomNavigationBar (5 табов)
    // ═══════════════════════════════════════════════
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainShell(navigationShell: navigationShell);
      },
      branches: [
        // ── Tab 1: Хаб ──
        StatefulShellBranch(
          navigatorKey: _hubNavigatorKey,
          routes: [
            GoRoute(
              path: '/hub',
              name: 'hub',
              builder: (context, state) => const HubFeedScreen(),
              routes: [
                GoRoute(
                  parentNavigatorKey: _rootNavigatorKey,
                  path: 'search',
                  name: 'hub-search',
                  builder: (context, state) => const HubSearchScreen(),
                ),
                GoRoute(
                  parentNavigatorKey: _rootNavigatorKey,
                  path: 'event/:eventId',
                  name: 'event-detail',
                  pageBuilder: (context, state) => CustomTransitionPage(
                    key: state.pageKey,
                    child: const EventDetailScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return SharedAxisTransition(
                        animation: animation,
                        secondaryAnimation: secondaryAnimation,
                        transitionType: SharedAxisTransitionType.scaled,
                        child: child,
                      );
                    },
                  ),
                  routes: [
                    GoRoute(
                      parentNavigatorKey: _rootNavigatorKey,
                      path: 'register',
                      name: 'event-register',
                      builder: (context, state) => const RegisterWizardScreen(),
                    ),
                    GoRoute(
                      parentNavigatorKey: _rootNavigatorKey,
                      path: 'participants',
                      name: 'event-participants',
                      builder: (context, state) => const ParticipantsScreen(isOrganizer: false),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // ── Tab 2: Мои Мероприятия ──
        StatefulShellBranch(
          navigatorKey: _myNavigatorKey,
          routes: [
            GoRoute(
              path: '/my',
              name: 'my-events',
              builder: (context, state) => const MyEventsScreen(),
              routes: [
                GoRoute(
                  parentNavigatorKey: _rootNavigatorKey,
                  path: 'create',
                  name: 'create-event',
                  builder: (context, state) => const CreateEventWizardScreen(),
                ),
              ],
            ),
          ],
        ),

        // ── Tab 3: Клубы ──
        StatefulShellBranch(
          navigatorKey: _clubsNavigatorKey,
          routes: [
            GoRoute(
              path: '/clubs',
              name: 'my-clubs',
              builder: (context, state) => const MyClubsScreen(),
              routes: [
                GoRoute(
                  parentNavigatorKey: _rootNavigatorKey,
                  path: 'create',
                  name: 'create-club',
                  builder: (context, state) => const CreateClubScreen(),
                ),
                GoRoute(
                  parentNavigatorKey: _rootNavigatorKey,
                  path: ':clubId',
                  name: 'club-profile',
                  builder: (context, state) => const ClubProfileScreen(),
                  routes: [
                    GoRoute(
                      parentNavigatorKey: _rootNavigatorKey,
                      path: 'manage',
                      name: 'club-manage',
                      builder: (context, state) => const ClubManageScreen(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // ── Tab 4: Уведомления ──
        StatefulShellBranch(
          navigatorKey: _notificationsNavigatorKey,
          routes: [
            GoRoute(
              path: '/notifications',
              name: 'notifications',
              builder: (context, state) => const InboxScreen(),
            ),
          ],
        ),

        // ── Tab 5: Профиль ──
        StatefulShellBranch(
          navigatorKey: _profileNavigatorKey,
          routes: [
            GoRoute(
              path: '/profile',
              name: 'profile',
              builder: (context, state) => const ProfileScreen(),
              routes: [
                GoRoute(
                  parentNavigatorKey: _rootNavigatorKey,
                  path: 'documents',
                  name: 'my-documents',
                  builder: (context, state) => const ProfileDocumentsScreen(),
                ),
                GoRoute(
                  parentNavigatorKey: _rootNavigatorKey,
                  path: 'dogs',
                  name: 'my-dogs',
                  builder: (context, state) => const MyDogsScreen(),
                  routes: [
                    GoRoute(
                      parentNavigatorKey: _rootNavigatorKey,
                      path: ':dogId',
                      name: 'dog-detail',
                      builder: (context, state) => const DogDetailScreen(),
                    ),
                  ],
                ),
                GoRoute(
                  parentNavigatorKey: _rootNavigatorKey,
                  path: 'results',
                  name: 'my-results',
                  builder: (context, state) => const MyResultsScreen(),
                ),
                GoRoute(
                  parentNavigatorKey: _rootNavigatorKey,
                  path: 'diplomas',
                  name: 'my-diplomas',
                  builder: (context, state) => const MyDiplomasScreen(),
                ),
                GoRoute(
                  parentNavigatorKey: _rootNavigatorKey,
                  path: 'settings',
                  name: 'settings',
                  builder: (context, state) => const SettingsScreen(),
                  routes: [
                    GoRoute(
                      parentNavigatorKey: _rootNavigatorKey,
                      path: 'notifications',
                      name: 'notifications-settings',
                      builder: (context, state) => const NotificationsSettingsScreen(),
                    ),
                    GoRoute(
                      parentNavigatorKey: _rootNavigatorKey,
                      path: 'theme',
                      name: 'theme-settings',
                      builder: (context, state) => const ThemeSettingsScreen(),
                    ),
                  ],
                ),

                GoRoute(
                  parentNavigatorKey: _rootNavigatorKey,
                  path: 'trainer',
                  name: 'trainer',
                  builder: (context, state) => const TrainerScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // ═══════════════════════════════════════════════
    // Управление Мероприятием (E1-E7)
    // ═══════════════════════════════════════════════
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/manage/:eventId',
      name: 'manage-event',
      builder: (context, state) => const EventOverviewScreen(),
      routes: [
        GoRoute(
          path: 'disciplines',
          name: 'manage-disciplines',
          builder: (context, state) => const DisciplinesScreen(),
        ),
        GoRoute(
          path: 'participants',
          name: 'manage-participants',
          builder: (context, state) => const ParticipantsScreen(),
        ),
        GoRoute(
          path: 'team',
          name: 'manage-team',
          builder: (context, state) => const TeamScreen(),
        ),
        GoRoute(
          path: 'finances',
          name: 'manage-finances',
          builder: (context, state) {
            final eventId = state.pathParameters['eventId'] ?? '';
            return FinancesScreen(eventId: eventId);
          },
        ),
        GoRoute(
          path: 'documents',
          name: 'manage-documents',
          builder: (context, state) => const DocumentsScreen(),
        ),
        // Подготовка к гонке (P1-P6)
        GoRoute(
          path: 'draw',
          name: 'draw',
          builder: (context, state) => const DrawScreen(),
        ),
        GoRoute(
          path: 'startlist',
          name: 'startlist',
          builder: (context, state) => const StartListScreen(),
        ),
        GoRoute(
          path: 'bibs',
          name: 'bibs',
          builder: (context, state) => const BibAssignScreen(),
        ),
        GoRoute(
          path: 'vetcheck',
          name: 'vetcheck',
          builder: (context, state) => const VetCheckScreen(),
        ),
        GoRoute(
          path: 'mandate',
          name: 'mandate',
          builder: (context, state) => const MandateScreen(),
        ),
        GoRoute(
          path: 'checkin',
          name: 'checkin',
          builder: (context, state) => const CheckInScreen(),
        ),
        GoRoute(
          path: 'multiday',
          name: 'multiday-config',
          builder: (context, state) => const MultiDayConfigScreen(),
        ),
        GoRoute(
          path: 'basic-info',
          name: 'manage-basic-info',
          builder: (context, state) => const BasicInfoScreen(),
        ),
        GoRoute(
          path: 'schedule',
          name: 'manage-schedule',
          builder: (context, state) => const DayScheduleScreen(),
        ),
        GoRoute(
          path: 'bibs',
          name: 'manage-bibs',
          builder: (context, state) => const BibPoolScreen(),
        ),
        GoRoute(
          path: 'courses',
          name: 'manage-courses',
          builder: (context, state) => const CoursesScreen(),
        ),
        GoRoute(
          path: 'display',
          name: 'manage-display',
          builder: (context, state) => const DisplaySettingsScreen(),
        ),
        GoRoute(
          path: 'timing-settings',
          name: 'manage-timing-settings',
          builder: (context, state) => const TimingSettingsScreen(),
        ),
        GoRoute(
          path: 'vet',
          name: 'manage-vet',
          builder: (context, state) => const VetSettingsScreen(),
        ),
        GoRoute(
          path: 'registration-settings',
          name: 'manage-registration-settings',
          builder: (context, state) => const RegistrationSettingsScreen(),
        ),
        GoRoute(
          path: 'draw-settings',
          name: 'manage-draw-settings',
          builder: (context, state) => const DrawSettingsScreen(),
        ),
        GoRoute(
          path: 'categories',
          name: 'manage-categories',
          builder: (context, state) => const CategoriesScreen(),
        ),
        GoRoute(
          path: 'checklist',
          name: 'manage-checklist',
          builder: (context, state) => const PreStartChecklistScreen(),
        ),
        GoRoute(
          path: 'import',
          name: 'manage-import',
          builder: (context, state) => const ExcelImportScreen(),
        ),
      ],
    ),

    // ═══════════════════════════════════════════════
    // L2: Ops Shell — Двухрежимная навигация судьи
    // ═══════════════════════════════════════════════
    ShellRoute(
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state, child) => OpsRootShell(child: child),
      routes: [
        GoRoute(
          path: '/ops/:eventId/dash',
          name: 'ops-dash',
          builder: (context, state) => const OpsDashboardScreen(),
        ),
        GoRoute(
          path: '/ops/:eventId/checkin',
          name: 'ops-checkin',
          builder: (context, state) => const CheckInScreen(), // reuse existing prep screen
        ),
        GoRoute(
          path: '/ops/:eventId/timing',
          name: 'ops-timing',
          builder: (context, state) => OpsTimingHubScreen(eventId: state.pathParameters['eventId']!),
          routes: [
            GoRoute(
              path: 'starter',
              name: 'ops-starter',
              builder: (context, state) => const StarterScreen(),
            ),
            GoRoute(
              path: 'finish',
              name: 'ops-finish',
              builder: (context, state) => const FinishScreen(),
            ),
            GoRoute(
              path: 'marshal',
              name: 'ops-marshal',
              builder: (context, state) => const MarshalScreen(),
            ),
            GoRoute(
              path: 'dictator',
              name: 'ops-dictator',
              builder: (context, state) => const DictatorScreen(),
            ),
            GoRoute(
              path: 'map',
              name: 'ops-map',
              builder: (context, state) => const GpsMapScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/ops/:eventId/results',
          name: 'ops-results',
          builder: (context, state) => const LiveResultsScreen(),
        ),
      ],
    ),

    // ═══════════════════════════════════════════════
    // Тренерский Хронометраж (публичный)
    // ═══════════════════════════════════════════════
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/events/:eventId/timing',
      name: 'event-coach-timing',
      builder: (context, state) => const CoachTimingScreen(),
    ),

    // ═══════════════════════════════════════════════
    // Результаты (RS1-RS4)
    // ═══════════════════════════════════════════════
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/results/:eventId/live',
      name: 'live-results',
      builder: (context, state) => const LiveResultsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/results/:eventId/protocol',
      name: 'protocol',
      builder: (context, state) => const ProtocolScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/results/:eventId/protests',
      name: 'protests',
      builder: (context, state) => const ProtestsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/results/:eventId/diplomas',
      name: 'diplomas',
      builder: (context, state) => const DiplomaGenScreen(),
    ),

    // ═══════════════════════════════════════════════
    // Авторизация (A1-A3)
    // ═══════════════════════════════════════════════
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/welcome',
      name: 'welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/verify',
      name: 'verify',
      builder: (context, state) => const OtpVerifyScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/forgot-password',
      name: 'forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),



    // ═══════════════════════════════════════════════
    // QR Pairing
    // ═══════════════════════════════════════════════
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/pair',
      name: 'pair',
      builder: (context, state) => const QrPairingScreen(),
    ),

    // ═══════════════════════════════════════════════
    // Серия / Кубок (S1)
    // ═══════════════════════════════════════════════
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/series/:seriesId',
      name: 'series',
      builder: (context, state) => const SeriesScreen(),
    ),

    // ═══════════════════════════════════════════════
    // Быстрый Секундомер (QT1-QT4)
    // ═══════════════════════════════════════════════
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/quick-timer',
      name: 'quick-timer',
      builder: (context, state) => const QuickTimerScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/quick-timer/live',
      name: 'quick-timer-live',
      builder: (context, state) => const QuickTimerScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/quick-timer/results',
      name: 'quick-timer-results',
      builder: (context, state) => const QuickTimerResultsScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/quick-timer/history',
      name: 'quick-timer-history',
      builder: (context, state) => const QuickTimerHistoryScreen(),
    ),
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: '/quick-timer/settings',
      name: 'quick-timer-settings',
      builder: (context, state) => const QtSettingsScreen(),
    ),
  ],

  // ═══════════════════════════════════════════════
  // Role-based Guards (Redirects)
  // ═══════════════════════════════════════════════
  redirect: (context, state) {
    // TODO: Подключить AuthProvider из Riverpod
    //
    // final isLoggedIn = ref.read(authProvider).isLoggedIn;
    // final isOnAuthPage = state.matchedLocation.startsWith('/welcome') ||
    //                      state.matchedLocation.startsWith('/login') ||
    //                      state.matchedLocation.startsWith('/verify');
    //
    // if (!isLoggedIn && !isOnAuthPage) return '/welcome';
    // if (isLoggedIn && isOnAuthPage) return '/hub';
    //
    // Role-based:
    // if (state.matchedLocation.startsWith('/manage') && !user.isOrganizer) return '/hub';
    // if (state.matchedLocation.startsWith('/ops') && !user.hasOpsRole) return '/hub';

    return null; // no redirect
  },
);
