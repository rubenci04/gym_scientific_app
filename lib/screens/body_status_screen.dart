import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/muscle_data.dart'; // Importante para la lista completa
import '../theme/app_colors.dart';
import '../services/fatigue_service.dart';
import '../widgets/interactive_body_map.dart';

class BodyStatusScreen extends StatefulWidget {
  const BodyStatusScreen({super.key});

  @override
  State<BodyStatusScreen> createState() => _BodyStatusScreenState();
}

class _BodyStatusScreenState extends State<BodyStatusScreen> {
  bool _isFrontView = true;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<UserProfile>('userBox').listenable(),
      builder: (context, Box<UserProfile> box, _) {
        final currentUser = box.get('currentUser');
        if (currentUser == null)
          return const Center(child: Text("Sin usuario"));

        final fatigueMap = FatigueService.calculateMuscleFatigue(currentUser);
        final svgFatigueMap = _mapGenericFatigueToSvg(fatigueMap);

        // Obtenemos la lista única de nombres de músculos para mostrar en la lista
        final musclesToShow = allMuscleParts
            .where((m) => m.face == (_isFrontView ? 'ant' : 'post'))
            .map((m) => m.name)
            .toSet() // Eliminar duplicados (ej: biceps der/izq -> Biceps)
            .toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Estado Corporal'),
            backgroundColor: AppColors.surface,
            actions: [
              IconButton(
                icon: Icon(
                  _isFrontView ? Icons.flip_to_back : Icons.flip_to_front,
                ),
                onPressed: () => setState(() => _isFrontView = !_isFrontView),
              ),
            ],
          ),
          body: Column(
            children: [
              const SizedBox(height: 10),
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

              Expanded(
                flex: 3,
                child: InteractiveBodyMap(
                  fatigueMap: svgFatigueMap,
                  isFront: _isFrontView,
                ),
              ),

              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: ListView(
                    children: [
                      const Text(
                        "Estado Muscular Detallado",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Iteramos sobre TODOS los músculos visibles, no solo los fatigados
                      ...musclesToShow.map((muscleName) {
                        // Buscamos la ID interna para obtener la fatiga del mapa SVG
                        // Esto es una simplificación, busca el primer ID que coincida con el nombre
                        String sampleId = allMuscleParts
                            .firstWhere((m) => m.name == muscleName)
                            .id;
                        double val = svgFatigueMap[sampleId] ?? 0.0;
                        return _buildMuscleBar(muscleName, val);
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Mapeo exhaustivo para cubrir todos los nuevos músculos
  Map<String, double> _mapGenericFatigueToSvg(Map<String, double> general) {
    final Map<String, double> svgMap = {};

    // Función auxiliar para asignar a pares (izq/der)
    void assign(String generalKey, List<String> ids) {
      if (general.containsKey(generalKey)) {
        for (var id in ids) svgMap[id] = general[generalKey]!;
      }
    }

    // Mapeos (Asegúrate que las claves coinciden con FatigueService)
    assign('Pectorales', ['pec_der', 'pec_izq']);
    assign('Abdominales', ['abd_der', 'abd_izq']);
    assign('Oblicuos', ['oblicuo_der', 'oblicuo_izq']);
    assign('Aductores', ['aduc_der', 'aduc_izq']);
    assign('Hombros', [
      'hombro_der',
      'hombro_izq',
      'hombro_post_der',
      'hombro_post_izq',
    ]);
    assign('Biceps', ['biceps_der', 'biceps_izq']);
    assign('Cuadriceps', ['quad_der', 'quad_izq']);
    assign('Dorsales', ['dorsal_der', 'dorsal_izq']);
    assign('EspaldaAlta', [
      'trap_der',
      'trap_izq',
      'trap_der_post',
      'trap_izq_post',
      'espalda_alta_der',
      'espalda_alta_izq',
    ]);
    assign('Triceps', ['triceps_der', 'triceps_izq']);
    assign('Gluteos', ['gluteo_der', 'gluteo_izq']);
    assign('Isquiotibiales', ['isquio_der', 'isquio_izq']);
    assign('Gemelos', ['gemelo_der', 'gemelo_izq']);
    assign('Lumbares', ['lumb_der', 'lumb_izq']);
    assign('Trapecios', [
      'trap_der',
      'trap_izq',
      'trap_der_post',
      'trap_izq_post',
    ]);
    assign('Antebrazos', ['antebrazo_der', 'antebrazo_izq']);
    assign('Abductores', ['abduc_der', 'abduc_izq']);

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
    // Definir color y estado texto
    Color color;
    String statusText;

    if (fatigue <= 0.05) {
      color = Colors.grey;
      statusText = "Descanso";
    } else if (fatigue < 0.6) {
      color = Colors.green;
      statusText = "Activo";
    } else {
      color = Colors.red;
      statusText = "Fatigado";
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
              Row(
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${(fatigue * 100).toInt()}%",
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ],
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
