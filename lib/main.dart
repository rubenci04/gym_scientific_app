import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/user_model.dart';
import 'models/exercise_model.dart';

// Importamos las pantallas que creamos en los pasos anteriores
import 'screens/onboarding_screen.dart'; 
import 'screens/home_screen.dart';       

void main() async {
  // 1. Inicializar Hive para Flutter 
  await Hive.initFlutter();

  // 2. Registrar los adaptadores (Esquemas de datos)
  Hive.registerAdapter(SomatotypeAdapter());
  Hive.registerAdapter(UserProfileAdapter());
  Hive.registerAdapter(ExerciseAdapter());

  // 3. Abrir las cajas (Boxes) de forma asíncrona antes de iniciar la UI
  await Hive.openBox<UserProfile>('userBox');
  await Hive.openBox<Exercise>('exerciseBox');
  
  runApp(const GymApp());
}

class GymApp extends StatelessWidget {
  const GymApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 4. LÓGICA DE NAVEGACIÓN:
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
      // 5. DECISIÓN:
      // Si el usuario existe -> Pantalla Principal (HomeScreen)
      // Si NO existe -> Pantalla de Configuración (OnboardingScreen)
      home: userExists ? const HomeScreen() : const OnboardingScreen(),
    );
  }
}