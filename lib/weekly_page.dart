import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class WeeklyPage extends StatelessWidget {
  final int dailyGoal;
  final List<int> weeklyData;
  final bool isOz;

  const WeeklyPage({
    super.key,
    required this.dailyGoal,
    required this.weeklyData,
    required this.isOz,
  });

  @override
  Widget build(BuildContext context) {
    // Oz dönüşümü ve maxY ayarı
    final convertedDailyGoal = isOz ? (dailyGoal / 29.5735).ceilToDouble() : dailyGoal.toDouble();
    final barValues = weeklyData.map((ml) => isOz ? (ml / 29.5735).ceilToDouble() : ml.toDouble()).toList();
    final maxY = (barValues.reduce((a, b) => a > b ? a : b) + 5); // her zaman biraz üst boşluk

    return Scaffold(
      appBar: AppBar(title: const Text("Weekly Stats")),
      backgroundColor: Colors.blue.shade50,
      body: Padding(
        padding: const EdgeInsets.only(bottom: 40, top: 40, left: 25, right: 25),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 3,
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(
                  "Water Intake (Last 7 Days)",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxY,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
                              if (value.toInt() >= 0 && value.toInt() < days.length) {
                                return Text(days[value.toInt()]);
                              }
                              return const Text("");
                            },
                          ),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(barValues.length, (index) {
                        final value = barValues[index];
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: value,
                              color: value >= convertedDailyGoal
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.secondary,
                              width: 16,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isOz
                      ? "Daily Goal: ${convertedDailyGoal.round()} oz"
                      : "Daily Goal: $dailyGoal ml",
                  style: const TextStyle(color: Colors.black, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
