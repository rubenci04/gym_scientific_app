import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/routine_model.dart';
import '../models/exercise_model.dart';
import '../theme/app_colors.dart';
import '../services/routine_repository.dart'; // Importante para guardar nuevas rutinas
import 'exercise_selection_screen.dart';

class RoutineEditorScreen extends StatefulWidget {
  final WeeklyRoutine routine;

  const RoutineEditorScreen({super.key, required this.routine});

  @override
  State<RoutineEditorScreen> createState() => _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends State<RoutineEditorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late WeeklyRoutine _editableRoutine;
  
  // Lista temporal para edición
  List<RoutineDay> _days = [];

  @override
  void initState() {
    super.initState();
    _editableRoutine = widget.routine;
    _days = List.from(_editableRoutine.days);
    _tabController = TabController(length: _days.length > 0 ? _days.length : 1, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    // Actualizamos la rutina con los días editados
    _editableRoutine.days = _days;

    // Lógica inteligente de guardado:
    // Si ya existe en la BD (tiene clave), la actualizamos.
    // Si es nueva (no está en caja), la agregamos.
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
          reps: '10-12', // Corregido: Ahora es String
          restTimeSeconds: 90, // Corregido: Nombre correcto del parámetro
        );
        
        _days[dayIndex].exercises.add(newRoutineExercise);
      });
    }
  }

  void _removeExercise(int dayIndex, int exerciseIndex) {
    setState(() {
      _days[dayIndex].exercises.removeAt(exerciseIndex);
    });
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

  String _getExerciseName(String id) {
    final box = Hive.box<Exercise>('exerciseBox');
    // Intentamos buscar por ID directo o iterando
    final exercise = box.get(id); 
    if (exercise != null) return exercise.name;
    
    try {
      return box.values.firstWhere((e) => e.id == id).name;
    } catch (e) {
      return 'Ejercicio ($id)';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si no hay días (rutina nueva vacía), mostramos mensaje o un tab por defecto
    if (_days.isEmpty) {
        return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(title: const Text("Editar Rutina"), backgroundColor: AppColors.surface),
            body: const Center(child: Text("La rutina no tiene días configurados.", style: TextStyle(color: Colors.white)))
        );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_editableRoutine.name.isEmpty ? 'Nueva Rutina' : _editableRoutine.name),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
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
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onPressed: () => _addExercise(dayIndex),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Agregar"),
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
                          final exercise = day.exercises[index];
                          final exerciseName = _getExerciseName(exercise.exerciseId);

                          return Card(
                            key: ValueKey(exercise),
                            color: AppColors.surface,
                            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            child: ListTile(
                              leading: const Icon(Icons.drag_handle, color: Colors.grey),
                              title: Text(exerciseName, style: const TextStyle(color: Colors.white)),
                              subtitle: Text(
                                "${exercise.sets} Series x ${exercise.reps} Reps",
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => _removeExercise(dayIndex, index),
                              ),
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