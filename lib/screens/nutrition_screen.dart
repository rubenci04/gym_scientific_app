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

    double bmr;
    if (_user!.gender == 'Masculino') {
      bmr = (10 * _user!.weight) + (6.25 * _user!.height) - (5 * _user!.age) + 5;
    } else {
      bmr = (10 * _user!.weight) + (6.25 * _user!.height) - (5 * _user!.age) - 161;
    }

    double activityFactor = 1.375;
    if (_user!.daysPerWeek >= 5) activityFactor = 1.55;

    double tdee = bmr * activityFactor;

    if (_user!.goal == TrainingGoal.weightLoss || _user!.goal == TrainingGoal.generalHealth) {
      if (_user!.goal == TrainingGoal.weightLoss) tdee -= 500;
    } else if (_user!.goal == TrainingGoal.hypertrophy || _user!.goal == TrainingGoal.strength) {
      tdee += 300;
    }

    _user!.tdee = tdee;
    _user!.save();
  }

  Map<String, double> _getMacros() {
    if (_user == null) return {'P': 0, 'C': 0, 'G': 0};

    double tdee = _user!.tdee;
    double protein, carbs, fats;

    if (_user!.somatotype == Somatotype.ectomorph) {
      protein = tdee * 0.25 / 4;
      carbs = tdee * 0.55 / 4;
      fats = tdee * 0.20 / 9;
    } else if (_user!.somatotype == Somatotype.endomorph) {
      protein = tdee * 0.35 / 4;
      carbs = tdee * 0.25 / 4;
      fats = tdee * 0.40 / 9;
    } else {
      protein = tdee * 0.30 / 4;
      carbs = tdee * 0.40 / 4;
      fats = tdee * 0.30 / 9;
    }

    return {'P': protein, 'C': carbs, 'G': fats};
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
            
            _buildMenuTucumano(), 
            
            const SizedBox(height: 20),
            _buildHydrationCard(),
            const SizedBox(height: 20),
            _buildSupplementsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTucumano() {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: const [
                  Icon(Icons.restaurant, color: Colors.orange),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Recetario",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Desayuno
            _buildRecipeExpansionTile(
              "Desayuno / Merienda", 
              Icons.wb_sunny,
              [
                "Yogur con cereales (copos) y fruta de estación. (~250 kcal)",
                "Panqueques de avena y banana. (~300 kcal, 15g prot)",
                "Té con leche y tostadas de pan francés con mermelada. (~280 kcal)",
                "Licuado de banana con leche y un puñado de nueces. (~320 kcal)",
                "Huevos revueltos (2) con tomate y mate. (~220 kcal, 14g prot)",
                "Tostadas con queso crema y dulce de cayote/batata. (~260 kcal)",
                "Bowl de avena cocida con manzana y canela. (~300 kcal)",
                "Tostadas de pan integral con palta y huevo poche. (~350 kcal, 12g prot)",
                "Yogur griego natural con mix de semillas y miel. (~280 kcal, 15g prot)",
                "Sandwich de queso tybo y tomate en pan árabe tostado. (~300 kcal, 12g prot)",
                "Licuado de proteínas (whey) con fruta y agua/leche. (~250 kcal, 25g prot)",
              ]
            ),
            const Divider(color: Colors.white12),
            // Almuerzo
            _buildRecipeExpansionTile(
              "Almuerzo (Energía)", 
              Icons.lunch_dining,
              [
                "Guiso de arroz con pollo. (~450 kcal, 25g prot)",
                "Milanesa con ensalada mixta. (~400 kcal, 30g prot)",
                "Fideos con tuco casero. (~480 kcal)",
                "Tarta de atún o caballa (masa casera). (~380 kcal por porción, 20g prot)",
                "Pastel de papas. (~500 kcal)",
                "Polenta con salsa bolognesa y queso. (~420 kcal)",
                "Salpicón de ave. (~350 kcal, 28g prot)",
                "Bife a la criolla con arroz. (~450 kcal, 35g prot)",
                "Zapallitos rellenos con carne y arroz. (~300 kcal, 18g prot)",
                "Albóndigas de carne con puré. (~480 kcal)",
                "Wok de vegetales con trozos de carne magra o pollo. (~400 kcal, 30g prot)",
                "Filet de merluza al horno con puré de calabaza. (~350 kcal, 25g prot)",
                "Ensalada César con pollo (aderezo ligero). (~380 kcal, 28g prot)",
                "Wrap o Fajitas de pollo con verduras salteadas. (~450 kcal, 25g prot)",
                "Lentejas guisadas con verduras. (~400 kcal, 18g prot)",
              ]
            ),
            const Divider(color: Colors.white12),
            // Cena
            _buildRecipeExpansionTile(
              "Cena (Ligera)", 
              Icons.dinner_dining,
              [
                "Omelette de 2 huevos con queso. (~320 kcal, 18g prot)",
                "Ensalada completa (huevo, atún). (~280 kcal, 20g prot)",
                "Sopa de verduras con fideos. (~150 kcal)",
                "Tarta de acelga o espinaca con huevo. (~250 kcal)",
                "Revuelto de zapallitos verdes y huevo. (~200 kcal)",
                "Pechuga de pollo a la plancha con tomate. (~250 kcal, 30g prot)",
                "Arroz frío con atún y mayonesa. (~350 kcal)",
                "Empanadas de carne o Pollo al Horno (2 unidades). (~500 kcal)",
                "Berenjenas a la napolitana. (~300 kcal)",
                "Humita en olla (plato chico). (~350 kcal)",
                "Tortilla de acelga o espinaca al horno. (~220 kcal)",
                "Filet de pollo al limón con espárragos o chauchas. (~280 kcal, 28g prot)",
                "Ensalada de lentejas frías, tomate y huevo duro. (~320 kcal, 18g prot)",
                "Calabaza rellena con queso y choclo. (~300 kcal)",
                "Hamburguesa de lentejas o carne magra al plato con ensalada. (~350 kcal, 22g prot)",
              ]
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeExpansionTile(String title, IconData icon, List<String> items) {
    return ExpansionTile(
      leading: Icon(icon, color: AppColors.secondary),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      iconColor: AppColors.primary,
      collapsedIconColor: Colors.grey,
      children: items.map((item) => ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        leading: const Icon(Icons.circle, size: 6, color: Colors.white30),
        title: Text(item, style: const TextStyle(color: Colors.white70)),
      )).toList(),
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