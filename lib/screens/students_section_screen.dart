import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/result_model.dart';
import '../services/auth_service.dart';
import 'attendance_screen.dart';
import 'students_list_screen.dart';
import 'todo_works_screen.dart';
import 'materials_screen.dart';
import 'assignment_submission_screen.dart';
import 'timetable_screen.dart';
import 'student_result_screen.dart';
import 'student_fee_screen.dart';
import 'library_screen.dart';
import 'order_history_screen.dart';
import 'profile_screen.dart';
import 'exam_dashboard_screen.dart';

class StudentsSectionScreen extends StatefulWidget {
  final UserModel? user;
  const StudentsSectionScreen({super.key, this.user});

  @override
  State<StudentsSectionScreen> createState() => _StudentsSectionScreenState();
}

class _StudentsSectionScreenState extends State<StudentsSectionScreen> {
  final _auth = AuthService();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              extended: size.width > 1200,
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
                NavigationRailDestination(icon: Icon(Icons.history), label: Text('Orders')),
                NavigationRailDestination(icon: Icon(Icons.person), label: Text('Profile')),
              ],
              selectedIndex: 0,
              onDestinationSelected: (index) {
                if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
                if (index == 2) {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(user: widget.user!)));
                }
                if (index == 0) Navigator.pop(context);
              },
            ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: isDesktop ? 80.0 : 120.0,
                  floating: false,
                  pinned: true,
                  backgroundColor: theme.colorScheme.primary,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(isDesktop ? "Academic Services" : "Students Section", 
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                ),
                SliverToBoxAdapter(
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Academic Services",
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Text("Manage your academic records and resources", style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildInfoChip(theme, Icons.school, "Sem ${widget.user?.semester ?? 'N/A'}"),
                              _buildInfoChip(theme, Icons.qr_code, "Batch: ${widget.user?.batch ?? 'N/A'}"),
                              _buildInfoChip(theme, Icons.account_tree_outlined, "Branch: ${widget.user?.branchName ?? 'N/A'}"),
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('results')
                                    .where('studentId', isEqualTo: widget.user?.uid)
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
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExamDashboardScreen(student: widget.user!))),
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
                          _buildAttendanceSummaryCard(theme),
                          const SizedBox(height: 24),
                          Text("Academic Tools", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? (size.width - 1200).clamp(20, double.infinity) / 2 + 20 : 20),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isDesktop ? 4 : 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.1,
                    ),
                    delegate: SliverChildListDelegate([
                      _ModernSectionCard(
                        title: "Library",
                        icon: Icons.local_library_rounded,
                        color: Colors.indigo,
                        onTap: () {
                          if (widget.user != null) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => LibraryScreen(user: widget.user!)));
                          }
                        },
                      ),
                      _ModernSectionCard(
                        title: "Attendance",
                        icon: Icons.calendar_month_rounded,
                        color: Colors.green,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceScreen(student: widget.user, collegeId: widget.user?.collegeId))),
                      ),
                      _ModernSectionCard(
                        title: "Student List",
                        icon: Icons.people_alt_rounded,
                        color: Colors.blue,
                        onTap: () {
                          if (widget.user != null) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => StudentsListScreen(viewer: widget.user!)));
                          }
                        },
                      ),
                      _ModernSectionCard(
                        title: "Materials",
                        icon: Icons.menu_book_rounded,
                        color: Colors.teal,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MaterialsScreen(role: 'student'))),
                      ),
                      _ModernSectionCard(
                        title: "Fees",
                        icon: Icons.account_balance_wallet_rounded,
                        color: Colors.orange,
                        onTap: () {
                          if (widget.user != null) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => StudentFeeScreen(student: widget.user!)));
                          }
                        },
                      ),
                      _ModernSectionCard(
                        title: "Timetable",
                        icon: Icons.schedule_rounded,
                        color: Colors.indigo,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TimetableScreen(userRole: 'student', userBranch: widget.user?.branch))),
                      ),
                      _ModernSectionCard(
                        title: "Assignments",
                        icon: Icons.assignment_rounded,
                        color: Colors.purple,
                        onTap: () {
                          if (widget.user != null) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => AssignmentSubmissionScreen(user: widget.user!)));
                          }
                        },
                      ),
                      _ModernSectionCard(
                        title: "Todo Works",
                        icon: Icons.task_alt_rounded,
                        color: Colors.red,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TodoWorksScreen())),
                      ),
                      _ModernSectionCard(
                        title: "Result",
                        icon: Icons.assessment_rounded,
                        color: Colors.blueGrey,
                        onTap: () {
                          if (widget.user != null) {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => StudentResultScreen(student: widget.user!)));
                          }
                        },
                      ),
                    ]),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildAttendanceSummaryCard(ThemeData theme) {
    if (widget.user == null) return const SizedBox();
    
    return StreamBuilder<QuerySnapshot>(
      stream: _auth.getStudentAttendance(widget.user!.uid, widget.user!.branch ?? '', widget.user!.semester ?? 1, collegeId: widget.user?.collegeId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        
        final docs = snapshot.data!.docs;
        int totalDays = docs.length;
        int presentDays = 0;
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final presentList = List<String>.from(data['presentStudents'] ?? []);
          if (presentList.contains(widget.user!.uid)) presentDays++;
        }
        
        double percentage = totalDays == 0 ? 0 : (presentDays / totalDays) * 100;
        
        return InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceScreen(student: widget.user, collegeId: widget.user?.collegeId))),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: (percentage >= 75 ? Colors.green : Colors.red).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      "${percentage.toInt()}%",
                      style: TextStyle(
                        color: percentage >= 75 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Attendance Record", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("$presentDays/$totalDays days present", style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ModernSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModernSectionCard({
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
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
