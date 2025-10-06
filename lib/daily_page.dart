import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

class _DailyPageState extends State<DailyPage> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const double ML_TO_OZ = 29.5735;
  
  int totalMl = 0;
  double sliderValue = 200;
  late ConfettiController _confettiController;
  late AnimationController _waveController;
  bool _hasShownConfetti = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _waveController = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat();
    _loadMl();
    sliderValue = widget.isOz ? (sliderValue / ML_TO_OZ).clamp(2, 16) : sliderValue.clamp(50, 500);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _confettiController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _waveController.stop();
    } else if (state == AppLifecycleState.resumed) {
      _waveController.repeat();
    }
  }

@override
void didUpdateWidget(covariant DailyPage oldWidget) {
  super.didUpdateWidget(oldWidget);

  if (widget.isOz != oldWidget.isOz) {
    setState(() {
      // 🔹 Slider dönüştür
      sliderValue = widget.isOz
          ? (sliderValue / ML_TO_OZ).clamp(2, 16)
          : (sliderValue * ML_TO_OZ).clamp(50, 500);

      // 🔹 Toplamı dönüştür
      totalMl = widget.isOz
          ? totalMl
          : totalMl; // totalMl her zaman ML cinsinden tutulduğu için burada dokunmuyoruz
    });
  }

  // 🔹 DailyGoal doğru birimle gösterilsin
  if (widget.dailyGoal != oldWidget.dailyGoal) {
    _hasShownConfetti = totalMl < widget.dailyGoal;
  }
}



  Future<void> _loadMl() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final savedDateString = prefs.getString('lastDate');

      if (savedDateString != null) {
        final savedDate = DateTime.parse(savedDateString);
        if (savedDate.day != today.day ||
            savedDate.month != today.month ||
            savedDate.year != today.year) {
          totalMl = 0;
          _hasShownConfetti = false;
        } else {
          totalMl = prefs.getInt('totalMl') ?? 0;
          _hasShownConfetti = totalMl >= widget.dailyGoal;
        }
      } else {
        totalMl = prefs.getInt('totalMl') ?? 0;
        _hasShownConfetti = totalMl >= widget.dailyGoal;
      }

      await prefs.setString('lastDate', today.toIso8601String());
      setState(() {});
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
  }

  Future<void> _saveMl() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('totalMl', totalMl);
    } catch (e) {
      debugPrint('Error saving data: $e');
    }
  }

  void addWater(int ml) {
    setState(() {
      totalMl += ml;
      _saveMl();
      
      // İlk kez hedefi tutturduğunda konfeti göster
      if (totalMl >= widget.dailyGoal 
          && !_hasShownConfetti
      ){
        _confettiController.play();
        _hasShownConfetti = true;
      }
      
      widget.onDayComplete(totalMl);
    });
  }

  void resetWater() {
    setState(() {
      totalMl = 0;
      _hasShownConfetti = false;
      _saveMl();
      widget.onDayComplete(totalMl);
    });
  }

  void setDailyGoal(int goal) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('dailyGoal', goal);
      widget.onGoalChange(goal);
    } catch (e) {
      debugPrint('Error saving goal: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double sliderMin = widget.isOz ? 2 : 50;
    double sliderMax = widget.isOz ? 16 : 500;
    double progress = totalMl / widget.dailyGoal;
    if (progress > 1.0) progress = 1.0;

    // Dinamik hızlı ekleme değerleri
    final List<int> quickAddValues = widget.isOz 
        ? [4, 8, 16]  // oz için (yarım bardak, 1 bardak, 2 bardak)
        : [150, 250, 400]; // ml için

    double displayedValue = widget.isOz
        ? (sliderValue / ML_TO_OZ).clamp(sliderMin, sliderMax)
        : sliderValue.clamp(sliderMin, sliderMax);

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.settings),
            iconSize: 33,
            alignment: Alignment(2,1),
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
              alignment: const Alignment(-0.9, 0.8),
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
                setDailyGoal(widget.isOz ? 68 : 2000); // 68 oz ≈ 2000 ml
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(widget.isOz 
                        ? 'Goal set to 68 oz (≈2000 ml)'
                        : 'Goal set to 2000 ml (≈68 oz)'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Daily Reset'),
              onTap: () {
                Navigator.pop(context);
                _showResetConfirmation();
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight,
          ),
          child: Center(
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
                              color: Theme.of(context).colorScheme.surface,
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
                            mainAxisSize: MainAxisSize.min, // 🔥 Overflow engeller
                            children: [
                              Flexible( // 🔥 Text sığmazsa küçülür
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    widget.isOz
                                        ? "${(totalMl / ML_TO_OZ).round()} oz"
                                        : "$totalMl ml",
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: progress >= 0.55
                                          ? Colors.white
                                          : Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    widget.isOz
                                        ? "Goal: ${(widget.dailyGoal / ML_TO_OZ).round()} oz"
                                        : "Goal: ${widget.dailyGoal} ml",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: progress >= 0.5
                                          ? Colors.white
                                          : Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 35),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Slider(
                            value: displayedValue, // 🔹 Burada değişti
                            min: sliderMin,
                            max: sliderMax,
                            divisions: widget.isOz ? (sliderMax - sliderMin).toInt() : 9,
                            activeColor: Theme.of(context).colorScheme.primary,
                            inactiveColor: Theme.of(context).colorScheme.secondary,
                            label: widget.isOz
                                ? "${displayedValue.round()} oz"
                                : "${displayedValue.toInt()} ml",
                            onChanged: (value) {
                              setState(() {
                                // 🔹 Kullanıcı oz seçmişse tekrar mL’ye çevir
                                sliderValue = widget.isOz ? (value * ML_TO_OZ) : value;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          Semantics(
                            label: 'Add ${widget.isOz ? sliderValue.round() : sliderValue.toInt()} ${widget.isOz ? "ounces" : "milliliters"} of water',
                            child: ElevatedButton(
                              onPressed: () {
                                final mlValue = widget.isOz 
                                    ? (sliderValue * ML_TO_OZ).round() 
                                    : sliderValue.toInt();
                                addWater(mlValue);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                minimumSize: const Size(120, 50),
                              ),
                              child: Text(
                                widget.isOz
                                    ? "+ ${sliderValue.round()} oz"
                                    : "+ ${sliderValue.toInt()} ml",
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 50),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              for (var val in quickAddValues)
                                Semantics(
                                  label: 'Quick add $val ${widget.isOz ? "ounces" : "milliliters"}',
                                  child: ElevatedButton(
                                    onPressed: () {
                                      final mlValue = widget.isOz 
                                          ? (val * ML_TO_OZ).round() 
                                          : val;
                                      addWater(mlValue);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      shape: const CircleBorder(),
                                      padding: const EdgeInsets.all(13),
                                      backgroundColor: Theme.of(context).colorScheme.secondary,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text(
                                      "+$val",
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  emissionFrequency: 0.05,
                  numberOfParticles: 40,
                  maxBlastForce: 40,
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
        ),
      );
        }
        )
    );
  }

  void _changeGoalDialog() async {
    final controller = TextEditingController();
    final newGoal = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.isOz ? "Enter new goal (oz):" : "Enter new goal (ml):"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: widget.isOz ? "How many oz?" : "How many ml?",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cancel")
          ),
          TextButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value > 0) {
                // Girilen değeri her zaman ml'ye çevir
                final mlValue = widget.isOz ? (value * ML_TO_OZ).round() : value;
                Navigator.pop(context, mlValue);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
    if (newGoal != null) {
      setDailyGoal(newGoal);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isOz 
              ? 'Goal set to ${(newGoal / ML_TO_OZ).round()} oz'
              : 'Goal set to $newGoal ml'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

 void _showResetConfirmation() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24), // 👈 Küçük ekranlarda taşmayı önler
      title: const Text("Reset Today's Progress?"),
      content: SingleChildScrollView( // 👈 İçerik taşarsa kaydırılabilir olur
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              "This will reset your water intake for today to 0. Are you sure?",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.end, // 👈 Butonlar hizalı dursun
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () {
            resetWater();
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Daily progress reset!'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: const Text(
            "Reset",
            style: TextStyle(color: Colors.red),
          ),
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