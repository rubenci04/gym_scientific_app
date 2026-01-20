import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // Para ThemeProvider
import '../models/user_model.dart';
import '../theme/app_colors.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  // Datos del día actual
  double _eatenCalories = 0;
  double _eatenProtein = 0;
  double _eatenCarbs = 0;
  double _eatenFat = 0;
  double _waterIntake = 0;
  final double _waterGoal = 3.0;

  late Box _dailyBox;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initDailyTracking();
  }

  Future<void> _initDailyTracking() async {
    // Abrimos una caja ligera para guardar el progreso diario
    _dailyBox = await Hive.openBox('dailyTrackingBox');
    _loadTodayData();
    setState(() => _isLoading = false);
  }

  void _loadTodayData() {
    // Usamos la fecha como clave para reiniciar cada día automáticamente
    final todayKey = _getTodayKey();
    
    // Si ya hay datos de hoy, los cargamos. Si no, ceros.
    final data = _dailyBox.get(todayKey, defaultValue: {
      'cals': 0.0,
      'prot': 0.0,
      'carbs': 0.0,
      'fat': 0.0,
      'water': 0.0,
    });

    // Convertimos dynamic a tipos seguros
    if (data is Map) {
      setState(() {
        _eatenCalories = (data['cals'] ?? 0.0) as double;
        _eatenProtein = (data['prot'] ?? 0.0) as double;
        _eatenCarbs = (data['carbs'] ?? 0.0) as double;
        _eatenFat = (data['fat'] ?? 0.0) as double;
        _waterIntake = (data['water'] ?? 0.0) as double;
      });
    }
  }

  void _saveData() {
    final todayKey = _getTodayKey();
    _dailyBox.put(todayKey, {
      'cals': _eatenCalories,
      'prot': _eatenProtein,
      'carbs': _eatenCarbs,
      'fat': _eatenFat,
      'water': _waterIntake,
    });
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month}-${now.day}";
  }

  void _addFood(String name, double cals, double p, double c, double f) {
    setState(() {
      _eatenCalories += cals;
      _eatenProtein += p;
      _eatenCarbs += c;
      _eatenFat += f;
    });
    _saveData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Añadido: $name (+${cals.toInt()} kcal)"),
        duration: const Duration(milliseconds: 1500),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      )
    );
  }

  void _showAddCustomFoodDialog(BuildContext context, ThemeData theme) {
    final nameCtrl = TextEditingController();
    final calsCtrl = TextEditingController();
    final protCtrl = TextEditingController();
    final carbsCtrl = TextEditingController();
    final fatCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text("Agregar Comida Manual", style: theme.textTheme.titleLarge),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: theme.textTheme.bodyMedium,
                decoration: const InputDecoration(labelText: "Nombre (ej: Manzana)"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: calsCtrl,
                keyboardType: TextInputType.number,
                style: theme.textTheme.bodyMedium,
                decoration: const InputDecoration(labelText: "Calorías (kcal)"),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(controller: protCtrl, keyboardType: TextInputType.number, style: theme.textTheme.bodyMedium, decoration: const InputDecoration(labelText: "Prot (g)"))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: carbsCtrl, keyboardType: TextInputType.number, style: theme.textTheme.bodyMedium, decoration: const InputDecoration(labelText: "Carb (g)"))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: fatCtrl, keyboardType: TextInputType.number, style: theme.textTheme.bodyMedium, decoration: const InputDecoration(labelText: "Grasa (g)"))),
                ],
              )
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            onPressed: () {
              if (nameCtrl.text.isEmpty || calsCtrl.text.isEmpty) return;
              _addFood(
                nameCtrl.text,
                double.tryParse(calsCtrl.text) ?? 0,
                double.tryParse(protCtrl.text) ?? 0,
                double.tryParse(carbsCtrl.text) ?? 0,
                double.tryParse(fatCtrl.text) ?? 0,
              );
              Navigator.pop(ctx);
            },
            child: const Text("Agregar"),
          )
        ],
      ),
    );
  }

  // Base de datos local de comidas comunes para selección rápida
  final Map<String, List<Map<String, dynamic>>> _foodDatabase = {
    "Desayuno / Merienda": [
      {'name': "Yogur, cereales y fruta", 'kcal': 250, 'p': 10, 'c': 40, 'f': 5},
      {'name': "Panqueques avena/banana", 'kcal': 300, 'p': 15, 'c': 45, 'f': 8},
      {'name': "Tostadas pan francés c/mermelada", 'kcal': 280, 'p': 6, 'c': 55, 'f': 4},
      {'name': "Licuado banana c/leche", 'kcal': 320, 'p': 12, 'c': 50, 'f': 8},
      {'name': "Huevos revueltos (2) c/tomate", 'kcal': 220, 'p': 14, 'c': 5, 'f': 15},
      {'name': "Tostadas c/queso y dulce", 'kcal': 260, 'p': 8, 'c': 40, 'f': 9},
      {'name': "Bowl avena y manzana", 'kcal': 300, 'p': 10, 'c': 50, 'f': 6},
      {'name': "Tostada integral palta/huevo", 'kcal': 350, 'p': 12, 'c': 30, 'f': 20},
      {'name': "Sandwich queso y tomate", 'kcal': 300, 'p': 12, 'c': 35, 'f': 12},
      {'name': "Scoop Whey Protein", 'kcal': 120, 'p': 24, 'c': 3, 'f': 1},
      {'name': "Café con leche", 'kcal': 100, 'p': 5, 'c': 8, 'f': 4},
    ],
    "Almuerzo (Comidas)": [
      {'name': "Guiso arroz c/pollo", 'kcal': 450, 'p': 25, 'c': 60, 'f': 10},
      {'name': "Milanesa al horno c/ensalada", 'kcal': 400, 'p': 30, 'c': 20, 'f': 18},
      {'name': "Fideos con tuco", 'kcal': 480, 'p': 15, 'c': 80, 'f': 10},
      {'name': "Tarta atún (2 porciones)", 'kcal': 380, 'p': 20, 'c': 35, 'f': 18},
      {'name': "Pastel de papas", 'kcal': 500, 'p': 25, 'c': 50, 'f': 20},
      {'name': "Polenta con salsa y queso", 'kcal': 420, 'p': 12, 'c': 70, 'f': 12},
      {'name': "Bife a la criolla c/arroz", 'kcal': 450, 'p': 35, 'c': 40, 'f': 15},
      {'name': "Zapallitos rellenos (2)", 'kcal': 300, 'p': 18, 'c': 20, 'f': 15},
      {'name': "Albóndigas con puré", 'kcal': 480, 'p': 25, 'c': 50, 'f': 20},
      {'name': "Filet merluza c/puré", 'kcal': 350, 'p': 25, 'c': 30, 'f': 8},
      {'name': "Pechuga de pollo (200g)", 'kcal': 220, 'p': 46, 'c': 0, 'f': 4},
      {'name': "Arroz blanco (taza cocida)", 'kcal': 200, 'p': 4, 'c': 44, 'f': 0},
    ],
    "Cena (Ligera)": [
      {'name': "Omelette 2 huevos y queso", 'kcal': 320, 'p': 18, 'c': 2, 'f': 22},
      {'name': "Ensalada completa (atún/huevo)", 'kcal': 280, 'p': 20, 'c': 15, 'f': 12},
      {'name': "Sopa verduras c/fideos", 'kcal': 150, 'p': 5, 'c': 25, 'f': 3},
      {'name': "Tarta acelga (2 porciones)", 'kcal': 250, 'p': 10, 'c': 25, 'f': 12},
      {'name': "Revuelto zapallitos", 'kcal': 200, 'p': 12, 'c': 10, 'f': 10},
      {'name': "Pechuga plancha c/tomate", 'kcal': 250, 'p': 30, 'c': 5, 'f': 5},
      {'name': "Empanadas (2 unidades)", 'kcal': 500, 'p': 15, 'c': 40, 'f': 25},
      {'name': "Berenjenas napolitana", 'kcal': 300, 'p': 10, 'c': 15, 'f': 18},
      {'name': "Hamburguesa lentejas", 'kcal': 350, 'p': 15, 'c': 40, 'f': 10},
    ]
  };

  UserProfile _calculateNutrition(UserProfile user) {
    // Recalculamos TDEE al vuelo por si cambió el peso
    double bmr;
    if (user.gender == 'Masculino') {
      bmr = (10 * user.weight) + (6.25 * user.height) - (5 * user.age) + 5;
    } else {
      bmr = (10 * user.weight) + (6.25 * user.height) - (5 * user.age) - 161;
    }

    double activityFactor = 1.375;
    if (user.daysPerWeek >= 5) activityFactor = 1.55;

    double tdee = bmr * activityFactor;

    if (user.goal == TrainingGoal.weightLoss) tdee -= 500;
    if (user.goal == TrainingGoal.hypertrophy) tdee += 300;

    // Solo actualizamos el modelo en memoria para mostrar, no guardamos en DB aquí para evitar loops
    user.tdee = tdee;
    return user;
  }

  Map<String, double> _getMacros(UserProfile user) {
    double tdee = user.tdee;
    double protein, carbs, fats;

    if (user.somatotype == Somatotype.ectomorph) {
      protein = tdee * 0.25 / 4;
      carbs = tdee * 0.55 / 4;
      fats = tdee * 0.20 / 9;
    } else if (user.somatotype == Somatotype.endomorph) {
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
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Nutrición & Tracking', style: theme.appBarTheme.titleTextStyle),
        backgroundColor: theme.appBarTheme.backgroundColor,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: isDark ? Colors.orange : Colors.indigo),
            onPressed: themeProvider.toggleTheme,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCustomFoodDialog(context, theme),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Comida Manual", style: TextStyle(color: Colors.white)),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<UserProfile>('userBox').listenable(),
        builder: (context, Box<UserProfile> box, _) {
          final user = box.get('currentUser');
          if (user == null) return const Center(child: CircularProgressIndicator());

          final updatedUser = _calculateNutrition(user);
          final macrosGoal = _getMacros(updatedUser);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Resumen de Hoy (Tracking)
                _buildTrackingCard(updatedUser, macrosGoal, theme),
                const SizedBox(height: 20),

                // 2. Hidratación
                _buildHydrationCard(theme),
                const SizedBox(height: 20),

                // 3. Menú Interactivo
                Text("Menú Rápido (Toca para agregar):", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildMenuInteractible(theme),
                
                const SizedBox(height: 80), // Espacio para el FAB
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildTrackingCard(UserProfile user, Map<String, double> goals, ThemeData theme) {
    double caloriesProgress = (_eatenCalories / user.tdee).clamp(0.0, 1.0);
    
    return Card(
      color: theme.cardColor,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Resumen Diario", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      _getTodayKey(), // Muestra la fecha simple
                      style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    // Confirmar reinicio
                    showDialog(context: context, builder: (c) => AlertDialog(
                      title: const Text("¿Reiniciar día?"),
                      content: const Text("Se borrarán las comidas de hoy."),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancelar")),
                        TextButton(onPressed: () {
                          setState(() { _eatenCalories=0; _eatenProtein=0; _eatenCarbs=0; _eatenFat=0; _waterIntake=0; });
                          _saveData();
                          Navigator.pop(c);
                        }, child: const Text("Reiniciar", style: TextStyle(color: Colors.red)))
                      ],
                    ));
                  },
                  child: const Text("Reiniciar", style: TextStyle(color: Colors.red)),
                )
              ],
            ),
            const SizedBox(height: 10),
            
            // Círculo de Calorías
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 110, width: 110,
                      child: CircularProgressIndicator(
                        value: caloriesProgress,
                        backgroundColor: theme.dividerColor.withOpacity(0.1),
                        color: caloriesProgress > 1.0 ? Colors.redAccent : AppColors.primary,
                        strokeWidth: 10,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Column(
                      children: [
                        Text("${_eatenCalories.toInt()}", style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                        Text("/ ${user.tdee.toInt()} kcal", style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color)),
                      ],
                    )
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Barras de Macros
            _buildMacroBar("Proteína", _eatenProtein, goals['P']!, Colors.blueAccent, theme),
            _buildMacroBar("Carbos", _eatenCarbs, goals['C']!, Colors.greenAccent, theme),
            _buildMacroBar("Grasas", _eatenFat, goals['G']!, Colors.orangeAccent, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroBar(String label, double current, double goal, Color color, ThemeData theme) {
    double progress = (goal > 0) ? (current / goal).clamp(0.0, 1.0) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              Text("${current.toInt()} / ${goal.toInt()}g", style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.dividerColor.withOpacity(0.1),
              color: color,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuInteractible(ThemeData theme) {
    return Column(
      children: _foodDatabase.entries.map((entry) {
        return Card(
          color: theme.cardColor,
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 10),
          child: ExpansionTile(
            leading: Icon(_getIconForCategory(entry.key), color: AppColors.primary),
            title: Text(entry.key, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            iconColor: AppColors.primary,
            shape: Border.all(color: Colors.transparent),
            children: entry.value.map((food) {
              return ListTile(
                dense: true,
                title: Text(food['name'], style: theme.textTheme.bodyMedium),
                subtitle: Text(
                  "${food['kcal']} kcal | P: ${food['p']} C: ${food['c']} G: ${food['f']}", 
                  style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color)
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                  onPressed: () {
                    _addFood(
                      food['name'], 
                      (food['kcal'] as num).toDouble(), 
                      (food['p'] as num).toDouble(), 
                      (food['c'] as num).toDouble(), 
                      (food['f'] as num).toDouble()
                    );
                  },
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  IconData _getIconForCategory(String category) {
    if (category.contains("Desayuno")) return Icons.wb_sunny_outlined;
    if (category.contains("Almuerzo")) return Icons.lunch_dining;
    return Icons.nights_stay_outlined;
  }

  Widget _buildHydrationCard(ThemeData theme) {
    return Card(
      color: theme.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.water_drop, color: Colors.blue[400]),
                    const SizedBox(width: 8),
                    const Text("Hidratación", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Text("${_waterIntake.toStringAsFixed(1)} / $_waterGoal L", style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: (_waterIntake / _waterGoal).clamp(0.0, 1.0),
              color: Colors.blue,
              backgroundColor: Colors.blue.withOpacity(0.1),
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton.filledTonal(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    setState(() => _waterIntake = (_waterIntake - 0.25).clamp(0.0, 5.0));
                    _saveData();
                  },
                ),
                const Text("- 250ml +"),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: Colors.blue),
                  icon: const Icon(Icons.add, color: Colors.white),
                  onPressed: () {
                    setState(() => _waterIntake += 0.25);
                    _saveData();
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}