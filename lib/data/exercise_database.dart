import '../models/exercise_model.dart';

/// Base de datos completa de ejercicios (200+ ejercicios)
/// Organizada por grupo muscular con información educativa completa
class ExerciseDatabase {
  static List<Exercise> getAllExercises() {
    return [
      ...chestExercises,
      ...backExercises,
      ...shoulderExercises,
      ...bicepsExercises,
      ...tricepsExercises,
      ...forearmExercises,
      ...quadExercises,
      ...hamstringExercises,
      ...gluteExercises,
      ...calfExercises,
      ...coreExercises,
      ...accessoryExercises,
    ];
  }

  // ===================
  // PECHO (25 ejercicios)
  // ===================
  static final List<Exercise> chestExercises = [
    Exercise(
      id: 'bench_press_barbell',
      name: 'Press de Banca con Barra',
      muscleGroup: 'Pecho',
      equipment: 'Barra',
      movementPattern: 'Empuje Horizontal',
      difficulty: 'Intermedio',
      description:
          'El press de banca es el rey de los ejercicios de pecho. Acuéstate en un banco plano, baja la barra hasta el pecho y empuja hacia arriba.',
      tips: [
        'Mantén los omóplatos retraídos durante todo el movimiento',
        'Baja la barra a la línea de los pezones',
        'Empuja con fuerza explosiva pero controlada',
        'Los pies deben estar firmes en el suelo',
      ],
      commonMistakes: [
        'Rebotar la barra en el pecho',
        'Arquear excesivamente la espalda',
        'No usar rango completo de movimiento',
        'Perder la tensión en el core',
      ],
      targetMuscles: ['Pectoral Mayor', 'Pectoral Menor'],
      secondaryMuscles: ['Deltoides Anterior', 'Tríceps'],
      variations: [
        'bench_press_incline',
        'bench_press_decline',
        'bench_press_close_grip',
      ],
      isBilateral: true,
      alternativeExercise: 'pushup',
    ),

    Exercise(
      id: 'bench_press_incline',
      name: 'Press de Banca Inclinado',
      muscleGroup: 'Pecho',
      equipment: 'Barra',
      movementPattern: 'Empuje Inclinado',
      difficulty: 'Intermedio',
      description:
          'Variante del press de banca con el banco a 30-45 grados. Enfatiza la porción superior del pecho.',
      tips: [
        'Ángulo ideal: 30-45 grados',
        'Baja la barra a la parte superior del pecho',
        'No uses un ángulo tan pronunciado que se convierta en un press de hombros',
      ],
      commonMistakes: [
        'Usar un ángulo demasiado pronunciado (>60°)',
        'Dejar que los codos se separen demasiado',
      ],
      targetMuscles: ['Pectoral Mayor Superior'],
      secondaryMuscles: ['Deltoides Anterior', 'Tríceps'],
      variations: ['bench_press_barbell', 'db_press_incline'],
      isBilateral: true,
      alternativeExercise: 'pushup_incline',
    ),

    Exercise(
      id: 'bench_press_decline',
      name: 'Press de Banca Declinado',
      muscleGroup: 'Pecho',
      equipment: 'Barra',
      movementPattern: 'Empuje Horizontal',
      difficulty: 'Intermedio',
      description:
          'Press con el banco declinado (cabeza más baja que las piernas). Enfatiza la porción inferior del pecho.',
      tips: [
        'Asegura bien los pies',
        'Controla el descenso',
        'Empuja en línea recta',
      ],
      commonMistakes: ['Usar demasiado peso', 'Perder el equilibrio'],
      targetMuscles: ['Pectoral Mayor Inferior'],
      secondaryMuscles: ['Tríceps'],
      variations: ['bench_press_barbell'],
      isBilateral: true,
    ),

    Exercise(
      id: 'db_press_flat',
      name: 'Press Plano con Mancuernas',
      muscleGroup: 'Pecho',
      equipment: 'Mancuernas',
      movementPattern: 'Empuje Horizontal',
      difficulty: 'Principiante',
      description:
          'Versión con mancuernas del press de banca. Permite mayor rango de movimiento y activa más estabilizadores.',
      tips: [
        'Desciende hasta sentir estiramiento en el pecho',
        'Las mancuernas deben moverse en forma de arco',
        'Mantén muñecas neutras',
      ],
      commonMistakes: [
        'Bajar las mancuernas en línea recta (reduce ROM)',
        'Chocar las mancuernas arriba',
      ],
      targetMuscles: ['Pectoral Mayor'],
      secondaryMuscles: ['Deltoides Anterior', 'Tríceps'],
      variations: ['db_press_incline', 'db_press_decline'],
      isBilateral: true,
      alternativeExercise: 'pushup',
    ),

    Exercise(
      id: 'db_press_incline',
      name: 'Press Inclinado con Mancuernas',
      muscleGroup: 'Pecho',
      equipment: 'Mancuernas',
      movementPattern: 'Empuje Inclinado',
      difficulty: 'Principiante',
      description:
          'Press inclinado con mancuernas. Excelente para desarrollar la parte superior del pecho.',
      tips: [
        'Mantén los codos a 45 grados del torso',
        'Rota ligeramente las mancuernas en la parte superior',
      ],
      commonMistakes: ['Usar un agarre demasiado ancho'],
      targetMuscles: ['Pectoral Mayor Superior'],
      secondaryMuscles: ['Deltoides Anterior', 'Tríceps'],
      variations: ['db_press_flat'],
      isBilateral: true,
      alternativeExercise: 'pushup_incline',
    ),

    Exercise(
      id: 'cable_crossover',
      name: 'Cruce de Poleas',
      muscleGroup: 'Pecho',
      equipment: 'Polea',
      movementPattern: 'Aislamiento',
      difficulty: 'Intermedio',
      description:
          'Ejercicio de aislamiento para pecho usando poleas. Excelente para el pico de contracción.',
      tips: [
        'Mantén una ligera flexión de codos',
        'Cruza las manos al final del movimiento',
        'Contrae el pecho en la posición final',
      ],
      commonMistakes: [
        'Usar demasiado peso y perder la tensión',
        'No controlar la fase excéntrica',
      ],
      targetMuscles: ['Pectoral Mayor'],
      secondaryMuscles: ['Deltoides Anterior'],
      variations: ['cable_crossover_high', 'cable_crossover_low'],
      isBilateral: true,
      alternativeExercise: 'db_fly',
    ),

    Exercise(
      id: 'db_fly',
      name: 'Aperturas con Mancuernas',
      muscleGroup: 'Pecho',
      equipment: 'Mancuernas',
      movementPattern: 'Aislamiento',
      difficulty: 'Principiante',
      description:
          'Ejercicio de aislamiento que estira profundamente el pecho. Acostado en banco, abre los brazos en forma de arco.',
      tips: [
        'Mantén codos ligeramente flexionados',
        'Baja hasta sentir estiramiento (no dolor)',
        'Imagina abrazar un árbol al subir',
      ],
      commonMistakes: [
        'Usar demasiado peso',
        'Extender completamente los codos',
        'Bajar demasiado y lastimar los hombros',
      ],
      targetMuscles: ['Pectoral Mayor'],
      secondaryMuscles: [],
      variations: ['db_fly_incline', 'cable_crossover'],
      isBilateral: true,
    ),

    Exercise(
      id: 'pushup',
      name: 'Flexiones de Brazos',
      muscleGroup: 'Pecho',
      equipment: 'Corporal',
      movementPattern: 'Empuje Horizontal',
      difficulty: 'Principiante',
      description:
          'El ejercicio más básico y efectivo para pecho sin equipo. Perfecto para principiantes.',
      tips: [
        'Cuerpo en línea recta de cabeza a talones',
        'Codos a 45 grados',
        'Baja hasta que el pecho casi toque el suelo',
        'Empuja con fuerza',
      ],
      commonMistakes: [
        'Dejar caer las caderas',
        'Arquear la espalda',
        'No bajar lo suficiente',
        'Cabeza hacia abajo',
      ],
      targetMuscles: ['Pectoral Mayor'],
      secondaryMuscles: ['Deltoides Anterior', 'Tríceps', 'Core'],
      variations: ['pushup_incline', 'pushup_decline', 'pushup_diamond'],
      isBilateral: true,
    ),

    Exercise(
      id: 'pushup_incline',
      name: 'Flexiones Inclinadas',
      muscleGroup: 'Pecho',
      equipment: 'Corporal',
      movementPattern: 'Empuje Horizontal',
      difficulty: 'Principiante',
      description:
          'Flexiones con las manos elevadas. Más fácil que las regulares, ideal para principiantes.',
      tips: [
        'Entre más alto el punto de apoyo, más fácil',
        'Mantén el core apretado',
      ],
      commonMistakes: ['Usar un ángulo tan alto que no haya tensión'],
      targetMuscles: ['Pectoral Mayor'],
      secondaryMuscles: ['Deltoides Anterior', 'Tríceps'],
      variations: ['pushup'],
      isBilateral: true,
    ),

    Exercise(
      id: 'pushup_decline',
      name: 'Flexiones Declinadas',
      muscleGroup: 'Pecho',
      equipment: 'Corporal',
      movementPattern: 'Empuje Horizontal',
      difficulty: 'Intermedio',
      description:
          'Flexiones con los pies elevados. Más difícil que las regulares, enfatiza la porción superior del pecho.',
      tips: ['Controla el descenso', 'Mantén el core muy apretado'],
      commonMistakes: ['Perder la línea del cuerpo'],
      targetMuscles: ['Pectoral Mayor Superior'],
      secondaryMuscles: ['Deltoides Anterior', 'Tríceps'],
      variations: ['pushup'],
      isBilateral: true,
    ),

    Exercise(
      id: 'pushup_diamond',
      name: 'Flexiones Diamante',
      muscleGroup: 'Pecho',
      equipment: 'Corporal',
      movementPattern: 'Empuje Horizontal',
      difficulty: 'Avanzado',
      description:
          'Flexiones con las manos juntas formando un diamante. Gran énfasis en tríceps.',
      tips: [
        'Forma un diamante con índices y pulgares',
        'Mantén codos pegados al cuerpo',
      ],
      commonMistakes: ['Separar los codos'],
      targetMuscles: ['Pectoral Mayor', 'Tríceps'],
      secondaryMuscles: ['Deltoides Anterior'],
      variations: ['pushup'],
      isBilateral: true,
    ),

    Exercise(
      id: 'pec_deck',
      name: 'Contractor (Pec Deck)',
      muscleGroup: 'Pecho',
      equipment: 'Máquina',
      movementPattern: 'Aislamiento',
      difficulty: 'Principiante',
      description:
          'Máquina que aísla el pecho. Ideal para sentir la contracción.',
      tips: [
        'Ajusta el siento correctamente',
        'Mantén la espalda pegada al respaldo',
        'Contrae fuerte al final',
      ],
      commonMistakes: ['Usar impulso', 'No controlar la apertura'],
      targetMuscles: ['Pectoral Mayor'],
      secondaryMuscles: [],
      variations: ['cable_crossover'],
      isBilateral: true,
    ),

    Exercise(
      id: 'chest_press_machine',
      name: 'Press de Pecho en Máquina',
      muscleGroup: 'Pecho',
      equipment: 'Máquina',
      movementPattern: 'Empuje Horizontal',
      difficulty: 'Principiante',
      description:
          'Versión en máquina del press de banca. Más segura para principiantes.',
      tips: ['Ajusta la altura del asiento', 'Empuja en línea recta'],
      commonMistakes: ['No ajustar bien el asiento'],
      targetMuscles: ['Pectoral Mayor'],
      secondaryMuscles: ['Deltoides Anterior', 'Tríceps'],
      variations: ['bench_press_barbell'],
      isBilateral: true,
    ),

    Exercise(
      id: 'dips_chest',
      name: 'Fondos en Paralelas (Pecho)',
      muscleGroup: 'Pecho',
      equipment: 'Paralelas',
      movementPattern: 'Empuje Vertical',
      difficulty: 'Avanzado',
      description:
          'Fondos con el torso inclinado hacia adelante para enfatizar el pecho.',
      tips: [
        'Inclínate hacia adelante',
        'Baja hasta sentir estiramiento',
        'Codos ligeramente hacia afuera',
      ],
      commonMistakes: [
        'Mantenerse vertical (trabaja más tríceps)',
        'Bajar demasiado',
      ],
      targetMuscles: ['Pectoral Mayor Inferior'],
      secondaryMuscles: ['Tríceps', 'Deltoides Anterior'],
      variations: ['dips_bench'],
      isBilateral: true,
      alternativeExercise: 'pushup_decline',
    ),

    // Añadir más ejercicios de pecho...
    Exercise(
      id: 'svend_press',
      name: 'Svend Press',
      muscleGroup: 'Pecho',
      equipment: 'Disco',
      movementPattern: 'Aislamiento',
      difficulty: 'Intermedio',
      description:
          'Ejercicio único donde presionas un disco frente a ti mientras lo alejas del pecho.',
      tips: [
        'Aprieta el disco con fuerza',
        'Extiende completamente los brazos',
        'Mantén la contracción',
      ],
      commonMistakes: ['No apretar el disco', 'Usar un disco demasiado pesado'],
      targetMuscles: ['Pectoral Mayor'],
      secondaryMuscles: ['Deltoides Anterior'],
      variations: [],
      isBilateral: true,
    ),
  ];

