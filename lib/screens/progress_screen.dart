import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/history_model.dart';
import '../theme/app_colors.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String _selectedMetric = 'Volumen'; // Volumen, Fuerza (1RM estimado)
  List<WorkoutSession> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    final box = Hive.box<WorkoutSession>('historyBox');
    setState(() {
      _history = box.values.toList()..sort((a, b) => a.date.compareTo(b.date));
    });
  }

  List<FlSpot> _getSpots() {
    List<FlSpot> spots = [];
    for (int i = 0; i < _history.length; i++) {
      final session = _history[i];
      double yValue = 0;

      if (_selectedMetric == 'Volumen') {
        // Suma total de peso * reps
        for (var ex in session.exercises) {
          for (var set in ex.sets) {
            yValue += set.weight * set.reps;
          }
        }
      } else {
        // Fuerza: Promedio de peso máximo levantado (simplificado)
        // Idealmente sería por ejercicio, pero para generalizar:
        double maxWeight = 0;
        for (var ex in session.exercises) {
          for (var set in ex.sets) {
            if (set.weight > maxWeight) maxWeight = set.weight;
          }
        }
        yValue = maxWeight;
      }

      spots.add(FlSpot(i.toDouble(), yValue));
    }
    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final spots = _getSpots();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi Progreso'),
        backgroundColor: AppColors.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _selectedMetric,
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: Colors.white),
              items: [
                'Volumen',
                'Fuerza Máxima',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => _selectedMetric = val!),
              decoration: const InputDecoration(
                labelText: 'Métrica',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: AppColors.surface,
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: spots.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay datos suficientes.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: const FlGridData(
                          show: true,
                          drawVerticalLine: false,
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                int index = value.toInt();
                                if (index >= 0 && index < _history.length) {
                                  return Text(
                                    DateFormat.Md().format(
                                      _history[index].date,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 10,
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: spots,
                            isCurved: true,
                            color: AppColors.primary,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Color.fromARGB(
                                51,
                                AppColors.primary.red,
                                AppColors.primary.green,
                                AppColors.primary.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
