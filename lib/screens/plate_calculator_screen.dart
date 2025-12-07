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

  // He añadido esto porque me di cuenta de que no siempre usarás la barra de 20kg.
  // A veces usarás la barra Z o una barra femenina. Esto le da flexibilidad PRO.
  double _barWeight = 20.0;
  final List<double> _barOptions = [20.0, 15.0, 10.0];

  @override
  void initState() {
    super.initState();
    // Si la pantalla se abre desde el entrenamiento con un peso ya puesto, lo cargo aquí.
    _weightController = TextEditingController(
      text: widget.initialWeight > 0 ? widget.initialWeight.toString() : '',
    );
    if (widget.initialWeight > 0) {
      _calculatePlates();
    }
  }

  void _calculatePlates() {
    double targetWeight = double.tryParse(_weightController.text) ?? 0;

    // Lógica básica de seguridad: Si el peso es menor que la barra, limpio todo.
    if (targetWeight <= _barWeight) {
      setState(() => _plates = []);
      return;
    }

    // Calculo cuánto peso va en CADA lado de la barra.
    double weightToLoad = (targetWeight - _barWeight) / 2;

    // Defino el inventario estándar de un gimnasio comercial.
    List<double> availablePlates = [25, 20, 15, 10, 5, 2.5, 1.25];
    List<double> calculated = [];

    // Uso un algoritmo "Greedy" (Codicioso): Intento meter siempre el disco más grande
    // que quepa en el espacio restante. Es la forma más eficiente de cargar.
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
        title: const Text('Calculadora de Discos'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      // Uso SingleChildScrollView para evitar errores de píxeles si el teclado sube.
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // --- 1. SECCIÓN DE ENTRADA (Input Grande) ---
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
                ]
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text("Peso Total a Levantar", style: TextStyle(color: Colors.grey, fontSize: 14)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    // He puesto el texto muy grande para que sea legible en el gym.
                    style: const TextStyle(color: AppColors.primary, fontSize: 48, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "0.0",
                      hintStyle: TextStyle(color: Colors.white24),
                      suffixText: "kg",
                      suffixStyle: TextStyle(color: Colors.white30, fontSize: 24),
                    ),
                    onChanged: (_) => _calculatePlates(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),

            // --- 2. SELECTOR DE BARRA ---
            // Es vital permitir cambiar esto rápidamente sin entrar a menús complejos.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Peso de la Barra:", style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(width: 15),
                DropdownButton<double>(
                  value: _barWeight,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 18),
                  underline: Container(height: 2, color: AppColors.secondary),
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.secondary),
                  items: _barOptions.map((w) {
                    return DropdownMenuItem(
                      value: w,
                      child: Text("${w.toInt()} kg"),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _barWeight = val);
                      _calculatePlates(); // Recalculo al instante al cambiar la barra
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 40),

            // --- 3. VISUALIZACIÓN DE LA MANGA (LO MÁS IMPORTANTE) ---
            const Text(
              "CARGAR POR LADO",
              style: TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 1.5, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            if (_plates.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Ingresa un peso superior a la barra (${_barWeight.toInt()}kg)",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white38),
                ),
              )
            else
              // He cambiado el Wrap de círculos por un diseño que simula la barra real.
              // Es mucho más intuitivo ver el perfil de los discos apilados.
              SizedBox(
                height: 220, // Altura suficiente para el disco más grande
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true, // Importante: Llenamos desde la barra (derecha) hacia afuera (izquierda)
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Simulación del tope de la barra (collarín)
                        Container(
                          width: 12,
                          height: 50,
                          decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2)),
                        ),
                        const SizedBox(width: 2),
                        // Los discos generados dinámicamente
                        ..._plates.map((plate) => _buildPlateVisual(plate)),
                        
                        // La punta de la manga de la barra donde se meten los discos
                        Container(
                          width: 40,
                          height: 25,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.grey[500]!, Colors.grey[700]!],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: const BorderRadius.only(topRight: Radius.circular(4), bottomRight: Radius.circular(4))
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Resumen de texto simple debajo de la imagen
            if (_plates.isNotEmpty)
               Padding(
                 padding: const EdgeInsets.only(top: 20),
                 child: Text(
                   _plates.map((e) => e % 1 == 0 ? e.toInt() : e).join(" + "), // Quito decimales .0 si es entero
                   style: const TextStyle(color: Colors.grey, fontSize: 16),
                 ),
               ),
          ],
        ),
      ),
    );
  }

  // --- CONSTRUCTOR DE LA IMAGEN DEL DISCO (VISTA DE PERFIL) ---
  Widget _buildPlateVisual(double weight) {
    Color color;
    double height; // Diámetro del disco
    double thickness; // Grosor del disco

    // Configuro colores y tamaños según estándares IWF aproximados.
    // Esto hace que la app se sienta profesional.
    if (weight >= 25) {
      color = Colors.redAccent;
      height = 200; 
      thickness = 28;
    } else if (weight >= 20) {
      color = Colors.blueAccent;
      height = 200; // 20kg y 25kg suelen tener el mismo diámetro (450mm)
      thickness = 24;
    } else if (weight >= 15) {
      color = Colors.yellow[700]!;
      height = 170;
      thickness = 20;
    } else if (weight >= 10) {
      color = Colors.green;
      height = 140;
      thickness = 18;
    } else if (weight >= 5) {
      color = Colors.white;
      height = 100;
      thickness = 14;
    } else if (weight >= 2.5) {
      color = Colors.black; // Discos pequeños suelen ser negros o de colores variados
      height = 80;
      thickness = 12;
    } else {
      color = Colors.grey;
      height = 60;
      thickness = 10;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 1), // Espacio mínimo entre discos
      width: thickness,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.black38, width: 1),
        boxShadow: [
          BoxShadow(
             color: Colors.black.withOpacity(0.4),
             blurRadius: 3,
             offset: const Offset(2, 0), // Sombra hacia un lado para dar volumen 3D
          )
        ]
      ),
      child: Center(
        child: RotatedBox(
          quarterTurns: 3, // Giro el texto para que se lea vertical en el perfil del disco
          child: Text(
            weight % 1 == 0 ? "${weight.toInt()}" : "$weight",
            style: TextStyle(
              // Si el disco es blanco o amarillo, uso texto negro. Si no, blanco.
              color: (weight == 5 || weight == 15 || weight >= 25) ? Colors.white : Colors.white,
              // Ajuste fino: discos claros necesitan texto oscuro, pero por simplicidad de diseño
              // y contraste en la UI oscura, el blanco con sombra suele ir bien, 
              // excepto en el blanco real.
              shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}