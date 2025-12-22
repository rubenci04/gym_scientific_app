import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/routine_model.dart';
import '../services/progressive_overload_service.dart';
import '../services/routine_repository.dart';
import '../services/notification_service.dart'; 
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
import 'onboarding_screen.dart'; 

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
    
    // Solicitamos permisos de notificación al inicio
    NotificationService.requestPermissions();
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

  void _logout() async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("¿Cerrar Sesión?", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Se borrarán tus datos de este dispositivo para que otra persona pueda usarlo.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Cerrar Sesión", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      final userBox = Hive.box<UserProfile>('userBox');
      await userBox.delete('currentUser');

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    
                    // --- CABECERA PERSONALIZADA ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Logo pequeño y nombre de la App
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Image.asset(
                                // CORRECCIÓN: Usamos el logo principal grande (app_logo.png)
                                // Nota: Mantengo la extensión doble .png.png si así está en tus assets,
                                // si lo renombraste, cambia esto a 'assets/logo/app_logo.png'
                                'assets/logo/app_logo.png.png',
                                height: 40, // Aumentado ligeramente para que se vea bien
                                errorBuilder: (c, e, s) => const Icon(Icons.fitness_center, color: AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'GYM SCIENTIFIC',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        // Botón de Logout
                        IconButton(
                          onPressed: _logout,
                          icon: const Icon(Icons.logout_rounded, color: Colors.white54),
                          tooltip: "Cerrar Sesión",
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    // --- TARJETA DE BIENVENIDA ---
                    _buildWelcomeCard(_currentUser),
                    
                    const SizedBox(height: 30),

                    // --- SECCIÓN DE HERRAMIENTAS ---
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "HERRAMIENTAS",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildToolsGrid(context),

                    const SizedBox(height: 30),

                    // --- SECCIÓN DE RUTINA ACTIVA ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "TU PLAN DE HOY",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_currentRoutine != null)
                          GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RoutineEditorScreen(
                                    routine: _currentRoutine!,
                                  ),
                                ),
                              );
                              _loadDataAndApplyProgression();
                            },
                            child: const Text(
                              "Editar Plan",
                              style: TextStyle(
                                color: AppColors.primary, 
                                fontWeight: FontWeight.bold,
                                fontSize: 14
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    
                    if (_currentRoutine != null)
                      _buildRoutineList(context, _currentRoutine!)
                    else
                      _buildEmptyRoutineState(context),
                      
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeCard(UserProfile? user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF2E86C1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, ${user?.name ?? "Atleta"}',
                      style: const TextStyle(
                        fontSize: 26,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Tu entrenamiento, respaldado por ciencia.",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const SomatotypeInfoScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person, color: Colors.white),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolsGrid(BuildContext context) {
    final tools = [
      {
        'icon': Icons.menu_book,
        'label': 'Ejercicios',
        'route': const ExerciseLibraryScreen(),
        'color': Colors.orange,
      },
      {
        'icon': Icons.list_alt,
        'label': 'Rutinas',
        'route': const MyRoutinesScreen(),
        'color': Colors.purple,
      },
      {
        'icon': Icons.show_chart,
        'label': 'Progreso',
        'route': const ProgressScreen(),
        'color': Colors.green,
      },
      {
        'icon': Icons.accessibility_new,
        'label': 'Fatiga',
        'route': const BodyStatusScreen(),
        'color': Colors.redAccent,
      },
      {
        'icon': Icons.restaurant_menu,
        'label': 'Nutrición',
        'route': const NutritionScreen(),
        'color': Colors.teal,
      },
      {
        'icon': Icons.water_drop,
        'label': 'Hidratación',
        'route': const HydrationSettingsScreen(),
        'color': Colors.blue,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tools.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.1,
      ),
      itemBuilder: (context, index) {
        final tool = tools[index];
        return Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (c) => tool['route'] as Widget),
              );
              if (tool['label'] == 'Rutinas') _loadDataAndApplyProgression();
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (tool['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    tool['icon'] as IconData,
                    color: tool['color'] as Color,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  tool['label'] as String,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
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
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.03)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            title: Text(
              day.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Text(
                "${day.exercises.length} Ejercicios • Enfoque: ${day.targetMuscles.join(", ")}",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => WorkoutScreen(
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
            const Text(
              "No tienes un plan activo",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              "Crea uno nuevo o selecciona una plantilla.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => const MyRoutinesScreen()),
                );
              },
              child: const Text(
                "Ir a Mis Rutinas",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }
}