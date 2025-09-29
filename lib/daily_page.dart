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
    double progress = totalMl / widget.dailyGoal;
    if (progress > 1.0) progress = 1.0;

    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      appBar: AppBar(title: const Center(child: Text('Su Takibi')),backgroundColor: Colors.lightBlue[100]),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
            child: Column(
              children: [
                // const SizedBox(height: 30),
                // Su dairesi
                Expanded(
                  child: Center(
                    child: SizedBox(
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
                              color: Colors.grey[300],
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blueAccent.withOpacity(0.6),
                                  blurRadius: 30,
                                  spreadRadius: 5
                                )
                              ]
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _waveController,
                            builder: (context, child) {
                              return ClipPath(
                                clipper: WaveClipper(
                                    animationValue: _waveController.value, progress: progress),
                                child: Container(
                                  width: 220,
                                  height: 220,
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
                              Text("$totalMl ml",
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                              Text("Hedef: ${widget.dailyGoal} ml",
                                  style: const TextStyle(fontSize: 16, color: Colors.white)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                    Slider(
                      value: sliderValue,
                      min: 50,
                      max: 500,
                      divisions: 9,
                      activeColor: Colors.blue,
                      inactiveColor: Colors.blue[100],
                      label: sliderValue.toInt().toString(),
                      onChanged: (value) {
                        setState(() {
                          sliderValue = value;
                        });
                      },
                    ),
                    ElevatedButton(
                      onPressed: () => addWater(sliderValue.toInt()),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue, minimumSize: const Size(150, 50)),
                      child: Text("+ ${sliderValue.toInt()} ml", style: TextStyle(color: Colors.white),),
                ),
                SizedBox(height: 50,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _mlButton(150, Colors.blue[300]!),
                    _mlButton(250, Colors.blue[400]!),
                    _mlButton(400, Colors.blue[600]!),
                  ],
                ),
                SizedBox(height: 100,),
                // Alt menü butonları
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _smallButton("Sıfırla", resetWater, Colors.grey[400]!),
                        _smallButton("Hedefi değiştir", _changeGoalDialog, Colors.blue[400]!),
                        _smallButton("Varsayılana dön", () => setDailyGoal(2000), Colors.red[300]!),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Konfeti
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

  Widget _mlButton(int ml, Color color) {
    return ElevatedButton(
      onPressed: () => addWater(ml),
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(15),
        backgroundColor: color,
      ),
      child: Text(
        "+$ml",
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _smallButton(String text, VoidCallback onTap, Color color) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, color: Colors.white),
      ),
    );
  }

  void _changeGoalDialog() async {
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value > 0) Navigator.pop(context, value);
            },
            child: const Text("Kaydet"),
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
