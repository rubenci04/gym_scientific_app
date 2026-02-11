import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../models/routine_model.dart';
import '../models/user_model.dart';
import '../services/routine_generator_service.dart';
import '../services/routine_repository.dart';
import '../theme/app_colors.dart';
import '../main.dart'; // Para acceder al ThemeProvider
import 'routine_detail_screen.dart';
import 'routine_editor_screen.dart';
import 'routine_templates_screen.dart';

class MyRoutinesScreen extends StatefulWidget {
  const MyRoutinesScreen({super.key});

  @override
  State<MyRoutinesScreen> createState() => _MyRoutinesScreenState();
}

class _MyRoutinesScreenState extends State<MyRoutinesScreen> {
  List<WeeklyRoutine> _routines = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoutines();
  }

  Future<void> _loadRoutines() async {
    final routines = await RoutineRepository.getAllRoutines();
    if (mounted) {
      setState(() {
        _routines = routines;
        _isLoading = false;
      });
    }
  }

  Future<void> _activateRoutine(WeeklyRoutine routine) async {
    await RoutineRepository.setActiveRoutine(routine.id);
    await _loadRoutines();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rutina "${routine.name}" activada'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deleteRoutine(WeeklyRoutine routine) async {
    final theme = Theme.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text('Eliminar Rutina', style: theme.textTheme.titleLarge),
        content: Text(
          '¿Estás seguro de eliminar "${routine.name}"?',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await RoutineRepository.deleteRoutine(routine.id);
      _loadRoutines();
    }
  }

  void _createNewRoutine() {
    final newRoutine = WeeklyRoutine(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Nueva Rutina',
      days: [],
      createdAt: DateTime.now(),
      isActive: false,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoutineEditorScreen(routine: newRoutine),
      ),
    ).then((_) => _loadRoutines());
  }

  // --- GENERADOR IA CORREGIDO Y EXPANDIDO ---
  void _createNewSmartRoutine() async {
    final userBox = Hive.box<UserProfile>('userBox');
    final user = userBox.get('currentUser');

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: No hay usuario activo.")),
      );
      return;
    }

    final Map<String, String> routineOptions = {
      'Full Body (Cuerpo Completo)': 'Cuerpo Completo',
      'Torso / Pierna (4 días)': 'Torso/Pierna',
      'PPL (Empuje/Tracción/Pierna)': 'Empuje/Tracción/Pierna',
      'Rutina Equilibrada (General)': 'Equilibrado',
      'Especialización: Pecho': 'Pecho',
      'Especialización: Espalda': 'Espalda',
      'Especialización: Hombros': 'Hombros',
      'Especialización: Brazos': 'Bíceps',
      'Especialización: Glúteos': 'Glúteos',
      'Especialización: Piernas': 'Cuádriceps',
    };

    debugPrint("Showing selection dialog...");
    String? selectedFocus = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          backgroundColor: theme.cardColor,
          title: Text(
            "Elige el tipo de rutina",
            style: theme.textTheme.titleLarge,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: routineOptions.entries.map((entry) {
                final isSpecialization = entry.key.contains("Especialización");
                return ListTile(
                  title: Text(
                    entry.key,
                    style: TextStyle(
                      fontWeight: isSpecialization
                          ? FontWeight.normal
                          : FontWeight.bold,
                      color: isSpecialization
                          ? theme.colorScheme.secondary
                          : theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  leading: Icon(
                    isSpecialization
                        ? Icons.auto_fix_high
                        : Icons.fitness_center,
                    color: isSpecialization
                        ? AppColors.secondary
                        : AppColors.primary,
                  ),
                  onTap: () {
                    debugPrint("Selected: ${entry.value}");
                    Navigator.pop(ctx, entry.value);
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                debugPrint("Cancelled dialog");
                Navigator.pop(ctx);
              },
              child: const Text("Cancelar"),
            ),
          ],
        );
      },
    );

    debugPrint("Selection result: $selectedFocus");

    if (selectedFocus != null) {
      if (!mounted) return;

      // Mostrar indicador de carga
      debugPrint("Showing loading indicator...");
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      try {
        debugPrint("Calling RoutineGeneratorService...");
        // Llamar al servicio
        await RoutineGeneratorService.generateAndSaveRoutine(
          user,
          focusArea: selectedFocus,
        );
        debugPrint("Routine generated successfully.");

        // Cerrar indicador de carga
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop(); // Force pop
        }

        // Recargar lista y avisar
        await _loadRoutines();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("¡Rutina generada con éxito!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e, stack) {
        debugPrint("Error generating routine: $e");
        debugPrint(stack.toString());
        // Cerrar indicador de carga si falla
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Mis Rutinas', style: theme.appBarTheme.titleTextStyle),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: theme.iconTheme,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: themeProvider.isDarkMode
                  ? Colors.orangeAccent
                  : Colors.indigo,
            ),
            onPressed: () => themeProvider.toggleTheme(),
          ),
          const SizedBox(width: 8),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: theme.cardColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (sheetContext) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Crear Nueva Rutina",
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      leading: const Icon(
                        Icons.auto_awesome,
                        color: AppColors.secondary,
                      ),
                      title: Text(
                        "Generar con IA (Recomendado)",
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "Personalizada según tus objetivos.",
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(
                          sheetContext,
                        ); // Cerramos el sheet usando su propio context
                        _createNewSmartRoutine(); // Llamamos sin argumentos (usará context del state)
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.edit, color: AppColors.primary),
                      title: Text(
                        "Crear desde cero",
                        style: theme.textTheme.bodyLarge,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _createNewRoutine();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.copy, color: AppColors.primary),
                      title: Text(
                        "Usar plantilla clásica",
                        style: theme.textTheme.bodyLarge,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const RoutineTemplatesScreen(),
                          ),
                        ).then((_) => _loadRoutines());
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "NUEVA RUTINA",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _routines.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: _routines.length,
              itemBuilder: (context, index) {
                final routine = _routines[index];
                return _buildRoutineCard(routine);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center, size: 80, color: theme.disabledColor),
          const SizedBox(height: 16),
          Text(
            'No tienes rutinas guardadas',
            style: TextStyle(
              color: theme.textTheme.bodyMedium?.color,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => _createNewSmartRoutine(),
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            label: const Text(
              'Generar Rutina Inteligente',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineCard(WeeklyRoutine routine) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      color: theme.cardColor,
      elevation: isDark ? 1 : 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: routine.isActive
            ? const BorderSide(color: Colors.green, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoutineDetailScreen(routine: routine),
            ),
          ).then((_) => _loadRoutines());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          routine.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (routine.description.isNotEmpty)
                          Text(
                            routine.description.split('\n').first,
                            style: TextStyle(
                              color: theme.textTheme.bodySmall?.color,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: theme.iconTheme.color),
                    color: theme.cardColor,
                    onSelected: (value) {
                      if (value == 'activate') _activateRoutine(routine);
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RoutineEditorScreen(routine: routine),
                          ),
                        ).then((_) => _loadRoutines());
                      }
                      if (value == 'delete') _deleteRoutine(routine);
                    },
                    itemBuilder: (context) => [
                      if (!routine.isActive)
                        PopupMenuItem(
                          value: 'activate',
                          child: Text(
                            'Activar',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      PopupMenuItem(
                        value: 'edit',
                        child: Text(
                          'Editar',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Eliminar',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${routine.days.length} Días / semana',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  if (routine.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 14,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'ACTIVA',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
