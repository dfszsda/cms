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
  final _reqEmailCtrl = TextEditingController();
  bool _showPass = false;
  bool _isLoading = false;

  Future<void> _login() async {
    final email = emailCtrl.text.trim();
    final password = passCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // --- એડમિન ડાયરેક્ટ એક્સેસ લોજિક ---
    if (email == "gohilhari23@gmail.com" && password == "Mbit@123") {
      final user = await _auth.signIn(email, password);
      setState(() => _isLoading = false);
      
      if (user != null && user.role == 'admin') {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
        );
        return;
      }
    }
    // --------------------------------

    final user = await _auth.signIn(email, password);
    
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid credentials. Please check your email/password."), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    if (user.role == 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
      );
    } else {
      final isFirst = await _auth.isFirstTimeLogin(user.uid);
      if (!mounted) return;

      if (isFirst) {
        await _auth.markFirstLoginDone(user.uid);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ChangePasswordScreen(isFirstTime: true)),
        );
      } else if (!user.profileComplete) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ProfileScreen(user: user)),
        );
      } else {
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

  void _showRequestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Request Admin Help"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter your registered email to request a password reset link."),
            const SizedBox(height: 16),
            TextField(
              controller: _reqEmailCtrl,
              decoration: const InputDecoration(
                labelText: "Your Email",
                prefixIcon: Icon(Icons.alternate_email),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (_reqEmailCtrl.text.isEmpty) return;
              try {
                await _auth.sendLoginRequest(_reqEmailCtrl.text.trim(), 'password');
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Request sent successfully!"), behavior: SnackBarBehavior.floating),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            child: const Text("Send Request"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.school_rounded, size: 64, color: Theme.of(context).colorScheme.primary),
                ),
              ),
              const SizedBox(height: 32),
              const Center(child: Text("Welcome Back", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
              const Center(child: Text("Login to your college account", style: TextStyle(color: Colors.grey, fontSize: 16))),
              const SizedBox(height: 48),
              const Text("Email Address", style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(hintText: 'name@college.edu', prefixIcon: Icon(Icons.email_outlined)),
              ),
              const SizedBox(height: 24),
              const Text("Password", style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: passCtrl,
                obscureText: !_showPass,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_showPass ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: _showRequestDialog, child: const Text("Forgot Password?")),
              ),
              const SizedBox(height: 32),
              if (_isLoading) const Center(child: CircularProgressIndicator())
              else ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                child: const Text("Login", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an account? ", style: TextStyle(color: Colors.grey)),
                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                    child: const Text("Sign Up", style: TextStyle(fontWeight: FontWeight.bold)),
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
