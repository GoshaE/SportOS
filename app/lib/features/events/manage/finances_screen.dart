import 'package:flutter/material.dart';
import '../../../../core/widgets/app_app_bar.dart';
import '../../../../core/widgets/widgets.dart';

import 'tabs/finances_dashboard_tab.dart';
import 'tabs/finances_fees_tab.dart';
import 'tabs/finances_moderation_tab.dart';
import 'tabs/finances_promos_tab.dart';
import 'tabs/finances_transactions_tab.dart';

class FinancesScreen extends StatefulWidget {
  final String eventId;

  const FinancesScreen({super.key, required this.eventId});

  @override
  State<FinancesScreen> createState() => _FinancesScreenState();
}

class _FinancesScreenState extends State<FinancesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Фейковые данные (могут передаваться во вкладки)
  final Map<String, dynamic> _dashboardData = {
    'income': '1 254 000',
    'ticketsSold': 345,
    'avgTicket': 3650,
  };

  final List<Map<String, dynamic>> _promos = [
    {
      'code': 'WINTER24',
      'type': 'percent',
      'value': 15,
      'maxUses': 50,
      'used': 45,
      'validUntil': '31.12.2024',
      'active': false,
      'disciplines': 'Все',
    },
    {
      'code': 'LOCALHERO',
      'type': 'fixed',
      'value': 500,
      'maxUses': 0, // Безлимит
      'used': 12,
      'validUntil': '20.01.2025',
      'active': true,
      'disciplines': 'Каникросс',
    },
    {
      'code': 'EARLYBIRD',
      'type': 'percent',
      'value': 20,
      'maxUses': 100,
      'used': 100,
      'validUntil': '01.11.2024',
      'active': false,
      'disciplines': 'Скиджоринг 5км',
    },
    {
      'code': 'VIPGUEST',
      'type': 'percent',
      'value': 100,
      'maxUses': 5,
      'used': 2,
      'validUntil': 'Бессрочно',
      'active': true,
      'disciplines': 'Все',
    },
  ];

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
    return Scaffold(
      appBar: AppAppBar(
        title: const Text('Финансы (Зов Предков)'),
        bottom: AppPillTabBar(
          controller: _tabController,
          tabs: const [
            'Дашборд',
            'Взносы',
            'Промокоды',
            'Транзакции (45)',
            'Сверки ручные (3)',
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          FinancesDashboardTab(data: _dashboardData),
          const FinancesFeesTab(),
          FinancesPromosTab(promos: _promos),
          const FinancesTransactionsTab(),
          const FinancesModerationTab(),
        ],
      ),
    );
  }
}