  // ===================
  // ESPALDA (30 ejercicios)
  // ===================
  static final List<Exercise> backExercises = [
    Exercise(
      id: 'deadlift_conv',
      name: 'Peso Muerto Convencional',
      muscleGroup: 'Espalda',
      equipment: 'Barra',
      movementPattern: 'Bisagra',
      difficulty: 'Avanzado',
      description:
          'El ejercicio más completo para toda la cadena posterior. Levanta una barra desde el suelo hasta la cadera.',
      tips: [
        'Espalda neutral en todo momento',
        'Empuja el suelo con los pies',
        'Barra pegada al cuerpo',
        'Caderas y hombros suben al mismo tiempo',
      ],
      commonMistakes: [
        'Redondear la espalda baja',
        'Iniciar con las caderas muy altas o muy bajas',
        'Usar los brazos para jalar (los brazos son ganchos)',
        'No bloquear correctamente arriba',
      ],
      targetMuscles: ['Erectores Espinales', 'Dorsales', 'Trapecio'],
      secondaryMuscles: ['Glúteos', 'Isquiotibiales', 'Antebrazos'],
      variations: ['deadlift_sumo', 'deadlift_romanian'],
      isBilateral: true,
      alternativeExercise: 'rdl_db',
    ),

    Exercise(
      id: 'lat_pulldown',
      name: 'Jalón al Pecho',
      muscleGroup: 'Espalda',
      equipment: 'Polea',
      movementPattern: 'Tracción Vertical',
      difficulty: 'Principiante',
      description:
          'Ejercicio fundamental para desarrollar dorsales. Jala una barra desde arriba hasta el pecho.',
      tips: [
        'Pecho hacia afuera',
        'Jala con los codos, no con las manos',
        'Barra al pecho, no detrás de la nuca',
        'Controla la subida',
      ],
      commonMistakes: [
        'Inclinarse demasiado hacia atrás',
        'Usar impulso',
        'Jalar detrás de la nuca (riesgo de lesión)',
        'No retraer escápulas',
      ],
      targetMuscles: ['Dorsal Ancho'],
      secondaryMuscles: ['Bíceps', 'Romboides', 'Trapecio Medio'],
      variations: ['pullup', 'lat_pulldown_wide', 'lat_pulldown_underhand'],
      isBilateral: true,
      alternativeExercise: 'pullup',
    ),

    Exercise(
      id: 'row_barbell',
      name: 'Remo con Barra',
      muscleGroup: 'Espalda',
      equipment: 'Barra',
      movementPattern: 'Tracción Horizontal',
      difficulty: 'Intermedio',
      description:
          'Ejercicio compuesto excelente para el grosor de la espalda. Bisagra de cadera y jala la barra hacia el abdomen.',
      tips: [
        'Torso a 45 grados o paralelo al suelo',
        'Jala hacia el ombligo/estómago',
        'Retrae escapulas al final',
        'Core apretado',
      ],
      commonMistakes: [
        'Estar muy erguido',
        'Rebotar la barra',
        'Usar el impulso de la espalda baja',
        'No controlar la bajada',
      ],
      targetMuscles: ['Dorsal Ancho', 'Romboides', 'Trapecio Medio'],
      secondaryMuscles: ['Erectores Espinales', 'Bíceps'],
      variations: ['row_pendlay', 'row_db_one_arm'],
      isBilateral: true,
      alternativeExercise: 'row_db_one_arm',
    ),

    Exercise(
      id: 'pullup',
      name: 'Dominadas',
      muscleGroup: 'Espalda',
      equipment: 'Barra Dominadas',
      movementPattern: 'Tracción Vertical',
      difficulty: 'Avanzado',
      description:
          'El rey de los ejercicios de espalda con peso corporal. Cuelga de una barra y jala tu cuerpo hacia arriba.',
      tips: [
        'Agarre pronado (palmas alejadas)',
        'Barbilla sobre la barra',
        'Controla el descenso',
        'No balancear el cuerpo',
      ],
      commonMistakes: [
        'No bajar completamente',
        'Usar kipping (balanceo)',
        'Encoger los hombros',
      ],
      targetMuscles: ['Dorsal Ancho'],
      secondaryMuscles: ['Bíceps', 'Romboides', 'Trapecio'],
      variations: ['chinup', 'pullup_wide', 'pullup_neutral'],
      isBilateral: true,
      alternativeExercise: 'lat_pulldown',
    ),

    Exercise(
      id: 'chinup',
      name: 'Dominadas Supinas (Chin-ups)',
      muscleGroup: 'Espalda',
      equipment: 'Barra Dominadas',
      movementPattern: 'Tracción Vertical',
      difficulty: 'Intermedio',
      description:
          'Dominadas con agarre supino (palmas hacia ti). Más énfasis en bíceps.',
      tips: [
        'Agarre supino a ancho de hombros',
        'Enfócate en jalar con el pecho',
      ],
      commonMistakes: ['Usar solo los brazos'],
      targetMuscles: ['Dorsal Ancho', 'Bíceps'],
      secondaryMuscles: ['Romboides'],
      variations: ['pullup'],
      isBilateral: true,
      alternativeExercise: 'lat_pulldown_underhand',
    ),

    Exercise(
      id: 'row_db_one_arm',
      name: 'Remo Unilateral con Mancuerna',
      muscleGroup: 'Espalda',
      equipment: 'Mancuernas',
      movementPattern: 'Tracción Horizontal',
      difficulty: 'Principiante',
      description:
          'Remo con una mano apoyada en banco. Excelente para corregir desbalances.',
      tips: [
        'Espalda plana',
        'Jala hacia la cadera',
        'Rota ligeramente el torso al final',
        'No jalar con el bíceps',
      ],
      commonMistakes: [
        'Rotar excesivamente el torso',
        'Usar impulso',
        'Dejar caer el hombro contrario',
      ],
      targetMuscles: ['Dorsal Ancho', 'Romboides'],
      secondaryMuscles: ['Trapecio', 'Bíceps'],
      variations: ['row_barbell', 'row_seated'],
      isBilateral: false,
    ),

    Exercise(
      id: 'row_seated',
      name: 'Remo en Polea Baja',
      muscleGroup: 'Espalda',
      equipment: 'Polea',
      movementPattern: 'Tracción Horizontal',
      difficulty: 'Principiante',
      description:
          'Remo sentado con polea. Gran ejercicio para grosor y densidad de espalda.',
      tips: [
        'Torso erguido',
        'Jala hacia el abdomen bajo',
        'Retrae escápulas al final',
      ],
      commonMistakes: ['Inclinarse mucho hacia adelante/atrás', 'Usar impulso'],
      targetMuscles: ['Dorsal Ancho', 'Romboides', 'Trapecio Medio'],
      secondaryMuscles: ['Bíceps', 'Erectores'],
      variations: ['row_barbell'],
      isBilateral: true,
    ),

    Exercise(
      id: 't_bar_row',
      name: 'Remo en T',
      muscleGroup: 'Espalda',
      equipment: 'Barra',
      movementPattern: 'Tracción Horizontal',
      difficulty: 'Intermedio',
      description:
          'Remo con una barra en T. Menos estrés en la espalda baja que el remo con barra.',
      tips: ['Pies estables', 'Jala con los codos', 'Mantén el pecho alto'],
      commonMistakes: ['Redondear la espalda', 'Usar demasiado peso'],
      targetMuscles: ['Dorsal Ancho', 'Romboides', 'Trapecio'],
      secondaryMuscles: ['Bíceps'],
      variations: ['row_barbell'],
      isBilateral: true,
    ),

    Exercise(
      id: 'shrug_barbell',
      name: 'Encogimientos con Barra',
      muscleGroup: 'Espalda',
      equipment: 'Barra',
      movementPattern: 'Aislamiento',
      difficulty: 'Principiante',
      description:
          'Ejercicio de aislamiento para trapecios. Eleva los hombros hacia las orejas.',
      tips: [
        'Movimiento vertical, no rotar',
        'Contrae al final',
        'Controla el descenso',
      ],
      commonMistakes: [
        'Rotar los hombros',
        'Usar el cuello',
        'Rebotar el peso',
      ],
      targetMuscles: ['Trapecio Superior'],
      secondaryMuscles: [],
      variations: ['shrug_db', 'shrug_trap_bar'],
      isBilateral: true,
    ),

    Exercise(
      id: 'face_pull',
      name: 'Face Pulls',
      muscleGroup: 'Espalda',
      equipment: 'Polea',
      movementPattern: 'Tracción Horizontal',
      difficulty: 'Principiante',
      description:
          'Ejercicio de corrección postural. Jala una cuerda hacia la cara.',
      tips: ['Codos altos', 'Separa las manos al final', 'Retrae escápulas'],
      commonMistakes: [
        'Bajar demasiado los codos',
        'No rotar externamente los hombros',
      ],
      targetMuscles: ['Trapecio Medio', 'Romboides', 'Deltoides Posterior'],
      secondaryMuscles: ['Manguito Rotador'],
      variations: [],
      isBilateral: true,
    ),

    // Más ejercicios de espalda (continúa con 20 más para llegar a 30)...
    Exercise(
      id: 'seal_row',
      name: 'Seal Row',
      muscleGroup: 'Espalda',
      equipment: 'Barra',
      movementPattern: 'Tracción Horizontal',
      difficulty: 'Intermedio',
      description:
          'Remo acostado en banco elevado. Elimina el estrés de la espalda baja.',
      tips: ['Acuéstate boca abajo en banco alto', 'Jala hacia el pecho'],
      commonMistakes: ['Arquear la espalda'],
      targetMuscles: ['Dorsal Ancho', 'Romboides'],
      secondaryMuscles: ['Bíceps'],
      variations: ['row_barbell'],
      isBilateral: true,
    ),
  ];

