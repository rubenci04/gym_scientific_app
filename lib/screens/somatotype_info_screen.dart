import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../data/somatotype_data.dart';
import '../theme/app_colors.dart';

class SomatotypeInfoScreen extends StatelessWidget {
  const SomatotypeInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mi Perfil y Somatotipo'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<UserProfile>('userBox').listenable(),
        builder: (context, Box<UserProfile> box, _) {
          final user = box.get('currentUser');
          if (user == null) {
            return const Center(child: Text("Sin usuario", style: TextStyle(color: Colors.white)));
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
                _buildProfileHeader(user, content.title, imagePath),
                
                const SizedBox(height: 25),
                const Text("Tus Medidas Actuales", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                
                // --- GRID DE DATOS BIOMÉTRICOS ---
                _buildStatsGrid(user),

                const SizedBox(height: 20),
                
                // --- TARJETA DE HISTORIAL (FECHA) ---
                _buildHistoryCard(),

                const SizedBox(height: 30),
                const Divider(color: Colors.white24),
                const SizedBox(height: 20),

                // --- INFORMACIÓN EDUCATIVA DEL SOMATOTIPO ---
                Text("Análisis: ${content.title}", style: const TextStyle(color: AppColors.secondary, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                _buildSection("Características", content.description, Icons.info_outline),
                const SizedBox(height: 15),
                _buildSection("Entrenamiento Recomendado", content.trainingAdvice, Icons.fitness_center),
                const SizedBox(height: 15),
                _buildSection("Nutrición Sugerida", content.nutritionAdvice, Icons.restaurant),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(UserProfile user, String typeTitle, String imagePath) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))
        ]
      ),
      child: Row(
        children: [
          // Avatar / Imagen Somatotipo
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: Colors.white10,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.5))
            ),
            child: ClipOval(
              child: Image.asset(
                imagePath, 
                fit: BoxFit.contain, 
                // Icono fallback si no carga la imagen
                errorBuilder: (c,e,s) => const Icon(Icons.person, size: 40, color: Colors.white54)
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
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
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

  Widget _buildStatsGrid(UserProfile user) {
    // Calculamos el IMC simple
    double bmi = user.weight / ((user.height / 100) * (user.height / 100));

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1, // Ajuste para que quepan bien
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: [
        _buildStatCard("Edad", "${user.age} años", Icons.cake),
        _buildStatCard("Peso", "${user.weight} kg", Icons.monitor_weight),
        _buildStatCard("Altura", "${user.height} cm", Icons.height),
        _buildStatCard("Muñeca", "${user.wristCircumference} cm", Icons.watch),
        _buildStatCard("Tobillo", "${user.ankleCircumference} cm", Icons.accessibility),
        _buildStatCard("IMC", bmi.toStringAsFixed(1), Icons.calculate),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05))
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildHistoryCard() {
    // Nota para mí: Muestro la fecha actual como "última verificación".
    // En el futuro, si guardamos historial real, aquí listaríamos las fechas.
    final now = DateTime.now();
    final dateStr = "${now.day}/${now.month}/${now.year}";
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          const Icon(Icons.history, color: AppColors.secondary),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Estado Actual", style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(dateStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          // Botón decorativo por ahora (podría llevar a editar perfil)
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
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
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}