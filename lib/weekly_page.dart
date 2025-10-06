import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class WeeklyPage extends StatelessWidget {
  static const double ML_TO_OZ = 29.5735;

  final int dailyGoal;
  final List<int> weeklyData;
  final bool isOz;

  const WeeklyPage({
    super.key,
    required this.dailyGoal,
    required this.weeklyData,
    required this.isOz,
  });

  List<int> alignWeeklyData(List<int> weeklyData, DateTime today) {
    final todayIndex = today.weekday ; // 1 = Pzt, 7 = Paz
    if (weeklyData.length != 7) return weeklyData;
    return List.generate(7, (i) => weeklyData[(i + 7 - todayIndex) % 7]);
  }

  @override
  Widget build(BuildContext context) {
    const daysShort = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    // const daysFull = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];

    final convertedDailyGoal = isOz ? dailyGoal / ML_TO_OZ : dailyGoal.toDouble();

    // 🔄 Haftayı hizala
    final alignedData = alignWeeklyData(weeklyData, DateTime.now());
    final barValues = alignedData.map((v) => isOz ? v / ML_TO_OZ : v.toDouble()).toList();

    final maxValue = barValues.reduce((a, b) => a > b ? a : b);
    final maxY = (maxValue > convertedDailyGoal ? maxValue * 1.1 : convertedDailyGoal * 1.1).ceilToDouble();

    final totalIntake = barValues.reduce((a, b) => a + b);
    final avgIntake = (totalIntake / 7).round();
    final daysCompleted = barValues.where((v) => v >= convertedDailyGoal).length;
    final completionRate = ((daysCompleted / 7) * 100).round();

    final todayIndex = DateTime.now().weekday - 1;

    return Scaffold(
      appBar: AppBar(toolbarHeight: 0,),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: "Average",
                    value: isOz ? "$avgIntake oz" : "$avgIntake ml",
                    icon: Icons.analytics,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: "Completed",
                    value: "$daysCompleted/7",
                    icon: Icons.check_circle,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            _StatCard(
              title: "Success Rate",
              value: "$completionRate%",
              icon: Icons.trending_up,
              color: completionRate >= 70 ? Colors.green : Colors.orange,
              isWide: true,
            ),
            const SizedBox(height: 10),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              color: Theme.of(context).colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text("Water Intake (Last 7 Days)", style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 300,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: maxY,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchTooltipData: BarTouchTooltipData(
                              tooltipPadding: const EdgeInsets.all(8),
                              tooltipMargin: 8,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                return BarTooltipItem(
                                  '${daysShort[group.x.toInt()]}\n',
                                  const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: "${rod.toY.round()} ${isOz ? 'oz' : 'ml'}",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  if (value == 0 || value == meta.max) return const SizedBox.shrink();
                                  return Text(
                                    value.toInt().toString(),
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                      fontSize: 10,
                                    ),
                                  );
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() < 0 || value.toInt() > 6) return const Text("");
                                  final isToday = value.toInt() == todayIndex;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      daysShort[value.toInt()],
                                      style: TextStyle(
                                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                        color: isToday
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: maxY / 5,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: List.generate(barValues.length, (index) {
                            final value = barValues[index];
                            final isToday = index == todayIndex;
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: value,
                                  color: value >= convertedDailyGoal
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.secondary,
                                  width: isToday ? 20 : 16,
                                  borderRadius: BorderRadius.circular(6),
                                  backDrawRodData: BackgroundBarChartRodData(
                                    show: true,
                                    toY: maxY,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _legendBox(Theme.of(context).colorScheme.primary, "Goal Reached"),
                        const SizedBox(width: 16),
                        _legendBox(Theme.of(context).colorScheme.secondary, "Below Goal"),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Daily Goal: ${isOz ? convertedDailyGoal.round() : dailyGoal} ${isOz ? 'oz' : 'ml'}",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendBox(Color color, String text) => Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      );
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isWide;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: isWide ? 16 : 12, horizontal: 12),
        child: isWide
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                      Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                    ],
                  ),
                ],
              )
            : Column(
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(height: 8),
                  Text(title, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                  Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
      ),
    );
  }
}
