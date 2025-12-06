import 'package:flutter/material.dart';
import '../models/routine_model.dart';
import '../theme/app_colors.dart';

class RoutineDetailScreen extends StatelessWidget {
  final WeeklyRoutine routine;

  const RoutineDetailScreen({super.key, required this.routine});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(routine.name),
        backgroundColor: AppColors.surface,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: routine.days.length,
        itemBuilder: (context, index) {
          final day = routine.days[index];
          return Card(
            color: AppColors.surface,
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
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
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Músculos: ${day.targetMuscles.join(", ")}',
                        style: const TextStyle(color: AppColors.primary),
                      ),
                      const SizedBox(height: 10),
                      ...day.exercises.map(
                        (exercise) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.fitness_center,
                                size: 16,
                                color: Colors.white54,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  exercise
                                      .exerciseId, // Idealmente buscaríamos el nombre real en la DB
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              Text(
                                '${exercise.sets} x ${exercise.reps}',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
