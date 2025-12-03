import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:ui';
import 'dart:io';
import 'dart:math' as math;
import 'dart:async';

// REQUIRED: Add `health: ^10.0.0`, `lottie: ^3.1.0`, `image_picker: ^1.0.7`, `rive: ^0.13.0` to pubspec.yaml
import 'package:health/health.dart';
import 'package:health_tracker_poc/providers/auth_provider.dart';
import 'package:health_tracker_poc/services/api_service.dart';
import 'package:lottie/lottie.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:uuid/uuid.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/health_provider.dart';
import 'screens/login_screen.dart';

// ALIASED IMPORT to prevent conflicts with Flutter's Image, LinearGradient, etc.
import 'package:rive/rive.dart' as rive;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // load environment file
  await dotenv.load(fileName: ".env");

  // keep your status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  final api = ApiService();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HealthProvider(api)),
      ],
      child: const ZenoApp(),
    ),
  );
}

class ZenoApp extends StatelessWidget {
  const ZenoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Zeno',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        primaryColor: const Color(0xFF6C63FF),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6C63FF),
          secondary: Color(0xFF00F0FF),
          surface: Color(0xFF1E2129),
          onSurface: Colors.white,
        ),
        fontFamily: 'Roboto',
      ),
      initialRoute: LoginScreen.routeName,
      routes: {
        LoginScreen.routeName: (_) => LoginScreen(),
        '/home': (_) => const MainScaffold(), // your existing scaffold as home
      },
    );
  }
}

// --- DATA MODELS ---

class EnergySystem {
  static const int stateIdle = 0;
  static const int stateActive = 100;
  static const int stateCharged = 300;
  static const int stateOverdrive = 600;
  static const int stateQuantum = 1000;

  static Map<String, dynamic> getState(int energy) {
    if (energy >= stateQuantum) {
      return {"name": "Quantum State", "color": const Color(0xFFE040FB)};
    } else if (energy >= stateOverdrive) {
      return {"name": "Overdrive", "color": const Color(0xFFFF9100)};
    } else if (energy >= stateCharged) {
      return {"name": "Fully Charged", "color": const Color(0xFF00E676)};
    } else if (energy >= stateActive) {
      return {"name": "System Active", "color": const Color(0xFF00B0FF)};
    } else {
      return {"name": "Idle Mode", "color": Colors.white70};
    }
  }

  static double getProgress(int energy) {
    if (energy >= stateQuantum) return 1.0;
    int prevLimit = 0;
    int nextLimit = 100;

    if (energy >= stateOverdrive) {
      prevLimit = stateOverdrive;
      nextLimit = stateQuantum;
    } else if (energy >= stateCharged) {
      prevLimit = stateCharged;
      nextLimit = stateOverdrive;
    } else if (energy >= stateActive) {
      prevLimit = stateActive;
      nextLimit = stateCharged;
    }

    return (energy - prevLimit) / (nextLimit - prevLimit);
  }
}

class MealEntry {
  final String name;
  final String cals;
  final String time;
  final String nutrition;
  final String fiber;
  final String vitamins;
  final IconData icon;
  final File? image;
  final String? imageUrl;
  final String type;
  final DateTime dateTime;
  final double protein;
  final double carbs;
  final double fat;

  MealEntry(this.name, this.cals, this.time, this.nutrition, this.fiber,
      this.vitamins, this.icon, this.image, this.type, this.dateTime,
      {this.imageUrl, this.protein = 20.0, this.carbs = 30.0, this.fat = 10.0});
}

class ExercisePlan {
  final String title;
  final String duration;
  final String focus;
  final List<ExerciseItem> exercises;
  bool isActive;

  ExercisePlan(this.title, this.duration, this.focus, this.exercises,
      {this.isActive = true});
}

class ExerciseItem {
  final String name;
  final String reps;
  final String sets;
  final String time;
  final String animationUrl;
  bool isCompleted;

  ExerciseItem(this.name, this.reps, this.sets, this.time, this.animationUrl,
      {this.isCompleted = false});
}

class WorkoutRecord {
  final String title;
  final String duration;
  final String cals;
  final DateTime date;

  WorkoutRecord(this.title, this.duration, this.cals, this.date);
}

