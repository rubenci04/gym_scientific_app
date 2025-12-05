import '../models/user_model.dart';

class SomatotypeContent {
  final String title;
  final String description;
  final String trainingAdvice;
  final String nutritionAdvice;
  final String imageAsset; // Placeholder for now

  const SomatotypeContent({
    required this.title,
    required this.description,
    required this.trainingAdvice,
    required this.nutritionAdvice,
    this.imageAsset = '',
  });
}

class SomatotypeData {
  static const Map<Somatotype, SomatotypeContent> data = {
    Somatotype.ectomorph: SomatotypeContent(
      title: 'Ectomorfo',
      description:
          'Tiendes a ser delgado, con estructura ósea ligera y dificultad para ganar peso (tanto músculo como grasa). Tu metabolismo es rápido.',
      trainingAdvice:
          'Prioriza ejercicios compuestos pesados. Descansa más entre series (2-3 min). Limita el cardio para no quemar el excedente calórico necesario para crecer.',
      nutritionAdvice:
          'Necesitas un superávit calórico alto. Prioriza carbohidratos complejos. Come frecuentemente. No temas a las grasas saludables.',
    ),
    Somatotype.mesomorph: SomatotypeContent(
      title: 'Mesomorfo',
      description:
          'Tienes una estructura ósea mediana, hombros anchos y cintura estrecha. Ganas músculo con facilidad y puedes perder grasa relativamente rápido.',
      trainingAdvice:
          'Respondes bien a un equilibrio entre fuerza e hipertrofia. Puedes tolerar más volumen de entrenamiento. Variedad de rangos de repeticiones (6-12).',
      nutritionAdvice:
          'Mantén un equilibrio de macronutrientes (40% carbos, 30% prote, 30% grasa). Ajusta calorías según tu objetivo (volumen o definición).',
    ),
    Somatotype.endomorph: SomatotypeContent(
      title: 'Endomorfo',
      description:
          'Tiendes a acumular grasa fácilmente. Sueles tener una estructura ósea más ancha y un metabolismo más lento.',
      trainingAdvice:
          'Entrenamiento de alta intensidad y menor descanso entre series. Incorpora cardio regularmente. El entrenamiento de fuerza es crucial para elevar el metabolismo.',
      nutritionAdvice:
          'Controla estrictamente los carbohidratos, priorizándolos alrededor del entrenamiento. Alta ingesta de proteínas y verduras. Déficit calórico ligero para mantenimiento.',
    ),
    Somatotype.undefined: SomatotypeContent(
      title: 'No definido',
      description: 'Aún no has definido tu somatotipo.',
      trainingAdvice: 'Sigue un programa equilibrado de fuerza e hipertrofia.',
      nutritionAdvice:
          'Mantén una dieta balanceada y ajusta según tus resultados.',
    ),
  };
}
