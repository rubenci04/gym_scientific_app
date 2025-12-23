import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Importante para el botón de tema
import '../models/routine_model.dart';
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
    // La lógica de base de datos ya asegura que solo una quede activa
    await RoutineRepository.setActiveRoutine(routine.id);
    await _loadRoutines(); // Recargamos para ver el cambio visual (switch de rutinas)
    
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
        content: Text('¿Estás seguro de eliminar "${routine.name}"?', style: theme.textTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
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
      isActive: false, // Siempre nacen inactivas (salvo que sea la primera, gestionado por repo)
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoutineEditorScreen(routine: newRoutine),
      ),
    ).then((_) => _loadRoutines());
  }

  @override
  Widget build(BuildContext context) {
    // Accedemos al tema actual y al provider para el botón
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
          // --- NUEVO: BOTÓN CAMBIO DE TEMA ---
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: themeProvider.isDarkMode ? Colors.orangeAccent : Colors.indigo,
            ),
            tooltip: "Cambiar Tema",
            onPressed: () {
              themeProvider.toggleTheme();
            },
          ),
          const SizedBox(width: 8),
        ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: theme.cardColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Crear Nueva Rutina",
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      leading: const Icon(Icons.edit, color: AppColors.primary),
                      title: Text("Crear desde cero", style: theme.textTheme.bodyLarge),
                      onTap: () {
                        Navigator.pop(context);
                        _createNewRoutine();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.copy, color: AppColors.primary),
                      title: Text("Usar plantilla", style: theme.textTheme.bodyLarge),
                      subtitle: Text(
                        "PPL, Arnold Split, Full Body...",
                        style: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.7)),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RoutineTemplatesScreen(),
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
        child: const Icon(Icons.add, color: Colors.white),
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
            style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 18),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: _createNewRoutine,
            child: const Text('Crear mi primera rutina', style: TextStyle(color: Colors.white)),
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
      elevation: isDark ? 1 : 3, // Un poco más de sombra en modo claro para que destaque
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // Borde sutil verde si está activa, transparente si no
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
          );
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
                    child: Text(
                      routine.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
                            builder: (context) => RoutineEditorScreen(routine: routine),
                          ),
                        ).then((_) => _loadRoutines());
                      }
                      if (value == 'delete') _deleteRoutine(routine);
                    },
                    itemBuilder: (context) => [
                      if (!routine.isActive)
                        PopupMenuItem(
                          value: 'activate', 
                          child: Text('Activar', style: theme.textTheme.bodyMedium)
                        ),
                      PopupMenuItem(
                        value: 'edit', 
                        child: Text('Editar', style: theme.textTheme.bodyMedium)
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${routine.days.length} Días por semana',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              
              // Estado de Activación
              if (routine.isActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      SizedBox(width: 5),
                      Text(
                        'ACTIVA',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                )
              else
                OutlinedButton.icon(
                  icon: const Icon(Icons.play_circle_outline, size: 18),
                  label: const Text('ACTIVAR ESTA RUTINA'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () => _activateRoutine(routine),
                ),
            ],
          ),
        ),
      ),
    );
  }
}