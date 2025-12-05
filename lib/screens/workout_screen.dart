import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/exercise_model.dart';
import '../models/history_model.dart';
import '../models/routine_model.dart';
import '../theme/app_colors.dart';
import '../services/current_workout_service.dart';
import 'plate_calculator_screen.dart';
import 'home_screen.dart';

class WorkoutScreen extends StatefulWidget {
  final String dayName;
  final List<RoutineExercise> routineExercises;
  final String routineDayId;

  const WorkoutScreen({
    super.key,
    required this.dayName,
    required this.routineExercises,
    this.routineDayId = '',
  });

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen>
    with WidgetsBindingObserver {
  late Box<Exercise> exerciseBox;
  late List<RoutineExercise> currentExercises;

  // Mapa crucial para datos: ID Ejercicio -> Lista de Sets
  final Map<String, List<WorkoutSet>> _sessionData = {};

  // Cache de definiciones de ejercicios
  final Map<String, Exercise> _exerciseDefs = {};

  // CONTROLADORES DE TEXTO
  final Map<String, List<TextEditingController>> _weightControllers = {};
  final Map<String, List<TextEditingController>> _repsControllers = {};

  // Temporizador
  Timer? _timer;
  int _secondsRest = 0;
  bool _isResting = false;
  int _suggestedRest = 90;
  double _timerProgress = 0.0; // 0.0 a 1.0

  // Debouncer para guardado automático
  Timer? _saveDebouncer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    exerciseBox = Hive.box<Exercise>('exerciseBox');
    currentExercises = List.from(widget.routineExercises);

    _initializeDataStructures();
    _restoreSession();
  }

  void _initializeDataStructures() {
    for (var routineExercise in currentExercises) {
      final id = routineExercise.exerciseId;
      // Solo inicializar si no existen (para evitar sobrescribir al restaurar)
      if (!_sessionData.containsKey(id)) {
        _sessionData[id] = [];
        _weightControllers[id] = [];
        _repsControllers[id] = [];
      }

      _exerciseDefs[id] = exerciseBox.values.firstWhere(
        (e) => e.id == id,
        orElse: () => Exercise(
          id: id,
          name: 'Desconocido',
          muscleGroup: '',
          equipment: '',
          movementPattern: '',
        ),
      );
    }
  }