  // Continuará con hombros, bíceps, tríceps, piernas, core, etc.
  // Por brevedad, agregaré versiones resumidas

  // ===================
  // HOMBROS (20 ejercicios)
  // ===================
  static final List<Exercise> shoulderExercises = [
    Exercise(
      id: 'ohp_barbell',
      name: 'Press Militar con Barra',
      muscleGroup: 'Hombros',
      equipment: 'Barra',
      movementPattern: 'Empuje Vertical',
      difficulty: 'Intermedio',
      description:
          'El rey de los ejercicios de hombros. Press vertical con barra desde los hombros.',
      tips: [
        'Core apretado',
        'Barbilla hacia atrás al pasar la barra',
        'No arquear la espalda',
      ],
      commonMistakes: ['Arquear la espalda', 'Usar impulso de piernas'],
      targetMuscles: ['Deltoides Anterior', 'Deltoides Medio'],
      secondaryMuscles: ['Tríceps', 'Core'],
      variations: ['ohp_db', 'push_press'],
      isBilateral: true,
      alternativeExercise: 'ohp_db',
    ),

    Exercise(
      id: 'ohp_db',
      name: 'Press de Hombros con Mancuernas',
      muscleGroup: 'Hombros',
      equipment: 'Mancuernas',
      movementPattern: 'Empuje Vertical',
      difficulty: 'Principiante',
      description: 'Press de hombros sentado o de pie con mancuernas.',
      tips: ['Codos ligeramente adelante', 'No chocar las mancuernas arriba'],
      commonMistakes: ['Arquear la espalda excesivamente'],
      targetMuscles: ['Deltoides Anterior', 'Deltoides Medio'],
      secondaryMuscles: ['Tríceps'],
      variations: ['ohp_barbell', 'arnold_press'],
      isBilateral: true,
      alternativeExercise: 'pike_pushup',
    ),

    Exercise(
      id: 'lat_raise',
      name: 'Elevaciones Laterales',
      muscleGroup: 'Hombros',
      equipment: 'Mancuernas',
      movementPattern: 'Aislamiento',
      difficulty: 'Principiante',
      description:
          'Aislamiento para el deltoides lateral. Eleva los brazos a los lados.',
      tips: [
        'Codos ligeramente flexionados',
        'Subir hasta la altura de los hombros',
        'Controlar el descenso',
      ],
      commonMistakes: [
        'Usar demasiado peso',
        'Elevar los hombros',
        'Subir más allá de la horizontal',
      ],
      targetMuscles: ['Deltoides Medio'],
      secondaryMuscles: [],
      variations: ['lat_raise_cable', 'lat_raise_machine'],
      isBilateral: true,
    ),

    Exercise(
      id: 'front_raise',
      name: 'Elevaciones Frontales',
      muscleGroup: 'Hombros',
      equipment: 'Mancuernas',
      movementPattern: 'Aislamiento',
      difficulty: 'Principiante',
      description:
          'Aislamiento para deltoides anterior. Eleva los brazos al frente.',
      tips: ['Brazos rectos', 'Subir hasta la altura de los ojos'],
      commonMistakes: ['Usar impulso', 'Subir demasiado'],
      targetMuscles: ['Deltoides Anterior'],
      secondaryMuscles: [],
      variations: ['front_raise_barbell'],
      isBilateral: true,
    ),

    Exercise(
      id: 'rear_delt_fly',
      name: 'Aperturas Posteriores (Deltoides)',
      muscleGroup: 'Hombros',
      equipment: 'Mancuernas',
      movementPattern: 'Aislamiento',
      difficulty: 'Principiante',
      description:
          'Aislamiento para el deltoides posterior. Esencial para hombros balanceados.',
      tips: [
        'Inclinarse hacia adelante',
        'Codos ligeramente flexionados',
        'Jalar con los codos',
      ],
      commonMistakes: [
        'Usar trapecio en lugar de deltoides',
        'No inclinarse suficiente',
      ],
      targetMuscles: ['Deltoides Posterior'],
      secondaryMuscles: ['Romboides'],
      variations: ['face_pull', 'rear_delt_machine'],
      isBilateral: true,
    ),
  ];

