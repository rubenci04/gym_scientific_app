import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Modelos
import 'models/user_model.dart';
import 'models/exercise_model.dart';
import 'models/history_model.dart';
import 'models/routine_model.dart';

// Servicios
import 'services/seed_data_service.dart';

// UI & Theme
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_colors.dart'; // <--- IMPORTANTE

void main() async {
  await Hive.initFlutter();

  // REGISTROS (Adapters)
  Hive.registerAdapter(SomatotypeAdapter()); // 0
  Hive.registerAdapter(UserProfileAdapter()); // 1
  Hive.registerAdapter(ExerciseAdapter()); // 2
  Hive.registerAdapter(WorkoutSetAdapter()); // 3
  Hive.registerAdapter(WorkoutExerciseAdapter()); // 4
  Hive.registerAdapter(WorkoutSessionAdapter()); // 5
  Hive.registerAdapter(TrainingGoalAdapter()); // 6
  Hive.registerAdapter(TrainingLocationAdapter()); // 7
  Hive.registerAdapter(RoutineDayAdapter()); // 8
  Hive.registerAdapter(WeeklyRoutineAdapter()); // 9
  Hive.registerAdapter(ExperienceAdapter()); // 10

  // ABRIR CAJAS
  await Hive.openBox<UserProfile>('userBox');
  await Hive.openBox<Exercise>('exerciseBox');
  await Hive.openBox<WorkoutSession>('historyBox');
  await Hive.openBox<WeeklyRoutine>('routineBox');

  await SeedDataService.initializeExercises();

  runApp(const GymApp());
}

class GymApp extends StatelessWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context) {
    final userBox = Hive.box<UserProfile>('userBox');
    final bool userExists = userBox.containsKey('currentUser');

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gym AI Trainer',
      // --- TEMA PROFESIONAL ---
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        useMaterial3: true,
      ),
      home: userExists ? const HomeScreen() : const OnboardingScreen(),
    );
  }
}
