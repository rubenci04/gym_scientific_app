import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/routine_templates.dart';
import '../models/routine_model.dart';
import '../models/user_model.dart';
import '../services/routine_generator_service.dart';
import '../theme/app_colors.dart';
import 'routine_editor_screen.dart';

class RoutineTemplatesScreen extends StatelessWidget {
  const RoutineTemplatesScreen({super.key});

  void _selectTemplate(BuildContext context, WeeklyRoutine template) {
    // Clone the template to avoid modifying the static instance
    final newRoutine = WeeklyRoutine(
      id: 'routine_${DateTime.now().millisecondsSinceEpoch}',
      name: template.name,
      days: template.days
          .map(
            (day) => RoutineDay(
              id: 'day_${DateTime.now().millisecondsSinceEpoch}_${day.id}',
              name: day.name,
              targetMuscles: List.from(day.targetMuscles),
              exercises: day.exercises
                  .map(
                    (ex) => RoutineExercise(
                      exerciseId: ex.exerciseId,
                      sets: ex.sets,
                      reps: ex.reps,
                      rpe: ex.rpe,
                      restTimeSeconds: ex.restTimeSeconds,
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
      createdAt: DateTime.now(),
      isActive: false,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoutineEditorScreen(routine: newRoutine),
      ),
    );
  }

  Future<void> _generateSmartRoutine(BuildContext context) async {
    final userBox = Hive.box<UserProfile>('userBox');
    final user = userBox.get('currentUser');

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se encontró perfil de usuario'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      var routine = await RoutineGeneratorService.generateRoutine(user);
      // Set as active by default for immediate use
      routine = WeeklyRoutine(
        id: routine.id,
        name: routine.name,
        days: routine.days,
        createdAt: routine.createdAt,
        isActive: true,
      );

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoutineEditorScreen(routine: routine),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al generar rutina: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final templates = RoutineTemplates.templates;
    final userBox = Hive.box<UserProfile>('userBox');
    final user = userBox.get('currentUser');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Plantillas de Rutina'),
        backgroundColor: AppColors.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Smart Template Card
          if (user != null)
            Card(
              color: AppColors.primary.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.primary, width: 1),
              ),
              child: InkWell(
                onTap: () => _generateSmartRoutine(context),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.auto_awesome, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            "Generar para mis días",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Crear un plan de ${user.daysPerWeek} días basado en tu objetivo (${user.goal.toString().split('.').last}) y equipamiento.',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
                          Text(
                            "Generar Ahora",
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            color: AppColors.primary,
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
          const Text(
            "Plantillas Estándar",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          // Standard Templates
          ...templates.map((template) {
            return Card(
              color: AppColors.surface,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () => _selectTemplate(context, template),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${template.days.length} Días • ${template.days.map((d) => d.targetMuscles.join(", ")).join(" | ")}',
                        style: const TextStyle(color: Colors.white70),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
                          Text(
                            "Usar Plantilla",
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            color: AppColors.primary,
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
