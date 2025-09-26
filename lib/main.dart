import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WaterTracker(),
    );
  }
}

class WaterTracker extends StatefulWidget {
  const WaterTracker({super.key});
  @override
  State<WaterTracker> createState() => _WaterTracker();
}

class _WaterTracker extends State<WaterTracker> with SingleTickerProviderStateMixin {
  int totalMl = 0;
  int dailyGoal = 2000;
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
    _loadGoal();
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

  Future<void> _loadGoal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      dailyGoal = prefs.getInt('dailyGoal') ?? 2000;
    });
  }

  void addWater(int ml) {
    setState(() {
      totalMl += ml;
      _saveMl();
      if (totalMl >= dailyGoal) {
        _confettiController.play();
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
    setState(() {
      dailyGoal = goal;
    });
  }

  @override
  Widget build(BuildContext context) {
    double progress = totalMl / dailyGoal;
    if (progress > 1.0) progress = 1.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Su Takibi')),
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
                    // Daire arka plan
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[300],
                      ),
                    ),
                    // Sıvı animasyonu
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
                    // Ortadaki yazılar
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "$totalMl ml",
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          "Hedef: $dailyGoal ml",
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

// Dalgalı kesme clipper
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
