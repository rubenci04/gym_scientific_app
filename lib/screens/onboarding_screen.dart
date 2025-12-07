import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
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
        features = "• Dificultad para ganar peso y músculo.\n• Metabolismo rápido.\n• Estructura ósea estrecha (hombros y caderas).";
        break;
      case Somatotype.mesomorph:
        fileName = '$folder-Mesomorfo.png';
        title = 'Mesomorfo';
        description = "Tienes una complexión atlética natural.";
        features = "• Ganas músculo con facilidad.\n• Postura erguida y hombros anchos.\n• Metabolismo equilibrado (ganas/pierdes peso fácil).";
        break;
      case Somatotype.endomorph:
        fileName = '$folder-Endomorfo.png';
        title = 'Endomorfo';
        description = "Tu cuerpo tiende a acumular energía fácilmente.";
        features = "• Estructura ósea gruesa y fuerte.\n• Facilidad para ganar fuerza.\n• Metabolismo más lento, tendencia a almacenar grasa.";
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Center(
          child: Text(
            "Tu Somatotipo: $title", 
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
          )
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10)
              ),
              child: Image.asset(
                imagePath, 
                height: 180, 
                fit: BoxFit.contain,
                errorBuilder: (c, o, s) => const Icon(Icons.person, size: 80, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 15),
            Text(description, 
              textAlign: TextAlign.center, 
              style: const TextStyle(color: Colors.black87, fontStyle: FontStyle.italic)
            ),
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(8),
                color: Colors.blue[50]
              ),
              child: Text(features, style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4)),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 12)
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _saveAndContinue(type);
              },
              child: const Text("CONTINUAR", style: TextStyle(color: Colors.white)),
            ),
          )
        ],
      ),
    );
  }

  void _saveAndContinue(Somatotype type) async {
    final age = int.parse(_ageCtrl.text);
    final weight = double.parse(_weightCtrl.text);
    final height = double.parse(_heightCtrl.text);
    
    double bmr = (10 * weight) + (6.25 * height) - (5 * age) + (_gender == 'Masculino' ? 5 : -161);
    
    final newUser = UserProfile(
      name: _nameCtrl.text,
      age: age,
      weight: weight,
      height: height,
      gender: _gender,
      wristCircumference: double.parse(_wristCtrl.text),
      ankleCircumference: double.parse(_ankleCtrl.text),
      somatotype: type,
      tdee: bmr * 1.2,
    );

    await Hive.box<UserProfile>('userBox').put('currentUser', newUser);
                value: _gender,
                items: ['Masculino', 'Femenino'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                onChanged: (v) => setState(() => _gender = v.toString()),
                decoration: const InputDecoration(labelText: 'Sexo'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _processData,
                child: const Text('CALCULAR'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController c, String label, {bool isNumber = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextFormField(controller: c, keyboardType: isNumber ? TextInputType.number : TextInputType.text, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()), validator: (v) => v!.isEmpty ? 'Requerido' : null),
  );

  Widget _buildRowInput(TextEditingController c1, String l1, TextEditingController c2, String l2) => Row(children: [Expanded(child: _buildInput(c1, l1, isNumber: true)), const SizedBox(width: 10), Expanded(child: _buildInput(c2, l2, isNumber: true))]);
}