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
  final double svgWidth = 375.42;
  final double svgHeight = 832.97;

  @override
  Widget build(BuildContext context) {
    final visibleMuscles = allMuscleParts
        .where((m) => m.face == (widget.isFront ? "ant" : "post"))
        .toList();

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
    final Offset scaledOffset = localOffset / scale;

    for (var muscle in muscles) {
      final Path path = parseSvgPathData(muscle.pathSvg);
      if (path.contains(scaledOffset)) {
        if (widget.onMuscleTap != null) {
          widget.onMuscleTap!(muscle.name);
        } else {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(muscle.name),
              duration: const Duration(milliseconds: 500),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        break;
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

      // Check if this muscle is selected (by ID or Name - trying both for safety)
      // Ideally we should use IDs everywhere, but let's check both to be safe with legacy code
      final bool isSelected =
          selectedMuscleId == muscle.id || selectedMuscleId == muscle.name;

      Color muscleColor;

      if (isSelected) {
        muscleColor = AppColors.primary; // Highlight selected
      } else if (fatigue > 0) {
        // Cap fatigue at 1.0 for color interpolation
        final double effectiveFatigue = fatigue > 1.0 ? 1.0 : fatigue;
        muscleColor = Color.lerp(Colors.green, Colors.red, effectiveFatigue)!;
      } else {
        // Neutral color for non-fatigued/non-selected
        muscleColor = Colors.grey[800]!;
      }

      canvas.drawPath(path, Paint()..color = muscleColor);

      // Draw border (thicker if selected)
      if (isSelected) {
        canvas.drawPath(
          path,
          borderPaint
            ..strokeWidth = 2.0
            ..color = Colors.white,
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
