import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/muscle_data.dart';
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
        if (currentUser == null) return const Center(child: Text("Sin usuario"));

        // Calculo la fatiga real usando tu servicio
        final fatigueMap = FatigueService.calculateMuscleFatigue(currentUser);
        final svgFatigueMap = _mapGenericFatigueToSvg(fatigueMap);

        // --- CÁLCULO CIENTÍFICO DE RECUPERACIÓN (READINESS) ---
        double totalFatigue = 0;
        int count = 0;
        fatigueMap.forEach((_, val) {
          totalFatigue += val;
          count++;
        });
        
        // Si la fatiga promedio es 0.2 (20%), la recuperación es 80%
        double avgFatigue = count > 0 ? totalFatigue / count : 0;
        double readinessScore = (1.0 - avgFatigue).clamp(0.0, 1.0) * 100;

        // Lista de músculos para el desglose inferior
        final musclesToShow = allMuscleParts
            .where((m) => m.face == (_isFrontView ? 'ant' : 'post'))
            .map((m) => m.name)
            .toSet()
            .toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Análisis de Fatiga'),
            backgroundColor: AppColors.surface,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(_isFrontView ? Icons.flip_to_back : Icons.flip_to_front),
                tooltip: "Girar Cuerpo",
                onPressed: () => setState(() => _isFrontView = !_isFrontView),
              ),
            ],
          ),
          body: Column(
            children: [
              // --- PANEL DE DIAGNÓSTICO ---
              _buildReadinessCard(readinessScore),

              const SizedBox(height: 10),
              
              // Leyenda
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(Colors.grey[800]!, 'Fresco'),
                  const SizedBox(width: 15),
                  _buildLegendItem(Colors.green, 'Estímulo'),
                  const SizedBox(width: 15),
                  _buildLegendItem(Colors.red, 'Fatiga Alta'),
                ],
              ),

              // --- MAPA INTERACTIVO ---
              Expanded(
                flex: 4, 
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: InteractiveBodyMap(
                    fatigueMap: svgFatigueMap,
                    isFront: _isFrontView,
                  ),
                ),
              ),

              // --- LISTA DETALLADA ---
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -5))
                    ]
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Estado Muscular Local",
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Icon(Icons.keyboard_arrow_down, color: Colors.white.withOpacity(0.5))
                        ],
                      ),
                      const SizedBox(height: 15),
                      Expanded(
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          children: musclesToShow.map((muscleName) {
                            // Buscamos la ID interna para obtener la fatiga del mapa SVG
                            String sampleId = allMuscleParts.firstWhere((m) => m.name == muscleName).id;
                            double val = svgFatigueMap[sampleId] ?? 0.0;
                            
                            // Solo mostramos si tiene algo de fatiga para no saturar la lista
                            if (val > 0.05) return _buildMuscleBar(muscleName, val);
                            return const SizedBox.shrink(); 
                          }).toList(),
                        ),
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

  Widget _buildReadinessCard(double score) {
    Color scoreColor = score > 80 ? Colors.greenAccent : (score > 50 ? Colors.orangeAccent : Colors.redAccent);
    String message = score > 80 ? "Listo para entrenar fuerte." : (score > 50 ? "Entrena con precaución." : "Prioriza el descanso.");

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.surface, AppColors.surface.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60, height: 60,
                child: CircularProgressIndicator(
                  value: score / 100,
                  backgroundColor: Colors.grey[800],
                  color: scoreColor,
                  strokeWidth: 6,
                ),
              ),
              Text("${score.toInt()}%", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("RECUPERACIÓN SISTÉMICA", style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.5)),
                const SizedBox(height: 4),
                Text(message, style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Mapeo exhaustivo para conectar el Servicio de Fatiga con el Mapa SVG
  Map<String, double> _mapGenericFatigueToSvg(Map<String, double> general) {
    final Map<String, double> svgMap = {};

    void assign(String generalKey, List<String> ids) {
      if (general.containsKey(generalKey)) {
        for (var id in ids) svgMap[id] = general[generalKey]!;
      }
    }

    assign('Pectorales', ['pec_der', 'pec_izq']);
    assign('Abdominales', ['abd_der', 'abd_izq']);
    assign('Oblicuos', ['oblicuo_der', 'oblicuo_izq']);
    
    // --- CORRECCIÓN CLAVE PARA QUE SE PINTEN ---
    // El servicio debe enviar 'Aductores' o 'Abductores' para que esto funcione.
    assign('Aductores', ['aduc_der', 'aduc_izq']); 
    assign('Abductores', ['abduc_der', 'abduc_izq']);
    
    assign('Hombros', ['hombro_der', 'hombro_izq', 'hombro_post_der', 'hombro_post_izq']);
    assign('Biceps', ['biceps_der', 'biceps_izq']);
    assign('Cuadriceps', ['quad_der', 'quad_izq']);
    assign('Dorsales', ['dorsal_der', 'dorsal_izq']);
    assign('EspaldaAlta', ['trap_der', 'trap_izq', 'trap_der_post', 'trap_izq_post', 'espalda_alta_der', 'espalda_alta_izq']);
    assign('Triceps', ['triceps_der', 'triceps_izq']);
    assign('Gluteos', ['gluteo_der', 'gluteo_izq']);
    assign('Isquiotibiales', ['isquio_der', 'isquio_izq']);
    assign('Gemelos', ['gemelo_der', 'gemelo_izq']);
    assign('Lumbares', ['lumb_der', 'lumb_izq']);
    assign('Trapecios', ['trap_der', 'trap_izq', 'trap_der_post', 'trap_izq_post']);
    assign('Antebrazos', ['antebrazo_der', 'antebrazo_izq']);

    return svgMap;
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildMuscleBar(String label, double fatigue) {
    Color color;
    String statusText;

    if (fatigue <= 0.05) {
      color = Colors.grey;
      statusText = "Recuperado";
    } else if (fatigue < 0.6) {
      color = AppColors.primary;
      statusText = "Activo";
    } else {
      color = Colors.redAccent;
      statusText = "Fatigado";
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
              Text(statusText, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fatigue,
              backgroundColor: Colors.white10,
              color: color,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}