  Future<void> _restoreSession() async {
    final savedSession = await CurrentWorkoutService.getSession();
    if (savedSession != null) {
      // Verificar si la sesión guardada corresponde a esta rutina
      if (savedSession['routineId'] == widget.routineDayId ||
          (widget.routineDayId.isEmpty &&
              savedSession['dayName'] == widget.dayName)) {
        setState(() {
          final Map<String, List<WorkoutSet>> data =
              savedSession['sessionData'];
          data.forEach((exId, sets) {
            if (_sessionData.containsKey(exId)) {
              _sessionData[exId] = sets;
              // Recrear controladores
              _weightControllers[exId] = [];
              _repsControllers[exId] = [];
              for (var set in sets) {
                _weightControllers[exId]!.add(
                  TextEditingController(text: set.weight.toString()),
                );
                _repsControllers[exId]!.add(
                  TextEditingController(text: set.reps.toString()),
                );
              }
            }
          });
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesión anterior restaurada')),
        );
      }
    }
  }

  void _autoSave() {
    if (_saveDebouncer?.isActive ?? false) _saveDebouncer!.cancel();
    _saveDebouncer = Timer(const Duration(seconds: 2), () {
      CurrentWorkoutService.saveSession(
        routineId: widget.routineDayId,
        dayName: widget.dayName,
        sessionData: _sessionData,
      );
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _saveDebouncer?.cancel();
    for (var list in _weightControllers.values) {
      for (var c in list) c.dispose();
    }
    for (var list in _repsControllers.values) {
      for (var c in list) c.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      CurrentWorkoutService.saveSession(
        routineId: widget.routineDayId,
        dayName: widget.dayName,
        sessionData: _sessionData,
      );
    }
  }

  // --- LÓGICA DEL TEMPORIZADOR ---
  void _startRestTimer(double rpe, String exerciseId) {
    _timer?.cancel();
    final ex = _exerciseDefs[exerciseId];
    int baseRest = 90;

    if (ex != null) {
      if (ex.movementPattern.contains('Squat') ||
          ex.movementPattern.contains('Deadlift')) {
        baseRest = 180;
      }
    }
    if (rpe >= 9)
      baseRest += 60;
    else if (rpe < 6)
      baseRest -= 30;

    setState(() {
      _secondsRest = 0;
      _isResting = true;
      _suggestedRest = baseRest;
      _timerProgress = 0.0;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsRest++;
        _timerProgress = (_secondsRest / _suggestedRest).clamp(0.0, 1.0);
      });
    });
  }

  void _stopRestTimer() {
    _timer?.cancel();
    setState(() => _isResting = false);
  }

  void _addTime(int seconds) {
    setState(() {
      _suggestedRest += seconds;
      // Recalcular progreso para que no salte bruscamente
      _timerProgress = (_secondsRest / _suggestedRest).clamp(0.0, 1.0);
    });
  }

  String _calculate1RM(double weight, int reps) {
    if (reps == 0 || weight == 0) return "-";
    if (reps == 1) return "${weight.toInt()}";
    double oneRM = weight * (1 + reps / 30);
    return "${oneRM.toInt()}";
  }

  Future<bool> _onWillPop() async {
    bool hasData = _sessionData.values.any((sets) => sets.isNotEmpty);
    if (!hasData) return true;

    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text(
              '¿Salir del entrenamiento?',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Si sales ahora, se guardará tu progreso para continuar luego.',
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  // Guardar antes de salir
                  CurrentWorkoutService.saveSession(
                    routineId: widget.routineDayId,
                    dayName: widget.dayName,
                    sessionData: _sessionData,
                  );
                  Navigator.of(context).pop(true);
                },
                child: const Text(
                  'Salir y Guardar',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
        )) ??
        false;
  }

