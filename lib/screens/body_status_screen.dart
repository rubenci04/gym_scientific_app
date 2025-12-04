import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/user_model.dart';
import '../theme/app_colors.dart';
import '../services/fatigue_service.dart';
import '../widgets/interactive_body_map.dart'; // Asegúrate de haber creado este archivo en el paso anterior

class BodyStatusScreen extends StatefulWidget {
  const BodyStatusScreen({super.key});

  @override
  State<BodyStatusScreen> createState() => _BodyStatusScreenState();
}

class _BodyStatusScreenState extends State<BodyStatusScreen> {
  bool _isFrontView = true;

  @override
  Widget build(BuildContext context) {
    final userBox = Hive.box<UserProfile>('userBox');
    // Manejo seguro por si el usuario es null (aunque no debería)
    final currentUser = userBox.get('currentUser');

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text("No hay usuario activo")));
    }

    // 1. Obtenemos la fatiga general de tu servicio existente
    // Ejemplo: {"Pectorales": 0.5, "Biceps": 0.2}
    final Map<String, double> generalFatigue = FatigueService.calculateMuscleFatigue(currentUser);

    // 2. Convertimos esa fatiga general a los IDs específicos del SVG
    final Map<String, double> svgFatigueMap = _mapGenericFatigueToSvg(generalFatigue);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mapa de Recuperación'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: Icon(_isFrontView ? Icons.flip_to_back : Icons.flip_to_front),
            tooltip: "Girar Cuerpo",
            onPressed: () {
              setState(() {
                _isFrontView = !_isFrontView;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          // Leyenda de colores
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(Colors.grey[800]!, 'Descanso'),
              const SizedBox(width: 15),
              _buildLegendItem(Colors.green, 'Activo'),
              const SizedBox(width: 15),
              _buildLegendItem(Colors.red, 'Fatigado'),
            ],
          ),

          // --- AQUÍ ESTÁ EL CAMBIO PRINCIPAL ---
          // Reemplazamos el InteractiveViewer y CustomPaint antiguos
          Expanded(
            flex: 3,
            child: InteractiveBodyMap(
              fatigueMap: svgFatigueMap,
              isFront: _isFrontView,
            ),
          ),
          // -------------------------------------

          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ListView(
                children: [
                  const Text(
                    "Estado por Grupo Muscular",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Mostramos la lista basada en la vista actual
                  ...(_isFrontView
                          ? [
                              'Pectorales',
                              'Hombros',
                              'Biceps',
                              'Abdominales',
                              'Cuadriceps',
                            ]
                          : [
                              'Dorsales',
                              'Trapecios', // Agregado trapecios que faltaba
                              'Triceps',
                              'Gluteos',
                              'Isquiotibiales',
                              'Gemelos',
                            ])
                      .map(
                        (muscleKey) => _buildMuscleBar(
                          muscleKey,
                          // Usamos la fatiga original para la barra de progreso
                          generalFatigue[muscleKey] ?? 0.0,
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Esta función es el "puente" entre tu FatigueService y el nuevo Mapa SVG
  Map<String, double> _mapGenericFatigueToSvg(Map<String, double> generalFatigue) {
    final Map<String, double> svgMap = {};

    // Helper para asignar valor a ambos lados (izquierdo y derecho)
    void assignToBothSides(String generalKey, String leftId, String rightId) {
      final value = generalFatigue[generalKey] ?? 0.0;
      svgMap[leftId] = value;
      svgMap[rightId] = value;
    }

    // Mapeo: Nombre en FatigueService -> IDs en muscle_data.dart
    
    // Frente
    assignToBothSides('Pectorales', 'pec_izq', 'pec_der');
    assignToBothSides('Hombros', 'hombro_izq', 'hombro_der');
    assignToBothSides('Biceps', 'biceps_izq', 'biceps_der');
    assignToBothSides('Cuadriceps', 'quad_izq', 'quad_der');
    assignToBothSides('Abdominales', 'abd', 'abd_izq'); 
    assignToBothSides('Antebrazos', 'avb_izq', 'avb_der');

    // Espalda
    assignToBothSides('Dorsales', 'dorsal_izq', 'dorsal_der');
    assignToBothSides('Trapecios', 'trap_izq', 'trap_der');
    assignToBothSides('Triceps', 'triceps_izq', 'triceps_der');
    assignToBothSides('Gluteos', 'gluteo_izq', 'gluteo_der');
    assignToBothSides('Isquiotibiales', 'isquio_izq', 'isquio_der');
    assignToBothSides('Gemelos', 'gemelo_izq', 'gemelo_der');
    assignToBothSides('Lumbares', 'lumb_izq', 'lumb_der');

    return svgMap;
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMuscleBar(String label, double fatigue) {
    // Lógica de color idéntica al mapa SVG
    Color color;
    if (fatigue > 0) {
      color = Color.lerp(Colors.green, Colors.red, fatigue)!;
    } else {
      color = AppColors.muscleFresh;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white)),
              Text(
                "${(fatigue * 100).toInt()}%",
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 5),
          LinearProgressIndicator(
            value: fatigue,
            backgroundColor: Colors.grey.shade800,
            color: color,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }
}