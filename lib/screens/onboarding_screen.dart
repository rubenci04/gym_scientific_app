import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../theme/app_colors.dart'; 
import 'goal_selection_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _wristCtrl = TextEditingController();
  final _ankleCtrl = TextEditingController();

  String _gender = 'Masculino';

  Somatotype _calculateSomatotype(double bmi, double wrist, double height) {
    double rIndex = height / wrist;
    if (bmi < 19 && rIndex > 10.4) return Somatotype.ectomorph;
    if (bmi > 25 && rIndex < 9.6) return Somatotype.endomorph;
    return Somatotype.mesomorph;
  }

  void _processData() {
    if (!_formKey.currentState!.validate()) return;

    final weight = double.parse(_weightCtrl.text);
    final height = double.parse(_heightCtrl.text);
    final wrist = double.parse(_wristCtrl.text);
    final bmi = weight / ((height / 100) * (height / 100));

    final somatotype = _calculateSomatotype(bmi, wrist, height);
    _showResultDialog(somatotype);
  }

  void _showResultDialog(Somatotype type) {
    String folder = _gender == 'Masculino' ? 'Male' : 'Female';
    String fileName = '';
    String title = '';
    String description = '';
    String features = '';

    switch (type) {
      case Somatotype.ectomorph:
        fileName = '$folder-Ectomorfo.png';
        title = 'Ectomorfo';
        description = "Tu cuerpo tiende a ser delgado y ligero.";
        features =
            "• Dificultad para ganar peso y músculo.\n• Metabolismo rápido.\n• Estructura ósea estrecha (hombros y caderas).";
        break;
      case Somatotype.mesomorph:
        fileName = '$folder-Mesomorfo.png';
        title = 'Mesomorfo';
        description = "Tienes una complexión atlética natural.";
        features =
            "• Ganas músculo con facilidad.\n• Postura erguida y hombros anchos.\n• Metabolismo equilibrado (ganas/pierdes peso fácil).";
        break;
      case Somatotype.endomorph:
        fileName = '$folder-Endomorfo.png';
        title = 'Endomorfo';
        description = "Tu cuerpo tiende a acumular energía fácilmente.";
        features =
            "• Estructura ósea gruesa y fuerte.\n• Facilidad para ganar fuerza.\n• Metabolismo más lento, tendencia a almacenar grasa.";
        break;
      default:
        fileName = '$folder-Mesomorfo.png';
        title = 'Indefinido';
    }

    String imagePath = 'assets/images/somatotypes/$folder/$fileName';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface, // Adaptado a tema oscuro
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Center(
          child: Text(
            "Tu Somatotipo: $title",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                imagePath,
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (c, o, s) =>
                    const Icon(Icons.person, size: 80, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
                color: AppColors.primary.withOpacity(0.1),
              ),
              child: Text(
                features,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _saveAndContinue(type);
              },
              child: const Text(
                "CONTINUAR",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveAndContinue(Somatotype type) async {
    final age = int.tryParse(_ageCtrl.text) ?? 25;
    final weight = double.tryParse(_weightCtrl.text) ?? 70.0;
    final height = double.tryParse(_heightCtrl.text) ?? 170.0;

    double bmr =
        (10 * weight) +
        (6.25 * height) -
        (5 * age) +
        (_gender == 'Masculino' ? 5 : -161);

    // Creamos el perfil (con valores por defecto seguros)
    final newUser = UserProfile(
      name: _nameCtrl.text,
      age: age,
      weight: weight,
      height: height,
      gender: _gender,
      wristCircumference: double.tryParse(_wristCtrl.text) ?? 17.0,
      ankleCircumference: double.tryParse(_ankleCtrl.text) ?? 22.0,
      somatotype: type,
      tdee: bmr * 1.2,
      // Valores iniciales que se refinarán en siguientes pantallas
      goal: TrainingGoal.generalHealth, 
      daysPerWeek: 3, 
      experience: Experience.beginner 
    );

    await Hive.box<UserProfile>('userBox').put('currentUser', newUser);

    if (mounted) {
      // Nota para mí: Aquí estaba el error de pantalla blanca. 
      // Usaba pushReplacement, pero lo cambié a pushAndRemoveUntil 
      // para borrar todo el historial anterior y evitar conflictos de navegación.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const GoalSelectionScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Fondo oscuro corporativo
      appBar: AppBar(
        title: const Text('Tus Datos'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // --- HEADER CON LOGO Y TEXTO ---
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 2,
                          )
                        ]
                      ),
                      child: Image.asset(
                        // Nota para mí: Corregí la ruta del logo, tenía extensión doble (.png.png).
                        'assets/logo/logo_icon.png', 
                        height: 90, 
                        errorBuilder: (c, e, s) => const Icon(Icons.fitness_center, size: 60, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      'GYM SCIENTIFIC',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Inputs estilizados para fondo oscuro
              _buildInput(_nameCtrl, 'Nombre'),
              _buildRowInput(_ageCtrl, 'Edad', _weightCtrl, 'Peso (kg)'),
              _buildRowInput(
                _heightCtrl,
                'Altura (cm)',
                _wristCtrl,
                'Muñeca (cm)',
              ),
              _buildInput(_ankleCtrl, 'Tobillo (cm)', isNumber: true),

              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: DropdownButtonFormField(
                  value: _gender,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: Colors.white),
                  items: ['Masculino', 'Femenino']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() => _gender = v.toString()),
                  decoration: const InputDecoration(
                    labelText: 'Sexo',
                    labelStyle: TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  ),
                ),
              ),
              
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _processData,
                child: const Text('CALCULAR SOMATOTIPO', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
    TextEditingController c,
    String label, {
    bool isNumber = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: TextFormField(
      controller: c,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: AppColors.surface,
        border: const OutlineInputBorder(),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
      ),
      validator: (v) => v!.isEmpty ? 'Requerido' : null,
    ),
  );

  Widget _buildRowInput(
    TextEditingController c1,
    String l1,
    TextEditingController c2,
    String l2,
  ) => Row(
    children: [
      Expanded(child: _buildInput(c1, l1, isNumber: true)),
      const SizedBox(width: 15),
      Expanded(child: _buildInput(c2, l2, isNumber: true)),
    ],
  );
}