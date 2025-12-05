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
        title: const Text('Tu Somatotipo'),
        backgroundColor: AppColors.surface,
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<UserProfile>('userBox').listenable(),
        builder: (context, Box<UserProfile> box, _) {
          final user = box.get('currentUser');
          if (user == null) return const Center(child: Text("Sin usuario"));

          final somatotype = user.somatotype;
          final content =
              SomatotypeData.data[somatotype] ??
              SomatotypeData.data[Somatotype.undefined]!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: Icon(
                      Icons.accessibility_new, // Placeholder icon
                      size: 80,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    content.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                _buildSection(
                  "Características",
                  content.description,
                  Icons.info_outline,
                ),
                const SizedBox(height: 20),
                _buildSection(
                  "Entrenamiento Recomendado",
                  content.trainingAdvice,
                  Icons.fitness_center,
                ),
                const SizedBox(height: 20),
                _buildSection(
                  "Nutrición Sugerida",
                  content.nutritionAdvice,
                  Icons.restaurant,
                ),
              ],
            ),
          );
        },
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
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
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
