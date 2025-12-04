// lib/widgets/interactive_body_map.dart

import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';
import '../models/muscle_data.dart'; // Asegúrate de que esta ruta sea correcta

class InteractiveBodyMap extends StatefulWidget {
  // Mapa que recibe: { "pec_der": 0.8, "abs": 0.2 } (0.0 a 1.0)
  final Map<String, double> fatigueMap;
  final bool isFront; // true = Frente, false = Espalda

  const InteractiveBodyMap({
    super.key,
    required this.fatigueMap,
    this.isFront = true,
  });

  @override
  State<InteractiveBodyMap> createState() => _InteractiveBodyMapState();
}

class _InteractiveBodyMapState extends State<InteractiveBodyMap> {
  // Dimensiones originales del SVG
  final double svgWidth = 375.42;
  final double svgHeight = 832.97;

  @override
  Widget build(BuildContext context) {
    // Filtramos los músculos que corresponden a la vista actual
    final visibleMuscles = allMuscleParts.where((m) => 
      m.face == (widget.isFront ? "ant" : "post")
    ).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculamos la escala para que se ajuste a la pantalla
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
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTap(TapUpDetails details, List<MusclePart> muscles, double scale) {
    // Detectar qué músculo se tocó
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localOffset = box.globalToLocal(details.globalPosition);
    final Offset scaledOffset = localOffset / scale;

    for (var muscle in muscles) {
      final Path path = parseSvgPathData(muscle.pathSvg);
      
      if (path.contains(scaledOffset)) {
        // AQUÍ PUEDES AÑADIR ACCIONES AL TOCAR (Ej. Mostrar nombre)
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Músculo: ${muscle.name}"),
            duration: const Duration(milliseconds: 500),
          )
        );
        break;
      }
    }
  }
}

class BodyPainter extends CustomPainter {
  final List<MusclePart> muscles;
  final Map<String, double> fatigueMap;
  final double scale;

  BodyPainter({
    required this.muscles,
    required this.fatigueMap,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(scale);

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var muscle in muscles) {
      final Path path = parseSvgPathData(muscle.pathSvg);

      // Calculamos el color basado en la fatiga (Verde -> Rojo)
      final double fatigue = fatigueMap[muscle.id] ?? 0.0;
      
      // Color base (Gris oscuro) si fatiga es 0, si no, degradado
      Color muscleColor;
      if (fatigue > 0) {
        muscleColor = Color.lerp(Colors.green, Colors.red, fatigue)!;
      } else {
        muscleColor = Colors.grey[800]!; // Color "apagado"
      }

      final Paint fillPaint = Paint()
        ..color = muscleColor
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BodyPainter oldDelegate) => true;
}