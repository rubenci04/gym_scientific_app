import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import 'workout_screen.dart'; // <--- IMPORTANTE: Importamos la nueva pantalla

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Recuperamos el usuario guardado
    final userBox = Hive.box<UserProfile>('userBox');
    final currentUser = userBox.get('currentUser');

    return Scaffold(
      appBar: AppBar(title: const Text('Panel Principal')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¡Hola, ${currentUser?.name}!',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tu Somatotipo detectado es:',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              currentUser?.somatotype.toString().split('.').last.toUpperCase() ?? 'N/A',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 20),
            Text(
              'TDEE (Calorías): ${currentUser?.tdee.toStringAsFixed(0)} kcal',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            
            // --- BOTÓN DE ACCIÓN PRINCIPAL ---
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent, // Color llamativo
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () {
                // Navegamos a la pantalla de entrenamiento
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const WorkoutScreen()),
                );
              }, 
              child: const Text(
                'INICIAR RUTINA DE HOY', 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }
}