import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

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
  runZonedGuarded(
    () async {
      bool isInitSuccessful = false;
      String? errorMessage;

      try {
        WidgetsFlutterBinding.ensureInitialized();

        // Configuración de UI del Sistema (Barra transparente)
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark, // Default para fondo claro
            systemNavigationBarColor: AppColors.background,
          ),
        );

        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);

        // 1. Inicializar Hive
        await Hive.initFlutter();
        _registerAdapters();

        // 2. Abrir Cajas (Con sistema de auto-reparación)
        try {
          await _openBoxes();
          
          if (Hive.isBoxOpen('userBox') && Hive.isBoxOpen('settingsBox')) {
            isInitSuccessful = true;
          } else {
            errorMessage = "Error: No se pudieron abrir las bases de datos.";
          }
        } catch (e) {
          errorMessage = "Error crítico de base de datos: $e";
        }

        // 3. Inicializar Servicios Auxiliares (Solo si la BD está OK)
        if (isInitSuccessful) {
          try {
            // Cargar ejercicios base si está vacío
            await SeedDataService.initializeExercises();
            
            // Inicializar Notificaciones (Crea canales en Android)
            await NotificationService.initialize();
            
            debugPrint("🚀 Servicios inicializados correctamente.");
          } catch (e) {
            debugPrint("⚠️ Advertencia en servicios secundarios: $e");
            // No detenemos la app por esto, pero lo logueamos
          }
        }
      } catch (e, stack) {
        debugPrint("❌ CRITICAL ERROR IN MAIN: $e");
        debugPrint(stack.toString());
        errorMessage = e.toString();
        isInitSuccessful = false;
      } finally {
        runApp(
          isInitSuccessful
              ? MultiProvider(
                  providers: [
                    ChangeNotifierProvider(create: (_) => ThemeProvider()),
                  ],
                  child: const GymApp(),
                )
              : ErrorApp(errorMessage: errorMessage),
        );
      }
    },
    (error, stack) {
      debugPrint("💥 Uncaught Flutter error: $error");
      debugPrint(stack.toString());
    },
  );
}

void _registerAdapters() {
  // Registramos todos los adaptadores de Hive
  // Nota: Asegúrate de correr 'flutter packages pub run build_runner build' si cambias modelos
  try {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(SomatotypeAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(UserProfileAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(ExerciseAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(WorkoutSetAdapter());
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(WorkoutExerciseAdapter());
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(WorkoutSessionAdapter());
    if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(TrainingGoalAdapter());
    if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(TrainingLocationAdapter());
    if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(RoutineDayAdapter());
    if (!Hive.isAdapterRegistered(9)) Hive.registerAdapter(WeeklyRoutineAdapter());
    if (!Hive.isAdapterRegistered(10)) Hive.registerAdapter(ExperienceAdapter());
    if (!Hive.isAdapterRegistered(11)) Hive.registerAdapter(RoutineExerciseAdapter());
    if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(HydrationSettingsAdapter());
  } catch (e) {
    debugPrint("⚠️ Error registrando adapters: $e");
  }
}

Future<void> _openBoxes() async {
  // Abrimos todas las cajas necesarias para la app
  await _openBoxSafely<UserProfile>('userBox');
  await _openBoxSafely<Exercise>('exerciseBox');
  await _openBoxSafely<WorkoutSession>('historyBox');
  await _openBoxSafely<WeeklyRoutine>('routineBox');
  await _openBoxSafely<HydrationSettings>('hydrationBox');
  await _openBoxSafely('settingsBox');
}

Future<void> _openBoxSafely<T>(String boxName) async {
  try {
    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox<T>(boxName);
    }
  } catch (e) {
    debugPrint("⚠️ Error abriendo caja '$boxName': $e. Intentando reparar...");
    try {
      await Hive.deleteBoxFromDisk(boxName);
      await Hive.openBox<T>(boxName);
      debugPrint("✅ Caja '$boxName' recreada exitosamente.");
    } catch (e2) {
      debugPrint("❌ Falló la reparación de '$boxName': $e2");
      rethrow;
    }
  }
}

class GymApp extends StatelessWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Verificamos si hay usuario activo
    final userBox = Hive.box<UserProfile>('userBox');
    final bool userExists = userBox.containsKey('currentUser');

    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gym Scientific',
      themeMode: themeProvider.themeMode,
      theme: AppColors.lightTheme, // Usamos los temas centralizados
      darkTheme: AppColors.darkTheme,
      home: userExists ? const HomeScreen() : const OnboardingScreen(),
    );
  }
}

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = true;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() {
    if (Hive.isBoxOpen('settingsBox')) {
      final box = Hive.box('settingsBox');
      _isDarkMode = box.get('isDarkMode', defaultValue: true);
    }
    _updateSystemUI();
  }

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    if (Hive.isBoxOpen('settingsBox')) {
      final box = Hive.box('settingsBox');
      box.put('isDarkMode', _isDarkMode);
    }
    _updateSystemUI();
    notifyListeners();
  }

  void _updateSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: _isDarkMode ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: _isDarkMode ? AppColors.background : const Color(0xFFF5F5F5),
        systemNavigationBarIconBrightness: _isDarkMode ? Brightness.light : Brightness.dark,
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String? errorMessage;
  const ErrorApp({super.key, this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.red.shade900,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 80, color: Colors.white),
                const SizedBox(height: 20),
                const Text(
                  "Error de Inicialización",
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  errorMessage ?? "Error desconocido.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => SystemNavigator.pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red),
                  child: const Text("Salir de la App"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}