import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart'; // Necesario para el botón de tema
import '../main.dart'; // Para acceder al ThemeProvider
import '../models/history_model.dart';
import '../models/exercise_model.dart'; 
import '../theme/app_colors.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String _selectedMetric = '1RM Estimado'; 
  String? _selectedExerciseId; 
  List<WorkoutSession> _history = [];
  Map<String, String> _availableExercises = {}; 

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    final historyBox = Hive.box<WorkoutSession>('historyBox');
    final exerciseBox = Hive.box<Exercise>('exerciseBox');

    final rawHistory = historyBox.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final Map<String, String> foundExercises = {};
    
    for (var session in rawHistory) {
      for (var ex in session.exercises) {
        if (!foundExercises.containsKey(ex.exerciseId)) {
          final realName = exerciseBox.get(ex.exerciseId)?.name ?? ex.exerciseName;
          foundExercises[ex.exerciseId] = realName;
        }
      }
    }

    setState(() {
      _history = rawHistory;
      _availableExercises = foundExercises;
      
      if (_selectedExerciseId == null && _availableExercises.isNotEmpty) {
        _selectedExerciseId = _availableExercises.keys.first;
      }
    });
  }

  // --- LÓGICA MATEMÁTICA DEL GRÁFICO ---
  List<FlSpot> _getSpots() {
    if (_selectedExerciseId == null) return [];

    List<FlSpot> spots = [];
    int indexCounter = 0; 

    for (var session in _history) {
      WorkoutExercise? targetExercise;
      try {
        targetExercise = session.exercises.firstWhere((e) => e.exerciseId == _selectedExerciseId);
      } catch (e) {
        targetExercise = null;
      }

      if (targetExercise != null) {
        double yValue = 0;

        if (_selectedMetric == 'Volumen Total') {
          for (var set in targetExercise.sets) {
            yValue += set.weight * set.reps;
          }
        } else if (_selectedMetric == '1RM Estimado') {
          double max1RM = 0;
          for (var set in targetExercise.sets) {
            if (set.weight > 0 && set.reps > 0) {
              // Fórmula de Epley
              double estimated = set.weight * (1 + set.reps / 30);
              if (estimated > max1RM) max1RM = estimated;
            }
          }
          yValue = max1RM;
        } else if (_selectedMetric == 'Peso Máximo') {
           double maxWeight = 0;
           for (var set in targetExercise.sets) {
             if (set.weight > maxWeight) maxWeight = set.weight;
           }
           yValue = maxWeight;
        }

        if (yValue > 0) {
          spots.add(FlSpot(indexCounter.toDouble(), yValue));
        }
      }
      if (targetExercise != null) indexCounter++;
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    // --- TEMA DINÁMICO ---
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    final spots = _getSpots();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Análisis de Progreso', style: theme.appBarTheme.titleTextStyle),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: theme.iconTheme,
        actions: [
          // Botón de Tema
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: isDark ? Colors.orangeAccent : Colors.indigo,
            ),
            tooltip: "Cambiar Tema",
            onPressed: themeProvider.toggleTheme,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- FILTROS SUPERIORES ---
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isDark ? [] : [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 3))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("EJERCICIO", style: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.6), fontSize: 12)),
                  const SizedBox(height: 5),
                  DropdownButtonFormField<String>(
                    value: _selectedExerciseId,
                    isExpanded: true,
                    dropdownColor: theme.cardColor,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87, 
                      fontWeight: FontWeight.bold,
                      fontSize: 16
                    ),
                    items: _availableExercises.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedExerciseId = val),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Divider(color: theme.dividerColor),
                  Text("MÉTRICA CIENTÍFICA", style: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.6), fontSize: 12)),
                  DropdownButtonFormField<String>(
                    value: _selectedMetric,
                    dropdownColor: theme.cardColor,
                    style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 16),
                    items: [
                      '1RM Estimado',
                      'Volumen Total',
                      'Peso Máximo',
                    ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setState(() => _selectedMetric = val!),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),

            // --- GRÁFICO ---
            Expanded(
              child: spots.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.show_chart, size: 60, color: theme.disabledColor),
                          const SizedBox(height: 10),
                          Text(
                            _availableExercises.isEmpty 
                              ? 'Registra tu primer entrenamiento.' 
                              : 'No hay datos para este ejercicio.',
                            style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                          ),
                        ],
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: _selectedMetric == '1RM Estimado' ? 5 : null, 
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: isDark ? Colors.white10 : Colors.black12, // Líneas dinámicas
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 10), // Texto dinámico
                                );
                              },
                            ),
                          ),
                          bottomTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false), 
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true, 
                            curveSmoothness: 0.2,
                            color: AppColors.primary,
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 4,
                                  color: theme.cardColor, // El centro del punto del color de fondo
                                  strokeWidth: 2,
                                  strokeColor: AppColors.primary,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withOpacity(0.3),
                                  AppColors.primary.withOpacity(0.0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            // --- CORRECCIÓN AQUÍ ---
                            // Usamos un color seguro (negro semi-transparente) que siempre queda bien en tooltips
                            tooltipBgColor: Colors.black.withOpacity(0.8), 
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((LineBarSpot touchedSpot) {
                                return LineTooltipItem(
                                  '${touchedSpot.y.toInt()} ${_selectedMetric.contains("Volumen") ? "kg·reps" : "kg"}',
                                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                );
                              }).toList();
                            },
                            tooltipRoundedRadius: 8,
                            tooltipPadding: const EdgeInsets.all(8),
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                "Historial de Sesiones →",
                style: TextStyle(color: theme.textTheme.bodySmall?.color?.withOpacity(0.3), fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}