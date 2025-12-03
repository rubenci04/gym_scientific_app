import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../services/routine_generator_service.dart';
import 'home_screen.dart';

class GoalSelectionScreen extends StatefulWidget {
  const GoalSelectionScreen({super.key});

  @override
  State<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends State<GoalSelectionScreen> {
  TrainingGoal _selectedGoal = TrainingGoal.generalHealth;
  TrainingLocation _selectedLocation = TrainingLocation.gym;
  double _daysPerWeek = 3;
  bool _isLoading = false;

  void _generateRoutine() async {
    setState(() => _isLoading = true);

    final userBox = Hive.box<UserProfile>('userBox');
    final currentUser = userBox.get('currentUser');

    if (currentUser != null) {
      currentUser.goal = _selectedGoal;
      currentUser.location = _selectedLocation;
      currentUser.daysPerWeek = _daysPerWeek.round();
      await currentUser.save(); 
      
      await RoutineGeneratorService.generateAndSaveRoutine(currentUser);

      if (mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const HomeScreen())
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diseña tu Plan')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('¿Dónde vas a entrenar?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              // Usamos Chips simples para máxima compatibilidad
              Wrap(
                spacing: 10,
                children: [
                  ChoiceChip(
                    label: const Text('Gimnasio'),
                    selected: _selectedLocation == TrainingLocation.gym,
                    onSelected: (selected) => setState(() => _selectedLocation = TrainingLocation.gym),
                  ),
                  ChoiceChip(
                    label: const Text('Casa'),
                    selected: _selectedLocation == TrainingLocation.home,
                    onSelected: (selected) => setState(() => _selectedLocation = TrainingLocation.home),
                  ),
                ],
              ),
              
              const SizedBox(height: 30),
              
              const Text('¿Cuál es tu objetivo?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              DropdownButtonFormField<TrainingGoal>(
                initialValue: _selectedGoal,
                items: const [
                  DropdownMenuItem(value: TrainingGoal.hypertrophy, child: Text('Ganar Músculo')),
                  DropdownMenuItem(value: TrainingGoal.weightLoss, child: Text('Perder Grasa')),
                  DropdownMenuItem(value: TrainingGoal.strength, child: Text('Ganar Fuerza')),
                  DropdownMenuItem(value: TrainingGoal.generalHealth, child: Text('Salud')),
                ], 
                onChanged: (val) => setState(() => _selectedGoal = val!),
              ),

              const SizedBox(height: 30),

              Text('Días por semana: ${_daysPerWeek.round()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Slider(
                value: _daysPerWeek,
                min: 2,
                max: 5,
                divisions: 3,
                label: _daysPerWeek.round().toString(),
                onChanged: (val) => setState(() => _daysPerWeek = val),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _generateRoutine,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(18),
                    backgroundColor: Colors.blueAccent,
                  ), 
                  child: const Text('CREAR RUTINA INTELIGENTE', style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              )
            ],
          ),
        ),
    );
  }
}