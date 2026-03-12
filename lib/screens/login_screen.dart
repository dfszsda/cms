import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'change_password_screen.dart';
import 'student_home_screen.dart';
import 'teacher_home_screen.dart';
import 'admin_home_screen.dart';
import 'profile_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool _showPass = false;
  bool _isLoading = false;

  Future<void> _login() async {
    final email = emailCtrl.text.trim();
    final password = passCtrl.text;

    // Hardcoded Admin Login check as requested
    if (email == "gohilhari23@gmail.com" && password == "Mbit@123") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = await _auth.signIn(email, password);
    setState(() => _isLoading = false);

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid credentials")),
        );
      }
      return;
    }

    if (user.role == 'admin') {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
        );
      }
      return;
    }

    final isFirst = await _auth.isFirstTimeLogin(user.uid);
    if (isFirst) {
      await _auth.markFirstLoginDone(user.uid);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ChangePasswordScreen(isFirstTime: true)),
        );
      }
    } else if (!user.profileComplete) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ProfileScreen(user: user)),
        );
      }
    } else {
      if (mounted) {
        if (user.role == 'student') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
          );
        } else if (user.role == 'teacher') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const TeacherHomeScreen()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.indigo,
                child: Icon(Icons.school, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                "CMS LOGIN",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email or Username',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passCtrl,
                obscureText: !_showPass,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_showPass ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                  ),
                  child: const Text("Forgot Password?"),
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text("LOGIN", style: TextStyle(fontSize: 16)),
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? "),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SignupScreen()),
                    ),
                    child: const Text("Sign Up"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
