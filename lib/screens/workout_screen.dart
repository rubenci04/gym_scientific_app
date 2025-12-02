import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/exercise_model.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  // Accedemos a la caja de ejercicios
  final Box<Exercise> exerciseBox = Hive.box<Exercise>('exerciseBox');

  @override
  Widget build(BuildContext context) {
    // Convertimos los valores de la caja a una lista
    final exercises = exerciseBox.values.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrenamiento Activo'),
        backgroundColor: Colors.blueAccent.shade700,
      ),
      body: exercises.isEmpty
          ? const Center(child: Text("No hay ejercicios cargados. Revisa el Seed."))
          : ListView.builder(
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final exercise = exercises[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueGrey.shade800,
                      child: Text(exercise.name[0], style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(exercise.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${exercise.muscleGroup} • ${exercise.equipment}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Añadido ${exercise.name} a la rutina (Demo)')),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
           // Aquí iría la lógica para finalizar y guardar en el Historial
           Navigator.pop(context);
        },
        child: const Icon(Icons.check),
        backgroundColor: Colors.green,
      ),
    );
  }
}