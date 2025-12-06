import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/routine_model.dart';
import '../models/exercise_model.dart';
import '../theme/app_colors.dart';
import 'exercise_selection_screen.dart';
import 'muscle_selector_screen.dart';

class DayEditorScreen extends StatefulWidget {
  final RoutineDay day;

  const DayEditorScreen({super.key, required this.day});

  @override
  State<DayEditorScreen> createState() => _DayEditorScreenState();
}

class _DayEditorScreenState extends State<DayEditorScreen> {
  late List<RoutineExercise> _exercises;
  late Box<Exercise> _exerciseBox;

  @override
  void initState() {
    super.initState();
    _exercises = widget.day.exercises;
    _exerciseBox = Hive.box<Exercise>('exerciseBox');
  }

  void _addExercise() async {
    // Show dialog to choose search or body map
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Agregar Ejercicio',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.search, color: AppColors.primary),
              title: const Text(
                'Buscar por nombre',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(context, 'search'),
            ),
            ListTile(
              leading: const Icon(
                Icons.accessibility_new,
                color: AppColors.primary,
              ),
              title: const Text(
                'Seleccionar por músculo',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(context, 'body'),
            ),
          ],
        ),
      ),
    );

    Exercise? selected;
    if (choice == 'search') {
      selected = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ExerciseSelectionScreen(),
        ),
      );
    } else if (choice == 'body') {
      selected = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MuscleSelectorScreen()),
      );
    }

    if (selected != null) {
      setState(() {
        _exercises.add(
          RoutineExercise(
            exerciseId: selected!.id,
            sets: 3,
            reps: "8-12",
            rpe: "8",
            restTimeSeconds: 90,
          ),
        );
      });
    }
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
  }

  void _editExercise(int index) {
    final ex = _exercises[index];
    final setsController = TextEditingController(text: ex.sets.toString());
    final repsController = TextEditingController(text: ex.reps);
    final rpeController = TextEditingController(text: ex.rpe ?? "");
    final restController = TextEditingController(
      text: ex.restTimeSeconds?.toString() ?? "",
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Editar Ejercicio',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: setsController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Series',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: repsController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Reps',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextField(
              controller: rpeController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'RPE (Opcional)',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            TextField(
              controller: restController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Descanso (seg)',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                ex.sets = int.tryParse(setsController.text) ?? 3;
                ex.reps = repsController.text;
                ex.rpe = rpeController.text;
                ex.restTimeSeconds = int.tryParse(restController.text);
              });
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  String _getExerciseName(String id) {
    final ex = _exerciseBox.values.firstWhere(
      (e) => e.id == id,
      orElse: () => Exercise(
        id: id,
        name: 'Desconocido',
        muscleGroup: '',
        equipment: '',
        movementPattern: '',
      ),
    );
    return ex.name;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.day.name),
        backgroundColor: AppColors.surface,
      ),
      body: ReorderableListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _exercises.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final item = _exercises.removeAt(oldIndex);
            _exercises.insert(newIndex, item);
          });
        },
        itemBuilder: (context, index) {
          final routineEx = _exercises[index];
          return Card(
            key: ValueKey(
              routineEx.hashCode,
            ), // Use hashCode as key since ID might not be unique if same exercise added twice
            color: AppColors.surface,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(
                Icons.fitness_center,
                color: AppColors.primary,
              ),
              title: Text(
                _getExerciseName(routineEx.exerciseId),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${routineEx.sets} x ${routineEx.reps} @ RPE ${routineEx.rpe ?? "-"}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editExercise(index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeExercise(index),
                  ),
                  const Icon(Icons.drag_handle, color: Colors.white54),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExercise,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
