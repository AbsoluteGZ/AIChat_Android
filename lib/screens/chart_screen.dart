import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({Key? key}) : super(key: key);

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Chart')),
      body: _buildChart(chatProvider),
    );
  }

  Widget _buildChart(ChatProvider chatProvider) {
    return FutureBuilder<Map<String, dynamic>>(
      future: chatProvider.exportHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('No data available'));
        }

        final data = snapshot.data!;
        final sessionData = data['session_data'] as List<dynamic>?;

        if (sessionData == null || sessionData.isEmpty) {
          return const Center(child: Text('No chart data available'));
        }

        final chartData = _prepareBarChartData(sessionData);
        final pieChartData = _preparePieChartData(sessionData);
        final dailyCost = _calculateCost(sessionData, 'day');
        final weeklyCost = _calculateCost(sessionData, 'week');
        final monthlyCost = _calculateCost(sessionData, 'month');

        return Column(
          children: [
            // Диаграмма занимает верхнюю часть экрана
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: PieChart(
                  PieChartData(
                    sections: pieChartData,
                    centerSpaceRadius: 50,
                    sectionsSpace: 2,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ),

            // Гистограмма
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: BarChart(
                  BarChartData(
                    barGroups: chartData,
                    alignment: BarChartAlignment.spaceEvenly,
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)), // Убрали цифры слева
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final int index = value.toInt();
                            if (index >= 0 && index < chartData.length) {
                              final date = DateTime.fromMillisecondsSinceEpoch(chartData[index].x);
                              return Text(DateFormat('dd/MM').format(date), style: const TextStyle(fontSize: 10));
                            }
                            return const Text('');
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    barTouchData: BarTouchData(enabled: false),
                  ),
                ),
              ),
            ),

            // Таблица затрат
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Table(
                border: TableBorder.all(),
                children: [
                  const TableRow(children: [
                    Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Day'))),
                    Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Week'))),
                    Center(child: Padding(padding: EdgeInsets.all(8.0), child: Text('Month'))),
                  ]),
                  TableRow(children: [
                    Center(child: Padding(padding: const EdgeInsets.all(8.0), child: Text('\$${dailyCost.toStringAsFixed(6)}'))),
                    Center(child: Padding(padding: const EdgeInsets.all(8.0), child: Text('\$${weeklyCost.toStringAsFixed(6)}'))),
                    Center(child: Padding(padding: const EdgeInsets.all(8.0), child: Text('\$${monthlyCost.toStringAsFixed(6)}'))),
                  ]),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  List<BarChartGroupData> _prepareBarChartData(List<dynamic> sessionData) {
    final Map<int, double> dailyCost = {};

    for (var item in sessionData) {
      final DateTime messageTime = DateTime.parse(item['timestamp']);
      final int day = DateTime(messageTime.year, messageTime.month, messageTime.day).millisecondsSinceEpoch;
      final cost = (item['cost'] as num?)?.toDouble() ?? 0.0;
      dailyCost[day] = (dailyCost[day] ?? 0.0) + cost;
    }

    final List<BarChartGroupData> barGroups = [];
    dailyCost.forEach((day, cost) {
      barGroups.add(
        BarChartGroupData(
          x: day,
          barRods: [
            BarChartRodData(
              toY: cost,
              color: Colors.blue,
              width: 12,
              borderRadius: const BorderRadius.all(Radius.circular(6)),
            ),
          ],
        ),
      );
    });

    return barGroups;
  }

  List<PieChartSectionData> _preparePieChartData(List<dynamic> sessionData) {
    final Map<String, double> modelCosts = {};

    for (var item in sessionData) {
      final model = item['model'];
      final cost = (item['cost'] as num?)?.toDouble() ?? 0.0;
      modelCosts[model] = (modelCosts[model] ?? 0.0) + cost;
    }

    final List<PieChartSectionData> pieChartData = [];
    modelCosts.forEach((model, cost) {
      pieChartData.add(
        PieChartSectionData(
          value: cost,
          title: model,
          radius: 80,
          titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
          color: _getModelColor(model),
        ),
      );
    });

    return pieChartData;
  }

  double _calculateCost(List<dynamic> sessionData, String type) {
    double totalCost = 0;
    DateTime now = DateTime.now();
    DateTime start;

    switch (type) {
      case 'day':
        start = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        start = now.subtract(Duration(days: now.weekday - 1));
        break;
      case 'month':
        start = DateTime(now.year, now.month, 1);
        break;
      default:
        start = now;
    }

    for (var item in sessionData) {
      final DateTime messageTime = DateTime.parse(item['timestamp']);
      final double cost = (item['cost'] as num?)?.toDouble() ?? 0.0;
      if (messageTime.isAfter(start)) {
        totalCost += cost;
      }
    }
    return totalCost;
  }

  Color _getModelColor(String model) {
    switch (model) {
      case 'gpt-3.5-turbo': return Colors.blue;
      case 'claude-3-sonnet': return Colors.green;
      case 'deepseek-coder': return Colors.red;
      case 'mistral-7b-instruct': return Colors.orange;
      case '01-ai/yi-large': return Colors.purple;
      default: return Colors.grey;
    }
  }
}
