import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/user_model.dart';
import '../theme/app_colors.dart';
import '../services/fatigue_service.dart';

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
    final currentUser = userBox.get('currentUser');

    final fatigueMap = FatigueService.calculateMuscleFatigue(currentUser);

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

          Expanded(
            flex: 3,
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 3.0,
              child: CustomPaint(
                size: const Size(300, 500),
                painter: BodyHeatmapPainter(
                  fatigueMap: fatigueMap,
                  isFront: _isFrontView,
                ),
              ),
            ),
          ),

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
                        (muscleKey) => _buildMuscleBar(
                          muscleKey,
                          FatigueService.getFatigueLevel(
                            muscleKey,
                            currentUser,
                          ),
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
    Color color = fatigue < 0.3
        ? AppColors.muscleFresh
        : (fatigue < 0.7
              ? AppColors.muscleRecovering
              : AppColors.muscleFatigued);
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

class BodyHeatmapPainter extends CustomPainter {
  final Map<String, double> fatigueMap;
  final bool isFront;

  BodyHeatmapPainter({required this.fatigueMap, required this.isFront});

  @override
  void paint(Canvas canvas, Size size) {
    final outlinePaint = Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    if (isFront) {
      // Head
      _drawHead(
        canvas,
        size,
        const Offset(0.5, 0.1),
        0.08,
        Colors.grey,
        outlinePaint,
      );

      // Chest (Pectorales) - More organic shape
      _drawPath(canvas, size, [
        const Offset(0.30, 0.20),
        const Offset(0.70, 0.20),
        const Offset(0.65, 0.35),
        const Offset(0.35, 0.35),
      ], 'Pectorales');

      // Abs (Abdominales)
      _drawPath(canvas, size, [
        const Offset(0.38, 0.35),
        const Offset(0.62, 0.35),
        const Offset(0.58, 0.50),
        const Offset(0.42, 0.50),
      ], 'Abdominales');

      // Shoulders (Hombros)
      _drawPath(canvas, size, [
        const Offset(0.20, 0.18),
        const Offset(0.30, 0.20),
        const Offset(0.30, 0.28),
        const Offset(0.18, 0.25),
      ], 'Hombros'); // Left
      _drawPath(canvas, size, [
        const Offset(0.70, 0.20),
        const Offset(0.80, 0.18),
        const Offset(0.82, 0.25),
        const Offset(0.70, 0.28),
      ], 'Hombros'); // Right

      // Biceps
      _drawPath(canvas, size, [
        const Offset(0.18, 0.28),
        const Offset(0.30, 0.30),
        const Offset(0.28, 0.40),
        const Offset(0.15, 0.38),
      ], 'Biceps'); // Left
      _drawPath(canvas, size, [
        const Offset(0.70, 0.30),
        const Offset(0.82, 0.28),
        const Offset(0.85, 0.38),
        const Offset(0.72, 0.40),
      ], 'Biceps'); // Right

      // Quads (Cuadriceps)
      _drawPath(canvas, size, [
        const Offset(0.35, 0.50),
        const Offset(0.48, 0.50),
        const Offset(0.46, 0.75),
        const Offset(0.38, 0.75),
      ], 'Cuadriceps'); // Left
      _drawPath(canvas, size, [
        const Offset(0.52, 0.50),
        const Offset(0.65, 0.50),
        const Offset(0.62, 0.75),
        const Offset(0.54, 0.75),
      ], 'Cuadriceps'); // Right
    } else {
      // Head
      _drawHead(
        canvas,
        size,
        const Offset(0.5, 0.1),
        0.08,
        Colors.grey,
        outlinePaint,
      );

      // Back (Dorsales)
      _drawPath(canvas, size, [
        const Offset(0.25, 0.20),
        const Offset(0.75, 0.20),
        const Offset(0.60, 0.45),
        const Offset(0.40, 0.45),
      ], 'Dorsales');

      // Glutes (Gluteos)
      _drawPath(canvas, size, [
        const Offset(0.35, 0.45),
        const Offset(0.65, 0.45),
        const Offset(0.65, 0.60),
        const Offset(0.35, 0.60),
      ], 'Gluteos');

      // Triceps
      _drawPath(canvas, size, [
        const Offset(0.18, 0.28),
        const Offset(0.30, 0.30),
        const Offset(0.28, 0.40),
        const Offset(0.15, 0.38),
      ], 'Triceps'); // Left
      _drawPath(canvas, size, [
        const Offset(0.70, 0.30),
        const Offset(0.82, 0.28),
        const Offset(0.85, 0.38),
        const Offset(0.72, 0.40),
      ], 'Triceps'); // Right

      // Hamstrings (Isquiotibiales)
      _drawPath(canvas, size, [
        const Offset(0.38, 0.60),
        const Offset(0.46, 0.60),
        const Offset(0.46, 0.75),
        const Offset(0.38, 0.75),
      ], 'Isquiotibiales'); // Left
      _drawPath(canvas, size, [
        const Offset(0.54, 0.60),
        const Offset(0.62, 0.60),
        const Offset(0.62, 0.75),
        const Offset(0.54, 0.75),
      ], 'Isquiotibiales'); // Right

      // Calves (Gemelos)
      _drawPath(canvas, size, [
        const Offset(0.38, 0.78),
        const Offset(0.46, 0.78),
        const Offset(0.44, 0.90),
        const Offset(0.40, 0.90),
      ], 'Gemelos'); // Left
      _drawPath(canvas, size, [
        const Offset(0.54, 0.78),
        const Offset(0.62, 0.78),
        const Offset(0.60, 0.90),
        const Offset(0.56, 0.90),
      ], 'Gemelos'); // Right
    }
  }

  void _drawHead(
    Canvas canvas,
    Size size,
    Offset center,
    double radiusPct,
    Color color,
    Paint outlinePaint,
  ) {
    canvas.drawCircle(
      Offset(center.dx * size.width, center.dy * size.height),
      radiusPct * size.width,
      Paint()..color = color,
    );
    canvas.drawCircle(
      Offset(center.dx * size.width, center.dy * size.height),
      radiusPct * size.width,
      outlinePaint,
    );
  }

  void _drawPath(
    Canvas canvas,
    Size size,
    List<Offset> points,
    String muscleKey,
  ) {
    final fatigue = fatigueMap[muscleKey] ?? 0.0;
    Color color;
    if (fatigue < 0.3) {
      color = AppColors.muscleFresh;
    } else if (fatigue < 0.7) {
      color = AppColors.muscleRecovering;
    } else {
      color = AppColors.muscleFatigued;
    }

    final path = Path();
    path.moveTo(points[0].dx * size.width, points[0].dy * size.height);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx * size.width, points[i].dy * size.height);
    }
    path.close();

    // Draw filled shape
    canvas.drawPath(
      path,
      Paint()..color = Color.fromARGB(200, color.red, color.green, color.blue),
    );

    // Draw outline with rounded joins for a smoother look
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white30
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
