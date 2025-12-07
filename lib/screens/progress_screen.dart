import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/history_model.dart';
import '../models/exercise_model.dart'; // Necesitamos saber los nombres de los ejercicios
import '../theme/app_colors.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String _selectedMetric = '1RM Estimado'; // Métrica científica por defecto
  String? _selectedExerciseId; // ID del ejercicio a analizar
  List<WorkoutSession> _history = [];
  Map<String, String> _availableExercises = {}; // Mapa ID -> Nombre para el selector

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    final historyBox = Hive.box<WorkoutSession>('historyBox');
    final exerciseBox = Hive.box<Exercise>('exerciseBox');

    // 1. Cargo el historial ordenado por fecha
    final rawHistory = historyBox.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // 2. Extraigo qué ejercicios se han realizado alguna vez para llenar el filtro
    final Map<String, String> foundExercises = {};
    
    for (var session in rawHistory) {
      for (var ex in session.exercises) {
        if (!foundExercises.containsKey(ex.exerciseId)) {
          // Busco el nombre real en la caja de ejercicios, o uso el guardado en el historial
          final realName = exerciseBox.get(ex.exerciseId)?.name ?? ex.exerciseName;
          foundExercises[ex.exerciseId] = realName;
        }
      }
    }

    setState(() {
      _history = rawHistory;
      _availableExercises = foundExercises;
      
      // Selecciono el primer ejercicio encontrado por defecto para no mostrar vacío
      if (_selectedExerciseId == null && _availableExercises.isNotEmpty) {
        _selectedExerciseId = _availableExercises.keys.first;
      }
    });
  }

  // --- LÓGICA MATEMÁTICA DEL GRÁFICO ---
  List<FlSpot> _getSpots() {
    if (_selectedExerciseId == null) return [];

    List<FlSpot> spots = [];
    int indexCounter = 0; // Usamos un contador secuencial para el eje X

    for (var session in _history) {
      // Buscamos si esta sesión contiene el ejercicio seleccionado
      // .firstWhereOrNull (pero sin importar librerias extra, lo hacemos manual)
      WorkoutExercise? targetExercise;
      try {
        targetExercise = session.exercises.firstWhere((e) => e.exerciseId == _selectedExerciseId);
      } catch (e) {
        targetExercise = null;
      }

      if (targetExercise != null) {
        double yValue = 0;

        if (_selectedMetric == 'Volumen Total') {
          // Volumen = Series * Reps * Peso
          for (var set in targetExercise.sets) {
            yValue += set.weight * set.reps;
          }
        } else if (_selectedMetric == '1RM Estimado') {
          // Buscamos el MEJOR set de la sesión para estimar el 1RM
          double max1RM = 0;
          for (var set in targetExercise.sets) {
            if (set.weight > 0 && set.reps > 0) {
              // Fórmula de Epley: Peso * (1 + Reps/30)
              double estimated = set.weight * (1 + set.reps / 30);
              if (estimated > max1RM) max1RM = estimated;
            }
          }
          yValue = max1RM;
        } else if (_selectedMetric == 'Peso Máximo') {
           // Solo el peso más alto movido (sin importar reps)
           double maxWeight = 0;
           for (var set in targetExercise.sets) {
             if (set.weight > maxWeight) maxWeight = set.weight;
           }
           yValue = maxWeight;
        }

        // Solo añadimos el punto si hubo actividad real (>0)
        if (yValue > 0) {
          spots.add(FlSpot(indexCounter.toDouble(), yValue));
        }
      }
      // Incrementamos el contador de "tiempo" (sesiones) incluso si no hizo el ejercicio
      // para mantener la escala temporal, o solo cuando lo hace? 
      // Para gráficos de progreso, mejor comprimir:
      if (targetExercise != null) indexCounter++;
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final spots = _getSpots();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Análisis de Progreso'),
        backgroundColor: AppColors.surface,
        elevation: 0,
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
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("EJERCICIO", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 5),
                  DropdownButtonFormField<String>(
                    value: _selectedExerciseId,
                    isExpanded: true, // Para que nombres largos no rompan
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                  const Divider(color: Colors.white24),
                  const Text("MÉTRICA CIENTÍFICA", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  DropdownButtonFormField<String>(
                    value: _selectedMetric,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
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
                          const Icon(Icons.show_chart, size: 60, color: Colors.white10),
                          const SizedBox(height: 10),
                          Text(
                            _availableExercises.isEmpty 
                              ? 'Registra tu primer entrenamiento.' 
                              : 'No hay datos para este ejercicio.',
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: _selectedMetric == '1RM Estimado' ? 5 : null, // Líneas cada 5kg si es fuerza
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.white10,
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
                                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                                );
                              },
                            ),
                          ),
                          bottomTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false), // Ocultamos fechas para limpieza visual
                          ),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true, // Curva suave para estética moderna
                            curveSmoothness: 0.2,
                            color: AppColors.primary,
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 4,
                                  color: AppColors.surface,
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
                            // El color de fondo del tooltip lo maneja la librería, a veces necesita configuración extra
                            // pero el default suele ser oscuro en modo oscuro.
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            const Center(
              child: Text(
                "Historial de Sesiones →",
                style: TextStyle(color: Colors.white24, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}