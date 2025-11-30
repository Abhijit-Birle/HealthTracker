import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';
import '../widgets/bouncing_button.dart';

class TrendsTab extends StatelessWidget {
  const TrendsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // (A) Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Trends & Insights", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(height: 4),
                  Text("Your last 7 days at a glance", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24)
                ),
                child: const Row(
                  children: [
                    Text("Week", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16)
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 25),

          // (B) Key Metrics Row
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildKPICard("Calories In", "2,100", "avg/day", const Color(0xFFFF9100)),
                const SizedBox(width: 10),
                _buildKPICard("Calories Out", "540", "avg/day", const Color(0xFF00B0FF)),
                const SizedBox(width: 10),
                _buildKPICard("Sleep Avg", "6.8", "hrs", const Color(0xFFE040FB)),
                const SizedBox(width: 10),
                _buildKPICard("Hydration", "78%", "target", const Color(0xFF00E676)),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // (C) Hero Chart Section
          GlassCard(
            color: Colors.black.withOpacity(0.4),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Calorie Balance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text("Intake vs Burn", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white10, shape: BoxShape.circle),
                        child: const Icon(Icons.bar_chart, color: Colors.white70, size: 20),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _TrendsLineChartPainter(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.circle, size: 10, color: Color(0xFFFF9100)),
                      SizedBox(width: 5),
                      Text("In", style: TextStyle(color: Colors.grey, fontSize: 10)),
                      SizedBox(width: 15),
                      Icon(Icons.circle, size: 10, color: Color(0xFF00B0FF)),
                      SizedBox(width: 5),
                      Text("Out", style: TextStyle(color: Colors.grey, fontSize: 10)),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),

          // (E) AI Insights
          GlassCard(
            color: const Color(0xFF6C63FF).withOpacity(0.15),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white),
                      SizedBox(width: 10),
                      Text("AI Insight", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildInsightItem("You consumed 22% more calories on weekends."),
                  const SizedBox(height: 10),
                  _buildInsightItem("Low sleep (<6 hrs) correlates with higher sugar intake."),
                  const SizedBox(height: 15),
                  BouncingButton(
                      onTap: () {},
                      child: const Text("Ask AI Coach for more details >", style: TextStyle(color: Color(0xFF00B0FF), fontWeight: FontWeight.bold, fontSize: 12))
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),

          // (F) Predictions Slider
          const Text("Predictions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 15),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPredictionCard("Weight", "Trending Down", Icons.trending_down, const Color(0xFF00E676)),
                const SizedBox(width: 15),
                _buildPredictionCard("Consistency", "High Prob.", Icons.trending_up, const Color(0xFF00B0FF)),
                const SizedBox(width: 15),
                _buildPredictionCard("Sleep", "Improving", Icons.bedtime, const Color(0xFFE040FB)),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // (G) Achievements / Trophies
          const Text("Monthly Highlights", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBadge("Hydration Hero", Icons.water_drop, Colors.blue),
              _buildBadge("Early Bird", Icons.wb_sunny, Colors.orange),
              _buildBadge("Protein Pro", Icons.fitness_center, Colors.purple),
              _buildBadge("On Fire", Icons.local_fire_department, Colors.redAccent),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildKPICard(String label, String value, String unit, Color color) {
    return GlassCard(
      color: Colors.white.withOpacity(0.05),
      child: Container(
        width: 110,
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            const SizedBox(height: 5),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 22)),
            Text(unit, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Icon(Icons.circle, size: 6, color: Colors.white54),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4))),
      ],
    );
  }

  Widget _buildPredictionCard(String title, String status, IconData icon, Color color) {
    return GlassCard(
      color: Colors.white.withOpacity(0.05),
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(status, style: TextStyle(color: color.withOpacity(0.8), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String title, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.2),
              border: Border.all(color: color.withOpacity(0.5))
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}

class _TrendsLineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint linePaint1 = Paint()..color = const Color(0xFFFF9100)..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round;
    Paint linePaint2 = Paint()..color = const Color(0xFF00B0FF)..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round;

    Path path1 = Path();
    Path path2 = Path();

    List<double> points1 = [0.6, 0.8, 0.5, 0.9, 0.7, 0.6, 0.85];
    List<double> points2 = [0.3, 0.4, 0.35, 0.5, 0.4, 0.3, 0.45];

    double stepX = size.width / (points1.length - 1);

    for (int i = 0; i < points1.length; i++) {
      double x = i * stepX;
      double y1 = size.height - (points1[i] * size.height);
      double y2 = size.height - (points2[i] * size.height);

      if (i == 0) {
        path1.moveTo(x, y1);
        path2.moveTo(x, y2);
      } else {
        double prevX = (i - 1) * stepX;
        double prevY1 = size.height - (points1[i-1] * size.height);
        double prevY2 = size.height - (points2[i-1] * size.height);
        double cpX = (prevX + x) / 2;
        path1.cubicTo(cpX, prevY1, cpX, y1, x, y1);
        path2.cubicTo(cpX, prevY2, cpX, y2, x, y2);
      }
    }
    canvas.drawPath(path1, linePaint1);
    canvas.drawPath(path2, linePaint2);

    Path fillPath = Path.from(path1)..lineTo(size.width, size.height)..lineTo(0, size.height)..close();
    canvas.drawPath(fillPath, Paint()..shader = LinearGradient(colors: [const Color(0xFFFF9100).withOpacity(0.2), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
  }
  @override bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AICoachTab extends StatelessWidget { const AICoachTab({super.key}); @override Widget build(BuildContext context) => const Center(child: Text("AI Coach Tab Placeholder", style: TextStyle(color: Colors.white))); }