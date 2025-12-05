import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/exercise_model.dart';
import '../theme/app_colors.dart';

class ExerciseSelectionScreen extends StatefulWidget {
  const ExerciseSelectionScreen({super.key});

  @override
  State<ExerciseSelectionScreen> createState() =>
      _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
  late Box<Exercise> _exerciseBox;
  List<Exercise> _allExercises = [];
  List<Exercise> _filteredExercises = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _exerciseBox = Hive.box<Exercise>('exerciseBox');
    _allExercises = _exerciseBox.values.toList();
    _filteredExercises = _allExercises;
  }

  void _filterExercises(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredExercises = _allExercises;
      } else {
        final normalizedQuery = _removeAccents(query.toLowerCase());
        _filteredExercises = _allExercises.where((ex) {
          final normalizedName = _removeAccents(ex.name.toLowerCase());
          final normalizedMuscle = _removeAccents(ex.muscleGroup.toLowerCase());
          final normalizedEquipment = _removeAccents(
            ex.equipment.toLowerCase(),
          );

          return normalizedName.contains(normalizedQuery) ||
              normalizedMuscle.contains(normalizedQuery) ||
              normalizedEquipment.contains(normalizedQuery);
        }).toList();
      }
    });
  }

  String _removeAccents(String text) {
    const accents = 'áéíóúÁÉÍÓÚñÑüÜ';
    const withoutAccents = 'aeiouAEIOUnNuU';

    String result = text;
    for (int i = 0; i < accents.length; i++) {
      result = result.replaceAll(accents[i], withoutAccents[i]);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Seleccionar Ejercicio'),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Buscar por nombre o músculo...',
                hintStyle: TextStyle(color: Colors.white54),
                prefixIcon: Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _filterExercises,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredExercises.length,
              itemBuilder: (context, index) {
                final exercise = _filteredExercises[index];
                return ListTile(
                  title: Text(
                    exercise.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '${exercise.muscleGroup} • ${exercise.equipment}',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  onTap: () {
                    Navigator.pop(context, exercise);
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
