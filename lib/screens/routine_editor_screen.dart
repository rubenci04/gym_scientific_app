import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/routine_model.dart';
import '../models/exercise_model.dart';
import '../theme/app_colors.dart';
import '../services/routine_repository.dart';
import 'exercise_selection_screen.dart';

class RoutineEditorScreen extends StatefulWidget {
  final WeeklyRoutine routine;

  const RoutineEditorScreen({super.key, required this.routine});

  @override
  State<RoutineEditorScreen> createState() => _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends State<RoutineEditorScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late WeeklyRoutine _editableRoutine;
  
  // Lista temporal para edición
  List<RoutineDay> _days = [];

  @override
  void initState() {
    super.initState();
    _editableRoutine = widget.routine;
    _days = List.from(_editableRoutine.days);

    // NOTA PARA MÍ: Si es una rutina nueva (lista vacía), inicializo el Día 1
    // para evitar la pantalla en blanco.
    if (_days.isEmpty) {
      _days.add(RoutineDay(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Día 1',
        exercises: [],
        targetMuscles: [],
      ));
    }

    _initTabController();
  }

  void _initTabController() {
    _tabController = TabController(length: _days.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Nota para mí: Función para agregar un nuevo día de entrenamiento (ej: Día 2, Día 3)
  void _addNewDay() {
    setState(() {
      _days.add(RoutineDay(
        id: "${DateTime.now().millisecondsSinceEpoch}_${_days.length}",
        name: 'Día ${_days.length + 1}',
        exercises: [],
        targetMuscles: [],
      ));
      
      // Recreamos el controlador para reflejar la nueva pestaña
      _tabController.dispose();
      _initTabController();
      _tabController.animateTo(_days.length - 1); // Ir al nuevo día
    });
  }

  // Eliminar un día entero (si te equivocaste)
  void _removeDay(int index) {
    if (_days.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("La rutina debe tener al menos un día.")));
      return;
    }
    
    setState(() {
      _days.removeAt(index);
      _tabController.dispose();
      _initTabController();
    });
  }

