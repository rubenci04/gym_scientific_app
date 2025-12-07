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
  // Necesito controladores para Peso, Reps y ahora también para RPE (Esfuerzo)
  final Map<String, List<TextEditingController>> _weightControllers = {};
  final Map<String, List<TextEditingController>> _repsControllers = {};
  final Map<String, List<TextEditingController>> _rpeControllers = {}; // ¡Nuevo!

  // Temporizador
  Timer? _timer;
  int _secondsRest = 0;
  bool _isResting = false;
  int _suggestedRest = 90;
  double _timerProgress = 0.0;

  // Debouncer para guardado automático (para no guardar a cada tecla que presiono)
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
      // Solo inicializo si es la primera vez que cargo este ejercicio en memoria
      if (!_sessionData.containsKey(id)) {
        _sessionData[id] = [];
        _weightControllers[id] = [];
        _repsControllers[id] = [];
        _rpeControllers[id] = [];
      }

      // Busco la info científica del ejercicio (músculos, tips, etc.)
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
    // Intento recuperar si se me cerró la app en medio del entrenamiento
    final savedSession = await CurrentWorkoutService.getSession();
    if (savedSession != null) {
      if (savedSession['routineId'] == widget.routineDayId ||
          (widget.routineDayId.isEmpty &&
              savedSession['dayName'] == widget.dayName)) {
        setState(() {
          final Map<String, List<WorkoutSet>> data =
              savedSession['sessionData'];
          data.forEach((exId, sets) {
            if (_sessionData.containsKey(exId)) {
              _sessionData[exId] = sets;
              // Recreo los controladores para que el texto aparezca en los inputs
              _weightControllers[exId] = [];
              _repsControllers[exId] = [];
              _rpeControllers[exId] = [];
              for (var set in sets) {
                _weightControllers[exId]!.add(
                  TextEditingController(text: set.weight.toString()),
                );
                _repsControllers[exId]!.add(
                  TextEditingController(text: set.reps.toString()),
                );
                // Restauro el RPE también
                _rpeControllers[exId]!.add(
                  TextEditingController(text: set.rpe.toString()),
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
    // Limpio memoria de todos los controladores
    for (var list in _weightControllers.values) {
      for (var c in list) c.dispose();
    }
    for (var list in _repsControllers.values) {
      for (var c in list) c.dispose();
    }
    for (var list in _rpeControllers.values) {
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

  // --- LÓGICA CIENTÍFICA DEL TEMPORIZADOR ---
  // El descanso depende del ejercicio (SNC) y del esfuerzo (RPE)
  void _startRestTimer(double rpe, String exerciseId) {
    _timer?.cancel();
    final ex = _exerciseDefs[exerciseId];
    int baseRest = 90; // Hipertrofia estándar

    if (ex != null) {
      // Ejercicios compuestos taxan más el Sistema Nervioso Central
      if (ex.movementPattern.contains('Squat') ||
          ex.movementPattern.contains('Deadlift') ||
          ex.movementPattern.contains('Press')) {
        baseRest = 180; // Fuerza/Potencia
      }
    }
    // Si me esforcé mucho (RPE alto), necesito más descanso
    if (rpe >= 9) baseRest += 60;
    else if (rpe < 6) baseRest -= 30;

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
      _timerProgress = (_secondsRest / _suggestedRest).clamp(0.0, 1.0);
    });
  }

  // Fórmula de Epley para estimar 1RM
  String _calculate1RM(double weight, int reps) {
    if (reps == 0 || weight == 0) return "-";
    if (reps == 1) return "${weight.toInt()}";
    double oneRM = weight * (1 + reps / 30);
    return "${oneRM.toInt()}";
  }

  // Mostrar info científica del ejercicio (Popup)
  void _showExerciseInfo(Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(exercise.name, style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (exercise.description.isNotEmpty) ...[
                const Text("Biomecánica:", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                Text(exercise.description, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
              ],
              if (exercise.commonMistakes.isNotEmpty) ...[
                const Text("Errores Comunes:", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ...exercise.commonMistakes.map((e) => Text("• $e", style: const TextStyle(color: Colors.white70))),
                const SizedBox(height: 10),
              ],
              if (exercise.tips.isNotEmpty) ...[
                const Text("Tips Pro:", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                ...exercise.tips.map((e) => Text("• $e", style: const TextStyle(color: Colors.white70))),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    bool hasData = _sessionData.values.any((sets) => sets.isNotEmpty);
    if (!hasData) return true;

    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('¿Pausar entrenamiento?', style: TextStyle(color: Colors.white)),
            content: const Text(
              'Tu progreso se guardará automáticamente para continuar luego.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  CurrentWorkoutService.saveSession(
                    routineId: widget.routineDayId,
                    dayName: widget.dayName,
                    sessionData: _sessionData,
                  );
                  Navigator.of(context).pop(true);
                },
                child: const Text('Salir y Guardar', style: TextStyle(color: AppColors.primary)),
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

    // Recopilo todos los datos de los inputs
    _sessionData.forEach((exId, sets) {
      for (int i = 0; i < sets.length; i++) {
        sets[i].weight = double.tryParse(_weightControllers[exId]![i].text) ?? 0;
        sets[i].reps = int.tryParse(_repsControllers[exId]![i].text) ?? 0;
        // Importante: Guardo el RPE real
        sets[i].rpe = double.tryParse(_rpeControllers[exId]![i].text) ?? 0;
        
        totalVolume += sets[i].weight * sets[i].reps;
      }

      // Solo guardo ejercicios que tengan series registradas
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
        const SnackBar(content: Text("Registra al menos una serie para guardar.")),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Resumen Científico', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ejercicios: ${exercisesDone.length}', style: const TextStyle(color: AppColors.textSecondary)),
            Text('Series Totales: $totalSets', style: const TextStyle(color: AppColors.textSecondary)),
            Text('Tonelaje: ${totalVolume.toStringAsFixed(0)} kg', style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            const Text('¿Finalizar sesión?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Seguir'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Finalizar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final session = WorkoutSession(
      date: DateTime.now(),
      routineName: widget.dayName,
      exercises: exercisesDone,
      durationInMinutes: 60, 
    );

    final historyBox = await Hive.openBox<WorkoutSession>('historyBox');
    await historyBox.add(session);
    await CurrentWorkoutService.clearSession();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Entrenamiento Guardado!')));
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
      double lastRpe = 8.0; // RPE por defecto

      // Si ya hay series, copio los valores de la anterior (ahorra tiempo)
      if (_sessionData[exId]!.isNotEmpty) {
        lastWeight = _sessionData[exId]!.last.weight;
        lastReps = _sessionData[exId]!.last.reps;
        lastRpe = _sessionData[exId]!.last.rpe;
      }

      final newSet = WorkoutSet(weight: lastWeight, reps: lastReps, rpe: lastRpe);
      _sessionData[exId]!.add(newSet);

      _weightControllers[exId]!.add(TextEditingController(text: lastWeight == 0 ? '' : lastWeight.toString()));
      _repsControllers[exId]!.add(TextEditingController(text: lastReps == 0 ? '' : lastReps.toString()));
      _rpeControllers[exId]!.add(TextEditingController(text: lastRpe.toString()));
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
      _rpeControllers[exId]![index].dispose();
      _rpeControllers[exId]!.removeAt(index);
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
              icon: const Icon(Icons.save, color: AppColors.secondary),
              onPressed: _finishWorkout,
              tooltip: "Guardar",
            ),
            IconButton(
              icon: const Icon(Icons.calculate, color: Colors.orange),
              onPressed: () => _openCalculator(0),
              tooltip: "Calculadora de Discos",
            ),
          ],
        ),
        body: Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.only(bottom: 120),
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
                        // --- ENCABEZADO DEL EJERCICIO ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                exercise.name,
                                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                            // Botón de Info Científica
                            IconButton(
                              icon: const Icon(Icons.info_outline, color: AppColors.primary),
                              onPressed: () => _showExerciseInfo(exercise),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // --- ENCABEZADOS DE COLUMNAS (Ahora con RPE) ---
                        if (sets.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                SizedBox(width: 30, child: Text("#", style: TextStyle(color: Colors.grey))),
                                Expanded(child: Text("KG", style: TextStyle(color: Colors.grey), textAlign: TextAlign.center)),
                                SizedBox(width: 8),
                                Expanded(child: Text("Reps", style: TextStyle(color: Colors.grey), textAlign: TextAlign.center)),
                                SizedBox(width: 8),
                                Expanded(child: Text("RPE", style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                                SizedBox(width: 8),
                                SizedBox(width: 35, child: Text("1RM", style: TextStyle(color: Colors.grey, fontSize: 10))),
                                SizedBox(width: 30), // Espacio para borrar
                              ],
                            ),
                          ),

                        // --- LISTA DE SERIES (SETS) ---
                        ...sets.asMap().entries.map((entry) {
                          int setIdx = entry.key;
                          WorkoutSet set = entry.value;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                SizedBox(width: 30, child: Text("${setIdx + 1}", style: const TextStyle(color: Colors.white))),
                                // Input PESO
                                Expanded(
                                  child: _buildCompactInput(
                                    controller: _weightControllers[exId]![setIdx],
                                    onChanged: (v) {
                                      set.weight = double.tryParse(v) ?? 0;
                                      _autoSave();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 4),
                                // Input REPS
                                Expanded(
                                  child: _buildCompactInput(
                                    controller: _repsControllers[exId]![setIdx],
                                    onChanged: (v) {
                                      set.reps = int.tryParse(v) ?? 0;
                                      _autoSave();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 4),
                                // Input RPE (Nuevo)
                                Expanded(
                                  child: _buildCompactInput(
                                    controller: _rpeControllers[exId]![setIdx],
                                    isRpe: true, // Para darle un color diferente
                                    onChanged: (v) {
                                      set.rpe = double.tryParse(v) ?? 0;
                                      _autoSave();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Cálculo automático 1RM
                                SizedBox(
                                  width: 35,
                                  child: Text(
                                    _calculate1RM(set.weight, set.reps),
                                    style: const TextStyle(color: Colors.orange, fontSize: 12),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                                  onPressed: () => _removeSet(exId, setIdx),
                                ),
                              ],
                            ),
                          );
                        }).toList(),

                        // --- BOTONES DE ACCIÓN ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              onPressed: () => _addSet(exId),
                              icon: const Icon(Icons.add),
                              label: const Text("Serie"),
                            ),
                            if (sets.isNotEmpty)
                              TextButton.icon(
                                // Al descansar, paso el RPE de la última serie para ajustar el tiempo
                                onPressed: () => _startRestTimer(sets.last.rpe, exId),
                                icon: const Icon(Icons.timer_outlined, color: AppColors.secondary),
                                label: const Text("Descanso", style: TextStyle(color: AppColors.secondary)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // --- POPUP FLOTANTE DEL TEMPORIZADOR ---
            if (_isResting)
              Positioned(
                bottom: 80,
                left: 20,
                right: 20,
                child: Card(
                  color: Colors.black87,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                strokeWidth: 6,
                              ),
                              Text("${_suggestedRest - _secondsRest}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Descanso Inteligente", style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                              Text("Adaptado a tu RPE. Meta: $_suggestedRest s", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.blue), onPressed: () => _addTime(30)),
                        IconButton(icon: const Icon(Icons.skip_next, color: Colors.white), onPressed: _stopRestTimer),
                      ],
                    ),
                  ),
                ),
              ),

            // --- BOTÓN TERMINAR ---
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _finishWorkout,
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text("TERMINAR SESIÓN", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Método auxiliar para limpiar el código de los inputs
  Widget _buildCompactInput({
    required TextEditingController controller,
    required Function(String) onChanged,
    bool isRpe = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textAlign: TextAlign.center,
      style: TextStyle(color: isRpe ? AppColors.secondary : Colors.white, fontWeight: isRpe ? FontWeight.bold : FontWeight.normal),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        filled: true,
        fillColor: isRpe ? AppColors.secondary.withOpacity(0.1) : AppColors.inputBackground,
        border: OutlineInputBorder(
          borderSide: BorderSide(color: isRpe ? AppColors.secondary : AppColors.inputBorder),
          borderRadius: BorderRadius.circular(4),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: isRpe ? AppColors.secondary.withOpacity(0.5) : AppColors.inputBorder),
          borderRadius: BorderRadius.circular(4),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: isRpe ? AppColors.secondary : AppColors.primary, width: 2),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      onChanged: onChanged,
    );
  }
}