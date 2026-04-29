import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  final bool isFirstTime;
  const ChangePasswordScreen({super.key, this.isFirstTime = false});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _auth = AuthService();
  final newPassCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  bool _showPass = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isFirstTime) {
      newPassCtrl.text = 'Admin@123';
    }
  }

  @override
  void dispose() {
    newPassCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _change() async {
    FocusScope.of(context).unfocus();
    if (newPassCtrl.text != confirmCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => _isLoading = true);
    await _auth.changePassword(newPassCtrl.text);
    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Change Password")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: newPassCtrl,
              obscureText: !_showPass,
              decoration: InputDecoration(
                labelText: "New Password",
                suffixIcon: IconButton(
                  icon: Icon(_showPass ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _showPass = !_showPass),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmCtrl,
              obscureText: !_showPass,
              decoration: const InputDecoration(labelText: "Confirm Password"),
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ElevatedButton(
                onPressed: _change,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                child: const Text("CHANGE PASSWORD"),
              ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        ),
      ),
    );
  }
}