// --- MAIN SCAFFOLD ---

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;

  // State lifted up
  bool _isSliderActive = false;
  double _moodValue = 0.7;
  double _stressValue = 0.4;
  int _currentEnergy = 150;

  // Exercise State
  ExercisePlan? _activePlan;
  List<WorkoutRecord> _workoutHistory = [
    WorkoutRecord("Full Body HIIT", "24 min", "320 kcal",
        DateTime.now().subtract(const Duration(days: 1))),
    WorkoutRecord("Yoga Flow", "45 min", "150 kcal",
        DateTime.now().subtract(const Duration(days: 3))),
  ];

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

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _activePlan =
        ExercisePlan("Full Body Burn – Day 3", "30 min", "Full Body", [
      ExerciseItem("Jumping Jacks", "30", "2", "45s",
          "https://assets4.lottiefiles.com/packages/lf20_j1adja0n.json"),
      ExerciseItem("Push Ups", "15", "3", "",
          "https://assets2.lottiefiles.com/packages/lf20_3ntisyac.json"),
      ExerciseItem("Squats", "20", "3", "",
          "https://assets9.lottiefiles.com/packages/lf20_vT1rK7.json"),
    ]);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onNavItemTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutExpo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardTab(
        mood: _moodValue,
        stress: _stressValue,
        energy: _currentEnergy,
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

    var stateColor = EnergySystem.getState(_currentEnergy)['color'];

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Stack(
          children: [
            // 1. VIBRANT BACKGROUND IMAGE
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
                        gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
                ))),
              ),
            ),

            // 2. Main Content
            PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: _isSliderActive
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              children: screens,
            ),

            // 3. "LIQUID" Floating Navigation Bar
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
                      painter: LiquidNavBarPainter(
                        selectedIndex: _currentIndex,
                        itemsCount: 5,
                        color: Colors.black.withOpacity(0.9),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildNavItem(
                            0,
                            'https://lottie.host/0796777c-07b6-4d14-82c2-52163c24773c/19249.json',
                            Icons.grid_view_rounded,
                            stateColor),
                        // Home
                        _buildNavItem(
                            1,
                            'https://lottie.host/82504310-5213-4e48-912f-047209934432/12345.json',
                            Icons.restaurant_menu_rounded,
                            stateColor),
                        // Food
                        _buildNavItem(
                            2,
                            'https://lottie.host/56173744-8571-4546-9287-288081558657/54321.json',
                            Icons.psychology,
                            stateColor),
                        // Mind
                        _buildNavItem(
                            3,
                            'https://lottie.host/20825579-9937-4133-9912-155555666777/67890.json',
                            Icons.fitness_center_rounded,
                            stateColor),
                        // Exercise
                        _buildNavItem(
                            4,
                            'https://lottie.host/91011121-3141-5161-7181-920212223242/11111.json',
                            Icons.analytics_rounded,
                            stateColor),
                        // Trends
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

  Widget _buildNavItem(
      int index, String lottieUrl, IconData fallbackIcon, Color activeColor) {
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
              decoration: isSelected
                  ? BoxDecoration(
                      color: activeColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                          BoxShadow(
                              color: activeColor.withOpacity(0.6),
                              blurRadius: 15,
                              spreadRadius: 2)
                        ])
                  : null,
              child: Opacity(
                opacity: isSelected ? 1.0 : 0.6,
                child: Icon(fallbackIcon,
                    color: isSelected ? Colors.black : Colors.white54,
                    size: 26),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LiquidNavBarPainter extends CustomPainter {
  final int selectedIndex;
  final int itemsCount;
  final Color color;

  LiquidNavBarPainter(
      {required this.selectedIndex,
      required this.itemsCount,
      required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    Path path = Path();

    double itemWidth = size.width / itemsCount;
    double centerX = (selectedIndex * itemWidth) + (itemWidth / 2);
    double barTop = 40.0;

    path.moveTo(0, size.height);
    path.lineTo(0, barTop);
    path.lineTo(centerX - 50, barTop);
    path.cubicTo(
        centerX - 30, barTop, centerX - 30, barTop + 40, centerX, barTop + 40);
    path.cubicTo(
        centerX + 30, barTop + 40, centerX + 30, barTop, centerX + 50, barTop);
    path.lineTo(size.width, barTop);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
    Paint borderPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant LiquidNavBarPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex;
  }
}

// ---------------------------------------------------------------------------
// 1. DASHBOARD TAB
// ---------------------------------------------------------------------------

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

class _DashboardTabState extends State<DashboardTab>
    with AutomaticKeepAliveClientMixin {
  List<dynamic> backendRecords = [];
  bool loadingBackend = true;
  final int userId = 42; // Replace with real logged-in user ID later

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

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact(); // Nice touch feedback

    // 1. Fetch latest data from Apple Health (Updates Steps, Calories, etc.)
    await _syncHealthData();

    // 2. Fetch latest history from your Backend
    await loadFromBackend();

    // 3. (Optional) You can add a slight delay if it's too fast,
    // just to let the user see the spinner for a moment.
    // await Future.delayed(const Duration(seconds: 1));
  }

  Future<void> loadFromBackend() async {
    try {
      loadingBackend = true;
      setState(() {});

      backendRecords = await ApiService.fetchRecords(userId);

      print("Loaded ${backendRecords.length} records from backend");
    } catch (e) {
      print("Error loading backend: $e");
    } finally {
      loadingBackend = false;
      setState(() {});
    }
  }

  Widget _getMoodAnimation(double value) {
    String url;
    if (value > 0.8)
      url = 'https://assets10.lottiefiles.com/packages/lf20_5tl1xxnz.json';
    else if (value > 0.5)
      url = 'https://assets9.lottiefiles.com/packages/lf20_isbiybfh.json';
    else if (value > 0.3)
      url = 'https://assets2.lottiefiles.com/packages/lf20_0w4m5z.json';
    else
      url = 'https://assets9.lottiefiles.com/packages/lf20_sO48sB.json';
    return SizedBox(
        height: 80,
        width: 80,
        child: Lottie.network(url,
            errorBuilder: (c, e, s) =>
                const Icon(Icons.face, size: 50, color: Colors.white)));
  }

  Widget _getStressAnimation(double value) {
    String url;
    if (value < 0.3)
      url = 'https://assets1.lottiefiles.com/packages/lf20_jJ2B9V.json';
    else if (value < 0.7)
      url = 'https://assets9.lottiefiles.com/packages/lf20_Y66a4O.json';
    else
      url = 'https://assets3.lottiefiles.com/packages/lf20_49rdyysj.json';
    return SizedBox(
        height: 80,
        width: 80,
        child: Lottie.network(url,
            errorBuilder: (c, e, s) =>
                const Icon(Icons.bolt, size: 50, color: Colors.white)));
  }

  @override
  void initState() {
    super.initState();
    loadFromBackend();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _syncHealthData() async {
    // 1. EXTENSIVE LIST OF TYPES
    // Note: Some types are platform-specific (iOS only vs Android only).
    // The health package handles this gracefully, but we must ask for permission carefully.
    List<HealthDataType> types = [
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.AUDIOGRAM,
      HealthDataType.BASAL_ENERGY_BURNED,
      HealthDataType.BLOOD_GLUCOSE,
      HealthDataType.BLOOD_OXYGEN,
      HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
      HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
      HealthDataType.BODY_FAT_PERCENTAGE,
      HealthDataType.BODY_MASS_INDEX,
      HealthDataType.BODY_TEMPERATURE,
      HealthDataType.DIETARY_CARBS_CONSUMED,
      HealthDataType.DIETARY_CAFFEINE,
      HealthDataType.DIETARY_ENERGY_CONSUMED,
      HealthDataType.DIETARY_FATS_CONSUMED,
      HealthDataType.DIETARY_PROTEIN_CONSUMED,
      HealthDataType.ELECTRODERMAL_ACTIVITY,
      HealthDataType.FORCED_EXPIRATORY_VOLUME,
      HealthDataType.HEART_RATE,
      HealthDataType.HEART_RATE_VARIABILITY_SDNN,
      HealthDataType.HEIGHT,
      HealthDataType.HIGH_HEART_RATE_EVENT,
      HealthDataType.IRREGULAR_HEART_RATE_EVENT,
      HealthDataType.LOW_HEART_RATE_EVENT,
      HealthDataType.RESTING_HEART_RATE,
      HealthDataType.RESPIRATORY_RATE,
      HealthDataType.PERIPHERAL_PERFUSION_INDEX,
      HealthDataType.STEPS,
      HealthDataType.WAIST_CIRCUMFERENCE,
      HealthDataType.WALKING_HEART_RATE,
      HealthDataType.WEIGHT,
      HealthDataType.FLIGHTS_CLIMBED,
      HealthDataType.DISTANCE_WALKING_RUNNING,
      HealthDataType.DISTANCE_SWIMMING,
      HealthDataType.DISTANCE_CYCLING,
      HealthDataType.MINDFULNESS,
      HealthDataType.SLEEP_IN_BED,
      HealthDataType.SLEEP_AWAKE,
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_DEEP,
      HealthDataType.SLEEP_REM,
      HealthDataType.SLEEP_ASLEEP_CORE,
      HealthDataType.SLEEP_ASLEEP_DEEP,
      HealthDataType.SLEEP_ASLEEP_REM,
      HealthDataType.WATER,
      HealthDataType.EXERCISE_TIME,
      HealthDataType.WORKOUT,
      HealthDataType.HEADACHE_NOT_PRESENT,
      HealthDataType.HEADACHE_MILD,
      HealthDataType.HEADACHE_MODERATE,
      HealthDataType.HEADACHE_SEVERE,
      HealthDataType.HEADACHE_UNSPECIFIED,
      HealthDataType.ELECTROCARDIOGRAM,
      HealthDataType.NUTRITION
    ];

    // Filter types based on platform to prevent crashes
    // (e.g. Audiogram is iOS only)
    List<HealthDataType> availableTypes = [];
    if (Platform.isIOS) {
      availableTypes = types;
    } else {
      // On Android, remove iOS-only types like AUDIOGRAM, ELECTROCARDIOGRAM if not supported
      availableTypes = types
          .where((t) =>
              t != HealthDataType.AUDIOGRAM &&
              t != HealthDataType.ELECTROCARDIOGRAM)
          .toList();
    }

    setState(() => loadingBackend = true);

    try {
      // 2. Request Permissions
      // We request READ access for all types.
      // Note: Some types (like Activity) might need WRITE access if you plan to save them back.
      bool requested = await health.requestAuthorization(availableTypes);

      if (!requested) {
        showFuturisticSnackBar(context, "Permission Issue", Colors.orangeAccent,
            subtitle: "Some permissions were denied or canceled.");
        // We continue anyway, as some permissions might have been granted previously.
      }

      // 3. Fetch Data (Last 24 Hours)
      // Fetch data for the last 30 days to ensure we catch Weight/Height
// (The API handles large datasets efficiently)
      DateTime now = DateTime.now();
      DateTime startTime = now.subtract(const Duration(days: 7));
      DateTime yesterday = now.subtract(const Duration(days: 1));

      List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
        startTime: startTime,
        endTime: now,
        types: availableTypes,
      );
      // 4. Remove Duplicates (Apple Health often sends duplicates)
      healthData = health.removeDuplicates(healthData);

      // 5. Process Data for UI Updates
      // We create local variables to aggregate the data
      int totalSteps = 0;
      double totalCalories = 0.0;
      int sleepMinutes = 0;
      double fetchedWeight = 0.0;

      // Nutrition totals
      double totalProtein = 0.0;
      double totalCarbs = 0.0;
      double totalFat = 0.0;

      DateTime? lastWeightDate;

      print("--- FETCHED ${healthData.length} RAW POINTS ---");

      for (var point in healthData) {
        // --- A. Handle Standard Numeric Data ---
        if (point.value is NumericHealthValue) {
          double val =
              (point.value as NumericHealthValue).numericValue.toDouble();

          // if (point.type == HealthDataType.STEPS) {
          //   totalSteps += val.toInt();
          // }
          // Fetch the "Smart" Step Count directly from Apple's native engine
          int? smartSteps =
              await health.getTotalStepsInInterval(yesterday, now);

// Use this for UI instead of your loop sum
          if (point.type == HealthDataType.STEPS && smartSteps != null) {
            totalSteps = smartSteps;
          } else if (point.type == HealthDataType.ACTIVE_ENERGY_BURNED ||
              point.type == HealthDataType.BASAL_ENERGY_BURNED) {
            double totalCalories = 0.0;
            bool hasWatch =
                healthData.any((e) => e.sourceName.contains("Watch"));

            for (var point in healthData) {
              // Filter: If we have Watch data, ignore iPhone data for calories
              if (hasWatch && point.sourceName.contains("iPhone")) continue;

              if (point.type == HealthDataType.ACTIVE_ENERGY_BURNED) {
                if (point.value is NumericHealthValue) {
                  totalCalories += (point.value as NumericHealthValue)
                      .numericValue
                      .toDouble();
                }
              }
            }
          } else if (point.type == HealthDataType.WEIGHT) {
            // Weight is a "snapshot", so we usually take the most recent one.
            // Since the list isn't guaranteed order, we just upd
            if (point.value is NumericHealthValue) {
              // ONLY update if this point is newer than what we have seen so far
              if (lastWeightDate == null ||
                  point.dateFrom.isAfter(lastWeightDate!)) {
                fetchedWeight =
                    (point.value as NumericHealthValue).numericValue.toDouble();
                lastWeightDate = point.dateFrom;
                print(
                    "✅ Found newer weight: $fetchedWeight kg from ${point.dateFrom}");
              }
            }
          } else if (point.type == HealthDataType.DIETARY_PROTEIN_CONSUMED)
            totalProtein += val;
          else if (point.type == HealthDataType.DIETARY_CARBS_CONSUMED)
            totalCarbs += val;
          else if (point.type == HealthDataType.DIETARY_FATS_CONSUMED)
            totalFat += val;
        }

        // --- B. Handle Sleep Data ---
        // Sleep types are often intervals. We sum up "ASLEEP" durations.
        else if (point.type == HealthDataType.SLEEP_ASLEEP ||
            point.type == HealthDataType.SLEEP_ASLEEP_CORE ||
            point.type == HealthDataType.SLEEP_ASLEEP_DEEP ||
            point.type == HealthDataType.SLEEP_ASLEEP_REM ||
            point.type == HealthDataType.SLEEP_REM ||
            point.type == HealthDataType.SLEEP_DEEP) {
          int minutes = point.dateTo.difference(point.dateFrom).inMinutes;
          sleepMinutes += minutes;
        }

        // --- C. Handle Audiograms / ECG / Workouts ---
        // These are complex. We don't sum them for the dashboard UI,
        // but they will be sent to the backend in the payload loop below.
      }

      // 6. Update Dashboard UI with Real Data
      setState(() {
        if (totalSteps > 0) steps = totalSteps;
        if (totalCalories > 0) burnedKcal = totalCalories.toInt();

        // Update Weight if found
        if (fetchedWeight > 0) currentWeight = fetchedWeight;

        // Update Sleep UI
        if (sleepMinutes > 0) {
          int hours = sleepMinutes ~/ 60;
          int mins = sleepMinutes % 60;
          sleepTime = "${hours}h ${mins}m";
          sleepProgress =
              (sleepMinutes / 480).clamp(0.0, 1.0); // Target 8h (480m)
        }

        // Update Nutrition UI
        if (totalProtein > 0) dailyProtein = totalProtein.toInt();
        if (totalCarbs > 0) dailyCarbs = totalCarbs.toInt();
        if (totalFat > 0) dailyFat = totalFat.toInt();
      });

      // 7. Prepare Backend Payload (Send EVERYTHING)
      // We convert complex health values into a JSON-friendly format
      List<Map<String, dynamic>> backendPoints = healthData.map((e) {
        dynamic val;
        Map<String, dynamic> metadata = {};

        if (e.value is NumericHealthValue) {
          val = (e.value as NumericHealthValue).numericValue.toDouble();
        } else if (e.value is AudiogramHealthValue) {
          val =
              "audiogram_data"; // Audiograms are too large for simple value fields
          metadata['frequencies'] =
              (e.value as AudiogramHealthValue).frequencies;
        } else if (e.value is WorkoutHealthValue) {
          var w = (e.value as WorkoutHealthValue);
          val = w.totalEnergyBurned ?? 0;
          metadata['workoutType'] = w.workoutActivityType.name;
          metadata['totalDistance'] = w.totalDistance;
          metadata['totalSteps'] = w.totalSteps;
        } else if (e.value is ElectrocardiogramHealthValue) {
          val = "ecg_data";
          metadata['voltageValues'] =
              (e.value as ElectrocardiogramHealthValue).voltageValues;
        } else {
          val = e.value.toString();
        }

        return {
          "type": e.typeString,
          "startTime": e.dateFrom.toUtc().toIso8601String(),
          "endTime": e.dateTo.toUtc().toIso8601String(),
          "measureValue": val,
          "metadata": metadata, // Add metadata field for complex objects
          "source": e.sourceName,
          "idempotencyKey": const Uuid().v4()
        };
      }).toList();

      // 8. Send to Backend
      if (backendPoints.isNotEmpty) {
        await ApiService.syncHealth(userId, backendPoints);
        showFuturisticSnackBar(
            context, "Synced Everything!", const Color(0xFF00E676),
            emoji: "🧬",
            subtitle: "${backendPoints.length} datapoints processed");
      } else {
        showFuturisticSnackBar(context, "No New Data", Colors.grey,
            subtitle: "Apple Health is empty for today");
      }
    } catch (e) {
      debugPrint("Sync Error: $e");
      showFuturisticSnackBar(context, "Sync Failed", Colors.redAccent,
          subtitle: "Check console for details");
    } finally {
      setState(() => loadingBackend = false);
    }
  }

  void _showEditDialog(
      {required String title,
      required String suffix,
      required String currentValue,
      required Function(String) onSave}) {
    TextEditingController controller =
        TextEditingController(text: currentValue);
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF1E2129),
                title: Text(title, style: const TextStyle(color: Colors.white)),
                content: TextField(
                    controller: controller,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                        suffixText: suffix,
                        suffixStyle: const TextStyle(color: Color(0xFF00F0FF)),
                        enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.1))),
                        focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF00F0FF))))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel",
                          style: TextStyle(color: Colors.grey))),
                  TextButton(
                      onPressed: () {
                        onSave(controller.text);
                        Navigator.pop(context);
                      },
                      child: const Text("Save",
                          style: TextStyle(color: Color(0xFF00F0FF))))
                ]));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var stateData = EnergySystem.getState(widget.energy);
    double energyProgress = EnergySystem.getProgress(widget.energy);
    Color stateColor = stateData['color'];
    Color weightColor = currentWeight > targetWeight
        ? const Color(0xFFFF5252)
        : const Color(0xFF00E676);
    Color moodColor = Color.lerp(
        const Color(0xFF757575), const Color(0xFF00F0FF), widget.mood)!;
    Color stressColor = Color.lerp(
        const Color(0xFF00E676), const Color(0xFFFF5252), widget.stress)!;
    Color moodBgColor = Color.lerp(Colors.black.withOpacity(0.3),
        const Color(0xFF00F0FF).withOpacity(0.2), widget.mood)!;
    Color stressBgColor = Color.lerp(Colors.black.withOpacity(0.3),
        const Color(0xFFFF5252).withOpacity(0.2), widget.stress)!;
    return RefreshIndicator(
        onRefresh: _handleRefresh, // <--- Call your new function here
        color: const Color(0xFF00F0FF), // Cyan spinner color
        backgroundColor: const Color(0xFF1E2129), // Dark background for spinner
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 130),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Good Morning,",
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                      Text("Alex Carter",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5))
                    ]),
                Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 1),
                        image: const DecorationImage(
                            image: NetworkImage(
                                "https://i.pravatar.cc/150?img=11"),
                            fit: BoxFit.cover)))
              ]),
              const SizedBox(height: 20),
              if (!loadingBackend)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    "Backend records: ${backendRecords.length}",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              GlassCard(
                  color: stateColor.withOpacity(0.15),
                  child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Core Status",
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12)),
                                    Text(stateData['name'],
                                        style: TextStyle(
                                            color: stateColor,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            shadows: [
                                              BoxShadow(
                                                  color: stateColor
                                                      .withOpacity(0.7),
                                                  blurRadius: 12,
                                                  spreadRadius: 2)
                                            ]))
                                  ]),
                              Text("${widget.energy} EU",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      shadows: [
                                        BoxShadow(
                                            color: stateColor.withOpacity(0.5),
                                            blurRadius: 10)
                                      ]))
                            ]),
                        const SizedBox(height: 15),
                        ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                                value: energyProgress,
                                backgroundColor: Colors.black45,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(stateColor),
                                minHeight: 10))
                      ]))),
              const SizedBox(height: 20),
              GlassCard(
                  color: Colors.black.withOpacity(0.4),
                  child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                  onTap: () => _showEditDialog(
                                      title: "Consumed",
                                      suffix: "kcal",
                                      currentValue: takenKcal.toString(),
                                      onSave: (v) => setState(() => takenKcal =
                                          int.tryParse(v) ?? takenKcal)),
                                  child: _buildStatColumn("Taken", "$takenKcal",
                                      "kcal", const Color(0xFF00F0FF))),
                              Container(
                                  height: 30, width: 1, color: Colors.white24),
                              _buildStatColumn("Burned", "$burnedKcal", "kcal",
                                  const Color(0xFFE94560)),
                              Container(
                                  height: 30, width: 1, color: Colors.white24),
                              GestureDetector(
                                  onTap: () => _showEditDialog(
                                      title: "Target",
                                      suffix: "kcal",
                                      currentValue: targetKcal.toString(),
                                      onSave: (v) => setState(() => targetKcal =
                                          int.tryParse(v) ?? targetKcal)),
                                  child: _buildStatColumn("Target",
                                      "$targetKcal", "kcal", Colors.white))
                            ]),
                        const SizedBox(height: 20),
                        Stack(children: [
                          Container(
                              height: 8,
                              decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(10))),
                          FractionallySizedBox(
                              widthFactor: targetKcal > 0
                                  ? (takenKcal / targetKcal).clamp(0.0, 1.0)
                                  : 0.0,
                              child: Container(
                                  height: 8,
                                  decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [
                                        Color(0xFF00F0FF),
                                        Color(0xFF6C63FF)
                                      ]),
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [
                                        BoxShadow(
                                            color: const Color(0xFF00F0FF)
                                                .withOpacity(0.4),
                                            blurRadius: 10,
                                            spreadRadius: 2)
                                      ])))
                        ])
                      ]))),
              const SizedBox(height: 15),
              GlassCard(
                  color: Colors.black.withOpacity(0.4),
                  child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Today's Nutrition",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 15),
                            _buildMacroRow("Protein", dailyProtein,
                                targetProtein, const Color(0xFFE040FB)),
                            const SizedBox(height: 10),
                            _buildMacroRow("Carbs", dailyCarbs, targetCarbs,
                                const Color(0xFF00E676)),
                            const SizedBox(height: 10),
                            _buildMacroRow("Fat", dailyFat, targetFat,
                                const Color(0xFF00B0FF))
                          ]))),
              const SizedBox(height: 15),
              BouncingButton(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _syncHealthData();
                  },
                  child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            Colors.white.withOpacity(0.15),
                            Colors.white.withOpacity(0.05)
                          ]),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.2))),
                      child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sync, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Text("Sync Apple Health",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14))
                          ]))),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                    flex: 3,
                    child: GlassCard(
                        color: Colors.black.withOpacity(0.4),
                        child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(children: [
                                    Icon(Icons.bedtime,
                                        color: Colors.purpleAccent, size: 18),
                                    SizedBox(width: 5),
                                    Text("Sleep",
                                        style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12))
                                  ]),
                                  const SizedBox(height: 10),
                                  Text(sleepTime,
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          shadows: [
                                            BoxShadow(
                                                color: Colors.purpleAccent
                                                    .withOpacity(0.5),
                                                blurRadius: 10)
                                          ])),
                                  const SizedBox(height: 5),
                                  Stack(children: [
                                    Container(
                                        height: 4,
                                        width: double.infinity,
                                        color: Colors.black45),
                                    AnimatedFractionallySizedBox(
                                        duration:
                                            const Duration(milliseconds: 1000),
                                        widthFactor: sleepProgress,
                                        child: Container(
                                            height: 4,
                                            decoration: BoxDecoration(
                                                color: Colors.purpleAccent,
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                                boxShadow: [
                                                  BoxShadow(
                                                      color: Colors.purpleAccent
                                                          .withOpacity(0.5),
                                                      blurRadius: 5)
                                                ])))
                                  ])
                                ])))),
                const SizedBox(width: 10),
                Expanded(
                    flex: 2,
                    child: GlassCard(
                        color: Colors.black.withOpacity(0.4),
                        child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(children: [
                              const Icon(Icons.directions_walk,
                                  color: Colors.orangeAccent, size: 20),
                              const SizedBox(height: 5),
                              Text("$steps",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        BoxShadow(
                                            color: Colors.orangeAccent
                                                .withOpacity(0.5),
                                            blurRadius: 10)
                                      ])),
                              const Text("Steps",
                                  style: TextStyle(
                                      fontSize: 10, color: Colors.white70))
                            ]))))
              ]),
              const SizedBox(height: 20),
              const Text("Mental Balance",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: GlassCard(
                        color: moodBgColor,
                        child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 20, horizontal: 15),
                            child: Column(children: [
                              const Text("Mood",
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.white70)),
                              const SizedBox(height: 15),
                              _getMoodAnimation(widget.mood),
                              const SizedBox(height: 10),
                              FuturisticSlider(
                                  value: widget.mood,
                                  color: const Color(0xFF00F0FF),
                                  onChanged: widget.onMoodChanged,
                                  onStart: widget.onInteractionStart,
                                  onEnd: widget.onInteractionEnd),
                              const SizedBox(height: 10),
                              Text(
                                  widget.mood > 0.8
                                      ? "Ecstatic"
                                      : widget.mood > 0.5
                                          ? "Good"
                                          : "Low",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF00F0FF),
                                      shadows: [
                                        BoxShadow(
                                            color: const Color(0xFF00F0FF)
                                                .withOpacity(0.5),
                                            blurRadius: 8)
                                      ]))
                            ])))),
                const SizedBox(width: 15),
                Expanded(
                    child: GlassCard(
                        color: stressBgColor,
                        child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 20, horizontal: 15),
                            child: Column(children: [
                              const Text("Stress",
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.white70)),
                              const SizedBox(height: 15),
                              _getStressAnimation(widget.stress),
                              const SizedBox(height: 10),
                              FuturisticSlider(
                                  value: widget.stress,
                                  color: const Color(0xFFFF5252),
                                  onChanged: widget.onStressChanged,
                                  onStart: widget.onInteractionStart,
                                  onEnd: widget.onInteractionEnd),
                              const SizedBox(height: 10),
                              Text(
                                  widget.stress < 0.3
                                      ? "Calm"
                                      : widget.stress < 0.7
                                          ? "Moderate"
                                          : "High",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFFF5252),
                                      shadows: [
                                        BoxShadow(
                                            color: const Color(0xFFFF5252)
                                                .withOpacity(0.5),
                                            blurRadius: 8)
                                      ]))
                            ]))))
              ]),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                    child: GestureDetector(
                        onTap: () => _showEditDialog(
                            title: "Update Weight",
                            suffix: "kg",
                            currentValue: currentWeight.toString(),
                            onSave: (v) => setState(() => currentWeight =
                                double.tryParse(v) ?? currentWeight)),
                        child: GlassCard(
                            color: Colors.black.withOpacity(0.4),
                            child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Icon(Icons.monitor_weight_outlined,
                                                color: Colors.white70),
                                            Icon(Icons.edit,
                                                size: 14, color: Colors.white30)
                                          ]),
                                      const SizedBox(height: 10),
                                      const Text("Weight",
                                          style: TextStyle(color: Colors.grey)),
                                      const SizedBox(height: 5),
                                      RichText(
                                          text: TextSpan(children: [
                                        TextSpan(
                                            text: "$currentWeight",
                                            style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: weightColor)),
                                        TextSpan(
                                            text: " / $targetWeight kg",
                                            style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.grey))
                                      ]))
                                    ]))))),
                const SizedBox(width: 15),
                Expanded(
                    child: GlassCard(
                        color: Colors.black.withOpacity(0.4),
                        child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.star_outline_rounded,
                                      color: Color(0xFFFFD700)),
                                  const SizedBox(height: 10),
                                  const Text("Health Score",
                                      style: TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 5),
                                  const Text("8.5/10",
                                      style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          shadows: [
                                            BoxShadow(
                                                color: Color(0xFFFFD700),
                                                blurRadius: 10)
                                          ]))
                                ]))))
              ]),
              const SizedBox(height: 20),
              const Text("Daily Notes",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 10),
              GlassCard(
                  color: Colors.black.withOpacity(0.4),
                  child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: TextField(
                          controller: _notesController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 3,
                          decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: "How are you feeling today?",
                              hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.5)),
                              icon: const Icon(Icons.edit_note,
                                  color: Colors.white70))))),
              const SizedBox(height: 20),
            ],
          ),
        ));
  }

  Widget _buildStatColumn(String label, String val, String unit, Color color) {
    return Column(children: [
      Text(val,
          style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: color,
              shadows: [
                BoxShadow(
                    color: color.withOpacity(0.7),
                    blurRadius: 10,
                    spreadRadius: 2)
              ])),
      Text("$label ($unit)",
          style: const TextStyle(fontSize: 13, color: Colors.white70))
    ]);
  }

  Widget _buildMacroRow(String label, int val, int target, Color color) {
    double progress = (val / target).clamp(0.0, 1.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text("$val / $target g",
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 12))
      ]),
      const SizedBox(height: 5),
      ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6))
    ]);
  }
}