  void _finishWorkout() async {
    List<WorkoutExercise> exercisesDone = [];
    double totalVolume = 0;
    int totalSets = 0;

    _sessionData.forEach((exId, sets) {
      for (int i = 0; i < sets.length; i++) {
        sets[i].weight =
            double.tryParse(_weightControllers[exId]![i].text) ?? 0;
        sets[i].reps = int.tryParse(_repsControllers[exId]![i].text) ?? 0;
        totalVolume += sets[i].weight * sets[i].reps;
      }

      if (sets.isNotEmpty) {
        exercisesDone.add(
          WorkoutExercise(
            exerciseId: exId,
            exerciseName: _exerciseDefs[exId]?.name ?? 'Ejercicio',
            sets: sets,
          ),
        );
        totalSets += sets.length;
      }
    });

    if (exercisesDone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registra al menos una serie para guardar."),
        ),
      );
      return;
    }

    // Mostrar resumen
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Resumen del Entrenamiento',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ejercicios: ${exercisesDone.length}',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              'Series Totales: $totalSets',
              style: const TextStyle(color: Colors.white70),
            ),
            Text(
              'Volumen Total: ${totalVolume.toStringAsFixed(0)} kg',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            const Text(
              '¿Deseas finalizar y guardar?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir Entrenando'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final session = WorkoutSession(
      date: DateTime.now(),
      routineName: widget.dayName,
      exercises: exercisesDone,
      durationInMinutes: 60, // TODO: Calcular real
    );

    final historyBox = await Hive.openBox<WorkoutSession>('historyBox');
    await historyBox.add(session);

    // Limpiar sesión temporal
    await CurrentWorkoutService.clearSession();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('¡Entrenamiento Guardado!')));
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  void _addSet(String exId) {
    setState(() {
      double lastWeight = 0;
      int lastReps = 0;
      if (_sessionData[exId]!.isNotEmpty) {
        lastWeight = _sessionData[exId]!.last.weight;
        lastReps = _sessionData[exId]!.last.reps;
      }

      final newSet = WorkoutSet(weight: lastWeight, reps: lastReps, rpe: 8);
      _sessionData[exId]!.add(newSet);

      _weightControllers[exId]!.add(
        TextEditingController(
          text: lastWeight == 0 ? '' : lastWeight.toString(),
        ),
      );
      _repsControllers[exId]!.add(
        TextEditingController(text: lastReps == 0 ? '' : lastReps.toString()),
      );
    });
    _autoSave();
  }

  void _removeSet(String exId, int index) {
    setState(() {
      _sessionData[exId]!.removeAt(index);
      _weightControllers[exId]![index].dispose();
      _weightControllers[exId]!.removeAt(index);
      _repsControllers[exId]![index].dispose();
      _repsControllers[exId]!.removeAt(index);
    });
    _autoSave();
  }

  void _openCalculator(double currentWeight) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlateCalculatorScreen(initialWeight: currentWeight),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              onPressed: () => _openCalculator(0),
              tooltip: "Calculadora",
            ),
          ],
        ),
        body: Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.only(
                bottom: 120,
              ), // Espacio para timer y botón
              itemCount: currentExercises.length,
              itemBuilder: (context, index) {
                final routineExercise = currentExercises[index];
                final exId = routineExercise.exerciseId;
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                exercise.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.info_outline,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                // TODO: Mostrar info del ejercicio
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        if (sets.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 30,
                                  child: Text(
                                    "#",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "KG",
                                    style: TextStyle(color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "Reps",
                                    style: TextStyle(color: Colors.grey),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(width: 10),
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    "1RM",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 40),
                              ],
                            ),
                          ),

                        ...sets.asMap().entries.map((entry) {
                          int setIdx = entry.key;
                          WorkoutSet set = entry.value;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 30,
                                  child: Text(
                                    "${setIdx + 1}",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller:
                                        _weightControllers[exId]![setIdx],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      filled: true,
                                      fillColor: Colors.black26,
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    onChanged: (v) {
                                      set.weight = double.tryParse(v) ?? 0;
                                      _autoSave();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 4),
                                IconButton(
                                  icon: const Icon(
                                    Icons.calculate_outlined,
                                    color: Colors.orange,
                                    size: 16,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => _openCalculator(set.weight),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: TextField(
                                    controller: _repsControllers[exId]![setIdx],
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      filled: true,
                                      fillColor: Colors.black26,
                                      border: OutlineInputBorder(
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    onChanged: (v) {
                                      set.reps = int.tryParse(v) ?? 0;
                                      _autoSave();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    _calculate1RM(set.weight, set.reps),
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  onPressed: () => _removeSet(exId, setIdx),
                                ),
                              ],
                            ),
                          );
                        }).toList(),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: () => _addSet(exId),
                              icon: const Icon(Icons.add),
                              label: const Text("Agregar Serie"),
                            ),
                            if (sets.isNotEmpty)
                              TextButton.icon(
                                onPressed: () =>
                                    _startRestTimer(8, exId), // RPE 8 default
                                icon: const Icon(
                                  Icons.timer,
                                  color: Colors.blue,
                                ),
                                label: const Text(
                                  "Descanso",
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            if (_isResting)
              Positioned(
                bottom: 80,
                left: 20,
                right: 20,
                child: Card(
                  color: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: _timerProgress,
                                backgroundColor: Colors.grey[800],
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                                strokeWidth: 6,
                              ),
                              Text(
                                "${_suggestedRest - _secondsRest}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Descansando...",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Meta: $_suggestedRest s",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.add_circle_outline,
                            color: Colors.blue,
                          ),
                          onPressed: () => _addTime(30),
                          tooltip: "+30s",
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.skip_next,
                            color: Colors.white,
                          ),
                          onPressed: _stopRestTimer,
                          tooltip: "Saltar",
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
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _finishWorkout,
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text(
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
      ),
    );
  }
}
