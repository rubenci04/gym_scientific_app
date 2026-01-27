import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/user_model.dart';
import '../models/hydration_settings_model.dart';
import '../services/routine_generator_service.dart';
import '../theme/app_colors.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Controladores
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _wristController = TextEditingController(); // Recuperado
  final _ankleController = TextEditingController(); // Recuperado

  // Estado
  String _selectedGender = 'Masculino';
  TrainingGoal _selectedGoal = TrainingGoal.hypertrophy;
  TrainingLocation _selectedLocation = TrainingLocation.gym;
  Experience _selectedExperience = Experience.beginner;
  int _daysPerWeek = 3;
  
  // Variables Científicas
  int _timeAvailable = 60;
  String _focusArea = 'Cuerpo Completo'; // Traducido
  bool _hasAsymmetry = false;

  final List<String> _focusOptions = [
    'Cuerpo Completo', 
    'Torso/Pierna', 
    'Empuje/Tracción/Pierna', 
    'Glúteos', 
    'Pectoral', 
    'Bíceps', 
    'Hombros', 
    'Espalda'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _currentPage = p),
                children: [
                  _buildPage1Personal(),
                  _buildPage2Measurements(), // Nueva página para medidas específicas
                  _buildPage3TrainingBase(),
                  _buildPage4ScientificDetails(),
                ],
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // PÁGINA 1: DATOS PERSONALES + LOGO
  Widget _buildPage1Personal() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // --- LOGO CORREGIDO ---
          Container(
            height: 120,
            margin: const EdgeInsets.only(bottom: 20),
            child: Image.asset(
              'assets/logo/app_logo.png.png', // Ruta exacta según tus archivos
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const Icon(Icons.fitness_center, size: 80, color: AppColors.primary),
            ),
          ),
          const Text("Bienvenido a Gym Scientific", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("Tu entrenador biomecánico personal", style: TextStyle(color: Colors.white54, fontSize: 14)),
          const SizedBox(height: 30),
          
          _buildTextField("Nombre", _nameController),
          const SizedBox(height: 15),
          Row(children: [
            Expanded(child: _buildTextField("Edad", _ageController, isNumber: true)),
            const SizedBox(width: 15),
            Expanded(child: _buildDropdown("Género", _selectedGender, ['Masculino', 'Femenino'], (val) => setState(() => _selectedGender = val!))),
          ]),
        ],
      ),
    );
  }

  // PÁGINA 2: MEDIDAS (MUÑECA/TOBILLO RECUPERADOS)
  Widget _buildPage2Measurements() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.accessibility, size: 60, color: AppColors.secondary),
          const SizedBox(height: 20),
          const Text("Datos Corporales", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const Text("Necesario para calcular tu Somatotipo", style: TextStyle(color: Colors.white54)),
          const SizedBox(height: 30),
          
          Row(children: [
            Expanded(child: _buildTextField("Peso (kg)", _weightController, isNumber: true)),
            const SizedBox(width: 15),
            Expanded(child: _buildTextField("Altura (cm)", _heightController, isNumber: true)),
          ]),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 20),
          
          // --- CAMPOS RECUPERADOS ---
          Row(children: [
            Expanded(child: _buildTextField("Muñeca (cm)", _wristController, isNumber: true)),
            const SizedBox(width: 15),
            Expanded(child: _buildTextField("Tobillo (cm)", _ankleController, isNumber: true)),
          ]),
          const SizedBox(height: 10),
          const Text(
            "Mide la circunferencia del hueso de la muñeca y el tobillo para determinar tu estructura ósea.",
            style: TextStyle(color: Colors.white30, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // PÁGINA 3: CONFIGURACIÓN ENTRENAMIENTO
  Widget _buildPage3TrainingBase() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Objetivos y Lugar", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          
          // Selector de Objetivo (Traducido visualmente)
          _buildDropdownEnum<TrainingGoal>(
            "Objetivo Principal", 
            _selectedGoal, 
            TrainingGoal.values, 
            (val) => setState(() => _selectedGoal = val!),
            labelMap: {
              TrainingGoal.hypertrophy: "Ganar Músculo (Hipertrofia)",
              TrainingGoal.strength: "Ganar Fuerza",
              TrainingGoal.weightLoss: "Perder Grasa / Definir",
              TrainingGoal.endurance: "Resistencia",
              TrainingGoal.generalHealth: "Salud General"
            }
          ),
          
          const SizedBox(height: 20),
          
          _buildDropdownEnum<Experience>(
            "Nivel de Experiencia", 
            _selectedExperience, 
            Experience.values, 
            (val) => setState(() => _selectedExperience = val!),
            labelMap: {
              Experience.beginner: "Principiante (< 1 año)",
              Experience.intermediate: "Intermedio (1-3 años)",
              Experience.advanced: "Avanzado (> 3 años)"
            }
          ),

          const SizedBox(height: 20),
          
          _buildDropdownEnum<TrainingLocation>(
            "Lugar de Entrenamiento", 
            _selectedLocation, 
            TrainingLocation.values, 
            (val) => setState(() => _selectedLocation = val!),
            labelMap: {
              TrainingLocation.gym: "Gimnasio Comercial (Equipo Completo)",
              TrainingLocation.home: "Casa (Mancuernas / Corporal)"
            }
          ),

          const SizedBox(height: 30),
          Text("Frecuencia: $_daysPerWeek días/semana", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          Slider(
            value: _daysPerWeek.toDouble(),
            min: 1, max: 6, divisions: 5,
            activeColor: AppColors.primary,
            label: "$_daysPerWeek días",
            onChanged: (val) => setState(() => _daysPerWeek = val.toInt()),
          ),
        ],
      ),
    );
  }

  // PÁGINA 4: AJUSTES FINOS (CIENTÍFICO)
  Widget _buildPage4ScientificDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Personalización Avanzada", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("Ajusta el algoritmo a tus necesidades reales", style: TextStyle(color: Colors.white54, fontSize: 14)),
          
          const SizedBox(height: 30),
          
          const Align(alignment: Alignment.centerLeft, child: Text("Tiempo por Sesión", style: TextStyle(color: AppColors.textPrimary))),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: [30, 45, 60, 90].map((time) {
              final isSelected = _timeAvailable == time;
              return ChoiceChip(
                label: Text("$time min"),
                selected: isSelected,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.cardColor,
                labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white),
                onSelected: (val) => setState(() => _timeAvailable = time),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          _buildDropdown("Enfoque Prioritario", _focusArea, _focusOptions, (val) => setState(() => _focusArea = val!)),
          if (_focusArea != 'Cuerpo Completo' && _focusArea != 'Torso/Pierna' && _focusArea != 'Empuje/Tracción/Pierna')
             const Padding(
               padding: EdgeInsets.only(top: 5),
               child: Text("ℹ️ Se generará una rutina con énfasis en este grupo.", style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
             ),

          const SizedBox(height: 20),

          SwitchListTile(
            title: const Text("Corrección de Asimetría", style: TextStyle(color: Colors.white)),
            subtitle: const Text("Priorizar ejercicios unilaterales (ej: para pierna izquierda más débil).", style: TextStyle(color: Colors.white54, fontSize: 11)),
            value: _hasAsymmetry,
            activeColor: AppColors.primary,
            contentPadding: EdgeInsets.zero,
            onChanged: (val) => setState(() => _hasAsymmetry = val),
          ),
        ],
      ),
    );
  }

  void _finishOnboarding() async {
    final user = UserProfile(
      name: _nameController.text.isEmpty ? "Atleta" : _nameController.text,
      age: int.tryParse(_ageController.text) ?? 25,
      weight: double.tryParse(_weightController.text) ?? 70,
      height: double.tryParse(_heightController.text) ?? 175,
      wristCircumference: double.tryParse(_wristController.text) ?? 17.0, // GUARDADO
      ankleCircumference: double.tryParse(_ankleController.text) ?? 22.0, // GUARDADO
      gender: _selectedGender,
      daysPerWeek: _daysPerWeek,
      goal: _selectedGoal,
      location: _selectedLocation,
      experience: _selectedExperience,
      timeAvailable: _timeAvailable,
      focusArea: _focusArea, // Se guardará en español
      hasAsymmetry: _hasAsymmetry,
    );

    final userBox = Hive.box<UserProfile>('userBox');
    await userBox.clear();
    await userBox.add(user);

    final hydrationBox = Hive.box<HydrationSettings>('hydrationBox');
    if (hydrationBox.isEmpty) {
      hydrationBox.add(HydrationSettings(dailyGoalMl: user.weight * 35));
    }

    // GENERACIÓN DE RUTINA
    await RoutineGeneratorService.generateAndSaveRoutine(user, focusArea: _focusArea);

    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  // WIDGETS AUXILIARES
  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      dropdownColor: AppColors.surface,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
      ),
    );
  }

  Widget _buildDropdownEnum<T>(String label, T value, List<T> values, Function(T?) onChanged, {Map<T, String>? labelMap}) {
    return DropdownButtonFormField<T>(
      value: value,
      items: values.map((e) => DropdownMenuItem(
        value: e, 
        child: Text(labelMap != null ? labelMap[e]! : e.toString().split('.').last.toUpperCase(), overflow: TextOverflow.ellipsis)
      )).toList(),
      onChanged: onChanged,
      dropdownColor: AppColors.surface,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease),
              child: const Text("Atrás", style: TextStyle(color: Colors.white54)),
            )
          else
            const SizedBox(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            ),
            onPressed: () {
              if (_currentPage < 3) { // Ahora son 4 páginas (índices 0,1,2,3)
                _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
              } else {
                _finishOnboarding();
              }
            },
            child: Text(_currentPage < 3 ? "Siguiente" : "CREAR PLAN", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}