// lib/widgets/interactive_body_map.dart

import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';
import '../models/muscle_data.dart';
import '../theme/app_colors.dart';

class InteractiveBodyMap extends StatefulWidget {
  final Map<String, double> fatigueMap;
  final bool isFront;
  final Function(String)? onMuscleTap;
  final String? selectedMuscleId;

  const InteractiveBodyMap({
    super.key,
    required this.fatigueMap,
    this.isFront = true,
    this.onMuscleTap,
    this.selectedMuscleId,
  });

  @override
  State<InteractiveBodyMap> createState() => _InteractiveBodyMapState();
}

class _InteractiveBodyMapState extends State<InteractiveBodyMap> {
  // Dimensiones estándar del SVG original
  final double svgWidth = 375.42;
  final double svgHeight = 832.97;

  @override
  Widget build(BuildContext context) {
    // Filtramos los músculos según la vista (frontal o posterior)
    final visibleMuscles = allMuscleParts
        .where((m) => m.face == (widget.isFront ? "ant" : "post"))
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculamos la escala para que el cuerpo se ajuste a la pantalla
        final double scale = constraints.maxHeight / svgHeight;

        return Center(
          child: SizedBox(
            width: svgWidth * scale,
            height: svgHeight * scale,
            child: GestureDetector(
              onTapUp: (details) => _handleTap(details, visibleMuscles, scale),
              child: CustomPaint(
                painter: BodyPainter(
                  muscles: visibleMuscles,
                  fatigueMap: widget.fatigueMap,
                  scale: scale,
                  selectedMuscleId: widget.selectedMuscleId,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTap(
    TapUpDetails details,
    List<MusclePart> muscles,
    double scale,
  ) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localOffset = box.globalToLocal(details.globalPosition);
    // Des-escalamos el punto de toque para coincidir con las coordenadas del SVG
    final Offset scaledOffset = localOffset / scale;

    for (var muscle in muscles) {
      final Path path = parseSvgPathData(muscle.pathSvg);
      // Verificamos si el toque cayó dentro del dibujo del músculo
      if (path.contains(scaledOffset)) {
        if (widget.onMuscleTap != null) {
          // --- CORRECCIÓN CRÍTICA ---
          // Antes enviaba muscle.name, ahora envía muscle.id
          // Esto permite que el selector encuentre los ejercicios correctamente.
          widget.onMuscleTap!(muscle.id); 
        } else {
          // Comportamiento por defecto (ej: en pantalla de fatiga): Mostrar nombre
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(muscle.name),
              duration: const Duration(milliseconds: 500),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        break; // Detenemos el bucle al encontrar el músculo tocado
      }
    }
  }
}

class BodyPainter extends CustomPainter {
  final List<MusclePart> muscles;
  final Map<String, double> fatigueMap;
  final double scale;
  final String? selectedMuscleId;

  BodyPainter({
    required this.muscles,
    required this.fatigueMap,
    required this.scale,
    this.selectedMuscleId,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(scale);
    final Paint borderPaint = Paint()
      ..color = Colors.white30
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (var muscle in muscles) {
      final Path path = parseSvgPathData(muscle.pathSvg);
      final double fatigue = fatigueMap[muscle.id] ?? 0.0;

      // Verificamos si este músculo está seleccionado
      final bool isSelected = selectedMuscleId == muscle.id;

      Color muscleColor;

      if (isSelected) {
        muscleColor = AppColors.primary; // Resaltado azul/cian si está seleccionado
      } else if (fatigue > 0) {
        // Lógica de mapa de calor (Verde -> Rojo)
        final double effectiveFatigue = fatigue > 1.0 ? 1.0 : fatigue;
        muscleColor = Color.lerp(Colors.green, Colors.red, effectiveFatigue)!;
      } else {
        // Color gris neutro por defecto
        muscleColor = Colors.grey[800]!;
      }

      // Pintar el relleno
      canvas.drawPath(path, Paint()..color = muscleColor);

      // Pintar el borde
      if (isSelected) {
        canvas.drawPath(
          path,
          borderPaint
            ..strokeWidth = 2.0
            ..color = Colors.white, // Borde blanco brillante si está seleccionado
        );
      } else {
        canvas.drawPath(
          path,
          borderPaint
            ..strokeWidth = 1.0
            ..color = Colors.white30,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant BodyPainter oldDelegate) => true;
}