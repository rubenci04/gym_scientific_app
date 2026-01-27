import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // Para ThemeProvider
import '../models/user_model.dart';
import '../models/muscle_data.dart';
import '../theme/app_colors.dart';
import '../services/fatigue_service.dart';
import '../widgets/interactive_body_map.dart';
// Asegúrate de importar OnboardingScreen si quieres redirigir
import 'onboarding_screen.dart'; 

class BodyStatusScreen extends StatefulWidget {
  const BodyStatusScreen({super.key});

  @override
  State<BodyStatusScreen> createState() => _BodyStatusScreenState();
}

class _BodyStatusScreenState extends State<BodyStatusScreen> {
  bool _isFrontView = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    // Protección: Si la caja no está abierta, mostrar carga
    if (!Hive.isBoxOpen('userBox')) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ValueListenableBuilder(
      valueListenable: Hive.box<UserProfile>('userBox').listenable(),
      builder: (context, Box<UserProfile> box, _) {
        
        // 1. INTENTO ROBUSTO DE OBTENER USUARIO
        UserProfile? currentUser = box.get('currentUser');
        
        // Fallback: Si no hay 'currentUser' pero la caja tiene datos, coge el primero
        if (currentUser == null && box.isNotEmpty) {
           currentUser = box.values.first;
        }

        // 2. ESTADO SIN USUARIO (Actionable)
        if (currentUser == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 60, color: Colors.grey),
                  const SizedBox(height: 20),
                  const Text("No se encontró perfil de usuario."),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Navegar al onboarding para crear perfil
                      Navigator.pushReplacement(
                        context, 
                        MaterialPageRoute(builder: (_) => const OnboardingScreen())
                      );
                    },
                    child: const Text("Crear Perfil"),
                  )
                ],
              ),
            ),
          );
        }

        // 3. CÁLCULOS (Solo si hay usuario)
        final fatigueMap = FatigueService.calculateMuscleFatigue(currentUser);
        final svgFatigueMap = _mapGenericFatigueToSvg(fatigueMap);

        // Cálculo de Readiness
        double totalFatigue = 0;
        int count = 0;
        fatigueMap.forEach((_, val) {
          totalFatigue += val;
          count++;
        });
        
        double avgFatigue = count > 0 ? totalFatigue / count : 0;
        double readinessScore = (1.0 - avgFatigue).clamp(0.0, 1.0) * 100;

        final musclesToShow = allMuscleParts
            .where((m) => m.face == (_isFrontView ? 'ant' : 'post'))
            .map((m) => m.name)
            .toSet()
            .toList();

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text('Análisis Corporal', style: theme.appBarTheme.titleTextStyle),
            backgroundColor: theme.appBarTheme.backgroundColor,
            elevation: 0,
            iconTheme: theme.iconTheme,
            actions: [
              // Botón de Girar Cuerpo
              IconButton(
                icon: Icon(_isFrontView ? Icons.flip_to_back : Icons.flip_to_front),
                tooltip: "Girar Cuerpo",
                onPressed: () => setState(() => _isFrontView = !_isFrontView),
              ),
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
          body: Column(
            children: [
              // --- DATOS RÁPIDOS ---
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                color: theme.cardColor.withOpacity(0.5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem("Peso", "${currentUser.weight} kg", theme),
                    _buildStatItem("Altura", "${currentUser.height} cm", theme),
                    _buildStatItem("Somatotipo", currentUser.somatotype.toString().split('.').last, theme, isBold: true),
                  ],
                ),
              ),

              // --- PANEL DE DIAGNÓSTICO ---
              _buildReadinessCard(readinessScore, theme),

              const SizedBox(height: 10),
              
              // Leyenda
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(isDark ? Colors.grey[800]! : Colors.grey[300]!, 'Fresco', theme),
                  const SizedBox(width: 15),
                  _buildLegendItem(Colors.green, 'Estímulo', theme),
                  const SizedBox(width: 15),
                  _buildLegendItem(Colors.red, 'Fatiga Alta', theme),
                ],
              ),

              // --- MAPA INTERACTIVO ---
              Expanded(
                flex: 4, 
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: InteractiveBodyMap(
                    fatigueMap: svgFatigueMap,
                    isFront: _isFrontView,
                  ),
                ),
              ),

              // --- LISTA DETALLADA ---
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))
                    ]
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Estado Muscular Local",
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Icon(Icons.keyboard_arrow_down, color: theme.iconTheme.color?.withOpacity(0.5))
                        ],
                      ),
                      const SizedBox(height: 15),
                      Expanded(
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          children: musclesToShow.map((muscleName) {
                            // Buscar ID de muestra para el mapa
                            String sampleId = "";
                            try {
                               sampleId = allMuscleParts.firstWhere((m) => m.name == muscleName).id;
                            } catch (e) {
                               return const SizedBox.shrink();
                            }
                            
                            double val = svgFatigueMap[sampleId] ?? 0.0;
                            
                            if (val > 0.05) return _buildMuscleBar(muscleName, val, theme);
                            return const SizedBox.shrink(); 
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, ThemeData theme, {bool isBold = false}) {
    return Column(
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey)),
        Text(
          value, 
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? AppColors.primary : theme.textTheme.bodyLarge?.color
          )
        ),
      ],
    );
  }

  Widget _buildReadinessCard(double score, ThemeData theme) {
    Color scoreColor = score > 80 ? Colors.greenAccent : (score > 50 ? Colors.orangeAccent : Colors.redAccent);
    if (theme.brightness == Brightness.light) {
       scoreColor = score > 80 ? Colors.green[700]! : (score > 50 ? Colors.orange[800]! : Colors.red[700]!);
    }

    String message = score > 80 ? "Listo para entrenar fuerte." : (score > 50 ? "Entrena con precaución." : "Prioriza el descanso.");

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme.brightness == Brightness.dark 
              ? [theme.cardColor, theme.cardColor.withOpacity(0.8)]
              : [Colors.white, Colors.grey[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          if (theme.brightness == Brightness.light)
            BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 5, offset: const Offset(0, 3))
        ]
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60, height: 60,
                child: CircularProgressIndicator(
                  value: score / 100,
                  backgroundColor: theme.disabledColor.withOpacity(0.2),
                  color: scoreColor,
                  strokeWidth: 6,
                ),
              ),
              Text("${score.toInt()}%", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("RECUPERACIÓN SISTÉMICA", style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 1.5)),
                const SizedBox(height: 4),
                Text(message, style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Map<String, double> _mapGenericFatigueToSvg(Map<String, double> general) {
    final Map<String, double> svgMap = {};

    void assign(String generalKey, List<String> ids) {
      if (general.containsKey(generalKey)) {
        for (var id in ids) svgMap[id] = general[generalKey]!;
      }
    }

    // Mapeo exhaustivo para cubrir todas las partes del cuerpo
    assign('Pectorales', ['pec_der', 'pec_izq']);
    assign('Abdominales', ['abd_der', 'abd_izq']);
    assign('Oblicuos', ['oblicuo_der', 'oblicuo_izq']);
    assign('Aductores', ['aduc_der', 'aduc_izq']); 
    assign('Abductores', ['abduc_der', 'abduc_izq']);
    assign('Hombros', ['hombro_der', 'hombro_izq', 'hombro_post_der', 'hombro_post_izq']);
    assign('Biceps', ['biceps_der', 'biceps_izq']);
    assign('Cuadriceps', ['quad_der', 'quad_izq']);
    assign('Dorsales', ['dorsal_der', 'dorsal_izq']);
    assign('EspaldaAlta', ['trap_der', 'trap_izq', 'trap_der_post', 'trap_izq_post', 'espalda_alta_der', 'espalda_alta_izq']);
    assign('Triceps', ['triceps_der', 'triceps_izq']);
    assign('Gluteos', ['gluteo_der', 'gluteo_izq']);
    assign('Isquiotibiales', ['isquio_der', 'isquio_izq']);
    assign('Gemelos', ['gemelo_der', 'gemelo_izq']);
    assign('Lumbares', ['lumb_der', 'lumb_izq']);
    assign('Trapecios', ['trap_der', 'trap_izq', 'trap_der_post', 'trap_izq_post']);
    assign('Antebrazos', ['antebrazo_der', 'antebrazo_izq']);

    return svgMap;
  }

  Widget _buildLegendItem(Color color, String label, ThemeData theme) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildMuscleBar(String label, double fatigue, ThemeData theme) {
    Color color;
    String statusText;

    if (fatigue <= 0.05) {
      color = theme.disabledColor;
      statusText = "Recuperado";
    } else if (fatigue < 0.6) {
      color = AppColors.primary;
      statusText = "Activo";
    } else {
      color = Colors.redAccent;
      statusText = "Fatigado";
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
              Text(statusText, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fatigue,
              backgroundColor: theme.dividerColor.withOpacity(0.2),
              color: color,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}