import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/fatigue_service.dart';

class BodyStatusScreen extends StatefulWidget {
  const BodyStatusScreen({super.key});

  @override
  State<BodyStatusScreen> createState() => _BodyStatusScreenState();
}

class _BodyStatusScreenState extends State<BodyStatusScreen> {
  // Estado para alternar vista (Frente / Espalda)
  bool _isFrontView = true;

  @override
  Widget build(BuildContext context) {
    // Calculamos fatiga en tiempo real
    final fatigueMap = FatigueService.calculateMuscleFatigue();

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
          )
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          // --- LEYENDA ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(AppColors.muscleFresh, 'Fresco'),
              const SizedBox(width: 15),
              _buildLegendItem(AppColors.muscleRecovering, 'Recuperando'),
              const SizedBox(width: 15),
              _buildLegendItem(AppColors.muscleFatigued, 'Fatigado'),
            ],
          ),
          
          // --- VISUALIZADOR ANATÓMICO ---
          Expanded(
            flex: 3,
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: BodyHeatmap(
                fatigueMap: fatigueMap, 
                isFront: _isFrontView,
                isMale: true, // Forzado a hombre por ahora
              ),
            ),
          ),

          // --- LISTA DE ESTADO ---
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
                  const Text("Estado por Grupo Muscular", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  // Lista dinámica según la vista (Frente o Espalda)
                  ...(_isFrontView 
                      ? ['Pectorales', 'Hombros', 'Biceps', 'Abdominales', 'Cuadriceps'] 
                      : ['Dorsales', 'Triceps', 'Gluteos', 'Isquiotibiales', 'Gemelos']
                    ).map((muscleKey) => _buildMuscleBar(muscleKey, FatigueService.getFatigueLevel(muscleKey)))
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildMuscleBar(String label, double fatigue) {
    Color color = fatigue < 0.3 ? AppColors.muscleFresh : (fatigue < 0.7 ? AppColors.muscleRecovering : AppColors.muscleFatigued);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.white)),
              Text("${(fatigue * 100).toInt()}%", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
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

// --- WIDGET DEL MAPA DE CALOR (La Magia Visual) ---
class BodyHeatmap extends StatelessWidget {
  final Map<String, double> fatigueMap;
  final bool isFront;
  final bool isMale;

  const BodyHeatmap({
    super.key, 
    required this.fatigueMap, 
    required this.isFront, 
    required this.isMale
  });

  @override
  Widget build(BuildContext context) {
    // Rutas normalizadas (minúsculas)
    final String gender = isMale ? 'male' : 'female';
    final String view = isFront ? 'front' : 'back'; 
    final String basePath = 'assets/images/body/$gender/$view';

    // Nombres de tus archivos base
    final String baseImage = isFront ? 'CuerpoEnteroFrente.png' : 'CuerpoEnteroDetras.png';

    return Stack(
      alignment: Alignment.center,
      children: [
        // 1. SILUETA BASE
        Image.asset(
          '$basePath/$baseImage',
          fit: BoxFit.contain,
          // Color base para unificar tono (opcional)
          color: const Color(0xFF2C3E50), 
          colorBlendMode: BlendMode.modulate, 
        ),

        // 2. CAPAS DE MÚSCULOS (Overlays)
        // Se cargan dinámicamente. Asegúrate de que los archivos existan.
        if (isFront) ...[
          _buildOverlay('$basePath/Pectorales.png', fatigueMap['Pectorales']),
          _buildOverlay('$basePath/Abdominales.png', fatigueMap['Abdominales']),
          _buildOverlay('$basePath/Cuadriceps.png', fatigueMap['Cuadriceps']), // Sin tilde
          _buildOverlay('$basePath/Hombros.png', fatigueMap['Hombros']),
          _buildOverlay('$basePath/Biceps.png', fatigueMap['Biceps']), // Sin tilde
        ] else ...[
          _buildOverlay('$basePath/Dorsales.png', fatigueMap['Dorsales']),
          // Si tienes EspaldaAlta, puedes descomentar:
          // _buildOverlay('$basePath/EspaldaAlta.png', fatigueMap['Dorsales']), 
          _buildOverlay('$basePath/Gluteos.png', fatigueMap['Gluteos']), // Sin tilde
          _buildOverlay('$basePath/Triceps.png', fatigueMap['Triceps']), // Sin tilde
          _buildOverlay('$basePath/Gemelos.png', fatigueMap['Gemelos']),
          // Nombre corregido
          _buildOverlay('$basePath/Isquiotibiales.png', fatigueMap['Isquiotibiales']),
        ]
      ],
    );
  }

  Widget _buildOverlay(String assetPath, double? fatigue) {
    final f = fatigue ?? 0.0;

    // Lógica de color: Verde -> Amarillo -> Rojo
    Color glowColor;
    if (f < 0.3) {
      glowColor = AppColors.muscleFresh.withOpacity(0.1); // Casi invisible
    } else if (f < 0.7) {
      glowColor = AppColors.muscleRecovering.withOpacity(0.6);
    } else {
      glowColor = AppColors.muscleFatigued.withOpacity(0.8);
    }

    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      color: glowColor,
      colorBlendMode: BlendMode.srcATop, // Pinta solo sobre el músculo
      errorBuilder: (context, error, stackTrace) {
        // Esto evita que la app explote si falta una imagen
        return const SizedBox(); 
      },
    );
  }
}