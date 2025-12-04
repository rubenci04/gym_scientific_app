import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
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
    // Escucha cambios en el usuario (Hive)
    return ValueListenableBuilder(
      valueListenable: Hive.box<UserProfile>('userBox').listenable(),
      builder: (context, Box<UserProfile> box, _) {
        final currentUser = box.get('currentUser');

        if (currentUser == null) {
          return const Center(child: Text("No hay datos de usuario"));
        }

        // Calcular fatiga
        final fatigueMap = FatigueService.calculateMuscleFatigue(currentUser);
        // Convertir datos genéricos a IDs del SVG
        final svgFatigueMap = _mapGenericFatigueToSvg(fatigueMap);

        // Obtener imagen de fondo según perfil
        final imagePath = _getBodyImagePath(currentUser);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Mapa de Recuperación'),
            backgroundColor: AppColors.surface,
            actions: [
              IconButton(
                icon: Icon(
                  _isFrontView ? Icons.flip_to_back : Icons.flip_to_front,
                ),
                tooltip: "Girar Cuerpo",
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
                  _buildLegendItem(Colors.grey[800]!, 'Fresco'),
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
                  imagePath: imagePath,
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
                        "Estado por Grupo Muscular",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
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
                                  'Triceps',
                                  'Gluteos',
                                  'Isquiotibiales',
                                  'Gemelos',
                                ])
                          .map(
                            (key) =>
                                _buildMuscleBar(key, fatigueMap[key] ?? 0.0),
                          ),
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

  String _getBodyImagePath(UserProfile user) {
    // Mapeo de género
    String genderStr = (user.gender == 'Masculino') ? 'Male' : 'Female';

    // Mapeo de somatotipo
    String somatoFolder = 'Ectomorph';
    String somatoSuffix = 'Ectomorfo';

    switch (user.somatotype) {
      case Somatotype.mesomorph:
        somatoFolder = 'Mesomorph';
        somatoSuffix = 'Mesomorfo';
        break;
      case Somatotype.endomorph:
        somatoFolder = 'Endomorph';
        somatoSuffix = 'Endomorfo';
        break;
      default:
        somatoFolder = 'Ectomorph';
        somatoSuffix = 'Ectomorfo';
    }

    // Construcción de la ruta: assets/images/Ectomorph/Male/Male-Ectomorfo.png
    return 'assets/images/$somatoFolder/$genderStr/$genderStr-$somatoSuffix.png';
  }

  Map<String, double> _mapGenericFatigueToSvg(Map<String, double> general) {
    final Map<String, double> svgMap = {};
    void set(String key, List<String> ids) {
      final val = general[key] ?? 0.0;
      for (var id in ids) {
        svgMap[id] = val;
      }
    }

    set('Pectorales', ['pec_der', 'pec_izq']);
    set('Hombros', ['hombro_der', 'hombro_izq']);
    set('Biceps', ['biceps_der', 'biceps_izq']);
    set('Abdominales', ['abd_der', 'abd_izq']);
    set('Cuadriceps', ['quad_der', 'quad_izq']);
    set('Dorsales', ['dorsal_der', 'dorsal_izq']);
    set('Triceps', ['triceps_der', 'triceps_izq']);
    set('Gluteos', ['gluteo_der', 'gluteo_izq']);
    set('Isquiotibiales', ['isquio_der', 'isquio_izq']);
    set('Gemelos', ['gemelo_der', 'gemelo_izq']);

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
    Color color = fatigue > 0
        ? Color.lerp(Colors.green, Colors.red, fatigue)!
        : AppColors.muscleFresh;
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
