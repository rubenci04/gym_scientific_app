import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/user_model.dart';
import '../models/routine_model.dart';
import '../models/history_model.dart';
import './routine_generator_service.dart';

class ProgressiveOverloadService {
  static const int weeksForMesocycle = 4;

  static Future<void> applyProgressiveOverload(UserProfile user, WeeklyRoutine currentRoutine) async {
    final historyBox = Hive.box<WorkoutSession>('historyBox');
    
    // 1. Analizamos la consistencia
    final recentSessions = historyBox.values.where((session) {
      return session.date.isAfter(DateTime.now().subtract(const Duration(days: 30)));
    }).toList();

    if (recentSessions.length < 8) {
      debugPrint("⚠️ Usuario no consistente aún para sobrecarga (Sesiones: ${recentSessions.length})");
      return;
    }

    // 2. Verificamos ciclo
    final daysSinceCreation = DateTime.now().difference(currentRoutine.createdAt).inDays;
    
    if (daysSinceCreation >= (weeksForMesocycle * 7)) {
      debugPrint("🚀 Ciclo completado. Aplicando periodización...");
      
      // INICIALIZAMOS CON UN VALOR POR DEFECTO PARA EVITAR ERRORES
      TrainingGoal newGoal = TrainingGoal.hypertrophy; 
      
      switch (user.goal) {
        case TrainingGoal.hypertrophy:
          newGoal = TrainingGoal.strength; 
          break;
        case TrainingGoal.strength:
          newGoal = TrainingGoal.hypertrophy; 
          break;
        case TrainingGoal.endurance:
          newGoal = TrainingGoal.hypertrophy; 
          break;
        case TrainingGoal.weightLoss: // Asegúrate de que coincida con tu modelo
          newGoal = TrainingGoal.endurance; 
          break;
        case TrainingGoal.generalHealth: // Manejamos el caso que faltaba
          newGoal = TrainingGoal.hypertrophy; // Lo movemos a algo más estructurado
          break;
        default:
          // Red de seguridad: si llega un objetivo nuevo en el futuro,
          // no rompemos la app, simplemente asignamos hipertrofia.
          newGoal = TrainingGoal.hypertrophy;
          break;
      }

      user.goal = newGoal; 
      user.save();

      await RoutineGeneratorService.generateAndSaveRoutine(user);
      
      debugPrint("✅ ¡Sobrecarga aplicada! Nuevo objetivo: ${newGoal.toString()}");
    } else {
      if (daysSinceCreation > 14 && daysSinceCreation < 21) {
        debugPrint("ℹ️ Fase de acumulación: Manteniendo intensidad.");
      }
    }
  }
}