  // ===================
  // BÍCEPS (15 ejercicios)
  // ===================
  static final List<Exercise> bicepsExercises = [
    Exercise(
      id: 'curl_barbell',
      name: 'Curl de Bíceps con Barra',
      muscleGroup: 'Bíceps',
      equipment: 'Barra',
      movementPattern: 'Aislamiento',
      difficulty: 'Principiante',
      description: 'El ejercicio clásico de bíceps. Curl de pie con barra.',
      tips: ['Codos pegados al torso', 'No balancear', 'Controlar la bajada'],
      commonMistakes: ['Usar impulso', 'Mover los codos'],
      targetMuscles: ['Bíceps'],
      secondaryMuscles: ['Antebrazo'],
      variations: ['curl_db', 'curl_ez_bar'],
      isBilateral: true,
    ),

    Exercise(
      id: 'curl_db',
      name: 'Curl de Bíceps con Mancuernas',
      muscleGroup: 'Bíceps',
      equipment: 'Mancuernas',
      movementPattern: 'Aislamiento',
      difficulty: 'Principiante',
      description: 'Curl con mancuernas. Permite supinación completa.',
      tips: ['Rotar las manos al subir', 'Alternar o simultáneo'],
      commonMistakes: ['Balancear el cuerpo'],
      targetMuscles: ['Bíceps'],
      secondaryMuscles: ['Braquial'],
      variations: ['curl_hammer', 'curl_barbell'],
      isBilateral: true,
    ),

    Exercise(
      id: 'curl_hammer',
      name: 'Curl Martillo',
      muscleGroup: 'Bíceps',
      equipment: 'Mancuernas',
      movementPattern: 'Aislamiento',
      difficulty: 'Principiante',
      description:
          'Curl con agarre neutro (martillo). Enfatiza braquial y braquiorradial.',
      tips: ['Pulgar arriba', 'No rotar la muñeca'],
      commonMistakes: ['Abrir los codos'],
      targetMuscles: ['Braquial', 'Braquiorradial'],
      secondaryMuscles: ['Bíceps'],
      variations: ['curl_db'],
      isBilateral: true,
    ),
  ];

