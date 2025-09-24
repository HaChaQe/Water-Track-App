import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:confetti/confetti.dart';

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

class WaterTracker extends StatefulWidget{
  const WaterTracker({super.key});
  @override
  State<WaterTracker> createState() => _WaterTracker();
}

class _WaterTracker extends State<WaterTracker> {
  int glasses = 0;
  int dailyGoal = 8;
  late ConfettiController _confettiController;

  @override
  void initState(){
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _loadGoal();
    _loadGlasses();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  _loadGlasses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final today = DateTime.now();
    final savedDateString = prefs.getString('lastDate');

    if (savedDateString != null){
      final savedDate = DateTime.parse(savedDateString);
      if(savedDate.day != today.day
      || savedDate.month != today.month
      || savedDate.year != today.year) {
        glasses = 0;
      }else {
        glasses = (prefs.getInt('glasses')?? 0);
      }
    } else {
      glasses = (prefs.getInt('glasses')?? 0);
    }

    await prefs.setString('lastDate', today.toIso8601String());

    setState(() {});
  }

  _saveGlasses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('glasses', glasses);
  }

  _loadGoal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      dailyGoal = prefs.getInt('dailyGoal') ?? 8;
    });
  }

  void addGlass() {
    setState(() {
      glasses++;
      _saveGlasses();
      if (glasses >= dailyGoal){
        _confettiController.play();
      }
    });
  }

  void resetGlass() {
    setState(() {
      glasses = 0;
      _saveGlasses();
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
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(title: const Text('Su Takibi')),
      body: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Bugün $glasses bardak su içtin!",
                    style: const TextStyle(fontSize: 22)),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(dailyGoal, (index) {
                    return Icon(
                      Icons.local_drink,
                      color: index < glasses ? Colors.blue : Colors.grey,
                    );
                  }),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: LinearProgressIndicator(
                    value: glasses / dailyGoal,
                    minHeight: 10,
                    backgroundColor: Colors.grey[300],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(onPressed: addGlass, child: const Text("+1 Bardak")),
                const SizedBox(height: 10),
                ElevatedButton(onPressed: resetGlass, child: const Text("Sıfırla!")),
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
                          decoration:
                              const InputDecoration(hintText: "Kaç bardak?"),
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
              ],
            ),
          ),
          // Confetti widget mutlaka Stack içinde olmalı
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
