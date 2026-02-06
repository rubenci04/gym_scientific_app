import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Para HapticFeedback y Sonidos
import 'package:hive_flutter/hive_flutter.dart';
import '../models/exercise_model.dart';
import '../models/history_model.dart';
import '../models/routine_model.dart';
import '../theme/app_colors.dart';
import '../services/current_workout_service.dart';
import 'plate_calculator_screen.dart';
import 'home_screen.dart';
import 'exercise_selection_screen.dart';

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

class _WorkoutScreenState extends State<WorkoutScreen> with WidgetsBindingObserver {
  late Box<Exercise> exerciseBox;
  late List<RoutineExercise> currentExercises;

  // Estructuras de datos
  final Map<String, List<WorkoutSet>> _sessionData = {};
  final Map<String, Exercise> _exerciseDefs = {};
  // Controladores de texto (se limpian en dispose)
  final Map<String, List<TextEditingController>> _weightControllers = {};
  final Map<String, List<TextEditingController>> _repsControllers = {};
  final Map<String, List<TextEditingController>> _rpeControllers = {}; 

  // Temporizadores
  late DateTime _startTime;
  Timer? _elapsedTimer;
  String _elapsedTimeString = "00:00";

  Timer? _restTimer;
  int _secondsRest = 0;
  bool _isResting = false;
  int _suggestedRest = 90;
  double _restTimerProgress = 0.0;
  
  Timer? _saveDebouncer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Escuchar ciclo de vida de la app
    exerciseBox = Hive.box<Exercise>('exerciseBox');
    
    // Iniciar Cronómetro Global
    _startTime = DateTime.now();
    _startElapsedTimer();
    
    // Copia local para poder modificarla (agregar/quitar ejercicios)
    currentExercises = List.from(widget.routineExercises);

