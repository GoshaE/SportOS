import 'package:flutter/material.dart';
import '../../../../core/widgets/widgets.dart';

class FinancesModerationTab extends StatefulWidget {
  const FinancesModerationTab({super.key});

  @override
  State<FinancesModerationTab> createState() => _FinancesModerationTabState();
}

class _FinancesModerationTabState extends State<FinancesModerationTab> {
  // Фейковые данные для модерации (список чеков ожидающих проверки)
  final List<Map<String, dynamic>> _mockTransactions = [
    {
      'id': 'TRX-1049',
      'date': '12.05.2024 14:32',
      'user': 'Иванов Иван',
      'amount': '+ 5 000 ₽',
      'description': 'Оплата стартового взноса (Чек Сбербанк)',
      'status': 'pending', // pending, approved, rejected
      'imageUrl': 'assets/images/event1.jpeg', // Имитация чека (бумага с текстом)
      'category': 'Взносы',
    },
    {
      'id': 'TRX-1050',
      'date': '12.05.2024 15:10',
      'user': 'Смирнова Анна',
      'amount': '+ 4 500 ₽',
      'description': 'Оплата взноса + Аренда номера (Тинькофф)',
      'status': 'approved',
      'imageUrl': 'assets/images/event1.jpeg', // Имитация выписки
      'category': 'Взносы',
    },
    {
      'id': 'TRX-1051',
      'date': '12.05.2024 16:45',
      'user': 'Петров Алексей',
      'amount': '+ 2 500 ₽',
      'description': 'Благотворительный взнос',
      'status': 'rejected',
      'imageUrl': 'assets/images/event1.jpeg',
      'category': 'Пожертвования',
      'rejectReason': 'Чек не читаем (размыто фото)',
    },
  ];

  void _acceptReceipt(int index) {
    final user = _mockTransactions[index]['user'];
    setState(() {
      _mockTransactions[index]['status'] = 'approved';
    });
    AppSnackBar.success(context, 'Платеж $user подтвержден');
    Navigator.of(context, rootNavigator: true).pop(); // Закрываем модалку если она открыта
  }

  void _rejectReceipt(int index) {
    final user = _mockTransactions[index]['user'];
    setState(() {
      _mockTransactions[index]['status'] = 'rejected';
    });
    AppSnackBar.error(context, 'Платеж $user отклонен!');
    Navigator.of(context, rootNavigator: true).pop(); // Закрываем модалку если она открыта
  }

  void _showReceiptDetails(int index) {
    final item = _mockTransactions[index];
    final cs = Theme.of(context).colorScheme;

    AppBottomSheet.show(
      context,
      title: 'Сверка платежа',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Информация о платеже
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, color: cs.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['user'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(item['item'], style: TextStyle(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(item['date'], style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              Text(
                item['amount'],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          
          if (item['comment'].toString().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.notes, size: 20, color: cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '«${item['comment']}»',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Фото чека
          const Text('Прикрепленный чек', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AppCachedImage(
              url: item['imageUrl'],
              height: 300,
              fit: BoxFit.cover,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Кнопки
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _rejectReceipt(index),
                  icon: const Icon(Icons.close),
                  label: const Text('Отклонить'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.error,
                    side: BorderSide(color: cs.error),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _acceptReceipt(index),
                  icon: const Icon(Icons.check),
                  label: const Text('Подтвердить'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_mockTransactions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
            SizedBox(height: 16),
            Text('Все чеки проверены!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('На данный момент ручных сверок больше нет.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _mockTransactions.length,
      itemBuilder: (context, index) {
        final item = _mockTransactions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            padding: const EdgeInsets.all(12),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Миниатюра чека
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AppCachedImage(
                      url: item['imageUrl'],
                      width: 60,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Инфо
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item['user'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              item['amount'],
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(item['description'], style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13)),
                        const SizedBox(height: 4),
                        Text(item['date'], style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.8), fontSize: 11)),
                        
                        const SizedBox(height: 8),
                        // Кнопка для открытия модалки
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.tonal(
                            onPressed: () => _showReceiptDetails(index),
                            child: const Text('Сверить чек'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}
