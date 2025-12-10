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

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        toolbarHeight: 0, 
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // --- HEADER (LOGO + TEXTO) ---
                    const SizedBox(height: 20),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.surface,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                )
                              ]
                            ),
                            child: Image.asset(
                              // He puesto la ruta con doble extensión para que te funcione ya mismo
                              'assets/logo/logo_icon.png.png', 
                              height: 90, 
                              // Si falla, mostramos un icono de fallback pero intentará cargar tu imagen
                              errorBuilder: (c, e, s) => const Icon(Icons.fitness_center, size: 60, color: AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: 15),
                          const Text(
                            'GYM SCIENTIFIC',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2.5,
                              shadows: [
                                Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 4))
                              ]
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 35),
                    
                    // Tarjeta de Bienvenida
                    _buildWelcomeCard(_currentUser),
                    const SizedBox(height: 30),
                    
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "HERRAMIENTAS", 
                        style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildToolsGrid(context),
                    
                    const SizedBox(height: 30),

                    // Sección Rutina Activa
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "TU PLAN DE HOY", 
                          style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)
                        ),
                        if (_currentRoutine != null)
                          TextButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RoutineEditorScreen(routine: _currentRoutine!),
                                ),
                              );
                              _loadDataAndApplyProgression();
                            },
                            icon: const Icon(Icons.edit, size: 16, color: AppColors.primary),
                            label: const Text("Editar Plan", style: TextStyle(color: AppColors.primary)),
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, ${user?.name ?? "Atleta"}',
                  style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Tu entrenamiento, respaldado por ciencia.",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const SomatotypeInfoScreen())),
              icon: const Icon(Icons.person, color: Colors.white),
              tooltip: "Perfil y Somatotipo",
            ),
          )
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
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (context, index) {
        final tool = tools[index];
        return Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (c) => tool['route'] as Widget));
              if (tool['label'] == 'Rutinas') _loadDataAndApplyProgression();
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (tool['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(tool['icon'] as IconData, color: tool['color'] as Color, size: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  tool['label'] as String,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
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
      separatorBuilder: (c, i) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final day = routine.days[index];
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Text(day.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                "${day.exercises.length} Ejercicios • Enfoque: ${day.targetMuscles.join(", ")}", 
                style: const TextStyle(color: Colors.grey, fontSize: 12)
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow, color: AppColors.primary, size: 24),
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
        margin: const EdgeInsets.only(top: 20),
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            const Icon(Icons.fitness_center, size: 50, color: Colors.grey),
            const SizedBox(height: 15),
            const Text("No tienes un plan activo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 5),
            const Text("Crea uno nuevo o selecciona una plantilla.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12)
              ),
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