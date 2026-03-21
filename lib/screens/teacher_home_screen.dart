import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'teachers_list_screen.dart';
import 'canteen_screen.dart';
import 'coming_soon_screen.dart';
import 'materials_screen.dart';
import 'attendance_screen.dart';
import 'teacher_assignments_screen.dart';
import 'timetable_screen.dart';
import 'todo_works_screen.dart';
import 'order_history_screen.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  final _auth = AuthService();
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _currentUser = UserModel.fromMap(doc.data()!, user.uid);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _handleEditProfile() {
    if (_currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProfileScreen(user: _currentUser!)),
      ).then((_) => _loadUserData());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: theme.colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text("Teacher Portal", 
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [const Color(0xFF1E3A8A), theme.colorScheme.primary],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.history_rounded, color: Colors.white),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
                tooltip: "Order History",
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                onPressed: () {},
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
                onSelected: (value) {
                  if (value == 'edit') {
                    _handleEditProfile();
                  } else if (value == 'logout') {
                    _handleLogout();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [Icon(Icons.edit_outlined, size: 20), SizedBox(width: 8), Text("Edit Profile")],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [Icon(Icons.logout, size: 20, color: Colors.red), SizedBox(width: 8), Text("Logout", style: TextStyle(color: Colors.red))],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome back, ${_currentUser?.fullName.split(' ')[0] ?? 'Professor'}",
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Text("Here's what's happening today", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  Text(
                    "Quick Management",
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              delegate: SliverChildListDelegate([
                _ModernTeacherCard(
                  title: "Attendance",
                  icon: Icons.checklist_rounded,
                  color: Colors.green,
                  onTap: () {
                    if (_currentUser?.branch != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceScreen(teacherBranch: _currentUser!.branch!)));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Branch not assigned. Contact Admin.")));
                    }
                  },
                ),
                _ModernTeacherCard(
                  title: "Timetable",
                  icon: Icons.calendar_today_rounded,
                  color: Colors.indigo,
                  onTap: () {
                    if (_currentUser?.branch != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => TimetableScreen(
                        userRole: 'teacher',
                        userBranch: _currentUser!.branch,
                      )));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Branch not assigned. Contact Admin.")));
                    }
                  },
                ),
                _ModernTeacherCard(
                  title: "Assignments",
                  icon: Icons.assignment_rounded,
                  color: Colors.orange,
                  onTap: () {
                    if (_currentUser?.branch != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherAssignmentsScreen(branchId: _currentUser!.branch!)));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Branch not assigned. Contact Admin.")));
                    }
                  },
                ),
                _ModernTeacherCard(
                  title: "Study Materials",
                  icon: Icons.auto_stories_rounded,
                  color: Colors.teal,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MaterialsScreen(role: 'teacher'))),
                ),
                _ModernTeacherCard(
                  title: "Group Works",
                  icon: Icons.groups_rounded,
                  color: Colors.blue,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TodoWorksScreen())),
                ),
                _ModernTeacherCard(
                  title: "Staff List",
                  icon: Icons.people_outline_rounded,
                  color: Colors.blueGrey,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeachersListScreen())),
                ),
                _ModernTeacherCard(
                  title: "Canteen",
                  icon: Icons.restaurant_rounded,
                  color: Colors.red,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CanteenScreen())),
                ),
                _ModernTeacherCard(
                  title: "Events",
                  icon: Icons.event_rounded,
                  color: Colors.purple,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComingSoonScreen(title: "Events"))),
                ),
              ]),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }
}

class _ModernTeacherCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModernTeacherCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
