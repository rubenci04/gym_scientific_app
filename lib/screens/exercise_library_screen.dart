import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart'; // Necesario para fotos
import 'package:path_provider/path_provider.dart'; // Necesario para guardar archivos
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

  // Normaliza texto para búsquedas (quita tildes y mayúsculas)
  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u');
  }

  // --- LÓGICA DE CÁMARA / GALERÍA ---
  Future<String?> _pickImage() async {
    final picker = ImagePicker();
    
    // Preguntar origen: Cámara o Galería
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text('Galería', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text('Cámara', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return null;

    final XFile? image = await picker.pickImage(
      source: source, 
      imageQuality: 50, // Comprimimos para no llenar memoria
      maxWidth: 800,
    );

    if (image == null) return null;

    // Guardamos la imagen en el directorio de documentos de la app para que sea persistente
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await File(image.path).copy('${directory.path}/$fileName');
    
    return savedImage.path;
  }

  // --- DIÁLOGO DE AGREGAR / EDITAR ---
  void _showExerciseDialog({Exercise? exerciseToEdit}) {
    final isEditing = exerciseToEdit != null;
    final nameCtrl = TextEditingController(text: isEditing ? exerciseToEdit.name : '');
    
    // Valores por defecto o los del ejercicio a editar
    String selectedMuscle = isEditing ? exerciseToEdit.muscleGroup : 'Pecho';
    String selectedEquipment = isEditing ? exerciseToEdit.equipment : 'Mancuernas';
    String? localImagePath = isEditing ? exerciseToEdit.localImagePath : null;

    final muscles = ['Pecho', 'Espalda', 'Hombros', 'Bíceps', 'Tríceps', 'Cuádriceps', 'Isquios', 'Glúteos', 'Gemelos', 'Abdominales', 'Cardio', 'Trapecio', 'Antebrazo', 'Aductores', 'Otro'];
    final equipments = ['Corporal', 'Mancuernas', 'Barra', 'Máquina', 'Polea', 'Banda', 'Kettlebell', 'Disco', 'Otro'];

    // Asegurar que el valor seleccionado exista en la lista (por si acaso)
    if (!muscles.contains(selectedMuscle)) muscles.add(selectedMuscle);
    if (!equipments.contains(selectedEquipment)) equipments.add(selectedEquipment);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: Text(isEditing ? "Editar Ejercicio" : "Nuevo Ejercicio", style: const TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- SELECTOR DE FOTO ---
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
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                        image: localImagePath != null
                            ? DecorationImage(
                                image: FileImage(File(localImagePath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: localImagePath == null
                          ? const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, color: AppColors.primary, size: 40),
                                SizedBox(height: 8),
                                Text("Toca para añadir foto", style: TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            )
                          : Stack(
                              children: [
                                Positioned(
                                  right: 5,
                                  top: 5,
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.black54,
                                    child: const Icon(Icons.edit, size: 14, color: Colors.white),
                                  ),
                                )
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
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
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  if (nameCtrl.text.isEmpty) return;

                  final box = Hive.box<Exercise>('exerciseBox');
                  
                  if (isEditing) {
                    // Actualizar existente
                    exerciseToEdit!.name = nameCtrl.text;
                    exerciseToEdit.muscleGroup = selectedMuscle;
                    exerciseToEdit.equipment = selectedEquipment;
                    exerciseToEdit.localImagePath = localImagePath;
                    exerciseToEdit.save(); // Guarda cambios en Hive
                  } else {
                    // Crear nuevo
                    final newExercise = Exercise(
                      id: 'custom_${DateTime.now().millisecondsSinceEpoch}', // ID único
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
                      behavior: SnackBarBehavior.floating, // Flotante para corregir márgenes
                    )
                  );
                },
                child: const Text("Guardar", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        }
      ),
    );
  }

  void _confirmDelete(Exercise exercise) {
    // Protección: Solo borrar ejercicios custom
    if (!exercise.id.startsWith('custom_')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No puedes borrar ejercicios predeterminados de la app."),
          behavior: SnackBarBehavior.floating,
        )
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("¿Eliminar?", style: TextStyle(color: Colors.white)),
        content: Text("¿Borrar '${exercise.name}' permanentemente?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              exercise.delete();
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Biblioteca Científica'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
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
          
          // Ordenar: Custom primero, luego A-Z
          allExercises.sort((a, b) {
             final aIsCustom = a.id.startsWith('custom_');
             final bIsCustom = b.id.startsWith('custom_');
             if (aIsCustom && !bIsCustom) return -1;
             if (!aIsCustom && bIsCustom) return 1;
             return a.name.compareTo(b.name);
          });

          // Filtros
          final filteredExercises = allExercises.where((exercise) {
            final matchesSearch =
                _normalize(exercise.name).contains(_normalize(_searchQuery)) ||
                _normalize(exercise.muscleGroup).contains(_normalize(_searchQuery));
            final matchesMuscle =
                _selectedMuscleGroup == null || exercise.muscleGroup == _selectedMuscleGroup;
            return matchesSearch && matchesMuscle;
          }).toList();

          final muscleGroups = allExercises.map((e) => e.muscleGroup).toSet().toList()..sort();

          return Column(
            children: [
              // --- BUSCADOR ---
              Container(
                padding: const EdgeInsets.all(16.0),
                color: AppColors.surface,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.background,
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

              // --- FILTROS ---
              Container(
                height: 50,
                color: AppColors.surface,
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
                  ? const Center(child: Text("No se encontraron ejercicios", style: TextStyle(color: Colors.grey)))
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
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 10),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: AppColors.background,
        selectedColor: AppColors.primary,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppColors.primary : Colors.white10)),
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, Exercise exercise) {
    final bool isCustom = exercise.id.startsWith('custom_');
    
    // Decidir qué imagen mostrar: 
    // 1. Imagen local del usuario
    // 2. Imagen de assets (usando el ID)
    // 3. Fallback (icono)
    ImageProvider? imageProvider;
    bool isLocalImage = false;

    if (exercise.localImagePath != null && File(exercise.localImagePath!).existsSync()) {
      imageProvider = FileImage(File(exercise.localImagePath!));
      isLocalImage = true;
    } else {
      imageProvider = AssetImage('assets/exercises/${exercise.id}.png');
    }

    return Dismissible(
      key: Key(exercise.id),
      direction: isCustom ? DismissDirection.endToStart : DismissDirection.none,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(15)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        _confirmDelete(exercise);
        return false; // Esperamos al diálogo
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _showExerciseDetails(context, exercise, imageProvider!, isLocalImage),
          onLongPress: isCustom ? () => _showExerciseDialog(exerciseToEdit: exercise) : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // MINIATURA
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white10),
                    image: imageProvider != null 
                        ? DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover, // Cover se ve mejor en miniaturas cuadradas
                            onError: (e, s) {} // Captura errores de asset no encontrado
                          ) 
                        : null,
                  ),
                  // Si falla la carga de imagen (ej: asset no existe), mostramos la inicial
                  child: imageProvider is AssetImage 
                      ? Image(
                          image: imageProvider, 
                          fit: BoxFit.contain, // Contain para assets técnicos
                          errorBuilder: (c, e, s) => Center(
                            child: Text(
                              exercise.name.substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 24),
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 15),
                
                // DATOS
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              exercise.name,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCustom) 
                            const Padding(
                              padding: EdgeInsets.only(left: 5),
                              child: Icon(Icons.edit, size: 14, color: AppColors.primary),
                            )
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${exercise.muscleGroup} • ${exercise.difficulty}",
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
                const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showExerciseDetails(BuildContext context, Exercise exercise, ImageProvider imageProvider, bool isLocal) {
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
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      width: double.infinity,
                      color: isLocal ? Colors.black : Colors.white,
                      child: Image(
                        image: imageProvider,
                        fit: isLocal ? BoxFit.cover : BoxFit.contain, // Fotos de usuario cover, dibujos contain
                        errorBuilder: (c, e, s) => const Center(child: Icon(Icons.image_not_supported, color: Colors.grey, size: 50)),
                      ),
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
                    Text(exercise.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
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
                      exercise.description.isNotEmpty ? exercise.description : "No hay descripción disponible.", 
                      style: const TextStyle(color: Colors.white70, height: 1.5, fontSize: 15)
                    ),
                    
                    if (exercise.tips.isNotEmpty) ...[
                      const SizedBox(height: 25),
                      _buildSectionTitle("Consejos Pro"),
                      const SizedBox(height: 10),
                      ...exercise.tips.map((tip) => _buildBulletPoint(tip, Colors.greenAccent)),
                    ],
                    
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
        Text(title.toUpperCase(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
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
          Padding(padding: const EdgeInsets.only(top: 6), child: Icon(Icons.circle, size: 6, color: color)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14))),
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