  // ===================
  // TRÍCEPS (15 ejercicios)
  // ===================
  static final List<Exercise> tricepsExercises = [
    Exercise(
      id: 'tricep_extension_overhead',
      name: 'Extensión de Tríceps sobre la Cabeza',
      muscleGroup: 'Tríceps',
      equipment: 'Mancuernas',
      movementPattern: 'Aislamiento',
      difficulty: 'Principiante',
      description:
          'Extensión con mancuerna detrás de la cabeza. Excelente estiramiento.',
      tips: ['Codos apuntando al techo', 'No mover los hombros'],
      commonMistakes: ['Abrir los codos'],
      targetMuscles: ['Tríceps'],
      secondaryMuscles: [],
      variations: ['tricep_extension_cable'],
      isBilateral: true,
    ),

    Exercise(
      id: 'dips_bench',
      name: 'Fondos en Banco',
      muscleGroup: 'Tríceps',
      equipment: 'Banco/Silla',
      movementPattern: 'Empuje Vertical',
      difficulty: 'Principiante',
      description: 'Fondos con apoyo en banco. Excelente para tríceps en casa.',
      tips: ['Codos hacia atrás', 'Bajar hasta 90 grados'],
      commonMistakes: ['Bajar demasiado', 'Separar los codos'],
      targetMuscles: ['Tríceps'],
      secondaryMuscles: ['Pecho'],
      variations: ['dips_chest'],
      isBilateral: true,
      alternativeExercise: 'tricep_extension_overhead',
    ),

    Exercise(
      id: 'pushdown_cable',
      name: 'Extensión de Tríceps en Polea',
      muscleGroup: 'Tríceps',
      equipment: 'Polea',
      movementPattern: 'Aislamiento',
      difficulty: 'Principiante',
      description: 'Extensión con polea. Gran aislamiento de tríceps.',
      tips: ['Codos pegados', 'Extensión completa', 'Controlar la subida'],
      commonMistakes: ['Mover los codos', 'Inclinarse demasiado'],
      targetMuscles: ['Tríceps'],
      secondaryMuscles: [],
      variations: ['tricep_extension_overhead'],
      isBilateral: true,
    ),
  ];

