import '../models/routine_model.dart';

class RoutineTemplates {
  static List<WeeklyRoutine> get templates {
    return [
      // =======================================================
      // 1. PUSH PULL LEGS (Frecuencia 1 | 3 Días)
      // =======================================================
      WeeklyRoutine(
        id: 'template_ppl_3',
        name: 'Push Pull Legs (3 Días)',
        days: [
          RoutineDay(
            id: 'ppl_push',
            name: 'Día 1: Empuje (Push)',
            targetMuscles: ['Pecho', 'Hombros', 'Tríceps'],
            exercises: [
              RoutineExercise(exerciseId: 'bench_press_barbell', sets: 4, reps: '6-8', rpe: '8.5', restTimeSeconds: 180, note: "Cargas progresivas."),
              RoutineExercise(exerciseId: 'ohp_barbell', sets: 3, reps: '8-10', rpe: '8', restTimeSeconds: 120),
              RoutineExercise(exerciseId: 'db_press_incline', sets: 3, reps: '10-12', rpe: '8', restTimeSeconds: 90),
              RoutineExercise(exerciseId: 'lat_raise', sets: 4, reps: '12-15', rpe: '9', restTimeSeconds: 60, note: "Controla la bajada."),
              RoutineExercise(exerciseId: 'cable_crossover', sets: 3, reps: '15', rpe: '9', restTimeSeconds: 60),
              RoutineExercise(exerciseId: 'tricep_extension_overhead', sets: 3, reps: '10-12', rpe: '9', restTimeSeconds: 60),
              RoutineExercise(exerciseId: 'tricep_pushdown_rope', sets: 3, reps: '12-15', rpe: '9', restTimeSeconds: 60),
            ],
          ),
          RoutineDay(
            id: 'ppl_pull',
            name: 'Día 2: Tracción (Pull)',
            targetMuscles: ['Espalda', 'Bíceps', 'Trapecio'],
            exercises: [
              RoutineExercise(exerciseId: 'deadlift_conv', sets: 3, reps: '5', rpe: '8.5', restTimeSeconds: 180, note: "Técnica perfecta."),
              RoutineExercise(exerciseId: 'lat_pulldown', sets: 3, reps: '8-12', rpe: '8', restTimeSeconds: 90),
              RoutineExercise(exerciseId: 'row_barbell', sets: 3, reps: '8-10', rpe: '8.5', restTimeSeconds: 120),
              RoutineExercise(exerciseId: 'face_pull', sets: 4, reps: '15', rpe: '8', restTimeSeconds: 60),
              RoutineExercise(exerciseId: 'shrug_dumbbell', sets: 3, reps: '12-15', rpe: '9', restTimeSeconds: 60),
              RoutineExercise(exerciseId: 'curl_barbell', sets: 3, reps: '8-10', rpe: '9', restTimeSeconds: 90),
              RoutineExercise(exerciseId: 'curl_hammer', sets: 3, reps: '12', rpe: '9', restTimeSeconds: 60),
            ],
          ),
          RoutineDay(
            id: 'ppl_legs',
            name: 'Día 3: Pierna (Legs)',
            targetMuscles: ['Cuádriceps', 'Isquios', 'Glúteos'],
            exercises: [
              RoutineExercise(exerciseId: 'squat_barbell', sets: 4, reps: '5-8', rpe: '8.5', restTimeSeconds: 180),
              RoutineExercise(exerciseId: 'rdl_barbell', sets: 3, reps: '8-10', rpe: '8', restTimeSeconds: 120),
              RoutineExercise(exerciseId: 'leg_press', sets: 3, reps: '10-15', rpe: '8', restTimeSeconds: 90),
              RoutineExercise(exerciseId: 'leg_curl', sets: 3, reps: '12-15', rpe: '9', restTimeSeconds: 60),
              RoutineExercise(exerciseId: 'leg_extension', sets: 3, reps: '15', rpe: '9', restTimeSeconds: 60),
              RoutineExercise(exerciseId: 'calf_raise_standing', sets: 4, reps: '15-20', rpe: '9', restTimeSeconds: 60),
              RoutineExercise(exerciseId: 'plank', sets: 3, reps: '60s', rpe: '8', restTimeSeconds: 60),
            ],
          ),
        ],
        createdAt: DateTime.now(),
        isActive: false,
      ),

      // =======================================================
      // 2. ARNOLD SPLIT (Pecho/Espalda, Hombro/Brazo, Pierna)
      // =======================================================
      WeeklyRoutine(
        id: 'template_arnold',
        name: 'Arnold Split (3 Días)',
        days: [
          RoutineDay(
            id: 'arnold_chest_back',
            name: 'Día 1: Pecho y Espalda',
            targetMuscles: ['Pecho', 'Espalda'],
            exercises: [
              RoutineExercise(exerciseId: 'bench_press_barbell', sets: 4, reps: '6-8', rpe: '8.5'),
              RoutineExercise(exerciseId: 'pullup', sets: 4, reps: 'AMRAP', rpe: '9'),
              RoutineExercise(exerciseId: 'db_press_incline', sets: 3, reps: '10-12', rpe: '8'),
              RoutineExercise(exerciseId: 'row_barbell', sets: 3, reps: '8-10', rpe: '8'),
              RoutineExercise(exerciseId: 'db_fly', sets: 3, reps: '12-15', rpe: '9'),
              RoutineExercise(exerciseId: 'pullover_db', sets: 3, reps: '12-15', rpe: '9'),
              RoutineExercise(exerciseId: 'deadlift_conv', sets: 2, reps: '5', rpe: '8', note: "Finalizador de potencia"),
            ],
          ),
          RoutineDay(
            id: 'arnold_shoulders_arms',
            name: 'Día 2: Hombros y Brazos',
            targetMuscles: ['Hombros', 'Bíceps', 'Tríceps'],
            exercises: [
              RoutineExercise(exerciseId: 'ohp_barbell', sets: 4, reps: '6-8', rpe: '8.5'),
              RoutineExercise(exerciseId: 'lat_raise', sets: 4, reps: '12-15', rpe: '9'),
              RoutineExercise(exerciseId: 'rear_delt_fly', sets: 3, reps: '15-20', rpe: '9'),
              RoutineExercise(exerciseId: 'curl_barbell', sets: 3, reps: '8-10', rpe: '9'),
              RoutineExercise(exerciseId: 'skullcrusher_ez', sets: 3, reps: '10-12', rpe: '9'),
              RoutineExercise(exerciseId: 'curl_incline_db', sets: 3, reps: '12', rpe: '9'),
              RoutineExercise(exerciseId: 'tricep_pushdown_rope', sets: 3, reps: '12-15', rpe: '9'),
              RoutineExercise(exerciseId: 'wrist_curl', sets: 3, reps: '15-20', rpe: '9'),
            ],
          ),
          RoutineDay(
            id: 'arnold_legs',
            name: 'Día 3: Pierna Masiva',
            targetMuscles: ['Cuádriceps', 'Isquios', 'Glúteos'],
            exercises: [
              RoutineExercise(exerciseId: 'squat_barbell', sets: 4, reps: '6-10', rpe: '8.5'),
              RoutineExercise(exerciseId: 'lunge_barbell', sets: 3, reps: '10-12', rpe: '8'),
              RoutineExercise(exerciseId: 'leg_press', sets: 3, reps: '12-15', rpe: '8'),
              RoutineExercise(exerciseId: 'leg_curl', sets: 4, reps: '12-15', rpe: '9'),
              RoutineExercise(exerciseId: 'rdl_barbell', sets: 3, reps: '10-12', rpe: '8'),
              RoutineExercise(exerciseId: 'calf_raise_standing', sets: 4, reps: '15-20', rpe: '9'),
              RoutineExercise(exerciseId: 'hanging_leg_raise', sets: 3, reps: '10-15', rpe: '9'),
            ],
          ),
        ],
        createdAt: DateTime.now(),
        isActive: false,
      ),

      // =======================================================
      // 3. TORSO / PIERNA (Frecuencia 2 | 4 Días)
      // =======================================================
      WeeklyRoutine(
        id: 'template_upper_lower',
        name: 'Torso / Pierna (4 Días)',
        days: [
          RoutineDay(
            id: 'ul_upper1',
            name: 'Día 1: Torso (Fuerza)',
            targetMuscles: ['Pecho', 'Espalda', 'Hombros'],
            exercises: [
              RoutineExercise(exerciseId: 'bench_press_barbell', sets: 4, reps: '5-6', rpe: '8.5'),
              RoutineExercise(exerciseId: 'row_barbell', sets: 4, reps: '6-8', rpe: '8.5'),
              RoutineExercise(exerciseId: 'ohp_barbell', sets: 3, reps: '6-8', rpe: '8'),
              RoutineExercise(exerciseId: 'pullup', sets: 3, reps: 'AMRAP', rpe: '9'),
              RoutineExercise(exerciseId: 'dips_chest', sets: 3, reps: '8-10', rpe: '9'),
              RoutineExercise(exerciseId: 'face_pull', sets: 3, reps: '15', rpe: '8'),
              RoutineExercise(exerciseId: 'curl_barbell', sets: 3, reps: '10', rpe: '9'),
            ],
          ),
          RoutineDay(
            id: 'ul_lower1',
            name: 'Día 2: Pierna (Fuerza)',
            targetMuscles: ['Cuádriceps', 'Isquios'],
            exercises: [
              RoutineExercise(exerciseId: 'squat_barbell', sets: 4, reps: '5-6', rpe: '8.5'),
              RoutineExercise(exerciseId: 'rdl_barbell', sets: 4, reps: '6-8', rpe: '8'),
              RoutineExercise(exerciseId: 'leg_press', sets: 3, reps: '8-10', rpe: '8'),
              RoutineExercise(exerciseId: 'leg_curl', sets: 3, reps: '10-12', rpe: '9'),
              RoutineExercise(exerciseId: 'calf_raise_standing', sets: 4, reps: '10-12', rpe: '9'),
              RoutineExercise(exerciseId: 'plank', sets: 3, reps: '60s', rpe: '8'),
            ],
          ),
          RoutineDay(
            id: 'ul_upper2',
            name: 'Día 3: Torso (Hipertrofia)',
            targetMuscles: ['Pecho', 'Espalda', 'Brazos'],
            exercises: [
              RoutineExercise(exerciseId: 'db_press_incline', sets: 3, reps: '8-12', rpe: '8'),
              RoutineExercise(exerciseId: 'lat_pulldown', sets: 3, reps: '10-12', rpe: '8'),
              RoutineExercise(exerciseId: 'chest_press_machine', sets: 3, reps: '12-15', rpe: '9'),
              RoutineExercise(exerciseId: 'row_seated', sets: 3, reps: '12-15', rpe: '9'),
              RoutineExercise(exerciseId: 'lat_raise', sets: 4, reps: '15', rpe: '9'),
              RoutineExercise(exerciseId: 'tricep_pushdown_rope', sets: 3, reps: '12-15', rpe: '9'),
              RoutineExercise(exerciseId: 'curl_hammer', sets: 3, reps: '12-15', rpe: '9'),
            ],
          ),
          RoutineDay(
            id: 'ul_lower2',
            name: 'Día 4: Pierna (Hipertrofia)',
            targetMuscles: ['Cuádriceps', 'Isquios', 'Glúteos'],
            exercises: [
              RoutineExercise(exerciseId: 'deadlift_sumo', sets: 3, reps: '8-10', rpe: '8'),
              RoutineExercise(exerciseId: 'squat_hack', sets: 3, reps: '10-12', rpe: '8'),
              RoutineExercise(exerciseId: 'bulgarian_split_squat', sets: 3, reps: '10-12', rpe: '9'),
              RoutineExercise(exerciseId: 'leg_extension', sets: 3, reps: '15', rpe: '9'),
              RoutineExercise(exerciseId: 'hip_thrust_barbell', sets: 3, reps: '10-12', rpe: '9'),
              RoutineExercise(exerciseId: 'calf_raise_seated', sets: 4, reps: '15-20', rpe: '9'),
              RoutineExercise(exerciseId: 'crunch', sets: 3, reps: '15-20', rpe: '8'),
            ],
          ),
        ],
        createdAt: DateTime.now(),
        isActive: false,
      ),

      // =======================================================
      // 4. FULL BODY (Ideal principiantes / poco tiempo)
      // =======================================================
      WeeklyRoutine(
        id: 'template_fullbody',
        name: 'Full Body (3 Días)',
        days: [
          RoutineDay(
            id: 'fb_day1',
            name: 'Día 1: Enfoque Sentadilla',
            targetMuscles: ['Cuerpo Completo'],
            exercises: [
              RoutineExercise(exerciseId: 'squat_barbell', sets: 3, reps: '6-8', rpe: '8'),
              RoutineExercise(exerciseId: 'bench_press_barbell', sets: 3, reps: '8-10', rpe: '8'),
              RoutineExercise(exerciseId: 'row_barbell', sets: 3, reps: '8-10', rpe: '8'),
              RoutineExercise(exerciseId: 'ohp_db', sets: 3, reps: '10-12', rpe: '8'),
              RoutineExercise(exerciseId: 'curl_barbell', sets: 3, reps: '12', rpe: '9'),
              RoutineExercise(exerciseId: 'tricep_pushdown_rope', sets: 3, reps: '12', rpe: '9'),
              RoutineExercise(exerciseId: 'plank', sets: 3, reps: '45s', rpe: '8'),
            ],
          ),
          RoutineDay(
            id: 'fb_day2',
            name: 'Día 2: Enfoque Peso Muerto',
            targetMuscles: ['Cuerpo Completo'],
            exercises: [
              RoutineExercise(exerciseId: 'deadlift_conv', sets: 3, reps: '5', rpe: '8'),
              RoutineExercise(exerciseId: 'ohp_barbell', sets: 3, reps: '6-8', rpe: '8'),
              RoutineExercise(exerciseId: 'lat_pulldown', sets: 3, reps: '10-12', rpe: '8'),
              RoutineExercise(exerciseId: 'lunge_barbell', sets: 3, reps: '10-12', rpe: '8'),
              RoutineExercise(exerciseId: 'lat_raise', sets: 3, reps: '15', rpe: '9'),
              RoutineExercise(exerciseId: 'face_pull', sets: 3, reps: '15', rpe: '9'),
              RoutineExercise(exerciseId: 'hanging_leg_raise', sets: 3, reps: '10-12', rpe: '8'),
            ],
          ),
          RoutineDay(
            id: 'fb_day3',
            name: 'Día 3: Enfoque Hipertrofia',
            targetMuscles: ['Cuerpo Completo'],
            exercises: [
              RoutineExercise(exerciseId: 'leg_press', sets: 3, reps: '10-12', rpe: '8'),
              RoutineExercise(exerciseId: 'db_press_incline', sets: 3, reps: '10-12', rpe: '8'),
              RoutineExercise(exerciseId: 'row_db_one_arm', sets: 3, reps: '10-12', rpe: '8'),
              RoutineExercise(exerciseId: 'rdl_barbell', sets: 3, reps: '10-12', rpe: '8'),
              RoutineExercise(exerciseId: 'dips_machine', sets: 3, reps: '12-15', rpe: '9'),
              RoutineExercise(exerciseId: 'curl_hammer', sets: 3, reps: '12-15', rpe: '9'),
              RoutineExercise(exerciseId: 'calf_raise_standing', sets: 4, reps: '15', rpe: '9'),
            ],
          ),
        ],
        createdAt: DateTime.now(),
        isActive: false,
      ),

      // =======================================================
      // 5. BRO SPLIT (Clásica 5 Días)
      // =======================================================
      WeeklyRoutine(
        id: 'template_bro_split',
        name: 'Bro Split (5 Días)',
        days: [
          RoutineDay(
            id: 'bro_chest',
            name: 'Lunes: Pecho Internacional',
            targetMuscles: ['Pecho'],
            exercises: [
              RoutineExercise(exerciseId: 'bench_press_barbell', sets: 4, reps: '6-8', rpe: '8.5'),
              RoutineExercise(exerciseId: 'db_press_incline', sets: 4, reps: '8-10', rpe: '8.5'),
              RoutineExercise(exerciseId: 'dips_chest', sets: 3, reps: '10-12', rpe: '9'),
              RoutineExercise(exerciseId: 'cable_crossover', sets: 3, reps: '12-15', rpe: '9'),
              RoutineExercise(exerciseId: 'pec_deck', sets: 3, reps: '15', rpe: '9'),
              RoutineExercise(exerciseId: 'pushup', sets: 2, reps: 'AMRAP', rpe: '10'),
            ],
          ),
          RoutineDay(
            id: 'bro_back',
            name: 'Martes: Espalda',
            targetMuscles: ['Espalda'],
            exercises: [
              RoutineExercise(exerciseId: 'deadlift_conv', sets: 3, reps: '5', rpe: '8.5'),
              RoutineExercise(exerciseId: 'pullup', sets: 4, reps: 'AMRAP', rpe: '9'),
              RoutineExercise(exerciseId: 'row_barbell', sets: 4, reps: '8-10', rpe: '8.5'),
              RoutineExercise(exerciseId: 'lat_pulldown', sets: 3, reps: '10-12', rpe: '8.5'),
              RoutineExercise(exerciseId: 'row_seated', sets: 3, reps: '12-15', rpe: '9'),
              RoutineExercise(exerciseId: 'pullover_db', sets: 3, reps: '12-15', rpe: '9'),
            ],
          ),
          RoutineDay(
            id: 'bro_legs',
            name: 'Miércoles: Pierna',
            targetMuscles: ['Piernas'],
            exercises: [
              RoutineExercise(exerciseId: 'squat_barbell', sets: 4, reps: '6-8', rpe: '8.5'),
              RoutineExercise(exerciseId: 'leg_press', sets: 4, reps: '10-12', rpe: '8.5'),
              RoutineExercise(exerciseId: 'rdl_barbell', sets: 3, reps: '8-10', rpe: '8'),
              RoutineExercise(exerciseId: 'leg_extension', sets: 3, reps: '12-15', rpe: '9'),
              RoutineExercise(exerciseId: 'leg_curl', sets: 3, reps: '12-15', rpe: '9'),
              RoutineExercise(exerciseId: 'lunge_barbell', sets: 3, reps: '20 pasos', rpe: '9'),
              RoutineExercise(exerciseId: 'calf_raise_standing', sets: 5, reps: '15', rpe: '9'),
            ],
          ),
          RoutineDay(
            id: 'bro_shoulders',
            name: 'Jueves: Hombros',
            targetMuscles: ['Hombros'],
            exercises: [
              RoutineExercise(exerciseId: 'ohp_barbell', sets: 4, reps: '6-8', rpe: '8.5'),
              RoutineExercise(exerciseId: 'arnold_press', sets: 3, reps: '10-12', rpe: '8.5'),
              RoutineExercise(exerciseId: 'lat_raise', sets: 5, reps: '12-15', rpe: '9'),
              RoutineExercise(exerciseId: 'front_raise', sets: 3, reps: '12-15', rpe: '9'),
              RoutineExercise(exerciseId: 'rear_delt_fly', sets: 4, reps: '15-20', rpe: '9'),
              RoutineExercise(exerciseId: 'shrug_barbell', sets: 4, reps: '10-12', rpe: '8.5'),
            ],
          ),
          RoutineDay(
            id: 'bro_arms',
            name: 'Viernes: Brazos (Playa)',
            targetMuscles: ['Bíceps', 'Tríceps'],
            exercises: [
              RoutineExercise(exerciseId: 'curl_barbell', sets: 4, reps: '8-10', rpe: '9'),
              RoutineExercise(exerciseId: 'skullcrusher_ez', sets: 4, reps: '8-10', rpe: '9'),
              RoutineExercise(exerciseId: 'curl_incline_db', sets: 3, reps: '10-12', rpe: '9'),
              RoutineExercise(exerciseId: 'tricep_pushdown_rope', sets: 3, reps: '12-15', rpe: '9'),
              RoutineExercise(exerciseId: 'spider_curl', sets: 3, reps: '12-15', rpe: '9'),
              RoutineExercise(exerciseId: 'dips_bench', sets: 3, reps: 'AMRAP', rpe: '10'),
              RoutineExercise(exerciseId: 'wrist_curl', sets: 3, reps: '15', rpe: '9'),
            ],
          ),
        ],
        createdAt: DateTime.now(),
        isActive: false,
      ),

      // =======================================================
      // 6. GLUTE FOCUS (Especialización)
      // =======================================================
      WeeklyRoutine(
        id: 'template_glute_special',
        name: 'Glúteos de Acero (4 Días)',
        days: [
          RoutineDay(
            id: 'glute_A',
            name: 'Día 1: Glúteo Pesado',
            targetMuscles: ['Glúteos', 'Isquios'],
            exercises: [
              RoutineExercise(exerciseId: 'hip_thrust_barbell', sets: 4, reps: '6-8', rpe: '8.5', restTimeSeconds: 180),
              RoutineExercise(exerciseId: 'rdl_barbell', sets: 3, reps: '8-10', rpe: '8', restTimeSeconds: 120),
              RoutineExercise(exerciseId: 'bulgarian_split_squat', sets: 3, reps: '10-12', rpe: '8.5', restTimeSeconds: 90),
              RoutineExercise(exerciseId: 'cable_glute_kickback', sets: 3, reps: '12-15', rpe: '9', restTimeSeconds: 60),
              RoutineExercise(exerciseId: 'machine_hip_abduction', sets: 3, reps: '15-20', rpe: '9', restTimeSeconds: 60),
              RoutineExercise(exerciseId: 'plank', sets: 3, reps: '60s', rpe: '8'),
            ],
          ),
          RoutineDay(
            id: 'glute_upper',
            name: 'Día 2: Torso Completo',
            targetMuscles: ['Pecho', 'Espalda', 'Hombros'],
            exercises: [
              RoutineExercise(exerciseId: 'lat_pulldown', sets: 3, reps: '10-12'),
              RoutineExercise(exerciseId: 'ohp_db', sets: 3, reps: '10-12'),
              RoutineExercise(exerciseId: 'row_seated', sets: 3, reps: '10-12'),
              RoutineExercise(exerciseId: 'pushup', sets: 3, reps: 'AMRAP'),
              RoutineExercise(exerciseId: 'lat_raise', sets: 3, reps: '15'),
              RoutineExercise(exerciseId: 'tricep_pushdown_rope', sets: 3, reps: '12'),
            ],
          ),
          RoutineDay(
            id: 'glute_B',
            name: 'Día 3: Glúteo & Bombeo',
            targetMuscles: ['Glúteos', 'Cuádriceps'],
            exercises: [
              RoutineExercise(exerciseId: 'sumo_squat', sets: 4, reps: '8-10', rpe: '8.5'),
              RoutineExercise(exerciseId: 'glute_bridge', sets: 3, reps: '10-12', rpe: '8'),
              RoutineExercise(exerciseId: 'curtsy_lunge', sets: 3, reps: '12', rpe: '8.5'),
              RoutineExercise(exerciseId: 'leg_press', sets: 3, reps: '12-15', rpe: '8.5', note: "Pies altos en plataforma"),
              RoutineExercise(exerciseId: 'clamshell', sets: 3, reps: '15-20', rpe: '9'),
              RoutineExercise(exerciseId: 'frog_pump', sets: 3, reps: '20-30', rpe: '9', note: "Si no existe, usar puente sin peso"), 
            ],
          ),
          RoutineDay(
            id: 'glute_full',
            name: 'Día 4: Full Body + Glúteo',
            targetMuscles: ['Todo'],
            exercises: [
              RoutineExercise(exerciseId: 'squat_goblet', sets: 3, reps: '10-12'),
              RoutineExercise(exerciseId: 'step_up', sets: 3, reps: '10-12'),
              RoutineExercise(exerciseId: 'db_press_incline', sets: 3, reps: '10-12'),
              RoutineExercise(exerciseId: 'row_db_one_arm', sets: 3, reps: '10-12'),
              RoutineExercise(exerciseId: 'cable_glute_kickback', sets: 3, reps: '15'),
              RoutineExercise(exerciseId: 'russian_twist', sets: 3, reps: '20'),
            ],
          ),
        ],
        createdAt: DateTime.now(),
        isActive: false,
      ),

      // =======================================================
      // 7. PPL FRECUENCIA 2 (6 Días | Avanzado)
      // =======================================================
      WeeklyRoutine(
        id: 'template_ppl_6',
        name: 'PPL Avanzado (6 Días)',
        days: [
          RoutineDay(
            id: 'ppl6_push_a',
            name: 'Push A (Fuerza)',
            targetMuscles: ['Pecho', 'Hombros', 'Tríceps'],
            exercises: [
              RoutineExercise(exerciseId: 'bench_press_barbell', sets: 5, reps: '5', rpe: '9'),
              RoutineExercise(exerciseId: 'ohp_barbell', sets: 4, reps: '6-8', rpe: '8.5'),
              RoutineExercise(exerciseId: 'dips_chest', sets: 3, reps: '8-10', rpe: '9'),
              RoutineExercise(exerciseId: 'skullcrusher_ez', sets: 3, reps: '10-12', rpe: '9'),
              RoutineExercise(exerciseId: 'lat_raise', sets: 4, reps: '12-15', rpe: '9'),
              RoutineExercise(exerciseId: 'tricep_pushdown_rope', sets: 3, reps: '15', rpe: '9'),
            ],
          ),
          RoutineDay(
            id: 'ppl6_pull_a',
            name: 'Pull A (Fuerza)',
            targetMuscles: ['Espalda', 'Bíceps'],
            exercises: [
              RoutineExercise(exerciseId: 'deadlift_conv', sets: 3, reps: '5', rpe: '9'),
              RoutineExercise(exerciseId: 'pullup', sets: 4, reps: '6-8', rpe: '9'), // Lastradas si es posible
              RoutineExercise(exerciseId: 'row_barbell', sets: 4, reps: '8-10', rpe: '8.5'),
              RoutineExercise(exerciseId: 'face_pull', sets: 3, reps: '15', rpe: '8'),
              RoutineExercise(exerciseId: 'curl_barbell', sets: 3, reps: '8-10', rpe: '9'),
              RoutineExercise(exerciseId: 'curl_hammer', sets: 3, reps: '12', rpe: '9'),
            ],
          ),
          RoutineDay(
            id: 'ppl6_legs_a',
            name: 'Legs A (Fuerza)',
            targetMuscles: ['Piernas'],
            exercises: [
              RoutineExercise(exerciseId: 'squat_barbell', sets: 5, reps: '5', rpe: '9'),
              RoutineExercise(exerciseId: 'rdl_barbell', sets: 3, reps: '8-10', rpe: '8.5'),
              RoutineExercise(exerciseId: 'leg_press', sets: 3, reps: '10-12', rpe: '9'),
              RoutineExercise(exerciseId: 'leg_curl', sets: 3, reps: '12', rpe: '9'),
              RoutineExercise(exerciseId: 'calf_raise_standing', sets: 4, reps: '10', rpe: '9'),
              RoutineExercise(exerciseId: 'hanging_leg_raise', sets: 3, reps: '15', rpe: '8'),
            ],
          ),
          RoutineDay(
            id: 'ppl6_push_b',
            name: 'Push B (Hipertrofia)',
            targetMuscles: ['Pecho', 'Hombros', 'Tríceps'],
            exercises: [
              RoutineExercise(exerciseId: 'db_press_incline', sets: 4, reps: '8-12', rpe: '9'),
              RoutineExercise(exerciseId: 'ohp_db', sets: 3, reps: '10-12', rpe: '9'),
              RoutineExercise(exerciseId: 'chest_press_machine', sets: 3, reps: '12-15', rpe: '9'),
              RoutineExercise(exerciseId: 'lat_raise', sets: 4, reps: '15-20', rpe: '10', note: "Dropset en la última"),
              RoutineExercise(exerciseId: 'tricep_extension_overhead', sets: 3, reps: '12-15', rpe: '9'),
              RoutineExercise(exerciseId: 'cable_crossover', sets: 3, reps: '15', rpe: '9'),
            ],
          ),
          RoutineDay(
            id: 'ppl6_pull_b',
            name: 'Pull B (Hipertrofia)',
            targetMuscles: ['Espalda', 'Bíceps'],
            exercises: [
              RoutineExercise(exerciseId: 'lat_pulldown', sets: 4, reps: '10-12', rpe: '9'),
              RoutineExercise(exerciseId: 'row_db_one_arm', sets: 3, reps: '12-15', rpe: '9'),
              RoutineExercise(exerciseId: 'pullover_db', sets: 3, reps: '15', rpe: '9'),
              RoutineExercise(exerciseId: 'rear_delt_fly', sets: 3, reps: '15-20', rpe: '9'),
              RoutineExercise(exerciseId: 'shrug_dumbbell', sets: 3, reps: '15', rpe: '9'),
              RoutineExercise(exerciseId: 'incline_db_curl', sets: 3, reps: '12', rpe: '9'),
              RoutineExercise(exerciseId: 'preacher_curl', sets: 3, reps: '15', rpe: '10'),
            ],
          ),
          RoutineDay(
            id: 'ppl6_legs_b',
            name: 'Legs B (Hipertrofia)',
            targetMuscles: ['Piernas'],
            exercises: [
              RoutineExercise(exerciseId: 'squat_hack', sets: 4, reps: '10-12', rpe: '9'),
              RoutineExercise(exerciseId: 'bulgarian_split_squat', sets: 3, reps: '12', rpe: '9'),
              RoutineExercise(exerciseId: 'leg_extension', sets: 3, reps: '15-20', rpe: '10'),
              RoutineExercise(exerciseId: 'hip_thrust_barbell', sets: 3, reps: '12', rpe: '9'),
              RoutineExercise(exerciseId: 'leg_curl', sets: 3, reps: '15', rpe: '9'),
              RoutineExercise(exerciseId: 'calf_raise_seated', sets: 4, reps: '15-20', rpe: '9'),
            ],
          ),
        ],
        createdAt: DateTime.now(),
        isActive: false,
      ),

      // =======================================================
      // 8. POWERBUILDING (Fuerza Base + Accesorios)
      // =======================================================
      WeeklyRoutine(
        id: 'template_powerbuilding',
        name: 'Powerbuilding (4 Días)',
        days: [
          RoutineDay(
            id: 'pb_squat',
            name: 'Día 1: Sentadilla Pesada',
            targetMuscles: ['Piernas'],
            exercises: [
              RoutineExercise(exerciseId: 'squat_barbell', sets: 5, reps: '3-5', rpe: '9', restTimeSeconds: 240),
              RoutineExercise(exerciseId: 'squat_front', sets: 3, reps: '8-10', rpe: '8'),
              RoutineExercise(exerciseId: 'leg_extension', sets: 3, reps: '15', rpe: '9'),
              RoutineExercise(exerciseId: 'leg_curl', sets: 4, reps: '12', rpe: '9'),
              RoutineExercise(exerciseId: 'calf_raise_standing', sets: 4, reps: '10', rpe: '9'),
              RoutineExercise(exerciseId: 'plank', sets: 3, reps: 'Max', rpe: '10'),
            ],
          ),
          RoutineDay(
            id: 'pb_bench',
            name: 'Día 2: Press Banca Pesado',
            targetMuscles: ['Pecho', 'Tríceps'],
            exercises: [
              RoutineExercise(exerciseId: 'bench_press_barbell', sets: 5, reps: '3-5', rpe: '9', restTimeSeconds: 180),
              RoutineExercise(exerciseId: 'db_press_incline', sets: 3, reps: '8-10', rpe: '8.5'),
              RoutineExercise(exerciseId: 'dips_chest', sets: 3, reps: 'AMRAP', rpe: '9'),
              RoutineExercise(exerciseId: 'pec_deck', sets: 3, reps: '15', rpe: '9'),
              RoutineExercise(exerciseId: 'skullcrusher_ez', sets: 4, reps: '10-12', rpe: '9'),
              RoutineExercise(exerciseId: 'tricep_pushdown_rope', sets: 3, reps: '15', rpe: '10'),
            ],
          ),
          RoutineDay(
            id: 'pb_deadlift',
            name: 'Día 3: Peso Muerto Pesado',
            targetMuscles: ['Espalda', 'Isquios'],
            exercises: [
              RoutineExercise(exerciseId: 'deadlift_conv', sets: 5, reps: '3', rpe: '9', restTimeSeconds: 240),
              RoutineExercise(exerciseId: 'row_barbell', sets: 4, reps: '6-8', rpe: '8.5'),
              RoutineExercise(exerciseId: 'lat_pulldown', sets: 3, reps: '10-12', rpe: '8.5'),
              RoutineExercise(exerciseId: 'hyperextension', sets: 3, reps: '15', rpe: '8'), // Si no existe, good morning
              RoutineExercise(exerciseId: 'curl_barbell', sets: 4, reps: '8-10', rpe: '9'),
              RoutineExercise(exerciseId: 'hammer_curl', sets: 3, reps: '12', rpe: '9'),
            ],
          ),
          RoutineDay(
            id: 'pb_ohp',
            name: 'Día 4: Militar + Hombros',
            targetMuscles: ['Hombros'],
            exercises: [
              RoutineExercise(exerciseId: 'ohp_barbell', sets: 5, reps: '5', rpe: '9', restTimeSeconds: 180),
              RoutineExercise(exerciseId: 'ohp_db', sets: 3, reps: '8-10', rpe: '8.5'),
              RoutineExercise(exerciseId: 'lat_raise', sets: 5, reps: '12-15', rpe: '9'),
              RoutineExercise(exerciseId: 'face_pull', sets: 4, reps: '15', rpe: '9'),
              RoutineExercise(exerciseId: 'shrug_barbell', sets: 4, reps: '10', rpe: '9'),
              RoutineExercise(exerciseId: 'hanging_leg_raise', sets: 3, reps: '15', rpe: '9'),
            ],
          ),
        ],
        createdAt: DateTime.now(),
        isActive: false,
      ),

      // =======================================================
      // 9. CALISTENIA / EN CASA (Sin material)
      // =======================================================
      WeeklyRoutine(
        id: 'template_calisthenics',
        name: 'Calistenia / En Casa (3 Días)',
        days: [
          RoutineDay(
            id: 'cal_push',
            name: 'Día 1: Empuje Corporal',
            targetMuscles: ['Pecho', 'Tríceps', 'Pierna'],
            exercises: [
              RoutineExercise(exerciseId: 'pushup', sets: 4, reps: 'AMRAP', rpe: '9', note: "Si es fácil, pies elevados."),
              RoutineExercise(exerciseId: 'pushup_diamond', sets: 3, reps: 'AMRAP', rpe: '9'),
              RoutineExercise(exerciseId: 'dips_bench', sets: 3, reps: '15-20', rpe: '9'),
              RoutineExercise(exerciseId: 'squat_goblet', sets: 4, reps: '20', rpe: '8', note: "Usa mochila con peso si tienes"),
              RoutineExercise(exerciseId: 'lunge_barbell', sets: 3, reps: '15/pierna', rpe: '9', note: "Sin peso o mochila"),
              RoutineExercise(exerciseId: 'plank', sets: 3, reps: 'Max', rpe: '10'),
            ],
          ),
          RoutineDay(
            id: 'cal_pull',
            name: 'Día 2: Tracción Corporal',
            targetMuscles: ['Espalda', 'Bíceps', 'Core'],
            exercises: [
              RoutineExercise(exerciseId: 'pullup', sets: 4, reps: 'AMRAP', rpe: '9', note: "Si no puedes, usa banda o salto"),
              RoutineExercise(exerciseId: 'chinup', sets: 3, reps: 'AMRAP', rpe: '9'),
              RoutineExercise(exerciseId: 'dead_hang', sets: 3, reps: 'Max Tiempo', rpe: '10'),
              RoutineExercise(exerciseId: 'glute_bridge', sets: 4, reps: '20', rpe: '9'),
              RoutineExercise(exerciseId: 'superman', sets: 3, reps: '15', rpe: '8', note: "Si no existe, puente"),
              RoutineExercise(exerciseId: 'leg_raise_floor', sets: 3, reps: '15', rpe: '9'),
            ],
          ),
          RoutineDay(
            id: 'cal_full',
            name: 'Día 3: Circuito Metabólico',
            targetMuscles: ['Todo'],
            exercises: [
              RoutineExercise(exerciseId: 'jump_squat', sets: 3, reps: '15', rpe: '8', note: "Si no existe, sentadilla rápida"),
              RoutineExercise(exerciseId: 'pushup_incline', sets: 3, reps: '15', rpe: '8'),
              RoutineExercise(exerciseId: 'lunge_barbell', sets: 3, reps: '15/pierna', rpe: '8'),
              RoutineExercise(exerciseId: 'dips_bench', sets: 3, reps: '15', rpe: '9'),
              RoutineExercise(exerciseId: 'bicycle_crunch', sets: 3, reps: '20', rpe: '8'),
              RoutineExercise(exerciseId: 'mountain_climber', sets: 3, reps: '30s', rpe: '9', note: "Si no existe, plancha"),
            ],
          ),
        ],
        createdAt: DateTime.now(),
        isActive: false,
      ),

      // =======================================================
      // 10. METABÓLICO / FAT LOSS (4 Días)
      // =======================================================
      WeeklyRoutine(
        id: 'template_fat_loss',
        name: 'Quema Grasa (4 Días)',
        days: [
          RoutineDay(
            id: 'meta_A',
            name: 'Circuito A',
            targetMuscles: ['Full Body'],
            exercises: [
              RoutineExercise(exerciseId: 'squat_goblet', sets: 4, reps: '15', restTimeSeconds: 60),
              RoutineExercise(exerciseId: 'pushup', sets: 4, reps: '15', restTimeSeconds: 60),
              RoutineExercise(exerciseId: 'row_db_one_arm', sets: 4, reps: '15', restTimeSeconds: 60),
              RoutineExercise(exerciseId: 'ohp_db', sets: 4, reps: '15', restTimeSeconds: 60),
              RoutineExercise(exerciseId: 'jump_rope', sets: 4, reps: '1 min', restTimeSeconds: 60, note: "O Jumping Jacks"),
              RoutineExercise(exerciseId: 'plank', sets: 4, reps: '45s', restTimeSeconds: 60),
            ],
          ),
          RoutineDay(
            id: 'meta_B',
            name: 'Circuito B',
            targetMuscles: ['Full Body'],
            exercises: [
              RoutineExercise(exerciseId: 'deadlift_conv', sets: 4, reps: '10', restTimeSeconds: 90, note: "Peso moderado"),
              RoutineExercise(exerciseId: 'lat_pulldown', sets: 4, reps: '15', restTimeSeconds: 60),
              RoutineExercise(exerciseId: 'lunge_barbell', sets: 4, reps: '12/lado', restTimeSeconds: 60),
              RoutineExercise(exerciseId: 'dips_bench', sets: 4, reps: '15', restTimeSeconds: 60),
              RoutineExercise(exerciseId: 'curl_barbell', sets: 4, reps: '15', restTimeSeconds: 60),
              RoutineExercise(exerciseId: 'bicycle_crunch', sets: 4, reps: '20', restTimeSeconds: 60),
            ],
          ),
          // Se repite A y B
          RoutineDay(
            id: 'meta_A2',
            name: 'Circuito A (Repetición)',
            targetMuscles: ['Full Body'],
            exercises: [
              RoutineExercise(exerciseId: 'leg_press', sets: 4, reps: '20', restTimeSeconds: 60),
              RoutineExercise(exerciseId: 'db_press_flat', sets: 4, reps: '15', restTimeSeconds: 60),
              RoutineExercise(exerciseId: 'row_seated', sets: 4, reps: '15', restTimeSeconds: 60),
              RoutineExercise(exerciseId: 'lat_raise', sets: 4, reps: '15', restTimeSeconds: 45),
              RoutineExercise(exerciseId: 'kettlebell_swing', sets: 4, reps: '20', restTimeSeconds: 60, note: "O peso muerto ligero"),
              RoutineExercise(exerciseId: 'hanging_leg_raise', sets: 4, reps: '15', restTimeSeconds: 60),
            ],
          ),
          RoutineDay(
            id: 'meta_B2',
            name: 'Circuito B (Repetición)',
            targetMuscles: ['Full Body'],
            exercises: [
              RoutineExercise(exerciseId: 'step_up', sets: 4, reps: '15/lado', restTimeSeconds: 60),
              RoutineExercise(exerciseId: 'face_pull', sets: 4, reps: '20', restTimeSeconds: 60),
              RoutineExercise(exerciseId: 'pushup_diamond', sets: 4, reps: '12', restTimeSeconds: 60),
              RoutineExercise(exerciseId: 'curl_hammer', sets: 4, reps: '15', restTimeSeconds: 60),
              RoutineExercise(exerciseId: 'mountain_climber', sets: 4, reps: '45s', restTimeSeconds: 60),
              RoutineExercise(exerciseId: 'treadmill_run', sets: 1, reps: '20 min', restTimeSeconds: 0, note: "HIIT: 1 min correr / 1 min andar"),
            ],
          ),
        ],
        createdAt: DateTime.now(),
        isActive: false,
      ),
    ];
  }
}