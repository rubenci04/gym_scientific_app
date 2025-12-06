import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PlateCalculatorScreen extends StatefulWidget {
  final double initialWeight;

  const PlateCalculatorScreen({super.key, this.initialWeight = 0});

  @override
  State<PlateCalculatorScreen> createState() => _PlateCalculatorScreenState();
}

class _PlateCalculatorScreenState extends State<PlateCalculatorScreen> {
  late TextEditingController _weightController;
  List<double> _plates = [];
  double _barWeight = 20.0; // Barra olímpica estándar

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.initialWeight > 0 ? widget.initialWeight.toString() : '',
    );
    if (widget.initialWeight > 0) {
      _calculatePlates();
    }
  }

  void _calculatePlates() {
    double targetWeight = double.tryParse(_weightController.text) ?? 0;
    if (targetWeight <= _barWeight) {
      setState(() => _plates = []);
      return;
    }

    double weightToLoad = (targetWeight - _barWeight) / 2;
    List<double> availablePlates = [25, 20, 15, 10, 5, 2.5, 1.25];
    List<double> calculated = [];

    for (double plate in availablePlates) {
      while (weightToLoad >= plate) {
        calculated.add(plate);
        weightToLoad -= plate;
      }
    }

    setState(() {
      _plates = calculated;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Calculadora de Placas'),
        backgroundColor: AppColors.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Peso Total (kg)',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: AppColors.surface,
              ),
              onChanged: (_) => _calculatePlates(),
            ),
            const SizedBox(height: 30),
            const Text(
              "Cargar por lado:",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 18),
            ),
            const SizedBox(height: 20),
            if (_plates.isEmpty)
              const Text(
                "Ingresa un peso mayor a 20kg",
                style: TextStyle(color: Colors.grey),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: _plates
                    .map((plate) => _buildPlateWidget(plate))
                    .toList(),
              ),
            const Spacer(),
            Text(
              "Barra: $_barWeight kg",
              style: const TextStyle(color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlateWidget(double weight) {
    Color color;
    double size;

    // Colores estándar IWF (aprox)
    if (weight >= 25) {
      color = Colors.red;
      size = 100;
    } else if (weight >= 20) {
      color = Colors.blue;
      size = 100;
    } else if (weight >= 15) {
      color = Colors.yellow;
      size = 90;
    } else if (weight >= 10) {
      color = Colors.green;
      size = 80;
    } else if (weight >= 5) {
      color = Colors.white;
      size = 60;
    } else {
      color = Colors.grey;
      size = 50;
    }

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(100, 0, 0, 0),
            blurRadius: 5,
            offset: const Offset(2, 2),
          ),
        ],
      ),
      child: Text(
        "$weight",
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.3,
        ),
      ),
    );
  }
}
