import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'dart:async';
import '../models/exercise_plan.dart';
import '../models/workout_record.dart';
import '../widgets/glass_card.dart';
import '../widgets/bouncing_button.dart';
import '../widgets/snackbar_utils.dart';
import 'workout_execution_page.dart';

class ExercisesTab extends StatefulWidget {
  final ExercisePlan? activePlan;
  final List<WorkoutRecord> history;
  final Function(ExercisePlan) onSetPlan;
  final Function(WorkoutRecord) onAddRecord;
  final Function(int) onDeleteRecord;
  final Function(int) onEarnXP;

  const ExercisesTab({
    super.key,
    this.activePlan,
    required this.history,
    required this.onSetPlan,
    required this.onAddRecord,
    required this.onDeleteRecord,
    required this.onEarnXP,
  });

  @override
  State<ExercisesTab> createState() => _ExercisesTabState();
}

class _ExercisesTabState extends State<ExercisesTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  void _showGeneratePlanDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _GeneratePlanPopup(onGenerate: (plan) {
        widget.onSetPlan(plan);
        Navigator.pop(context);
        showFuturisticSnackBar(context, "Plan Generated!", const Color(0xFF00E676), emoji: "⚡");
      }),
    );
  }

  void _startWorkout() {
    Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (context) => WorkoutExecutionPage(
            plan: widget.activePlan!,
            onFinish: (record, xp) {
              widget.onAddRecord(record);
              widget.onEarnXP(xp);
            }
        ))
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TOP SUMMARY
          Row(
            children: [
              Expanded(child: _buildSummaryCard("Mins Today", "24", Icons.timer, Colors.blueAccent)),
              const SizedBox(width: 10),
              Expanded(child: _buildSummaryCard("Streak", "4 Days", Icons.local_fire_department, Colors.orangeAccent)),
            ],
          ),
          const SizedBox(height: 30),

          // 2. ACTIVE PLAN OR GENERATE BUTTON
          if (widget.activePlan != null && widget.activePlan!.isActive)
            GlassCard(
              color: const Color(0xFF6C63FF).withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Current Plan", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(5)), child: const Text("Active", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)))
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(widget.activePlan!.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 5),
                    Text("${widget.activePlan!.duration} • ${widget.activePlan!.focus}", style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 20),
                    // Exercise Preview List
                    ...widget.activePlan!.exercises.take(3).map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Icon(e.isCompleted ? Icons.check_circle : Icons.circle_outlined, color: e.isCompleted ? const Color(0xFF00E676) : Colors.grey, size: 16),
                        const SizedBox(width: 10),
                        Text(e.name, style: TextStyle(color: e.isCompleted ? Colors.white54 : Colors.white, decoration: e.isCompleted ? TextDecoration.lineThrough : null))
                      ]),
                    )).toList(),
                    if (widget.activePlan!.exercises.length > 3) const Text("...and more", style: TextStyle(color: Colors.grey, fontSize: 10)),
                    const SizedBox(height: 20),
                    BouncingButton(
                      onTap: _startWorkout,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(color: const Color(0xFF6C63FF), borderRadius: BorderRadius.circular(15)),
                        child: const Center(child: Text("Start Workout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      ),
                    )
                  ],
                ),
              ),
            )
          else
            BouncingButton(
              onTap: _showGeneratePlanDialog,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF00F0FF), Color(0xFF6C63FF)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: const Color(0xFF6C63FF).withOpacity(0.3), blurRadius: 20)]
                ),
                child: const Column(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 40),
                    SizedBox(height: 10),
                    Text("Generate AI Workout Plan", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text("Personalized to your goals", style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 30),

          // 8. AI COACH SUGGESTION
          GlassCard(
            color: Colors.white.withOpacity(0.05),
            child: ListTile(
              leading: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.purpleAccent, shape: BoxShape.circle), child: const Icon(Icons.lightbulb, color: Colors.white, size: 20)),
              title: const Text("Coach Tip", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text("You trained legs yesterday. Try Upper Body today?", style: TextStyle(color: Colors.white54, fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
              onTap: _showGeneratePlanDialog,
            ),
          ),

          const SizedBox(height: 30),

          // 5. HISTORY
          const Text("Workout History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 15),

          if (widget.history.isEmpty)
            const Center(child: Text("No workouts yet. Let's go!", style: TextStyle(color: Colors.grey)))
          else
            ...widget.history.asMap().entries.map((entry) {
              int idx = entry.key;
              var record = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Dismissible(
                  key: Key("${record.title}_$idx"),
                  background: Container(color: Colors.redAccent, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                  onDismissed: (direction) {
                    widget.onDeleteRecord(idx);
                    showFuturisticSnackBar(context, "Workout Deleted", Colors.redAccent, emoji: "🗑️");
                  },
                  child: GlassCard(
                    child: ListTile(
                      leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.fitness_center, color: Color(0xFF00E676))),
                      title: Text(record.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      subtitle: Text("${record.duration} • ${record.cals}", style: const TextStyle(color: Colors.white54)),
                      trailing: const Icon(Icons.check_circle, color: Color(0xFF00E676), size: 16),
                    ),
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String val, IconData icon, Color color) {
    return GlassCard(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(val, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

// POPUP: GENERATE WORKOUT
class _GeneratePlanPopup extends StatefulWidget {
  final Function(ExercisePlan) onGenerate;
  const _GeneratePlanPopup({required this.onGenerate});
  @override State<_GeneratePlanPopup> createState() => _GeneratePlanPopupState();
}
class _GeneratePlanPopupState extends State<_GeneratePlanPopup> {
  bool _generating = false;
  String _selectedGoal = "Build Muscle";
  String _selectedDuration = "30 min";

  void _generate() {
    setState(() => _generating = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        // Create a mock plan based on selection
        widget.onGenerate(ExercisePlan(
            "$_selectedGoal Focus",
            _selectedDuration,
            "Full Body",
            [
              ExerciseItem("Push Ups", "15", "3", "", "https://assets2.lottiefiles.com/packages/lf20_3ntisyac.json"),
              ExerciseItem("Squats", "20", "3", "", "https://assets9.lottiefiles.com/packages/lf20_vT1rK7.json"),
              ExerciseItem("Plank", "1", "3", "60s", "https://assets8.lottiefiles.com/packages/lf20_znsm7udl.json"),
            ]
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(color: Color(0xFF1E2129), borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: Text("Configure Plan", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
          const SizedBox(height: 20),
          if (_generating)
            const Center(child: Column(children: [CircularProgressIndicator(color: Color(0xFF6C63FF)), SizedBox(height: 20), Text("AI is crafting your routine...", style: TextStyle(color: Colors.white70))]))
          else ...[
            const Text("Goal", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            Wrap(spacing: 10, children: ["Build Muscle", "Lose Fat", "Cardio"].map((g) => ChoiceChip(
              label: Text(g),
              selected: _selectedGoal == g,
              onSelected: (b) => setState(() => _selectedGoal = g),
              selectedColor: const Color(0xFF6C63FF),
              backgroundColor: Colors.white10,
              labelStyle: const TextStyle(color: Colors.white),
            )).toList()),
            const SizedBox(height: 20),
            const Text("Duration", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            Wrap(spacing: 10, children: ["15 min", "30 min", "45 min"].map((d) => ChoiceChip(
              label: Text(d),
              selected: _selectedDuration == d,
              onSelected: (b) => setState(() => _selectedDuration = d),
              selectedColor: const Color(0xFF00F0FF),
              backgroundColor: Colors.white10,
              labelStyle: const TextStyle(color: Colors.white),
            )).toList()),
            const SizedBox(height: 30),
            BouncingButton(
              onTap: _generate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: const Color(0xFF6C63FF), borderRadius: BorderRadius.circular(15)),
                child: const Center(child: Text("Generate", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              ),
            ),
            const SizedBox(height: 20),
          ]
        ],
      ),
    );
  }
}