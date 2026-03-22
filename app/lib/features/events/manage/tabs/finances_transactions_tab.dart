import 'package:flutter/material.dart';
import '../../../../core/widgets/widgets.dart';

class FinancesTransactionsTab extends StatefulWidget {
  const FinancesTransactionsTab({super.key});

  @override
  State<FinancesTransactionsTab> createState() => _FinancesTransactionsTabState();
}

class _FinancesTransactionsTabState extends State<FinancesTransactionsTab> {
  // Фейковые данные для транзакций
  final List<Map<String, dynamic>> _transactions = [
    {
      'id': 'TRC-1004',
      'user': 'Иванов Иван',
      'item': 'Скиджоринг 5км',
      'amount': 3500,
      'date': 'Сегодня, 14:30',
      'status': 'success',
      'method': 'sbp',
    },
    {
      'id': 'TRC-1003',
      'user': 'Смирнова Анна',
      'item': 'Каникросс 3км',
      'amount': 2000,
      'date': 'Сегодня, 11:15',
      'status': 'pending',
      'method': 'card',
    },
    {
      'id': 'TRC-1002',
      'user': 'Петров Петр',
      'item': 'Нарты 15км (Early Bird)',
      'amount': 4500,
      'date': 'Вчера, 18:40',
      'status': 'success',
      'method': 'sbp',
    },
    {
      'id': 'TRC-1001',
      'user': 'Козлов Дмитрий',
      'item': 'Скиджоринг 10км',
      'amount': 4000,
      'date': 'Вчера, 09:20',
      'status': 'error',
      'method': 'card',
    },
    {
      'id': 'TRC-1000',
      'user': 'Лебедева Елена',
      'item': 'Каникросс 3км',
      'amount': 2000,
      'date': '10 Фев, 16:55',
      'status': 'refunded',
      'method': 'sbp',
    },
  ];

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        // Панель фильтров
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Поиск по ФИО или ID',
                  prefixIcon: Icons.search,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: () {},
                icon: const Icon(Icons.filter_list, size: 20),
                tooltip: 'Фильтры',
              ),
            ],
          ),
        ),
        
        // Список транзакций
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _transactions.length,
            itemBuilder: (context, index) {
              final t = _transactions[index];
              return _buildTransactionCard(context, t);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(BuildContext context, Map<String, dynamic> t) {
    final cs = Theme.of(context).colorScheme;
    
    final statusColor = t['status'] == 'success'
        ? cs.primary
        : t['status'] == 'pending'
            ? cs.tertiary
            : t['status'] == 'error'
                ? cs.error
                : t['status'] == 'refunded'
                    ? cs.error
                    : cs.outline;

    final statusText = t['status'] == 'success'
        ? 'Оплачено'
        : t['status'] == 'pending'
            ? 'Ожидает'
            : t['status'] == 'error'
                ? 'Ошибка'
                : t['status'] == 'refunded'
                    ? 'Возврат'
                    : 'Неизвестно';

    final statusIcon = t['status'] == 'success'
        ? Icons.check_circle
        : t['status'] == 'pending'
            ? Icons.schedule
            : t['status'] == 'error'
                ? Icons.error
                : t['status'] == 'refunded'
                    ? Icons.refresh
                    : Icons.help;

    final isPositive = t['status'] == 'success' || t['status'] == 'pending';
    final amountPrefix = isPositive ? '+' : (t['status'] == 'refunded' ? '-' : '');
    final amountColor = isPositive ? cs.primary : (t['status'] == 'refunded' ? cs.error : cs.onSurface);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.all(12),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Иконка метода оплаты
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  t['method'] == 'sbp' ? Icons.account_balance : Icons.credit_card,
                  color: cs.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              // Основная информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t['user'],
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t['item'],
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          t['date'],
                          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withValues(alpha: 0.8)),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ID: ${t['id']}',
                          style: TextStyle(fontSize: 11, fontFeatures: const [FontFeature.tabularFigures()], color: cs.onSurfaceVariant.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Сумма и статус
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$amountPrefix ${t['amount']} ₽',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: amountColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 10, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
