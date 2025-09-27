import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

class DailyPage extends StatefulWidget {
  final int dailyGoal;
  final Function(int) onGoalChange;
  final Function(int) onDayComplete;

  const DailyPage({
    super.key,
    required this.dailyGoal,
    required this.onGoalChange,
    required this.onDayComplete,
  });

  @override
  State<DailyPage> createState() => _DailyPage();
}

class _DailyPage extends State<DailyPage> with SingleTickerProviderStateMixin {
  int totalMl = 0;
  late ConfettiController _confettiController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _loadMl();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _waveController.dispose();
    super.dispose();
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
        widget.onDayComplete(totalMl); // ✅ WeeklyPage’e gönder
      }
    });
  }

  void resetWater() {
    setState(() {
      totalMl = 0;
      _saveMl();
    });
  }

  void setDailyGoal(int goal) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('dailyGoal', goal);
    widget.onGoalChange(goal); // ✅ Ana sayfadaki hedefi güncelle
  }

  @override
  Widget build(BuildContext context) {
    double progress = totalMl / widget.dailyGoal;
    if (progress > 1.0) progress = 1.0;

    return Scaffold(
      appBar: AppBar(title: const Center(child: Text('Su Takibi'))),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[300],
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        return ClipPath(
                          clipper: WaveClipper(
                            animationValue: _waveController.value,
                            progress: progress,
                          ),
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
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
                          "$totalMl ml",
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          "Hedef: ${widget.dailyGoal} ml",
                          style: const TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(onPressed: () => addWater(150), child: const Text("+150 Ml")),
                  const SizedBox(width: 10),
                  ElevatedButton(onPressed: () => addWater(250), child: const Text("+250 Ml")),
                  const SizedBox(width: 10),
                  ElevatedButton(onPressed: () => addWater(400), child: const Text("+400 Ml")),
                ],
              ),
              const SizedBox(height: 10),
              ElevatedButton(onPressed: resetWater, child: const Text("Sıfırla!")),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final controller = TextEditingController();
                  final newGoal = await showDialog<int>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Yeni hedef gir:"),
                      content: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: "Kaç ml?"),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("İptal"),
                        ),
                        TextButton(
                          onPressed: () {
                            final value = int.tryParse(controller.text);
                            if (value != null && value > 0) {
                              Navigator.pop(context, value);
                            }
                          },
                          child: const Text("Kaydet"),
                        ),
                      ],
                    ),
                  );
                  if (newGoal != null) {
                    setDailyGoal(newGoal);
                  }
                },
                child: const Text("Hedefi değiştir"),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => setDailyGoal(2000),
                child: const Text("Varsayılana dön (2000 ml)"),
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
            colors: const [Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple],
          ),
        ],
      ),
    );
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
