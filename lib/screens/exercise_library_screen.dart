import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/exercise_model.dart';
import '../theme/app_colors.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  String _searchQuery = '';
  String? _selectedMuscleGroup;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Biblioteca de Ejercicios'),
        backgroundColor: AppColors.surface,
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Exercise>('exerciseBox').listenable(),
        builder: (context, Box<Exercise> box, _) {
          final allExercises = box.values.toList();

          // Get unique muscle groups for filter chips
          final muscleGroups =
              allExercises.map((e) => e.muscleGroup).toSet().toList()..sort();

          // Filter logic
          final filteredExercises = allExercises.where((exercise) {
            final matchesSearch =
                _normalize(exercise.name).contains(_normalize(_searchQuery)) ||
                _normalize(
                  exercise.muscleGroup,
                ).contains(_normalize(_searchQuery));
            final matchesMuscle =
                _selectedMuscleGroup == null ||
                exercise.muscleGroup == _selectedMuscleGroup;
            return matchesSearch && matchesMuscle;
          }).toList();

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar ejercicio...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppColors.textSecondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Todos'),
                      selected: _selectedMuscleGroup == null,
                      onSelected: (selected) =>
                          setState(() => _selectedMuscleGroup = null),
                      backgroundColor: AppColors.surface,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: _selectedMuscleGroup == null
                            ? Colors.black
                            : Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ...muscleGroups.map((muscle) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(muscle),
                          selected: _selectedMuscleGroup == muscle,
                          onSelected: (selected) {
                            setState(() {
                              _selectedMuscleGroup = selected ? muscle : null;
                            });
                          },
                          backgroundColor: AppColors.surface,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: _selectedMuscleGroup == muscle
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Exercise List
              Expanded(
                child: ListView.builder(
                  itemCount: filteredExercises.length,
                  itemBuilder: (context, index) {
                    final exercise = filteredExercises[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      color: AppColors.surface,
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              exercise.name.substring(0, 1).toUpperCase(),
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          exercise.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          "${exercise.muscleGroup} • ${exercise.equipment}",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        onTap: () {
                          // TODO: Show detailed view dialog
                          _showExerciseDetails(context, exercise);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showExerciseDetails(BuildContext context, Exercise exercise) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            _detailRow(Icons.fitness_center, "Músculo", exercise.muscleGroup),
            const SizedBox(height: 10),
            _detailRow(Icons.construction, "Equipo", exercise.equipment),
            const SizedBox(height: 10),
            _detailRow(
              Icons.compare_arrows,
              "Patrón",
              exercise.movementPattern,
            ),
            const SizedBox(height: 24),
            const Text(
              "Instrucciones",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Mantén una postura correcta y controla el movimiento en todo momento. Realiza el rango de movimiento completo.",
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(width: 10),
        Text("$label: ", style: const TextStyle(color: Colors.white54)),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
