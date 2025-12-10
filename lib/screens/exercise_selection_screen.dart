import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/exercise_model.dart';
import '../theme/app_colors.dart';

class ExerciseSelectionScreen extends StatefulWidget {
  const ExerciseSelectionScreen({super.key});

  @override
  State<ExerciseSelectionScreen> createState() => _ExerciseSelectionScreenState();
}

class _ExerciseSelectionScreenState extends State<ExerciseSelectionScreen> {
  late Box<Exercise> _exerciseBox;
  List<Exercise> _allExercises = [];
  List<Exercise> _filteredExercises = [];
  final TextEditingController _searchController = TextEditingController();
  String? _selectedFilter; // Para el filtro de grupo muscular

  @override
  void initState() {
    super.initState();
    _exerciseBox = Hive.box<Exercise>('exerciseBox');
    _allExercises = _exerciseBox.values.toList();
    _filteredExercises = _allExercises;
  }

  void _applyFilters() {
    final query = _removeAccents(_searchController.text.toLowerCase());
    
    setState(() {
      _filteredExercises = _allExercises.where((ex) {
        // Coincidencia por texto (Nombre o Músculo)
        final matchesSearch = query.isEmpty || 
            _removeAccents(ex.name.toLowerCase()).contains(query) ||
            _removeAccents(ex.muscleGroup.toLowerCase()).contains(query);
            
        // Coincidencia por Chip seleccionado
        final matchesGroup = _selectedFilter == null || 
            ex.muscleGroup == _selectedFilter;

        return matchesSearch && matchesGroup;
      }).toList();
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
    // Obtenemos lista única de grupos musculares para los filtros
    final muscleGroups = _allExercises.map((e) => e.muscleGroup).toSet().toList()..sort();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Seleccionar Ejercicio'),
        backgroundColor: AppColors.surface,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: AppColors.surface,
            child: Column(
              children: [
                // Barra de Búsqueda
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onChanged: (v) => _applyFilters(),
                ),
                const SizedBox(height: 10),
                
                // --- FILTROS DE GRUPO MUSCULAR (CHIPS) ---
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Todos', _selectedFilter == null, () {
                        setState(() {
                          _selectedFilter = null;
                          _applyFilters();
                        });
                      }),
                      ...muscleGroups.map((group) => _buildFilterChip(group, _selectedFilter == group, () {
                        setState(() {
                          _selectedFilter = (_selectedFilter == group) ? null : group;
                          _applyFilters();
                        });
                      })),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de Resultados
          Expanded(
            child: ListView.builder(
              itemCount: _filteredExercises.length,
              itemBuilder: (context, index) {
                final exercise = _filteredExercises[index];
                return ListTile(
                  leading: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                    child: Center(child: Text(exercise.name[0], style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
                  ),
                  title: Text(exercise.name, style: const TextStyle(color: Colors.white)),
                  subtitle: Text('${exercise.muscleGroup} • ${exercise.equipment}', style: const TextStyle(color: Colors.white54)),
                  onTap: () => Navigator.pop(context, exercise),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: AppColors.background,
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey),
        side: BorderSide(color: isSelected ? AppColors.primary : Colors.transparent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}