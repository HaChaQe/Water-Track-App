import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState(){
    super.initState();
    _loadGlasses();
    _loadGoal();
  }

  _loadGlasses() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      glasses = (prefs.getInt('glasses')?? 0);
    });
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:[
            Text("Bugün $glasses bardak su içtin!",
            style: const TextStyle(fontSize: 22)
            ),
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
            const SizedBox(height: 20,),
            Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: LinearProgressIndicator(
                value: glasses / dailyGoal,
                minHeight: 10,
                backgroundColor: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: addGlass,
            child: const Text("+1 Bardak"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: resetGlass,
            child: const Text("Sıfırla!"),  
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: () async {
              final controller = TextEditingController();
              final newGoal = await showDialog<int>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Yeni hedef gir:"),
                  content: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: "Kaç bardak?"),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context),
                    child: const Text("İptal"),
                    ),
                    TextButton(onPressed: () {
                      final value = int.tryParse(controller.text);
                      if (value != null && value > 0){
                        Navigator.pop(context, value);
                      }
                    },
                    child: const Text("Kaydet"),
                    ),
                  ],
                ),
              );
              if (newGoal != null){
                setDailyGoal(newGoal);
              }
            },
            child: const Text("Hedefi değiştir"),
            ),
            ],
          )
        ),
      );
  }
}
