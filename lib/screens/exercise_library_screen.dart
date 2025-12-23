import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // Para el ThemeProvider
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

  // Normaliza texto: minúsculas y sin tildes para búsqueda flexible
  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u');
  }

  // --- MOTOR DE BÚSQUEDA INTELIGENTE ---
  bool _matchesSearch(Exercise exercise) {
    // 1. Si no hay búsqueda ni filtro, pasa todo
    if (_searchQuery.isEmpty && _selectedMuscleGroup == null) return true;

    bool textMatch = true;
    bool chipMatch = true;

    // 2. Lógica de Texto (Buscador)
    if (_searchQuery.isNotEmpty) {
      final q = _normalize(_searchQuery);
      final name = _normalize(exercise.name);
      final group = _normalize(exercise.muscleGroup);
      
      // Grupos musculares agrupados (Lógica "Piernas", "Brazos")
      final isLegs = ['cuadriceps', 'isquiotibiales', 'gemelos', 'gluteos', 'aductores', 'abductores'].contains(group);
      final isArms = ['biceps', 'triceps', 'antebrazo'].contains(group);
      final isTorso = ['pecho', 'espalda', 'hombros', 'core', 'trapecio', 'cuello'].contains(group);

      if (q == 'piernas' || q == 'pierna') {
        textMatch = isLegs;
      } else if (q == 'brazos' || q == 'brazo') {
        textMatch = isArms;
      } else if (q == 'torso' || q == 'tronco') {
        textMatch = isTorso;
      } else {
        // Búsqueda estándar: Nombre, Grupo o Músculos implicados (Primarios y Secundarios)
        textMatch = name.contains(q) || 
                    group.contains(q) ||
                    exercise.targetMuscles.any((t) => _normalize(t).contains(q)) ||
                    exercise.secondaryMuscles.any((s) => _normalize(s).contains(q));
      }
    }

    // 3. Lógica de Chips (Filtros de arriba)
    if (_selectedMuscleGroup != null) {
      // El ejercicio pasa si es del grupo seleccionado O si ese grupo es un músculo secundario
      // Ej: Si filtro "Tríceps", me saldrá "Press Banca" (que es de Pecho) porque trabaja tríceps.
      bool isPrimary = exercise.muscleGroup == _selectedMuscleGroup;
      bool isSecondary = exercise.secondaryMuscles.contains(_selectedMuscleGroup) || 
                         exercise.targetMuscles.contains(_selectedMuscleGroup);
      
      chipMatch = isPrimary || isSecondary;
    }

    return textMatch && chipMatch;
  }

  // --- LÓGICA DE CÁMARA / GALERÍA ---
  Future<String?> _pickImage() async {
    try {
      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("La carga de imágenes no está soportada en Web demo.")),
        );
        return null;
      }

      final picker = ImagePicker();
      final theme = Theme.of(context);
      
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: theme.cardColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))
        ),
        builder: (context) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: theme.iconTheme.color),
                title: Text('Galería', style: theme.textTheme.bodyLarge),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: theme.iconTheme.color),
                title: Text('Cámara', style: theme.textTheme.bodyLarge),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        ),
      );

      if (source == null) return null;

      final XFile? image = await picker.pickImage(
        source: source, 
        imageQuality: 50,
        maxWidth: 800,
      );

      if (image == null) return null;

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'custom_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImage = await File(image.path).copy('${directory.path}/$fileName');
      
      return savedImage.path;
    } catch (e) {
      debugPrint("Error al seleccionar imagen: $e");
      return null;
    }
  }

  void _showExerciseDialog({Exercise? exerciseToEdit}) {
    final isEditing = exerciseToEdit != null;
    final nameCtrl = TextEditingController(text: isEditing ? exerciseToEdit.name : '');
    
    String selectedMuscle = isEditing ? exerciseToEdit.muscleGroup : 'Pecho';
    String selectedEquipment = isEditing ? exerciseToEdit.equipment : 'Mancuernas';
    String? localImagePath = isEditing ? exerciseToEdit.localImagePath : null;

    final muscles = ['Pecho', 'Espalda', 'Hombros', 'Bíceps', 'Tríceps', 'Cuádriceps', 'Isquios', 'Glúteos', 'Gemelos', 'Abdominales', 'Cardio', 'Trapecio', 'Antebrazo', 'Aductores', 'Otro'];
    final equipments = ['Corporal', 'Mancuernas', 'Barra', 'Máquina', 'Polea', 'Banda', 'Kettlebell', 'Disco', 'Otro'];

    if (!muscles.contains(selectedMuscle)) muscles.add(selectedMuscle);
    if (!equipments.contains(selectedEquipment)) equipments.add(selectedEquipment);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final theme = Theme.of(context);
          
          return AlertDialog(
            backgroundColor: theme.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text(
              isEditing ? "Editar Ejercicio" : "Nuevo Ejercicio", 
              style: theme.textTheme.titleLarge
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final path = await _pickImage();
                      if (path != null) {
                        setStateDialog(() => localImagePath = path);
                      }
                    },
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor),
                        image: localImagePath != null
                            ? DecorationImage(
                                image: FileImage(File(localImagePath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: localImagePath == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.add_a_photo, color: AppColors.primary, size: 40),
                                const SizedBox(height: 8),
                                Text("Toca para añadir foto", style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6), fontSize: 12)),
                              ],
                            )
                          : const Stack(
                              children: [
                                Positioned(
                                  right: 5,
                                  top: 5,
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.black54,
                                    child: Icon(Icons.edit, size: 14, color: Colors.white),
                                  ),
                                )
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  TextField(
                    controller: nameCtrl,
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      labelText: "Nombre del ejercicio",
                      labelStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.dividerColor)),
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  DropdownButtonFormField<String>(
                    value: selectedMuscle,
                    dropdownColor: theme.cardColor,
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      labelText: "Músculo Principal",
                      labelStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.dividerColor)),
                    ),
                    items: muscles.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setStateDialog(() => selectedMuscle = v!),
                  ),
                  const SizedBox(height: 15),
                  
                  DropdownButtonFormField<String>(
                    value: selectedEquipment,
                    dropdownColor: theme.cardColor,
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      labelText: "Equipamiento",
                      labelStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                      border: const OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: theme.dividerColor)),
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
                child: Text("Cancelar", style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  if (nameCtrl.text.isEmpty) return;

                  final box = Hive.box<Exercise>('exerciseBox');
                  
                  if (isEditing) {
                    exerciseToEdit!.name = nameCtrl.text;
                    exerciseToEdit.muscleGroup = selectedMuscle;
                    exerciseToEdit.equipment = selectedEquipment;
                    exerciseToEdit.localImagePath = localImagePath;
                    box.put(exerciseToEdit.key, exerciseToEdit); 
                  } else {
                    final newExercise = Exercise(
                      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                      name: nameCtrl.text,
                      muscleGroup: selectedMuscle,
                      equipment: selectedEquipment,
                      movementPattern: 'Personalizado',
                      difficulty: 'General',
                      description: 'Ejercicio personalizado.',
                      targetMuscles: [selectedMuscle],
                      localImagePath: localImagePath,
                    );
                    box.put(newExercise.id, newExercise);
                  }

                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditing ? "Ejercicio actualizado" : "Ejercicio creado"),
                      behavior: SnackBarBehavior.floating,
                    )
                  );
                },
                child: const Text("Guardar"),
              ),
            ],
          );
        }
      ),
    );
  }

  void _confirmDelete(Exercise exercise) {
    if (!exercise.id.startsWith('custom_')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No puedes borrar ejercicios predeterminados de la app."),
          behavior: SnackBarBehavior.floating,
        )
      );
      return;
    }

    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text("¿Eliminar?", style: theme.textTheme.titleLarge),
        content: Text("¿Borrar '${exercise.name}' permanentemente?", style: theme.textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancelar", style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
          ),
          TextButton(
            onPressed: () {
              final box = Hive.box<Exercise>('exerciseBox');
              box.delete(exercise.key); 
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Ejercicio eliminado"), behavior: SnackBarBehavior.floating)
              );
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Biblioteca Científica', style: theme.appBarTheme.titleTextStyle),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: theme.iconTheme,
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: isDark ? Colors.orangeAccent : Colors.indigo,
            ),
            tooltip: "Cambiar Tema",
            onPressed: themeProvider.toggleTheme,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showExerciseDialog(),
        backgroundColor: AppColors.primary,
        tooltip: "Crear ejercicio",
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Exercise>('exerciseBox').listenable(),
        builder: (context, Box<Exercise> box, _) {
          var allExercises = box.values.toList();
          
          // Orden alfabético (Customs primero)
          allExercises.sort((a, b) {
             final aIsCustom = a.id.startsWith('custom_');
             final bIsCustom = b.id.startsWith('custom_');
             if (aIsCustom && !bIsCustom) return -1;
             if (!aIsCustom && bIsCustom) return 1;
             return a.name.compareTo(b.name);
          });

          // Filtro Inteligente aplicado aquí
          final filteredExercises = allExercises.where((exercise) => _matchesSearch(exercise)).toList();

          final muscleGroups = allExercises.map((e) => e.muscleGroup).toSet().toList()..sort();

          return Column(
            children: [
              // --- BUSCADOR ---
              Container(
                padding: const EdgeInsets.all(16.0),
                color: theme.cardColor,
                child: TextField(
                  controller: _searchController,
                  style: theme.textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Buscar (ej: "Piernas", "Pecho", "Curl")',
                    hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4)),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    filled: true,
                    fillColor: isDark ? AppColors.background : Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () => setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            }),
                          )
                        : null,
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),

              // --- FILTROS (CHIPS) ---
              Container(
                height: 50,
                color: theme.cardColor,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFilterChip('Todos', _selectedMuscleGroup == null, () => setState(() => _selectedMuscleGroup = null)),
                    ...muscleGroups.map((muscle) => _buildFilterChip(muscle, _selectedMuscleGroup == muscle, () => setState(() => _selectedMuscleGroup = _selectedMuscleGroup == muscle ? null : muscle))),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // --- LISTA ---
              Expanded(
                child: filteredExercises.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fitness_center, size: 60, color: theme.disabledColor),
                          const SizedBox(height: 10),
                          Text("No se encontraron ejercicios", style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 10),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: isDark ? AppColors.background : Colors.grey[200],
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color, 
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), 
          side: BorderSide(color: isSelected ? AppColors.primary : Colors.transparent)
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, Exercise exercise) {
    final bool isCustom = exercise.id.startsWith('custom_');
    final theme = Theme.of(context);
    
    ImageProvider? imageProvider;
    bool isLocalImage = false;

    if (exercise.localImagePath != null) {
      if (kIsWeb) {
         imageProvider = null; 
      } else {
        final f = File(exercise.localImagePath!);
        if (f.existsSync()) {
          imageProvider = FileImage(f);
          isLocalImage = true;
        }
      }
    }
    
    if (imageProvider == null && !isCustom) {
         imageProvider = AssetImage('assets/exercises/${exercise.id}.png');
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: () => _showExerciseDetails(context, exercise, imageProvider, isLocalImage),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
                  image: imageProvider != null 
                      ? DecorationImage(
                          image: imageProvider,
                          fit: BoxFit.cover,
                          onError: (e, s) {}
                        ) 
                      : null,
                ),
                child: imageProvider == null
                    ? Center(
                        child: Text(
                          exercise.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 24),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${exercise.muscleGroup} • ${exercise.difficulty}",
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                      child: Text(exercise.equipment, style: const TextStyle(color: AppColors.primary, fontSize: 10)),
                    ),
                  ],
                ),
              ),
              if (isCustom)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: theme.iconTheme.color),
                  color: theme.cardColor,
                  onSelected: (value) {
                    if (value == 'edit') _showExerciseDialog(exerciseToEdit: exercise);
                    if (value == 'delete') _confirmDelete(exercise);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: theme.iconTheme.color, size: 20),
                          const SizedBox(width: 10),
                          Text("Editar", style: theme.textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          const SizedBox(width: 10),
                          Text("Eliminar", style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Icon(Icons.arrow_forward_ios, color: theme.iconTheme.color?.withOpacity(0.3), size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showExerciseDetails(BuildContext context, Exercise exercise, ImageProvider? imageProvider, bool isLocal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) => Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: ListView(
              controller: controller,
              padding: EdgeInsets.zero,
              children: [
                Stack(
                  children: [
                    AspectRatio(
                      aspectRatio: 1.0,
                      child: Container(
                        width: double.infinity,
                        color: isLocal ? Colors.black : Colors.white,
                        child: imageProvider != null 
                          ? Image(
                              image: imageProvider,
                              fit: isLocal ? BoxFit.cover : BoxFit.contain,
                              errorBuilder: (c, e, s) => const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 50)),
                            )
                          : const Center(child: Icon(Icons.fitness_center, size: 80, color: Colors.grey)),
                      ),
                    ),
                    Positioned(
                      top: 15,
                      right: 15,
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
                      Text(exercise.name, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildTag(exercise.muscleGroup, Colors.blue),
                          _buildTag(exercise.difficulty, Colors.orange),
                          _buildTag(exercise.equipment, Colors.purple),
                        ],
                      ),
                      const SizedBox(height: 25),
                      _buildSectionTitle("Biomecánica y Ejecución", theme),
                      const SizedBox(height: 10),
                      Text(
                        exercise.description.isNotEmpty ? exercise.description : "No hay descripción disponible.", 
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.5)
                      ),
                      
                      if (exercise.tips.isNotEmpty) ...[
                        const SizedBox(height: 25),
                        _buildSectionTitle("Consejos Pro", theme),
                        const SizedBox(height: 10),
                        ...exercise.tips.map((tip) => _buildBulletPoint(tip, Colors.greenAccent, theme)),
                      ],
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(), style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Container(width: 40, height: 2, color: AppColors.primary),
      ],
    );
  }

  Widget _buildBulletPoint(String text, Color color, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 6), child: Icon(Icons.circle, size: 6, color: color)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(5), border: Border.all(color: color.withOpacity(0.5))),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}