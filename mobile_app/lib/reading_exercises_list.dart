import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'services/reading_api_service.dart';
import 'reading_practice.dart';

class ReadingExercisesList extends StatefulWidget {
  const ReadingExercisesList({super.key});

  @override
  State<ReadingExercisesList> createState() => _ReadingExercisesListState();
}

class _ReadingExercisesListState extends State<ReadingExercisesList> {
  final _apiService = ReadingApiService();
  late Future<List<dynamic>> _exercisesFuture;

  @override
  void initState() {
    super.initState();
    _exercisesFuture = _apiService.getExercises();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Reading Exercises",
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _exercisesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 60, color: Colors.red),
                    const SizedBox(height: 16),
                    Text("Error: ${snapshot.error}", textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _exercisesFuture = _apiService.getExercises();
                        });
                      },
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            );
          }

          final exercises = snapshot.data ?? [];

          if (exercises.isEmpty) {
            return const Center(child: Text("No exercises available yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return _buildExerciseCard(exercise);
            },
          );
        },
      ),
    );
  }

  Widget _buildExerciseCard(dynamic exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: ListTile(
          contentPadding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.logoBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.menu_book_rounded, color: AppColors.logoBlue),
          ),
          title: Text(
            exercise['title'] ?? 'Untitled',
            style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textDark, fontSize: 18),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getLevelColor(exercise['level']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    exercise['level']?.toString().toUpperCase() ?? 'BEGINNER',
                    style: TextStyle(
                      color: _getLevelColor(exercise['level']),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  exercise['language'] ?? 'en-US',
                  style: const TextStyle(color: AppColors.textLight, fontSize: 12),
                ),
              ],
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textLight),
          onTap: () {
            final id = exercise['id'];
            if (id == null) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReadingPractice(exerciseId: id as int),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getLevelColor(String? level) {
    switch (level?.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return AppColors.logoBlue;
    }
  }
}
