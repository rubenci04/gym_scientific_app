import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_model.dart';
import '../models/routine_model.dart';
import '../theme/app_colors.dart';
import 'workout_screen.dart';
import 'body_status_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userBox = Hive.box<UserProfile>('userBox');
    final currentUser = userBox.get('currentUser');
    
    final routineBox = Hive.box<WeeklyRoutine>('routineBox');
    final currentRoutine = routineBox.get('currentRoutine');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Panel de Control', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.accessibility_new, color: AppColors.primary),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (c) => const BodyStatusScreen()));
            },
            tooltip: "Ver Mapa de Fatiga",
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            _buildHeader(currentUser),
            const SizedBox(height: 30),

            // --- ACCESO DIRECTO MAPA ---
            _buildStatusCard(context),
            const SizedBox(height: 30),

            // --- RUTINA ---
            const Text("TU PLAN ASIGNADO", style: TextStyle(color: Colors.grey, letterSpacing: 1.5, fontSize: 12)),
            const SizedBox(height: 10),
            
            if (currentRoutine != null)
              _buildRoutineCard(context, currentRoutine)
            else
              const Center(child: Text("Sin plan asignado.", style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(UserProfile? user) {
    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.primary,
          child: Text(user?.name[0] ?? 'U', style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bienvenido, ${user?.name}', style: const TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
            Text(
              '${user?.somatotype.toString().split('.').last.toUpperCase()} • Objetivo: ${user?.goal.toString().split('.').last}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const BodyStatusScreen())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF2C3E50), Color(0xFF4CA1AF)]),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Estado Corporal", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text("Toca para ver mapa de fatiga", style: TextStyle(color: Colors.white70)),
              ],
            ),
            Icon(Icons.analytics, color: Colors.white, size: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineCard(BuildContext context, WeeklyRoutine routine) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: routine.days.length,
      separatorBuilder: (c, i) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final day = routine.days[index];
        return Card(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            title: Text(day.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(
              "Enfoque: ${day.targetMuscles.join(", ")}", 
              style: const TextStyle(color: AppColors.textSecondary)
            ),
            trailing: const Icon(Icons.play_circle_fill, color: AppColors.secondary, size: 40),
            onTap: () {
              // AQUÍ PASAMOS LA LISTA EXACTA DE EJERCICIOS PARA QUE EL USUARIO NO ELIJA
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WorkoutScreen(
                  dayName: day.name,
                  exerciseIds: day.exerciseIds,
                )),
              );
            },
          ),
        );
      },
    );
  }
}