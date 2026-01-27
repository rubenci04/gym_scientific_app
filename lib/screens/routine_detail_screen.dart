import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/routine_model.dart';
import '../models/exercise_model.dart';
import '../theme/app_colors.dart';
import 'workout_screen.dart';

class RoutineDetailScreen extends StatelessWidget {
  final WeeklyRoutine routine;

  const RoutineDetailScreen({super.key, required this.routine});

  // Helper de traducción local
  Map<String, String> _getTexts(String lang) {
    if (lang == 'en') {
      return {
        'empty_routine': 'This routine has no days configured.',
        'exercises': 'Exercises',
        'start_workout': 'START WORKOUT',
      };
    }
    return {
      'empty_routine': 'Esta rutina no tiene días configurados.',
      'exercises': 'Ejercicios',
      'start_workout': 'COMENZAR ENTRENAMIENTO',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final exerciseBox = Hive.box<Exercise>('exerciseBox');

    // Escuchamos el idioma global
    return ValueListenableBuilder(
      valueListenable: Hive.box('settingsBox').listenable(keys: ['language']),
      builder: (context, Box box, _) {
        final String lang = box.get('language', defaultValue: 'es');
        final texts = _getTexts(lang);

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(routine.name, style: theme.appBarTheme.titleTextStyle),
            backgroundColor: theme.appBarTheme.backgroundColor,
            iconTheme: theme.iconTheme,
            elevation: 0,
          ),
          body: routine.days.isEmpty
              ? Center(
                  child: Text(
                    texts['empty_routine']!,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: routine.days.length,
                  itemBuilder: (context, index) {
                    final day = routine.days[index];
                    return Card(
                      color: theme.cardColor,
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ExpansionTile(
                        shape: Border.all(color: Colors.transparent),
                        collapsedShape: Border.all(color: Colors.transparent),
                        title: Text(
                          day.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${day.exercises.length} ${texts['exercises']}',
                          style: theme.textTheme.bodySmall,
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (day.targetMuscles.isNotEmpty) ...[
                                  Wrap(
                                    spacing: 8,
                                    children: day.targetMuscles.map((muscle) => 
                                      Chip(
                                        label: Text(muscle, style: const TextStyle(fontSize: 10, color: Colors.white)),
                                        backgroundColor: AppColors.primary.withOpacity(0.8),
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      )
                                    ).toList(),
                                  ),
                                  const SizedBox(height: 15),
                                ],
                                
                                // Lista de ejercicios
                                ...day.exercises.map((routineExercise) {
                                  final realExercise = exerciseBox.get(routineExercise.exerciseId);
                                  final exerciseName = realExercise?.name ?? routineExercise.exerciseId;

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 6),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.fitness_center,
                                          size: 16,
                                          color: theme.iconTheme.color?.withOpacity(0.5),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            exerciseName,
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: theme.dividerColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(4)
                                          ),
                                          child: Text(
                                            '${routineExercise.sets} x ${routineExercise.reps}',
                                            style: TextStyle(
                                              color: theme.textTheme.bodySmall?.color,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),

                                const SizedBox(height: 20),
                                
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      elevation: 4,
                                      shadowColor: AppColors.primary.withOpacity(0.4),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => WorkoutScreen(
                                            dayName: day.name,
                                            routineExercises: day.exercises,
                                            routineDayId: day.id,
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.play_arrow, size: 24),
                                    label: Text(
                                      texts['start_workout']!,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
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
    );
  }
}