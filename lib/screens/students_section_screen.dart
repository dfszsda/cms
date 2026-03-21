import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'attendance_screen.dart';
import 'students_list_screen.dart';
import 'coming_soon_screen.dart';
import 'todo_works_screen.dart';
import 'materials_screen.dart';
import 'assignment_submission_screen.dart';
import 'timetable_screen.dart';

class StudentsSectionScreen extends StatefulWidget {
  final UserModel? user;
  const StudentsSectionScreen({super.key, this.user});

  @override
  State<StudentsSectionScreen> createState() => _StudentsSectionScreenState();
}

class _StudentsSectionScreenState extends State<StudentsSectionScreen> {
  final _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Students Section", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Academic Services",
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Manage your academic activities here",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Attendance Summary Card moved from Home
                  _buildAttendanceSummaryCard(theme),
                  
                  const SizedBox(height: 20),
                  
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      _ModernSectionCard(
                        title: "Attendance",
                        icon: Icons.calendar_month_rounded,
                        color: Colors.green,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceScreen(student: widget.user))),
                      ),
                      _ModernSectionCard(
                        title: "Student List",
                        icon: Icons.people_alt_rounded,
                        color: Colors.blue,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentsListScreen())),
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
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComingSoonScreen(title: "Fees"))),
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
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComingSoonScreen(title: "Result"))),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceSummaryCard(ThemeData theme) {
    if (widget.user == null) return const SizedBox();
    
    return StreamBuilder<QuerySnapshot>(
      stream: _auth.getStudentAttendance(widget.user!.uid, widget.user!.branch ?? '', widget.user!.semester ?? 1),
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
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceScreen(student: widget.user))),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: (percentage >= 75 ? Colors.green : Colors.red).withValues(alpha: 0.1),
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
              color: Colors.black.withValues(alpha: 0.05),
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
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
