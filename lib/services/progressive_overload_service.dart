import '../models/user_model.dart';
import '../models/routine_model.dart';
import './routine_generator_service.dart';

class ProgressiveOverloadService {
  static const int sessionsBeforeProgression = 4; // 4 weeks of consistent training

  static Future<void> applyProgressiveOverload(UserProfile user, WeeklyRoutine currentRoutine) async {
    // This is a placeholder for a more sophisticated check.
    // In a real app, we would check the user's workout history.
    final bool readyForProgression = _isReadyForProgression(user, currentRoutine);

    if (readyForProgression) {
      // For now, we will just regenerate the routine with a slightly modified goal.
      // A more advanced implementation would modify the existing routine.
      // For example, increase sets or reps, or swap exercises.
      
      // Simple progression: switch goals to add variety and new stimulus
      TrainingGoal newGoal;
      switch (user.goal) {
        case TrainingGoal.hypertrophy:
          newGoal = TrainingGoal.strength; // After a hypertrophy phase, do a strength phase
          break;
        case TrainingGoal.strength:
          newGoal = TrainingGoal.hypertrophy; // After a strength phase, do a hypertrophy phase
          break;
        case TrainingGoal.endurance:
          newGoal = TrainingGoal.hypertrophy; // After an endurance phase, do a hypertrophy phase
          break;
        default:
          newGoal = user.goal;
      }
      
      // We can create a new user profile object with the new goal to generate a new routine
      final UserProfile progressedUser = UserProfile(
          id: user.id,
          name: user.name,
          goal: newGoal, // Assign the new goal
          daysPerWeek: user.daysPerWeek,
          location: user.location,
          experience: user.experience,
          somatotype: user.somatotype,
          weight: user.weight,
          height: user.height,
          birthDate: user.birthDate,
          gender: user.gender,
      );

      // Generate a new routine based on the progressed user profile
      await RoutineGeneratorService.generateAndSaveRoutine(progressedUser);
    }
  }

  static bool _isReadyForProgression(UserProfile user, WeeklyRoutine routine) {
    // Placeholder logic: check if the routine is older than a month
    final aMonthAgo = DateTime.now().subtract(const Duration(days: 30));
    return routine.createdAt.isBefore(aMonthAgo);
  }
}
