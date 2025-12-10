import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/routine_model.dart';
import '../services/progressive_overload_service.dart';
import '../services/routine_repository.dart';
import '../theme/app_colors.dart';
import 'workout_screen.dart';
import 'body_status_screen.dart';
import 'my_routines_screen.dart';
import 'progress_screen.dart';
import 'nutrition_screen.dart';
import 'hydration_settings_screen.dart';
import 'routine_editor_screen.dart';
import 'somatotype_info_screen.dart';
import 'exercise_library_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserProfile? _currentUser;
  WeeklyRoutine? _currentRoutine;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDataAndApplyProgression();
  }

  Future<void> _loadDataAndApplyProgression() async {
    final userBox = Hive.box<UserProfile>('userBox');
    _currentUser = userBox.get('currentUser');

    _currentRoutine = RoutineRepository.getActiveRoutine();

    if (_currentUser != null && _currentRoutine != null) {
      await ProgressiveOverloadService.applyProgressiveOverload(
        _currentUser!,
        _currentRoutine!,
      );
      _currentRoutine = RoutineRepository.getActiveRoutine();
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            // --- CORRECCIÓN DE NOMBRE DE ARCHIVO AQUÍ ---
            Image.asset(
              'assets/logo/logo_icon.png', // Antes decía .png.png
              height: 30,
              errorBuilder: (c, e, s) => const Icon(Icons.fitness_center, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            const Text('GYM SCIENTIFIC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.0)),
          ],
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (c) => const SomatotypeInfoScreen()));
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeCard(_currentUser),
                  const SizedBox(height: 25),
                  
                  const Text("HERRAMIENTAS", style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.5)),
                  const SizedBox(height: 10),
                  _buildToolsGrid(context),
                  
                  const SizedBox(height: 25),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("TU PLAN DE HOY", style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.5)),
                      if (_currentRoutine != null)
                        TextButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => RoutineEditorScreen(routine: _currentRoutine)),
                            );
                            _loadDataAndApplyProgression();
                          },
                          child: const Text("Editar Plan", style: TextStyle(color: AppColors.primary)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_currentRoutine != null)
                    _buildRoutineList(context, _currentRoutine!)
                  else
                    _buildEmptyRoutineState(context),
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeCard(UserProfile? user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF2E86C1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hola, ${user?.name ?? "Atleta"}',
            style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          const Text(
            "Prepárate para entrenar con base científica.",
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsGrid(BuildContext context) {
    final tools = [
      {'icon': Icons.menu_book, 'label': 'Ejercicios', 'route': const ExerciseLibraryScreen(), 'color': Colors.orange},
      {'icon': Icons.list_alt, 'label': 'Rutinas', 'route': const MyRoutinesScreen(), 'color': Colors.purple},
      {'icon': Icons.show_chart, 'label': 'Progreso', 'route': const ProgressScreen(), 'color': Colors.green},
      {'icon': Icons.accessibility_new, 'label': 'Fatiga', 'route': const BodyStatusScreen(), 'color': Colors.redAccent},
      {'icon': Icons.restaurant_menu, 'label': 'Nutrición', 'route': const NutritionScreen(), 'color': Colors.teal},
      {'icon': Icons.water_drop, 'label': 'Hidratación', 'route': const HydrationSettingsScreen(), 'color': Colors.blue},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tools.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        final tool = tools[index];
        return Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (c) => tool['route'] as Widget));
              if (tool['label'] == 'Rutinas') _loadDataAndApplyProgression();
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(tool['icon'] as IconData, color: tool['color'] as Color, size: 28),
                const SizedBox(height: 8),
                Text(
                  tool['label'] as String,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoutineList(BuildContext context, WeeklyRoutine routine) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: routine.days.length,
      separatorBuilder: (c, i) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final day = routine.days[index];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Text(day.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text("${day.exercises.length} Ejercicios • ${day.targetMuscles.join(", ")}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
            trailing: const CircleAvatar(
              backgroundColor: AppColors.primary,
              radius: 18,
              child: Icon(Icons.play_arrow, color: Colors.white, size: 20),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => WorkoutScreen(
                    dayName: day.name,
                    routineExercises: day.exercises,
                    routineDayId: day.id,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyRoutineState(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10, style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            const Icon(Icons.fitness_center, size: 50, color: Colors.grey),
            const SizedBox(height: 15),
            const Text("No tienes un plan activo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            const Text("Crea uno o selecciona una plantilla para empezar.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (c) => const MyRoutinesScreen()));
              },
              child: const Text("Ir a Mis Rutinas", style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}