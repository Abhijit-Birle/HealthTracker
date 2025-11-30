import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:lottie/lottie.dart';
import '../models/energy_system.dart';
import '../widgets/glass_card.dart';
import '../widgets/bouncing_button.dart';
import '../widgets/futuristic_slider.dart';
import '../widgets/snackbar_utils.dart';

class DashboardTab extends StatefulWidget {
  final double mood;
  final double stress;
  final int energy;
  final ValueChanged<double> onMoodChanged;
  final ValueChanged<double> onStressChanged;
  final VoidCallback onInteractionStart;
  final VoidCallback onInteractionEnd;
  final Function(int) onCharge;

  const DashboardTab({
    super.key,
    required this.mood,
    required this.stress,
    required this.energy,
    required this.onMoodChanged,
    required this.onStressChanged,
    required this.onInteractionStart,
    required this.onInteractionEnd,
    required this.onCharge,
  });

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  double currentWeight = 72.5;
  double targetWeight = 70.0;
  Health health = Health();
  int steps = 0;
  int takenKcal = 0;
  int burnedKcal = 0;
  int targetKcal = 2400;

  int dailyProtein = 85;
  int dailyCarbs = 150;
  int dailyFat = 45;
  int targetProtein = 140;
  int targetCarbs = 250;
  int targetFat = 70;

  String sleepTime = "0h 0m";
  double sleepProgress = 0.0;

  final TextEditingController _notesController = TextEditingController();

  Widget _getMoodAnimation(double value) {
    String url;
    if (value > 0.8) url = 'https://assets10.lottiefiles.com/packages/lf20_5tl1xxnz.json';
    else if (value > 0.5) url = 'https://assets9.lottiefiles.com/packages/lf20_isbiybfh.json';
    else if (value > 0.3) url = 'https://assets2.lottiefiles.com/packages/lf20_0w4m5z.json';
    else url = 'https://assets9.lottiefiles.com/packages/lf20_sO48sB.json';
    return SizedBox(height: 80, width: 80, child: Lottie.network(url, errorBuilder: (c,e,s) => const Icon(Icons.face, size: 50, color: Colors.white)));
  }

