import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/routine_templates.dart';
import '../models/routine_model.dart';
import '../models/user_model.dart';
import '../services/routine_generator_service.dart';
import '../theme/app_colors.dart';
import 'routine_editor_screen.dart';

class RoutineTemplatesScreen extends StatelessWidget {
  const RoutineTemplatesScreen({super.key});

  void _selectTemplate(BuildContext context, WeeklyRoutine template) {
    // Clonamos la plantilla para no modificar la estática
    final newRoutine = WeeklyRoutine(
      id: 'routine_${DateTime.now().millisecondsSinceEpoch}',
      name: template.name,
      days: template.days
          .map(
            (day) => RoutineDay(
              id: 'day_${DateTime.now().millisecondsSinceEpoch}_${day.id}',
              name: day.name,
              targetMuscles: List.from(day.targetMuscles),
              exercises: day.exercises
                  .map(
                    (ex) => RoutineExercise(
                      exerciseId: ex.exerciseId,
                      sets: ex.sets,
                      reps: ex.reps,
                      rpe: ex.rpe,
                      restTimeSeconds: ex.restTimeSeconds,
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
      createdAt: DateTime.now(),
      isActive: false,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoutineEditorScreen(routine: newRoutine),
      ),
    );
  }

  // Nota para mí: Función que abre el configurador antes de generar
  void _openSmartRoutineConfig(BuildContext context) {
    final userBox = Hive.box<UserProfile>('userBox');
    final user = userBox.get('currentUser');

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: No se encontró perfil de usuario')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SmartRoutineConfigSheet(user: user),
    );
  }

  @override
  Widget build(BuildContext context) {
    final templates = RoutineTemplates.templates;
    final userBox = Hive.box<UserProfile>('userBox');
    final user = userBox.get('currentUser');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Plantillas de Rutina'),
        backgroundColor: AppColors.surface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Smart Template Card
          if (user != null)
            Card(
              color: AppColors.primary.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.primary, width: 1),
              ),
              child: InkWell(
                onTap: () => _openSmartRoutineConfig(context),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.auto_awesome, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            "Generador Inteligente",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Crea un plan personalizado ajustando tus días, objetivo y equipamiento disponible.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
                          Text(
                            "Configurar y Generar",
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            color: AppColors.primary,
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
          const Text(
            "Plantillas Estándar",
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          // Standard Templates
          ...templates.map((template) {
            return Card(
              color: AppColors.surface,
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () => _selectTemplate(context, template),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${template.days.length} Días • ${template.days.map((d) => d.targetMuscles.join(", ")).join(" | ")}',
                        style: const TextStyle(color: Colors.white70),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: const [
                          Text(
                            "Usar Plantilla",
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            color: AppColors.primary,
                            size: 16,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// Nota para mí: Widget privado para configurar la generación
class _SmartRoutineConfigSheet extends StatefulWidget {
  final UserProfile user;

  const _SmartRoutineConfigSheet({required this.user});

  @override
  State<_SmartRoutineConfigSheet> createState() => _SmartRoutineConfigSheetState();
}

class _SmartRoutineConfigSheetState extends State<_SmartRoutineConfigSheet> {
  late int _days;
  late TrainingGoal _goal;
  late TrainingLocation _location;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    // Inicializamos con los valores del usuario
    _days = widget.user.daysPerWeek;
    _goal = widget.user.goal;
    _location = widget.user.location;
  }

  Future<void> _generate() async {
    setState(() => _isGenerating = true);

    try {
      // Creamos un usuario temporal con las preferencias seleccionadas
      final tempUser = UserProfile(
        name: widget.user.name,
        age: widget.user.age,
        weight: widget.user.weight,
        height: widget.user.height,
        gender: widget.user.gender,
        daysPerWeek: _days,
        goal: _goal,
        location: _location,
        somatotype: widget.user.somatotype,
      );

      var routine = await RoutineGeneratorService.generateRoutine(tempUser);
      
      // La marcamos como activa
      routine = WeeklyRoutine(
        id: routine.id,
        name: routine.name,
        days: routine.days,
        createdAt: routine.createdAt,
        isActive: true,
      );

      if (mounted) {
        Navigator.pop(context); // Cierra el modal
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoutineEditorScreen(routine: routine),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Configurar Nueva Rutina",
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          
          // Selector de Días
          const Text("Días por semana", style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(7, (index) {
                final dayNum = index + 1;
                final isSelected = _days == dayNum;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text("$dayNum"),
                    selected: isSelected,
                    onSelected: (v) => setState(() => _days = dayNum),
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey),
                  ),
                );
              }),
            ),
          ),
          
          const SizedBox(height: 20),

          // Selector de Objetivo
          const Text("Objetivo Principal", style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: TrainingGoal.values.map((g) {
              final isSelected = _goal == g;
              String label = "";
              switch(g) {
                case TrainingGoal.hypertrophy: label = "Hipertrofia (Masa)"; break;
                case TrainingGoal.strength: label = "Fuerza"; break;
                case TrainingGoal.weightLoss: label = "Perder Grasa"; break;
                case TrainingGoal.endurance: label = "Resistencia"; break;
                default: label = "Salud General";
              }
              
              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (v) => setState(() => _goal = g),
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surface,
                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Selector de Lugar
          const Text("Lugar de Entrenamiento", style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildLocationOption(
                  "Gimnasio", 
                  TrainingLocation.gym, 
                  Icons.fitness_center
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildLocationOption(
                  "Casa", 
                  TrainingLocation.home, 
                  Icons.home
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Botón Generar
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _isGenerating ? null : _generate,
              child: _isGenerating 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("GENERAR RUTINA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationOption(String label, TrainingLocation loc, IconData icon) {
    final isSelected = _location == loc;
    return InkWell(
      onTap: () => setState(() => _location = loc),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.2) : AppColors.surface,
          border: Border.all(color: isSelected ? AppColors.primary : Colors.white24),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
            const SizedBox(height: 5),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}