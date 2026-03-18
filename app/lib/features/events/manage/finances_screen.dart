import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../domain/event/config_providers.dart';

import 'tabs/finances_dashboard_tab.dart';
import 'tabs/finances_fees_tab.dart';
import 'tabs/finances_moderation_tab.dart';
import 'tabs/finances_promos_tab.dart';
import 'tabs/finances_transactions_tab.dart';

class FinancesScreen extends ConsumerStatefulWidget {
  final String eventId;

  const FinancesScreen({super.key, required this.eventId});

  @override
  ConsumerState<FinancesScreen> createState() => _FinancesScreenState();
}

class _FinancesScreenState extends ConsumerState<FinancesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(eventConfigProvider);
    final disciplines = ref.watch(disciplineConfigsProvider);

    // Dashboard stats from disciplines
    final totalRevenue = disciplines.fold<int>(0, (sum, d) => sum + (d.priceRub ?? 0));
    final dashboardData = {
      'income': totalRevenue > 0 ? '$totalRevenue' : '0',
      'ticketsSold': 0,
      'avgTicket': totalRevenue > 0 ? (totalRevenue ~/ disciplines.length) : 0,
    };

    return Scaffold(
      appBar: AppAppBar(
        title: Text('Финансы (${config.name})'),
        bottom: AppPillTabBar(
          controller: _tabController,
          tabs: const [
            'Дашборд',
            'Взносы',
            'Промокоды',
            'Транзакции',
            'Сверки',
          ],
          isScrollable: true,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          FinancesDashboardTab(data: dashboardData),
          const FinancesFeesTab(),
          const FinancesPromosTab(),
          const FinancesTransactionsTab(),
          const FinancesModerationTab(),
        ],
      ),
    );
  }
}
