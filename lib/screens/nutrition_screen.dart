import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../theme/app_colors.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  UserProfile? _user;
  double _waterIntake = 0;
  final double _waterGoal = 3.0; // Litros por defecto

  @override
  void initState() {
    super.initState();
    final box = Hive.box<UserProfile>('userBox');
    _user = box.get('currentUser');
    _calculateNutrition();
  }

  void _calculateNutrition() {
    if (_user == null) return;

    // Mifflin-St Jeor
    double bmr;
    if (_user!.gender == 'Masculino') {
      bmr =
          (10 * _user!.weight) + (6.25 * _user!.height) - (5 * _user!.age) + 5;
    } else {
      bmr =
          (10 * _user!.weight) +
          (6.25 * _user!.height) -
          (5 * _user!.age) -
          161;
    }

    // Factor de actividad estimado (moderado por defecto)
    double activityFactor = 1.375;
    if (_user!.daysPerWeek >= 5) activityFactor = 1.55;

    double tdee = bmr * activityFactor;

    // Ajuste por objetivo
    if (_user!.goal == TrainingGoal.weightLoss ||
        _user!.goal == TrainingGoal.generalHealth) {
      // Asumiendo generalHealth como mantenimiento/ligero deficit
      if (_user!.goal == TrainingGoal.weightLoss) tdee -= 500;
    } else if (_user!.goal == TrainingGoal.hypertrophy ||
        _user!.goal == TrainingGoal.strength) {
      tdee += 300;
    }

    // Guardar TDEE actualizado
    _user!.tdee = tdee;
    _user!.save();
  }

  Map<String, double> _getMacros() {
    if (_user == null) return {'P': 0, 'C': 0, 'G': 0};

    double tdee = _user!.tdee;
    double protein, carbs, fats;

    // Ajuste por Somatotipo
    if (_user!.somatotype == Somatotype.ectomorph) {
      // Alto en carbos: 25% P, 55% C, 20% G
      protein = tdee * 0.25 / 4;
      carbs = tdee * 0.55 / 4;
      fats = tdee * 0.20 / 9;
    } else if (_user!.somatotype == Somatotype.endomorph) {
      // Bajo en carbos: 35% P, 25% C, 40% G
      protein = tdee * 0.35 / 4;
      carbs = tdee * 0.25 / 4;
      fats = tdee * 0.40 / 9;
    } else {
      // Mesomorfo (Equilibrado): 30% P, 40% C, 30% G
      protein = tdee * 0.30 / 4;
      carbs = tdee * 0.40 / 4;
      fats = tdee * 0.30 / 9;
    }

    return {'P': protein, 'C': carbs, 'G': fats};
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final macros = _getMacros();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nutrición Científica'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCalorieCard(),
            const SizedBox(height: 20),
            _buildMacroCard(macros),
            const SizedBox(height: 20),
            _buildHydrationCard(),
            const SizedBox(height: 20),
            _buildSupplementsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieCard() {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "OBJETIVO CALÓRICO DIARIO",
              style: TextStyle(color: AppColors.textSecondary),
            ),
            Text(
              "${_user!.tdee.toInt()} kcal",
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Basado en fórmula Mifflin-St Jeor para ${_user!.somatotype.toString().split('.').last}",
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroCard(Map<String, double> macros) {
    return Row(
      children: [
        _buildMacroItem("Proteína", macros['P']!, Colors.blueAccent),
        const SizedBox(width: 10),
        _buildMacroItem("Carbos", macros['C']!, Colors.greenAccent),
        const SizedBox(width: 10),
        _buildMacroItem("Grasas", macros['G']!, Colors.orangeAccent),
      ],
    );
  }

  Widget _buildMacroItem(String label, double amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Color.fromARGB(100, color.red, color.green, color.blue),
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            Text(
              "${amount.toInt()}g",
              style: const TextStyle(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHydrationCard() {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Hidratación",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(Icons.water_drop, color: Colors.blue),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: _waterIntake / _waterGoal,
              color: Colors.blue,
              backgroundColor: Colors.grey.shade800,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${_waterIntake.toStringAsFixed(1)} / $_waterGoal L",
                  style: const TextStyle(color: Colors.white),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blue),
                  onPressed: () => setState(() => _waterIntake += 0.25),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplementsCard() {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Suplementación Recomendada (Evidencia A)",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildSupplementItem(
              "Creatina Monohidrato",
              "5g diarios (post-entreno o cualquier hora). Saturación muscular para energía explosiva.",
            ),
            const Divider(color: Colors.white24),
            _buildSupplementItem(
              "Cafeína",
              "3-6 mg/kg (30-60 min pre-entreno). Reducción de fatiga percibida.",
            ),
            const Divider(color: Colors.white24),
            _buildSupplementItem(
              "Proteína Whey",
              "Solo si no llegas a tus requerimientos de proteína con comida real.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplementItem(String name, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          desc,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}
