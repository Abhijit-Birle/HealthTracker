// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../services/health_service.dart';
import 'main_scaffold.dart';

class LoginScreen extends StatefulWidget {
  final String backendBase;
  final String authToken;

  const LoginScreen({Key? key, required this.backendBase, this.authToken = ''}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSignInPressed() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Please enter email (or use Skip for anonymous).');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final hs = HealthService();

    try {
      final uid = await hs.loginAndSync(
        email: email,
        backendBase: widget.backendBase,
        authToken: widget.authToken,
        // lookbackWindowIfNull: const Duration(days: 30), // optional
      );

      debugPrint('loginAndSync succeeded. userId returned: $uid');

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainScaffold(initialUserId: uid, backendBase: widget.backendBase),
        ),
      );
    } catch (err) {
      setState(() {
        _error = err.toString();
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _onSkipPressed() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final hs = HealthService();
    try {
      // Provision anonymous user (fallback path)
      final uid = await hs.createOrGetUserByEmail(widget.backendBase, '');
      debugPrint('Anonymous provisioning gave userId: $uid');

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainScaffold(initialUserId: uid, backendBase: widget.backendBase)),
      );
    } catch (err) {
      setState(() => _error = 'Anonymous provisioning failed: $err');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', hintText: 'you@example.com'),
            ),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
            ],
            ElevatedButton.icon(
              onPressed: _loading ? null : _onSignInPressed,
              icon: _loading ? const SizedBox.shrink() : const Icon(Icons.login),
              label: _loading ? const Text('Signing & syncing…') : const Text('Sign in & Sync'),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _loading ? null : _onSkipPressed, child: const Text('Skip (anonymous)')),
          ],
        ),
      ),
    );
  }
}
