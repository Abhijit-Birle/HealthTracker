import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import '../models/exercise_plan.dart';
import '../models/workout_record.dart';
import '../widgets/bouncing_button.dart';

class WorkoutExecutionPage extends StatefulWidget {
  final ExercisePlan plan;
  final Function(WorkoutRecord, int) onFinish;
  const WorkoutExecutionPage({super.key, required this.plan, required this.onFinish});

  @override
  State<WorkoutExecutionPage> createState() => _WorkoutExecutionPageState();
}

class _WorkoutExecutionPageState extends State<WorkoutExecutionPage> {
  int _currentExerciseIndex = 0;
  late Timer _timer;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) => setState(() => _secondsElapsed++));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  void _nextExercise() {
    if (_currentExerciseIndex < widget.plan.exercises.length - 1) {
      setState(() => _currentExerciseIndex++);
    } else {
      // Finish
      widget.onFinish(
          WorkoutRecord(widget.plan.title, _formatTime(_secondsElapsed), "150 kcal", DateTime.now()),
          100 // XP
      );
      Navigator.pop(context);
      // Show summary could go here
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.plan.exercises[_currentExerciseIndex];
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(_formatTime(_secondsElapsed), style: const TextStyle(fontFamily: 'Courier')), // Timer style
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Progress
            LinearProgressIndicator(
              value: (_currentExerciseIndex + 1) / widget.plan.exercises.length,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation(Color(0xFF00E676)),
            ),
            const SizedBox(height: 30),
            // Animation
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(30)),
                child: Lottie.network(exercise.animationUrl, errorBuilder: (c,e,s) => const Icon(Icons.fitness_center, size: 80, color: Colors.white24)),
              ),
            ),
            const SizedBox(height: 30),
            // Details
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Text(exercise.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatBadge("${exercise.sets} Sets"),
                      const SizedBox(width: 15),
                      _buildStatBadge("${exercise.reps} Reps"),
                      if(exercise.time.isNotEmpty) ...[
                        const SizedBox(width: 15),
                        _buildStatBadge(exercise.time),
                      ]
                    ],
                  ),
                  const Spacer(),
                  BouncingButton(
                    onTap: _nextExercise,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          color: const Color(0xFF00E676),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: const Color(0xFF00E676).withOpacity(0.4), blurRadius: 20)]
                      ),
                      child: Center(child: Text(_currentExerciseIndex < widget.plan.exercises.length - 1 ? "Next Exercise" : "Finish Workout", style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold))),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(20)
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}