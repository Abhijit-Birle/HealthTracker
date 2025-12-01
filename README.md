🧬 Zeno - Holistic Health Companion (Frontend)

Zeno is a futuristic, gamified health tracking application built with Flutter. It integrates deeply with Apple Health to track physical metrics (Steps, Sleep, Calories, Workouts) and combines them with manual logging for Mental Health and Nutrition.

The app uses a unique "Energy System" that gamifies your health data, turning steps and sleep into "Energy Units" (EU) that level up your virtual state from Idle to Quantum State.

📱 Features

1. 🏠 Dashboard (The Core)

Live Apple Health Sync: Syncs Steps, Active Energy, Resting Energy, Weight, and Sleep directly from HealthKit.

Energy System: Gamified progress bar that reacts to your daily activity.

Interactive Sliders: Track Mood and Stress levels with futuristic UI controls.

Daily Snapshot: Quick view of Sleep, Hydration, and Macro targets.

2. 🥗 Nutrition Tracking

Visual Logs: Log meals with photos and auto-calculated macros.

Circular Breakdown: Beautiful custom-painted charts for Protein, Carbs, and Fats.

AI Scan (Mock): Placeholder for camera-based food recognition.

3. 🧠 Mental Wellness

Mood Journal: Track emotional states over time.

AI Chat: A conversational interface for mental health check-ins.

Insights: AI-driven text analysis of your journal entries.

4. 🏋️ Workout & Trends

Routine Generator: Select goals (Muscle/Cardio) and duration to generate plans.

Execution Mode: Guided workout timer with Lottie animations.

Data Trends: 7-day analysis of Calorie Balance (In vs. Out) and Sleep consistency.

🛠 Tech Stack

Framework: Flutter (Dart)

State Management: provider

Health Integration: health (Apple HealthKit / Google Health Connect)

Networking: http

Animations: lottie, rive

UI/UX: Custom Painters (Liquid Nav Bar, Circular Charts), Glassmorphism effects.

🚀 Getting Started

Prerequisites

Flutter SDK (3.0+)

Xcode (for iOS simulation/building)

CocoaPods

An active Backend server (Spring Boot)

1. Installation

Clone the repository and install dependencies:

git clone [https://github.com/yourusername/zeno-frontend.git](https://github.com/yourusername/zeno-frontend.git)
cd zeno-frontend
flutter pub get


2. Environment Setup

Create a .env file in the root directory to configure your backend URL:

# .env
API_BASE_URL=http://localhost:8080
BACKEND_BASE=[http://192.168.1.7:8080](http://192.168.1.7:8080)


Note: If testing on a real device, use your machine's local IP address instead of localhost.

3. iOS Configuration (Crucial for HealthKit)

To make Apple Health work, you must configure ios/Runner/Info.plist.

Open ios/Runner/Info.plist and ensure these keys exist:

<key>NSHealthShareUsageDescription</key>
<string>We need access to your health data to track steps, sleep, and workouts for your daily score.</string>
<key>NSHealthUpdateUsageDescription</key>
<string>We sync your workout and nutrition data back to Apple Health.</string>


Enable Capabilities in Xcode:

Open ios/Runner.xcworkspace in Xcode.

Select the Runner target.

Go to Signing & Capabilities.

Click + Capability and add HealthKit.

Check "Background Delivery" if you plan to sync in the background.

🏃‍♂️ Running the App

iOS Simulator

Warning: The iOS Simulator has zero health data by default.

Run the app: flutter run

Open the native Health app on the Simulator.

Go to Browse > Activity > Steps.

Tap Add Data and add dummy steps/sleep for "Today".

Pull-to-refresh in Zeno to see the data.

Real Device

Connect your iPhone.

Run flutter run -d <your_device_id>.

When prompted, tap "Turn All Categories On" in the Apple Health permission popup.

🐛 Troubleshooting Health Sync

Issue: "I see 0 Steps or Sleep data."

Cause: Apple Health permissions were denied or not fully granted.

Fix:

Delete the app from the device (Long press -> Remove App).

Re-install the app.

When the popup appears, click "Turn All Categories On" at the top.

Issue: "Weight is not updating."

Cause: Weight is a "snapshot" metric, not continuous.

Fix: Ensure you have logged a weight entry in the Apple Health app within the last 30 days. The app looks back 30 days for body measurements.

Issue: "Calories don't match Apple Health."

Cause: Apple Health smart-merges Watch and Phone data.

Fix: The app logic prioritizes Apple Watch data sources to avoid double-counting steps from the phone in your pocket.

📂 Project Structure

lib/
├── main.dart             # Entry point & App Config
├── models/               # Data models (Dashboard, Tab1Dto)
├── providers/            # State Management (HealthProvider, AuthProvider)
├── services/             # API calls (ApiService)
├── screens/
│   ├── login_screen.dart # Auth UI
│   ├── dashboard_tab.dart# Main Health Dashboard (The complex one)
│   ├── meals_tab.dart    # Nutrition logging
│   └── ...
└── widgets/              # Reusable components (GlassCard, BouncingButton)


🤝 Contributing

Fork the repo.

Create a feature branch (git checkout -b feature/AmazingFeature).g

Commit your changes.

Push to the branch.

Open a Pull
