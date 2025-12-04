// lib/widgets/interactive_body_map.dart

import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';
import '../models/muscle_data.dart'; 

class InteractiveBodyMap extends StatefulWidget {
  final Map<String, double> fatigueMap;
  final bool isFront; 

  const InteractiveBodyMap({
    super.key,
    required this.fatigueMap,
    this.isFront = true,
  });

  @override
  State<InteractiveBodyMap> createState() => _InteractiveBodyMapState();
}

class _InteractiveBodyMapState extends State<InteractiveBodyMap> {
  final double svgWidth = 375.42;
  final double svgHeight = 832.97;

  @override
  Widget build(BuildContext context) {
    final visibleMuscles = allMuscleParts.where((m) => 
      m.face == (widget.isFront ? "ant" : "post")
    ).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
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
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset localOffset = box.globalToLocal(details.globalPosition);
    final Offset scaledOffset = localOffset / scale;

    for (var muscle in muscles) {
      final Path path = parseSvgPathData(muscle.pathSvg);
      if (path.contains(scaledOffset)) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(muscle.name),
            duration: const Duration(milliseconds: 500),
            behavior: SnackBarBehavior.floating,
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

  BodyPainter({required this.muscles, required this.fatigueMap, required this.scale});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(scale);
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0; 

    for (var muscle in muscles) {
      final Path path = parseSvgPathData(muscle.pathSvg);
      final double fatigue = fatigueMap[muscle.id] ?? 0.0;
      
      Color muscleColor;
      if (fatigue > 0) {
        muscleColor = Color.lerp(Colors.green, Colors.red, fatigue)!;
      } else {
        muscleColor = Colors.grey[800]!; 
      }

      canvas.drawPath(path, Paint()..color = muscleColor);
      canvas.drawPath(path, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BodyPainter oldDelegate) => true;
}