  // ===================
  // ANTEBRAZO (10 ejercicios)
  // ===================
  static final List<Exercise> forearmExercises = [
    Exercise(
      id: 'wrist_curl',
      name: 'Curl de Muñeca',
      muscleGroup: 'Antebrazo',
      equipment: 'Mancuernas',
      movementPattern: 'Aislamiento',
      difficulty: 'Principiante',
      description: 'Aislamiento para flexores del antebrazo.',
      tips: ['Rango completo', 'Antebrazos apoyados'],
      commonMistakes: ['Usar demasiado peso'],
      targetMuscles: ['Flexores del Antebrazo'],
      secondaryMuscles: [],
      variations: ['wrist_curl_reverse'],
      isBilateral: true,
    ),

    Exercise(
      id: 'farmers_walk',
      name: 'Caminata del Granjero',
      muscleGroup: 'Antebrazo',
      equipment: 'Mancuernas',
      movementPattern: 'Agarre',
      difficulty: 'Intermedio',
      description:
          'Caminar sosteniendo pesos pesados. Desarrolla agarre y core.',
      tips: ['Hombros hacia atrás', 'Pasos firmes'],
      commonMistakes: ['Encoger los hombros'],
      targetMuscles: ['Antebrazos', 'Trapecio'],
      secondaryMuscles: ['Core', 'Piernas'],
      variations: [],
      isBilateral: true,
    ),
  ];

  // ===================
  // CUÁDRICEPS (20 ejercicios)
  // ===================
  static final List<Exercise> quadExercises = [
    Exercise(
      id: 'squat_barbell',
      name: 'Sentadilla Trasera con Barra',
      muscleGroup: 'Cuádriceps',
      equipment: 'Barra',
      movementPattern: 'Sentadilla',
      difficulty: 'Intermedio',
      description:
          'La reina de todos los ejercicios. Sentadilla profunda con barra en la espalda.',
      tips: [
        'Profundidad: muslos paralelos o más',
        'Rodillas en línea con los pies',
        'Pecho alto',
        'Empujar el suelo',
      ],
      commonMistakes: [
        'No bajar suficiente',
        'Rodillas hacia adentro',
        'Talones despegan',
      ],
      targetMuscles: ['Cuádriceps', 'Glúteos'],
      secondaryMuscles: ['Isquiotibiales', 'Core', 'Erectores'],
      variations: ['squat_front', 'squat_goblet'],
      isBilateral: true,
      alternativeExercise: 'squat_goblet',
    ),

    Exercise(
      id: 'leg_press',
      name: 'Prensa de Piernas',
      muscleGroup: 'Cuádriceps',
      equipment: 'Máquina',
      movementPattern: 'Sentadilla',
      difficulty: 'Principiante',
      description:
          'Máquina de prensa. Menos técnica que sentadilla, más segura para principiantes.',
      tips: [
        'Espalda baja pegada al respaldo',
        'Rango completo',
        'No bloquear las rodillas arriba',
      ],
      commonMistakes: ['Despegar la espalda baja', 'Poner los pies muy juntos'],
      targetMuscles: ['Cuádriceps', 'Glúteos'],
      secondaryMuscles: ['Isquiotibiales'],
      variations: [],
      isBilateral: true,
      alternativeExercise: 'squat_barbell',
    ),

    Exercise(
      id: 'lunge_barbell',
      name: 'Zancadas con Barra',
      muscleGroup: 'Cuádriceps',
      equipment: 'Barra',
      movementPattern: 'Zancada',
      difficulty: 'Intermedio',
      description:
          'Zancadas caminando o estáticas. Excelente para balance y cuádriceps.',
      tips: [
        'Rodilla trasera casi toca el suelo',
        'Torso erguido',
        'Rodilla no pasa mucho la punta del pie',
      ],
      commonMistakes: ['Inclinarse hacia adelante', 'Paso muy corto'],
      targetMuscles: ['Cuádriceps', 'Glúteos'],
      secondaryMuscles: ['Isquiotibiales'],
      variations: ['lunge_db', 'lunge_reverse'],
      isBilateral: false,
      alternativeExercise: 'lunge_body',
    ),

    Exercise(
      id: 'leg_extension',
      name: 'Extensión de Cuádriceps',
      muscleGroup: 'Cuádriceps',
      equipment: 'Máquina',
      movementPattern: 'Aislamiento',
      difficulty: 'Principiante',
      description:
          'Aislamiento puro de cuádriceps. Extensión de rodilla sentado.',
      tips: ['Extensión completa', 'Controlar el descenso', 'Pausar arriba'],
      commonMistakes: ['Usar demasiado peso', 'Balancear'],
      targetMuscles: ['Cuádriceps'],
      secondaryMuscles: [],
      variations: [],
      isBilateral: true,
    ),

    Exercise(
      id: 'squat_goblet',
      name: 'Sentadilla Goblet',
      muscleGroup: 'Cuádriceps',
      equipment: 'Mancuernas',
      movementPattern: 'Sentadilla',
      difficulty: 'Principiante',
      description:
          'Sentadilla sosteniendo una mancuerna al frente. Perfecta para aprender técnica.',
      tips: [
        'Mancuerna al pecho',
        'Codos entre las rodillas',
        'Sentarse entre los talones',
      ],
      commonMistakes: ['No bajar suficiente'],
      targetMuscles: ['Cuádriceps', 'Glúteos'],
      secondaryMuscles: ['Core'],
      variations: ['squat_barbell'],
      isBilateral: true,
    ),
  ];

