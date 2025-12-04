import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/exercise_model.dart';
import '../models/history_model.dart';
import '../models/routine_model.dart';
import '../theme/app_colors.dart';
import 'plate_calculator_screen.dart';
import 'home_screen.dart'; // NECESARIO PARA NAVEGAR AL INICIO

class WorkoutScreen extends StatefulWidget {
  final String dayName;
  final List<String> exerciseIds;
  final String routineDayId;

  const WorkoutScreen({
    super.key,
    required this.dayName,
    required this.exerciseIds,
    this.routineDayId = '',
  });

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  late Box<Exercise> exerciseBox;
  late List<String> currentExercises;
  
  // Mapa crucial para datos: ID Ejercicio -> Lista de Sets
  final Map<String, List<WorkoutSet>> _sessionData = {};
  
  // Cache de definiciones de ejercicios
  final Map<String, Exercise> _exerciseDefs = {};

  // CONTROLADORES DE TEXTO: Esto evita que el teclado se cierre al escribir
  // Mapa: ID Ejercicio -> Lista de Controladores (uno por set)
  final Map<String, List<TextEditingController>> _weightControllers = {};
  final Map<String, List<TextEditingController>> _repsControllers = {};

  // Temporizador
  Timer? _timer;
  int _secondsRest = 0;
  bool _isResting = false;
  int _suggestedRest = 90;

