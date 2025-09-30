import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

class DailyPage extends StatefulWidget {
  final int dailyGoal;
  final Function(int) onGoalChange;
  final Function(int) onDayComplete;
  final bool isOz;
  final VoidCallback onToggleUnit;

  const DailyPage({
    super.key,
    required this.dailyGoal,
    required this.onGoalChange,
    required this.onDayComplete,
    required this.isOz,
    required this.onToggleUnit,
  });

  @override
  State<DailyPage> createState() => _DailyPageState();
}

class _DailyPageState extends State<DailyPage> with SingleTickerProviderStateMixin {
  int totalMl = 0;
  double sliderValue = 150;
  late ConfettiController _confettiController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _loadMl();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DailyPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOz != oldWidget.isOz) {
      setState(() {
        sliderValue = widget.isOz
            ? (sliderValue / 29.57).clamp(2, 16) // ml -> oz
            : (sliderValue * 29.57).clamp(50, 500); // oz -> ml
      });
    }
  }

  Future<void> _loadMl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final savedDateString = prefs.getString('lastDate');

    if (savedDateString != null) {
      final savedDate = DateTime.parse(savedDateString);
      if (savedDate.day != today.day ||
          savedDate.month != today.month ||
          savedDate.year != today.year) {
        totalMl = 0;
      } else {
        totalMl = prefs.getInt('totalMl') ?? 0;
      }
    } else {
      totalMl = prefs.getInt('totalMl') ?? 0;
    }

    await prefs.setString('lastDate', today.toIso8601String());
    setState(() {});
  }

  Future<void> _saveMl() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('totalMl', totalMl);
  }

  void addWater(int ml) {
    setState(() {
      totalMl += ml;
      _saveMl();
      if (totalMl >= widget.dailyGoal) {
        _confettiController.play();
      }
      widget.onDayComplete(totalMl);
    });
  }

  void resetWater() {
    setState(() {
      totalMl = 0;
      _saveMl();
      widget.onDayComplete(totalMl);
    });
  }

  void setDailyGoal(int goal) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dailyGoal', goal);
    widget.onGoalChange(goal);
  }

  @override
  Widget build(BuildContext context) {
    double sliderMin = widget.isOz ? 2 : 50;
    double sliderMax = widget.isOz ? 16 : 500;
    double progress = totalMl / widget.dailyGoal;
    if (progress > 1.0) progress = 1.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Daily Water Track"),
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.settings),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 100,
              color: Theme.of(context).colorScheme.primary,
              alignment: Alignment(-0.9, 0.8),
              child: const Text('Settings', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('Change Goal'),
              onTap: () {
                Navigator.pop(context);
                _changeGoalDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_backup_restore),
              title: const Text('Default Goal'),
              onTap: () {
                setDailyGoal(2000);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Daily Reset'),
              onTap: () {
                resetWater();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: Text(widget.isOz ? "Switch to mL" : "Switch to Oz"),
              onTap: () {
                widget.onToggleUnit();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[200],
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
                              blurRadius: 30,
                              spreadRadius: 5,
                            )
                          ],
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, child) {
                          return ClipPath(
                            clipper: WaveClipper(animationValue: _waveController.value, progress: progress),
                            child: Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        },
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            widget.isOz
                                ? "${(totalMl / 29.57).round()} oz"
                                : "$totalMl ml",
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: progress >= 0.5 ? Colors.white : Colors.grey),
                          ),
                          Text(
                            widget.isOz
                                ? "Goal: ${(widget.dailyGoal / 29.57).round()} oz"
                                : "Goal: ${widget.dailyGoal} ml",
                            style: TextStyle(
                                fontSize: 16,
                                color: progress >= 0.35 ? Colors.white : Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 35),
                Column(
                  children: [
                    Slider(
                      value: sliderValue.clamp(sliderMin, sliderMax),
                      min: sliderMin,
                      max: sliderMax,
                      divisions: widget.isOz ? (sliderMax - sliderMin).toInt() : 9,
                      activeColor: Theme.of(context).colorScheme.primary,
                      inactiveColor: Theme.of(context).colorScheme.secondary,
                      label: widget.isOz
                          ? "${sliderValue.clamp(sliderMin, sliderMax).round()} oz"
                          : "${sliderValue.clamp(sliderMin, sliderMax).toInt()} ml",
                      onChanged: (value) {
                        setState(() {
                          sliderValue = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        final mlValue = widget.isOz ? (sliderValue * 29.57).round() : sliderValue.toInt();
                        addWater(mlValue);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        minimumSize: const Size(120, 50),
                      ),
                      child: Text(
                        widget.isOz
                            ? "+ ${sliderValue.round()} oz"
                            : "+ ${sliderValue.toInt()} ml",
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 50),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        for (var val in [150, 250, 400])
                          ElevatedButton(
                            onPressed: () {
                              final mlValue = widget.isOz ? (val / 29.57).round() : val;
                              addWater(mlValue);
                            },
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(13),
                              backgroundColor: Colors.blue.shade300,
                            ),
                            child: Text(
                              widget.isOz ? "+ ${(val / 29.57).round()}" : "+$val",
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ],
                )
              ],
            ),
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              maxBlastForce: 50,
              minBlastForce: 20,
              gravity: 0.3,
              colors: const [
                Color(0xFF1976D2),
                Color(0xFF64B5F6),
                Color(0xFFFFC107),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _changeGoalDialog() async {
    final controller = TextEditingController();
    final newGoal = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter new goal:"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "How many ml?"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value > 0) Navigator.pop(context, value);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
    if (newGoal != null) setDailyGoal(newGoal);
  }
}

class WaveClipper extends CustomClipper<Path> {
  final double animationValue;
  final double progress;
  WaveClipper({required this.animationValue, required this.progress});

  @override
  Path getClip(Size size) {
    final Path path = Path();
    final double waveHeight = 10;
    final double baseHeight = size.height * (1 - progress);
    path.moveTo(0, size.height);

    for (double i = 0; i <= size.width; i++) {
      double y = sin((i / size.width * 2 * pi) + (animationValue * 2 * pi)) * waveHeight + baseHeight;
      path.lineTo(i, y);
    }

    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant WaveClipper oldClipper) => true;
}