// ---------------------------------------------------------------------------
// 2. MEALS TAB
// ---------------------------------------------------------------------------

class MealsTab extends StatefulWidget {
  final Function(int) onEarnXP;

  const MealsTab({super.key, required this.onEarnXP});

  @override
  State<MealsTab> createState() => _MealsTabState();
}

class _MealsTabState extends State<MealsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  DateTime _selectedDate = DateTime.now();
  late List<MealEntry> history;

  @override
  void initState() {
    super.initState();
    DateTime today = DateTime.now();
    history = [
      MealEntry("Avocado Toast", "350 kcal", "08:30 AM", "Prot: 8g • Fat: 12g",
          "5g", "Vit A, C", Icons.bakery_dining, null, "Breakfast", today,
          imageUrl:
              "https://images.unsplash.com/photo-1588137372308-15f75323ca8d?auto=format&fit=crop&w=200&q=80",
          protein: 8,
          carbs: 40,
          fat: 12),
      MealEntry("Greek Yogurt", "120 kcal", "10:30 AM", "Prot: 15g • Fat: 0g",
          "0g", "Calc", Icons.icecream, null, "Snack", today,
          imageUrl:
              "https://images.unsplash.com/photo-1488477181946-6428a029177b?auto=format&fit=crop&w=200&q=80",
          protein: 15,
          carbs: 8,
          fat: 0),
      MealEntry("Chicken Salad", "450 kcal", "01:15 PM", "Prot: 40g • Fat: 8g",
          "4g", "Iron", Icons.restaurant, null, "Lunch", today,
          imageUrl:
              "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=200&q=80",
          protein: 40,
          carbs: 10,
          fat: 8),
    ];
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030));
    if (picked != null) setState(() => _selectedDate = picked);
  }

  bool _isSameDay(DateTime d1, DateTime d2) =>
      d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;

  Future<void> _showAddMealPopup(BuildContext context) async {
    await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
                color: Color(0xFF1E2129),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text("Log Entry",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                  leading:
                      const Icon(Icons.camera_alt, color: Color(0xFF00F0FF)),
                  title: const Text("Take Photo",
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImageAndShowDetails(ImageSource.camera);
                  }),
              ListTile(
                  leading:
                      const Icon(Icons.photo_library, color: Color(0xFF6C63FF)),
                  title: const Text("Choose from Gallery",
                      style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImageAndShowDetails(ImageSource.gallery);
                  }),
              const SizedBox(height: 20)
            ])));
  }

  Future<void> _pickImageAndShowDetails(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null && mounted)
        _showMealDetailsDialog(imageFile: File(image.path));
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  // UPDATED DIALOG with CIRCULAR NUTRITION
  void _showMealDetailsDialog(
      {File? imageFile, MealEntry? existingEntry, int? editIndex}) {
    bool isEditing = existingEntry != null;
    String initialName = isEditing ? existingEntry!.name : "Grilled Chicken";
    String initialCals = isEditing ? existingEntry!.cals : "450 kcal";

    TextEditingController nameController =
        TextEditingController(text: initialName);
    TextEditingController calController =
        TextEditingController(text: initialCals);
    TextEditingController nutriController = TextEditingController(
        text: isEditing ? existingEntry!.nutrition : "Prot: 40g • Fat: 10g");
    TextEditingController fiberController =
        TextEditingController(text: isEditing ? existingEntry!.fiber : "4g");
    TextEditingController vitController = TextEditingController(
        text: isEditing ? existingEntry!.vitamins : "Vit A, B6");

    double p = isEditing ? existingEntry!.protein : 25;
    double c = isEditing ? existingEntry!.carbs : 30;
    double f = isEditing ? existingEntry!.fat : 10;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) =>
            StatefulBuilder(builder: (context, setModalState) {
              return Container(
                  height: MediaQuery.of(context).size.height * 0.9,
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                      color: Color(0xFF0F1115),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(30))),
                  child: SingleChildScrollView(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Center(
                            child: Container(
                                width: 50,
                                height: 5,
                                decoration: BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.circular(10)))),
                        const SizedBox(height: 20),

                        // CIRCULAR NUTRITION VISUALIZATION
                        Center(
                          child: SizedBox(
                            height: 180,
                            width: 180,
                            child: CustomPaint(
                              painter: NutritionRingPainter(
                                  protein: p, carbs: c, fat: f),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.bolt,
                                        color: Colors.orangeAccent),
                                    Text(
                                        calController.text
                                            .replaceAll(" kcal", ""),
                                        style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                    const Text("kcal",
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 12))
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildLegendItem("Prot", const Color(0xFFE040FB)),
                              const SizedBox(width: 10),
                              _buildLegendItem("Carb", const Color(0xFF00E676)),
                              const SizedBox(width: 10),
                              _buildLegendItem("Fat", const Color(0xFF00B0FF)),
                            ]),

                        const SizedBox(height: 30),

                        if (imageFile != null || existingEntry?.image != null)
                          ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.file(
                                  imageFile ?? existingEntry!.image!,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover)),

                        const SizedBox(height: 20),
                        TextField(
                            controller: nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                                labelText: "Name",
                                labelStyle: TextStyle(color: Colors.grey))),
                        const SizedBox(height: 15),
                        TextField(
                            controller: calController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                                labelText: "Cals",
                                labelStyle: TextStyle(color: Colors.grey))),

                        const SizedBox(height: 15),
                        Row(children: [
                          Expanded(
                              child: TextField(
                                  controller: fiberController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                      labelText: "Fiber",
                                      labelStyle:
                                          TextStyle(color: Colors.grey)))),
                          const SizedBox(width: 10),
                          Expanded(
                              child: TextField(
                                  controller: vitController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                      labelText: "Vitamins",
                                      labelStyle:
                                          TextStyle(color: Colors.grey)))),
                        ]),

                        const SizedBox(height: 30),
                        Row(children: [
                          if (isEditing)
                            Expanded(
                                child: BouncingButton(
                                    onTap: () {
                                      setState(() {
                                        history.removeAt(editIndex!);
                                      });
                                      Navigator.pop(context);
                                      showFuturisticSnackBar(
                                          context, "Deleted", Colors.redAccent,
                                          icon: SizedBox(
                                              height: 30,
                                              width: 30,
                                              child: Lottie.network(
                                                  'https://assets2.lottiefiles.com/packages/lf20_WCY7Y6.json')));
                                    },
                                    child: Container(
                                        padding: const EdgeInsets.all(15),
                                        decoration: BoxDecoration(
                                            color: Colors.redAccent
                                                .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            border: Border.all(
                                                color: Colors.redAccent)),
                                        child: const Center(
                                            child: Icon(Icons.delete,
                                                color: Colors.redAccent))))),
                          if (isEditing) const SizedBox(width: 10),
                          Expanded(
                              flex: 2,
                              child: BouncingButton(
                                  onTap: () {
                                    MealEntry entry = MealEntry(
                                        nameController.text,
                                        calController.text,
                                        "Now",
                                        nutriController.text,
                                        fiberController.text,
                                        vitController.text,
                                        Icons.food_bank,
                                        imageFile ?? existingEntry?.image,
                                        "Lunch",
                                        _selectedDate,
                                        imageUrl: existingEntry?.imageUrl,
                                        protein: p,
                                        carbs: c,
                                        fat: f);
                                    setState(() {
                                      if (isEditing)
                                        history[editIndex!] = entry;
                                      else {
                                        history.insert(0, entry);
                                        widget.onEarnXP(20);
                                      }
                                    });
                                    Navigator.pop(context);
                                    showFuturisticSnackBar(
                                        context,
                                        isEditing ? "Updated!" : "Logged!",
                                        const Color(0xFF00E676),
                                        icon: SizedBox(
                                            height: 40,
                                            width: 40,
                                            child: Lottie.network(
                                                'https://assets9.lottiefiles.com/packages/lf20_vT1rK7.json')));
                                  },
                                  child: Container(
                                      padding: const EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                          color: const Color(0xFF6C63FF),
                                          borderRadius:
                                              BorderRadius.circular(15)),
                                      child: const Center(
                                          child: Text("Save",
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight:
                                                      FontWeight.bold))))))
                        ]),
                        const SizedBox(height: 40),
                      ])));
            }));
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(children: [
      Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12))
    ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    List<MealEntry> filtered =
        history.where((e) => _isSameDay(e.dateTime, _selectedDate)).toList();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 130),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text("Meal Log",
              style: TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
          IconButton(
              icon: const Icon(Icons.calendar_month, color: Color(0xFF00F0FF)),
              onPressed: () => _pickDate(context))
        ]),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
              child: GestureDetector(
                  onTap: () => _showMealDetailsDialog(),
                  child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                          color: const Color(0xFF1E2129),
                          borderRadius: BorderRadius.circular(15)),
                      child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_circle_outline,
                                color: Color(0xFFE09F3E)),
                            SizedBox(width: 8),
                            Text("Manual Add",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold))
                          ])))),
          const SizedBox(width: 15),
          Expanded(
              child: GestureDetector(
                  onTap: () => _showAddMealPopup(context),
                  child: Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                          color: const Color(0xFF1E2129),
                          borderRadius: BorderRadius.circular(15)),
                      child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_scanner,
                                color: Color(0xFFE09F3E)),
                            SizedBox(width: 8),
                            Text("AI Scan",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold))
                          ])))),
        ]),
        const SizedBox(height: 30),
        const Text("Recently had",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 15),
        ...filtered
            .map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Dismissible(
                    key: Key("${e.name}_${history.indexOf(e)}"),
                    background: Container(
                        color: Colors.redAccent.withOpacity(0.5),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white)),
                    onDismissed: (direction) {
                      setState(() {
                        history.remove(e);
                      });
                      showFuturisticSnackBar(
                          context, "Meal Deleted", Colors.redAccent,
                          icon: SizedBox(
                              height: 30,
                              width: 30,
                              child: Lottie.network(
                                  'https://assets2.lottiefiles.com/packages/lf20_WCY7Y6.json')));
                    },
                    child: GestureDetector(
                      onTap: () => _showMealDetailsDialog(
                          existingEntry: e, editIndex: history.indexOf(e)),
                      child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(20)),
                          child: Row(children: [
                            ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: e.image != null
                                    ? Image.file(e.image!,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover)
                                    : (e.imageUrl != null
                                        ? Image.network(e.imageUrl!,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) =>
                                                Container(
                                                    width: 60,
                                                    height: 60,
                                                    color: Colors.grey,
                                                    child: const Icon(
                                                        Icons.fastfood)))
                                        : Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey,
                                            child:
                                                const Icon(Icons.fastfood)))),
                            const SizedBox(width: 15),
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text(e.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.white)),
                                  const SizedBox(height: 4),
                                  Text(e.cals,
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.6),
                                          fontSize: 12)),
                                  const SizedBox(height: 4),
                                  // Added explicit nutrition details row
                                  Text(
                                      "Prot: ${e.protein.toInt()}g • Fib: ${e.fiber} • ${e.vitamins}",
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.4),
                                          fontSize: 10)),
                                ])),
                            IconButton(
                                icon: const Icon(Icons.arrow_forward_ios,
                                    size: 16, color: Colors.grey),
                                onPressed: () => _showMealDetailsDialog(
                                    existingEntry: e,
                                    editIndex: history.indexOf(e)))
                          ])),
                    ))))
            .toList()
      ]),
    );
  }
}

