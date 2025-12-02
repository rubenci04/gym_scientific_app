import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';

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
            Text('¡Hola, ${currentUser?.name}!'),
            const SizedBox(height: 10),
            Text(
              'Tu Somatotipo detectado es:',
              style: TextStyle(fontSize: 18),
            ),
            Text(
              currentUser?.somatotype.toString().split('.').last.toUpperCase() ?? 'N/A',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 20),
            Text('TDEE (Calorías): ${currentUser?.tdee.toStringAsFixed(0)} kcal'),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {}, 
              child: const Text('Ver mi Rutina (Próximamente)')
            )
          ],
        ),
      ),
    );
  }
}