import 'package:flutter/material.dart';
import '../models/routine_model.dart';
import '../services/routine_repository.dart';
import '../theme/app_colors.dart';
import 'routine_detail_screen.dart';
import 'routine_editor_screen.dart';
import 'routine_templates_screen.dart';

class MyRoutinesScreen extends StatefulWidget {
  const MyRoutinesScreen({super.key});

  @override
  State<MyRoutinesScreen> createState() => _MyRoutinesScreenState();
}

class _MyRoutinesScreenState extends State<MyRoutinesScreen> {
  List<WeeklyRoutine> _routines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    final routines = await RoutineRepository.getAllRoutines();
    setState(() {
      _routines = routines;
      _isLoading = false;
    });
  }

  Future<void> _activateRoutine(WeeklyRoutine routine) async {
    await RoutineRepository.setActiveRoutine(routine.id);
    await _loadRoutines(); // Recargar para actualizar UI
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _routines.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _routines.length,
              itemBuilder: (context, index) {
                final routine = _routines[index];
                return _buildRoutineCard(routine);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: AppColors.surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Crear Nueva Rutina",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: const Icon(Icons.edit, color: AppColors.primary),
                    title: const Text(
                      "Crear desde cero",
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RoutineEditorScreen(),
                        ),
                      ).then((_) => _loadRoutines());
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.copy, color: AppColors.primary),
                    title: const Text(
                      "Usar plantilla",
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      "PPL, Arnold Split, Full Body...",
                      style: TextStyle(color: Colors.white70),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RoutineTemplatesScreen(),
                        ),
                      ).then((_) => _loadRoutines());
                    },
                  ),
                ],
              ),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.fitness_center, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No tienes rutinas guardadas',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RoutineEditorScreen(),
                ),
              ).then((_) => _loadRoutines());
            },
            child: const Text('Crear mi primera rutina'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineCard(WeeklyRoutine routine) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 16),
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
            const SizedBox(height: 8),
            Text(
              '${routine.days.length} Días por semana',
              style: const TextStyle(color: Colors.white70),
            ),
            if (routine.isActive)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green),
                ),
                child: const Text(
                  'ACTIVA',
                  style: TextStyle(color: Colors.green, fontSize: 12),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('ACTIVAR'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                  ),
                  onPressed: () => _activateRoutine(routine),
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            if (value == 'activate') _activateRoutine(routine);
            if (value == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RoutineEditorScreen(routine: routine),
                ),
              ).then((_) => _loadRoutines());
            }
            if (value == 'delete') _deleteRoutine(routine);
          },
          itemBuilder: (context) => [
            if (!routine.isActive)
              const PopupMenuItem(value: 'activate', child: Text('Activar')),
            const PopupMenuItem(value: 'edit', child: Text('Editar')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
        onTap: () {
          // Navegar a detalle de rutina
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoutineDetailScreen(routine: routine),
            ),
          );
        },
      ),
    );
  }
}
