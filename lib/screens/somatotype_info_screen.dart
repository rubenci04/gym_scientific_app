import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart'; // Para el tema
import '../main.dart'; // Para acceder al ThemeProvider
import '../models/user_model.dart';
import '../data/somatotype_data.dart';
import '../theme/app_colors.dart';

class SomatotypeInfoScreen extends StatelessWidget {
  const SomatotypeInfoScreen({super.key});

  // Lógica científica para recalcular el somatotipo si cambian las medidas
  Somatotype _recalculateSomatotype(double weight, double height, double wrist) {
    double bmi = weight / ((height / 100) * (height / 100));
    double rIndex = height / wrist;

    if (bmi < 19 && rIndex > 10.4) return Somatotype.ectomorph;
    if (bmi > 25 && rIndex < 9.6) return Somatotype.endomorph;
    return Somatotype.mesomorph;
  }

  void _showEditProfileDialog(BuildContext context, UserProfile user) {
    final weightCtrl = TextEditingController(text: user.weight.toString());
    final heightCtrl = TextEditingController(text: user.height.toString());
    final wristCtrl = TextEditingController(text: user.wristCircumference.toString());
    final ankleCtrl = TextEditingController(text: user.ankleCircumference.toString());
    
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Actualizar Perfil", style: theme.textTheme.titleLarge),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEditField(weightCtrl, "Peso Corporal (kg)", Icons.monitor_weight, theme),
              const SizedBox(height: 15),
              _buildEditField(heightCtrl, "Altura (cm)", Icons.height, theme),
              const SizedBox(height: 15),
              _buildEditField(wristCtrl, "Muñeca (cm)", Icons.watch, theme),
              const SizedBox(height: 15),
              _buildEditField(ankleCtrl, "Tobillo (cm)", Icons.accessibility, theme),
              const SizedBox(height: 10),
              Text(
                "Nota: Cambiar estos datos recalculará tu somatotipo y objetivos calóricos.",
                style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancelar", style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              // 1. Obtener nuevos valores
              double newWeight = double.tryParse(weightCtrl.text) ?? user.weight;
              double newHeight = double.tryParse(heightCtrl.text) ?? user.height;
              double newWrist = double.tryParse(wristCtrl.text) ?? user.wristCircumference;
              double newAnkle = double.tryParse(ankleCtrl.text) ?? user.ankleCircumference;

              // 2. Recalcular Somatotipo
              Somatotype newSomatotype = _recalculateSomatotype(newWeight, newHeight, newWrist);

              // 3. Recalcular TDEE (Calorías) si el peso cambió
              // Fórmula básica simplificada para actualizar mantenimiento
              double bmr = (10 * newWeight) + (6.25 * newHeight) - (5 * user.age) + (user.gender == 'Masculino' ? 5 : -161);
              double activityFactor = user.daysPerWeek >= 5 ? 1.55 : 1.375;
              double newTdee = bmr * activityFactor;

              // Ajuste por objetivo (mantenemos el objetivo actual)
              if (user.goal == TrainingGoal.weightLoss) newTdee -= 500;
              if (user.goal == TrainingGoal.hypertrophy) newTdee += 300;

              // 4. Guardar todo en Hive
              user.weight = newWeight;
              user.height = newHeight;
              user.wristCircumference = newWrist;
              user.ankleCircumference = newAnkle;
              user.somatotype = newSomatotype;
              user.tdee = newTdee;
              
              user.save(); // ¡Esto actualiza toda la app!
              
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Perfil actualizado. Nuevo tipo: ${newSomatotype.toString().split('.').last}"),
                  behavior: SnackBarBehavior.floating,
                )
              );
            },
            child: const Text("Guardar y Recalcular"),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(TextEditingController controller, String label, IconData icon, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: AppColors.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        filled: true,
        fillColor: isDark ? Colors.black12 : Colors.grey[100],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tema dinámico
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Mi Perfil y Somatotipo', style: theme.appBarTheme.titleTextStyle),
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: theme.iconTheme,
        actions: [
          // Botón de Edición (El protagonista aquí)
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.primary),
            tooltip: "Editar Datos",
            onPressed: () {
              final user = Hive.box<UserProfile>('userBox').get('currentUser');
              if (user != null) _showEditProfileDialog(context, user);
            },
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
      body: ValueListenableBuilder(
        valueListenable: Hive.box<UserProfile>('userBox').listenable(),
        builder: (context, Box<UserProfile> box, _) {
          final user = box.get('currentUser');
          if (user == null) {
            return Center(child: Text("Sin usuario", style: TextStyle(color: theme.textTheme.bodyLarge?.color)));
          }

          final somatotype = user.somatotype;
          final content = SomatotypeData.data[somatotype] ??
              SomatotypeData.data[Somatotype.undefined]!;

          // Construcción de la ruta de imagen según el somatotipo
          String folder = user.gender == 'Masculino' ? 'Male' : 'Female';
          String typeFilePart = 'Mesomorfo'; // Default
          if (somatotype == Somatotype.ectomorph) typeFilePart = 'Ectomorfo';
          if (somatotype == Somatotype.endomorph) typeFilePart = 'Endomorfo';
          
          final imagePath = 'assets/images/somatotypes/$folder/$folder-$typeFilePart.png';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- CABECERA DE PERFIL ---
                _buildProfileHeader(user, content.title, imagePath, theme),
                
                const SizedBox(height: 25),
                Text("Tus Medidas Actuales", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                
                // --- GRID DE DATOS BIOMÉTRICOS ---
                _buildStatsGrid(user, theme),

                const SizedBox(height: 20),
                
                // --- TARJETA DE HISTORIAL (FECHA) ---
                _buildHistoryCard(theme),

                const SizedBox(height: 30),
                Divider(color: theme.dividerColor),
                const SizedBox(height: 20),

                // --- INFORMACIÓN EDUCATIVA DEL SOMATOTIPO ---
                Text("Análisis: ${content.title}", style: const TextStyle(color: AppColors.secondary, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                _buildSection("Características", content.description, Icons.info_outline, theme),
                const SizedBox(height: 15),
                _buildSection("Entrenamiento Recomendado", content.trainingAdvice, Icons.fitness_center, theme),
                const SizedBox(height: 15),
                _buildSection("Nutrición Sugerida", content.nutritionAdvice, Icons.restaurant, theme),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(UserProfile user, String typeTitle, String imagePath, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
        boxShadow: isDark 
            ? [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))]
            : [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          // Avatar / Imagen Somatotipo
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey[200],
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.5))
            ),
            child: ClipOval(
              child: Image.asset(
                imagePath, 
                fit: BoxFit.contain, 
                errorBuilder: (c,e,s) => Icon(Icons.person, size: 40, color: theme.disabledColor)
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name, 
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3))
                  ),
                  child: Text(
                    typeTitle.toUpperCase(), 
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatsGrid(UserProfile user, ThemeData theme) {
    // Calculamos el IMC simple
    double bmi = user.weight / ((user.height / 100) * (user.height / 100));

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1, 
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _buildStatCard("Edad", "${user.age} años", Icons.cake, theme),
        _buildStatCard("Peso", "${user.weight} kg", Icons.monitor_weight, theme),
        _buildStatCard("Altura", "${user.height} cm", Icons.height, theme),
        _buildStatCard("Muñeca", "${user.wristCircumference} cm", Icons.watch, theme),
        _buildStatCard("Tobillo", "${user.ankleCircumference} cm", Icons.accessibility, theme),
        _buildStatCard("IMC", bmi.toStringAsFixed(1), Icons.calculate, theme),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.3))
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isDark ? Colors.grey : AppColors.primary.withOpacity(0.7), size: 20),
          const SizedBox(height: 8),
          Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(ThemeData theme) {
    final now = DateTime.now();
    final dateStr = "${now.day}/${now.month}/${now.year}";
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, color: AppColors.secondary),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Última actualización", style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12)),
                Text(dateStr, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String text, IconData icon, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.secondary, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}