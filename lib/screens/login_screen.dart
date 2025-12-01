import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  const LoginScreen({Key? key}) : super(key: key);   // <-- add const
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtr = TextEditingController();
  final _nameCtr = TextEditingController();

  @override
  void dispose() {
    _emailCtr.dispose();
    _nameCtr.dispose();
    super.dispose();
  }

  void _submit() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      await auth.login(_emailCtr.text.trim(), _nameCtr.text.trim());
      if (auth.user != null) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().loading;
    return Scaffold(
      appBar: AppBar(title: Text('Zeno — Login')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _emailCtr, decoration: InputDecoration(labelText: 'Email')),
            SizedBox(height: 12),
            TextField(controller: _nameCtr, decoration: InputDecoration(labelText: 'Name')),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : _submit,
              child: loading ? CircularProgressIndicator(color: Colors.white) : Text('Login / Register'),
            )
          ],
        ),
      ),
    );
  }
}
