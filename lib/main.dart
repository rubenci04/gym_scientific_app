import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Importante para controlar barra de estado y navegación
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart'; // He añadido esto para manejar el estado global (Tema, Rutinas, etc.)

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

        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: AppColors.background,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
        );

        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
        ]);

        await Hive.initFlutter();

        _registerAdapters();

        try {
          await _openBoxes();
          // Solo si _openBoxes no lanza excepción, consideramos éxito parcial
          // Pero _openBoxes ya tiene try-catch interno, así que debemos verificar si las cajas están abiertas
          if (Hive.isBoxOpen('userBox') && Hive.isBoxOpen('settingsBox')) {
            isInitSuccessful = true;
          } else {
            errorMessage = "No se pudieron abrir las bases de datos locales.";
          }
        } catch (e) {
          errorMessage = "Error crítico en base de datos: $e";
        }

        if (isInitSuccessful) {
          try {
            await SeedDataService.initializeExercises();
          } catch (e) {
            debugPrint("⚠️ Error inicializando ejercicios: $e");
          }

          try {
            await NotificationService.initialize();
          } catch (e) {
            debugPrint("⚠️ Error inicializando notificaciones: $e");
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
  try {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(SomatotypeAdapter());
    if (!Hive.isAdapterRegistered(1))
      Hive.registerAdapter(UserProfileAdapter());
    if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(ExerciseAdapter());
    if (!Hive.isAdapterRegistered(3)) Hive.registerAdapter(WorkoutSetAdapter());
    if (!Hive.isAdapterRegistered(4))
      Hive.registerAdapter(WorkoutExerciseAdapter());
    if (!Hive.isAdapterRegistered(5))
      Hive.registerAdapter(WorkoutSessionAdapter());
    if (!Hive.isAdapterRegistered(6))
      Hive.registerAdapter(TrainingGoalAdapter());
    if (!Hive.isAdapterRegistered(7))
      Hive.registerAdapter(TrainingLocationAdapter());
    if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(RoutineDayAdapter());
    if (!Hive.isAdapterRegistered(9))
      Hive.registerAdapter(WeeklyRoutineAdapter());
    if (!Hive.isAdapterRegistered(10))
      Hive.registerAdapter(ExperienceAdapter());
    if (!Hive.isAdapterRegistered(11))
      Hive.registerAdapter(RoutineExerciseAdapter());
    if (!Hive.isAdapterRegistered(12))
      Hive.registerAdapter(HydrationSettingsAdapter());
  } catch (e) {
    debugPrint("⚠️ Error registrando adapters: $e");
  }
}

Future<void> _openBoxes() async {
  await _openBoxSafely<UserProfile>('userBox');
  await _openBoxSafely<Exercise>('exerciseBox');
  await _openBoxSafely<WorkoutSession>('historyBox');
  await _openBoxSafely<WeeklyRoutine>('routineBox');
  await _openBoxSafely<HydrationSettings>('hydrationBox');
  await _openBoxSafely('settingsBox');
}

/// Intenta abrir una caja. Si falla (por datos corruptos o cambios de esquema),
/// la borra y la crea de nuevo limpia. (Self-Healing)
Future<void> _openBoxSafely<T>(String boxName) async {
  try {
    await Hive.openBox<T>(boxName);
  } catch (e) {
    debugPrint("⚠️ Error abriendo caja '$boxName': $e");
    debugPrint("🔥 Intentando reparar (borrar y recrear)...");

    // Paso 1: Intentar borrar (ignorando errores si el archivo ya no existe)
    try {
      await Hive.deleteBoxFromDisk(boxName);
    } catch (e2) {
      debugPrint(
        "⚠️ Advertencia al borrar '$boxName' (posiblemente no existía): $e2",
      );
    }

    // Paso 2: Intentar abrir de nuevo (ahora debería estar limpio)
    try {
      await Hive.openBox<T>(boxName);
      debugPrint("✅ Caja '$boxName' reparada exitosamente.");
    } catch (e3) {
      debugPrint("❌ Falló la reparación final de '$boxName': $e3");
      // Si falla la apertura INCLUSO después de intentar borrar, es fatal.
      rethrow;
    }
  }
}

class GymApp extends StatelessWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Verificación extra de seguridad
    if (!Hive.isBoxOpen('userBox')) {
      return const ErrorApp(errorMessage: "La caja de usuario está cerrada.");
    }

    final userBox = Hive.box<UserProfile>('userBox');
    final bool userExists = userBox.containsKey('currentUser');

    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gym Scientific',
      themeMode: themeProvider.themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        primaryColor: AppColors.primary,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: Colors.white,
          background: Color(0xFFF5F5F5),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
          background: AppColors.background,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
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

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = true;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() {
    if (Hive.isBoxOpen('settingsBox')) {
      final box = Hive.box('settingsBox');
      _isDarkMode = box.get('isDarkMode', defaultValue: true);
    } else {
      _isDarkMode = true; // Default safe
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
        statusBarIconBrightness: _isDarkMode
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarColor: _isDarkMode
            ? AppColors.background
            : const Color(0xFFF5F5F5),
        systemNavigationBarIconBrightness: _isDarkMode
            ? Brightness.light
            : Brightness.dark,
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
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.white),
                const SizedBox(height: 24),
                const Text(
                  "Error de Inicio",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  errorMessage ??
                      "Ocurrió un error desconocido al cargar la aplicación.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    // Cerrar la app para que el usuario la reabra y se reinicie el proceso limpio.
                    SystemNavigator.pop();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text("Salir y Reintentar"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red.shade900,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
