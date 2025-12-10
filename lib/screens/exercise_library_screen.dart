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

  // Normaliza texto para búsqueda sin tildes ni mayúsculas
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
        title: const Text('Biblioteca Científica'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Exercise>('exerciseBox').listenable(),
        builder: (context, Box<Exercise> box, _) {
          final allExercises = box.values.toList();
          final muscleGroups = allExercises.map((e) => e.muscleGroup).toSet().toList()..sort();

          final filteredExercises = allExercises.where((exercise) {
            final matchesSearch =
                _normalize(exercise.name).contains(_normalize(_searchQuery)) ||
                _normalize(exercise.muscleGroup).contains(_normalize(_searchQuery));
            final matchesMuscle = _selectedMuscleGroup == null || exercise.muscleGroup == _selectedMuscleGroup;
            return matchesSearch && matchesMuscle;
          }).toList();

          return Column(
            children: [
              // --- BARRA DE BÚSQUEDA ---
              Container(
                padding: const EdgeInsets.all(16.0),
                color: AppColors.surface,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o músculo...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () => setState(() { _searchController.clear(); _searchQuery = ''; }),
                          )
                        : null,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),

              // --- FILTROS (CHIPS) ---
              Container(
                height: 50,
                color: AppColors.surface,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFilterChip('Todos', _selectedMuscleGroup == null, () => setState(() => _selectedMuscleGroup = null)),
                    ...muscleGroups.map((muscle) => _buildFilterChip(
                      muscle, 
                      _selectedMuscleGroup == muscle, 
                      () => setState(() => _selectedMuscleGroup = _selectedMuscleGroup == muscle ? null : muscle)
                    )),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // --- LISTA DE EJERCICIOS ---
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: filteredExercises.length,
                  itemBuilder: (context, index) {
                    final exercise = filteredExercises[index];
                    return _buildExerciseCard(context, exercise);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 10),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: AppColors.background,
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppColors.primary : Colors.white10)),
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, Exercise exercise) {
    // Construcción dinámica de la ruta de imagen
    final imagePath = 'assets/exercises/${exercise.id}.png';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => _showExerciseDetails(context, exercise),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // --- MINIATURA DEL EJERCICIO ---
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white10)
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover, // Cubre el cuadro pequeño perfectamente
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback: Si no carga, muestra la inicial
                      return Center(
                        child: Text(
                          exercise.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 15),
              // Info Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${exercise.muscleGroup} • ${exercise.difficulty}",
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                       decoration: BoxDecoration(
                         color: AppColors.primary.withOpacity(0.1),
                         borderRadius: BorderRadius.circular(4)
                       ),
                       child: Text(
                         exercise.equipment,
                         style: const TextStyle(color: AppColors.primary, fontSize: 10),
                       ),
                     ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showExerciseDetails(BuildContext context, Exercise exercise) {
    final imagePath = 'assets/exercises/${exercise.id}.png';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: Colors.transparent, 
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: ListView(
            controller: controller,
            padding: EdgeInsets.zero,
            children: [
              // --- IMAGEN GRANDE (CORREGIDA) ---
              Stack(
                children: [
                  // Usamos AspectRatio 1.0 (Cuadrado) + BoxFit.contain
                  // Esto garantiza que la imagen se vea completa sin recortar la cabeza o pies
                  AspectRatio(
                    aspectRatio: 1.0, 
                    child: Container(
                      width: double.infinity,
                      color: Colors.white10, // Fondo sutil por si la imagen tiene transparencia
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.contain, // CLAVE: Se ajusta al contenedor sin recorte
                        errorBuilder: (c,e,s) => const Center(
                          child: Icon(Icons.image_not_supported, color: Colors.white24, size: 50)
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 15, right: 15,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),
              
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildTag(exercise.muscleGroup, Colors.blue),
                        const SizedBox(width: 8),
                        _buildTag(exercise.difficulty, Colors.orange),
                        const SizedBox(width: 8),
                        _buildTag(exercise.equipment, Colors.purple),
                      ],
                    ),
                    const SizedBox(height: 25),

                    _buildSectionTitle("Biomecánica y Ejecución"),
                    const SizedBox(height: 10),
                    Text(
                      exercise.description.isNotEmpty 
                        ? exercise.description 
                        : "No hay descripción disponible.",
                      style: const TextStyle(color: Colors.white70, height: 1.5, fontSize: 15),
                    ),
                    
                    const SizedBox(height: 25),

                    if (exercise.tips.isNotEmpty) ...[
                      _buildSectionTitle("Consejos Pro"),
                      const SizedBox(height: 10),
                      ...exercise.tips.map((tip) => _buildBulletPoint(tip, Colors.greenAccent)),
                      const SizedBox(height: 25),
                    ],

                    if (exercise.commonMistakes.isNotEmpty) ...[
                      _buildSectionTitle("Errores Comunes"),
                      const SizedBox(height: 10),
                      ...exercise.commonMistakes.map((mistake) => _buildBulletPoint(mistake, Colors.redAccent)),
                      const SizedBox(height: 25),
                    ],

                    _buildSectionTitle("Mapa Muscular"),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        _buildMuscleChip("Principal: ${exercise.muscleGroup}", true),
                        ...exercise.secondaryMuscles.map((m) => _buildMuscleChip(m, false))
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Container(width: 40, height: 2, color: AppColors.primary),
      ],
    );
  }

  Widget _buildBulletPoint(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildMuscleChip(String text, bool isPrimary) {
    return Chip(
      label: Text(text),
      backgroundColor: isPrimary ? AppColors.primary.withOpacity(0.2) : AppColors.surface,
      labelStyle: TextStyle(color: isPrimary ? AppColors.primary : Colors.white60, fontSize: 12),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}