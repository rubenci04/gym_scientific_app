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
  // Aseguramos que el motor de Flutter esté listo antes de configurar el sistema
  WidgetsFlutterBinding.ensureInitialized();

  // --- CONFIGURACIÓN DE MÁRGENES DEL SISTEMA ---
  // He movido la configuración de estilo dentro del ThemeProvider o del build
  // para que cambie dinámicamente, pero mantengo esta configuración inicial segura.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light, 
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
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
  
  // He añadido esta caja para guardar configuraciones como el Tema Oscuro/Claro
  await Hive.openBox('settingsBox'); 

  await SeedDataService.initializeExercises();
  await NotificationService.initialize();

  // He envuelto la app en un MultiProvider. Esto es vital para "modernizarla".
  // Nos permite tener variables globales inteligentes que actualizan la pantalla
  // cuando cambian (como el tema o las rutinas).
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const GymApp(),
    ),
  );
}

class GymApp extends StatelessWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context) {
    final userBox = Hive.box<UserProfile>('userBox');
    final bool userExists = userBox.containsKey('currentUser');

    // Aquí "escucho" al ThemeProvider. Si cambia el tema, esta parte se reconstruye sola.
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gym Scientific',
      
      // --- MODO DE TEMA DINÁMICO ---
      themeMode: themeProvider.themeMode, 
      
      // TEMA CLARO (Definido por mí para que contraste bien)
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Gris muy claro
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

      // TEMA OSCURO (El original que ya tenías, pulido)
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
        
        // --- ANIMACIONES GLOBALES ---
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

// --- CLASE THEME PROVIDER ---
// He puesto esta clase aquí mismo para facilitarte el copiado, pero conceptualmente
// actúa como el "cerebro" que decide si la app se ve oscura o clara.
class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = true; // Por defecto oscuro

  ThemeProvider() {
    // Al iniciar, leo la memoria (Hive) para ver qué prefería el usuario
    final box = Hive.box('settingsBox');
    _isDarkMode = box.get('isDarkMode', defaultValue: true);
    _updateSystemUI();
  }

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    
    // Guardo la preferencia para la próxima vez
    final box = Hive.box('settingsBox');
    box.put('isDarkMode', _isDarkMode);
    
    _updateSystemUI();
    notifyListeners(); // ¡Aviso a toda la app que repinte!
  }

  // Esto ajusta los iconos de la barra de estado (batería, hora) para que se vean
  // blancos sobre fondo oscuro, o negros sobre fondo claro.
  void _updateSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: _isDarkMode ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: _isDarkMode ? AppColors.background : const Color(0xFFF5F5F5),
      systemNavigationBarIconBrightness: _isDarkMode ? Brightness.light : Brightness.dark,
    ));
  }
}