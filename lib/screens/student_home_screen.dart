import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'teachers_list_screen.dart';
import 'students_section_screen.dart';
import 'canteen_screen.dart';
import 'college_info_screen.dart';
import 'attendance_screen.dart';
import 'order_history_screen.dart';
import 'student_leave_screen.dart';

class StudentHomeScreen extends StatelessWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _StudentHomeScreenContent();
  }
}

class _StudentHomeScreenContent extends StatefulWidget {
  const _StudentHomeScreenContent();

  @override
  State<_StudentHomeScreenContent> createState() => _StudentHomeScreenContentState();
}

class _StudentHomeScreenContentState extends State<_StudentHomeScreenContent> {
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
              title: const Text("College Connect", 
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
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
                    "Hello, ${_currentUser?.fullName.split(' ')[0] ?? 'Student'}!",
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Text("Welcome to your academic dashboard", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  
                  // Semester & Batch Info Chips
                  Row(
                    children: [
                      _buildInfoChip(theme, Icons.school, "Sem ${_currentUser?.semester ?? 'N/A'}"),
                      const SizedBox(width: 12),
                      _buildInfoChip(theme, Icons.qr_code, "Batch: ${_currentUser?.batch ?? 'N/A'}"),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // Today's Classes & Submissions
                  Row(
                    children: [
                      _buildClassTodayCard(theme),
                      const SizedBox(width: 16),
                      _buildSubmissionCard(theme),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    "Quick Actions",
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
                _ModernHomeCard(
                  title: "Students Section",
                  icon: Icons.group_rounded,
                  color: Colors.orange,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentsSectionScreen(user: _currentUser))),
                ),
                _ModernHomeCard(
                  title: "Attendance",
                  icon: Icons.calendar_month_rounded,
                  color: Colors.green,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceScreen(student: _currentUser))),
                ),
                _ModernHomeCard(
                  title: "Leave Request",
                  icon: Icons.exit_to_app_rounded,
                  color: Colors.purple,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentLeaveScreen(student: _currentUser!))),
                ),
                _ModernHomeCard(
                  title: "Teachers",
                  icon: Icons.school_rounded,
                  color: Colors.blue,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeachersListScreen())),
                ),
                _ModernHomeCard(
                  title: "Canteen",
                  icon: Icons.restaurant_rounded,
                  color: Colors.red,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CanteenScreen())),
                ),
                _ModernHomeCard(
                  title: "College Info",
                  icon: Icons.info_rounded,
                  color: Colors.teal,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CollegeInfoScreen(role: 'student'))),
                ),
              ]),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 30)),
        ],
      ),
    );
  }

  Widget _buildInfoChip(ThemeData theme, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildClassTodayCard(ThemeData theme) {
    if (_currentUser == null) return const SizedBox();
    String day = DateFormat('EEEE').format(DateTime.now());
    
    return Expanded(
      child: StreamBuilder<DocumentSnapshot>(
        stream: _auth.getTimetable(_currentUser!.branch ?? '', _currentUser!.semester ?? 1, day),
        builder: (context, snapshot) {
          int count = 0;
          if (snapshot.hasData && snapshot.data!.exists) {
            List slots = snapshot.data!.get('slots') ?? [];
            count = slots.where((s) => s['type'] == 'Subject').length;
          }
          
          return _buildStatCard(context, "$count", "Classes today", Icons.book_rounded);
        },
      ),
    );
  }

  Widget _buildSubmissionCard(ThemeData theme) {
    if (_currentUser == null) return const SizedBox();

    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('assignments')
            .where('branchId', isEqualTo: _currentUser!.branch)
            .where('batchId', isEqualTo: _currentUser!.batch)
            .snapshots(),
        builder: (context, assignmentSnap) {
          if (!assignmentSnap.hasData) return _buildStatCard(context, "0", "Submissions", Icons.assignment_turned_in_rounded);

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('submissions')
                .where('studentId', isEqualTo: _currentUser!.uid)
                .snapshots(),
            builder: (context, submissionSnap) {
              int totalAssignments = assignmentSnap.data!.docs.length;
              int submittedCount = 0;
              
              if (submissionSnap.hasData) {
                submittedCount = submissionSnap.data!.docs.length;
              }

              int remaining = totalAssignments - submittedCount;
              if (remaining < 0) remaining = 0;

              return _buildStatCard(context, "$remaining", "Submissions", Icons.assignment_turned_in_rounded);
            },
          );
        },
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ],
      ),
    );
  }
}

class _ModernHomeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModernHomeCard({
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
