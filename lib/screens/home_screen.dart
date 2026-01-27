import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../main.dart';
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
    NotificationService.requestPermissions();
  }

  Future<void> _loadDataAndApplyProgression() async {
    if (!Hive.isBoxOpen('userBox')) await Hive.openBox<UserProfile>('userBox');

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

  String _getLanguage() {
    if (!Hive.isBoxOpen('settingsBox')) return 'es';
    return Hive.box('settingsBox').get('language', defaultValue: 'es');
  }

  void _toggleLanguage() async {
    if (!Hive.isBoxOpen('settingsBox')) await Hive.openBox('settingsBox');
    final box = Hive.box('settingsBox');
    final current = box.get('language', defaultValue: 'es');
    box.put('language', current == 'es' ? 'en' : 'es');
  }

  Map<String, String> _getTexts(String lang) {
    if (lang == 'en') {
      return {
        'welcome': 'Hello',
        'subtitle': 'Your training, backed by science.',
        'tools': 'TOOLS',
        'today_plan': 'YOUR PLAN TODAY',
        'edit_plan': 'Edit Plan',
        'no_plan': 'No active plan',
        'no_plan_sub': 'Create a new one or select a template.',
        'go_routines': 'Go to My Routines',
        'logout_title': 'Log Out?',
        'logout_msg': 'Your data will be removed from this device.',
        'cancel': 'Cancel',
        'logout': 'Log Out',
        'exercises': 'Exercises',
        'focus': 'Focus',
      };
    }
    return {
      'welcome': 'Hola',
      'subtitle': 'Tu entrenamiento, respaldado por ciencia.',
      'tools': 'HERRAMIENTAS',
      'today_plan': 'TU PLAN DE HOY',
      'edit_plan': 'Editar Plan',
      'no_plan': 'No tienes un plan activo',
      'no_plan_sub': 'Crea uno nuevo o selecciona una plantilla.',
      'go_routines': 'Ir a Mis Rutinas',
      'logout_title': '¿Cerrar Sesión?',
      'logout_msg': 'Se borrarán tus datos de este dispositivo.',
      'cancel': 'Cancelar',
      'logout': 'Cerrar Sesión',
      'exercises': 'Ejercicios',
      'focus': 'Enfoque',
    };
  }

  void _logout(String lang) async {
    final theme = Theme.of(context);
    final texts = _getTexts(lang);

    bool confirm =
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: theme.cardColor,
            title: Text(texts['logout_title']!),
            content: Text(texts['logout_msg']!),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(texts['cancel']!),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  texts['logout']!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

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
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return ValueListenableBuilder(
      valueListenable: Hive.box('settingsBox').listenable(keys: ['language']),
      builder: (context, Box box, _) {
        final String lang = box.get('language', defaultValue: 'es');
        final texts = _getTexts(lang);

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: Column(
                      children: [
                        // HEADER
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.fitness_center,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'GYM SCIENTIFIC',
                                  style: theme.textTheme.titleLarge,
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.language),
                                  onPressed: _toggleLanguage,
                                ),
                                IconButton(
                                  icon: Icon(
                                    isDark ? Icons.light_mode : Icons.dark_mode,
                                  ),
                                  onPressed: themeProvider.toggleTheme,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.logout),
                                  onPressed: () => _logout(lang),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // WELCOME
                        _buildWelcomeCard(_currentUser, texts),
                        const SizedBox(height: 20),

                        // TOOLS
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            texts['tools']!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildToolsGrid(context, theme, lang),
                        const SizedBox(height: 20),

                        // PLAN
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              texts['today_plan']!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_currentRoutine != null)
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RoutineEditorScreen(
                                        routine: _currentRoutine!,
                                      ),
                                    ),
                                  );
                                },
                                child: Text(texts['edit_plan']!),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        if (_currentRoutine != null)
                          _buildRoutineList(
                            context,
                            _currentRoutine!,
                            theme,
                            texts,
                          )
                        else
                          _buildEmptyRoutineState(context, theme, texts),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildWelcomeCard(UserProfile? user, Map<String, String> texts) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${texts['welcome']}, ${user?.name ?? "User"}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            texts['subtitle']!,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsGrid(BuildContext context, ThemeData theme, String lang) {
    // Definimos nombres directos para evitar líos con el mapa
    final items = [
      {
        'icon': Icons.menu_book,
        'text': lang == 'es' ? 'Ejercicios' : 'Exercises',
        'page': const ExerciseLibraryScreen(),
        'color': Colors.orange,
      },
      {
        'icon': Icons.list_alt,
        'text': lang == 'es' ? 'Rutinas' : 'Routines',
        'page': const MyRoutinesScreen(),
        'color': Colors.purple,
      },
      {
        'icon': Icons.show_chart,
        'text': lang == 'es' ? 'Progreso' : 'Progress',
        'page': const ProgressScreen(),
        'color': Colors.green,
      },
      {
        'icon': Icons.accessibility_new,
        'text': lang == 'es' ? 'Fatiga' : 'Fatigue',
        'page': const BodyStatusScreen(),
        'color': Colors.red,
      },
      {
        'icon': Icons.restaurant,
        'text': lang == 'es' ? 'Nutrición' : 'Nutrition',
        'page': const NutritionScreen(),
        'color': Colors.teal,
      },
      {
        'icon': Icons.water_drop,
        'text': lang == 'es' ? 'Hidratación' : 'Hydration',
        'page': const HydrationSettingsScreen(),
        'color': Colors.blue,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.1,
      ),
      itemCount: items.length,
      itemBuilder: (c, i) {
        final item = items[i];
        return Card(
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => item['page'] as Widget),
              );
              if (item['text'].toString().contains('Rutin'))
                _loadDataAndApplyProgression();
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item['icon'] as IconData, color: item['color'] as Color),
                const SizedBox(height: 5),
                Text(
                  item['text'] as String,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoutineList(
    BuildContext context,
    WeeklyRoutine routine,
    ThemeData theme,
    Map<String, String> texts,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: routine.days.length,
      itemBuilder: (context, index) {
        final day = routine.days[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            title: Text(
              day.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "${day.exercises.length} ${texts['exercises']} - ${texts['focus']}: ${day.targetMuscles.join(', ')}",
            ),
            trailing: const Icon(Icons.play_arrow, color: AppColors.primary),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkoutScreen(
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

  Widget _buildEmptyRoutineState(
    BuildContext context,
    ThemeData theme,
    Map<String, String> texts,
  ) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.fitness_center, size: 40, color: Colors.grey),
          const SizedBox(height: 10),
          Text(
            texts['no_plan']!,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            texts['no_plan_sub']!,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyRoutinesScreen()),
            ),
            child: Text(texts['go_routines']!),
          ),
        ],
      ),
    );
  }
}
