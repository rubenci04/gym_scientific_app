import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/exercise_model.dart';
import '../models/muscle_data.dart';
import '../theme/app_colors.dart';
import '../widgets/interactive_body_map.dart';

class MuscleSelectorScreen extends StatefulWidget {
  const MuscleSelectorScreen({super.key});

  @override
  State<MuscleSelectorScreen> createState() => _MuscleSelectorScreenState();
}

class _MuscleSelectorScreenState extends State<MuscleSelectorScreen> {
  bool _isFrontView = true;
  String? _selectedMuscleId;
  String? _selectedMuscleName;
  List<Exercise> _filteredExercises = [];

  // Mapeo corregido: ID del músculo (parte del string) -> Grupo Muscular en Base de Datos
  final Map<String, String> muscleToExerciseGroup = {
    'pec': 'Pecho',
    'abd': 'Core',
    'oblicuo': 'Core',
    'hombro': 'Hombros',
    'biceps': 'Bíceps',
    'quad': 'Cuádriceps',
    'dorsal': 'Espalda',
    'trap': 'Espalda',
    'espalda': 'Espalda',
    'triceps': 'Tríceps',
    'gluteo': 'Glúteos',
    'isquio': 'Isquiotibiales',
    'gemelo': 'Gemelos',
    'lumb': 'Espalda',
    'aduc': 'Aductores', // CORREGIDO: Antes decía Cuádriceps
    'abduc': 'Abductores', // NUEVO: Añadido para Abductores
    'antebrazo': 'Antebrazo', // CORREGIDO: 'avb' no coincidía con 'antebrazo_der'
  };

  void _onMuscleTapped(String muscleId) {
    final exerciseBox = Hive.box<Exercise>('exerciseBox');

    // Buscamos el nombre legible del músculo para mostrarlo en el título
    final musclePart = allMuscleParts.firstWhere(
      (m) => m.id == muscleId,
      orElse: () => allMuscleParts.first,
    );

    // Identificamos a qué grupo de ejercicios pertenece este músculo
    String? targetGroup;
    for (var entry in muscleToExerciseGroup.entries) {
      if (muscleId.contains(entry.key)) {
        targetGroup = entry.value;
        break;
      }
    }

    if (targetGroup != null) {
      // Filtramos los ejercicios que coincidan con ese grupo
      final exercises = exerciseBox.values.where((ex) {
        return ex.muscleGroup == targetGroup ||
            ex.targetMuscles.any((m) => m.contains(targetGroup!)) ||
            ex.secondaryMuscles.any((m) => m.contains(targetGroup!));
      }).toList();

      setState(() {
        _selectedMuscleId = muscleId;
        _selectedMuscleName = musclePart.name;
        _filteredExercises = exercises;
      });
    } else {
      // Feedback visual si tocamos un músculo sin ejercicios mapeados
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No hay ejercicios vinculados a: ${musclePart.name}"),
          duration: const Duration(milliseconds: 1000),
          backgroundColor: Colors.grey,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Selecciona un Músculo'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isFrontView ? Icons.flip_to_back : Icons.flip_to_front),
            onPressed: () => setState(() {
              _isFrontView = !_isFrontView;
              _selectedMuscleId = null;
              _selectedMuscleName = null;
              _filteredExercises = [];
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedMuscleName != null)
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.primary.withOpacity(0.2),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Músculo: $_selectedMuscleName (${_filteredExercises.length} ejercicios)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _selectedMuscleId = null;
                        _selectedMuscleName = null;
                        _filteredExercises = [];
                      });
                    },
                  ),
                ],
              ),
            ),
          
          if (_selectedMuscleName == null)
            Expanded(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    'Toca un músculo para ver ejercicios',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _MuscleMapSelector(
                      isFront: _isFrontView,
                      onMuscleTapped: _onMuscleTapped,
                      selectedMuscleId: _selectedMuscleId,
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: _filteredExercises.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.fitness_center, size: 60, color: Colors.white24),
                          const SizedBox(height: 15),
                          const Text(
                            'No se encontraron ejercicios específicos\npara este grupo muscular.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredExercises.length,
                      itemBuilder: (context, index) {
                        final exercise = _filteredExercises[index];
                        // Ruta de imagen para la miniatura
                        final imagePath = 'assets/exercises/${exercise.id}.png';
                        
                        return Card(
                          color: AppColors.surface,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: Container(
                              width: 50, height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white10,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset(
                                  imagePath,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Icon(Icons.fitness_center, color: AppColors.primary),
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
                              '${exercise.equipment} • ${exercise.difficulty}',
                              style: const TextStyle(color: Colors.white54),
                            ),
                            trailing: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                            onTap: () {
                              Navigator.pop(context, exercise);
                            },
                          ),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}

class _MuscleMapSelector extends StatelessWidget {
  final bool isFront;
  final Function(String) onMuscleTapped;
  final String? selectedMuscleId;

  const _MuscleMapSelector({
    required this.isFront,
    required this.onMuscleTapped,
    this.selectedMuscleId,
  });

  @override
  Widget build(BuildContext context) {
    // Mapa de fatiga vacío porque estamos en modo selección (no análisis)
    final Map<String, double> emptyFatigue = {};

    return InteractiveBodyMap(
      fatigueMap: emptyFatigue,
      isFront: isFront,
      onMuscleTap: onMuscleTapped,
      selectedMuscleId: selectedMuscleId,
    );
  }
}