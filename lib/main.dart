import 'package:flutter/material.dart';
import 'daily_page.dart';
import 'weekly_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;
  int _dailyGoal = 2000;
  final List<int> _weeklyData = [1200, 1800, 2000, 1500, 2200, 1700, 2100];
  bool _isOz = false;

  void _updateDailyGoal(int newGoal) {
    setState(() {
      _dailyGoal = newGoal;
    });
  }

  void _updateWeeklyData(int todayAmount) {
    final todayIndex = DateTime.now().weekday - 1;
    setState(() {
      _weeklyData[todayIndex] = todayAmount;
    });
  }

  void _toggleUnit() {
    setState(() {
      _isOz = !_isOz;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      DailyPage(
        dailyGoal: _dailyGoal,
        onGoalChange: _updateDailyGoal,
        onDayComplete: _updateWeeklyData,
        isOz: _isOz,
        onToggleUnit: _toggleUnit,
      ),
      WeeklyPage(
        dailyGoal: _dailyGoal,
        weeklyData: _weeklyData,
        isOz: _isOz,
      ),
    ];

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Water Tracker',
      theme: ThemeData.light().copyWith(
        primaryColor: const Color(0xFF1976D2),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1976D2),
          secondary: Color(0xFF64B5F6),
          background: Color(0xFFF5F5F5),
          surface: Colors.white,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onBackground: Color(0xFF212121),
          onSurface: Color(0xFF212121),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1976D2),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF64B5F6),
          selectedItemColor: Color(0xFFFFFFFF),
          unselectedItemColor: Color(0xFFFFFFFF),
        ),
      ),
      home: Scaffold(
        body: pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedIndex,
          type: BottomNavigationBarType.fixed,
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
      ),
    );
  }
}
