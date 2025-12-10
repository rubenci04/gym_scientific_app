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

  final Map<String, List<WorkoutSet>> _sessionData = {};
  final Map<String, Exercise> _exerciseDefs = {};
  final Map<String, List<TextEditingController>> _weightControllers = {};
  final Map<String, List<TextEditingController>> _repsControllers = {};
  final Map<String, List<TextEditingController>> _rpeControllers = {}; 

  Timer? _timer;
  int _secondsRest = 0;
  bool _isResting = false;
  int _suggestedRest = 90;
  double _timerProgress = 0.0;
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
      if (!_sessionData.containsKey(id)) {
        _sessionData[id] = [];
        _weightControllers[id] = [];
        _repsControllers[id] = [];
        _rpeControllers[id] = [];
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
      if (savedSession['routineId'] == widget.routineDayId ||
          (widget.routineDayId.isEmpty &&
              savedSession['dayName'] == widget.dayName)) {
        setState(() {
          final Map<String, List<WorkoutSet>> data =
              savedSession['sessionData'];
          data.forEach((exId, sets) {
            if (_sessionData.containsKey(exId)) {
              _sessionData[exId] = sets;
              _weightControllers[exId] = [];
              _repsControllers[exId] = [];
              _rpeControllers[exId] = [];
              for (var set in sets) {
                _weightControllers[exId]!.add(TextEditingController(text: set.weight.toString()));
                _repsControllers[exId]!.add(TextEditingController(text: set.reps.toString()));
                _rpeControllers[exId]!.add(TextEditingController(text: set.rpe.toString()));
              }
            }
          });
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sesión anterior restaurada')));
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
    for (var list in _weightControllers.values) { for (var c in list) c.dispose(); }
    for (var list in _repsControllers.values) { for (var c in list) c.dispose(); }
    for (var list in _rpeControllers.values) { for (var c in list) c.dispose(); }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      CurrentWorkoutService.saveSession(
        routineId: widget.routineDayId,
        dayName: widget.dayName,
        sessionData: _sessionData,
      );
    }
  }

  void _startRestTimer(double rpe, String exerciseId) {
    _timer?.cancel();
    final ex = _exerciseDefs[exerciseId];
    int baseRest = 90; 

    if (ex != null) {
      if (ex.movementPattern.contains('Squat') ||
          ex.movementPattern.contains('Deadlift') ||
          ex.movementPattern.contains('Press')) {
        baseRest = 180;
      }
    }
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

  String _calculate1RM(double weight, int reps) {
    if (reps == 0 || weight == 0) return "-";
    if (reps == 1) return "${weight.toInt()}";
    double oneRM = weight * (1 + reps / 30);
    return "${oneRM.toInt()}";
  }

  // --- DIÁLOGOS EDUCATIVOS ---
  void _showEducationalDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(content, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido')),
        ],
      ),
    );
  }

  void _showWarmupGuide() {
    _showEducationalDialog(
      "Calentamiento General",
      "Antes de empezar:\n\n"
      "1. Movilidad Articular (3 min): Rota muñecas, hombros, caderas y tobillos.\n"
      "2. Activación (5 min): Cinta o bici suave para elevar temperatura corporal.\n"
      "3. Series de Aproximación: Haz 1-2 series con la barra vacía o peso muy ligero en el primer ejercicio.",
    );
  }

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
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(10)
                ),
                child: Image.asset(
                  'assets/exercises/${exercise.id}.png',
                  fit: BoxFit.contain,
                  errorBuilder: (c,e,s) => const Center(child: Icon(Icons.fitness_center, color: Colors.white24)),
                ),
              ),
              const SizedBox(height: 15),
              if (exercise.description.isNotEmpty) ...[
                const Text("Biomecánica:", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                Text(exercise.description, style: const TextStyle(color: Colors.white70)),
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido')),
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
            content: const Text('Tu progreso se guardará automáticamente.', style: TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
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

    _sessionData.forEach((exId, sets) {
      for (int i = 0; i < sets.length; i++) {
        sets[i].weight = double.tryParse(_weightControllers[exId]![i].text) ?? 0;
        sets[i].reps = int.tryParse(_repsControllers[exId]![i].text) ?? 0;
        sets[i].rpe = double.tryParse(_rpeControllers[exId]![i].text) ?? 0;
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registra al menos una serie para guardar.")));
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
            
            // --- RECORDATORIO ESTIRAMIENTO ---
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.accessibility_new, color: Colors.blue, size: 20),
                  SizedBox(width: 10),
                  Expanded(child: Text("¡No olvides estirar! Dedica 5 min a relajar los músculos trabajados.", style: TextStyle(color: Colors.white, fontSize: 12))),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text('¿Finalizar sesión?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Seguir')),
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
      double lastRpe = 8.0;

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
    Navigator.push(context, MaterialPageRoute(builder: (_) => PlateCalculatorScreen(initialWeight: currentWeight)));
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
            onPressed: () async { if (await _onWillPop()) if (mounted) Navigator.of(context).pop(); },
          ),
          title: Text(widget.dayName),
          backgroundColor: AppColors.surface,
          actions: [
            IconButton(icon: const Icon(Icons.save, color: AppColors.secondary), onPressed: _finishWorkout),
            IconButton(icon: const Icon(Icons.calculate, color: Colors.orange), onPressed: () => _openCalculator(0)),
          ],
        ),
        body: Stack(
          children: [
            // --- HEADER DE CALENTAMIENTO ---
            Positioned(
              top: 0, left: 0, right: 0,
              child: GestureDetector(
                onTap: _showWarmupGuide,
                child: Container(
                  color: Colors.orangeAccent.withOpacity(0.2),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 18),
                      SizedBox(width: 8),
                      Text("Ver Calentamiento Sugerido", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: 40), // Espacio para el banner de calentamiento
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 120),
                itemCount: currentExercises.length,
                itemBuilder: (context, index) {
                  final routineExercise = currentExercises[index];
                  final exId = routineExercise.exerciseId;
                  final exercise = _exerciseDefs[exId]!;
                  final sets = _sessionData[exId] ?? [];
                  
                  final imagePath = 'assets/exercises/${exercise.id}.png';

                  return Card(
                    color: AppColors.surface,
                    margin: const EdgeInsets.all(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => _showExerciseInfo(exercise),
                                child: Container(
                                  width: 50, height: 50,
                                  margin: const EdgeInsets.only(right: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white12)
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      imagePath,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c,e,s) => const Icon(Icons.fitness_center, color: Colors.white54, size: 20),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exercise.name,
                                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                      maxLines: 2,
                                    ),
                                    Text(
                                      "${exercise.muscleGroup} • ${exercise.equipment}",
                                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.info_outline, color: AppColors.primary),
                                onPressed: () => _showExerciseInfo(exercise),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),

                          // --- ENCABEZADOS DE COLUMNAS (CON AYUDA) ---
                          if (sets.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  const SizedBox(width: 30, child: Text("#", style: TextStyle(color: Colors.grey))),
                                  const Expanded(child: Text("KG", style: TextStyle(color: Colors.grey), textAlign: TextAlign.center)),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildHeaderWithHelp("Reps", "Repeticiones: Cantidad de veces que levantas el peso en una serie.")),
                                  const SizedBox(width: 8),
                                  Expanded(child: _buildHeaderWithHelp("RPE", "Índice de Esfuerzo Percibido (1-10):\n\n10: Fallo (no puedes más).\n9: Te queda 1 repetición.\n8: Te quedan 2 reps (Ideal).", color: AppColors.secondary)),
                                  const SizedBox(width: 8),
                                  SizedBox(width: 35, child: _buildHeaderWithHelp("1RM", "1 Repetición Máxima Estimada: Cuánto peso podrías levantar teóricamente una sola vez basado en esta serie.", isSmall: true)),
                                  const SizedBox(width: 30), 
                                ],
                              ),
                            ),

                          // ... (RESTO DEL CÓDIGO DE SERIES IGUAL QUE ANTES) ...
                          ...sets.asMap().entries.map((entry) {
                            int setIdx = entry.key;
                            WorkoutSet set = entry.value;

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                children: [
                                  SizedBox(width: 30, child: Text("${setIdx + 1}", style: const TextStyle(color: Colors.white))),
                                  Expanded(child: _buildCompactInput(controller: _weightControllers[exId]![setIdx], onChanged: (v) { set.weight = double.tryParse(v) ?? 0; _autoSave(); })),
                                  const SizedBox(width: 4),
                                  Expanded(child: _buildCompactInput(controller: _repsControllers[exId]![setIdx], onChanged: (v) { set.reps = int.tryParse(v) ?? 0; _autoSave(); })),
                                  const SizedBox(width: 4),
                                  Expanded(child: _buildCompactInput(controller: _rpeControllers[exId]![setIdx], isRpe: true, onChanged: (v) { set.rpe = double.tryParse(v) ?? 0; _autoSave(); })),
                                  const SizedBox(width: 8),
                                  SizedBox(width: 35, child: Text(_calculate1RM(set.weight, set.reps), style: const TextStyle(color: Colors.orange, fontSize: 12))),
                                  IconButton(icon: const Icon(Icons.close, color: Colors.redAccent, size: 18), onPressed: () => _removeSet(exId, setIdx)),
                                ],
                              ),
                            );
                          }).toList(),

                          // --- BOTONES ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(onPressed: () => _addSet(exId), icon: const Icon(Icons.add), label: const Text("Serie")),
                              if (sets.isNotEmpty)
                                TextButton.icon(onPressed: () => _startRestTimer(sets.last.rpe, exId), icon: const Icon(Icons.timer_outlined, color: AppColors.secondary), label: const Text("Descanso", style: TextStyle(color: AppColors.secondary))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            if (_isResting)
              Positioned(
                bottom: 80, left: 20, right: 20,
                child: Card(
                  color: Colors.black87,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        SizedBox(width: 60, height: 60, child: Stack(alignment: Alignment.center, children: [CircularProgressIndicator(value: _timerProgress, backgroundColor: Colors.grey[800], valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary), strokeWidth: 6), Text("${_suggestedRest - _secondsRest}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])),
                        const SizedBox(width: 15),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Descanso Inteligente", style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)), Text("Adaptado a tu RPE. Meta: $_suggestedRest s", style: const TextStyle(color: Colors.grey, fontSize: 12))])),
                        IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.blue), onPressed: () => _addTime(30)),
                        IconButton(icon: const Icon(Icons.skip_next, color: Colors.white), onPressed: _stopRestTimer),
                      ],
                    ),
                  ),
                ),
              ),

            Positioned(
              bottom: 20, left: 20, right: 20,
              child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: _finishWorkout, icon: const Icon(Icons.check_circle, color: Colors.white), label: const Text("TERMINAR SESIÓN", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
            ),
          ],
        ),
      ),
    );
  }

  // Header clickeable para ayuda
  Widget _buildHeaderWithHelp(String text, String helpText, {Color color = Colors.grey, bool isSmall = false}) {
    return GestureDetector(
      onTap: () => _showEducationalDialog(text, helpText),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(text, style: TextStyle(color: color, fontSize: isSmall ? 10 : 14, fontWeight: isSmall ? FontWeight.normal : FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(width: 2),
          Icon(Icons.help_outline, color: color.withOpacity(0.5), size: isSmall ? 10 : 14),
        ],
      ),
    );
  }

  Widget _buildCompactInput({required TextEditingController controller, required Function(String) onChanged, bool isRpe = false}) {
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
        border: OutlineInputBorder(borderSide: BorderSide(color: isRpe ? AppColors.secondary : AppColors.inputBorder), borderRadius: BorderRadius.circular(4)),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isRpe ? AppColors.secondary.withOpacity(0.5) : AppColors.inputBorder), borderRadius: BorderRadius.circular(4)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: isRpe ? AppColors.secondary : AppColors.primary, width: 2), borderRadius: BorderRadius.circular(4)),
      ),
      onChanged: onChanged,
    );
  }
}