// Circular Painter for Nutrition
class NutritionRingPainter extends CustomPainter {
  final double protein;
  final double carbs;
  final double fat;

  NutritionRingPainter(
      {required this.protein, required this.carbs, required this.fat});

  @override
  void paint(Canvas canvas, Size size) {
    double total = protein + carbs + fat;
    double startAngle = -math.pi / 2;
    double center = size.width / 2;
    double radius = size.width / 2 - 10;
    Rect rect = Rect.fromCircle(center: Offset(center, center), radius: radius);

    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    // Protein (Purple)
    paint.color = const Color(0xFFE040FB);
    double sweep1 = (protein / total) * 2 * math.pi;
    canvas.drawArc(rect, startAngle, sweep1, false, paint);

    // Carbs (Cyan)
    startAngle += sweep1;
    paint.color = const Color(0xFF00E676);
    double sweep2 = (carbs / total) * 2 * math.pi;
    canvas.drawArc(rect, startAngle, sweep2, false, paint);

    // Fat (Blue)
    startAngle += sweep2;
    paint.color = const Color(0xFF00B0FF);
    double sweep3 = (fat / total) * 2 * math.pi;
    canvas.drawArc(rect, startAngle, sweep3, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ---------------------------------------------------------------------------
// 3. MENTAL HEALTH TAB
// ---------------------------------------------------------------------------

class MentalHealthTab extends StatefulWidget {
  const MentalHealthTab({super.key});

  @override
  State<MentalHealthTab> createState() => _MentalHealthTabState();
}

class _MentalHealthTabState extends State<MentalHealthTab> {
  String _aiQuote = "Your mind is a garden. Your thoughts are the seeds.";
  List<Map<String, String>> _history = [
    {
      "type": "Chat",
      "date": "Today",
      "preview": "Feeling anxious about work..."
    },
    {
      "type": "Journal",
      "date": "Yesterday",
      "preview": "Grateful for the sunshine today."
    },
    {
      "type": "Chat",
      "date": "2 days ago",
      "preview": "Discussed sleep patterns."
    },
  ];

  void _addEntry(String type, String text) {
    setState(() {
      _history.insert(0, {
        "type": type,
        "date": "Just Now",
        "preview": text,
      });
    });
    showFuturisticSnackBar(context, "$type Saved!", const Color(0xFF00E676),
        icon: SizedBox(
            height: 30,
            width: 30,
            child: Lottie.network(
                'https://assets3.lottiefiles.com/packages/lf20_HjK9Ol.json'))); // Pencil Lottie
  }

  void _openChatSession() {
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
        builder: (context) => FullScreenChatPage(onAddEntry: _addEntry)));
  }

  void _openJournalSession() {
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
        builder: (context) => FullScreenJournalPage(onAddEntry: _addEntry)));
  }

  void _showAIInsight() {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF1E2129),
                title: const Row(children: [
                  Icon(Icons.auto_awesome, color: Color(0xFFE040FB)),
                  SizedBox(width: 10),
                  Text("AI Mind Analysis",
                      style: TextStyle(color: Colors.white))
                ]),
                content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Current State: Balanced",
                          style: TextStyle(
                              color: Color(0xFF00E676),
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Text(
                          "You have been logging consistent positive journal entries.",
                          style: TextStyle(color: Colors.white70)),
                      SizedBox(height: 15),
                      Text("Suggestion:",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      Text("Try a 5-minute meditation before sleep.",
                          style: TextStyle(color: Colors.white54))
                    ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Close",
                          style: TextStyle(color: Colors.grey)))
                ]));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 100),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Mental Wellness",
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 20),
          GlassCard(
              color: Colors.white.withOpacity(0.08),
              child: Padding(
                  padding: const EdgeInsets.all(25),
                  child: Column(children: [
                    // REPLACED WITH BRAIN LOTTIE, USE ASSET IF LOCAL
                    SizedBox(
                        height: 120,
                        width: 120,
                        child: Lottie.asset('assets/lottie_animation.lottie',
                            errorBuilder: (c, e, s) => const Icon(
                                Icons.auto_awesome,
                                color: Color(0xFF6C63FF),
                                size: 50))),
                    const SizedBox(height: 15),
                    Text("\"$_aiQuote\"",
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Colors.white))
                  ]))),
          const SizedBox(height: 30),
          Row(children: [
            Expanded(
                child: BouncingButton(
                    onTap: _openChatSession,
                    child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                            color: const Color(0xFF00B0FF).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color:
                                    const Color(0xFF00B0FF).withOpacity(0.4))),
                        child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  color: Color(0xFF00B0FF), size: 30),
                              SizedBox(height: 10),
                              Text("Chat",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold))
                            ])))),
            const SizedBox(width: 15),
            Expanded(
                child: BouncingButton(
                    onTap: _openJournalSession,
                    child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                            color: const Color(0xFFE040FB).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color:
                                    const Color(0xFFE040FB).withOpacity(0.4))),
                        child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.book,
                                  color: Color(0xFFE040FB), size: 30),
                              SizedBox(height: 10),
                              Text("Journal",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold))
                            ]))))
          ]),
          const SizedBox(height: 20),
          BouncingButton(
              onTap: _showAIInsight,
              child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF00F0FF)]),
                      borderRadius: BorderRadius.circular(15)),
                  child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.analytics, color: Colors.white),
                        SizedBox(width: 10),
                        Text("View AI Insights",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold))
                      ]))),
          const SizedBox(height: 30),
          const Text("History",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 15),
          ..._history.asMap().entries.map((entry) {
            int idx = entry.key;
            var item = entry.value;
            return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Dismissible(
                    key: Key("${item['type']}_$idx"),
                    background: Container(
                        color: Colors.redAccent.withOpacity(0.5),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 20),
                        child: const Icon(Icons.delete, color: Colors.white)),
                    secondaryBackground: Container(
                        color: Colors.blueAccent.withOpacity(0.5),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.archive, color: Colors.white)),
                    onDismissed: (direction) {
                      setState(() {
                        _history.removeAt(idx);
                      });
                      bool isDelete = direction == DismissDirection.startToEnd;
                      showFuturisticSnackBar(
                          context,
                          isDelete ? "Deleted" : "Archived",
                          isDelete ? Colors.redAccent : Colors.blueAccent,
                          icon: SizedBox(
                              height: 30,
                              width: 30,
                              child: Lottie.network(isDelete
                                  ? 'https://assets2.lottiefiles.com/packages/lf20_WCY7Y6.json'
                                  : 'https://assets8.lottiefiles.com/packages/lf20_1LhsaB.json')));
                    },
                    child: GlassCard(
                        child: ListTile(
                            leading: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                    color: item['type'] == 'Chat'
                                        ? Colors.blue.withOpacity(0.2)
                                        : Colors.purple.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(5)),
                                child:
                                    Text(item['type'] == 'Chat' ? "💬 Chat" : "📝 Journal",
                                        style: TextStyle(
                                            color: item['type'] == 'Chat'
                                                ? Colors.blue
                                                : Colors.purple,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold))),
                            title: Text(item['preview']!,
                                style: const TextStyle(color: Colors.white),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            trailing: Text(item['date']!,
                                style: const TextStyle(color: Colors.white30, fontSize: 12))))));
          }).toList()
        ]));
  }
}

