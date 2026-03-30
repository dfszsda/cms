import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class UfmSuspensionScreen extends StatelessWidget {
  final UserModel student;
  const UfmSuspensionScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String dateStr = student.ufmBanUntil != null 
        ? DateFormat('dd MMMM yyyy').format(student.ufmBanUntil!)
        : "N/A";

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.block_flipped, size: 80, color: Colors.red[700]),
              ),
              const SizedBox(height: 32),
              Text(
                "Access Suspended",
                style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.red[900]),
              ),
              const SizedBox(height: 16),
              const Text(
                "Your account has been suspended due to an UnFair Means (UFM) case reported during examination.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    const Text("Suspension Period", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(
                      "Until $dateStr",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const Divider(height: 32),
                    const Text(
                      "After this period, you will be allowed to continue from the NEXT semester. However, you will be marked as 'FAILED' in the subject where UFM was reported.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.redAccent, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await AuthService().signOut();
                    if (context.mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text("Logout"),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Contact the Examination Department if you believe this is a mistake.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