  Widget _getStressAnimation(double value) {
    String url;
    if (value < 0.3) url = 'https://assets1.lottiefiles.com/packages/lf20_jJ2B9V.json';
    else if (value < 0.7) url = 'https://assets9.lottiefiles.com/packages/lf20_Y66a4O.json';
    else url = 'https://assets3.lottiefiles.com/packages/lf20_49rdyysj.json';
    return SizedBox(height: 80, width: 80, child: Lottie.network(url, errorBuilder: (c,e,s) => const Icon(Icons.bolt, size: 50, color: Colors.white)));
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _syncHealthData() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      steps = 6542;
      burnedKcal = 540;
      takenKcal = 1800;
      sleepTime = "7h 12m";
      sleepProgress = 0.8;
      dailyProtein = 95;
      dailyCarbs = 180;
    });
    widget.onCharge(50);

    if (!mounted) return;
    showFuturisticSnackBar(
        context,
        "Health Data Synced!",
        const Color(0xFF00E676),
        emoji: "🚀",
        subtitle: "$steps steps • $sleepTime sleep • $burnedKcal kcal"
    );
  }

  void _showEditDialog({required String title, required String suffix, required String currentValue, required Function(String) onSave}) {
    TextEditingController controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2129),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            suffixText: suffix,
            suffixStyle: const TextStyle(color: Color(0xFF00F0FF)),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
            focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00F0FF))),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          TextButton(onPressed: () { onSave(controller.text); Navigator.pop(context); }, child: const Text("Save", style: TextStyle(color: Color(0xFF00F0FF)))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var stateData = EnergySystem.getState(widget.energy);
    double energyProgress = EnergySystem.getProgress(widget.energy);
    Color stateColor = stateData['color'];
    Color weightColor = currentWeight > targetWeight ? const Color(0xFFFF5252) : const Color(0xFF00E676);

    Color moodColor = Color.lerp(const Color(0xFF757575), const Color(0xFF00F0FF), widget.mood)!;
    Color stressColor = Color.lerp(const Color(0xFF00E676), const Color(0xFFFF5252), widget.stress)!;
    Color moodBgColor = Color.lerp(Colors.black.withOpacity(0.3), const Color(0xFF00F0FF).withOpacity(0.2), widget.mood)!;
    Color stressBgColor = Color.lerp(Colors.black.withOpacity(0.3), const Color(0xFFFF5252).withOpacity(0.2), widget.stress)!;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 50, 20, 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Good Morning,", style: TextStyle(color: Colors.white, fontSize: 16)),
                  Text("Alex Carter", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ],
              ),
              Container(
                width: 45, height: 45,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white24, width: 1), image: const DecorationImage(image: NetworkImage("https://i.pravatar.cc/150?img=11"), fit: BoxFit.cover)),
              )
            ],
          ),
          const SizedBox(height: 20),

          // 1. ENERGY CARD
          GlassCard(
            color: stateColor.withOpacity(0.15),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Core Status", style: TextStyle(color: Colors.white70, fontSize: 12)), Text(stateData['name'], style: TextStyle(color: stateColor, fontSize: 24, fontWeight: FontWeight.bold, shadows: [BoxShadow(color: stateColor.withOpacity(0.7), blurRadius: 12, spreadRadius: 2)]))]), Text("${widget.energy} EU", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, shadows: [BoxShadow(color: stateColor.withOpacity(0.5), blurRadius: 10)]))]),
                  const SizedBox(height: 15),
                  ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: energyProgress, backgroundColor: Colors.black45, valueColor: AlwaysStoppedAnimation<Color>(stateColor), minHeight: 10)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 2. CALORIES CARD
          GlassCard(
            color: Colors.black.withOpacity(0.4),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [GestureDetector(onTap: () => _showEditDialog(title: "Consumed", suffix: "kcal", currentValue: takenKcal.toString(), onSave: (v) => setState(() => takenKcal = int.tryParse(v) ?? takenKcal)), child: _buildStatColumn("Taken", "$takenKcal", "kcal", const Color(0xFF00F0FF))), Container(height: 30, width: 1, color: Colors.white24), _buildStatColumn("Burned", "$burnedKcal", "kcal", const Color(0xFFE94560)), Container(height: 30, width: 1, color: Colors.white24), GestureDetector(onTap: () => _showEditDialog(title: "Target", suffix: "kcal", currentValue: targetKcal.toString(), onSave: (v) => setState(() => targetKcal = int.tryParse(v) ?? targetKcal)), child: _buildStatColumn("Target", "$targetKcal", "kcal", Colors.white))]),
                  const SizedBox(height: 20),
                  Stack(children: [Container(height: 8, decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(10))), FractionallySizedBox(widthFactor: targetKcal > 0 ? (takenKcal / targetKcal).clamp(0.0, 1.0) : 0.0, child: Container(height: 8, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF00F0FF), Color(0xFF6C63FF)]), borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: const Color(0xFF00F0FF).withOpacity(0.4), blurRadius: 10, spreadRadius: 2)])))]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),

          // 3. NEW NUTRITION (MACROS) CARD
          GlassCard(
            color: Colors.black.withOpacity(0.4),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Today's Nutrition", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  _buildMacroRow("Protein", dailyProtein, targetProtein, const Color(0xFFE040FB)),
                  const SizedBox(height: 10),
                  _buildMacroRow("Carbs", dailyCarbs, targetCarbs, const Color(0xFF00E676)),
                  const SizedBox(height: 10),
                  _buildMacroRow("Fat", dailyFat, targetFat, const Color(0xFF00B0FF)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),

          // 4. SYNC BUTTON
          BouncingButton(
            onTap: () { HapticFeedback.lightImpact(); _syncHealthData(); },
            child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)]), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.2))), child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.sync, color: Colors.white, size: 18), SizedBox(width: 8), Text("Sync Apple Health", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14))])),
          ),
          const SizedBox(height: 20),

          // 5. SLEEP & STEPS
          Row(children: [Expanded(flex: 3, child: GlassCard(color: Colors.black.withOpacity(0.4), child: Padding(padding: const EdgeInsets.all(15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Row(children: [Icon(Icons.bedtime, color: Colors.purpleAccent, size: 18), SizedBox(width: 5), Text("Sleep", style: TextStyle(color: Colors.white70, fontSize: 12))]), const SizedBox(height: 10), Text(sleepTime, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, shadows: [BoxShadow(color: Colors.purpleAccent.withOpacity(0.5), blurRadius: 10)])), const SizedBox(height: 5), Stack(children: [Container(height: 4, width: double.infinity, color: Colors.black45), AnimatedFractionallySizedBox(duration: const Duration(milliseconds: 1000), widthFactor: sleepProgress, child: Container(height: 4, decoration: BoxDecoration(color: Colors.purpleAccent, borderRadius: BorderRadius.circular(2), boxShadow: [BoxShadow(color: Colors.purpleAccent.withOpacity(0.5), blurRadius: 5)])))])])))), const SizedBox(width: 10), Expanded(flex: 2, child: GlassCard(color: Colors.black.withOpacity(0.4), child: Padding(padding: const EdgeInsets.all(15), child: Column(children: [const Icon(Icons.directions_walk, color: Colors.orangeAccent, size: 20), const SizedBox(height: 5), Text("$steps", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, shadows: [BoxShadow(color: Colors.orangeAccent.withOpacity(0.5), blurRadius: 10)])), const Text("Steps", style: TextStyle(fontSize: 10, color: Colors.white70))]))))]),
          const SizedBox(height: 20),

          // 6. MENTAL BALANCE
          const Text("Mental Balance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: GlassCard(color: moodBgColor, child: Padding(padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15), child: Column(children: [const Text("Mood", style: TextStyle(fontSize: 14, color: Colors.white70)), const SizedBox(height: 15), _getMoodAnimation(widget.mood), const SizedBox(height: 10), FuturisticSlider(value: widget.mood, color: const Color(0xFF00F0FF), onChanged: widget.onMoodChanged, onStart: widget.onInteractionStart, onEnd: widget.onInteractionEnd), const SizedBox(height: 10), Text(widget.mood > 0.8 ? "Ecstatic" : widget.mood > 0.5 ? "Good" : "Low", style: TextStyle(fontWeight: FontWeight.bold, color: const Color(0xFF00F0FF), shadows: [BoxShadow(color: const Color(0xFF00F0FF).withOpacity(0.5), blurRadius: 8)]))])))),
            const SizedBox(width: 15),
            Expanded(child: GlassCard(color: stressBgColor, child: Padding(padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 15), child: Column(children: [const Text("Stress", style: TextStyle(fontSize: 14, color: Colors.white70)), const SizedBox(height: 15), _getStressAnimation(widget.stress), const SizedBox(height: 10), FuturisticSlider(value: widget.stress, color: const Color(0xFFFF5252), onChanged: widget.onStressChanged, onStart: widget.onInteractionStart, onEnd: widget.onInteractionEnd), const SizedBox(height: 10), Text(widget.stress < 0.3 ? "Calm" : widget.stress < 0.7 ? "Moderate" : "High", style: TextStyle(fontWeight: FontWeight.bold, color: const Color(0xFFFF5252), shadows: [BoxShadow(color: const Color(0xFFFF5252).withOpacity(0.5), blurRadius: 8)]))]))))
          ]),
          const SizedBox(height: 20),

          // 7. WEIGHT & HEALTH SCORE
          Row(children: [Expanded(child: GestureDetector(onTap: () => _showEditDialog(title: "Update Weight", suffix: "kg", currentValue: currentWeight.toString(), onSave: (v) => setState(() => currentWeight = double.tryParse(v) ?? currentWeight)), child: GlassCard(color: Colors.black.withOpacity(0.4), child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(Icons.monitor_weight_outlined, color: Colors.white70), Icon(Icons.edit, size: 14, color: Colors.white30)]), const SizedBox(height: 10), const Text("Weight", style: TextStyle(color: Colors.grey)), const SizedBox(height: 5), RichText(text: TextSpan(children: [TextSpan(text: "$currentWeight", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: weightColor)), TextSpan(text: " / $targetWeight kg", style: const TextStyle(fontSize: 14, color: Colors.grey))]))]))))), const SizedBox(width: 15), Expanded(child: GlassCard(color: Colors.black.withOpacity(0.4), child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.star_outline_rounded, color: Color(0xFFFFD700)), const SizedBox(height: 10), const Text("Health Score", style: TextStyle(color: Colors.grey)), const SizedBox(height: 5), const Text("8.5/10", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, shadows: [BoxShadow(color: Color(0xFFFFD700), blurRadius: 10)]))]))))]),

          const SizedBox(height: 20),
          // 8. DAILY NOTES
          const Text("Daily Notes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          GlassCard(color: Colors.black.withOpacity(0.4), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: TextField(controller: _notesController, style: const TextStyle(color: Colors.white), maxLines: 3, decoration: InputDecoration(border: InputBorder.none, hintText: "How are you feeling today?", hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)), icon: const Icon(Icons.edit_note, color: Colors.white70))))),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String val, String unit, Color color) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: color, shadows: [BoxShadow(color: color.withOpacity(0.7), blurRadius: 10, spreadRadius: 2)])),
        Text("$label ($unit)", style: const TextStyle(fontSize: 13, color: Colors.white70)),
      ],
    );
  }

  Widget _buildMacroRow(String label, int val, int target, Color color) {
    double progress = (val / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text("$val / $target g", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        )
      ],
    );
  }
}