class FullScreenChatPage extends StatefulWidget {
  final Function(String, String) onAddEntry; // Callback
  const FullScreenChatPage({super.key, required this.onAddEntry});

  @override
  State<FullScreenChatPage> createState() => _FullScreenChatPageState();
}

class _FullScreenChatPageState extends State<FullScreenChatPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {"text": "Hi there! I'm here to listen.", "isUser": false}
  ];

  void _sendMessage() {
    if (_controller.text.isEmpty) return;
    String userText = _controller.text;
    setState(() {
      _messages.add({"text": userText, "isUser": true});
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted)
          setState(
              () => _messages.add({"text": "I hear you.", "isUser": false}));
      });
    });
    // Save to main history
    widget.onAddEntry("Chat", userText);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text("AI Companion"),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context))),
      body: Column(children: [
        Expanded(
            child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _messages.length,
                itemBuilder: (ctx, i) {
                  final msg = _messages[i];
                  bool isUser = msg['isUser'];
                  return Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(15),
                          constraints: const BoxConstraints(maxWidth: 250),
                          decoration: BoxDecoration(
                              color: isUser
                                  ? const Color(0xFF6C63FF).withOpacity(0.3)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: isUser
                                      ? const Color(0xFF6C63FF).withOpacity(0.5)
                                      : Colors.transparent)),
                          child: Text(msg['text'],
                              style: const TextStyle(color: Colors.white))));
                })),
        Container(
            padding: const EdgeInsets.all(20),
            color: Colors.black54,
            child: Row(children: [
              Expanded(
                  child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                          hintText: "Type a message...",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: InputBorder.none))),
              IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF6C63FF)),
                  onPressed: _sendMessage)
            ]))
      ]),
    );
  }
}

