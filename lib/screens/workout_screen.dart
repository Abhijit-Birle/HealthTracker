// lib/screens/workout_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});
  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  bool _loading = false;
  Map<String, dynamic>? _result;

  Future<void> _getSuggestion() async {
    setState(() => _loading = true);
    try {
      final r = await ApiService.getWorkoutSuggestion('gain_muscle', 'beginner');
      setState(() => _result = r);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildResult() {
    if (_result == null) return const SizedBox.shrink();
    final program = (_result!['program'] as List<dynamic>? ?? []);
    final notes = _result!['notes'] ?? '';

    // Choose a TextStyle that works across Flutter versions:
    final headingStyle = Theme.of(context).textTheme.titleMedium ??
        const TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text('Program:', style: headingStyle),
        const SizedBox(height: 8),
        ...program.map((ex) => ListTile(
              title: Text('${ex['exercise']}'),
              subtitle: Text('Sets: ${ex['sets']} • Reps: ${ex['reps']}'),
            )),
        const SizedBox(height: 8),
        Text('Notes: $notes'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Workout')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const Text('Get a workout suggestion for your goal (mock/demo).'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loading ? null : _getSuggestion,
            child: _loading
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Suggest Workout'),
          ),
          _buildResult(),
        ]),
      ),
    );
  }
}
