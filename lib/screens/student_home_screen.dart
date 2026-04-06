import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/exam_timetable_model.dart';
import '../models/college_model.dart';
import '../models/result_model.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'teachers_list_screen.dart';
import 'students_section_screen.dart';
import 'exam_dashboard_screen.dart';
import 'canteen_screen.dart';
import 'college_info_screen.dart';
import 'attendance_screen.dart';
import 'order_history_screen.dart';
import 'student_leave_screen.dart';
import 'student_exam_form_screen.dart';
import 'student_exam_timetable_screen.dart';
import 'student_result_screen.dart';
import 'student_exam_fee_screen.dart';

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
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(user: _currentUser!))).then((_) => _loadUserData());
                  } else if (value == 'logout') {
                    _handleLogout();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text("Edit Profile")),
                  const PopupMenuItem(value: 'logout', child: Text("Logout")),
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
                  Row(
                    children: [
                      _buildInfoChip(theme, Icons.school, "Sem ${_currentUser?.semester ?? 'N/A'}"),
                      const SizedBox(width: 12),
                      _buildInfoChip(theme, Icons.qr_code, "Batch: ${_currentUser?.batch ?? 'N/A'}"),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildInfoChip(theme, Icons.account_tree_outlined, "Branch: ${_currentUser?.branchName ?? 'N/A'}"),
                      const SizedBox(width: 12),
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('results')
                            .where('studentId', isEqualTo: _currentUser?.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          int atktCount = 0;
                          if (snapshot.hasData) {
                            Map<String, bool> subjectStatus = {};
                            for (var doc in snapshot.data!.docs) {
                              final res = ResultModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
                              for (var sub in res.results) {
                                String key = "${res.semester}_${sub.subjectName}";
                                subjectStatus[key] = sub.isPass;
                              }
                            }
                            atktCount = subjectStatus.values.where((isPass) => !isPass).length;
                          }
                          return InkWell(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExamDashboardScreen(student: _currentUser!))),
                            child: _buildInfoChip(
                              theme, 
                              Icons.warning_amber_rounded, 
                              "ATKT: $atktCount",
                              color: atktCount > 0 ? Colors.red : Colors.green,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // NEW: College Info Card for Students
                  StreamBuilder<List<CollegeModel>>(
                    stream: _auth.getColleges(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
                      final college = snapshot.data!.first; // Show the first one by default for students
                      return InkWell(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CollegeInfoScreen(role: 'student', college: college))),
                        child: Card(
                          color: theme.colorScheme.primaryContainer,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                const Icon(Icons.school, size: 40, color: Colors.indigo),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(college.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text(college.university, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 16),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                  ),
                  const SizedBox(height: 16),

                  Text("Quick Actions", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
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
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceScreen(student: _currentUser, collegeId: _currentUser?.collegeId))),
                ),
                _ModernHomeCard(
                  title: "Examination",
                  icon: Icons.assignment_rounded,
                  color: Colors.deepOrange,
                  onTap: () => _showExaminationMenu(context),
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
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showExaminationMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StreamBuilder<ExamTimetableModel?>(
        stream: _auth.getExamTimetable(_currentUser!.branch ?? '', _currentUser!.semester ?? 1),
        builder: (context, snapshot) {
          final timetable = snapshot.data;
          bool isHallTicketAvailable = false;
          
          if (timetable != null) {
            final now = DateTime.now();
            final daysRemaining = timetable.startDate.difference(now).inDays;
            // Available 10 days before exam
            if (daysRemaining <= 10 && daysRemaining >= -15) { // Active until exam ends (approx 15 days)
              isHallTicketAvailable = true;
            }
          }

          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Examination", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const Divider(),
                _buildMenuItem(Icons.description_outlined, "Exam Form", 
                  subText: "View Form",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => StudentExamFormScreen(student: _currentUser!)));
                  }
                ),
                _buildMenuItem(Icons.table_chart_outlined, "Exam Timetable", 
                  subText: "View Timetable",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => StudentExamTimetableScreen(student: _currentUser!)));
                  }
                ),
                _buildMenuItem(
                  Icons.assessment_rounded, 
                  "My Result", 
                  subText: "View & Download",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => StudentResultScreen(student: _currentUser!)));
                  }
                ),
                _buildMenuItem(
                  Icons.badge_outlined, 
                  "Hall Ticket (PDF)", 
                  subText: isHallTicketAvailable ? "Download Now" : "Available 10 days before exam",
                  enabled: isHallTicketAvailable,
                  onTap: isHallTicketAvailable ? () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hall Ticket format will be added soon!")));
                  } : null,
                ),
                _buildMenuItem(
                  Icons.payment_outlined, 
                  "Exam Fee", 
                  subText: "Pay Now",
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => StudentExamFeeScreen(student: _currentUser!)));
                  }
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {String subText = "", VoidCallback? onTap, bool enabled = true}) {
    return ListTile(
      onTap: onTap,
      enabled: enabled,
      leading: Icon(icon, color: enabled ? Colors.deepOrange : Colors.grey),
      title: Text(title, style: TextStyle(color: enabled ? Colors.black : Colors.grey)),
      trailing: Text(subText, style: TextStyle(fontSize: 10, color: enabled ? Colors.deepOrange : Colors.grey)),
    );
  }

  Widget _buildInfoChip(ThemeData theme, IconData icon, String label, {Color? color}) {
    Color mainColor = color ?? theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: mainColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: mainColor),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: mainColor, fontWeight: FontWeight.bold, fontSize: 13)),
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

  const _ModernHomeCard({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