class FullScreenJournalPage extends StatelessWidget {
  final Function(String, String) onAddEntry; // Callback
  const FullScreenJournalPage({super.key, required this.onAddEntry});

  @override
  Widget build(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController bodyController = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text("Journal"),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context))),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
                controller: titleController,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                    hintText: "Title",
                    hintStyle: TextStyle(color: Colors.white30),
                    border: InputBorder.none)),
            const Divider(color: Colors.white24),
            Expanded(
                child: TextField(
                    controller: bodyController,
                    style: const TextStyle(color: Colors.white70),
                    maxLines: null,
                    decoration: const InputDecoration(
                        hintText: "Write your thoughts...",
                        hintStyle: TextStyle(color: Colors.white30),
                        border: InputBorder.none))),
            BouncingButton(
                onTap: () {
                  if (bodyController.text.isNotEmpty) {
                    onAddEntry(
                        "Journal",
                        titleController.text.isNotEmpty
                            ? "${titleController.text}: ${bodyController.text}"
                            : bodyController.text);
                    Navigator.pop(context);
                  }
                },
                child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                        color: const Color(0xFFE040FB),
                        borderRadius: BorderRadius.circular(15)),
                    child: const Center(
                        child: Text("Save Entry",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)))))
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. EXERCISES TAB
// ---------------------------------------------------------------------------

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

