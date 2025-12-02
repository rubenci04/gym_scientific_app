import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Modelos
import 'models/user_model.dart';
import 'models/exercise_model.dart';
import 'models/history_model.dart'; // <--- NUEVO: Importamos el modelo de historial

// Servicios
import 'services/seed_data_service.dart'; // <--- NUEVO: Importamos el servicio de carga de datos

// Pantallas
import 'screens/onboarding_screen.dart'; 
import 'screens/home_screen.dart';       

void main() async {
  // 1. Inicializar Hive para Flutter 
  await Hive.initFlutter();

  // 2. Registrar TODOS los adaptadores (Esquemas de datos)
  // --- Usuario ---
  Hive.registerAdapter(SomatotypeAdapter());
  Hive.registerAdapter(UserProfileAdapter());
  // --- Ejercicios ---
  Hive.registerAdapter(ExerciseAdapter());
  // --- Historial (NUEVOS) ---
  Hive.registerAdapter(WorkoutSetAdapter());      // ID: 3
  Hive.registerAdapter(WorkoutExerciseAdapter()); // ID: 4
  Hive.registerAdapter(WorkoutSessionAdapter());  // ID: 5

  // 3. Abrir las cajas (Boxes) de forma asíncrona
  await Hive.openBox<UserProfile>('userBox');
  await Hive.openBox<Exercise>('exerciseBox');
  await Hive.openBox<WorkoutSession>('historyBox'); // <--- NUEVA CAJA: Aquí se guardarán tus entrenamientos

  // 4. Inicializar Datos Semilla (Seed)
  // Esto llenará la base de datos de ejercicios automáticamente si está vacía
  await SeedDataService.initializeExercises();
  
  runApp(const GymApp());
}

class GymApp extends StatelessWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 5. LÓGICA DE NAVEGACIÓN:
    // Accedemos a la caja de usuarios ya abierta
    final userBox = Hive.box<UserProfile>('userBox');
    
    // Verificamos si existe la clave 'currentUser'
    final bool userExists = userBox.containsKey('currentUser');

    return MaterialApp(
      debugShowCheckedModeBanner: false, // Quitamos la etiqueta "Debug"
      title: 'Gym AI Trainer',
      theme: ThemeData(
        brightness: Brightness.dark, 
        primarySwatch: Colors.blue,
        useMaterial3: true,
        // Personalizamos un poco el estilo de los inputs
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.black12,
        ),
      ),
      // 6. DECISIÓN:
      // Si el usuario existe -> Pantalla Principal (HomeScreen)
      // Si NO existe -> Pantalla de Configuración (OnboardingScreen)
      home: userExists ? const HomeScreen() : const OnboardingScreen(),
    );
  }
}