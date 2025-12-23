import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart'; // NECESARIO PARA FOTOS
import 'package:path_provider/path_provider.dart'; // NECESARIO PARA GUARDAR
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
  bool _isNewRoutine = false;

  @override
  void initState() {
    super.initState();
    _editableRoutine = widget.routine;
    _nameController = TextEditingController(text: _editableRoutine.name);
    
    final box = Hive.box<WeeklyRoutine>('routineBox');
    _isNewRoutine = !box.containsKey(_editableRoutine.id);
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

    if (_isNewRoutine) {
      await RoutineRepository.addRoutine(_editableRoutine);
    } else {
      await RoutineRepository.saveRoutine(_editableRoutine);
    }

    if (mounted) {
      Navigator.pop(context);
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
        targetMuscles: [],
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
              final routineExercise = RoutineExercise(
                exerciseId: selectedExercise.id,
                sets: 3,
                reps: "10-12",
                rpe: "8",
                restTimeSeconds: 90,
                note: "",
              );
              _editableRoutine.days[dayIndex].exercises.add(routineExercise);
              
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
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        title: Text("Editar Rutina", style: theme.appBarTheme.titleTextStyle),
        iconTheme: theme.iconTheme,
        actions: [
          IconButton(
            onPressed: _saveRoutine,
            icon: const Icon(Icons.save, color: AppColors.primary),
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            color: theme.cardColor,
            child: TextField(
              controller: _nameController,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                labelText: "Nombre de la Rutina",
                labelStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.dividerColor)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
              ),
            ),
          ),
          
          Expanded(
            child: _editableRoutine.days.isEmpty
                ? _buildEmptyDaysState(theme)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _editableRoutine.days.length,
                    itemBuilder: (context, index) {
                      return _buildDayCard(index, theme);
                    },
                  ),
          ),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: theme.cardColor,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.cardColor,
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 15),
                elevation: 0,
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

  Widget _buildEmptyDaysState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_view_week, size: 60, color: theme.disabledColor),
          const SizedBox(height: 10),
          Text("No hay días configurados", style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5))),
        ],
      ),
    );
  }

  Widget _buildDayCard(int index, ThemeData theme) {
    final day = _editableRoutine.days[index];
    final nameCtrl = TextEditingController(text: day.name);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      color: theme.cardColor,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: isDark ? 1 : 2,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Nombre del día (ej: Pierna)",
                      hintStyle: TextStyle(color: theme.disabledColor),
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

          if (day.exercises.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: TextButton.icon(
                onPressed: () => _showExercisePicker(index),
                icon: Icon(Icons.add_circle_outline, color: theme.disabledColor),
                label: Text("Agregar primer ejercicio", style: TextStyle(color: theme.disabledColor)),
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

                final exerciseName = originalExercise?.name ?? 'Ejercicio Desconocido';

                return ListTile(
                  key: ValueKey(exercise),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.black26 : Colors.grey[200],
                      borderRadius: BorderRadius.circular(5),
                      image: img != null ? DecorationImage(image: img, fit: BoxFit.cover) : null,
                    ),
                    child: img == null ? Icon(Icons.fitness_center, size: 20, color: theme.disabledColor) : null,
                  ),
                  title: Text(exerciseName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                  subtitle: Text("${exercise.sets} series x ${exercise.reps}", style: theme.textTheme.bodySmall),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.drag_handle, color: theme.disabledColor),
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

class _ExercisePickerSheet extends StatefulWidget {
  final ScrollController scrollController;
  final Function(Exercise) onExerciseSelected;

  const _ExercisePickerSheet({required this.scrollController, required this.onExerciseSelected});

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  String _query = "";

  // --- NUEVA FUNCIONALIDAD: CREAR EJERCICIO ---
  Future<void> _showCreateExerciseDialog() async {
    final nameCtrl = TextEditingController();
    String selectedMuscle = 'Pecho';
    String selectedEquipment = 'Mancuernas';
    String? localImagePath;

    final muscles = ['Pecho', 'Espalda', 'Hombros', 'Bíceps', 'Tríceps', 'Cuádriceps', 'Isquios', 'Glúteos', 'Gemelos', 'Abdominales', 'Cardio', 'Trapecio', 'Antebrazo', 'Aductores', 'Otro'];
    final equipments = ['Corporal', 'Mancuernas', 'Barra', 'Máquina', 'Polea', 'Banda', 'Kettlebell', 'Disco', 'Otro'];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final theme = Theme.of(context);
          return AlertDialog(
            backgroundColor: theme.cardColor,
            title: Text("Crear Nuevo Ejercicio", style: theme.textTheme.titleLarge),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      try {
                        final picker = ImagePicker();
                        final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
                        if (image != null) {
                          if (!kIsWeb) {
                            final directory = await getApplicationDocumentsDirectory();
                            final fileName = 'custom_${DateTime.now().millisecondsSinceEpoch}.jpg';
                            final savedImage = await File(image.path).copy('${directory.path}/$fileName');
                            setStateDialog(() => localImagePath = savedImage.path);
                          }
                        }
                      } catch (e) {
                        debugPrint("Error imagen: $e");
                      }
                    },
                    child: Container(
                      height: 120, width: 120,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(10),
                        image: localImagePath != null ? DecorationImage(image: FileImage(File(localImagePath!)), fit: BoxFit.cover) : null
                      ),
                      child: localImagePath == null ? const Icon(Icons.add_a_photo, color: AppColors.primary, size: 40) : null,
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: nameCtrl,
                    style: theme.textTheme.bodyLarge,
                    decoration: const InputDecoration(labelText: "Nombre", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedMuscle,
                    items: muscles.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setStateDialog(() => selectedMuscle = v!),
                    decoration: const InputDecoration(labelText: "Músculo"),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedEquipment,
                    items: equipments.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setStateDialog(() => selectedEquipment = v!),
                    decoration: const InputDecoration(labelText: "Equipo"),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.isEmpty) return;
                  final newEx = Exercise(
                    id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text,
                    muscleGroup: selectedMuscle,
                    equipment: selectedEquipment,
                    movementPattern: 'Personalizado',
                    difficulty: 'General',
                    description: '',
                    targetMuscles: [selectedMuscle],
                    localImagePath: localImagePath,
                  );
                  Hive.box<Exercise>('exerciseBox').put(newEx.id, newEx);
                  Navigator.pop(ctx);
                  // Seleccionamos automáticamente el ejercicio creado
                  widget.onExerciseSelected(newEx);
                },
                child: const Text("Crear y Añadir"),
              )
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: "Buscar o crear...",
                      hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) => setState(() => _query = val),
                  ),
                ),
                // --- BOTÓN DE CREAR NUEVO ---
                IconButton(
                  icon: const Icon(Icons.add, color: AppColors.primary),
                  tooltip: "Crear nuevo ejercicio",
                  onPressed: _showCreateExerciseDialog,
                ),
                IconButton(
                  icon: Icon(Icons.close, color: theme.iconTheme.color),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          Divider(color: theme.dividerColor),
          
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<Exercise>('exerciseBox').listenable(),
              builder: (context, Box<Exercise> box, _) {
                var exercises = box.values.toList();
                
                if (_query.isNotEmpty) {
                  exercises = exercises.where((e) => 
                    e.name.toLowerCase().contains(_query.toLowerCase()) || 
                    e.muscleGroup.toLowerCase().contains(_query.toLowerCase())
                  ).toList();
                }

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
                          color: isDark ? Colors.white10 : Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(image: img!, fit: BoxFit.cover, onError: (e,s){}),
                        ),
                      ),
                      title: Text(ex.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Text(ex.muscleGroup, style: theme.textTheme.bodySmall),
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