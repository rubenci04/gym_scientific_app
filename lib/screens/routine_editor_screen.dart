import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/routine_model.dart';
import '../models/exercise_model.dart';
import '../services/routine_repository.dart';
import '../theme/app_colors.dart';

class RoutineEditorScreen extends StatefulWidget {
  final WeeklyRoutine routine;

  const RoutineEditorScreen({super.key, required this.routine});

  @override
  State<RoutineEditorScreen> createState() => _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends State<RoutineEditorScreen> {
  late TextEditingController _nameController;
  late WeeklyRoutine _editableRoutine;

  @override
  void initState() {
    super.initState();
    _editableRoutine = widget.routine;
    _nameController = TextEditingController(text: _editableRoutine.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveRoutine() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ponle un nombre a la rutina")),
      );
      return;
    }

    _editableRoutine.name = _nameController.text;
    await RoutineRepository.saveRoutine(_editableRoutine);

    if (mounted) {
      Navigator.pop(context); // Volver a Mis Rutinas
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Rutina guardada correctamente")),
      );
    }
  }

  void _addDay() {
    setState(() {
      final newDay = RoutineDay(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: 'Día ${_editableRoutine.days.length + 1}',
        targetMuscles: [], // ✅ CORREGIDO: Parámetro agregado
        exercises: [],
      );
      _editableRoutine.days.add(newDay);
    });
  }

  void _removeDay(int index) {
    setState(() {
      _editableRoutine.days.removeAt(index);
    });
  }

  void _updateDayName(int index, String newName) {
    setState(() {
      _editableRoutine.days[index].name = newName;
    });
  }

  void _removeExercise(int dayIndex, int exerciseIndex) {
    setState(() {
      _editableRoutine.days[dayIndex].exercises.removeAt(exerciseIndex);
    });
  }

  // --- SELECTOR DE EJERCICIOS (Mini Librería) ---
  void _showExercisePicker(int dayIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => _ExercisePickerSheet(
          scrollController: controller,
          onExerciseSelected: (Exercise selectedExercise) {
            setState(() {
              // Convertimos el Ejercicio de la Librería a un Ejercicio de Rutina
              final routineExercise = RoutineExercise(
                exerciseId: selectedExercise.id, // ✅ CORREGIDO: Cambió de 'id' a 'exerciseId'
                sets: 3, // ✅ CORREGIDO: Cambió de 'targetSets' a 'sets'
                reps: "10-12", // ✅ CORREGIDO: Cambió de 'targetReps' a 'reps'
                rpe: "8", // ✅ CORREGIDO: Cambió de 'targetRPE' (int) a 'rpe' (String?)
                restTimeSeconds: 90, // ✅ CORREGIDO: Cambió de 'restSeconds' a 'restTimeSeconds'
                note: "", // ✅ Mantenido
              );
              _editableRoutine.days[dayIndex].exercises.add(routineExercise);
              
              // Actualizamos los músculos objetivo del día automáticamente
              if (!_editableRoutine.days[dayIndex].targetMuscles.contains(selectedExercise.muscleGroup)) {
                 _editableRoutine.days[dayIndex].targetMuscles.add(selectedExercise.muscleGroup);
              }
            });
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text("Editar Rutina"),
        actions: [
          IconButton(
            onPressed: _saveRoutine,
            icon: const Icon(Icons.save, color: AppColors.primary),
          )
        ],
      ),
      body: Column(
        children: [
          // --- HEADER: NOMBRE ---
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.surface,
            child: TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: const InputDecoration(
                labelText: "Nombre de la Rutina",
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
          ),
          
          // --- LISTA DE DÍAS ---
          Expanded(
            child: _editableRoutine.days.isEmpty
                ? _buildEmptyDaysState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _editableRoutine.days.length,
                    itemBuilder: (context, index) {
                      return _buildDayCard(index);
                    },
                  ),
          ),
          
          // --- BOTÓN AGREGAR DÍA ---
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: _addDay,
              icon: const Icon(Icons.calendar_today),
              label: const Text("AGREGAR DÍA DE ENTRENAMIENTO"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDaysState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.calendar_view_week, size: 60, color: Colors.white24),
          SizedBox(height: 10),
          Text("No hay días configurados", style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildDayCard(int index) {
    final day = _editableRoutine.days[index];
    final nameCtrl = TextEditingController(text: day.name);

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          // CABECERA DEL DÍA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Nombre del día (ej: Pierna)",
                      hintStyle: TextStyle(color: Colors.white24),
                    ),
                    onSubmitted: (val) => _updateDayName(index, val),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  onPressed: () => _removeDay(index),
                ),
              ],
            ),
          ),

          // LISTA DE EJERCICIOS DEL DÍA
          if (day.exercises.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextButton.icon(
                onPressed: () => _showExercisePicker(index),
                icon: const Icon(Icons.add_circle_outline, color: Colors.white54),
                label: const Text("Agregar primer ejercicio", style: TextStyle(color: Colors.white54)),
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: day.exercises.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = day.exercises.removeAt(oldIndex);
                  day.exercises.insert(newIndex, item);
                });
              },
              itemBuilder: (context, exIndex) {
                final exercise = day.exercises[exIndex];
                // ✅ CORREGIDO: Cambió exercise.id a exercise.exerciseId
                final originalExercise = Hive.box<Exercise>('exerciseBox').get(exercise.exerciseId);
                
                ImageProvider? img;
                if (originalExercise != null) {
                   if (originalExercise.localImagePath != null) {
                      if (kIsWeb) {
                        img = NetworkImage(originalExercise.localImagePath!);
                      } else {
                        final f = File(originalExercise.localImagePath!);
                        if (f.existsSync()) img = FileImage(f);
                      }
                   }
                   if (img == null) {
                      img = AssetImage('assets/exercises/${originalExercise.id}.png');
                   }
                }

                // ✅ CORREGIDO: Obtenemos el nombre desde la base de datos
                final exerciseName = originalExercise?.name ?? 'Ejercicio Desconocido';

                return ListTile(
                  key: ValueKey(exercise), // Necesario para reorderable
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(5),
                      image: img != null ? DecorationImage(image: img, fit: BoxFit.cover) : null,
                    ),
                    child: img == null ? const Icon(Icons.fitness_center, size: 20, color: Colors.white24) : null,
                  ),
                  title: Text(exerciseName, style: const TextStyle(color: Colors.white)), // ✅ CORREGIDO
                  subtitle: Text("${exercise.sets} series x ${exercise.reps}", style: const TextStyle(color: Colors.grey, fontSize: 12)), // ✅ CORREGIDO
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.drag_handle, color: Colors.white24),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Colors.redAccent),
                        onPressed: () => _removeExercise(index, exIndex),
                      )
                    ],
                  ),
                );
              },
            ),

          if (day.exercises.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextButton.icon(
                onPressed: () => _showExercisePicker(index),
                icon: const Icon(Icons.add, size: 16),
                label: const Text("Agregar Ejercicio"),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}

// --- WIDGET HELPER: SELECTOR DE EJERCICIOS ---
// Este widget encapsula la lógica de búsqueda y visualización para no ensuciar el editor
class _ExercisePickerSheet extends StatefulWidget {
  final ScrollController scrollController;
  final Function(Exercise) onExerciseSelected;

  const _ExercisePickerSheet({required this.scrollController, required this.onExerciseSelected});

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  String _query = "";
  String? _filterMuscle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Barra superior
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: "Buscar ejercicio...",
                      hintStyle: TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => setState(() => _query = val),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          const Divider(color: Colors.white10),
          
          // Lista de ejercicios
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<Exercise>('exerciseBox').listenable(),
              builder: (context, Box<Exercise> box, _) {
                var exercises = box.values.toList();
                
                // Filtros
                if (_query.isNotEmpty) {
                  exercises = exercises.where((e) => 
                    e.name.toLowerCase().contains(_query.toLowerCase()) || 
                    e.muscleGroup.toLowerCase().contains(_query.toLowerCase())
                  ).toList();
                }

                // Ordenar: Custom primero
                exercises.sort((a, b) {
                   final aC = a.id.startsWith('custom_');
                   final bC = b.id.startsWith('custom_');
                   if (aC && !bC) return -1;
                   if (!aC && bC) return 1;
                   return a.name.compareTo(b.name);
                });

                return ListView.builder(
                  controller: widget.scrollController,
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final ex = exercises[index];
                    
                    // Imagen pequeña
                    ImageProvider? img;
                    if (ex.localImagePath != null && ex.localImagePath!.isNotEmpty) {
                      if (kIsWeb) {
                        img = NetworkImage(ex.localImagePath!);
                      } else {
                        final f = File(ex.localImagePath!);
                        if (f.existsSync()) img = FileImage(f);
                      }
                    }
                    if (img == null) img = AssetImage('assets/exercises/${ex.id}.png');

                    return ListTile(
                      leading: Container(
                        width: 50, height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(image: img!, fit: BoxFit.cover, onError: (e,s){}),
                        ),
                      ),
                      title: Text(ex.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text(ex.muscleGroup, style: const TextStyle(color: Colors.grey)),
                      trailing: const Icon(Icons.add_circle, color: AppColors.primary),
                      onTap: () => widget.onExerciseSelected(ex),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}