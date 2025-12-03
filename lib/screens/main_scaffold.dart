// lib/screens/main_scaffold.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart'; // keep if used in project

// Models
import '../models/energy_system.dart';
import '../models/exercise_plan.dart';
import '../models/workout_record.dart';

// Painters
import '../painters/liquid_nav_painter.dart';

// Screens (Tabs)
import 'dashboard_tab.dart';
import 'meals_tab.dart';
import 'mental_health_tab.dart';
import 'exercises_tab.dart';
import 'trends_tab.dart';

// services
import '../services/health_service.dart';

class MainScaffold extends StatefulWidget {
  final int? initialUserId;
  final String backendBase;

  const MainScaffold({Key? key, this.initialUserId, required this.backendBase}) : super(key: key);

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;

  // App state
  bool _isSliderActive = false;
  double _moodValue = 0.7;
  double _stressValue = 0.4;
  int _currentEnergy = 150;

  // User id
  int? _currentUserId;

  // Exercise State shared between tabs
  ExercisePlan? _activePlan;
  List<WorkoutRecord> _workoutHistory = [
    WorkoutRecord("Full Body HIIT", "24 min", "320 kcal", DateTime.now().subtract(const Duration(days: 1))),
    WorkoutRecord("Yoga Flow", "45 min", "150 kcal", DateTime.now().subtract(const Duration(days: 3))),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _activePlan = ExercisePlan("Full Body Burn – Day 3", "30 min", "Full Body", [
      ExerciseItem("Jumping Jacks", "30", "2", "45s", "https://assets4.lottiefiles.com/packages/lf20_j1adja0n.json"),
      ExerciseItem("Push Ups", "15", "3", "", "https://assets2.lottiefiles.com/packages/lf20_3ntisyac.json"),
      ExerciseItem("Squats", "20", "3", "", "https://assets9.lottiefiles.com/packages/lf20_vT1rK7.json"),
    ]);

    _initUserId();
  }

  Future<void> _initUserId() async {
    if (widget.initialUserId != null && widget.initialUserId! > 0) {
      setState(() {
        _currentUserId = widget.initialUserId;
      });
      return;
    }
    final hs = HealthService();
    final stored = await hs.getStoredUserId();
    setState(() {
      _currentUserId = stored;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Actions
  void _addEnergy(int amount) {
    setState(() {
      _currentEnergy += amount;
    });
    HapticFeedback.heavyImpact();
  }

  void _setActivePlan(ExercisePlan plan) {
    setState(() => _activePlan = plan);
  }

  void _addWorkoutRecord(WorkoutRecord record) {
    setState(() => _workoutHistory.insert(0, record));
  }

  void _deleteWorkoutRecord(int index) {
    setState(() => _workoutHistory.removeAt(index));
  }

  void _onPageChanged(int index) => setState(() => _currentIndex = index);

  void _onNavItemTapped(int index) {
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 600), curve: Curves.easeOutExpo);
  }

  @override
  Widget build(BuildContext context) {
    // Get current theme color based on energy level
    var stateColor = EnergySystem.getState(_currentEnergy)['color'];

    // Backend URLs
    final backendBase = widget.backendBase; // provided via constructor (set in main.dart)
    final backendSyncUrl = '$backendBase/api/health/sync';
    final backendStatusUrl = '$backendBase/api/sync/status';

    final List<Widget> screens = [
      DashboardTab(
        userId: _currentUserId ?? 0,
        backendBase: backendBase,
        backendSyncUrl: backendSyncUrl,
        backendStatusUrl: backendStatusUrl,
        authToken: '',
        energy: _currentEnergy,
        mood: _moodValue,
        stress: _stressValue,
        onMoodChanged: (val) => setState(() => _moodValue = val),
        onStressChanged: (val) => setState(() => _stressValue = val),
        onInteractionStart: () => setState(() => _isSliderActive = true),
        onInteractionEnd: () => setState(() => _isSliderActive = false),
        onCharge: _addEnergy,
      ),
      MealsTab(onEarnXP: _addEnergy),
      const MentalHealthTab(),
      ExercisesTab(
        activePlan: _activePlan,
        history: _workoutHistory,
        onSetPlan: _setActivePlan,
        onAddRecord: _addWorkoutRecord,
        onDeleteRecord: _deleteWorkoutRecord,
        onEarnXP: _addEnergy,
      ),
      const TrendsTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                'https://images.unsplash.com/photo-1614850523459-c2f4c699c52e?q=80&w=2670&auto=format&fit=crop',
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.3),
                colorBlendMode: BlendMode.darken,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(color: const Color(0xFF1E2129));
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)]),
                  ),
                ),
              ),
            ),
            PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: _isSliderActive ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
              children: screens,
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 110,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    CustomPaint(
                      size: Size(MediaQuery.of(context).size.width, 110),
                      painter: LiquidNavBarPainter(selectedIndex: _currentIndex, itemsCount: 5, color: Colors.black.withOpacity(0.9)),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildNavItem(0, 'https://lottie.host/0796777c-07b6-4d14-82c2-52163c24773c/19249.json', Icons.grid_view_rounded, stateColor),
                        _buildNavItem(1, 'https://lottie.host/82504310-5213-4e48-912f-047209934432/12345.json', Icons.restaurant_menu_rounded, stateColor),
                        _buildNavItem(2, 'https://lottie.host/56173744-8571-4546-9287-288081558657/54321.json', Icons.psychology, stateColor),
                        _buildNavItem(3, 'https://lottie.host/20825579-9937-4133-9912-155555666777/67890.json', Icons.fitness_center_rounded, stateColor),
                        _buildNavItem(4, 'https://lottie.host/91011121-3141-5161-7181-920212223242/11111.json', Icons.analytics_rounded, stateColor),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String lottieUrl, IconData fallbackIcon, Color activeColor) {
    bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onNavItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 5,
        height: 110,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.elasticOut,
              margin: EdgeInsets.only(bottom: isSelected ? 45 : 20),
              padding: const EdgeInsets.all(12),
              height: 55,
              width: 55,
              decoration: isSelected ? BoxDecoration(color: activeColor, shape: BoxShape.circle, boxShadow: [BoxShadow(color: activeColor.withOpacity(0.6), blurRadius: 15, spreadRadius: 2)]) : null,
              child: Opacity(
                opacity: isSelected ? 1.0 : 0.6,
                child: Icon(fallbackIcon, color: isSelected ? Colors.black : Colors.white54, size: 26),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
