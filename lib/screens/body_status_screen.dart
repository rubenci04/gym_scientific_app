import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/fatigue_service.dart';

class BodyStatusScreen extends StatelessWidget {
  const BodyStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Músculos principales a rastrear
    final muscles = [
      'Pecho', 'Espalda', 'Hombros', 'Bíceps', 'Tríceps', 
      'Cuádriceps', 'Isquios', 'Glúteo'
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mapa de Recuperación'),
        backgroundColor: AppColors.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- LEYENDA ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem(AppColors.muscleFresh, 'Fresco'),
                _buildLegendItem(AppColors.muscleRecovering, 'Recuperando'),
                _buildLegendItem(AppColors.muscleFatigued, 'Fatigado'),
              ],
            ),
            const SizedBox(height: 30),
            
            // --- GRÁFICO CORPORAL (Simplificado con Barras) ---
            Expanded(
              child: ListView.separated(
                itemCount: muscles.length,
                separatorBuilder: (c, i) => const SizedBox(height: 15),
                itemBuilder: (context, index) {
                  final muscle = muscles[index];
                  final fatigue = FatigueService.getFatigueLevel(muscle);
                  return _buildMuscleIndicator(muscle, fatigue);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildMuscleIndicator(String muscle, double fatigue) {
    // Determinar color
    Color statusColor = AppColors.muscleFresh;
    String statusText = "Listo para entrenar";
    
    if (fatigue > 0.3) {
      statusColor = AppColors.muscleRecovering;
      statusText = "Recuperación parcial";
    }
    if (fatigue > 0.7) {
      statusColor = AppColors.muscleFatigued;
      statusText = "Necesita descanso";
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(muscle, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Text("${(fatigue * 100).toInt()}% Fatiga", style: TextStyle(color: statusColor)),
            ],
          ),
          const SizedBox(height: 8),
          // Barra de progreso manual
          Container(
            height: 8,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fatigue == 0 ? 0.01 : fatigue, // Mínimo visible
              child: Container(
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(statusText, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }
}