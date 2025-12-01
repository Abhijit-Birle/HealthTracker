// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:health_tracker_poc/models/user.dart'; // <-- adjust path if your package name differs

/// Minimal AuthProvider for MVP usage.
/// - `login(email, name)` returns Future<bool>
/// - `loading` indicates in-progress state
/// - `user` holds the logged-in user (nullable)
class AuthProvider with ChangeNotifier {
  User? user;

  bool _loading = false;
  bool get loading => _loading;

  AuthProvider({this.user});

  // Safe getters for convenience in the UI.
  String get email => user?.email ?? '';
  String get name => user?.name ?? '';
  bool get isLoggedIn => user != null;

  /// Minimal login stub.
  /// Replace this body with a real backend call when ready.
  Future<bool> login(String email, String name) async {
    _loading = true;
    notifyListeners();

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 700));

      // Create a dummy user for now so UI sees values immediately.
      // If you integrate a real API, replace this with the fetched user:
      // final fetched = await api.login(email, name); user = fetched;
      user = User(id: DateTime.now().millisecondsSinceEpoch.toString(), email: email, name: name);

      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  void logout() {
    user = null;
    notifyListeners();
  }

  void setUser(User? u) {
    user = u;
    notifyListeners();
  }
}
