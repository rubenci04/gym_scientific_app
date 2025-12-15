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
  String? _selectedFilter; 

  @override
  void initState() {
    super.initState();
    _exerciseBox = Hive.box<Exercise>('exerciseBox');
    _allExercises = _exerciseBox.values.toList();
    // Ordenamos alfabéticamente para que los nuevos se mezclen bien
    _allExercises.sort((a, b) => a.name.compareTo(b.name));
    _filteredExercises = _allExercises;
  }

  void _applyFilters() {
    final query = _removeAccents(_searchController.text.toLowerCase());
    
    setState(() {
      _filteredExercises = _allExercises.where((ex) {
        final matchesSearch = query.isEmpty || 
            _removeAccents(ex.name.toLowerCase()).contains(query) ||
            _removeAccents(ex.muscleGroup.toLowerCase()).contains(query);
            
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

  // --- FUNCIÓN PARA CREAR EJERCICIO NUEVO ---
  void _showAddCustomExerciseDialog() {
    final nameCtrl = TextEditingController();
    String selectedMuscle = 'Piernas';
    String selectedEquipment = 'Corporal';
    
    final muscles = ['Pecho', 'Espalda', 'Hombros', 'Bíceps', 'Tríceps', 'Piernas', 'Glúteos', 'Abdominales', 'Cardio', 'Otro'];
    final equipments = ['Corporal', 'Mancuernas', 'Barra', 'Máquina', 'Polea', 'Banda', 'Kettlebell', 'Otro'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text("Crear Ejercicio Personalizado", style: TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Nombre del ejercicio",
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedMuscle,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Músculo Principal", 
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    ),
                    items: muscles.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setStateDialog(() => selectedMuscle = v!),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: selectedEquipment,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: "Equipamiento", 
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    ),
                    items: equipments.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setStateDialog(() => selectedEquipment = v!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancelar", style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () {
                  if (nameCtrl.text.isEmpty) return;
                  
                  // Crear el nuevo ejercicio
                  final newExercise = Exercise(
                    id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameCtrl.text,
                    muscleGroup: selectedMuscle,
                    equipment: selectedEquipment,
                    movementPattern: 'Personalizado',
                    difficulty: 'General',
                    description: 'Ejercicio personalizado creado por ti.',
                    targetMuscles: [selectedMuscle],
                    secondaryMuscles: [],
                    tips: [],
                    commonMistakes: [],
                  );
                  
                  // Guardar en Hive permanentemente
                  _exerciseBox.put(newExercise.id, newExercise);
                  
                  // Actualizar lista local
                  setState(() {
                    _allExercises.add(newExercise);
                    _allExercises.sort((a, b) => a.name.compareTo(b.name));
                    _applyFilters(); // Refrescar filtro
                  });

                  Navigator.pop(ctx); // Cierra diálogo
                  
                  // Seleccionar automáticamente y volver a la rutina
                  Navigator.pop(context, newExercise); 
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Ejercicio creado y seleccionado"))
                  );
                },
                child: const Text("Guardar y Usar", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showExerciseInfo(Exercise exercise) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(exercise.name, style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset(
                  'assets/exercises/${exercise.id}.png',
                  height: 150,
                  fit: BoxFit.contain,
                  // Si es personalizado, mostrará el icono por defecto
                  errorBuilder: (c, e, s) => const Icon(Icons.fitness_center, size: 50, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 15),
              Text(
                exercise.description.isNotEmpty ? exercise.description : "Sin descripción.",
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [
                  Chip(label: Text(exercise.muscleGroup), backgroundColor: AppColors.primary.withOpacity(0.2)),
                  Chip(label: Text(exercise.equipment), backgroundColor: Colors.white10),
                ],
              )
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cerrar", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, exercise);
            },
            child: const Text("Seleccionar", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final muscleGroups = _allExercises.map((e) => e.muscleGroup).toSet().toList()..sort();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Seleccionar Ejercicio'),
        backgroundColor: AppColors.surface,
      ),
      // BOTÓN FLOTANTE PARA AGREGAR NUEVO
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCustomExerciseDialog,
        backgroundColor: AppColors.primary,
        tooltip: "Crear ejercicio nuevo",
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: AppColors.surface,
            child: Column(
              children: [
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
          
          Expanded(
            child: ListView.builder(
              itemCount: _filteredExercises.length,
              // Dejamos espacio abajo para que el botón flotante no tape el último item
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 80),
              itemBuilder: (context, index) {
                final exercise = _filteredExercises[index];
                final imagePath = 'assets/exercises/${exercise.id}.png';

                return Card(
                  color: AppColors.surface,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    leading: Container(
                      width: 50, height: 50,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white, 
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.asset(
                          imagePath,
                          fit: BoxFit.contain,
                          errorBuilder: (c,e,s) => Center(
                            child: Text(exercise.name.isNotEmpty ? exercise.name[0].toUpperCase() : "E", 
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))
                          ),
                        ),
                      ),
                    ),
                    title: Text(exercise.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('${exercise.muscleGroup} • ${exercise.equipment}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    trailing: IconButton(
                      icon: const Icon(Icons.info_outline, color: AppColors.primary),
                      onPressed: () => _showExerciseInfo(exercise),
                    ),
                    onTap: () => Navigator.pop(context, exercise),
                  ),
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