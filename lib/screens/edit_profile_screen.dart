import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/hydration_settings_model.dart';
import '../theme/app_colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late UserProfile _currentUser;
  bool _isLoading = true;

  // Controladores
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  final _wristController = TextEditingController();
  final _ankleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userBox = Hive.box<UserProfile>('userBox');
    _currentUser = userBox.get('currentUser')!;

    _weightController.text = _currentUser.weight.toString();
    _ageController.text = _currentUser.age.toString();
    _wristController.text = _currentUser.wristCircumference.toString();
    _ankleController.text = _currentUser.ankleCircumference.toString();

    setState(() => _isLoading = false);
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final double newWeight = double.parse(_weightController.text);

    // 1. Crear usuario actualizado (manteniendo los datos que no se editan aquí)
    final updatedUser = UserProfile(
      name: _currentUser.name,
      age: int.parse(_ageController.text),
      weight: newWeight,
      height: _currentUser.height,
      gender: _currentUser.gender,
      daysPerWeek: _currentUser.daysPerWeek,
      goal: _currentUser.goal,
      location: _currentUser.location,
      experience: _currentUser.experience,
      timeAvailable: _currentUser.timeAvailable,
      focusArea: _currentUser.focusArea,
      hasAsymmetry: _currentUser.hasAsymmetry,
      somatotype: _currentUser.somatotype, // Mantenemos el calculado originalmente
      wristCircumference: double.parse(_wristController.text),
      ankleCircumference: double.parse(_ankleController.text),
    );

    // 2. Guardar en Hive
    final userBox = Hive.box<UserProfile>('userBox');
    await userBox.put('currentUser', updatedUser);

    // 3. Actualizar meta de hidratación si el peso cambió
    if (newWeight != _currentUser.weight) {
      final hydrationBox = Hive.box<HydrationSettings>('hydrationBox');
      final newGoal = newWeight * 35; // Fórmula simple: 35ml por kg
      await hydrationBox.put('settings', HydrationSettings(dailyGoalMl: newGoal));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Meta de hidratación actualizada a ${(newGoal/1000).toStringAsFixed(1)}L"))
        );
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Perfil actualizado correctamente"), backgroundColor: Colors.green),
      );
      Navigator.pop(context, true); // Retornar true para indicar que hubo cambios
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _ageController.dispose();
    _wristController.dispose();
    _ankleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Editar Perfil"),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: const Text("Guardar", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildSectionTitle(theme, "Datos Corporales"),
                  _buildNumericField(theme, "Peso Corporal (kg)", _weightController),
                  const SizedBox(height: 15),
                  _buildNumericField(theme, "Edad (años)", _ageController, isInteger: true),

                  const SizedBox(height: 30),
                  _buildSectionTitle(theme, "Medidas Óseas (Antropometría)"),
                  Text(
                    "Estas medidas ayudan a refinar tu somatotipo y potencial.",
                    style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12),
                  ),
                  const SizedBox(height: 15),
                  _buildNumericField(theme, "Circunferencia Muñeca (cm)", _wristController),
                  const SizedBox(height: 15),
                  _buildNumericField(theme, "Circunferencia Tobillo (cm)", _ankleController),

                  const SizedBox(height: 30),
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.withOpacity(0.3))
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.amber),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Nota: Si cambias drásticamente tus objetivos o días de entreno, te recomendamos generar una nueva rutina en la sección 'Mis Rutinas'.",
                            style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
    );
  }

  Widget _buildNumericField(ThemeData theme, String label, TextEditingController controller, {bool isInteger = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: !isInteger),
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: theme.cardColor,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Requerido';
        final numValue = double.tryParse(value);
        if (numValue == null || numValue <= 0) return 'Valor inválido';
        return null;
      },
    );
  }
}