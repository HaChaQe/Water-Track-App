import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'daily_page.dart';
import 'weekly_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  Map<String, int> _dailyHistory = {}; // 'yyyy-MM-dd': ml
  bool _isOz = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      
      // Goal yükle
      final savedGoal = prefs.getInt('dailyGoal') ?? 2000;
      
      // Birim tercihini yükle
      final savedIsOz = prefs.getBool('isOz') ?? false;
      
      // Günlük geçmişi yükle
      final historyString = prefs.getString('dailyHistory');
      Map<String, int> loadedHistory = {};
      if (historyString != null) {
        final decoded = jsonDecode(historyString) as Map<String, dynamic>;
        loadedHistory = decoded.map((key, value) => MapEntry(key, value as int));
      }
      
      // Son 30 günü tut, eskiyi sil
      final now = DateTime.now();
      loadedHistory.removeWhere((dateStr, _) {
        final date = DateTime.parse(dateStr);
        return now.difference(date).inDays > 30;
      });

      setState(() {
        _dailyGoal = savedGoal;
        _isOz = savedIsOz;
        _dailyHistory = loadedHistory;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveDailyHistory() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('dailyHistory', jsonEncode(_dailyHistory));
    } catch (e) {
      debugPrint('Error saving history: $e');
    }
  }

  Future<void> _saveGoal(int goal) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('dailyGoal', goal);
    } catch (e) {
      debugPrint('Error saving goal: $e');
    }
  }

  Future<void> _saveUnitPreference() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isOz', _isOz);
    } catch (e) {
      debugPrint('Error saving unit preference: $e');
    }
  }

  void _updateDailyGoal(int newGoal) {
    setState(() {
      _dailyGoal = newGoal;
    });
    _saveGoal(newGoal);
  }

  void _updateTodayData(int todayAmount) {
    final today = _getDateString(DateTime.now());
    setState(() {
      _dailyHistory[today] = todayAmount;
    });
    _saveDailyHistory();
  }

  void _toggleUnit() {
    setState(() {
      _isOz = !_isOz;
    });
    _saveUnitPreference();
  }

  String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  List<int> _getLast7DaysData() {
    final List<int> data = [];
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = _getDateString(date);
      data.add(_dailyHistory[dateStr] ?? 0);
    }
    
    return data;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              color: const Color(0xFF1976D2),
            ),
          ),
        ),
      );
    }

    final pages = [
      DailyPage(
        dailyGoal: _dailyGoal,
        onGoalChange: _updateDailyGoal,
        onDayComplete: _updateTodayData,
        isOz: _isOz,
        onToggleUnit: _toggleUnit,
      ),
      WeeklyPage(
        dailyGoal: _dailyGoal,
        weeklyData: _getLast7DaysData(),
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
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF1976D2),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF64B5F6),
          secondary: Color(0xFF90CAF9),
          background: Color(0xFF121212),
          surface: Color(0xFF1E1E1E),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onBackground: Colors.white,
          onSurface: Colors.white,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1E1E1E),
          selectedItemColor: Color(0xFF64B5F6),
          unselectedItemColor: Color(0xFF90CAF9),
        ),
      ),
      themeMode: ThemeMode.system,
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