class _ExercisesTabState extends State<ExercisesTab>
    with AutomaticKeepAliveClientMixin {
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
        showFuturisticSnackBar(
            context, "Plan Generated!", const Color(0xFF00E676),
            emoji: "⚡");
      }),
    );
  }

  void _startWorkout() {
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(
        builder: (context) => WorkoutExecutionPage(
            plan: widget.activePlan!,
            onFinish: (record, xp) {
              widget.onAddRecord(record);
              widget.onEarnXP(xp);
            })));
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
              Expanded(
                  child: _buildSummaryCard(
                      "Mins Today", "24", Icons.timer, Colors.blueAccent)),
              const SizedBox(width: 10),
              Expanded(
                  child: _buildSummaryCard("Streak", "4 Days",
                      Icons.local_fire_department, Colors.orangeAccent)),
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
                        const Text("Current Plan",
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(5)),
                            child: const Text("Active",
                                style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)))
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(widget.activePlan!.title,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 5),
                    Text(
                        "${widget.activePlan!.duration} • ${widget.activePlan!.focus}",
                        style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 20),
                    // Exercise Preview List
                    ...widget.activePlan!.exercises
                        .take(3)
                        .map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(children: [
                                Icon(
                                    e.isCompleted
                                        ? Icons.check_circle
                                        : Icons.circle_outlined,
                                    color: e.isCompleted
                                        ? const Color(0xFF00E676)
                                        : Colors.grey,
                                    size: 16),
                                const SizedBox(width: 10),
                                Text(e.name,
                                    style: TextStyle(
                                        color: e.isCompleted
                                            ? Colors.white54
                                            : Colors.white,
                                        decoration: e.isCompleted
                                            ? TextDecoration.lineThrough
                                            : null))
                              ]),
                            ))
                        .toList(),
                    if (widget.activePlan!.exercises.length > 3)
                      const Text("...and more",
                          style: TextStyle(color: Colors.grey, fontSize: 10)),
                    const SizedBox(height: 20),
                    BouncingButton(
                      onTap: _startWorkout,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF),
                            borderRadius: BorderRadius.circular(15)),
                        child: const Center(
                            child: Text("Start Workout",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold))),
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
                    gradient: const LinearGradient(
                        colors: [Color(0xFF00F0FF), Color(0xFF6C63FF)]),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.3),
                          blurRadius: 20)
                    ]),
                child: const Column(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 40),
                    SizedBox(height: 10),
                    Text("Generate AI Workout Plan",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text("Personalized to your goals",
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 30),

          // 8. AI COACH SUGGESTION
          GlassCard(
            color: Colors.white.withOpacity(0.05),
            child: ListTile(
              leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                      color: Colors.purpleAccent, shape: BoxShape.circle),
                  child: const Icon(Icons.lightbulb,
                      color: Colors.white, size: 20)),
              title: const Text("Coach Tip",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              subtitle: const Text(
                  "You trained legs yesterday. Try Upper Body today?",
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios,
                  color: Colors.grey, size: 14),
              onTap: _showGeneratePlanDialog,
            ),
          ),

          const SizedBox(height: 30),

          // 5. HISTORY
          const Text("Workout History",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 15),

          if (widget.history.isEmpty)
            const Center(
                child: Text("No workouts yet. Let's go!",
                    style: TextStyle(color: Colors.grey)))
          else
            ...widget.history.asMap().entries.map((entry) {
              int idx = entry.key;
              var record = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Dismissible(
                  key: Key("${record.title}_$idx"),
                  background: Container(
                      color: Colors.redAccent,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white)),
                  onDismissed: (direction) {
                    widget.onDeleteRecord(idx);
                    showFuturisticSnackBar(
                        context, "Workout Deleted", Colors.redAccent,
                        emoji: "🗑️");
                  },
                  child: GlassCard(
                    child: ListTile(
                      leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.fitness_center,
                              color: Color(0xFF00E676))),
                      title: Text(record.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      subtitle: Text("${record.duration} • ${record.cals}",
                          style: const TextStyle(color: Colors.white54)),
                      trailing: const Icon(Icons.check_circle,
                          color: Color(0xFF00E676), size: 16),
                    ),
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String val, IconData icon, Color color) {
    return GlassCard(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(val,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            Text(title,
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
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

  @override
  State<_GeneratePlanPopup> createState() => _GeneratePlanPopupState();
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
            "$_selectedGoal Focus", _selectedDuration, "Full Body", [
          ExerciseItem("Push Ups", "15", "3", "",
              "https://assets2.lottiefiles.com/packages/lf20_3ntisyac.json"),
          ExerciseItem("Squats", "20", "3", "",
              "https://assets9.lottiefiles.com/packages/lf20_vT1rK7.json"),
          ExerciseItem("Plank", "1", "3", "60s",
              "https://assets8.lottiefiles.com/packages/lf20_znsm7udl.json"),
        ]));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
          color: Color(0xFF1E2129),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
              child: Text("Configure Plan",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold))),
          const SizedBox(height: 20),
          if (_generating)
            const Center(
                child: Column(children: [
              CircularProgressIndicator(color: Color(0xFF6C63FF)),
              SizedBox(height: 20),
              Text("AI is crafting your routine...",
                  style: TextStyle(color: Colors.white70))
            ]))
          else ...[
            const Text("Goal", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            Wrap(
                spacing: 10,
                children: ["Build Muscle", "Lose Fat", "Cardio"]
                    .map((g) => ChoiceChip(
                          label: Text(g),
                          selected: _selectedGoal == g,
                          onSelected: (b) => setState(() => _selectedGoal = g),
                          selectedColor: const Color(0xFF6C63FF),
                          backgroundColor: Colors.white10,
                          labelStyle: const TextStyle(color: Colors.white),
                        ))
                    .toList()),
            const SizedBox(height: 20),
            const Text("Duration", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            Wrap(
                spacing: 10,
                children: ["15 min", "30 min", "45 min"]
                    .map((d) => ChoiceChip(
                          label: Text(d),
                          selected: _selectedDuration == d,
                          onSelected: (b) =>
                              setState(() => _selectedDuration = d),
                          selectedColor: const Color(0xFF00F0FF),
                          backgroundColor: Colors.white10,
                          labelStyle: const TextStyle(color: Colors.white),
                        ))
                    .toList()),
            const SizedBox(height: 30),
            BouncingButton(
              onTap: _generate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF),
                    borderRadius: BorderRadius.circular(15)),
                child: const Center(
                    child: Text("Generate",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold))),
              ),
            ),
            const SizedBox(height: 20),
          ]
        ],
      ),
    );
  }
}

