import 'package:flutter/material.dart';
import 'admin/admin_college_setup_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Redirecting to the new professional setup
    return const AdminCollegeSetupScreen();
  }
}