  @override
  void initState() {
    super.initState();
    exerciseBox = Hive.box<Exercise>('exerciseBox');
    currentExercises = List.from(widget.exerciseIds);

    for (var id in currentExercises) {
      _sessionData[id] = [];
      _weightControllers[id] = [];
      _repsControllers[id] = [];
      
      _exerciseDefs[id] = exerciseBox.values.firstWhere(
        (e) => e.id == id,
        orElse: () => Exercise(id: id, name: 'Desconocido', muscleGroup: '', equipment: '', movementPattern: ''),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Limpiar controladores para evitar fugas de memoria
    for (var list in _weightControllers.values) {
      for (var c in list) c.dispose();
    }
    for (var list in _repsControllers.values) {
      for (var c in list) c.dispose();
    }
    super.dispose();
  }

  // --- LÓGICA DEL TEMPORIZADOR ---
  void _startRestTimer(double rpe, String exerciseId) {
    _timer?.cancel();
    final ex = _exerciseDefs[exerciseId];
    int baseRest = 90;

    if (ex != null) {
      if (ex.movementPattern.contains('Squat') || ex.movementPattern.contains('Deadlift')) {
        baseRest = 180;
      }
    }
    if (rpe >= 9) baseRest += 60;
    else if (rpe < 6) baseRest -= 30;

    setState(() {
      _secondsRest = 0;
      _isResting = true;
      _suggestedRest = baseRest;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _secondsRest++);
    });
  }

  void _stopRestTimer() {
    _timer?.cancel();
    setState(() => _isResting = false);
  }

  String _formatTime(int seconds) {
    final m = (seconds / 60).floor();
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _calculate1RM(double weight, int reps) {
    if (reps == 0 || weight == 0) return "-";
    if (reps == 1) return "${weight.toInt()}";
    double oneRM = weight * (1 + reps / 30);
    return "${oneRM.toInt()}";
  }

  // --- CONFIRMACIÓN ANTES DE SALIR (Soluciona pérdida de datos) ---
  Future<bool> _onWillPop() async {
    bool hasData = _sessionData.values.any((sets) => sets.isNotEmpty);
    if (!hasData) return true;

    return (await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('¿Salir del entrenamiento?', style: TextStyle(color: Colors.white)),
        content: const Text('Si sales ahora, los datos no guardados se perderán.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Salir sin guardar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    )) ?? false;
  }

  void _finishWorkout() async {
    List<WorkoutExercise> exercisesDone = [];
    
    // Recopilar datos
    _sessionData.forEach((exId, sets) {
      // Sincronizar controladores con datos por seguridad
      for (int i = 0; i < sets.length; i++) {
        sets[i].weight = double.tryParse(_weightControllers[exId]![i].text) ?? 0;
        sets[i].reps = int.tryParse(_repsControllers[exId]![i].text) ?? 0;
      }

      if (sets.isNotEmpty) {
        exercisesDone.add(WorkoutExercise(
          exerciseId: exId,
          exerciseName: _exerciseDefs[exId]?.name ?? 'Ejercicio',
          sets: sets,
        ));
      }
    });

    if (exercisesDone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Registra al menos una serie para guardar."))
      );
      return;
    }

    final session = WorkoutSession(
      date: DateTime.now(),
      routineName: widget.dayName,
      exercises: exercisesDone,
      durationInMinutes: 60, // Podrías implementar un contador real
    );

    // Guardar en Hive
    final historyBox = await Hive.openBox<WorkoutSession>('historyBox');
    await historyBox.add(session);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Entrenamiento Guardado!'))
      );
      // NAVEGACIÓN SEGURA: Borra el historial y va al Home
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()), 
        (route) => false
      );
    }
  }

  void _addSet(String exId) {
    setState(() {
      double lastWeight = 0;
      int lastReps = 0;
      // Copiar datos del set anterior para facilitar la entrada
      if (_sessionData[exId]!.isNotEmpty) {
        lastWeight = _sessionData[exId]!.last.weight;
        lastReps = _sessionData[exId]!.last.reps;
      }
      
      final newSet = WorkoutSet(weight: lastWeight, reps: lastReps, rpe: 8);
      _sessionData[exId]!.add(newSet);

      // AGREGAR CONTROLADORES (Importante para que no falle el input)
      _weightControllers[exId]!.add(TextEditingController(text: lastWeight == 0 ? '' : lastWeight.toString()));
      _repsControllers[exId]!.add(TextEditingController(text: lastReps == 0 ? '' : lastReps.toString()));
    });
  }

  void _removeSet(String exId, int index) {
    setState(() {
      _sessionData[exId]!.removeAt(index);
      // Eliminar controladores también
      _weightControllers[exId]![index].dispose();
      _weightControllers[exId]!.removeAt(index);
      _repsControllers[exId]![index].dispose();
      _repsControllers[exId]!.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    // WillPopScope atrapa el botón físico "Atrás"
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () async {
              if (await _onWillPop()) {
                if (mounted) Navigator.of(context).pop();
              }
            },
          ),
          title: Text(widget.dayName),
          backgroundColor: AppColors.surface,
          actions: [
            IconButton(
              icon: const Icon(Icons.calculate, color: Colors.orange),
              onPressed: () => Navigator.push(
                context, 
                MaterialPageRoute(builder: (_) => const PlateCalculatorScreen())
              ),
              tooltip: "Calculadora",
            )
          ],
        ),
        body: Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: currentExercises.length,
              itemBuilder: (context, index) {
                final exId = currentExercises[index];
                final exercise = _exerciseDefs[exId]!;
                final sets = _sessionData[exId] ?? [];

                return Card(
                  color: AppColors.surface,
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name, 
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
                        ),
                        const SizedBox(height: 10),
                        
                        // Encabezados
                        if (sets.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                SizedBox(width: 30, child: Text("#", style: TextStyle(color: Colors.grey))),
                                Expanded(child: Text("KG", style: TextStyle(color: Colors.grey), textAlign: TextAlign.center)),
                                SizedBox(width: 10),
                                Expanded(child: Text("Reps", style: TextStyle(color: Colors.grey), textAlign: TextAlign.center)),
                                SizedBox(width: 10),
                                SizedBox(width: 40, child: Text("1RM", style: TextStyle(color: Colors.grey, fontSize: 10))),
                                SizedBox(width: 40), // Espacio para borrar/timer
                              ],
                            ),
                          ),

                        // Lista de Sets con Controladores
                        ...sets.asMap().entries.map((entry) {
                          int setIdx = entry.key;
                          WorkoutSet set = entry.value;
                          
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 30, 
                                  child: Text("${setIdx + 1}", style: const TextStyle(color: Colors.white))
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _weightControllers[exId]![setIdx],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                                      filled: true,
                                      fillColor: Colors.black26,
                                      border: OutlineInputBorder(borderSide: BorderSide.none),
                                    ),
                                    onChanged: (v) => set.weight = double.tryParse(v) ?? 0,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _repsControllers[exId]![setIdx],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                                      filled: true,
                                      fillColor: Colors.black26,
                                      border: OutlineInputBorder(borderSide: BorderSide.none),
                                    ),
                                    onChanged: (v) => set.reps = int.tryParse(v) ?? 0,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    _calculate1RM(set.weight, set.reps),
                                    style: const TextStyle(color: Colors.orange, fontSize: 12),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () => _removeSet(exId, setIdx),
                                )
                              ],
                            ),
                          );
                        }).toList(),

                        TextButton.icon(
                          onPressed: () => _addSet(exId),
                          icon: const Icon(Icons.add),
                          label: const Text("Agregar Serie"),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),

            // Timer flotante
            if (_isResting)
              Positioned(
                bottom: 80,
                left: 20,
                right: 20,
                child: Card(
                  color: Colors.black87,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Descansando...", style: TextStyle(color: Colors.white)),
                            Text("Sugerido: $_suggestedRest s", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                        Text(_formatTime(_secondsRest), style: const TextStyle(color: AppColors.primary, fontSize: 32, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.stop, color: Colors.red), onPressed: _stopRestTimer),
                      ],
                    ),
                  ),
                ),
              ),

            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: _finishWorkout,
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text("TERMINAR ENTRENAMIENTO", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}