    _initializeDataStructures();
    _restoreSession();
  }

  void _startElapsedTimer() {
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final now = DateTime.now();
      final difference = now.difference(_startTime);
      final hours = difference.inHours;
      final minutes = difference.inMinutes.remainder(60);
      final seconds = difference.inSeconds.remainder(60);
      
      setState(() {
        _elapsedTimeString = hours > 0 
            ? "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}"
            : "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
      });
    });
  }

  void _initializeDataStructures() {
    for (var routineExercise in currentExercises) {
      _initSingleExerciseData(routineExercise);
    }
  }

  void _initSingleExerciseData(RoutineExercise routineExercise) {
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
        name: id.toUpperCase(), // Fallback nombre
        muscleGroup: 'General',
        equipment: 'Varios',
        movementPattern: 'Mixto',
      ),
    );
  }

  // Restaurar si la app se cerró a medias
  Future<void> _restoreSession() async {
    final savedSession = await CurrentWorkoutService.getSession();
    if (savedSession != null) {
      // Verificar si la sesión guardada corresponde a esta rutina
      if (savedSession['routineId'] == widget.routineDayId ||
          (widget.routineDayId.isEmpty && savedSession['dayName'] == widget.dayName)) {
        
        setState(() {
          // Restaurar hora de inicio si es posible, o usar la actual
          // (Para simplificar, usamos la actual sesión, pero podríamos guardar el startTime también)
          
          final Map<String, List<WorkoutSet>> data = savedSession['sessionData'];
          
          data.forEach((exId, sets) {
            // Asegurarnos de que el ejercicio exista en la UI
            if (!_sessionData.containsKey(exId)) {
               // Si es un ejercicio nuevo que no estaba en la rutina base, lo añadimos
               final tempExercise = RoutineExercise(exerciseId: exId, sets: 3, reps: '10');
               currentExercises.add(tempExercise);
               _initSingleExerciseData(tempExercise);
            }

            _sessionData[exId] = sets;
            
            // Regenerar controladores
            _weightControllers[exId] = [];
            _repsControllers[exId] = [];
            _rpeControllers[exId] = [];
            
            for (var set in sets) {
              _weightControllers[exId]!.add(TextEditingController(text: set.weight == 0 ? '' : set.weight.toString()));
              _repsControllers[exId]!.add(TextEditingController(text: set.reps == 0 ? '' : set.reps.toString()));
              _rpeControllers[exId]!.add(TextEditingController(text: set.rpe.toString()));
            }
          });
        });
        
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🔄 Sesión anterior restaurada')));
      }
    }
  }

  void _autoSave() {
    if (_saveDebouncer?.isActive ?? false) _saveDebouncer!.cancel();
    _saveDebouncer = Timer(const Duration(seconds: 1), () {
      CurrentWorkoutService.saveSession(
        routineId: widget.routineDayId,
        dayName: widget.dayName,
        sessionData: _sessionData,
      );
    });
  }

  void _saveProgressOnly() {
    CurrentWorkoutService.saveSession(
      routineId: widget.routineDayId,
      dayName: widget.dayName,
      sessionData: _sessionData,
    );
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Progreso guardado localmente'),
        backgroundColor: Colors.green,
        duration: Duration(milliseconds: 1000),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _elapsedTimer?.cancel();
    _restTimer?.cancel();
    _saveDebouncer?.cancel();
    // Limpiar controladores
    for (var list in _weightControllers.values) { for (var c in list) c.dispose(); }
    for (var list in _repsControllers.values) { for (var c in list) c.dispose(); }
    for (var list in _rpeControllers.values) { for (var c in list) c.dispose(); }
    super.dispose();
  }

  // Guardado de emergencia al minimizar la app
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

  // --- LÓGICA DE EJERCICIOS ---

  void _addNewExercise() async {
    final Exercise? selected = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExerciseSelectionScreen()),
    );

    if (selected != null) {
      setState(() {
        // Si ya existe, no lo duplicamos, solo scrolleamos hacia él (pendiente implementar scroll)
        if (_sessionData.containsKey(selected.id)) return;

        final newRoutineEx = RoutineExercise(
          exerciseId: selected.id,
          sets: 3, 
          reps: '10',
          restTimeSeconds: 60 // Default aislamiento
        );
        
        currentExercises.add(newRoutineEx);
        _initSingleExerciseData(newRoutineEx);
      });
      _autoSave();
    }
  }

  void _replaceExercise(int index) async {
    final Exercise? selected = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExerciseSelectionScreen()),
    );

    if (selected != null) {
      setState(() {
        String oldId = currentExercises[index].exerciseId;
        
        // Limpiar controladores viejos
        if (_weightControllers[oldId] != null) {
           for (var c in _weightControllers[oldId]!) c.dispose();
           _weightControllers.remove(oldId);
           _repsControllers.remove(oldId);
           _rpeControllers.remove(oldId);
           _sessionData.remove(oldId);
        }

        currentExercises[index] = RoutineExercise(
           exerciseId: selected.id, 
           sets: currentExercises[index].sets, 
           reps: currentExercises[index].reps,
           restTimeSeconds: currentExercises[index].restTimeSeconds
        );
        
        _initSingleExerciseData(currentExercises[index]);
      });
      _autoSave();
    }
  }

  void _removeExerciseFromSession(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text("Eliminar ejercicio", style: Theme.of(context).textTheme.titleLarge),
        content: Text("¿Quitar este ejercicio de la sesión actual?", style: Theme.of(context).textTheme.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              setState(() {
                String id = currentExercises[index].exerciseId;
                _sessionData.remove(id); // Borrar datos
                currentExercises.removeAt(index);
              });
              Navigator.pop(ctx);
              _autoSave();
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.redAccent)),
          )
        ],
      )
    );
  }

  // --- TEMPORIZADOR DE DESCANSO ---

  void _startRestTimer(double rpe, String exerciseId) {
    _restTimer?.cancel();
    HapticFeedback.lightImpact();
    try { SystemSound.play(SystemSoundType.click); } catch (_) {}

    final ex = _exerciseDefs[exerciseId];
    int baseRest = 60; // Base para aislamiento

    // Lógica inteligente de descanso
    if (ex != null) {
      // Ejercicios compuestos demandan más ATP-PCr
      if (ex.mechanic == 'compound' || 
          ex.movementPattern.contains('Squat') ||
          ex.movementPattern.contains('Deadlift') ||
          ex.movementPattern.contains('Press') && ex.equipment == 'Barbell') {
        baseRest = 180; // 3 min
      } else if (ex.mechanic == 'compound') {
        baseRest = 120; // Compuestos medios (máquinas, mancuernas) = 2 min
      }
    }
    
    // Ajuste por esfuerzo percibido (RPE)
    if (rpe >= 8.5) baseRest += 30; // Si fue duro, +30s
    if (rpe >= 9.5) baseRest += 30; // Si fue fallo total, +30s extra

    setState(() {
      _secondsRest = 0;
      _isResting = true;
      _suggestedRest = baseRest;
      _restTimerProgress = 0.0;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsRest++;
        _restTimerProgress = (_secondsRest / _suggestedRest).clamp(0.0, 1.0);
        
        if (_secondsRest == _suggestedRest) {
          HapticFeedback.heavyImpact();
          try { SystemSound.play(SystemSoundType.alert); } catch (_) {}
        }
      });
    });
  }

  void _stopRestTimer() {
    _restTimer?.cancel();
    HapticFeedback.selectionClick();
    setState(() => _isResting = false);
  }

  void _addTime(int seconds) {
    HapticFeedback.lightImpact();
    setState(() {
      _suggestedRest += seconds;
      _restTimerProgress = (_secondsRest / _suggestedRest).clamp(0.0, 1.0);
    });
  }

  // --- PROTECCIÓN DE SALIDA ---
  Future<bool> _onWillPop() async {
    bool hasData = _sessionData.values.any((sets) => sets.isNotEmpty);
    if (!hasData) return true;

    final theme = Theme.of(context);
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text('¿Pausar entrenamiento?', style: theme.textTheme.titleLarge),
        content: Text('Tu tiempo corre. El progreso se guardará localmente.', style: theme.textTheme.bodyMedium),
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
            child: const Text('Guardar y Salir', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  void _finishWorkout() async {
    HapticFeedback.mediumImpact();

    List<WorkoutExercise> exercisesDone = [];
    double totalVolume = 0;
    int totalSets = 0;

    // Procesar datos
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Registra al menos una serie para terminar.")));
      return;
    }

    final theme = Theme.of(context);
    final durationMinutes = DateTime.now().difference(_startTime).inMinutes;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text('¡Entrenamiento Completado!', style: theme.textTheme.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryRow("Tiempo:", "$durationMinutes min", Icons.timer),
            _buildSummaryRow("Ejercicios:", "${exercisesDone.length}", Icons.fitness_center),
            _buildSummaryRow("Volumen Total:", "${totalVolume.toStringAsFixed(0)} kg", Icons.bar_chart),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Volver')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('FINALIZAR'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Guardar en Historial Permanente
    final session = WorkoutSession(
      date: DateTime.now(),
      routineName: widget.dayName,
      exercises: exercisesDone,
      durationInMinutes: durationMinutes > 0 ? durationMinutes : 1, // Mínimo 1 min
    );

    final historyBox = await Hive.openBox<WorkoutSession>('historyBox');
    await historyBox.add(session);
    
    // Limpiar sesión temporal
    await CurrentWorkoutService.clearSession();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Entrenamiento Guardado! 💪')));
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildSummaryRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text("$label ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  void _addSet(String exId) {
    HapticFeedback.lightImpact();
    setState(() {
      double lastWeight = 0;
      int lastReps = 0;
      double lastRpe = 8.0;

      // Copiar valores de la serie anterior para agilizar
      if (_sessionData[exId]!.isNotEmpty) {
        lastWeight = _sessionData[exId]!.last.weight;
        lastReps = _sessionData[exId]!.last.reps;
        lastRpe = _sessionData[exId]!.last.rpe;
      }

      // Crear nueva serie vacía
      final newSet = WorkoutSet(weight: lastWeight, reps: lastReps, rpe: lastRpe);
      _sessionData[exId]!.add(newSet);

      // Crear controladores
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

  void _showExerciseInfo(Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(exercise.name, style: theme.textTheme.titleLarge),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (exercise.description.isNotEmpty) ...[
                  const Text("Técnica:", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(exercise.description, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 15),
                ],
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(label: Text(exercise.muscleGroup), backgroundColor: AppColors.primary.withOpacity(0.2)),
                    Chip(label: Text(exercise.equipment), backgroundColor: theme.dividerColor.withOpacity(0.1)),
                  ],
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return WillPopScope( // Widget que captura el botón "Atrás"
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
            onPressed: () async { 
              if (await _onWillPop()) {
                if (mounted) Navigator.of(context).pop();
              }
            },
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.dayName, style: theme.appBarTheme.titleTextStyle?.copyWith(fontSize: 16)),
              // --- CRONÓMETRO EN APPBAR ---
              Row(
                children: [
                  const Icon(Icons.access_time, size: 12, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(_elapsedTimeString, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ],
              )
            ],
          ),
          backgroundColor: _isResting ? AppColors.secondary.withOpacity(0.9) : theme.appBarTheme.backgroundColor,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.save_outlined, color: AppColors.secondary),
              onPressed: _saveProgressOnly,
              tooltip: "Guardar Progreso",
            ),
            IconButton(icon: const Icon(Icons.calculate_outlined, color: Colors.orange), onPressed: () => _openCalculator(0)),
          ],
        ),
        body: Stack(
          children: [
            // LISTA DE EJERCICIOS
            Padding(
              padding: const EdgeInsets.only(top: 10), 
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 120), // Espacio para botones flotantes
                itemCount: currentExercises.length + 1,
                itemBuilder: (context, index) {
                  // --- BOTÓN AGREGAR EJERCICIO (Al final) ---
                  if (index == currentExercises.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          side: const BorderSide(color: AppColors.primary, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                        ),
                        onPressed: _addNewExercise,
                        icon: const Icon(Icons.add, color: AppColors.primary),
                        label: const Text("AÑADIR EJERCICIO EXTRA", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ),
                    );
                  }

                  // --- TARJETA DE EJERCICIO ---
                  final routineExercise = currentExercises[index];
                  final exId = routineExercise.exerciseId;
                  final exercise = _exerciseDefs[exId]!;
                  final sets = _sessionData[exId] ?? [];
                  
                  return Card(
                    color: theme.cardColor,
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    elevation: isDark ? 1 : 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. CABECERA
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _showExerciseInfo(exercise),
                                  child: Row(
                                    children: [
                                      // Imagen pequeña (Thumbnail)
                                      Container(
                                        width: 50, height: 50,
                                        margin: const EdgeInsets.only(right: 12),
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey.withOpacity(0.3))
                                        ),
                                        child: Image.asset(
                                          'assets/exercises/${exercise.id}.png',
                                          fit: BoxFit.contain,
                                          errorBuilder: (c,e,s) => const Icon(Icons.fitness_center, color: Colors.grey),
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              exercise.name,
                                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                              maxLines: 2,
                                            ),
                                            if (routineExercise.note.isNotEmpty)
                                              Text("📝 ${routineExercise.note}", style: TextStyle(color: Colors.amber[800], fontSize: 11, fontStyle: FontStyle.italic)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              // Menú
                              PopupMenuButton<String>(
                                icon: Icon(Icons.more_vert, color: theme.iconTheme.color),
                                color: theme.cardColor,
                                onSelected: (value) {
                                  if (value == 'info') _showExerciseInfo(exercise);
                                  if (value == 'swap') _replaceExercise(index);
                                  if (value == 'delete') _removeExerciseFromSession(index);
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'info', child: Text("Ver Detalles")),
                                  const PopupMenuItem(value: 'swap', child: Text("Reemplazar Ejercicio")),
                                  const PopupMenuItem(value: 'delete', child: Text("Eliminar", style: TextStyle(color: Colors.red))),
                                ],
                              )
                            ],
                          ),
                          
                          const SizedBox(height: 10),

                          // 2. TABLA DE SERIES
                          if (sets.isNotEmpty) ...[
                            // Encabezados
                            Row(
                              children: [
                                const SizedBox(width: 30), // Espacio para número
                                const Expanded(child: Text("KG", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                const SizedBox(width: 4),
                                const Expanded(child: Text("REPS", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                const SizedBox(width: 4),
                                const Expanded(child: Text("RPE", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondary))),
                                const SizedBox(width: 40), // Espacio para botón borrar
                              ],
                            ),
                            const SizedBox(height: 5),
                            
                            // Filas
                            ...sets.asMap().entries.map((entry) {
                              int setIdx = entry.key;
                              WorkoutSet set = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Row(
                                  children: [
                                    SizedBox(width: 30, child: Text("${setIdx + 1}", style: const TextStyle(fontWeight: FontWeight.bold))),
                                    // Peso
                                    Expanded(child: _buildCompactInput(controller: _weightControllers[exId]![setIdx], theme: theme, onChanged: (v) { set.weight = double.tryParse(v) ?? 0; _autoSave(); })),
                                    const SizedBox(width: 4),
                                    // Reps
                                    Expanded(child: _buildCompactInput(controller: _repsControllers[exId]![setIdx], theme: theme, onChanged: (v) { set.reps = int.tryParse(v) ?? 0; _autoSave(); })),
                                    const SizedBox(width: 4),
                                    // RPE
                                    Expanded(child: _buildCompactInput(controller: _rpeControllers[exId]![setIdx], theme: theme, isRpe: true, onChanged: (v) { set.rpe = double.tryParse(v) ?? 0; _autoSave(); })),
                                    
                                    IconButton(
                                      icon: const Icon(Icons.close, color: Colors.redAccent, size: 18), 
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.only(left: 10),
                                      onPressed: () => _removeSet(exId, setIdx)
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],

                          // 3. BOTONES DE ACCIÓN
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                onPressed: () => _addSet(exId), 
                                icon: const Icon(Icons.add_circle_outline), 
                                label: const Text("Añadir Serie")
                              ),
                              if (sets.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () => _startRestTimer(sets.last.rpe, exId), 
                                  icon: const Icon(Icons.timer, color: AppColors.secondary), 
                                  label: const Text("Descansar", style: TextStyle(color: AppColors.secondary))
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // --- PANEL DE DESCANSO FLOTANTE ---
            if (_isResting)
              Positioned(
                bottom: 90, left: 20, right: 20,
                child: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFF222222), // Siempre oscuro
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 50, height: 50,
                          child: CircularProgressIndicator(
                            value: _restTimerProgress,
                            backgroundColor: Colors.grey[700],
                            valueColor: AlwaysStoppedAnimation<Color>(_restTimerProgress > 0.9 ? Colors.red : AppColors.secondary),
                            strokeWidth: 5,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Descansando...", style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                              Text("${_suggestedRest - _secondsRest}s", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        TextButton(onPressed: () => _addTime(30), child: const Text("+30s")),
                        IconButton(onPressed: _stopRestTimer, icon: const Icon(Icons.close, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),

            // --- BOTÓN FINALIZAR FLOTANTE ---
            Positioned(
              bottom: 20, left: 20, right: 20,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
                onPressed: _finishWorkout,
                child: const Text("FINALIZAR ENTRENAMIENTO", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInput({required TextEditingController controller, required Function(String) onChanged, required ThemeData theme, bool isRpe = false}) {
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      height: 35,
      decoration: BoxDecoration(
        color: isRpe ? AppColors.secondary.withOpacity(0.1) : (isDark ? Colors.grey[800] : Colors.grey[200]),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isRpe ? AppColors.secondary.withOpacity(0.5) : Colors.transparent
        )
      ),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isRpe ? AppColors.secondary : (isDark ? Colors.white : Colors.black87), 
          fontWeight: isRpe ? FontWeight.bold : FontWeight.normal
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.only(bottom: 12), // Ajuste vertical
        ),
        onChanged: onChanged,
      ),
    );
  }
}