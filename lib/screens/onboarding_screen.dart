import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import 'goal_selection_screen.dart'; // <--- IMPORTANTE: Importamos la pantalla de objetivos

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _wristController = TextEditingController();
  final TextEditingController _ankleController = TextEditingController();
  
  String _gender = 'Masculino';

  Somatotype _calculateSomatotype(double bmi, double wrist, double height) {
    double rIndex = height / wrist;
    if (bmi < 19 && rIndex > 10.4) {
      return Somatotype.ectomorph; 
    } else if (bmi > 25 && rIndex < 9.6) {
      return Somatotype.endomorph; 
    } else {
      return Somatotype.mesomorph;
    }
  }

  void _saveAndContinue() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final age = int.parse(_ageController.text);
      final weight = double.parse(_weightController.text);
      final height = double.parse(_heightController.text);
      final wrist = double.parse(_wristController.text);
      final ankle = double.parse(_ankleController.text);

      final bmi = weight / ((height / 100) * (height / 100));
      
      double bmr;
      if (_gender == 'Masculino') {
        bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
      } else {
        bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
      }
      final tdee = bmr * 1.2; 

      final somatotype = _calculateSomatotype(bmi, wrist, height);

      final newUser = UserProfile(
        name: name,
        age: age,
        weight: weight,
        height: height,
        gender: _gender,
        wristCircumference: wrist,
        ankleCircumference: ankle,
        somatotype: somatotype,
        tdee: tdee,
      );

      final userBox = Hive.box<UserProfile>('userBox');
      await userBox.put('currentUser', newUser); 

      // --- CAMBIO CLAVE: Vamos a Selección de Objetivos ---
      if (mounted) {
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => const GoalSelectionScreen())
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración de Perfil')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text('Datos Biométricos', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Edad', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _gender,
                      items: ['Masculino', 'Femenino'].map((String val) {
                        return DropdownMenuItem(value: val, child: Text(val));
                      }).toList(),
                      onChanged: (val) => setState(() => _gender = val!),
                      decoration: const InputDecoration(labelText: 'Sexo', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Peso (kg)', border: OutlineInputBorder(), suffixText: 'kg'),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Altura (cm)', border: OutlineInputBorder(), suffixText: 'cm'),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Estructura Ósea (Estimación)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextFormField(
                controller: _wristController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Circunferencia Muñeca (cm)', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _ankleController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Circunferencia Tobillo (cm)', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _saveAndContinue,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blueAccent,
                ),
                child: const Text('CALCULAR MI PLAN Y CONTINUAR', style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}