// FULL SCREEN: WORKOUT EXECUTION
class WorkoutExecutionPage extends StatefulWidget {
  final ExercisePlan plan;
  final Function(WorkoutRecord, int) onFinish;

  const WorkoutExecutionPage(
      {super.key, required this.plan, required this.onFinish});

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
    _timer = Timer.periodic(const Duration(seconds: 1),
        (timer) => setState(() => _secondsElapsed++));
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
          WorkoutRecord(widget.plan.title, _formatTime(_secondsElapsed),
              "150 kcal", DateTime.now()),
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
        title: Text(_formatTime(_secondsElapsed),
            style: const TextStyle(fontFamily: 'Courier')), // Timer style
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context)),
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
                decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(30)),
                child: Lottie.network(exercise.animationUrl,
                    errorBuilder: (c, e, s) => const Icon(Icons.fitness_center,
                        size: 80, color: Colors.white24)),
              ),
            ),
            const SizedBox(height: 30),
            // Details
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Text(exercise.name,
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatBadge("${exercise.sets} Sets"),
                      const SizedBox(width: 15),
                      _buildStatBadge("${exercise.reps} Reps"),
                      if (exercise.time.isNotEmpty) ...[
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
                          boxShadow: [
                            BoxShadow(
                                color: const Color(0xFF00E676).withOpacity(0.4),
                                blurRadius: 20)
                          ]),
                      child: Center(
                          child: Text(
                              _currentExerciseIndex <
                                      widget.plan.exercises.length - 1
                                  ? "Next Exercise"
                                  : "Finish Workout",
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold))),
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
          borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. TRENDS TAB (FULLY RESTORED)
// ---------------------------------------------------------------------------

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
                  Text("Trends & Insights",
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  SizedBox(height: 4),
                  Text("Your last 7 days at a glance",
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24)),
                child: const Row(
                  children: [
                    Text("Week",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                    Icon(Icons.keyboard_arrow_down,
                        color: Colors.white, size: 16)
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
                _buildKPICard(
                    "Calories In", "2,100", "avg/day", const Color(0xFFFF9100)),
                const SizedBox(width: 10),
                _buildKPICard(
                    "Calories Out", "540", "avg/day", const Color(0xFF00B0FF)),
                const SizedBox(width: 10),
                _buildKPICard(
                    "Sleep Avg", "6.8", "hrs", const Color(0xFFE040FB)),
                const SizedBox(width: 10),
                _buildKPICard(
                    "Hydration", "78%", "target", const Color(0xFF00E676)),
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
                          Text("Calorie Balance",
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                          Text("Intake vs Burn",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.white10, shape: BoxShape.circle),
                        child: const Icon(Icons.bar_chart,
                            color: Colors.white70, size: 20),
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
                      Text("In",
                          style: TextStyle(color: Colors.grey, fontSize: 10)),
                      SizedBox(width: 15),
                      Icon(Icons.circle, size: 10, color: Color(0xFF00B0FF)),
                      SizedBox(width: 5),
                      Text("Out",
                          style: TextStyle(color: Colors.grey, fontSize: 10)),
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
                      Text("AI Insight",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildInsightItem(
                      "You consumed 22% more calories on weekends."),
                  const SizedBox(height: 10),
                  _buildInsightItem(
                      "Low sleep (<6 hrs) correlates with higher sugar intake."),
                  const SizedBox(height: 15),
                  BouncingButton(
                      onTap: () {},
                      child: const Text("Ask AI Coach for more details >",
                          style: TextStyle(
                              color: Color(0xFF00B0FF),
                              fontWeight: FontWeight.bold,
                              fontSize: 12)))
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),

          // (F) Predictions Slider
          const Text("Predictions",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 15),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPredictionCard("Weight", "Trending Down",
                    Icons.trending_down, const Color(0xFF00E676)),
                const SizedBox(width: 15),
                _buildPredictionCard("Consistency", "High Prob.",
                    Icons.trending_up, const Color(0xFF00B0FF)),
                const SizedBox(width: 15),
                _buildPredictionCard("Sleep", "Improving", Icons.bedtime,
                    const Color(0xFFE040FB)),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // (G) Achievements / Trophies
          const Text("Monthly Highlights",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBadge("Hydration Hero", Icons.water_drop, Colors.blue),
              _buildBadge("Early Bird", Icons.wb_sunny, Colors.orange),
              _buildBadge("Protein Pro", Icons.fitness_center, Colors.purple),
              _buildBadge(
                  "On Fire", Icons.local_fire_department, Colors.redAccent),
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
            Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 11)),
            const SizedBox(height: 5),
            Text(value,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.bold, fontSize: 22)),
            Text(unit,
                style: const TextStyle(color: Colors.white38, fontSize: 10)),
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
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 13, height: 1.4))),
      ],
    );
  }

  Widget _buildPredictionCard(
      String title, String status, IconData icon, Color color) {
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
            Text(title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(status,
                style: TextStyle(color: color.withOpacity(0.8), fontSize: 11)),
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
              border: Border.all(color: color.withOpacity(0.5))),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(title,
            style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}

class _TrendsLineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint linePaint1 = Paint()
      ..color = const Color(0xFFFF9100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    Paint linePaint2 = Paint()
      ..color = const Color(0xFF00B0FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

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
        double prevY1 = size.height - (points1[i - 1] * size.height);
        double prevY2 = size.height - (points2[i - 1] * size.height);
        double cpX = (prevX + x) / 2;
        path1.cubicTo(cpX, prevY1, cpX, y1, x, y1);
        path2.cubicTo(cpX, prevY2, cpX, y2, x, y2);
      }
    }
    canvas.drawPath(path1, linePaint1);
    canvas.drawPath(path2, linePaint2);

    Path fillPath = Path.from(path1)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
        fillPath,
        Paint()
          ..shader = LinearGradient(colors: [
            const Color(0xFFFF9100).withOpacity(0.2),
            Colors.transparent
          ], begin: Alignment.topCenter, end: Alignment.bottomCenter)
              .createShader(Rect.fromLTWH(0, 0, size.width, size.height)));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AICoachTab extends StatelessWidget {
  const AICoachTab({super.key});

  @override
  Widget build(BuildContext context) => const Center(
      child: Text("AI Coach Tab Placeholder",
          style: TextStyle(color: Colors.white)));
}

class BouncingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const BouncingButton({super.key, required this.child, required this.onTap});

  @override
  State<BouncingButton> createState() => _BouncingButtonState();
}

class _BouncingButtonState extends State<BouncingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _s = Tween<double>(begin: 1, end: 0.9).animate(_c);
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.onTap();
      },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(scale: _s, child: widget.child));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final Color? color;

  const GlassCard({super.key, required this.child, this.color});

  @override
  Widget build(BuildContext context) => ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
              decoration: BoxDecoration(
                  color: color ?? Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10)),
              child: child)));
}

class FuturisticSlider extends StatelessWidget {
  final double value;
  final Color color;
  final Function(double) onChanged;
  final VoidCallback onStart;
  final VoidCallback onEnd;

  const FuturisticSlider(
      {super.key,
      required this.value,
      required this.color,
      required this.onChanged,
      required this.onStart,
      required this.onEnd});

  @override
  Widget build(BuildContext context) => Slider(
      value: value,
      onChanged: onChanged,
      activeColor: color,
      onChangeStart: (_) => onStart(),
      onChangeEnd: (_) => onEnd());
}

void showFuturisticSnackBar(BuildContext context, String title, Color color,
    {String? subtitle, Widget? icon, bool isRive = false, String? emoji}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      content: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: const Color(0xFF1E2129).withOpacity(0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                            color: color.withOpacity(0.2),
                            blurRadius: 15,
                            spreadRadius: 2)
                      ]),
                  child: Row(children: [
                    if (icon != null)
                      icon
                    else if (emoji != null)
                      Text(emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 15),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                          Text(title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white)),
                          if (subtitle != null)
                            Text(subtitle,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12))
                        ]))
                  ]))))));
}

class WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
