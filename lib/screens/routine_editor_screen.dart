import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/routine_model.dart';
import '../models/exercise_model.dart';
import '../theme/app_colors.dart';
import '../services/routine_repository.dart';
import 'day_editor_screen.dart';

class RoutineEditorScreen extends StatefulWidget {
  final WeeklyRoutine? routine; // Null if creating new

  const RoutineEditorScreen({super.key, this.routine});

  @override
  State<RoutineEditorScreen> createState() => _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends State<RoutineEditorScreen> {
  late TextEditingController _nameController;
  late List<RoutineDay> _days;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.routine?.name ?? 'Nueva Rutina',
    );
    _days = widget.routine?.days.toList() ?? [];
    if (_days.isEmpty) {
      _addDay();
    }
  }

  void _addDay() {
    setState(() {
      _days.add(
        RoutineDay(
          id: 'day_${DateTime.now().millisecondsSinceEpoch}',
          name: 'Día ${_days.length + 1}',
          targetMuscles: [],
          exercises: [],
        ),
      );
    });
  }

  void _removeDay(int index) {
    setState(() {
      _days.removeAt(index);
    });
  }

  Future<void> _saveRoutine() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un nombre para la rutina'),
        ),
      );
      return;
    }

    final newRoutine = WeeklyRoutine(
      id:
          widget.routine?.id ??
          'routine_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text,
      days: _days,
      createdAt: widget.routine?.createdAt ?? DateTime.now(),
      isActive: widget.routine?.isActive ?? false,
    );

    await RoutineRepository.saveRoutine(newRoutine);

    // If the routine is set to active, ensure it's the only one
    if (newRoutine.isActive) {
      await RoutineRepository.setActiveRoutine(newRoutine.id);
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.routine == null ? 'Crear Rutina' : 'Editar Rutina'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: AppColors.primary),
            onPressed: _saveRoutine,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Nombre de la Rutina',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white24),
                ),
              ),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _days.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (oldIndex < newIndex) {
                    newIndex -= 1;
                  }
                  final item = _days.removeAt(oldIndex);
                  _days.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final day = _days[index];
                return Card(
                  key: ValueKey(day.id),
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    title: Text(
                      day.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      '${day.exercises.length} Ejercicios',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            // TODO: Navigate to DayEditorScreen
                            _editDay(day, index);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeDay(index),
                        ),
                        const Icon(Icons.drag_handle, color: Colors.white54),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDay,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _editDay(RoutineDay day, int index) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DayEditorScreen(day: day)),
    );
    setState(() {}); // Refresh to show updated exercise count
  }
}
