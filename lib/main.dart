import 'package:flutter/material.dart';
import 'daily_page.dart';
import 'weekly_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Water Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  int _dailyGoal = 2000;
  // Haftalık veri: Pazartesi=0, ..., Pazar=6
  final List<int> _weeklyData = [1200, 1800, 2000, 1500, 2200, 1700, 2100];

  void _updateDailyGoal(int newGoal) {
    setState(() {
      _dailyGoal = newGoal;
    });
  }

  void _updateWeeklyData(int todayAmount) {
    final todayIndex = DateTime.now().weekday - 1; // 0=Mon, 6=Sun
    setState(() {
      _weeklyData[todayIndex] = todayAmount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DailyPage(
        dailyGoal: _dailyGoal,
        onGoalChange: _updateDailyGoal,
        onDayComplete: _updateWeeklyData,
      ),
      WeeklyPage(
        dailyGoal: _dailyGoal,
        weeklyData: _weeklyData,
      ),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_drink),
            label: "Daily",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "7 Days",
          ),
        ],
      ),
    );
  }
}