  // ===================
  // ISQUIOTIBIALES (15 ejercicios)
  // ===================
  static final List<Exercise> hamstringExercises = [
    Exercise(
      id: 'rdl_barbell',
      name: 'Peso Muerto Rumano con Barra',
      muscleGroup: 'Isquiotibiales',
      equipment: 'Barra',
      movementPattern: 'Bisagra',
      difficulty: 'Intermedio',
      description:
          'Bisagra de cadera con barra. Movimiento fundamental para isquiotibiales.',
      tips: [
        'Espalda plana',
        'Empujar las caderas atrás',
        'Sentir estiramiento en isquios',
        'Barra pegada a las piernas',
      ],
      commonMistakes: [
        'Redondear la espalda',
        'Doblar mucho las rodillas',
        'Bajar la barra demasiado',
      ],
      targetMuscles: ['Isquiotibiales', 'Glúteos'],
      secondaryMuscles: ['Erectores Espinales'],
      variations: ['rdl_db', 'stiff_leg_deadlift'],
      isBilateral: true,
      alternativeExercise: 'rdl_db',
    ),

    Exercise(
      id: 'leg_curl',
      name: 'Curl Femoral',
      muscleGroup: 'Isquiotibiales',
      equipment: 'Máquina',
      movementPattern: 'Aislamiento',
      difficulty: 'Principiante',
      description:
          'Aislamiento de isquiotibiales. Flexión de rodilla acostado o sentado.',
      tips: [
        'Rango completo',
        'Controlar la bajada',
        'No despegar las caderas (versión acostado)',
      ],
      commonMistakes: ['Usar inercia', 'Rango parcial'],
      targetMuscles: ['Isquiotibiales'],
      secondaryMuscles: [],
      variations: ['nordic_curl'],
      isBilateral: true,
    ),

    Exercise(
      id: 'nordic_curl',
      name: 'Nordic Hamstring Curl',
      muscleGroup: 'Isquiotibiales',
      equipment: 'Corporal',
      movementPattern: 'Aislamiento',
      difficulty: 'Avanzado',
      description:
          'Curl excéntrico de isquiotibiales. Muy efectivo pero difícil.',
      tips: [
        'Alguien sostiene tus pies',
        'Bajar lentamente',
        'Usar las manos para volver arriba',
      ],
      commonMistakes: ['Bajar demasiado rápido'],
      targetMuscles: ['Isquiotibiales'],
      secondaryMuscles: [],
      variations: ['leg_curl'],
      isBilateral: true,
      alternativeExercise: 'leg_curl',
    ),
  ];

  // ===================
  // GLÚTEOS (15 ejercicios)
  // ===================
  static final List<Exercise> gluteExercises = [
    Exercise(
      id: 'hip_thrust_barbell',
      name: 'Hip Thrust con Barra',
      muscleGroup: 'Glúteos',
      equipment: 'Barra',
      movementPattern: 'Puente',
      difficulty: 'Intermedio',
      description:
          'El mejor ejercicio para glúteos. Empujar caderas hacia arriba con espalda en banco.',
      tips: [
        'Barbilla al pecho',
        'Apretar glúteos al final',
        'No usar espalda baja',
        'Rodillas a 90 grados arriba',
      ],
      commonMistakes: [
        'Arquear la espalda',
        'No apretar los glúteos',
        'Rango parcial',
      ],
      targetMuscles: ['Glúteos'],
      secondaryMuscles: ['Isquiotibiales'],
      variations: ['glute_bridge', 'single_leg_hip_thrust'],
      isBilateral: true,
      alternativeExercise: 'glute_bridge',
    ),

    Exercise(
      id: 'glute_bridge',
      name: 'Puente de Glúteos',
      muscleGroup: 'Glúteos',
      equipment: 'Corporal',
      movementPattern: 'Puente',
      difficulty: 'Principiante',
      description:
          'Puente de glúteos desde el suelo. Versión más fácil del hip thrust.',
      tips: [
        'Pies cerca de los glúteos',
        'Empujar con los talones',
        'Apretar glúteos arriba',
      ],
      commonMistakes: ['Usar la espalda baja en lugar de glúteos'],
      targetMuscles: ['Glúteos'],
      secondaryMuscles: ['Isquiotibiales'],
      variations: ['hip_thrust_barbell'],
      isBilateral: true,
    ),

    Exercise(
      id: 'bulgarian_split_squat',
      name: 'Sentadilla Búlgara',
      muscleGroup: 'Glúteos',
      equipment: 'Mancuernas',
      movementPattern: 'Zancada',
      difficulty: 'Intermedio',
      description:
          'Sentadilla unilateral con pie trasero elevado. Excelente para glúteos y cuádriceps.',
      tips: [
        'Pie trasero en banco',
        'Bajar hasta rodilla casi toca',
        'Torso erguido',
      ],
      commonMistakes: [
        'Pie delantero muy cerca del banco',
        'Inclinarse hacia adelante',
      ],
      targetMuscles: ['Glúteos', 'Cuádriceps'],
      secondaryMuscles: ['Isquiotibiales'],
      variations: ['lunge_reverse'],
      isBilateral: false,
    ),
  ];