  void _saveChanges() async {
    _editableRoutine.days = _days;

    if (_editableRoutine.isInBox) {
      _editableRoutine.save();
    } else {
      await RoutineRepository.addRoutine(_editableRoutine);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rutina guardada correctamente')),
      );
      Navigator.pop(context);
    }
  }

  void _addExercise(int dayIndex) async {
    final Exercise? selectedExercise = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExerciseSelectionScreen()),
    );

    if (selectedExercise != null) {
      setState(() {
        final newRoutineExercise = RoutineExercise(
          exerciseId: selectedExercise.id,
          sets: 3,
          reps: '10-12',
          restTimeSeconds: 90,
        );
        
        _days[dayIndex].exercises.add(newRoutineExercise);
      });
    }
  }

  // Nota para mí: Nueva función para reemplazar ejercicio
  void _replaceExercise(int dayIndex, int exerciseIndex) async {
    final Exercise? selectedExercise = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExerciseSelectionScreen()),
    );

    if (selectedExercise != null) {
      setState(() {
        // Mantenemos las series/reps del ejercicio anterior, cambiamos solo el ID
        _days[dayIndex].exercises[exerciseIndex].exerciseId = selectedExercise.id;
      });
    }
  }

  void _removeExercise(int dayIndex, int exerciseIndex) {
    setState(() {
      _days[dayIndex].exercises.removeAt(exerciseIndex);
    });
  }

  void _editSetsReps(int dayIndex, int exerciseIndex) {
    final exercise = _days[dayIndex].exercises[exerciseIndex];
    final setsCtrl = TextEditingController(text: exercise.sets.toString());
    final repsCtrl = TextEditingController(text: exercise.reps);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Editar Series y Reps", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: setsCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Series", labelStyle: TextStyle(color: Colors.white70)),
            ),
            TextField(
              controller: repsCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Repeticiones (ej: 10-12)", labelStyle: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              setState(() {
                exercise.sets = int.tryParse(setsCtrl.text) ?? 3;
                exercise.reps = repsCtrl.text;
              });
              Navigator.pop(ctx);
            },
            child: const Text("Guardar", style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _reorderExercises(int dayIndex, int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final RoutineExercise item = _days[dayIndex].exercises.removeAt(oldIndex);
      _days[dayIndex].exercises.insert(newIndex, item);
    });
  }

  // Helper para obtener nombre e imagen del ejercicio
  Exercise? _getExercise(String id) {
    final box = Hive.box<Exercise>('exerciseBox');
    return box.get(id) ?? 
           (box.values.any((e) => e.id == id) ? box.values.firstWhere((e) => e.id == id) : null);
  }

  // Diálogo de info del ejercicio
  void _showExerciseInfo(Exercise exercise) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(exercise.name, style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              color: Colors.white,
              child: Image.asset('assets/exercises/${exercise.id}.png', height: 100, fit: BoxFit.contain, errorBuilder: (c,e,s)=>const Icon(Icons.image)),
            ),
            const SizedBox(height: 10),
            Text(exercise.description, style: const TextStyle(color: Colors.white70), maxLines: 4, overflow: TextOverflow.ellipsis),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cerrar")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Nota para mí: Ya no debería entrar aquí gracias al fix del initState, pero lo dejo por seguridad.
    if (_days.isEmpty) {
        return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text("Editar Rutina"), backgroundColor: AppColors.surface),
            body: const Center(child: Text("Cargando...", style: TextStyle(color: Colors.white)))
        );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_editableRoutine.name.isEmpty ? 'Nueva Rutina' : _editableRoutine.name),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          // Botón para agregar más días (Splits)
          TextButton.icon(
            onPressed: _addNewDay, 
            icon: const Icon(Icons.add, color: AppColors.primary, size: 18),
            label: const Text("Día", style: TextStyle(color: AppColors.primary)),
          ),
          IconButton(
            icon: const Icon(Icons.save, color: AppColors.secondary),
            onPressed: _saveChanges,
            tooltip: "Guardar Cambios",
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.primary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: _days.map((day) => Tab(text: day.name)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _days.asMap().entries.map((entry) {
          final int dayIndex = entry.key;
          final RoutineDay day = entry.value;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: AppColors.surface,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Ejercicios (${day.exercises.length})",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        if (_days.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete_forever, color: Colors.red, size: 20),
                            onPressed: () => _removeDay(dayIndex),
                            tooltip: "Borrar este día",
                          ),
                        const SizedBox(width: 10),
                        // NOTA PARA MÍ: Botón AGREGAR corregido (Texto visible)
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white, // COLOR DE TEXTO BLANCO
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: () => _addExercise(dayIndex),
                          icon: const Icon(Icons.add, size: 18, color: Colors.white),
                          label: const Text("Agregar Ejercicio"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: day.exercises.isEmpty
                    ? const Center(
                        child: Text(
                          "No hay ejercicios en este día.\n¡Agrega uno para empezar!",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: day.exercises.length,
                        onReorder: (oldIndex, newIndex) => _reorderExercises(dayIndex, oldIndex, newIndex),
                        itemBuilder: (context, index) {
                          final routineExercise = day.exercises[index];
                          final exerciseData = _getExercise(routineExercise.exerciseId);
                          final imagePath = 'assets/exercises/${routineExercise.exerciseId}.png';

                          return Card(
                            key: ValueKey(routineExercise),
                            color: AppColors.surface,
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              // Nota para mí: Imagen visible en la lista
                              leading: Container(
                                width: 50, height: 50,
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white, 
                                  borderRadius: BorderRadius.circular(8)
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.asset(
                                    imagePath,
                                    fit: BoxFit.contain,
                                    errorBuilder: (c,e,s) => Center(child: Text(exerciseData?.name[0] ?? "E", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))),
                                  ),
                                ),
                              ),
                              title: Text(
                                exerciseData?.name ?? routineExercise.exerciseId,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                "${routineExercise.sets} Series x ${routineExercise.reps}",
                                style: const TextStyle(color: AppColors.textSecondary),
                              ),
                              // NOTA PARA MÍ: Aquí están los botones solicitados (Menú)
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Drag handle (Mover)
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: const Icon(Icons.drag_handle, color: Colors.grey),
                                  ),
                                  // Menú de opciones
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, color: Colors.white70),
                                    color: AppColors.surface,
                                    onSelected: (value) {
                                      if (value == 'edit') _editSetsReps(dayIndex, index);
                                      if (value == 'swap') _replaceExercise(dayIndex, index);
                                      if (value == 'info' && exerciseData != null) _showExerciseInfo(exerciseData);
                                      if (value == 'delete') _removeExercise(dayIndex, index);
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text("Editar Series/Reps")])),
                                      const PopupMenuItem(value: 'swap', child: Row(children: [Icon(Icons.swap_horiz, size: 18), SizedBox(width: 8), Text("Cambiar Ejercicio")])),
                                      const PopupMenuItem(value: 'info', child: Row(children: [Icon(Icons.info_outline, size: 18), SizedBox(width: 8), Text("Ver Detalles")])),
                                      const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text("Eliminar", style: TextStyle(color: Colors.red))])),
                                    ],
                                  ),
                                ],
                              ),
                              onTap: () => _editSetsReps(dayIndex, index),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}