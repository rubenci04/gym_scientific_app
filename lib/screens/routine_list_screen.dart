import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/routine_model.dart';
import '../services/routine_repository.dart';
import '../theme/app_colors.dart';
import 'goal_selection_screen.dart';

class RoutineListScreen extends StatefulWidget {
  const RoutineListScreen({super.key});

  @override
  State<RoutineListScreen> createState() => _RoutineListScreenState();
}

class _RoutineListScreenState extends State<RoutineListScreen> {
  List<WeeklyRoutine> _routines = [];

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  void _loadRoutines() {
    setState(() {
      _routines = RoutineRepository.getAllRoutines();
      // Sort by creation date descending
      _routines.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Future<void> _setActive(WeeklyRoutine routine) async {
    await RoutineRepository.setActiveRoutine(routine.id);
    _loadRoutines();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rutina "${routine.name}" activada')),
      );
    }
  }

  Future<void> _deleteRoutine(WeeklyRoutine routine) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Rutina'),
        content: Text('¿Estás seguro de eliminar "${routine.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await RoutineRepository.deleteRoutine(routine.id);
      _loadRoutines();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mis Rutinas'),
        backgroundColor: AppColors.surface,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const GoalSelectionScreen(),
            ),
          ).then((_) => _loadRoutines());
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
      body: _routines.isEmpty
          ? const Center(
              child: Text(
                'No tienes rutinas guardadas.',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _routines.length,
              itemBuilder: (context, index) {
                final routine = _routines[index];
                final dateStr = DateFormat.yMMMd().format(routine.createdAt);

                return Card(
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: routine.isActive
                        ? const BorderSide(color: AppColors.primary, width: 2)
                        : BorderSide.none,
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      routine.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        Text(
                          'Creada: $dateStr',
                          style: const TextStyle(color: Colors.white54),
                        ),
                        Text(
                          '${routine.days.length} días por semana',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!routine.isActive)
                          IconButton(
                            icon: const Icon(
                              Icons.check_circle_outline,
                              color: Colors.grey,
                            ),
                            onPressed: () => _setActive(routine),
                            tooltip: 'Activar',
                          ),
                        if (routine.isActive)
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                          ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _deleteRoutine(routine),
                        ),
                      ],
                    ),
                    onTap: () {
                      if (!routine.isActive) _setActive(routine);
                    },
                  ),
                );
              },
            ),
    );
  }
}
