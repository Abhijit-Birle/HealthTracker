import 'package:flutter/material.dart';

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