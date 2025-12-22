import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importante para controlar barra de estado y navegación
import 'package:hive_flutter/hive_flutter.dart';

// Modelos
import 'models/user_model.dart';
import 'models/exercise_model.dart';
import 'models/history_model.dart';
import 'models/routine_model.dart';
import 'models/hydration_settings_model.dart';

// Servicios
import 'services/seed_data_service.dart';
import 'services/notification_service.dart';

// UI & Theme
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'theme/app_colors.dart';

void main() async {
  // Aseguramos que el motor de Flutter esté listo antes de configurar el sistema
  WidgetsFlutterBinding.ensureInitialized();

  // --- CONFIGURACIÓN DE MÁRGENES DEL SISTEMA ---
  // Esto hace que la barra de arriba (hora/batería) sea transparente
  // y la de abajo (botones android) tenga el color de la app.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, 
    statusBarIconBrightness: Brightness.light, // Iconos blancos
    systemNavigationBarColor: AppColors.background, // Fondo barra inferior
    systemNavigationBarIconBrightness: Brightness.light, // Iconos blancos
  ));

  // Bloqueamos la orientación vertical (mejor experiencia para apps de gym)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

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
  Hive.registerAdapter(RoutineExerciseAdapter()); // 11
  Hive.registerAdapter(HydrationSettingsAdapter()); // 12

  // ABRIR CAJAS
  await Hive.openBox<UserProfile>('userBox');
  await Hive.openBox<Exercise>('exerciseBox');
  await Hive.openBox<WorkoutSession>('historyBox');
  await Hive.openBox<WeeklyRoutine>('routineBox');
  await Hive.openBox<HydrationSettings>('hydrationBox');

  await SeedDataService.initializeExercises();
  await NotificationService.initialize();

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
      title: 'Gym Scientific', // <--- NOMBRE ACTUALIZADO
      
      // --- TEMA PROFESIONAL ---
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          background: AppColors.background,
        ),
        
        // --- ANIMACIONES GLOBALES ---
        // Esto activa las transiciones suaves al cambiar de pantalla
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(), // Efecto Zoom suave
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(), // Efecto Deslizamiento iOS
          },
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          elevation: 0,
          centerTitle: true,
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