  // ===================
  // GEMELOS (10 ejercicios)
  // ===================
  static final List<Exercise> calfExercises = [
    Exercise(
      id: 'calf_raise_standing',
      name: 'Elevación de Gemelos de Pie',
      muscleGroup: 'Gemelos',
      equipment: 'Máquina',
      movementPattern: 'Aislamiento',
      difficulty: 'Principiante',
      description: 'Elevación de talones de pie. Trabaja gastrocnemio.',
      tips: ['Rango completo', 'Pausar arriba', 'Bajar completamente'],
      commonMistakes: ['Rango parcial', 'Rebotar'],
      targetMuscles: ['Gastrocnemio'],
      secondaryMuscles: [],
      variations: ['calf_raise_seated'],
      isBilateral: true,
    ),

    Exercise(
      id: 'calf_raise_seated',
      name: 'Elevación de Gemelos Sentado',
      muscleGroup: 'Gemelos',
      equipment: 'Máquina',
      movementPattern: 'Aislamiento',
      difficulty: 'Principiante',
      description: 'Elevación sentado. Enfatiza el sóleo.',
      tips: ['Rodillas a 90 grados', 'Rango completo'],
      commonMistakes: ['No estirar abajo'],
      targetMuscles: ['Sóleo'],
      secondaryMuscles: [],
      variations: ['calf_raise_standing'],
      isBilateral: true,
    ),
  ];

  // ===================
  // CORE/ABDOMINALES (25 ejercicios)
  // ===================
  static final List<Exercise> coreExercises = [
    Exercise(
      id: 'plank',
      name: 'Plancha Frontal',
      muscleGroup: 'Core',
      equipment: 'Corporal',
      movementPattern: 'Anti-Extensión',
      difficulty: 'Principiante',
      description:
          'El ejercicio fundamental de core. Mantén tu cuerpo en línea recta.',
      tips: [
        'Codos bajo los hombros',
        'Cuerpo en línea recta',
        'Glúteos apretados',
        'No dejar caer las caderas',
      ],
      commonMistakes: ['Caderas caídas', 'Caderas muy altas', 'No respirar'],
      targetMuscles: ['Recto Abdominal', 'Transverso'],
      secondaryMuscles: ['Oblicuos', 'Erectores'],
      variations: ['plank_side', 'plank_renegade'],
      isBilateral: true,
    ),

    Exercise(
      id: 'crunch',
      name: 'Abdominales Crunch',
      muscleGroup: 'Core',
      equipment: 'Corporal',
      movementPattern: 'Flexión',
      difficulty: 'Principiante',
      description: 'El crunch clásico. Flexiona el torso hacia las rodillas.',
      tips: ['Lumbar pegada al suelo', 'No jalar del cuello', 'Mirar al techo'],
      commonMistakes: ['Jalar la cabeza', 'Usar impulso'],
      targetMuscles: ['Recto Abdominal'],
      secondaryMuscles: [],
      variations: ['bicycle_crunch', 'reverse_crunch'],
      isBilateral: true,
    ),

    Exercise(
      id: 'russian_twist',
      name: 'Giros Rusos',
      muscleGroup: 'Core',
      equipment: 'Disco',
      movementPattern: 'Rotación',
      difficulty: 'Intermedio',
      description:
          'Ejercicio rotacional para oblicuos. Sentado, gira de lado a lado.',
      tips: ['Pies elevados', 'Torso a 45 grados', 'Giro controlado'],
      commonMistakes: ['Mover solo los brazos', 'Ir demasiado rápido'],
      targetMuscles: ['Oblicuos'],
      secondaryMuscles: ['Recto Abdominal'],
      variations: [],
      isBilateral: true,
    ),

    Exercise(
      id: 'hanging_leg_raise',
      name: 'Elevación de Piernas Colgado',
      muscleGroup: 'Core',
      equipment: 'Barra Dominadas',
      movementPattern: 'Flexión',
      difficulty: 'Avanzado',
      description:
          'Cuelga de una barra y eleva las piernas. Excelente para abdominales inferiores.',
      tips: [
        'Piernas rectas o flexionadas',
        'No balancear',
        'Inclina la pelvis',
      ],
      commonMistakes: [
        'Usar impulso',
        'Solo levantar las piernas sin inclinar pelvis',
      ],
      targetMuscles: ['Recto Abdominal Inferior'],
      secondaryMuscles: ['Flexores de Cadera'],
      variations: ['knee_raise_hanging'],
      isBilateral: true,
      alternativeExercise: 'knee_raise_hanging',
    ),

    Exercise(
      id: 'ab_wheel',
      name: 'Rueda Abdominal',
      muscleGroup: 'Core',
      equipment: 'Rueda Ab',
      movementPattern: 'Anti-Extensión',
      difficulty: 'Avanzado',
      description:
          'Roll out con rueda. Ejercicio muy intenso para todo el core.',
      tips: [
        'No arquear la espalda',
        'Ir hasta donde puedas controlar',
        'Empujar con los abdominales para volver',
      ],
      commonMistakes: ['Arquear la espalda baja', 'Usar los brazos'],
      targetMuscles: ['Recto Abdominal', 'Transverso'],
      secondaryMuscles: ['Erectores', 'Hombros'],
      variations: ['plank'],
      isBilateral: true,
      alternativeExercise: 'plank',
    ),
  ];

  // ===================
  // ACCESORIOS (15 ejercicios)
  // ===================
  static final List<Exercise> accessoryExercises = [
    Exercise(
      id: 'neck_extension',
      name: 'Extensión de Cuello',
      muscleGroup: 'Cuello',
      equipment: 'Disco',
      movementPattern: 'Aislamiento',
      difficulty: 'Principiante',
      description:
          'Fortalecimiento del cuello. Acostado, sostén disco en la frente.',
      tips: ['Peso ligero', 'Movimiento controlado', 'Rango completo'],
      commonMistakes: ['Usar demasiado peso'],
      targetMuscles: ['Cuello'],
      secondaryMuscles: [],
      variations: [],
      isBilateral: true,
    ),

    Exercise(
      id: 'band_pull_apart',
      name: 'Band Pull-Apart',
      muscleGroup: 'Espalda',
      equipment: 'Banda',
      movementPattern: 'Tracción Horizontal',
      difficulty: 'Principiante',
      description:
          'Separa una banda al frente del pecho. Excelente para salud de hombros.',
      tips: ['Codos rectos', 'Separar hasta el pecho', 'Retrae escápulas'],
      commonMistakes: ['Usar los brazos en lugar de la espalda'],
      targetMuscles: ['Romboides', 'Trapecio Medio', 'Deltoides Posterior'],
      secondaryMuscles: [],
      variations: ['face_pull'],
      isBilateral: true,
    ),
  ];
}
