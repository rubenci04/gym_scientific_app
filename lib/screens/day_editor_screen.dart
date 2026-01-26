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

  // --- FUNCIÓN MEJORADA: AGREGAR O REEMPLAZAR EJERCICIO ---
  // Acepta un ejercicio "original" opcional para activar el modo de reemplazo inteligente.
  void _addOrReplaceExercise({int? replaceIndex}) async {
    String? substitutionGroup;
    
    // Si estamos reemplazando, buscamos el grupo del ejercicio original
    if (replaceIndex != null) {
      final originalId = _exercises[replaceIndex].exerciseId;
      final originalExercise = _exerciseBox.get(originalId);
      substitutionGroup = originalExercise?.substitutionGroup;
    }

    // Show dialog to choose search or body map
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          replaceIndex == null ? 'Agregar Ejercicio' : 'Reemplazar Ejercicio',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.search, color: AppColors.primary),
              title: const Text(
                'Buscar en biblioteca',
                style: TextStyle(color: Colors.white),
              ),
              subtitle: replaceIndex != null 
                  ? const Text("Ver sugerencias inteligentes", style: TextStyle(color: Colors.greenAccent, fontSize: 12))
                  : null,
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

    if (choice == null) return;

    Exercise? selected;
    if (choice == 'search') {
      selected = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExerciseSelectionScreen(
            // PASAMOS EL GRUPO PARA FILTRADO INTELIGENTE
            originalSubstitutionGroup: substitutionGroup,
          ),
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
        if (replaceIndex != null) {
          // Mantener series/reps del ejercicio anterior, solo cambiar ID
          final old = _exercises[replaceIndex];
          _exercises[replaceIndex] = RoutineExercise(
            exerciseId: selected!.id,
            sets: old.sets,
            reps: old.reps,
            rpe: old.rpe,
            restTimeSeconds: old.restTimeSeconds,
            note: old.note, // Mantener notas si las hubiera
          );
        } else {
          // Agregar nuevo con valores por defecto
          _exercises.add(
            RoutineExercise(
              exerciseId: selected!.id,
              sets: 3,
              reps: "8-12",
              rpe: "8",
              restTimeSeconds: 90,
            ),
          );
        }
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
          'Editar Variables',
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
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: repsController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Reps',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
            TextField(
              controller: rpeController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'RPE (Esfuerzo 1-10)',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
            TextField(
              controller: restController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Descanso (seg)',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
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
            child: const Text('Guardar', style: TextStyle(color: AppColors.primary)),
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
      body: Column(
        children: [
          // Banner informativo si hay notas especiales
          if (widget.day.exercises.any((e) => e.note != null && e.note!.contains("LADO DÉBIL")))
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.amber.withOpacity(0.2),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Protocolo Simetría Activo: Revisa las notas.",
                      style: TextStyle(color: Colors.amber, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          Expanded(
            child: ReorderableListView.builder(
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
                final hasNote = routineEx.note != null && routineEx.note!.isNotEmpty;

                return Card(
                  key: ValueKey(routineEx.hashCode), 
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    children: [
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              '${routineEx.sets} x ${routineEx.reps} @ RPE ${routineEx.rpe ?? "-"}',
                              style: const TextStyle(color: AppColors.textSecondary),
                            ),
                            if (hasNote) ...[
                              const SizedBox(height: 4),
                              Text(
                                "📝 ${routineEx.note}",
                                style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontStyle: FontStyle.italic),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ]
                          ],
                        ),
                        // Al tocar el cuerpo, permitimos reemplazar el ejercicio
                        onTap: () => _addOrReplaceExercise(replaceIndex: index),
                        trailing: const Icon(Icons.swap_horiz, color: Colors.white24),
                      ),
                      
                      // Botones de acción inferiores
                      Divider(color: Colors.white.withOpacity(0.1), height: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                            label: const Text("Editar", style: TextStyle(color: Colors.blue)),
                            onPressed: () => _editExercise(index),
                          ),
                          Container(width: 1, height: 20, color: Colors.white10),
                          TextButton.icon(
                            icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                            label: const Text("Borrar", style: TextStyle(color: Colors.red)),
                            onPressed: () => _removeExercise(index),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrReplaceExercise(), // Agregar nuevo (sin index)
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}