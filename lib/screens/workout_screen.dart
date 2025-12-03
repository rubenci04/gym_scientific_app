import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/exercise_model.dart';
import '../models/history_model.dart';
import '../models/routine_model.dart';
import '../theme/app_colors.dart';
import 'plate_calculator_screen.dart';

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
  late Map<String, Exercise> _exerciseDataMap;
  late List<String> currentExercises;
  final Map<String, List<WorkoutSet>> _sessionData = {};

  // Temporizador
  Timer? _timer;
  int _secondsRest = 0;
  bool _isResting = false;
  int _suggestedRest = 90; // Default

  @override
  void initState() {
    super.initState();
    exerciseBox = Hive.box<Exercise>('exerciseBox');
    currentExercises = List.from(widget.exerciseIds);

    _exerciseDataMap = {
      for (var exId in currentExercises)
        exId: exerciseBox.values.firstWhere(
          (e) => e.id == exId,
          orElse: () => Exercise(
            id: exId,
            name: 'Ejercicio no encontrado',
            muscleGroup: '',
            equipment: '',
            movementPattern: '',
          ),
        ),
    };

    for (var id in currentExercises) {
      _sessionData[id] = [];
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- LÓGICA DEL TEMPORIZADOR INTELIGENTE ---
  void _startRestTimer(double rpe, String exerciseId) {
    _timer?.cancel();

    // Calcular descanso sugerido basado en RPE y Tipo de Ejercicio
    final ex = _exerciseDataMap[exerciseId];
    int baseRest = 90;

    if (ex != null) {
      // Compuestos pesados requieren más descanso
      if (ex.movementPattern.contains('Squat') ||
          ex.movementPattern.contains('Deadlift') ||
          ex.movementPattern.contains('Press')) {
        baseRest = 180; // 3 min
      }
    }

    // Ajuste por RPE
    if (rpe >= 9) {
      baseRest += 60;
    } else if (rpe >= 8) {
      baseRest += 30;
    } else if (rpe < 6) {
      baseRest -= 30;
    }

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

  // --- LÓGICA 1RM ESTIMADO (Epley) ---
  String _calculate1RM(double weight, int reps) {
    if (reps == 0 || weight == 0) return "-";
    if (reps == 1) return "${weight.toInt()}";

    // Epley Formula: 1RM = Weight * (1 + Reps/30)
    double oneRM = weight * (1 + reps / 30);
    return "${oneRM.toInt()}";
  }

  // --- LÓGICA DE EDICIÓN DE RUTINA ---
  void _removeExercise(int index) {
    final exId = currentExercises[index];
    setState(() {
      _sessionData.remove(exId);
      _exerciseDataMap.remove(exId);
      currentExercises.removeAt(index);
    });
  }

  void _showAddExerciseDialog([int? swapIndex]) {
    final allExercises = exerciseBox.values.toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return ListView.builder(
              controller: scrollController,
              itemCount: allExercises.length,
              itemBuilder: (c, i) {
                final ex = allExercises[i];
                return ListTile(
                  title: Text(
                    ex.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    ex.muscleGroup,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.add, color: AppColors.primary),
                  onTap: () {
                    setState(() {
                      _exerciseDataMap[ex.id] = ex;
                      if (swapIndex != null) {
                        _sessionData.remove(currentExercises[swapIndex]);
                        currentExercises[swapIndex] = ex.id;
                      } else {
                        currentExercises.add(ex.id);
                      }
                      if (!_sessionData.containsKey(ex.id)) {
                        _sessionData[ex.id] = [];
                      }
                    });
                    Navigator.pop(ctx);
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  void _saveRoutineChanges() async {
    if (widget.routineDayId.isEmpty) return;
    final routineBox = Hive.box<WeeklyRoutine>('routineBox');
    final currentRoutine = routineBox.get('currentRoutine');
    if (currentRoutine == null) return;

    final dayIndex = currentRoutine.days.indexWhere(
      (d) => d.id == widget.routineDayId,
    );
    if (dayIndex != -1) {
      currentRoutine.days[dayIndex].exerciseIds = List.from(currentExercises);
      await currentRoutine.save();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cambios guardados en la rutina.')),
        );
      }
    }
  }

  void _finishWorkout() async {
    final historyBox = Hive.box<WorkoutSession>('historyBox');
    List<WorkoutExercise> exercisesDone = [];

    _sessionData.forEach((exId, sets) {
      if (sets.isNotEmpty && currentExercises.contains(exId)) {
        final exDef = _exerciseDataMap[exId]!;
        exercisesDone.add(
          WorkoutExercise(
            exerciseId: exId,
            exerciseName: exDef.name,
            sets: sets,
          ),
        );
      }
    });

    if (exercisesDone.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final session = WorkoutSession(
      date: DateTime.now(),
      routineName: widget.dayName,
      exercises: exercisesDone,
      durationInMinutes: 60,
    );

    await historyBox.add(session);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('¡Entrenamiento Guardado!')));
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
    }
  }

  void _addSet(String exId) {
    setState(() {
      if (!_sessionData.containsKey(exId)) {
        _sessionData[exId] = [];
      }
      double lastWeight = 0;
      int lastReps = 0;
      if (_sessionData[exId]!.isNotEmpty) {
        lastWeight = _sessionData[exId]!.last.weight;
        lastReps = _sessionData[exId]!.last.reps;
      }

      _sessionData[exId]!.add(
        WorkoutSet(weight: lastWeight, reps: lastReps, rpe: 8.0),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.dayName),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate, color: Colors.orange),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => const PlateCalculatorScreen()),
            ),
            tooltip: "Calculadora de Placas",
          ),
          IconButton(
            icon: const Icon(Icons.save, color: AppColors.primary),
            onPressed: _saveRoutineChanges,
            tooltip: "Guardar Cambios a la Rutina",
          ),
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.secondary),
            onPressed: () => _showAddExerciseDialog(),
            tooltip: "Agregar Ejercicio",
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: currentExercises.length,
            itemBuilder: (context, index) {
              final exId = currentExercises[index];
              final exercise = _exerciseDataMap[exId]!;
              final sets = _sessionData[exId] ?? [];

              return Card(
                color: AppColors.surface,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              exercise.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          PopupMenuButton(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.grey,
                            ),
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'swap',
                                child: Text('Cambiar Ejercicio'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  'Eliminar',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                            onSelected: (val) {
                              if (val == 'delete') {
                                _removeExercise(index);
                              }
                              if (val == 'swap') {
                                _showAddExerciseDialog(index);
                              }
                            },
                          ),
                        ],
                      ),

                      if (sets.isNotEmpty)
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(1),
                            1: FlexColumnWidth(2),
                            2: FlexColumnWidth(2),
                            3: FlexColumnWidth(2),
                            4: FlexColumnWidth(1),
                            5: FlexColumnWidth(1), // 1RM
                          },
                          children: [
                            const TableRow(
                              children: [
                                Text("#", style: TextStyle(color: Colors.grey)),
                                Text(
                                  "KG",
                                  style: TextStyle(color: Colors.grey),
                                ),
                                Text(
                                  "Reps",
                                  style: TextStyle(color: Colors.grey),
                                ),
                                Text(
                                  "RPE",
                                  style: TextStyle(color: Colors.grey),
                                ),
                                Text(
                                  "1RM",
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                  ),
                                ),
                                SizedBox(),
                              ],
                            ),
                            ...sets.asMap().entries.map((entry) {
                              int i = entry.key;
                              var s = entry.value;
                              return TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      "${i + 1}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 4,
                                    ),
                                    child: TextFormField(
                                      initialValue: s.weight.toString(),
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.all(8),
                                        filled: true,
                                        fillColor: Colors.black26,
                                        border: InputBorder.none,
                                      ),
                                      onChanged: (val) => setState(
                                        () => s.weight =
                                            double.tryParse(val) ?? 0,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 4,
                                    ),
                                    child: TextFormField(
                                      initialValue: s.reps.toString(),
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.all(8),
                                        filled: true,
                                        fillColor: Colors.black26,
                                        border: InputBorder.none,
                                      ),
                                      onChanged: (val) => setState(
                                        () => s.reps = int.tryParse(val) ?? 0,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 4,
                                    ),
                                    child: TextFormField(
                                      initialValue: s.rpe.toString(),
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.all(8),
                                        filled: true,
                                        fillColor: Colors.black26,
                                        border: InputBorder.none,
                                      ),
                                      onChanged: (val) =>
                                          s.rpe = double.tryParse(val) ?? 7.0,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      _calculate1RM(s.weight, s.reps),
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.check_circle_outline,
                                      color: AppColors.primary,
                                    ),
                                    onPressed: () =>
                                        _startRestTimer(s.rpe, exId),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),

                      TextButton.icon(
                        onPressed: () => _addSet(exId),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text("Agregar Serie"),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Timer Overlay
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
                          const Text(
                            "Descansando...",
                            style: TextStyle(color: Colors.white),
                          ),
                          Text(
                            "Sugerido: $_suggestedRest s",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatTime(_secondsRest),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.stop, color: Colors.red),
                        onPressed: _stopRestTimer,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: _finishWorkout,
              child: const Text(
                "TERMINAR ENTRENAMIENTO",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
