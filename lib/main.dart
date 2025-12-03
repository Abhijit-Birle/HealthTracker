// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/main_scaffold.dart';
import 'services/health_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthTracker',
      theme: ThemeData.dark(),
      home: const RootDecider(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// RootDecider: shows LoginScreen when no stored userId found, otherwise goes to app.
class RootDecider extends StatefulWidget {
  const RootDecider({Key? key}) : super(key: key);

  @override
  State<RootDecider> createState() => _RootDeciderState();
}

class _RootDeciderState extends State<RootDecider> {
  int? _storedUid;
  bool _loading = true;

  // -- CONFIG: change this to your backend base URL (no trailing /api)
  static const String backendBase = 'http://192.168.1.7:8080';

  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    final hs = HealthService();
    final uid = await hs.getStoredUserId();
    setState(() {
      _storedUid = uid;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_storedUid == null) {
      return LoginScreen(backendBase: backendBase);
    } else {
      return MainScaffold(initialUserId: _storedUid!, backendBase: backendBase);
    }
  }
}
