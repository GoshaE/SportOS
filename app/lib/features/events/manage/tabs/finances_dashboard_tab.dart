import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/widgets/widgets.dart';

class FinancesDashboardTab extends StatelessWidget {
  final Map<String, dynamic> data;

  const FinancesDashboardTab({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final income = data['income'] ?? 0;
    final ticketsSold = data['ticketsSold'] ?? 0;
    final avgTicket = data['avgTicket'] ?? 0;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Быстрые действия
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              ActionChip(
                label: const Text('Экспорт Excel'),
                avatar: const Icon(Icons.file_download, size: 16),
                onPressed: () => AppSnackBar.success(context, 'Отчет отправлен на почту'),
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              ActionChip(
                label: const Text('Сверка'),
                avatar: const Icon(Icons.fact_check, size: 16),
                onPressed: () {},
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              ActionChip(
                label: const Text('Настройки'),
                avatar: const Icon(Icons.settings, size: 16),
                onPressed: () {},
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Главный KPI: Общий доход
        AppCard(
          padding: const EdgeInsets.all(20),
          backgroundColor: cs.primaryContainer,
          children: [
            Stack(
              alignment: Alignment.centerRight,
              children: [
                Icon(Icons.currency_ruble, size: 80, color: cs.onPrimaryContainer.withValues(alpha: 0.1)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Общий доход', style: TextStyle(fontSize: 14, color: cs.onPrimaryContainer)),
                    const SizedBox(height: 4),
                    Text('$income ₽', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: cs.onPrimaryContainer)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _miniKpi('Оплачено', '$ticketsSold шт', cs.onPrimaryContainer),
                        _miniKpi('Ожидают', '12 шт', cs.onPrimaryContainer.withValues(alpha: 0.7)),
                        _miniKpi('Возвраты', '3 шт', cs.error),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Сетка KPI
        Row(
          children: [
            AppStatCard(value: '$avgTicket ₽', label: 'Средний чек', icon: Icons.receipt_long, color: cs.primary),
            const SizedBox(width: 8),
            AppStatCard(value: '4.2%', label: 'Конверсия', icon: Icons.trending_up, color: cs.tertiary),
          ],
        ),
        const SizedBox(height: 12),

        // Графики
        AppChartStyle.chartCard(
          context: context,
          title: 'Доход по месяцам',
          subtitle: 'Продажи слотов и доп. услуг',
          height: 180,
          chart: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 600000,
              barGroups: [
                _barGroup(0, 150000, 20000, cs),
                _barGroup(1, 280000, 40000, cs),
                _barGroup(2, 450000, 80000, cs),
                _barGroup(3, 520000, 50000, cs),
              ],
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      const style = TextStyle(color: Colors.grey, fontSize: 10);
                      Widget text;
                      switch (value.toInt()) {
                        case 0: text = const Text('Дек', style: style); break;
                        case 1: text = const Text('Янв', style: style); break;
                        case 2: text = const Text('Фев', style: style); break;
                        case 3: text = const Text('Мар', style: style); break;
                        default: text = const Text('', style: style); break;
                      }
                      return SideTitleWidget(meta: meta, space: 4, child: text);
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        AppChartStyle.chartCard(
          context: context,
          title: 'Распределение по дисциплинам',
          subtitle: 'Доля выручки',
          height: 180,
          chart: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(color: cs.primary, value: 45, title: '45%', radius: 20, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                PieChartSectionData(color: cs.secondary, value: 30, title: '30%', radius: 20, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                PieChartSectionData(color: cs.tertiary, value: 15, title: '15%', radius: 20, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                PieChartSectionData(color: cs.error, value: 10, title: '10%', radius: 20, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
              ],
            ),
          ),
        ),
        
        // Легенда графика
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            children: [
              _legendItem(cs.primary, 'Скиджоринг 5км', '234 000 ₽'),
              _legendItem(cs.secondary, 'Скиджоринг 10км', '156 000 ₽'),
              _legendItem(cs.tertiary, 'Каникросс 3км', '78 000 ₽'),
              _legendItem(cs.error, 'Нарты 15км', '52 000 ₽'),
            ],
          ),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _miniKpi(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8))),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _legendItem(Color color, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double val1, double val2, ColorScheme cs) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: val1 + val2,
          width: 12,
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
          rodStackItems: [
            BarChartRodStackItem(0, val1, cs.primary),
            BarChartRodStackItem(val1, val1 + val2, cs.tertiary),
          ],
        ),
      ],
    );
  }
}
