import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/exercise_model.dart';
import '../models/history_model.dart';
import '../models/routine_model.dart'; // Necesario para guardar cambios en la rutina
import '../theme/app_colors.dart';

class WorkoutScreen extends StatefulWidget {
  final String dayName;
  final List<String> exerciseIds;
  final String routineDayId; // Para guardar cambios permanentes si queremos

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
  late List<String> currentExercises; // Lista local editable
  final Map<String, List<WorkoutSet>> _sessionData = {};
  
  // Temporizador
  Timer? _timer;
  int _secondsRest = 0;
  bool _isResting = false;

  @override
  void initState() {
    super.initState();
    exerciseBox = Hive.box<Exercise>('exerciseBox');
    currentExercises = List.from(widget.exerciseIds); // Copia modificable
    
    // Inicializar datos
    for (var id in currentExercises) {
      _sessionData[id] = [];
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // --- LÓGICA DEL TEMPORIZADOR ---
  void _startRestTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRest = 0;
      _isResting = true;
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

  // --- LÓGICA DE EDICIÓN DE RUTINA ---
  void _removeExercise(int index) {
    setState(() {
      _sessionData.remove(currentExercises[index]);
      currentExercises.removeAt(index);
    });
  }

  void _showAddExerciseDialog([int? swapIndex]) {
    // Diálogo simple para elegir ejercicio (se podría mejorar con buscador)
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
                  title: Text(ex.name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(ex.muscleGroup, style: const TextStyle(color: Colors.grey)),
                  trailing: const Icon(Icons.add, color: AppColors.primary),
                  onTap: () {
                    setState(() {
                      if (swapIndex != null) {
                        // Intercambiar
                        _sessionData.remove(currentExercises[swapIndex]); // Borrar datos del viejo
                        currentExercises[swapIndex] = ex.id;
                      } else {
                        // Agregar nuevo al final
                        currentExercises.add(ex.id);
                      }
                      // Inicializar datos del nuevo
                      if (!_sessionData.containsKey(ex.id)) {
                        _sessionData[ex.id] = [];
                      }
                    });
                    Navigator.pop(ctx);
                  },
                );
              },
            );
          }
        );
      },
    );
  }

  void _finishWorkout() async {
    final historyBox = Hive.box<WorkoutSession>('historyBox');
    List<WorkoutExercise> exercisesDone = [];
    
    _sessionData.forEach((exId, sets) {
      if (sets.isNotEmpty) {
        // Verificar que el ejercicio aún exista en la lista actual
        if (currentExercises.contains(exId)) {
           final exDef = exerciseBox.values.firstWhere(
            (e) => e.id == exId, 
            orElse: () => Exercise(id: 'err', name: '?', muscleGroup: '', equipment: '', movementPattern: '')
          );
          exercisesDone.add(WorkoutExercise(
            exerciseId: exId,
            exerciseName: exDef.name,
            sets: sets,
          ));
        }
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Entrenamiento Guardado!')),
      );
      Navigator.pop(context); 
    }
  }

  // --- UI DEL SET ---
  void _addSet(String exerciseId) {
    // Agregar set directamente para agilidad
    setState(() {
      // Copiar el peso/reps del set anterior si existe
      double lastWeight = 0;
      int lastReps = 0;
      if (_sessionData[exerciseId]!.isNotEmpty) {
        lastWeight = _sessionData[exerciseId]!.last.weight;
        lastReps = _sessionData[exerciseId]!.last.reps;
      }

      _sessionData[exerciseId]?.add(WorkoutSet(
        weight: lastWeight, 
        reps: lastReps, 
        rpe: 8
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(), // Arreglo navegación
        ),
        title: Text(widget.dayName),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.secondary),
            onPressed: () => _showAddExerciseDialog(),
            tooltip: "Agregar Ejercicio",
          )
        ],
      ),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.only(bottom: 100), // Espacio para FAB y Timer
            itemCount: currentExercises.length,
            itemBuilder: (context, index) {
              final exId = currentExercises[index];
              final exercise = exerciseBox.values.firstWhere(
                (e) => e.id == exId,
                orElse: () => Exercise(id: 'err', name: 'Ejercicio Eliminado', muscleGroup: '', equipment: '', movementPattern: ''),
              );
              final sets = _sessionData[exId] ?? [];

              return Card(
                color: AppColors.surface,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado Ejercicio con Opciones
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              exercise.name, 
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                            ),
                          ),
                          PopupMenuButton(
                            icon: const Icon(Icons.more_vert, color: Colors.grey),
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(value: 'swap', child: Text('Cambiar Ejercicio')),
                              const PopupMenuItem(value: 'delete', child: Text('Eliminar', style: TextStyle(color: Colors.red))),
                            ],
                            onSelected: (val) {
                              if (val == 'delete') _removeExercise(index);
                              if (val == 'swap') _showAddExerciseDialog(index);
                            },
                          )
                        ],
                      ),
                      
                      // Tabla de Sets
                      if (sets.isNotEmpty)
                        Table(
                          columnWidths: const {
                            0: FlexColumnWidth(1), // Set #
                            1: FlexColumnWidth(2), // KG
                            2: FlexColumnWidth(2), // Reps
                            3: FlexColumnWidth(1), // Check
                          },
                          children: [
                            const TableRow(children: [
                              Text("#", style: TextStyle(color: Colors.grey)),
                              Text("KG", style: TextStyle(color: Colors.grey)),
                              Text("Reps", style: TextStyle(color: Colors.grey)),
                              SizedBox(),
                            ]),
                            ...sets.asMap().entries.map((entry) {
                              int i = entry.key;
                              var s = entry.value;
                              return TableRow(children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Text("${i + 1}", style: const TextStyle(color: Colors.white)),
                                ),
                                // Input Peso
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                  child: TextFormField(
                                    initialValue: s.weight.toString(),
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      isDense: true, contentPadding: EdgeInsets.all(8),
                                      filled: true, fillColor: Colors.black26, border: InputBorder.none
                                    ),
                                    onChanged: (val) => s.weight = double.tryParse(val) ?? 0,
                                  ),
                                ),
                                // Input Reps
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                                  child: TextFormField(
                                    initialValue: s.reps.toString(),
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      isDense: true, contentPadding: EdgeInsets.all(8),
                                      filled: true, fillColor: Colors.black26, border: InputBorder.none
                                    ),
                                    onChanged: (val) => s.reps = int.tryParse(val) ?? 0,
                                  ),
                                ),
                                // Botón Check/Timer
                                IconButton(
                                  icon: const Icon(Icons.check_circle_outline, color: AppColors.primary),
                                  onPressed: () {
                                    // Guardar (ya se guarda al cambiar texto) e iniciar descanso
                                    _startRestTimer();
                                  },
                                )
                              ]);
                            }),
                          ],
                        ),

                      TextButton.icon(
                        onPressed: () => _addSet(exId),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text("Agregar Serie"),
                      )
                    ],
                  ),
                ),
              );
            },
          ),

          // --- TEMPORIZADOR FLOTANTE ---
          if (_isResting)
            Positioned(
              bottom: 80,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.secondary),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer, color: AppColors.secondary),
                    const SizedBox(width: 10),
                    Text("Descanso: ${_formatTime(_secondsRest)}", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: _stopRestTimer,
                    )
                  ],
                ),
              ),
            )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _finishWorkout,
        backgroundColor: AppColors.secondary,
        label: const Text("TERMINAR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.flag, color: Colors.black),
      ),
    );
  }
}